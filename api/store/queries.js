export const createUsersTable =
  "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)";
export const seedUsers =
  "INSERT INTO users (name) SELECT 'mike' WHERE NOT EXISTS (SELECT 1 FROM users)";
export const listUsers = "SELECT id, name FROM users ORDER BY id";
export const insertUser = "INSERT INTO users (name) VALUES ($1) RETURNING id, name";
