"use client";

import { useState, useEffect } from 'react';
import Link from 'next/link';

export default function TeamsPage() {
  const [teams, setTeams] = useState<string[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/teams')
      .then(res => res.json())
      .then(data => {
        if (data.teams) {
          setTeams(data.teams);
        }
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const filteredTeams = teams.filter(t => t.includes(search));

  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <h1>Teams Directory</h1>
      </div>

      <div className="card mb-8">
        <input 
          type="text" 
          placeholder="Search for a team number..." 
          value={search}
          onChange={e => setSearch(e.target.value)}
          style={{ fontSize: '1.25rem', padding: '1rem' }}
        />
      </div>

      {loading ? (
        <div className="flex justify-center my-8"><div className="spinner"></div></div>
      ) : (
        <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))' }}>
          {filteredTeams.map(team => (
            <Link key={team} href={`/teams/${team}`}>
              <div className="card flex flex-col items-center gap-2" style={{ cursor: 'pointer', transition: 'transform 0.2s', border: '1px solid var(--border)' }}>
                <span style={{ fontSize: '2.5rem', fontWeight: 'bold', color: 'var(--primary)' }}>{team}</span>
                <span style={{ color: 'var(--foreground-muted)' }}>View Profile</span>
              </div>
            </Link>
          ))}
          {filteredTeams.length === 0 && !loading && (
            <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '2rem', color: 'var(--foreground-muted)' }}>
              No teams found. Make sure you have synced data and configured the database in Settings.
            </div>
          )}
        </div>
      )}
    </div>
  );
}