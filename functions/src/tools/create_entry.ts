import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import {executeEffects} from "../effects/post_submit_effect_executor.js";

interface CreateEntryInput {
  moduleId: string;
  schemaKey: string;
  data: Record<string, unknown>;
}

export async function createEntry(
  userId: string,
  input: CreateEntryInput,
): Promise<string> {
  const db = getFirestore();
  const {moduleId, schemaKey, data} = input;

  // Load module to validate schema
  const moduleRef = db
    .collection("users").doc(userId)
    .collection("modules").doc(moduleId);
  const moduleDoc = await moduleRef.get();

  if (!moduleDoc.exists) {
    return JSON.stringify({error: `Module "${moduleId}" not found.`});
  }

  const moduleData = moduleDoc.data()!;
  const schemas = moduleData.schemas ?? {};
  const schema = schemas[schemaKey];

  if (!schema) {
    const available = Object.keys(schemas).join(", ");
    return JSON.stringify({
      error: `Schema "${schemaKey}" not found. Available: ${available}`,
    });
  }

  // Validate required fields
  const fields = schema.fields ?? {};
  const missing: string[] = [];
  for (const [key, field] of Object.entries(fields)) {
    const fieldDef = field as Record<string, unknown>;
    if (fieldDef.required && (data[key] === undefined || data[key] === null)) {
      missing.push(key);
    }
  }
  if (missing.length > 0) {
    return JSON.stringify({
      error: `Missing required fields: ${missing.join(", ")}`,
    });
  }

  // Create the entry
  const entriesRef = moduleRef.collection("entries");
  const entryDoc = entriesRef.doc();

  await entryDoc.set({
    data,
    schemaKey,
    schemaVersion: schema.version ?? 1,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Execute onSubmit effects from the form screen if any exist
  // Look for onSubmit effects in the module's screens
  const screens = moduleData.screens ?? {};
  for (const screen of Object.values(screens)) {
    const screenDef = screen as Record<string, unknown>;
    const onSubmit = screenDef.onSubmit as Record<string, unknown>[] | undefined;
    if (onSubmit && Array.isArray(onSubmit)) {
      // Fetch current entries for effect computation
      const entriesSnap = await entriesRef.get();
      const entries = entriesSnap.docs.map((doc) => ({
        id: doc.id,
        data: (doc.data().data ?? {}) as Record<string, unknown>,
      }));
      await executeEffects(userId, moduleId, onSubmit as never[], data, entries);
      break;
    }
  }

  // Read back for timestamp
  const created = await entryDoc.get();
  const createdData = created.data()!;
  const createdAt = createdData.createdAt instanceof Timestamp
    ? createdData.createdAt.toDate().toISOString()
    : new Date().toISOString();

  return JSON.stringify({
    id: entryDoc.id,
    schemaKey,
    data,
    createdAt,
  });
}
