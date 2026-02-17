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

jest.mock("../effects/post_submit_effect_executor", () => ({
  executeEffects: jest.fn().mockResolvedValue({}),
}));

import {executeToolCall} from "./executor";

describe("executeToolCall", () => {
  const userId = "user1";

  beforeEach(() => {
    resetStore();
  });

  it("returns error for unknown tool", async () => {
    const result = await executeToolCall(userId, {
      id: "tool_1",
      name: "unknownTool",
      input: {},
    });

    expect(result.type).toBe("tool_result");
    expect(result.tool_use_id).toBe("tool_1");
    const parsed = JSON.parse(result.content);
    expect(parsed.error).toContain("Unknown tool");
  });

  it("dispatches createEntry correctly", async () => {
    seedDoc(`users/${userId}/modules/mod1`, {
      name: "Test",
      schemas: {
        default: {label: "Default", fields: {}},
      },
    });

    const result = await executeToolCall(userId, {
      id: "tool_2",
      name: "createEntry",
      input: {moduleId: "mod1", schemaKey: "default", data: {x: 1}},
    });

    const parsed = JSON.parse(result.content);
    expect(parsed.error).toBeUndefined();
    expect(parsed.id).toBeDefined();
  });

  it("dispatches queryEntries correctly", async () => {
    seedDoc(`users/${userId}/modules/mod1`, {name: "Test", schemas: {}});

    const result = await executeToolCall(userId, {
      id: "tool_3",
      name: "queryEntries",
      input: {moduleId: "mod1"},
    });

    const parsed = JSON.parse(result.content);
    expect(parsed.count).toBe(0);
    expect(parsed.entries).toEqual([]);
  });

  it("catches and wraps tool errors", async () => {
    // getModuleSummary on nonexistent module returns error JSON, not throw
    const result = await executeToolCall(userId, {
      id: "tool_4",
      name: "getModuleSummary",
      input: {moduleId: "nonexistent"},
    });

    const parsed = JSON.parse(result.content);
    expect(parsed.error).toContain("not found");
  });
});
