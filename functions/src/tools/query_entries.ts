import {getFirestore, Timestamp} from "firebase-admin/firestore";

interface Filter {
  field: string;
  op: string;
  value: unknown;
}

interface QueryEntriesInput {
  moduleId: string;
  schemaKey?: string;
  filters?: Filter[];
  orderBy?: string;
  limit?: number;
}

function serializeTimestamps(
  data: Record<string, unknown>,
): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(data)) {
    if (value instanceof Timestamp) {
      result[key] = value.toDate().toISOString();
    } else {
      result[key] = value;
    }
  }
  return result;
}

export async function queryEntries(
  userId: string,
  input: QueryEntriesInput,
): Promise<string> {
  const db = getFirestore();
  const {moduleId, schemaKey, filters, orderBy} = input;
  const limit = Math.min(input.limit ?? 20, 50);

  // Verify module exists
  const moduleRef = db
    .collection("users").doc(userId)
    .collection("modules").doc(moduleId);
  const moduleDoc = await moduleRef.get();

  if (!moduleDoc.exists) {
    return JSON.stringify({error: `Module "${moduleId}" not found.`});
  }

  let query: FirebaseFirestore.Query = moduleRef.collection("entries");

  // Filter by schema key
  if (schemaKey) {
    query = query.where("schemaKey", "==", schemaKey);
  }

  // Apply filters on data fields
  // NOTE: Firestore compound queries may require indexes.
  // We apply one Firestore where() for the first filter and
  // do the rest in-memory to avoid index requirements.
  const firestoreFilters = filters ?? [];
  let firstFilter = true;
  const inMemoryFilters: Filter[] = [];

  for (const filter of firestoreFilters) {
    const firestoreOp = filter.op as FirebaseFirestore.WhereFilterOp;
    if (firstFilter && !schemaKey) {
      // Can use Firestore filter directly
      query = query.where(`data.${filter.field}`, firestoreOp, filter.value);
      firstFilter = false;
    } else {
      inMemoryFilters.push(filter);
    }
  }

  // Order
  if (orderBy) {
    query = query.orderBy(`data.${orderBy}`, "desc");
  } else {
    query = query.orderBy("createdAt", "desc");
  }

  // Fetch more than limit if we have in-memory filters
  const fetchLimit = inMemoryFilters.length > 0 ? limit * 3 : limit;
  query = query.limit(fetchLimit);

  const snapshot = await query.get();

  let entries = snapshot.docs.map((doc) => {
    const raw = doc.data();
    return {
      id: doc.id,
      schemaKey: raw.schemaKey ?? "default",
      data: serializeTimestamps(raw.data ?? {}),
      createdAt: raw.createdAt instanceof Timestamp
        ? raw.createdAt.toDate().toISOString()
        : null,
    };
  });

  // Apply in-memory filters
  for (const filter of inMemoryFilters) {
    entries = entries.filter((entry) => {
      const val = entry.data[filter.field];
      const expected = filter.value;
      switch (filter.op) {
      case "==": return val === expected;
      case "!=": return val !== expected;
      case ">": return (val as number) > (expected as number);
      case "<": return (val as number) < (expected as number);
      case ">=": return (val as number) >= (expected as number);
      case "<=": return (val as number) <= (expected as number);
      default: return true;
      }
    });
  }

  // Apply final limit
  entries = entries.slice(0, limit);

  return JSON.stringify({
    count: entries.length,
    entries,
  });
}
