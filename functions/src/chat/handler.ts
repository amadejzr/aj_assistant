import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import Anthropic from "@anthropic-ai/sdk";
import * as logger from "firebase-functions/logger";
import {buildSystemPrompt} from "./system_prompt.js";
import {toolDefinitions} from "./tool_definitions.js";
import {executeToolCall} from "../tools/executor.js";

const MAX_TOOL_ROUNDS = 10;
const MAX_HISTORY_MESSAGES = 20;

const TOOLS_REQUIRING_APPROVAL = new Set(["createEntry", "updateEntry"]);

interface PendingAction {
  toolUseId: string;
  name: string;
  input: Record<string, unknown>;
  description: string;
}

interface ChatRequest {
  conversationId: string;
  message: string;
}

function describeAction(
  name: string, input: Record<string, unknown>,
): string {
  switch (name) {
  case "createEntry": {
    const data = input.data as Record<string, unknown> ?? {};
    const fields = Object.entries(data)
      .map(([k, v]) => `${k}: ${v}`)
      .join(", ");
    return `Create entry in "${input.schemaKey}": ${fields}`;
  }
  case "updateEntry": {
    const data = input.data as Record<string, unknown> ?? {};
    const fields = Object.entries(data)
      .map(([k, v]) => `${k}: ${v}`)
      .join(", ");
    return `Update entry ${input.entryId}: ${fields}`;
  }
  default:
    return `${name}(${JSON.stringify(input)})`;
  }
}

export const chat = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 120,
    memory: "512MiB",
    secrets: ["ANTHROPIC_API_KEY"],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const userId = request.auth.uid;
    const {conversationId, message} = request.data as ChatRequest;

    if (!conversationId || !message) {
      throw new HttpsError(
        "invalid-argument",
        "conversationId and message are required.",
      );
    }

    const db = getFirestore();
    const convRef = db
      .collection("users").doc(userId)
      .collection("conversations").doc(conversationId);
    const messagesRef = convRef.collection("messages");

    // Ensure conversation exists
    const convDoc = await convRef.get();
    if (!convDoc.exists) {
      await convRef.set({
        startedAt: FieldValue.serverTimestamp(),
        lastMessageAt: FieldValue.serverTimestamp(),
        messageCount: 0,
      });
    }

    // Save user message
    await messagesRef.add({
      role: "user",
      content: message,
      timestamp: FieldValue.serverTimestamp(),
    });

    // Load conversation history
    const historySnap = await messagesRef
      .orderBy("timestamp", "asc")
      .limitToLast(MAX_HISTORY_MESSAGES)
      .get();

    const history: Anthropic.Messages.MessageParam[] = [];
    for (const doc of historySnap.docs) {
      const msg = doc.data();
      if (msg.role === "user") {
        history.push({role: "user", content: msg.content});
      } else if (msg.role === "assistant" && msg.content) {
        history.push({role: "assistant", content: msg.content});
      }
    }

    // Load modules for system prompt
    const modulesSnap = await db
      .collection("users").doc(userId)
      .collection("modules")
      .get();

    const modules: Record<string, {
      name: string;
      description?: string;
      schemas?: Record<string, unknown>;
      settings?: Record<string, unknown>;
    }> = {};
    for (const doc of modulesSnap.docs) {
      const d = doc.data();
      modules[doc.id] = {
        name: d.name ?? "",
        description: d.description,
        schemas: d.schemas,
        settings: d.settings,
      };
    }

    const systemPrompt = buildSystemPrompt(modules as never);

    // Call Claude API
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new HttpsError("internal", "ANTHROPIC_API_KEY not configured.");
    }

    const client = new Anthropic({apiKey});
    const messages = [...history];
    let finalText = "";

    try {
      for (let round = 0; round < MAX_TOOL_ROUNDS; round++) {
        logger.info(`Claude round ${round + 1}`, {
          messageCount: messages.length,
        });

        let response: Anthropic.Messages.Message;
        try {
          response = await client.messages.create({
            model: "claude-sonnet-4-5-20250929",
            max_tokens: 4096,
            system: systemPrompt,
            tools: toolDefinitions,
            messages,
          });
        } catch (apiErr) {
          const msg = (apiErr as Error).message ?? "Unknown API error";
          logger.error("Claude API call failed", {error: msg});

          // Save an error message so the user sees something
          await messagesRef.add({
            role: "assistant",
            content: "Sorry, I'm having trouble right now. Please try again.",
            timestamp: FieldValue.serverTimestamp(),
          });

          throw new HttpsError(
            "unavailable",
            `AI service error: ${msg}`,
          );
        }

        const textBlocks = response.content
          .filter(
            (b): b is Anthropic.Messages.TextBlock => b.type === "text",
          )
          .map((b) => b.text);

        if (textBlocks.length > 0) {
          finalText = textBlocks.join("\n");
        }

        if (response.stop_reason === "max_tokens") {
          logger.warn("Response truncated — max_tokens reached", {round});
          finalText += "\n\nI tried to do too much at once. " +
            "Could you break that into smaller requests?";
          break;
        }

        if (response.stop_reason !== "tool_use") break;

        const toolUses = response.content
          .filter(
            (b): b is Anthropic.Messages.ToolUseBlock =>
              b.type === "tool_use",
          );
        if (toolUses.length === 0) break;

        // Split: auto-execute read-only tools, pause for write tools
        const autoTools = toolUses.filter(
          (t) => !TOOLS_REQUIRING_APPROVAL.has(t.name),
        );
        const approvalTools = toolUses.filter(
          (t) => TOOLS_REQUIRING_APPROVAL.has(t.name),
        );

        if (approvalTools.length > 0) {
          // Execute read-only tools first
          for (const toolUse of autoTools) {
            await executeToolCall(userId, {
              id: toolUse.id,
              name: toolUse.name,
              input: toolUse.input as Record<string, unknown>,
            });
          }

          // Build pending actions for Flutter to show
          const pendingActions: PendingAction[] = approvalTools.map((t) => ({
            toolUseId: t.id,
            name: t.name,
            input: t.input as Record<string, unknown>,
            description: describeAction(
              t.name, t.input as Record<string, unknown>,
            ),
          }));

          logger.info("Pausing for approval", {
            tools: approvalTools.map((t) => t.name),
          });

          // Save AI text (if any) as a message
          if (finalText) {
            await messagesRef.add({
              role: "assistant",
              content: finalText,
              timestamp: FieldValue.serverTimestamp(),
            });
          }

          // Save pending actions as a special message
          await messagesRef.add({
            role: "assistant",
            content: "",
            pendingActions,
            approvalStatus: "pending",
            timestamp: FieldValue.serverTimestamp(),
          });

          await convRef.update({
            lastMessageAt: FieldValue.serverTimestamp(),
            messageCount: FieldValue.increment(2),
          });

          return {
            message: finalText,
            conversationId,
            pendingActions,
          };
        }

        // All tools are read-only — execute and continue loop
        messages.push({role: "assistant", content: response.content});

        const toolResults: Anthropic.Messages.ToolResultBlockParam[] = [];
        for (const toolUse of toolUses) {
          const result = await executeToolCall(userId, {
            id: toolUse.id,
            name: toolUse.name,
            input: toolUse.input as Record<string, unknown>,
          });
          toolResults.push(result);
        }

        messages.push({role: "user", content: toolResults});
      }
    } catch (err) {
      // Re-throw HttpsErrors (already handled above)
      if (err instanceof HttpsError) throw err;

      const msg = (err as Error).message ?? "Unknown error";
      logger.error("Chat handler error", {error: msg});
      throw new HttpsError("internal", `Chat failed: ${msg}`);
    }

    // Save final response
    if (!finalText) {
      finalText = "I wasn't able to generate a response. Please try again.";
    }

    await messagesRef.add({
      role: "assistant",
      content: finalText,
      timestamp: FieldValue.serverTimestamp(),
    });

    await convRef.update({
      lastMessageAt: FieldValue.serverTimestamp(),
      messageCount: FieldValue.increment(2),
    });

    return {
      message: finalText,
      conversationId,
    };
  },
);
