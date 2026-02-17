/**
 * In-memory Firestore mock for unit tests.
 * Supports get/set/update/add/collection/doc paths, where() queries,
 * orderBy, limit, and batch writes.
 */

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type DocData = Record<string, any>;

const store: Record<string, DocData> = {};
let autoIdCounter = 0;

/** Reset all data between tests */
export function resetStore() {
  for (const key of Object.keys(store)) delete store[key];
  autoIdCounter = 0;
}

/** Seed a document into the store */
export function seedDoc(path: string, data: DocData) {
  store[path] = {...data};
}

/** Read the raw store (for assertions) */
export function getStore(): Record<string, DocData> {
  return store;
}

function resolve(path: string) {
  return {
    path,
    exists: path in store,
    data: () => store[path] ? {...store[path]} : undefined,
  };
}

// Fake FieldValue
export const FakeFieldValue = {
  serverTimestamp: () => ({_type: "serverTimestamp"}),
  increment: (n: number) => ({_type: "increment", value: n}),
};

// Fake Timestamp
export class FakeTimestamp {
  seconds: number;
  nanoseconds: number;

  constructor(seconds: number, nanoseconds = 0) {
    this.seconds = seconds;
    this.nanoseconds = nanoseconds;
  }

  toDate() {
    return new Date(this.seconds * 1000);
  }
}

function buildDocRef(path: string) {
  return {
    id: path.split("/").pop()!,
    path,
    get: async () => {
      const d = resolve(path);
      return {exists: d.exists, data: () => d.data(), id: d.path.split("/").pop()!};
    },
    set: async (data: DocData) => {
      store[path] = {...data};
    },
    update: async (data: DocData) => {
      if (!(path in store)) throw new Error(`Document ${path} not found`);
      const existing = store[path];
      for (const [key, value] of Object.entries(data)) {
        // Support dot-notation
        if (key.includes(".")) {
          const parts = key.split(".");
          let obj = existing;
          for (let i = 0; i < parts.length - 1; i++) {
            if (!(parts[i] in obj)) obj[parts[i]] = {};
            obj = obj[parts[i]];
          }
          obj[parts[parts.length - 1]] = value;
        } else {
          existing[key] = value;
        }
      }
    },
    collection: (name: string) => buildCollectionRef(`${path}/${name}`),
  };
}

function buildCollectionRef(path: string) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let filters: Array<{field: string; op: string; value: any}> = [];
  let orderField: string | null = null;
  let orderDir: string = "asc";
  let limitCount: number | null = null;

  function buildQuery(): ReturnType<typeof buildCollectionRef> & {
    get: () => Promise<{docs: Array<{id: string; data: () => DocData; exists: boolean}>; size: number}>;
  } {
    return {
      ...buildCollectionRef(path),
      where: (field: string, op: string, value: unknown) => {
        filters.push({field, op, value});
        return buildQuery();
      },
      orderBy: (field: string, dir?: string) => {
        orderField = field;
        orderDir = dir ?? "asc";
        return buildQuery();
      },
      limit: (n: number) => {
        limitCount = n;
        return buildQuery();
      },
      limitToLast: (n: number) => {
        limitCount = n;
        return buildQuery();
      },
      get: async () => {
        // Find all docs in this collection (one level deep)
        const prefix = path + "/";
        const docs = Object.keys(store)
          .filter((k) => {
            if (!k.startsWith(prefix)) return false;
            const rest = k.slice(prefix.length);
            return !rest.includes("/"); // only direct children
          })
          .map((k) => ({
            id: k.split("/").pop()!,
            data: () => ({...store[k]}),
            exists: true,
          }));

        // Apply filters
        let result = docs;
        for (const f of filters) {
          result = result.filter((doc) => {
            const data = doc.data();
            const val = getNestedValue(data, f.field);
            switch (f.op) {
            case "==": return val === f.value;
            case "!=": return val !== f.value;
            case ">": return (val as number) > (f.value as number);
            case "<": return (val as number) < (f.value as number);
            default: return true;
            }
          });
        }

        // Apply orderBy
        if (orderField) {
          const field = orderField;
          result.sort((a, b) => {
            const aVal = getNestedValue(a.data(), field);
            const bVal = getNestedValue(b.data(), field);
            if (aVal < bVal) return orderDir === "asc" ? -1 : 1;
            if (aVal > bVal) return orderDir === "asc" ? 1 : -1;
            return 0;
          });
        }

        // Apply limit
        if (limitCount) {
          result = result.slice(0, limitCount);
        }

        // Reset query state
        filters = [];
        orderField = null;
        limitCount = null;

        return {docs: result, size: result.length};
      },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any;
  }

  return {
    doc: (id?: string) => {
      const docId = id ?? `auto_${++autoIdCounter}`;
      return buildDocRef(`${path}/${docId}`);
    },
    add: async (data: DocData) => {
      const docId = `auto_${++autoIdCounter}`;
      const docPath = `${path}/${docId}`;
      store[docPath] = {...data};
      return {id: docId, path: docPath};
    },
    where: (field: string, op: string, value: unknown) => {
      filters = [{field, op, value}];
      return buildQuery();
    },
    orderBy: (field: string, dir?: string) => {
      orderField = field;
      orderDir = dir ?? "asc";
      return buildQuery();
    },
    limit: (n: number) => {
      limitCount = n;
      return buildQuery();
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    get: async (): Promise<any> => {
      const prefix = path + "/";
      const docs = Object.keys(store)
        .filter((k) => {
          if (!k.startsWith(prefix)) return false;
          const rest = k.slice(prefix.length);
          return !rest.includes("/");
        })
        .map((k) => ({
          id: k.split("/").pop()!,
          data: () => ({...store[k]}),
          exists: true,
        }));
      return {docs, size: docs.length};
    },
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function getNestedValue(obj: any, path: string): any {
  const parts = path.split(".");
  let current = obj;
  for (const part of parts) {
    if (current == null) return undefined;
    current = current[part];
  }
  return current;
}

// Batch mock
function buildBatch() {
  const ops: Array<() => void> = [];
  return {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    update: (ref: any, data: DocData) => {
      ops.push(() => {
        const path = ref.path;
        if (path in store) {
          const existing = store[path];
          for (const [key, value] of Object.entries(data)) {
            if (key.includes(".")) {
              const parts = key.split(".");
              let obj = existing;
              for (let i = 0; i < parts.length - 1; i++) {
                if (!(parts[i] in obj)) obj[parts[i]] = {};
                obj = obj[parts[i]];
              }
              obj[parts[parts.length - 1]] = value;
            } else {
              existing[key] = value;
            }
          }
        }
      });
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    set: (ref: any, data: DocData) => {
      ops.push(() => {
        store[ref.path] = {...data};
      });
    },
    commit: async () => {
      for (const op of ops) op();
    },
  };
}

/** The mock getFirestore() */
export function mockGetFirestore() {
  return {
    collection: (name: string) => buildCollectionRef(name),
    batch: () => buildBatch(),
  };
}
