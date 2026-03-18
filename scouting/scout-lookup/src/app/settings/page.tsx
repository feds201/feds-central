"use client";

import { useState, useEffect } from 'react';

export default function SettingsPage() {
  const [config, setConfig] = useState({
    neonUrl: '',
    matchTable: '',
    pitTable: '',
    tbaKey: ''
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    fetch('/api/settings')
      .then(res => res.json())
      .then(data => {
        setConfig({
          neonUrl: data.neonUrl || '',
          matchTable: data.matchTable || '',
          pitTable: data.pitTable || '',
          tbaKey: data.tbaKey || ''
        });
        setLoading(false);
      });
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage('');
    try {
      const res = await fetch('/api/settings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config)
      });
      if (res.ok) {
        setMessage('Settings saved successfully!');
      } else {
        setMessage('Failed to save settings.');
      }
    } catch (err) {
      setMessage('An error occurred.');
    }
    setSaving(false);
  };

  if (loading) return <div className="flex justify-center my-8"><div className="spinner"></div></div>;

  return (
    <div>
      <h1 className="mb-4">Configuration</h1>
      <p className="mb-8" style={{ color: 'var(--foreground-muted)' }}>
        Configure the database connection and external APIs to power Scout Ops LookUp.
      </p>

      <form onSubmit={handleSave} className="card flex flex-col gap-4">
        <div>
          <label className="flex flex-col gap-2">
            <strong>Neon Postgres Connection String</strong>
            <input 
              type="password"
              placeholder="postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require"
              value={config.neonUrl}
              onChange={e => setConfig({...config, neonUrl: e.target.value})}
              required
            />
          </label>
        </div>

        <div>
          <label className="flex flex-col gap-2">
            <strong>Match Scouting Table Name</strong>
            <input 
              type="text"
              placeholder="e.g. match_data_2025"
              value={config.matchTable}
              onChange={e => setConfig({...config, matchTable: e.target.value})}
            />
          </label>
        </div>

        <div>
          <label className="flex flex-col gap-2">
            <strong>Pit Scouting Table Name</strong>
            <input 
              type="text"
              placeholder="e.g. pit_data_2025"
              value={config.pitTable}
              onChange={e => setConfig({...config, pitTable: e.target.value})}
            />
          </label>
        </div>

        <div>
          <label className="flex flex-col gap-2">
            <strong>The Blue Alliance (TBA) API Key</strong>
            <input 
              type="password"
              placeholder="TBA Read API Key"
              value={config.tbaKey}
              onChange={e => setConfig({...config, tbaKey: e.target.value})}
            />
          </label>
        </div>

        <button type="submit" disabled={saving}>
          {saving ? 'Saving...' : 'Save Settings'}
        </button>

        {message && <p style={{ color: 'var(--primary)', marginTop: '1rem' }}>{message}</p>}
      </form>
    </div>
  );
}