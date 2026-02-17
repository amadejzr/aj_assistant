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

  it("includes context for module view", () => {
    const prompt = buildSystemPrompt(
      {mod1: {name: "Test"}},
      {type: "module", moduleId: "mod1"},
    );
    expect(prompt).toContain("viewing module \"mod1\"");
  });

  it("includes context for dashboard", () => {
    const prompt = buildSystemPrompt({}, {type: "dashboard"});
    expect(prompt).toContain("user is on the dashboard");
  });

  it("includes context for modules list", () => {
    const prompt = buildSystemPrompt({}, {type: "modules_list"});
    expect(prompt).toContain("viewing their modules list");
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
