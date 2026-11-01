import { useQuery } from '@tanstack/react-query';
import { getUsers } from './api.js';

export default function UserList() {
  const { data: users = [] } = useQuery({ queryKey: ['users'], queryFn: getUsers });

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
