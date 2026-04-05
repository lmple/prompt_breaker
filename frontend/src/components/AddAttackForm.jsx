import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { postAttack } from '../api/client';
import { ATTACK_CATEGORIES, JAILBREAK_TECHNIQUES } from '../constants';

export default function AddAttackForm({ onClose }) {
  const queryClient = useQueryClient();
  const [category, setCategory] = useState('');
  const [technique, setTechnique] = useState('');
  const [payload, setPayload] = useState('');
  const [description, setDescription] = useState('');
  const [error, setError] = useState(null);

  const showTechnique = category === 'Jailbreak';
  const selectedCategory = ATTACK_CATEGORIES.find((c) => c.key === category);

  const mutation = useMutation({
    mutationFn: postAttack,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['attacks'] });
      onClose();
    },
    onError: (err) => {
      setError(err.message);
    },
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    setError(null);
    if (!category || !payload.trim() || !description.trim()) {
      setError('Category, Payload, and Description are required.');
      return;
    }
    if (showTechnique && !technique) {
      setError('Technique is required for Jailbreak attacks.');
      return;
    }
    mutation.mutate({
      arCategory: category,
      arTechnique: showTechnique ? technique : null,
      arPayload: payload.trim(),
      arDescription: description.trim(),
      arOwaspRef: selectedCategory.owaspRef,
    });
  };

  return (
    <div style={{ border: '1px solid #ccc', borderRadius: '8px', padding: '1rem', marginTop: '0.5rem', background: '#fafafa' }}>
      <h4 style={{ marginTop: 0 }}>Add New Attack Template</h4>
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        <label>
          Attack Category <span style={{ color: 'red' }}>*</span>
          <select value={category} onChange={(e) => { setCategory(e.target.value); setTechnique(''); }}
            style={{ display: 'block', width: '100%' }}>
            <option value="">Select...</option>
            {ATTACK_CATEGORIES.map((c) => (
              <option key={c.key} value={c.key}>{c.label}</option>
            ))}
          </select>
        </label>
        {showTechnique && (
          <label>
            Jailbreak Technique <span style={{ color: 'red' }}>*</span>
            <select value={technique} onChange={(e) => setTechnique(e.target.value)}
              style={{ display: 'block', width: '100%' }}>
              <option value="">Select...</option>
              {JAILBREAK_TECHNIQUES.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </select>
          </label>
        )}
        <label>
          Payload <span style={{ color: 'red' }}>*</span>
          <textarea value={payload} onChange={(e) => setPayload(e.target.value)}
            rows={4} placeholder="Attack payload text..."
            style={{ display: 'block', width: '100%' }} />
        </label>
        <label>
          Description <span style={{ color: 'red' }}>*</span>
          <input type="text" value={description} onChange={(e) => setDescription(e.target.value)}
            placeholder="Human-readable description of this attack"
            style={{ display: 'block', width: '100%' }} />
        </label>
        {error && <div style={{ color: 'red' }}>{error}</div>}
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button type="submit" disabled={mutation.isPending}>
            {mutation.isPending ? 'Saving...' : 'Save Attack'}
          </button>
          <button type="button" onClick={onClose}>Cancel</button>
        </div>
      </form>
    </div>
  );
}
