import Fastify from "fastify";
import pg from "pg";

const fastify = Fastify({
  logger: true,
});

const createMemoryStore = () => {
  const users = [{ id: 1, name: "mike" }];
  return {
    list: async () => users,
    add: async (name) => {
      const user = { id: users.length + 1, name };
      users.push(user);
      return user;
    },
  };
};

const createPostgresStore = async (connectionString) => {
  const pool = new pg.Pool({ connectionString });
  pool.on("error", (err) => fastify.log.error(err));

  // Replicas start together; the advisory lock serializes schema creation and seeding.
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("SELECT pg_advisory_xact_lock(1)");
    await client.query(
      "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)",
    );
    await client.query(
      "INSERT INTO users (name) SELECT 'mike' WHERE NOT EXISTS (SELECT 1 FROM users)",
    );
    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
  return {
    list: async () => (await pool.query("SELECT id, name FROM users ORDER BY id")).rows,
    add: async (name) =>
      (await pool.query("INSERT INTO users (name) VALUES ($1) RETURNING id, name", [name])).rows[0],
  };
};

const store = process.env.DATABASE_URL
  ? await createPostgresStore(process.env.DATABASE_URL)
  : createMemoryStore();

fastify.get("/api/users", async () => store.list());

fastify.post("/api/users", async (req, resp) => {
  const user = await store.add(req.body.name);
  resp.code(201).send(user);
});

fastify.listen({ port: 3000, host: "0.0.0.0" }, (err) => {
  if (err) {
    fastify.log.error(err);
    process.exit(1);
  }
});
