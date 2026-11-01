import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

const getUsers = () => fetch('/api/users').then((res) => res.json());

const addUser = (name) =>
  fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name }),
  }).then((res) => res.json());

export default function App() {
  const [name, setName] = useState('');
  const queryClient = useQueryClient();
  const { data: users = [] } = useQuery({ queryKey: ['users'], queryFn: getUsers });
  const { mutate } = useMutation({
    mutationFn: addUser,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
  });

  const submit = (e) => {
    e.preventDefault();
    mutate(name);
    setName('');
  };

  return (
    <>
      <form onSubmit={submit}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" required />
        <button>Add</button>
      </form>
      <ul>
        {users.map((user) => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </>
  );
}
