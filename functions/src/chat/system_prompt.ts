interface FieldDef {
  type: string;
  label: string;
  required?: boolean;
  options?: string[];
  constraints?: Record<string, unknown>;
}

interface SchemaData {
  label?: string;
  fields?: Record<string, FieldDef>;
}

interface ModuleData {
  name: string;
  description?: string;
  schemas?: Record<string, SchemaData>;
  settings?: Record<string, unknown>;
}

function formatField(key: string, field: FieldDef): string {
  let line = `    - ${key} (${field.type}): "${field.label}"`;
  if (field.required) line += " [required]";
  if (field.options && field.options.length > 0) {
    line += ` options=[${field.options.join(", ")}]`;
  }
  if (field.constraints && Object.keys(field.constraints).length > 0) {
    line += ` constraints=${JSON.stringify(field.constraints)}`;
  }
  return line;
}

function formatSchema(
  key: string,
  schema: SchemaData,
): string {
  const lines: string[] = [];
  const label = schema.label || key;
  lines.push(`  Schema "${key}" (${label}):`);

  const fields = schema.fields ?? {};
  if (Object.keys(fields).length === 0) {
    lines.push("    (no fields defined)");
  } else {
    for (const [fieldKey, field] of Object.entries(fields)) {
      lines.push(formatField(fieldKey, field));
    }
  }
  return lines.join("\n");
}

function formatModule(id: string, mod: ModuleData): string {
  const lines: string[] = [];
  lines.push(`Module "${mod.name}" (id: ${id})`);
  if (mod.description) {
    lines.push(`  Description: ${mod.description}`);
  }

  const schemas = mod.schemas ?? {};
  for (const [schemaKey, schema] of Object.entries(schemas)) {
    lines.push(formatSchema(schemaKey, schema));
  }

  if (mod.settings && Object.keys(mod.settings).length > 0) {
    lines.push(`  Settings: ${JSON.stringify(mod.settings)}`);
  }

  return lines.join("\n");
}

export function buildSystemPrompt(
  modules: Record<string, ModuleData>,
): string {
  const sections: string[] = [];

  const now = new Date();
  const dateStr = now.toISOString().split("T")[0];

  sections.push(
    "You are AJ, a personal assistant that helps users manage their data. " +
    "You operate within an app where users have created modules (like " +
    "expense trackers, fitness logs, habit trackers, etc.). Each module " +
    "has its own data schema.\n\n" +
    "Your job is to help users create, read, and update entries in their " +
    "modules through natural conversation. Always be concise and helpful.\n\n" +
    `Today's date is ${dateStr}.`,
  );

  sections.push(
    "RULES:\n" +
    "- ONLY operate on modules the user already has. If the user asks to " +
    "add data that doesn't fit any existing module, tell them they need " +
    "to create that module first. Never invent module IDs or schema keys.\n" +
    "- Use the tools provided to perform data operations. Never make up data.\n" +
    "- Always match field keys exactly as defined in the schema.\n" +
    "- For enum fields, only use values from the options list.\n" +
    "- For reference fields, use getModuleSummary or queryEntries first " +
    "to find the correct entry ID.\n" +
    "- For write operations (creating or updating entries), always call " +
    "the tool directly. The app shows the user an approval card before " +
    "anything is saved — do NOT ask for confirmation in text first.\n" +
    "- For deletions, confirm with the user in text before proceeding.\n" +
    "- When the user mentions an amount without specifying a module, " +
    "use context to infer which module they mean.\n" +
    "- When creating multiple entries at once (e.g. a week of meals, " +
    "several expenses, a batch of workouts), ALWAYS use createEntries " +
    "instead of calling createEntry multiple times. Same for updates: " +
    "use updateEntries to update several entries in one call.\n" +
    "- Keep responses short. After creating/updating data, briefly " +
    "confirm what was done.",
  );

  // Module schemas
  const moduleIds = Object.keys(modules);
  if (moduleIds.length === 0) {
    sections.push(
      "USER'S MODULES:\nThe user has no modules yet. They need to create " +
      "modules through the module builder before you can help with data.",
    );
  } else {
    const moduleLines = moduleIds
      .map((id) => formatModule(id, modules[id]))
      .join("\n\n");
    sections.push(`USER'S MODULES:\n${moduleLines}`);
  }

  return sections.join("\n\n");
}
