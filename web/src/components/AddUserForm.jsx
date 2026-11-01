import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { addUser } from '../api/users.js';

export default function AddUserForm() {
  const [name, setName] = useState('');
  const queryClient = useQueryClient();
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
    <form onSubmit={submit}>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" required />
      <button>Add</button>
    </form>
  );
}
