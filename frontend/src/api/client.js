const BASE_URL = 'http://localhost:8080';

async function fetchJSON(url, options = {}) {
  const res = await fetch(`${BASE_URL}${url}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${res.status}: ${text}`);
  }
  return res.json();
}

export const getTargets = () => fetchJSON('/targets');
export const getAttacks = () => fetchJSON('/attacks');
export const getRuns = () => fetchJSON('/runs');
export const getStats = () => fetchJSON('/stats');

export const postTarget = (data) =>
  fetchJSON('/targets', { method: 'POST', body: JSON.stringify(data) });

export const postAttack = (data) =>
  fetchJSON('/attacks', { method: 'POST', body: JSON.stringify(data) });

export const postRun = (data) =>
  fetchJSON('/runs', { method: 'POST', body: JSON.stringify(data) });
