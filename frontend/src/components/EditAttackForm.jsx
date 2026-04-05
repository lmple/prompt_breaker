import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { putAttack } from '../api/client';
import { ATTACK_CATEGORIES, JAILBREAK_TECHNIQUES } from '../constants';

export default function EditAttackForm({ attack, onClose }) {
  const queryClient = useQueryClient();
  const [category, setCategory] = useState(attack.atCategory);
  const [technique, setTechnique] = useState(attack.atTechnique || '');
  const [payload, setPayload] = useState(attack.atPayload);
  const [description, setDescription] = useState(attack.atDescription);
  const [error, setError] = useState(null);

  const showTechnique = category === 'Jailbreak';
  const selectedCategory = ATTACK_CATEGORIES.find((c) => c.key === category);

  const mutation = useMutation({
    mutationFn: (data) => putAttack(attack.atId, data),
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

  const handleCategoryChange = (newCategory) => {
    setCategory(newCategory);
    if (newCategory !== 'Jailbreak') {
      setTechnique('');
    }
  };

  return (
    <td colSpan={5} style={{ padding: '0.5rem' }}>
      <div style={{ border: '1px solid #ccc', borderRadius: '8px', padding: '1rem', background: '#fafafa' }}>
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          <label>
            Attack Category <span style={{ color: 'red' }}>*</span>
            <select value={category} onChange={(e) => handleCategoryChange(e.target.value)}
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
              rows={4} style={{ display: 'block', width: '100%' }} />
          </label>
          <label>
            Description <span style={{ color: 'red' }}>*</span>
            <input type="text" value={description} onChange={(e) => setDescription(e.target.value)}
              style={{ display: 'block', width: '100%' }} />
          </label>
          {error && <div style={{ color: 'red' }}>{error}</div>}
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? 'Saving...' : 'Save'}
            </button>
            <button type="button" onClick={onClose}>Cancel</button>
          </div>
        </form>
      </div>
    </td>
  );
}
