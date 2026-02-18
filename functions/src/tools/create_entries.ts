import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

interface EntryData {
  data: Record<string, unknown>;
}

interface CreateEntriesInput {
  moduleId: string;
  schemaKey: string;
  entries: EntryData[];
}

export async function createEntries(
  userId: string,
  input: CreateEntriesInput,
): Promise<string> {
  const db = getFirestore();
  const {moduleId, schemaKey, entries} = input;

  if (!entries || !Array.isArray(entries) || entries.length === 0) {
    return JSON.stringify({error: "entries must be a non-empty array."});
  }

  if (entries.length > 50) {
    return JSON.stringify({error: "Maximum 50 entries per batch."});
  }

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

  // Validate required fields for each entry
  const fields = schema.fields ?? {};
  const requiredKeys: string[] = [];
  for (const [key, field] of Object.entries(fields)) {
    const fieldDef = field as Record<string, unknown>;
    if (fieldDef.required) {
      requiredKeys.push(key);
    }
  }

  for (let i = 0; i < entries.length; i++) {
    const entryData = entries[i].data ?? {};
    const missing = requiredKeys.filter(
      (key) => entryData[key] === undefined || entryData[key] === null,
    );
    if (missing.length > 0) {
      return JSON.stringify({
        error: `Entry ${i + 1}: missing required fields: ${missing.join(", ")}`,
      });
    }
  }

  // Batch write all entries
  const entriesRef = moduleRef.collection("entries");
  const schemaVersion = schema.version ?? 1;
  const createdIds: string[] = [];

  try {
    const batch = db.batch();
    for (const entry of entries) {
      const docRef = entriesRef.doc();
      batch.set(docRef, {
        data: entry.data,
        schemaKey,
        schemaVersion,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      createdIds.push(docRef.id);
    }
    await batch.commit();
  } catch (err) {
    return JSON.stringify({
      error: `Failed to write entries: ${(err as Error).message}`,
    });
  }

  logger.info(`Batch created ${entries.length} entries`, {
    userId, moduleId, schemaKey,
  });

  // Read back one entry for timestamp reference
  const firstDoc = await entriesRef.doc(createdIds[0]).get();
  const firstData = firstDoc.data();
  const createdAt = firstData?.createdAt instanceof Timestamp
    ? firstData.createdAt.toDate().toISOString()
    : new Date().toISOString();

  return JSON.stringify({
    created: createdIds.length,
    ids: createdIds,
    schemaKey,
    createdAt,
  });
}
