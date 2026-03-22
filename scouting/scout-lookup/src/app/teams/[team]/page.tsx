"use client";

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';

export default function TeamProfilePage() {
  const { team } = useParams();
  
  const [dbData, setDbData] = useState<any>(null);
  const [tbaData, setTbaData] = useState<any>(null);
  const [statboticsData, setStatboticsData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchData() {
      try {
        // Fetch internal db data (pit & match) and config (for TBA key)
        const [dbRes, configRes] = await Promise.all([
          fetch(`/api/teams/${team}`),
          fetch('/api/settings')
        ]);
        const dbJson = await dbRes.json();
        const configJson = await configRes.json();
        
        setDbData(dbJson);

        // Fetch Statbotics (public API, no auth needed)
        try {
          const statRes = await fetch(`https://api.statbotics.io/v3/team/${team}`);
          if (statRes.ok) {
            setStatboticsData(await statRes.json());
          }
        } catch (e) {}

        // Fetch TBA Data if key exists
        if (configJson.tbaKey && configJson.tbaKey !== '••••••••••••••••') {
          try {
            const tbaRes = await fetch(`https://www.thebluealliance.com/api/v3/team/frc${team}`, {
              headers: { 'X-TBA-Auth-Key': configJson.tbaKey }
            });
            if (tbaRes.ok) {
              setTbaData(await tbaRes.json());
            }
          } catch (e) {}
        }
      } catch (e) {
        console.error("Failed to fetch team data", e);
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, [team]);

  if (loading) return <div className="flex justify-center my-8"><div className="spinner"></div></div>;

  const pit = dbData?.pitData;
  const matches = dbData?.matchData || [];

  return (
    <div className="flex flex-col gap-8">
      {/* Header Card */}
      <div className="card flex flex-col md:flex-row justify-between items-center gap-4" style={{ borderTop: '4px solid var(--primary)' }}>
        <div>
          <h1 style={{ fontSize: '3rem', margin: 0 }}>Team {team}</h1>
          <h2 style={{ color: 'var(--foreground-muted)', fontWeight: 400 }}>
            {tbaData?.nickname || statboticsData?.name || 'Unknown Name'}
          </h2>
          {tbaData?.city && (
            <p className="mt-4">{tbaData.city}, {tbaData.state_prov}, {tbaData.country}</p>
          )}
        </div>
        
        {statboticsData && (
          <div className="flex gap-4">
            <div className="card" style={{ background: 'rgba(74, 144, 226, 0.1)', border: '1px solid var(--primary)' }}>
              <div style={{ fontSize: '0.875rem', textTransform: 'uppercase', color: 'var(--foreground-muted)' }}>Normalized EPA</div>
              <div style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--primary)' }}>
                {typeof statboticsData.norm_epa?.current === 'number' 
                  ? statboticsData.norm_epa.current.toFixed(0) 
                  : 'N/A'}
              </div>
            </div>
            <div className="card" style={{ background: 'rgba(255, 64, 129, 0.1)', border: '1px solid var(--accent)' }}>
              <div style={{ fontSize: '0.875rem', textTransform: 'uppercase', color: 'var(--foreground-muted)' }}>Win Rate</div>
              <div style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--accent)' }}>
                {typeof statboticsData.record?.winrate === 'number' 
                  ? (statboticsData.record.winrate * 100).toFixed(1) + '%' 
                  : 'N/A'}
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))' }}>
        {/* Pit Scouting Data */}
        <div className="card">
          <div className="flex justify-between items-center mb-4">
            <h2 style={{ color: 'var(--primary)', margin: 0 }}>Pit Scouting</h2>
          </div>
          {pit ? (
            <div className="flex flex-col gap-2">
              {Object.entries(pit)
                .filter(([k, v]) => !['team', 'teamNumber', 'id', 'botImageId1', 'botImageId2', 'botImageId3', 'timestamp'].includes(k))
                .map(([key, value]) => (
                <div key={key} className="flex justify-between" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '0.5rem' }}>
                  <span style={{ color: 'var(--foreground-muted)', textTransform: 'capitalize' }}>{key.replace(/([A-Z])/g, ' $1').replace(/_/g, ' ')}</span>
                  <span style={{ fontWeight: 500, textAlign: 'right' }}>{String(value)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div style={{ padding: '2rem', textAlign: 'center', background: 'rgba(255,255,255,0.02)', borderRadius: 'var(--radius)' }}>
              <p style={{ color: 'var(--foreground-muted)' }}>No local pit scouting data found for Team {team}.</p>
              <Link href="/settings"><button className="secondary mt-4" style={{ fontSize: '0.875rem' }}>Check Settings</button></Link>
            </div>
          )}
        </div>

        {/* Match Scouting Summary */}
        <div className="card">
          <h2 className="mb-4" style={{ color: 'var(--accent)' }}>Match Performance</h2>
          {matches.length > 0 ? (
            <div className="table-container">
              <table style={{ fontSize: '0.875rem' }}>
                <thead>
                  <tr>
                    <th>Match</th>
                    <th>Auto</th>
                    <th>Teleop</th>
                    <th>Endgame</th>
                  </tr>
                </thead>
                <tbody>
                  {matches.map((m: any, i: number) => (
                    <tr key={i}>
                      <td>{m.matchNumber || m.match_number || m.match || `M${i+1}`}</td>
                      <td>{m.autoScore || m.auto_points || m.auto || '-'}</td>
                      <td>{m.teleopScore || m.teleop_points || m.teleop || '-'}</td>
                      <td>{m.endgame || m.endgame_status || '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div style={{ padding: '2rem', textAlign: 'center', background: 'rgba(255,255,255,0.02)', borderRadius: 'var(--radius)' }}>
              <p style={{ color: 'var(--foreground-muted)' }}>No local match scouting data found for Team {team}.</p>
              <Link href="/settings"><button className="secondary mt-4" style={{ fontSize: '0.875rem' }}>Check Settings</button></Link>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}