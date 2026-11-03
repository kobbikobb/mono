import Fastify from "fastify";
import { createStore } from "./store/index.js";
import { usersRoutes } from "./routes/users.js";

const fastify = Fastify({
  logger: true,
});

const store = await createStore(process.env.DATABASE_URL, fastify.log);
fastify.register(usersRoutes(store));

fastify.listen({ port: 3000, host: "0.0.0.0" }, (err) => {
  if (err) {
    fastify.log.error(err);
    process.exit(1);
  }
});
