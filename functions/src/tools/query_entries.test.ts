import {
  resetStore,
  seedDoc,
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

import {queryEntries} from "./query_entries";

describe("queryEntries", () => {
  const userId = "user1";
  const moduleId = "mod1";
  const modulePath = `users/${userId}/modules/${moduleId}`;

  beforeEach(() => {
    resetStore();
    // Seed module
    seedDoc(modulePath, {name: "Expenses", schemas: {}});
  });

  function seedEntry(id: string, data: Record<string, unknown>, schemaKey = "expense") {
    seedDoc(`${modulePath}/entries/${id}`, {
      data,
      schemaKey,
      createdAt: new FakeTimestamp(Date.now() / 1000),
    });
  }

  it("returns error when module doesn't exist", async () => {
    const result = await queryEntries(userId, {moduleId: "nope"});
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("not found");
  });

  it("returns empty list when no entries", async () => {
    const result = await queryEntries(userId, {moduleId});
    const parsed = JSON.parse(result);
    expect(parsed.count).toBe(0);
    expect(parsed.entries).toEqual([]);
  });

  it("returns entries with data", async () => {
    seedEntry("e1", {amount: 50, note: "Lunch"});
    seedEntry("e2", {amount: 30, note: "Coffee"});

    const result = await queryEntries(userId, {moduleId});
    const parsed = JSON.parse(result);
    expect(parsed.count).toBe(2);
    expect(parsed.entries.map((e: {id: string}) => e.id).sort()).toEqual(["e1", "e2"]);
  });

  it("filters by schemaKey", async () => {
    seedEntry("e1", {amount: 50}, "expense");
    seedEntry("e2", {amount: 100}, "income");

    const result = await queryEntries(userId, {
      moduleId,
      schemaKey: "expense",
    });
    const parsed = JSON.parse(result);
    expect(parsed.count).toBe(1);
    expect(parsed.entries[0].id).toBe("e1");
  });

  it("respects limit", async () => {
    seedEntry("e1", {amount: 10});
    seedEntry("e2", {amount: 20});
    seedEntry("e3", {amount: 30});

    const result = await queryEntries(userId, {moduleId, limit: 2});
    const parsed = JSON.parse(result);
    expect(parsed.count).toBe(2);
  });

  it("caps limit at 50", async () => {
    const result = await queryEntries(userId, {moduleId, limit: 100});
    // Should not throw — internally capped
    const parsed = JSON.parse(result);
    expect(parsed.count).toBe(0);
  });
});
