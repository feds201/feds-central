import { useState, useEffect, useRef } from 'react';

export default function MotorControlConfigurator() {
  const canvasRef = useRef(null);
  const [activeSlot, setActiveSlot] = useState(0);
  const [simMode, setSimMode] = useState('arm');
  const [slots, setSlots] = useState([
    { name: 'Slot 0', kP: 2.4, kI: 0, kD: 0.1, kS: 0.25, kV: 0.12, kA: 0.01, kG: 0.2 },
    { name: 'Slot 1', kP: 0.11, kI: 0, kD: 0, kS: 0.25, kV: 0.12, kA: 0.01, kG: 0 },
  ]);
  const [target, setTarget] = useState(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    const w = canvas.width, h = canvas.height;
    const cx = w / 2, cy = h / 2;
    const slot = slots[activeSlot];

    ctx.strokeStyle = '#333';
    ctx.lineWidth = 1;
    for (let i = 0; i < w; i += 20) {
      ctx.beginPath();
      ctx.moveTo(i, 0);
      ctx.lineTo(i, h);
      ctx.stroke();
    }

    if (simMode === 'arm') {
      const angle = target * Math.PI;
      const armLen = 80;
      ctx.fillStyle = '#666';
      ctx.beginPath();
      ctx.arc(cx, cy, 10, 0, Math.PI * 2);
      ctx.fill();
      const ex = cx + Math.cos(angle) * armLen;
      const ey = cy + Math.sin(angle) * armLen;
      ctx.strokeStyle = '#4dabf7';
      ctx.lineWidth = 8;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(ex, ey);
      ctx.stroke();
      ctx.fillStyle = '#51cf66';
      ctx.beginPath();
      ctx.arc(ex, ey, 8, 0, Math.PI * 2);
      ctx.fill();
    } else {
      const angle = target * Math.PI * 2;
      const r = 50;
      ctx.strokeStyle = '#555';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.stroke();
      ctx.strokeStyle = '#ff6b6b';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
      ctx.stroke();
    }

    ctx.fillStyle = '#e0e0e0';
    ctx.font = '14px monospace';
    ctx.fillText(`Target: ${target.toFixed(3)}`, 20, 30);
    ctx.fillText(`kP: ${slot.kP.toFixed(2)}, kD: ${slot.kD.toFixed(2)}`, 20, 50);
  }, [activeSlot, simMode, target, slots]);

  const slot = slots[activeSlot];

  return (
    <div style={{ backgroundColor: '#1a1a1a', color: '#e0e0e0', padding: '20px', borderRadius: '8px', marginTop: '20px', marginBottom: '20px' }}>
      <h2 style={{ textAlign: 'center', marginBottom: '10px' }}>Motor Control System Configurator</h2>

      <div style={{ display: 'flex', gap: '20px', marginBottom: '20px', flexWrap: 'wrap' }}>
        <div style={{ flex: '1 1 500px', backgroundColor: '#2d2d2d', borderRadius: '12px', padding: '20px' }}>
          <h3 style={{ marginBottom: '15px' }}>Simulation</h3>

          <div style={{ display: 'flex', gap: '10px', marginBottom: '15px' }}>
            <button onClick={() => setSimMode('arm')} style={{ padding: '8px 16px', backgroundColor: simMode === 'arm' ? '#4dabf7' : '#555', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>Arm</button>
            <button onClick={() => setSimMode('turret')} style={{ padding: '8px 16px', backgroundColor: simMode === 'turret' ? '#4dabf7' : '#555', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>Turret</button>
          </div>

          <canvas ref={canvasRef} width={500} height={300} style={{ backgroundColor: '#000', borderRadius: '8px', border: '1px solid #444', width: '100%' }} />

          <div style={{ marginTop: '15px' }}>
            <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '5px' }}>Target</label>
            <input type="range" min="-0.5" max="0.5" step="0.01" value={target} onChange={(e) => setTarget(parseFloat(e.target.value))} style={{ width: '100%' }} />
          </div>
        </div>

        <div style={{ flex: '1 1 300px', backgroundColor: '#2d2d2d', borderRadius: '12px', padding: '20px', display: 'flex', flexDirection: 'column', gap: '15px' }}>
          <div>
            <label style={{ fontWeight: 'bold' }}>Active Slot</label>
            <div style={{ display: 'flex', gap: '5px', marginTop: '8px' }}>
              {slots.map((s, i) => (
                <button key={i} onClick={() => setActiveSlot(i)} style={{ flex: 1, padding: '8px', backgroundColor: activeSlot === i ? '#4dabf7' : '#555', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>{i}</button>
              ))}
            </div>
          </div>

          <div style={{ borderTop: '1px solid #444', paddingTop: '15px' }}>
            <h4 style={{ marginBottom: '10px' }}>PID</h4>
            {['kP', 'kI', 'kD'].map((k) => (
              <div key={k} style={{ marginBottom: '8px', fontSize: '0.85em' }}>
                <label style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '3px' }}>{k} <span style={{ color: '#4dabf7' }}>{slot[k].toFixed(2)}</span></label>
                <input type="range" min="0" max="10" step="0.01" value={slot[k]} onChange={(e) => { const ns = [...slots]; ns[activeSlot] = { ...ns[activeSlot], [k]: parseFloat(e.target.value) }; setSlots(ns); }} style={{ width: '100%' }} />
              </div>
            ))}
          </div>

          <div style={{ borderTop: '1px solid #444', paddingTop: '15px' }}>
            <h4 style={{ marginBottom: '10px' }}>Feedforward</h4>
            {['kS', 'kV', 'kA'].map((k) => (
              <div key={k} style={{ marginBottom: '8px', fontSize: '0.85em' }}>
                <label style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '3px' }}>{k} <span style={{ color: '#51cf66' }}>{slot[k].toFixed(2)}</span></label>
                <input type="range" min="0" max="1" step="0.01" value={slot[k]} onChange={(e) => { const ns = [...slots]; ns[activeSlot] = { ...ns[activeSlot], [k]: parseFloat(e.target.value) }; setSlots(ns); }} style={{ width: '100%' }} />
              </div>
            ))}
          </div>

          <div style={{ borderTop: '1px solid #444', paddingTop: '15px' }}>
            <label style={{ fontSize: '0.85em' }}>kG: <span style={{ color: '#ff922b' }}>{slot.kG.toFixed(2)}</span></label>
            <input type="range" min="0" max="1" step="0.01" value={slot.kG} onChange={(e) => { const ns = [...slots]; ns[activeSlot] = { ...ns[activeSlot], kG: parseFloat(e.target.value) }; setSlots(ns); }} style={{ width: '100%', marginTop: '5px' }} />
          </div>
        </div>
      </div>
    </div>
  );
}

