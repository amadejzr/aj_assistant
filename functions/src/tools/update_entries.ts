import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

interface EntryUpdate {
  entryId: string;
  data: Record<string, unknown>;
}

interface UpdateEntriesInput {
  moduleId: string;
  entries: EntryUpdate[];
}

export async function updateEntries(
  userId: string,
  input: UpdateEntriesInput,
): Promise<string> {
  const db = getFirestore();
  const {moduleId, entries} = input;

  if (!entries || !Array.isArray(entries) || entries.length === 0) {
    return JSON.stringify({error: "entries must be a non-empty array."});
  }

  if (entries.length > 50) {
    return JSON.stringify({error: "Maximum 50 entries per batch."});
  }

  // Load module
  const moduleRef = db
    .collection("users").doc(userId)
    .collection("modules").doc(moduleId);
  const moduleDoc = await moduleRef.get();

  if (!moduleDoc.exists) {
    return JSON.stringify({error: `Module "${moduleId}" not found.`});
  }

  const moduleData = moduleDoc.data()!;
  const schemas = moduleData.schemas ?? {};

  // Validate all entries exist and fields are valid
  const entriesRef = moduleRef.collection("entries");
  const entryDocs: Map<string, FirebaseFirestore.DocumentSnapshot> = new Map();

  for (const entry of entries) {
    const entryDoc = await entriesRef.doc(entry.entryId).get();
    if (!entryDoc.exists) {
      return JSON.stringify({
        error: `Entry "${entry.entryId}" not found.`,
      });
    }
    entryDocs.set(entry.entryId, entryDoc);

    // Validate fields against schema
    const existingData = entryDoc.data()!;
    const schemaKey = existingData.schemaKey ?? "default";
    const schema = schemas[schemaKey];

    if (schema) {
      const schemaFields = schema.fields ?? {};
      const unknownFields = Object.keys(entry.data).filter(
        (key) => !schemaFields[key],
      );
      if (unknownFields.length > 0) {
        return JSON.stringify({
          error: `Entry "${entry.entryId}": unknown fields for ` +
            `schema "${schemaKey}": ${unknownFields.join(", ")}`,
        });
      }
    }
  }

  // Batch update all entries
  try {
    const batch = db.batch();
    for (const entry of entries) {
      const docRef = entriesRef.doc(entry.entryId);
      const updateFields: Record<string, unknown> = {
        updatedAt: FieldValue.serverTimestamp(),
      };
      for (const [key, value] of Object.entries(entry.data)) {
        updateFields[`data.${key}`] = value;
      }
      batch.update(docRef, updateFields);
    }
    await batch.commit();
  } catch (err) {
    return JSON.stringify({
      error: `Failed to update entries: ${(err as Error).message}`,
    });
  }

  logger.info(`Batch updated ${entries.length} entries`, {
    userId, moduleId,
  });

  // Read back one entry for timestamp reference
  const firstRef = entriesRef.doc(entries[0].entryId);
  const firstDoc = await firstRef.get();
  const firstData = firstDoc.data();
  const updatedAt = firstData?.updatedAt instanceof Timestamp
    ? firstData.updatedAt.toDate().toISOString()
    : new Date().toISOString();

  return JSON.stringify({
    updated: entries.length,
    ids: entries.map((e) => e.entryId),
    updatedAt,
  });
}
