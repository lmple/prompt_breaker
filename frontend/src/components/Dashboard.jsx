import { useQuery } from '@tanstack/react-query';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { getStats } from '../api/client';

export default function Dashboard() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['stats'],
    queryFn: getStats,
  });

  if (isLoading) return <p>Loading stats...</p>;
  if (error) return <p>Error loading stats: {error.message}</p>;

  const categories = (data?.byCategory ?? []).map(([name, stats]) => ({
    name: name.replace(/_/g, ' '),
    'Naive Rate': +(stats.csNaiveSuccessRate * 100).toFixed(1),
    'Sanitized Rate': +(stats.csSanitizedSuccessRate * 100).toFixed(1),
    totalRuns: stats.csTotalRuns,
  }));

  const totalRuns = categories.reduce((sum, c) => sum + c.totalRuns, 0);
  const avgNaive = categories.length
    ? (categories.reduce((s, c) => s + c['Naive Rate'], 0) / categories.length).toFixed(1)
    : 0;
  const avgSanitized = categories.length
    ? (categories.reduce((s, c) => s + c['Sanitized Rate'], 0) / categories.length).toFixed(1)
    : 0;
  const mostVulnerable = categories.length
    ? categories.reduce((a, b) => (a['Naive Rate'] > b['Naive Rate'] ? a : b)).name
    : 'N/A';

  return (
    <div>
      <h2>Dashboard</h2>
      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', flexWrap: 'wrap' }}>
        <SummaryCard label="Total Runs" value={totalRuns} />
        <SummaryCard label="Avg Naive Rate" value={`${avgNaive}%`} />
        <SummaryCard label="Avg Sanitized Rate" value={`${avgSanitized}%`} />
        <SummaryCard label="Most Vulnerable" value={mostVulnerable} />
      </div>
      {categories.length === 0 ? (
        <p>No run data yet. Execute some attacks to see results.</p>
      ) : (
        <ResponsiveContainer width="100%" height={400}>
          <BarChart data={categories}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" tick={{ fontSize: 12 }} />
            <YAxis label={{ value: 'Success Rate (%)', angle: -90, position: 'insideLeft' }} />
            <Tooltip />
            <Legend />
            <Bar dataKey="Naive Rate" fill="#e74c3c" />
            <Bar dataKey="Sanitized Rate" fill="#2ecc71" />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

function SummaryCard({ label, value }) {
  return (
    <div style={{
      padding: '1rem 1.5rem', border: '1px solid #ddd', borderRadius: '8px',
      minWidth: '150px', textAlign: 'center',
    }}>
      <div style={{ fontSize: '0.85rem', color: '#666' }}>{label}</div>
      <div style={{ fontSize: '1.5rem', fontWeight: 'bold', marginTop: '0.25rem' }}>{value}</div>
    </div>
  );
}
