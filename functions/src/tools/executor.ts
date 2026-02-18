import * as logger from "firebase-functions/logger";
import {createEntry} from "./create_entry.js";
import {createEntries} from "./create_entries.js";
import {queryEntries} from "./query_entries.js";
import {updateEntry} from "./update_entry.js";
import {updateEntries} from "./update_entries.js";
import {getModuleSummary} from "./get_module_summary.js";

interface ToolUse {
  id: string;
  name: string;
  input: Record<string, unknown>;
}

interface ToolResult {
  type: "tool_result";
  tool_use_id: string;
  content: string;
}

export async function executeToolCall(
  userId: string,
  tool: ToolUse,
): Promise<ToolResult> {
  logger.info(`Executing tool: ${tool.name}`, {userId, input: tool.input});

  let result: string;

  try {
    switch (tool.name) {
    case "createEntry":
      result = await createEntry(userId, tool.input as never);
      break;
    case "createEntries":
      result = await createEntries(userId, tool.input as never);
      break;
    case "queryEntries":
      result = await queryEntries(userId, tool.input as never);
      break;
    case "updateEntry":
      result = await updateEntry(userId, tool.input as never);
      break;
    case "updateEntries":
      result = await updateEntries(userId, tool.input as never);
      break;
    case "getModuleSummary":
      result = await getModuleSummary(userId, tool.input as never);
      break;
    default:
      result = JSON.stringify({error: `Unknown tool: ${tool.name}`});
    }
  } catch (err) {
    logger.error(`Tool ${tool.name} failed`, {error: err});
    result = JSON.stringify({
      error: `Tool execution failed: ${(err as Error).message}`,
    });
  }

  return {
    type: "tool_result",
    tool_use_id: tool.id,
    content: result,
  };
}
