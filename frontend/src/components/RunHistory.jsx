import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getRuns } from '../api/client';

export default function RunHistory() {
  const { data: runs = [], isLoading, error } = useQuery({
    queryKey: ['runs'],
    queryFn: getRuns,
  });

  const [owaspFilter, setOwaspFilter] = useState('');
  const [strategyFilter, setStrategyFilter] = useState('');
  const [expandedId, setExpandedId] = useState(null);

  if (isLoading) return <p>Loading runs...</p>;
  if (error) return <p>Error loading runs: {error.message}</p>;

  const owaspCategories = [...new Set(runs.map((r) => r.rrAttack?.atOwaspRef).filter(Boolean))];

  const filtered = runs.filter((r) => {
    if (owaspFilter && r.rrAttack?.atOwaspRef !== owaspFilter) return false;
    if (strategyFilter && r.rrStrategy !== strategyFilter) return false;
    return true;
  });

  return (
    <div>
      <h2>Run History</h2>
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '1rem' }}>
        <select value={owaspFilter} onChange={(e) => setOwaspFilter(e.target.value)}>
          <option value="">All OWASP Categories</option>
          {owaspCategories.map((c) => (
            <option key={c} value={c}>{c.replace(/_/g, ' ')}</option>
          ))}
        </select>
        <select value={strategyFilter} onChange={(e) => setStrategyFilter(e.target.value)}>
          <option value="">All Strategies</option>
          <option value="naive">Naive</option>
          <option value="sanitized">Sanitized</option>
        </select>
      </div>

      {filtered.length === 0 ? (
        <p>No runs found.</p>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #ddd', textAlign: 'left' }}>
              <th style={{ padding: '0.5rem' }}>Attack</th>
              <th style={{ padding: '0.5rem' }}>Target</th>
              <th style={{ padding: '0.5rem' }}>Model</th>
              <th style={{ padding: '0.5rem' }}>Strategy</th>
              <th style={{ padding: '0.5rem' }}>Success</th>
              <th style={{ padding: '0.5rem' }}>Confidence</th>
              <th style={{ padding: '0.5rem' }}>Time</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((run) => (
              <>
                <tr
                  key={run.rrRunId}
                  onClick={() => setExpandedId(expandedId === run.rrRunId ? null : run.rrRunId)}
                  style={{ borderBottom: '1px solid #eee', cursor: 'pointer' }}
                >
                  <td style={{ padding: '0.5rem' }}>{run.rrAttack?.atDescription}</td>
                  <td style={{ padding: '0.5rem' }}>{run.rrTarget?.ltName}</td>
                  <td style={{ padding: '0.5rem' }}>{run.rrTarget?.ltModel}</td>
                  <td style={{ padding: '0.5rem' }}>{run.rrStrategy}</td>
                  <td style={{ padding: '0.5rem' }}>{run.rrSuccess == null ? '—' : run.rrSuccess ? '✓' : '✗'}</td>
                  <td style={{ padding: '0.5rem' }}>{run.rrConfidence?.toFixed(2) ?? '—'}</td>
                  <td style={{ padding: '0.5rem' }}>{new Date(run.rrRanAt).toLocaleString()}</td>
                </tr>
                {expandedId === run.rrRunId && (
                  <tr key={`${run.rrRunId}-detail`}>
                    <td colSpan={7} style={{ padding: '1rem', background: '#f9f9f9' }}>
                      <strong>OWASP:</strong> {run.rrAttack?.atOwaspRef}<br />
                      <strong>Payload:</strong> <code>{run.rrAttack?.atPayload}</code><br />
                      <strong>Raw Response:</strong>
                      <pre style={{ whiteSpace: 'pre-wrap', marginTop: '0.5rem' }}>
                        {run.rrRawResponse ?? 'No response (LLM error)'}
                      </pre>
                    </td>
                  </tr>
                )}
              </>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
