import {getFirestore, Timestamp} from "firebase-admin/firestore";

interface GetModuleSummaryInput {
  moduleId: string;
  schemaKey?: string;
}

export async function getModuleSummary(
  userId: string,
  input: GetModuleSummaryInput,
): Promise<string> {
  const db = getFirestore();
  const {moduleId, schemaKey} = input;

  const moduleRef = db
    .collection("users").doc(userId)
    .collection("modules").doc(moduleId);
  const moduleDoc = await moduleRef.get();

  if (!moduleDoc.exists) {
    return JSON.stringify({error: `Module "${moduleId}" not found.`});
  }

  const moduleData = moduleDoc.data()!;
  const schemas = moduleData.schemas ?? {};

  // Build summary per schema
  const entriesRef = moduleRef.collection("entries");
  let query: FirebaseFirestore.Query = entriesRef;

  if (schemaKey) {
    query = query.where("schemaKey", "==", schemaKey);
  }

  const snapshot = await query.get();

  // Group entries by schema
  const bySchema: Record<string, Array<{
    id: string;
    data: Record<string, unknown>;
    createdAt: string | null;
  }>> = {};

  for (const doc of snapshot.docs) {
    const raw = doc.data();
    const sk = (raw.schemaKey as string) ?? "default";
    if (!bySchema[sk]) bySchema[sk] = [];
    bySchema[sk].push({
      id: doc.id,
      data: raw.data ?? {},
      createdAt: raw.createdAt instanceof Timestamp
        ? raw.createdAt.toDate().toISOString()
        : null,
    });
  }

  // Build summary for each schema
  const schemaSummaries: Record<string, unknown> = {};

  for (const [sk, entries] of Object.entries(bySchema)) {
    const schema = schemas[sk];
    const fields = schema?.fields ?? {};

    // Recent entries (last 5)
    const sorted = entries.sort((a, b) => {
      const aTime = a.createdAt ?? "";
      const bTime = b.createdAt ?? "";
      return bTime.localeCompare(aTime);
    });
    const recent = sorted.slice(0, 5).map((e) => ({
      id: e.id,
      data: e.data,
      createdAt: e.createdAt,
    }));

    // Numeric aggregates
    const numericAggregates: Record<string, {
      sum: number;
      avg: number;
      min: number;
      max: number;
    }> = {};

    for (const [fieldKey, fieldDef] of Object.entries(fields)) {
      const def = fieldDef as Record<string, unknown>;
      if (def.type === "number" || def.type === "currency") {
        const values = entries
          .map((e) => {
            const val = e.data[fieldKey];
            return typeof val === "number" ? val : null;
          })
          .filter((v): v is number => v !== null);

        if (values.length > 0) {
          const sum = values.reduce((a, b) => a + b, 0);
          numericAggregates[fieldKey] = {
            sum,
            avg: Math.round((sum / values.length) * 100) / 100,
            min: Math.min(...values),
            max: Math.max(...values),
          };
        }
      }
    }

    schemaSummaries[sk] = {
      label: schema?.label ?? sk,
      entryCount: entries.length,
      recentEntries: recent,
      ...(Object.keys(numericAggregates).length > 0
        ? {numericAggregates}
        : {}),
    };
  }

  return JSON.stringify({
    moduleName: moduleData.name,
    totalEntries: snapshot.size,
    schemas: schemaSummaries,
  });
}
