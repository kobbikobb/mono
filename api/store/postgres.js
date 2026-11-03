import pg from "pg";
import * as queries from "./queries.js";

export const createPostgresStore = async (connectionString, log) => {
  const pool = new pg.Pool({ connectionString });
  pool.on("error", (err) => log.error(err));

  // Replicas start together; the advisory lock serializes schema creation and seeding.
  const client = await pool.connect();
  let broken = false;
  try {
    await client.query("BEGIN");
    await client.query("SELECT pg_advisory_xact_lock(1)");
    await client.query(queries.createUsersTable);
    await client.query(queries.seedUsers);
    await client.query("COMMIT");
  } catch (err) {
    // Keep the original error even if the rollback fails (e.g. a dropped connection).
    await client.query("ROLLBACK").catch(() => {
      broken = true;
    });
    throw err;
  } finally {
    client.release(broken);
  }

  return {
    list: async () => (await pool.query(queries.listUsers)).rows,
    add: async (name) => (await pool.query(queries.insertUser, [name])).rows[0],
  };
};
