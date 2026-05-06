const mode = (process.env.DATA_STORE ?? "sqlite").toLowerCase();

let backendPromise;

export function dataStoreMode() {
  return mode;
}

export async function backend() {
  if (!backendPromise) {
    backendPromise = mode === "tablestore"
      ? import("./tablestoreBackend.mjs")
      : import("./sqliteBackend.mjs");
  }
  return backendPromise;
}
