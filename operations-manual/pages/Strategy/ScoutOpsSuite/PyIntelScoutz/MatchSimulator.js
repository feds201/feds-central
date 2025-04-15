import React, { useState } from 'react';

// Example team profiles (replace with real data or props)
const defaultTeams = [
  { name: 'Team Red 1', auton: 20, teleop: 40, endgame: 15, defense: 0.5, climb: 0.7 },
  { name: 'Team Red 2', auton: 18, teleop: 35, endgame: 10, defense: 0.3, climb: 0.5 },
  { name: 'Team Blue 1', auton: 22, teleop: 38, endgame: 12, defense: 0.4, climb: 0.6 },
  { name: 'Team Blue 2', auton: 19, teleop: 36, endgame: 14, defense: 0.6, climb: 0.8 },
];

function randomScore(mean, std = 5) {
  // Simple normal distribution
  return Math.round(mean + std * (Math.random() - 0.5));
}

function simulateTeam(team, aggressiveDefense, forceClimb) {
  const auton = randomScore(team.auton);
  const teleop = randomScore(team.teleop);
  let endgame = 0;
  if (forceClimb || Math.random() < team.climb) {
    endgame = 15;
  } else if (Math.random() < team.climb * 0.5) {
    endgame = 10;
  } else if (Math.random() < 0.3) {
    endgame = 5;
  }
  const defense = Math.random() < (aggressiveDefense ? 1 : team.defense) ? 5 : 0;
  return { auton, teleop, endgame, defense, total: auton + teleop + endgame + defense };
}

export default function MatchSimulator() {
  const [aggressiveDefense, setAggressiveDefense] = useState(false);
  const [forceClimb, setForceClimb] = useState(false);
  const [result, setResult] = useState(null);

  const runSimulation = () => {
    // Red alliance: first two teams, Blue: last two
    const redResults = [0, 1].map(i => simulateTeam(defaultTeams[i], aggressiveDefense, forceClimb));
    const blueResults = [2, 3].map(i => simulateTeam(defaultTeams[i], aggressiveDefense, forceClimb));
    const redTotal = redResults.reduce((sum, t) => sum + t.total, 0);
    const blueTotal = blueResults.reduce((sum, t) => sum + t.total, 0);
    setResult({ redResults, blueResults, redTotal, blueTotal });
  };

  return (
    <div style={{border: '1px solid #ccc', padding: 16, borderRadius: 8, margin: '24px 0'}}>
      <h3>Interactive Match Simulation</h3>
      <div style={{marginBottom: 8}}>
        <label>
          <input type="checkbox" checked={aggressiveDefense} onChange={e => setAggressiveDefense(e.target.checked)} />
          Aggressive Defense (all teams)
        </label>
      </div>
      <div style={{marginBottom: 8}}>
        <label>
          <input type="checkbox" checked={forceClimb} onChange={e => setForceClimb(e.target.checked)} />
          Force All Teams to Attempt Climb
        </label>
      </div>
      <button onClick={runSimulation} style={{marginBottom: 16}}>Run Simulation</button>
      {result && (
        <div>
          <h4>Results</h4>
          <div style={{display: 'flex', gap: 32}}>
            <div>
              <b>Red Alliance</b>
              <ul>
                {result.redResults.map((t, i) => (
                  <li key={i}>Team {i+1}: Auton {t.auton}, Teleop {t.teleop}, Endgame {t.endgame}, Defense {t.defense}, <b>Total {t.total}</b></li>
                ))}
              </ul>
              <b>Total: {result.redTotal}</b>
            </div>
            <div>
              <b>Blue Alliance</b>
              <ul>
                {result.blueResults.map((t, i) => (
                  <li key={i}>Team {i+3}: Auton {t.auton}, Teleop {t.teleop}, Endgame {t.endgame}, Defense {t.defense}, <b>Total {t.total}</b></li>
                ))}
              </ul>
              <b>Total: {result.blueTotal}</b>
            </div>
          </div>
          <div style={{marginTop: 16}}>
            <b>{result.redTotal === result.blueTotal ? 'Tie!' : result.redTotal > result.blueTotal ? 'Red wins!' : 'Blue wins!'}</b>
          </div>
        </div>
      )}
    </div>
  );
}
