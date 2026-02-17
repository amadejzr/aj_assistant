import {
  resetStore,
  seedDoc,
  getStore,
  mockGetFirestore,
  FakeFieldValue,
  FakeTimestamp,
} from "../__mocks__/firestore";

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: () => mockGetFirestore(),
  FieldValue: FakeFieldValue,
  Timestamp: FakeTimestamp,
}));

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

jest.mock("../effects/post_submit_effect_executor", () => ({
  executeEffects: jest.fn().mockResolvedValue({}),
}));

import {updateEntry} from "./update_entry";

describe("updateEntry", () => {
  const userId = "user1";
  const moduleId = "mod1";
  const modulePath = `users/${userId}/modules/${moduleId}`;
  const entryId = "entry1";
  const entryPath = `${modulePath}/entries/${entryId}`;

  beforeEach(() => {
    resetStore();
    seedDoc(modulePath, {
      name: "Expenses",
      schemas: {
        expense: {
          label: "Expense",
          fields: {
            amount: {type: "number", label: "Amount"},
            note: {type: "text", label: "Note"},
          },
        },
      },
    });
    seedDoc(entryPath, {
      data: {amount: 50, note: "Lunch"},
      schemaKey: "expense",
      createdAt: new FakeTimestamp(Date.now() / 1000),
      updatedAt: new FakeTimestamp(Date.now() / 1000),
    });
  });

  it("returns error when module doesn't exist", async () => {
    const result = await updateEntry(userId, {
      moduleId: "nonexistent",
      entryId,
      data: {amount: 100},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("not found");
  });

  it("returns error when entry doesn't exist", async () => {
    const result = await updateEntry(userId, {
      moduleId,
      entryId: "nonexistent",
      data: {amount: 100},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("not found");
  });

  it("returns error for unknown fields", async () => {
    const result = await updateEntry(userId, {
      moduleId,
      entryId,
      data: {unknown_field: "value"},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("Unknown fields");
    expect(parsed.error).toContain("unknown_field");
  });

  it("updates entry successfully", async () => {
    const result = await updateEntry(userId, {
      moduleId,
      entryId,
      data: {amount: 75},
    });
    const parsed = JSON.parse(result);

    expect(parsed.error).toBeUndefined();
    expect(parsed.id).toBe(entryId);

    // Verify the data was updated
    const stored = getStore()[entryPath];
    expect(stored.data.amount).toBe(75);
    expect(stored.data.note).toBe("Lunch"); // unchanged
  });

  it("does partial update (only specified fields)", async () => {
    const result = await updateEntry(userId, {
      moduleId,
      entryId,
      data: {note: "Dinner"},
    });
    const parsed = JSON.parse(result);
    expect(parsed.error).toBeUndefined();

    const stored = getStore()[entryPath];
    expect(stored.data.amount).toBe(50); // unchanged
    expect(stored.data.note).toBe("Dinner"); // updated
  });
});
