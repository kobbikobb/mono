import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

const getUsers = () => fetch('/api/users').then((res) => res.json());

const addUser = (name) =>
  fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name }),
  }).then((res) => res.json());

export const useUsers = () => useQuery({ queryKey: ['users'], queryFn: getUsers });

export const useAddUser = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: addUser,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
  });
};
