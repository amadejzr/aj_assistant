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

interface ChatContext {
  type: "dashboard" | "modules_list" | "module";
  moduleId?: string;
  screenId?: string;
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
  context?: ChatContext,
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
    "- Confirm before bulk operations or deletions.\n" +
    "- When the user mentions an amount without specifying a module, " +
    "use context to infer which module they mean.\n" +
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

  // Context awareness
  if (context) {
    switch (context.type) {
    case "module":
      sections.push(
        `CURRENT CONTEXT: The user is viewing module "${context.moduleId}"` +
          (context.screenId ? ` on screen "${context.screenId}"` : "") +
          ". Prioritize operations on this module unless they specify " +
          "otherwise.",
      );
      break;
    case "dashboard":
      sections.push(
        "CURRENT CONTEXT: The user is on the dashboard. They may ask " +
          "about any of their modules.",
      );
      break;
    case "modules_list":
      sections.push(
        "CURRENT CONTEXT: The user is viewing their modules list.",
      );
      break;
    }
  }

  return sections.join("\n\n");
}
