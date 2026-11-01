import Fastify from "fastify";

const fastify = Fastify({
  logger: true,
});

let id = 0;

const next = () => {
  id = id + 1;
  return id;
};

const users = [
  {
    id: next(),
    name: "mike",
  },
];

fastify.get("/api/users", (req, resp) => {
  resp.send(users);
});

fastify.post("/api/users", (req, resp) => {
  const { name } = req.body;
  const user = { id: next(), name };
  users.push(user);
  resp.code(201).send(user);
});

fastify.listen({ port: 3000, host: "0.0.0.0" }, (err, addr) => {
  if (err) {
    fastify.log.error(err);
    process.exit(1);
  }
});
