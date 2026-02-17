import {
  resetStore,
  seedDoc,
  getStore,
  mockGetFirestore,
  FakeFieldValue,
  FakeTimestamp,
} from "../__mocks__/firestore";

// Mock firebase-admin/firestore
jest.mock("firebase-admin/firestore", () => ({
  getFirestore: () => mockGetFirestore(),
  FieldValue: FakeFieldValue,
  Timestamp: FakeTimestamp,
}));

// Mock logger
jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

// Mock effects (don't actually run them in unit tests)
jest.mock("../effects/post_submit_effect_executor", () => ({
  executeEffects: jest.fn().mockResolvedValue({}),
}));

import {createEntry} from "./create_entry";

describe("createEntry", () => {
  beforeEach(() => {
    resetStore();
  });

  const userId = "user1";
  const moduleId = "mod1";
  const modulePath = `users/${userId}/modules/${moduleId}`;

  function seedModule(schemas: Record<string, unknown> = {}) {
    seedDoc(modulePath, {
      name: "Expenses",
      schemas,
    });
  }

  it("returns error when module doesn't exist", async () => {
    const result = await createEntry(userId, {
      moduleId: "nonexistent",
      schemaKey: "default",
      data: {},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("not found");
  });

  it("returns error when schema doesn't exist", async () => {
    seedModule({expense: {label: "Expense", fields: {}}});

    const result = await createEntry(userId, {
      moduleId,
      schemaKey: "wrong_schema",
      data: {},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("not found");
    expect(parsed.error).toContain("expense");
  });

  it("returns error when required fields are missing", async () => {
    seedModule({
      expense: {
        label: "Expense",
        fields: {
          amount: {type: "number", label: "Amount", required: true},
          note: {type: "text", label: "Note"},
        },
      },
    });

    const result = await createEntry(userId, {
      moduleId,
      schemaKey: "expense",
      data: {note: "Lunch"},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("Missing required fields");
    expect(parsed.error).toContain("amount");
  });

  it("creates entry successfully with valid data", async () => {
    seedModule({
      expense: {
        label: "Expense",
        version: 1,
        fields: {
          amount: {type: "number", label: "Amount", required: true},
          note: {type: "text", label: "Note"},
        },
      },
    });

    const result = await createEntry(userId, {
      moduleId,
      schemaKey: "expense",
      data: {amount: 42, note: "Coffee"},
    });
    const parsed = JSON.parse(result);

    expect(parsed.error).toBeUndefined();
    expect(parsed.id).toBeDefined();
    expect(parsed.schemaKey).toBe("expense");
    expect(parsed.data).toEqual({amount: 42, note: "Coffee"});

    // Verify the entry was written to the store
    const entries = Object.keys(getStore()).filter((k) =>
      k.startsWith(`${modulePath}/entries/`)
    );
    expect(entries.length).toBe(1);

    const storedEntry = getStore()[entries[0]];
    expect(storedEntry.data).toEqual({amount: 42, note: "Coffee"});
    expect(storedEntry.schemaKey).toBe("expense");
  });

  it("allows optional fields to be omitted", async () => {
    seedModule({
      expense: {
        label: "Expense",
        fields: {
          amount: {type: "number", label: "Amount", required: true},
          note: {type: "text", label: "Note"},
        },
      },
    });

    const result = await createEntry(userId, {
      moduleId,
      schemaKey: "expense",
      data: {amount: 100},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toBeUndefined();
    expect(parsed.id).toBeDefined();
  });
});
