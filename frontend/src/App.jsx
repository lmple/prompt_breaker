import { useState } from 'react';
import Dashboard from './components/Dashboard';
import AttackBuilder from './components/AttackBuilder';
import RunHistory from './components/RunHistory';

const TABS = [
  { id: 'dashboard', label: 'Dashboard', component: Dashboard },
  { id: 'builder', label: 'Attack Builder', component: AttackBuilder },
  { id: 'history', label: 'Run History', component: RunHistory },
];

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const ActiveComponent = TABS.find((t) => t.id === activeTab)?.component ?? Dashboard;

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '1rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1 style={{ marginBottom: '0.5rem' }}>Attack Harness</h1>
      <p style={{ color: '#666', marginBottom: '1.5rem' }}>LLM Prompt Injection Research Tool</p>
      <nav style={{ display: 'flex', gap: '0.5rem', marginBottom: '2rem', borderBottom: '2px solid #eee', paddingBottom: '0.5rem' }}>
        {TABS.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              padding: '0.5rem 1rem',
              border: 'none',
              borderRadius: '4px 4px 0 0',
              cursor: 'pointer',
              background: activeTab === tab.id ? '#333' : '#eee',
              color: activeTab === tab.id ? '#fff' : '#333',
              fontWeight: activeTab === tab.id ? 'bold' : 'normal',
            }}
          >
            {tab.label}
          </button>
        ))}
      </nav>
      <ActiveComponent />
    </div>
  );
}
