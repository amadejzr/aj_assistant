import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import Anthropic from "@anthropic-ai/sdk";
import * as logger from "firebase-functions/logger";
import {buildSystemPrompt} from "./system_prompt.js";
import {toolDefinitions} from "./tool_definitions.js";
import {executeToolCall} from "../tools/executor.js";

const MAX_TOOL_ROUNDS = 10;
const MAX_HISTORY_MESSAGES = 20;

interface ChatContext {
  type: "dashboard" | "modules_list" | "module";
  moduleId?: string;
  screenId?: string;
}

interface ChatRequest {
  conversationId: string;
  message: string;
  context?: ChatContext;
}

export const chat = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 120,
    memory: "512MiB",
    secrets: ["ANTHROPIC_API_KEY"],
  },
  async (request) => {
    // 1. Authenticate
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const userId = request.auth.uid;
    const {conversationId, message, context} = request.data as ChatRequest;

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

    // 2. Ensure conversation doc exists
    const convDoc = await convRef.get();
    if (!convDoc.exists) {
      await convRef.set({
        context: context ?? null,
        startedAt: FieldValue.serverTimestamp(),
        lastMessageAt: FieldValue.serverTimestamp(),
        messageCount: 0,
      });
    }

    // 3. Save user message
    await messagesRef.add({
      role: "user",
      content: message,
      timestamp: FieldValue.serverTimestamp(),
    });

    // 4. Load conversation history
    const historySnap = await messagesRef
      .orderBy("timestamp", "asc")
      .limitToLast(MAX_HISTORY_MESSAGES)
      .get();

    const history: Anthropic.Messages.MessageParam[] = [];
    for (const doc of historySnap.docs) {
      const msg = doc.data();
      if (msg.role === "user") {
        history.push({role: "user", content: msg.content});
      } else if (msg.role === "assistant") {
        history.push({role: "assistant", content: msg.content});
      }
    }

    // 5. Load user's modules for system prompt
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
      const data = doc.data();
      modules[doc.id] = {
        name: data.name ?? "",
        description: data.description,
        schemas: data.schemas,
        settings: data.settings,
      };
    }

    const systemPrompt = buildSystemPrompt(
      modules as never,
      context,
    );

    // 6. Call Claude API with tool loop
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new HttpsError("internal", "ANTHROPIC_API_KEY not configured.");
    }

    const client = new Anthropic({apiKey});
    const messages = [...history];
    let finalText = "";

    for (let round = 0; round < MAX_TOOL_ROUNDS; round++) {
      logger.info(`Claude API call round ${round + 1}`, {
        messageCount: messages.length,
      });

      const response = await client.messages.create({
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 1024,
        system: systemPrompt,
        tools: toolDefinitions,
        messages,
      });

      // Extract text blocks
      const textBlocks = response.content
        .filter((b): b is Anthropic.Messages.TextBlock => b.type === "text")
        .map((b) => b.text);

      if (textBlocks.length > 0) {
        finalText = textBlocks.join("\n");
      }

      // Check if we're done
      if (response.stop_reason !== "tool_use") {
        break;
      }

      // Extract tool use blocks
      const toolUses = response.content
        .filter(
          (b): b is Anthropic.Messages.ToolUseBlock => b.type === "tool_use",
        );

      if (toolUses.length === 0) break;

      // Add assistant response to messages
      messages.push({role: "assistant", content: response.content});

      // Execute tools and collect results
      const toolResults: Anthropic.Messages.ToolResultBlockParam[] = [];
      for (const toolUse of toolUses) {
        const result = await executeToolCall(userId, {
          id: toolUse.id,
          name: toolUse.name,
          input: toolUse.input as Record<string, unknown>,
        });
        toolResults.push(result);
      }

      // Add tool results to messages
      messages.push({role: "user", content: toolResults});
    }

    // 7. Save assistant response
    await messagesRef.add({
      role: "assistant",
      content: finalText,
      timestamp: FieldValue.serverTimestamp(),
    });

    // Update conversation metadata
    await convRef.update({
      lastMessageAt: FieldValue.serverTimestamp(),
      messageCount: FieldValue.increment(2),
      ...(context ? {context} : {}),
    });

    // 8. Return response to Flutter
    return {
      message: finalText,
      conversationId,
    };
  },
);
