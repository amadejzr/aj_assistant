import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {executeEffects} from "../effects/post_submit_effect_executor.js";

interface UpdateEntryInput {
  moduleId: string;
  entryId: string;
  data: Record<string, unknown>;
}

export async function updateEntry(
  userId: string,
  input: UpdateEntryInput,
): Promise<string> {
  const db = getFirestore();
  const {moduleId, entryId, data} = input;

  const moduleRef = db
    .collection("users").doc(userId)
    .collection("modules").doc(moduleId);
  const moduleDoc = await moduleRef.get();

  if (!moduleDoc.exists) {
    return JSON.stringify({error: `Module "${moduleId}" not found.`});
  }

  const entryRef = moduleRef.collection("entries").doc(entryId);
  const entryDoc = await entryRef.get();

  if (!entryDoc.exists) {
    return JSON.stringify({error: `Entry "${entryId}" not found.`});
  }

  const existingData = entryDoc.data()!;
  const schemaKey = existingData.schemaKey ?? "default";

  // Validate fields against schema
  const moduleData = moduleDoc.data()!;
  const schemas = moduleData.schemas ?? {};
  const schema = schemas[schemaKey];

  if (schema) {
    const schemaFields = schema.fields ?? {};
    const unknownFields = Object.keys(data).filter(
      (key) => !schemaFields[key],
    );
    if (unknownFields.length > 0) {
      return JSON.stringify({
        error: `Unknown fields for schema "${schemaKey}": ` +
          unknownFields.join(", "),
      });
    }
  }

  // Merge update into data using dot-notation for partial update
  const updateFields: Record<string, unknown> = {
    "updatedAt": FieldValue.serverTimestamp(),
  };
  for (const [key, value] of Object.entries(data)) {
    updateFields[`data.${key}`] = value;
  }

  await entryRef.update(updateFields);

  // Execute onSubmit effects for the changed fields
  const mergedData = {...(existingData.data ?? {}), ...data};
  const screens = moduleData.screens ?? {};
  for (const screen of Object.values(screens)) {
    const screenDef = screen as Record<string, unknown>;
    const onSubmit = screenDef.onSubmit as Record<string, unknown>[] | undefined;
    if (onSubmit && Array.isArray(onSubmit)) {
      const entriesSnap = await moduleRef.collection("entries").get();
      const entries = entriesSnap.docs.map((doc) => ({
        id: doc.id,
        data: (doc.data().data ?? {}) as Record<string, unknown>,
      }));
      await executeEffects(
        userId, moduleId, onSubmit as never[],
        mergedData as Record<string, unknown>, entries,
      );
      break;
    }
  }

  // Read back updated entry
  const updated = await entryRef.get();
  const updatedRaw = updated.data()!;
  const updatedAt = updatedRaw.updatedAt instanceof Timestamp
    ? updatedRaw.updatedAt.toDate().toISOString()
    : new Date().toISOString();

  return JSON.stringify({
    id: entryId,
    schemaKey,
    data: {...(updatedRaw.data ?? {})},
    updatedAt,
  });
}
