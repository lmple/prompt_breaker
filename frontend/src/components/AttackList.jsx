import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getAttacks, deleteAttack } from '../api/client';
import EditAttackForm from './EditAttackForm';

export default function AttackList() {
  const queryClient = useQueryClient();
  const { data: attacks = [], isLoading } = useQuery({ queryKey: ['attacks'], queryFn: getAttacks });
  const [editingId, setEditingId] = useState(null);
  const [deleteError, setDeleteError] = useState(null);

  const deleteMutation = useMutation({
    mutationFn: deleteAttack,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['attacks'] });
      setDeleteError(null);
    },
    onError: (err) => {
      if (err.message.includes('409')) {
        setDeleteError('Cannot delete attack: it has associated run history.');
      } else if (err.message.includes('404')) {
        setDeleteError('Attack not found.');
      } else {
        setDeleteError(err.message);
      }
    },
  });

  const handleDelete = (attack) => {
    if (!window.confirm(`Delete attack "${attack.atDescription}"? This cannot be undone.`)) return;
    setDeleteError(null);
    deleteMutation.mutate(attack.atId);
  };

  if (isLoading) return <p>Loading attacks...</p>;

  if (attacks.length === 0) {
    return (
      <p style={{ color: '#888', fontStyle: 'italic' }}>
        No attack templates defined yet. Use the "Add new..." button above to create your first attack.
      </p>
    );
  }

  return (
    <>
      {deleteError && <div style={{ color: 'red', marginBottom: '0.5rem' }}>{deleteError}</div>}
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #ddd', textAlign: 'left' }}>
            <th style={{ padding: '0.5rem' }}>Description</th>
            <th style={{ padding: '0.5rem' }}>OWASP Category</th>
            <th style={{ padding: '0.5rem' }}>Technique</th>
            <th style={{ padding: '0.5rem' }}>Created</th>
            <th style={{ padding: '0.5rem' }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {attacks.map((a) =>
            editingId === a.atId ? (
              <tr key={a.atId}>
                <EditAttackForm attack={a} onClose={() => setEditingId(null)} />
              </tr>
            ) : (
              <tr key={a.atId} style={{ borderBottom: '1px solid #eee' }}>
                <td style={{ padding: '0.5rem' }}>{a.atDescription}</td>
                <td style={{ padding: '0.5rem' }}>{a.atCategory}</td>
                <td style={{ padding: '0.5rem' }}>{a.atTechnique ?? '—'}</td>
                <td style={{ padding: '0.5rem' }}>{new Date(a.atCreatedAt).toLocaleDateString()}</td>
                <td style={{ padding: '0.5rem' }}>
                  <button onClick={() => setEditingId(a.atId)} style={{ marginRight: '0.25rem' }}>Edit</button>
                  <button onClick={() => handleDelete(a)}>Delete</button>
                </td>
              </tr>
            )
          )}
        </tbody>
      </table>
    </>
  );
}
