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

import {getModuleSummary} from "./get_module_summary";

describe("getModuleSummary", () => {
  const userId = "user1";
  const moduleId = "mod1";
  const modulePath = `users/${userId}/modules/${moduleId}`;

  beforeEach(() => {
    resetStore();
  });

  it("returns error when module doesn't exist", async () => {
    const result = await getModuleSummary(userId, {moduleId: "nope"});
    const parsed = JSON.parse(result);
    expect(parsed.error).toContain("not found");
  });

  it("returns empty summary for module with no entries", async () => {
    seedDoc(modulePath, {name: "Expenses", schemas: {}});

    const result = await getModuleSummary(userId, {moduleId});
    const parsed = JSON.parse(result);
    expect(parsed.moduleName).toBe("Expenses");
    expect(parsed.totalEntries).toBe(0);
  });

  it("counts entries and groups by schema", async () => {
    seedDoc(modulePath, {
      name: "Finance",
      schemas: {
        expense: {
          label: "Expense",
          fields: {
            amount: {type: "number", label: "Amount"},
          },
        },
        income: {
          label: "Income",
          fields: {
            amount: {type: "number", label: "Amount"},
          },
        },
      },
    });

    // Seed entries
    seedDoc(`${modulePath}/entries/e1`, {
      data: {amount: 50},
      schemaKey: "expense",
      createdAt: new FakeTimestamp(1000),
    });
    seedDoc(`${modulePath}/entries/e2`, {
      data: {amount: 30},
      schemaKey: "expense",
      createdAt: new FakeTimestamp(2000),
    });
    seedDoc(`${modulePath}/entries/e3`, {
      data: {amount: 200},
      schemaKey: "income",
      createdAt: new FakeTimestamp(3000),
    });

    const result = await getModuleSummary(userId, {moduleId});
    const parsed = JSON.parse(result);

    expect(parsed.totalEntries).toBe(3);
    expect(parsed.schemas.expense.entryCount).toBe(2);
    expect(parsed.schemas.income.entryCount).toBe(1);
  });

  it("computes numeric aggregates", async () => {
    seedDoc(modulePath, {
      name: "Expenses",
      schemas: {
        expense: {
          label: "Expense",
          fields: {
            amount: {type: "number", label: "Amount"},
          },
        },
      },
    });

    seedDoc(`${modulePath}/entries/e1`, {
      data: {amount: 10},
      schemaKey: "expense",
      createdAt: new FakeTimestamp(1000),
    });
    seedDoc(`${modulePath}/entries/e2`, {
      data: {amount: 20},
      schemaKey: "expense",
      createdAt: new FakeTimestamp(2000),
    });
    seedDoc(`${modulePath}/entries/e3`, {
      data: {amount: 30},
      schemaKey: "expense",
      createdAt: new FakeTimestamp(3000),
    });

    const result = await getModuleSummary(userId, {moduleId});
    const parsed = JSON.parse(result);

    const agg = parsed.schemas.expense.numericAggregates.amount;
    expect(agg.sum).toBe(60);
    expect(agg.avg).toBe(20);
    expect(agg.min).toBe(10);
    expect(agg.max).toBe(30);
  });

  it("returns recent entries (max 5)", async () => {
    seedDoc(modulePath, {
      name: "Test",
      schemas: {default: {label: "Default", fields: {}}},
    });

    for (let i = 0; i < 8; i++) {
      seedDoc(`${modulePath}/entries/e${i}`, {
        data: {n: i},
        schemaKey: "default",
        createdAt: new FakeTimestamp(i * 1000),
      });
    }

    const result = await getModuleSummary(userId, {moduleId});
    const parsed = JSON.parse(result);
    expect(parsed.schemas.default.recentEntries.length).toBe(5);
  });
});
