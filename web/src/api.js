export const getUsers = () => fetch('/api/users').then((res) => res.json());

export const addUser = (name) =>
  fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name }),
  }).then((res) => res.json());
