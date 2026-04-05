import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { postTarget } from '../api/client';

export default function AddTargetForm({ onClose }) {
  const queryClient = useQueryClient();
  const [name, setName] = useState('');
  const [baseUrl, setBaseUrl] = useState('');
  const [model, setModel] = useState('');
  const [apiKey, setApiKey] = useState('');
  const [error, setError] = useState(null);

  const mutation = useMutation({
    mutationFn: postTarget,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['targets'] });
      onClose();
    },
    onError: (err) => {
      setError(err.message);
    },
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    setError(null);
    if (!name.trim() || !baseUrl.trim() || !model.trim()) {
      setError('Name, Base URL, and Model are required.');
      return;
    }
    mutation.mutate({
      ltrName: name.trim(),
      ltrBaseUrl: baseUrl.trim(),
      ltrModel: model.trim(),
      ltrApiKey: apiKey.trim() || null,
    });
  };

  return (
    <div style={{ border: '1px solid #ccc', borderRadius: '8px', padding: '1rem', marginTop: '0.5rem', background: '#fafafa' }}>
      <h4 style={{ marginTop: 0 }}>Add New LLM Target</h4>
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        <label>
          Name <span style={{ color: 'red' }}>*</span>
          <input type="text" value={name} onChange={(e) => setName(e.target.value)}
            placeholder="e.g. Local Ollama" style={{ display: 'block', width: '100%' }} />
        </label>
        <label>
          Base URL <span style={{ color: 'red' }}>*</span>
          <input type="text" value={baseUrl} onChange={(e) => setBaseUrl(e.target.value)}
            placeholder="e.g. http://localhost:11434" style={{ display: 'block', width: '100%' }} />
        </label>
        <label>
          Model <span style={{ color: 'red' }}>*</span>
          <input type="text" value={model} onChange={(e) => setModel(e.target.value)}
            placeholder="e.g. llama3" style={{ display: 'block', width: '100%' }} />
        </label>
        <label>
          API Key
          <input type="password" value={apiKey} onChange={(e) => setApiKey(e.target.value)}
            placeholder="Optional" style={{ display: 'block', width: '100%' }} />
        </label>
        {error && <div style={{ color: 'red' }}>{error}</div>}
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button type="submit" disabled={mutation.isPending}>
            {mutation.isPending ? 'Saving...' : 'Save Target'}
          </button>
          <button type="button" onClick={onClose}>Cancel</button>
        </div>
      </form>
    </div>
  );
}
