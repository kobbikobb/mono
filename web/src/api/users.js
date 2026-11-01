import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

const json = (res) => {
  if (!res.ok) throw new Error(`Request failed: ${res.status}`);
  return res.json();
};

const getUsers = () => fetch('/api/users').then(json);

const addUser = (name) =>
  fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name }),
  }).then(json);

export const useUsers = () => useQuery({ queryKey: ['users'], queryFn: getUsers });

export const useAddUser = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: addUser,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
  });
};
