import { useState } from 'react';
import { useAddUser } from '../api/users.js';

export default function AddUserForm() {
  const [name, setName] = useState('');
  const { mutate } = useAddUser();

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
