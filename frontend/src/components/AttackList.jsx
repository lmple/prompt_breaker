import { useQuery } from '@tanstack/react-query';
import { getAttacks } from '../api/client';

export default function AttackList() {
  const { data: attacks = [], isLoading } = useQuery({ queryKey: ['attacks'], queryFn: getAttacks });

  if (isLoading) return <p>Loading attacks...</p>;

  if (attacks.length === 0) {
    return (
      <p style={{ color: '#888', fontStyle: 'italic' }}>
        No attack templates defined yet. Use the "Add new..." button above to create your first attack.
      </p>
    );
  }

  return (
    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
      <thead>
        <tr style={{ borderBottom: '2px solid #ddd', textAlign: 'left' }}>
          <th style={{ padding: '0.5rem' }}>Description</th>
          <th style={{ padding: '0.5rem' }}>OWASP Category</th>
          <th style={{ padding: '0.5rem' }}>Technique</th>
          <th style={{ padding: '0.5rem' }}>Created</th>
        </tr>
      </thead>
      <tbody>
        {attacks.map((a) => (
          <tr key={a.atId} style={{ borderBottom: '1px solid #eee' }}>
            <td style={{ padding: '0.5rem' }}>{a.atDescription}</td>
            <td style={{ padding: '0.5rem' }}>{a.atCategory}</td>
            <td style={{ padding: '0.5rem' }}>{a.atTechnique ?? '—'}</td>
            <td style={{ padding: '0.5rem' }}>{new Date(a.atCreatedAt).toLocaleDateString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
