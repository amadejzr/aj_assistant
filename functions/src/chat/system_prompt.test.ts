import {buildSystemPrompt} from "./system_prompt";

describe("buildSystemPrompt", () => {
  it("includes today's date", () => {
    const prompt = buildSystemPrompt({});
    const today = new Date().toISOString().split("T")[0];
    expect(prompt).toContain(`Today's date is ${today}`);
  });

  it("says no modules when empty", () => {
    const prompt = buildSystemPrompt({});
    expect(prompt).toContain("user has no modules yet");
  });

  it("includes module names and schemas", () => {
    const prompt = buildSystemPrompt({
      mod1: {
        name: "Expenses",
        schemas: {
          expense: {
            label: "Expense",
            fields: {
              amount: {type: "currency", label: "Amount", required: true},
              category: {
                type: "enumType",
                label: "Category",
                options: ["Food", "Transport"],
              },
            },
          },
        },
      },
    });

    expect(prompt).toContain("Expenses");
    expect(prompt).toContain("mod1");
    expect(prompt).toContain("amount (currency)");
    expect(prompt).toContain("[required]");
    expect(prompt).toContain("options=[Food, Transport]");
  });

  it("includes rule about only operating on existing modules", () => {
    const prompt = buildSystemPrompt({});
    expect(prompt).toContain("ONLY operate on modules the user already has");
  });

  it("includes database table names and CREATE TABLE SQL", () => {
    const prompt = buildSystemPrompt({
      hiking: {
        name: "Hiking Journal",
        description: "Plan hikes and log trail experiences",
        database: {
          tableNames: {hike: "m_hikes"},
          setup: [
            'CREATE TABLE IF NOT EXISTS "m_hikes" (' +
              "id TEXT PRIMARY KEY, " +
              "name TEXT NOT NULL, " +
              "distance REAL, " +
              "difficulty TEXT DEFAULT 'moderate'" +
              ")",
            'CREATE INDEX idx_hikes_name ON "m_hikes" (name)',
          ],
        },
      },
    });

    expect(prompt).toContain("Hiking Journal");
    expect(prompt).toContain("hiking");
    expect(prompt).toContain('Schema key "hike" → table "m_hikes"');
    expect(prompt).toContain("CREATE TABLE");
    expect(prompt).toContain("name TEXT NOT NULL");
    // Index statements should not be included
    expect(prompt).not.toContain("CREATE INDEX");
  });

  it("includes module settings when present", () => {
    const prompt = buildSystemPrompt({
      mod1: {
        name: "Budget",
        settings: {monthlyBudget: 2000, currency: "USD"},
      },
    });
    expect(prompt).toContain("monthlyBudget");
    expect(prompt).toContain("2000");
  });
});
