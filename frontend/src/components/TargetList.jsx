import { useQuery } from '@tanstack/react-query';
import { getTargets } from '../api/client';

export default function TargetList() {
  const { data: targets = [], isLoading } = useQuery({ queryKey: ['targets'], queryFn: getTargets });

  if (isLoading) return <p>Loading targets...</p>;

  if (targets.length === 0) {
    return (
      <p style={{ color: '#888', fontStyle: 'italic' }}>
        No targets registered yet. Use the "Add new..." button above to register your first LLM target.
      </p>
    );
  }

  return (
    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
      <thead>
        <tr style={{ borderBottom: '2px solid #ddd', textAlign: 'left' }}>
          <th style={{ padding: '0.5rem' }}>Name</th>
          <th style={{ padding: '0.5rem' }}>Base URL</th>
          <th style={{ padding: '0.5rem' }}>Model</th>
          <th style={{ padding: '0.5rem' }}>API Key</th>
          <th style={{ padding: '0.5rem' }}>Created</th>
        </tr>
      </thead>
      <tbody>
        {targets.map((t) => (
          <tr key={t.ltId} style={{ borderBottom: '1px solid #eee' }}>
            <td style={{ padding: '0.5rem' }}>{t.ltName}</td>
            <td style={{ padding: '0.5rem' }}>{t.ltBaseUrl}</td>
            <td style={{ padding: '0.5rem' }}>{t.ltModel}</td>
            <td style={{ padding: '0.5rem' }}>{t.ltApiKey ? 'Configured' : 'None'}</td>
            <td style={{ padding: '0.5rem' }}>{new Date(t.ltCreatedAt).toLocaleDateString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
