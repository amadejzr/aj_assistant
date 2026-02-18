import Anthropic from "@anthropic-ai/sdk";

type Tool = Anthropic.Messages.Tool;

export const toolDefinitions: Tool[] = [
  {
    name: "createEntry",
    description:
      "Create a new data entry in a module. Use this when the user wants " +
      "to add, log, or record something (an expense, a workout, a habit " +
      "check-in, etc.). Always confirm the module and data before creating.",
    input_schema: {
      type: "object" as const,
      properties: {
        moduleId: {
          type: "string",
          description: "The ID of the module to create the entry in.",
        },
        schemaKey: {
          type: "string",
          description:
            "The schema key within the module (e.g. 'default', " +
            "'transactions', 'accounts'). Use 'default' if the module " +
            "has only one schema.",
        },
        data: {
          type: "object",
          description:
            "The entry data as key-value pairs matching the schema " +
            "field keys. Use the exact field keys from the schema.",
        },
      },
      required: ["moduleId", "schemaKey", "data"],
    },
  },
  {
    name: "createEntries",
    description:
      "Create multiple entries in a module at once. Use this instead of " +
      "createEntry when the user wants to add several items in one go — " +
      "e.g. a week of meals, multiple expenses, a batch of habits. " +
      "All entries use the same schema. Maximum 50 entries per call.",
    input_schema: {
      type: "object" as const,
      properties: {
        moduleId: {
          type: "string",
          description: "The ID of the module to create the entries in.",
        },
        schemaKey: {
          type: "string",
          description:
            "The schema key within the module (e.g. 'default'). " +
            "All entries in the batch use this schema.",
        },
        entries: {
          type: "array",
          description: "Array of entries to create.",
          items: {
            type: "object",
            properties: {
              data: {
                type: "object",
                description:
                  "The entry data as key-value pairs matching the schema " +
                  "field keys.",
              },
            },
            required: ["data"],
          },
        },
      },
      required: ["moduleId", "schemaKey", "entries"],
    },
  },
  {
    name: "queryEntries",
    description:
      "Query and read entries from a module. Use this to look up, search, " +
      "list, or check existing data. Returns entries matching the filters.",
    input_schema: {
      type: "object" as const,
      properties: {
        moduleId: {
          type: "string",
          description: "The ID of the module to query.",
        },
        schemaKey: {
          type: "string",
          description:
            "Optional schema key to filter by. Omit to query all schemas.",
        },
        filters: {
          type: "array",
          description: "Optional filters to narrow results.",
          items: {
            type: "object",
            properties: {
              field: {type: "string", description: "The data field key."},
              op: {
                type: "string",
                enum: ["==", "!=", ">", "<", ">=", "<="],
                description: "Comparison operator.",
              },
              value: {description: "The value to compare against."},
            },
            required: ["field", "op", "value"],
          },
        },
        orderBy: {
          type: "string",
          description:
            "Field key to order results by. Defaults to createdAt.",
        },
        limit: {
          type: "number",
          description: "Max entries to return (default 20, max 50).",
        },
      },
      required: ["moduleId"],
    },
  },
  {
    name: "updateEntry",
    description:
      "Update an existing entry in a module. Use this to modify, change, " +
      "or correct data that already exists. Performs a partial merge — " +
      "only the provided fields are changed.",
    input_schema: {
      type: "object" as const,
      properties: {
        moduleId: {
          type: "string",
          description: "The ID of the module containing the entry.",
        },
        entryId: {
          type: "string",
          description: "The ID of the entry to update.",
        },
        data: {
          type: "object",
          description:
            "The fields to update as key-value pairs. Only provided " +
            "fields are changed; others are left untouched.",
        },
      },
      required: ["moduleId", "entryId", "data"],
    },
  },
  {
    name: "updateEntries",
    description:
      "Update multiple existing entries in a module at once. Use this " +
      "instead of updateEntry when the user wants to change several items — " +
      "e.g. mark a batch of meals as eaten, update multiple habit statuses. " +
      "Each entry can have different fields updated. Maximum 50 per call.",
    input_schema: {
      type: "object" as const,
      properties: {
        moduleId: {
          type: "string",
          description: "The ID of the module containing the entries.",
        },
        entries: {
          type: "array",
          description: "Array of entries to update.",
          items: {
            type: "object",
            properties: {
              entryId: {
                type: "string",
                description: "The ID of the entry to update.",
              },
              data: {
                type: "object",
                description:
                  "The fields to update as key-value pairs. Only provided " +
                  "fields are changed.",
              },
            },
            required: ["entryId", "data"],
          },
        },
      },
      required: ["moduleId", "entries"],
    },
  },
  {
    name: "getModuleSummary",
    description:
      "Get an overview of a module's data without fetching every entry. " +
      "Returns entry counts, recent entries, and numeric field aggregates. " +
      "Use this to answer questions like 'how much did I spend this month' " +
      "or 'show me my recent workouts' without pulling all data.",
    input_schema: {
      type: "object" as const,
      properties: {
        moduleId: {
          type: "string",
          description: "The ID of the module to summarize.",
        },
        schemaKey: {
          type: "string",
          description:
            "Optional schema key to narrow the summary to one schema.",
        },
      },
      required: ["moduleId"],
    },
  },
];
