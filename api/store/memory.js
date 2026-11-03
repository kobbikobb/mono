export const createMemoryStore = () => {
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
