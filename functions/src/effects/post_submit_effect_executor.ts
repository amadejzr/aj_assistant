import {getFirestore} from "firebase-admin/firestore";

/**
 * Port of the Dart PostSubmitEffectExecutor.
 *
 * Computes entry updates from `onSubmit` effects declared in form_screen
 * blueprints and applies them atomically via a Firestore batch write.
 *
 * Supported effect types:
 *   - adjust_reference: add/subtract a numeric value on a referenced entry
 *   - set_reference: set a field on a referenced entry
 */

interface Effect {
  type: string;
  referenceField?: string;
  targetField?: string;
  operation?: string;
  amountField?: string;
  amount?: number;
  sourceField?: string;
  value?: unknown;
}

interface EntryDoc {
  id: string;
  data: Record<string, unknown>;
}

/** Accumulated updates: { entryId: { field: newValue } } */
type UpdateMap = Record<string, Record<string, unknown>>;

function toNum(value: unknown): number | null {
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const n = Number(value);
    return isNaN(n) ? null : n;
  }
  return null;
}

function computeUpdates(
  effects: Effect[],
  formData: Record<string, unknown>,
  entries: EntryDoc[],
): UpdateMap {
  const entryById = new Map(entries.map((e) => [e.id, e]));
  const updates: UpdateMap = {};

  for (const effect of effects) {
    switch (effect.type) {
    case "adjust_reference":
      applyAdjust(effect, formData, entryById, updates);
      break;
    case "set_reference":
      applySet(effect, formData, entryById, updates);
      break;
    }
  }

  return updates;
}

function applyAdjust(
  effect: Effect,
  formData: Record<string, unknown>,
  entryById: Map<string, EntryDoc>,
  updates: UpdateMap,
): void {
  const {referenceField, targetField, operation} = effect;
  if (!referenceField || !targetField || !operation) return;
  if (operation !== "add" && operation !== "subtract") return;

  const entryId = String(formData[referenceField] ?? "");
  if (!entryId) return;

  const entry = entryById.get(entryId);
  if (!entry) return;

  // Resolve amount: literal `amount` takes precedence, then `amountField`
  let amount: number | null;
  if (effect.amount !== undefined) {
    amount = toNum(effect.amount);
  } else {
    if (!effect.amountField) return;
    amount = toNum(formData[effect.amountField]);
  }
  if (amount === null) return;

  const accumulated = updates[entryId] ?? {};
  const currentRaw = targetField in accumulated
    ? accumulated[targetField]
    : entry.data[targetField];
  const current = toNum(currentRaw) ?? 0;

  const newValue = operation === "add" ? current + amount : current - amount;

  if (!updates[entryId]) updates[entryId] = {};
  updates[entryId][targetField] = newValue;
}

function applySet(
  effect: Effect,
  formData: Record<string, unknown>,
  entryById: Map<string, EntryDoc>,
  updates: UpdateMap,
): void {
  const {referenceField, targetField} = effect;
  if (!referenceField || !targetField) return;

  const entryId = String(formData[referenceField] ?? "");
  if (!entryId) return;

  const entry = entryById.get(entryId);
  if (!entry) return;

  let newValue: unknown;
  if (effect.sourceField) {
    newValue = formData[effect.sourceField];
  } else {
    newValue = effect.value;
  }
  if (newValue === undefined || newValue === null) return;

  if (!updates[entryId]) updates[entryId] = {};
  updates[entryId][targetField] = newValue;
}

/**
 * Execute post-submit effects: compute updates and write them
 * atomically to Firestore.
 */
export async function executeEffects(
  userId: string,
  moduleId: string,
  effects: Effect[],
  formData: Record<string, unknown>,
  entries: EntryDoc[],
): Promise<UpdateMap> {
  const updates = computeUpdates(effects, formData, entries);

  if (Object.keys(updates).length === 0) return updates;

  const db = getFirestore();
  const batch = db.batch();

  for (const [entryId, fields] of Object.entries(updates)) {
    const ref = db
      .collection("users").doc(userId)
      .collection("modules").doc(moduleId)
      .collection("entries").doc(entryId);

    const dataUpdates: Record<string, unknown> = {};
    for (const [field, value] of Object.entries(fields)) {
      dataUpdates[`data.${field}`] = value;
    }
    batch.update(ref, dataUpdates);
  }

  await batch.commit();
  return updates;
}
