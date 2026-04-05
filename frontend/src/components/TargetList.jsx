import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getTargets, deleteTarget } from '../api/client';
import EditTargetForm from './EditTargetForm';

export default function TargetList() {
  const queryClient = useQueryClient();
  const { data: targets = [], isLoading } = useQuery({ queryKey: ['targets'], queryFn: getTargets });
  const [editingId, setEditingId] = useState(null);
  const [deleteError, setDeleteError] = useState(null);

  const deleteMutation = useMutation({
    mutationFn: deleteTarget,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['targets'] });
      setDeleteError(null);
    },
    onError: (err) => {
      if (err.message.includes('409')) {
        setDeleteError('Cannot delete target: it has associated run history.');
      } else if (err.message.includes('404')) {
        setDeleteError('Target not found.');
      } else {
        setDeleteError(err.message);
      }
    },
  });

  const handleDelete = (target) => {
    if (!window.confirm(`Delete target "${target.ltName}"? This cannot be undone.`)) return;
    setDeleteError(null);
    deleteMutation.mutate(target.ltId);
  };

  if (isLoading) return <p>Loading targets...</p>;

  if (targets.length === 0) {
    return (
      <p style={{ color: '#888', fontStyle: 'italic' }}>
        No targets registered yet. Use the "Add new..." button above to register your first LLM target.
      </p>
    );
  }

  return (
    <>
      {deleteError && <div style={{ color: 'red', marginBottom: '0.5rem' }}>{deleteError}</div>}
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #ddd', textAlign: 'left' }}>
            <th style={{ padding: '0.5rem' }}>Name</th>
            <th style={{ padding: '0.5rem' }}>Base URL</th>
            <th style={{ padding: '0.5rem' }}>Model</th>
            <th style={{ padding: '0.5rem' }}>API Key</th>
            <th style={{ padding: '0.5rem' }}>Created</th>
            <th style={{ padding: '0.5rem' }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {targets.map((t) =>
            editingId === t.ltId ? (
              <tr key={t.ltId}>
                <EditTargetForm target={t} onClose={() => setEditingId(null)} />
              </tr>
            ) : (
              <tr key={t.ltId} style={{ borderBottom: '1px solid #eee' }}>
                <td style={{ padding: '0.5rem' }}>{t.ltName}</td>
                <td style={{ padding: '0.5rem' }}>{t.ltBaseUrl}</td>
                <td style={{ padding: '0.5rem' }}>{t.ltModel}</td>
                <td style={{ padding: '0.5rem' }}>{t.ltApiKey ? 'Configured' : 'None'}</td>
                <td style={{ padding: '0.5rem' }}>{new Date(t.ltCreatedAt).toLocaleDateString()}</td>
                <td style={{ padding: '0.5rem' }}>
                  <button onClick={() => setEditingId(t.ltId)} style={{ marginRight: '0.25rem' }}>Edit</button>
                  <button onClick={() => handleDelete(t)}>Delete</button>
                </td>
              </tr>
            )
          )}
        </tbody>
      </table>
    </>
  );
}
