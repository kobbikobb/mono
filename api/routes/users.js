export const usersRoutes = (store) => async (fastify) => {
  fastify.get("/api/users", () => store.list());

  fastify.post("/api/users", async (req, resp) => {
    const user = await store.add(req.body.name);
    resp.code(201).send(user);
  });
};
