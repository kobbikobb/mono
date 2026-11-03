import { createMemoryStore } from "./memory.js";
import { createPostgresStore } from "./postgres.js";

export const createStore = (databaseUrl, log) =>
  databaseUrl ? createPostgresStore(databaseUrl, log) : createMemoryStore();
