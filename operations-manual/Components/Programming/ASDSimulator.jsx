import { useState, useEffect, useRef } from 'react';

export default function ASDSimulator() {
  const sensorCanvasRef = useRef(null);
  const graphCanvasRef = useRef(null);

  const [state, setState] = useState({
    rawAngleDeg: 0,
    discontinuity: 0,
    outputRot: 0,
    hardStopCenter: 180,
    travelRange: 340,
    isSpinning: false,
    history: [],
    historyMax: 200,
  });

  const [isDragging, setIsDragging] = useState(false);
  const [isSafe, setIsSafe] = useState(false);

  // Compute processed value
  const calculateOutput = (newState) => {
    const s = newState || state;

    let rawRot = (s.rawAngleDeg % 360) / 360;
    if (rawRot < 0) rawRot += 1;

    let distFromStart = rawRot - s.discontinuity;
    distFromStart -= Math.floor(distFromStart);

    const outputRot = distFromStart + s.discontinuity;

    let discAngle = (s.discontinuity * 360) % 360;
    if (discAngle < 0) discAngle += 360;

    const stopWidth = 360 - s.travelRange;
    const stopStart = (s.hardStopCenter - stopWidth / 2 + 360) % 360;
    const stopEnd = (s.hardStopCenter + stopWidth / 2 + 360) % 360;

    let safe = false;
    if (stopStart < stopEnd) {
      if (discAngle >= stopStart && discAngle <= stopEnd) safe = true;
    } else {
      if (discAngle >= stopStart || discAngle <= stopEnd) safe = true;
    }

    return { outputRot, safe };
  };

  // The corrected central update function
  const updateState = (updates) => {
    const merged = { ...state, ...updates };
    const { outputRot, safe } = calculateOutput(merged);

    const newHistory = [...merged.history, outputRot];
    if (newHistory.length > merged.historyMax) newHistory.shift();

    setState({
      ...merged,
      outputRot,
      history: newHistory,
    });

    setIsSafe(safe);
  };

  // Get cursor angle
  const getAngleFromMouse = (e, canvas) => {
    const rect = canvas.getBoundingClientRect();
    const cx = rect.width / 2;
    const cy = rect.height / 2;
    const x = e.clientX - rect.left - cx;
    const y = e.clientY - rect.top - cy;
    return Math.atan2(y, x) * (180 / Math.PI) + 90;
  };

  // Mouse down on the sensor
  const handleSensorMouseDown = (e) => {
    setIsDragging(true);
    updateState({
      rawAngleDeg: getAngleFromMouse(e, sensorCanvasRef.current),
      isSpinning: false,
    });
  };

  // Move + release handlers
  useEffect(() => {
    const move = (e) => {
      if (isDragging) {
        updateState({
          rawAngleDeg: getAngleFromMouse(e, sensorCanvasRef.current),
        });
      }
    };

    const up = () => setIsDragging(false);

    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);

    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
  }, [isDragging]);

  // Draw sensor view
  const drawSensor = () => {
    const canvas = sensorCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const cx = canvas.width / 2;
    const cy = canvas.height / 2;
    const radius = 100;

    ctx.save();
    ctx.translate(cx, cy);

    const stopWidth = 360 - state.travelRange;
    const stopStartRad = ((state.hardStopCenter - stopWidth / 2) - 90) * Math.PI / 180;
    const stopEndRad = ((state.hardStopCenter + stopWidth / 2) - 90) * Math.PI / 180;

    ctx.beginPath();
    ctx.arc(0, 0, radius, 0, Math.PI * 2);
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 20;
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(0, 0, radius, stopStartRad, stopEndRad);
    ctx.strokeStyle = '#555';
    ctx.lineWidth = 20;
    ctx.stroke();

    ctx.save();
    let labelAngle = (state.hardStopCenter - 90) * Math.PI / 180;
    ctx.translate(Math.cos(labelAngle) * (radius + 35), Math.sin(labelAngle) * (radius + 35));
    ctx.fillStyle = '#777';
    ctx.font = "bold 12px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText("HARD STOP", 0, 0);
    ctx.restore();

    let discAngleRad = (state.discontinuity * 360 - 90) * Math.PI / 180;
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(Math.cos(discAngleRad) * (radius + 20), Math.sin(discAngleRad) * (radius + 20));
    ctx.strokeStyle = '#ff6b6b';
    ctx.lineWidth = 3;
    ctx.setLineDash([5, 5]);
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.fillStyle = '#ff6b6b';
    ctx.font = "12px sans-serif";
    ctx.fillText("WRAP",
        Math.cos(discAngleRad) * (radius + 30) - 15,
        Math.sin(discAngleRad) * (radius + 30)
    );

    let angleRad = (state.rawAngleDeg - 90) * Math.PI / 180;
    ctx.rotate(angleRad);

    ctx.beginPath();
    ctx.moveTo(-10, 0);
    ctx.lineTo(10, 0);
    ctx.lineTo(0, -radius + 10);
    ctx.fillStyle = '#4dabf7';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(0, -radius, 10, 0, Math.PI * 2);
    ctx.fillStyle = '#4dabf7';
    ctx.fill();
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.restore();
  };

  // Draw output graph
  const drawGraph = () => {
    const canvas = graphCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const w = canvas.width;
    const h = canvas.height;
    const padding = 30;

    ctx.strokeStyle = '#444';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding, 0);
    ctx.lineTo(padding, h);
    ctx.moveTo(padding, h / 2);
    ctx.lineTo(w, h / 2);
    ctx.stroke();

    const data = state.history;

    ctx.beginPath();
    ctx.strokeStyle = '#51cf66';
    ctx.lineWidth = 2;

    const scaleY = h / 2.5;

    for (let i = 0; i < data.length; i++) {
      const x = padding + (i / state.historyMax) * (w - padding);
      const y = (h / 2) - (data[i] * scaleY);

      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }

    ctx.stroke();

    ctx.fillStyle = '#888';
    ctx.font = "10px monospace";
    ctx.fillText("Top", 0, (h / 2) - (0.8 * scaleY));
    ctx.fillText("Btm", 0, (h / 2) + (0.8 * scaleY));
  };

  // Smooth rotation loop
  useEffect(() => {
    const timer = setInterval(() => {
      if (state.isSpinning) {
        updateState({
          rawAngleDeg: (state.rawAngleDeg + 2) % 360,
        });
      }
    }, 50);

    return () => clearInterval(timer);
  }, [state.isSpinning, state.rawAngleDeg]);

  // Redraw when state changes
  useEffect(() => {
    drawSensor();
    drawGraph();
  }, [state]);

  // Sync first render
  useEffect(() => {
    const { outputRot, safe } = calculateOutput(state);
    setState(prev => ({ ...prev, outputRot }));
    setIsSafe(safe);
  }, []);

  const handleReset = () => {
    setState({
      rawAngleDeg: 0,
      discontinuity: 0,
      outputRot: 0,
      hardStopCenter: 180,
      travelRange: 340,
      isSpinning: false,
      history: [],
      historyMax: 200,
    });
    setIsSafe(false);
  };

  return (
      <div style={{
        backgroundColor: '#1a1a1a',
        color: '#e0e0e0',
        padding: '20px',
        borderRadius: '8px',
        marginTop: '20px',
        marginBottom: '20px'
      }}>
        <h1 style={{ marginBottom: '5px' }}>Absolute Sensor Discontinuity Point</h1>
        <p style={{ color: '#bbb', marginBottom: '20px', fontSize: '0.9em' }}>
          Where does your sensor wrap around?
        </p>

        <div style={{
          display: 'flex',
          flexWrap: 'wrap',
          gap: '20px',
          justifyContent: 'center',
          width: '100%',
          maxWidth: '1200px',
          margin: '0 auto'
        }}>

          {/* Left panel */}
          <div style={{
            backgroundColor: '#2d2d2d',
            borderRadius: '12px',
            padding: '20px',
            boxShadow: '0 4px 6px rgba(0, 0, 0, 0.3)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            flex: 1,
            minWidth: '300px'
          }}>
            <h3>Physical Turret</h3>
            <div style={{ fontSize: '1.2em', marginBottom: '10px', fontFamily: 'monospace' }}>
              Angle: <span style={{ color: '#4dabf7' }}>{state.rawAngleDeg.toFixed(1)}°</span>
            </div>

            <canvas
                ref={sensorCanvasRef}
                width={350}
                height={350}
                onMouseDown={handleSensorMouseDown}
                style={{
                  backgroundColor: '#000',
                  borderRadius: '8px',
                  border: '1px solid #444',
                  marginBottom: '10px',
                  cursor: 'crosshair'
                }}
            />

            <div style={{ fontSize: '0.8em', color: '#888', marginTop: '5px', textAlign: 'center' }}>
              Drag the blue dot to rotate. Grey zone is the hard stop.
            </div>

            {/* Controls */}
            <div style={{
              width: '100%',
              display: 'flex',
              flexDirection: 'column',
              gap: '15px',
              background: 'rgba(0, 0, 0, 0.2)',
              padding: '15px',
              borderRadius: '8px',
              marginTop: '20px'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '10px' }}>
                <label style={{ color: '#aaa' }}>Hard Stop Pos</label>
                <input
                    type="range"
                    min="0"
                    max="360"
                    value={state.hardStopCenter}
                    onChange={(e) => updateState({ hardStopCenter: parseFloat(e.target.value) })}
                    style={{
                      flex: 1,
                      margin: '0 10px',
                      accentColor: '#888',
                      minWidth: '150px',
                      cursor: 'pointer'
                    }}
                />
                <div style={{
                  fontFamily: 'monospace',
                  background: '#000',
                  border: '1px solid #444',
                  padding: '5px 10px',
                  borderRadius: '4px',
                  minWidth: '60px',
                  textAlign: 'right',
                  color: '#aaa'
                }}>
                  {state.hardStopCenter.toFixed(0)}°
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '10px' }}>
                <label style={{ color: '#aaa' }}>Travel Range</label>
                <input
                    type="range"
                    min="180"
                    max="360"
                    value={state.travelRange}
                    onChange={(e) => updateState({ travelRange: parseFloat(e.target.value) })}
                    style={{
                      flex: 1,
                      margin: '0 10px',
                      accentColor: '#888',
                      minWidth: '150px',
                      cursor: 'pointer'
                    }}
                />
                <div style={{
                  fontFamily: 'monospace',
                  background: '#000',
                  border: '1px solid #444',
                  padding: '5px 10px',
                  borderRadius: '4px',
                  minWidth: '60px',
                  textAlign: 'right',
                  color: '#aaa'
                }}>
                  {state.travelRange.toFixed(0)}°
                </div>
              </div>
            </div>
          </div>

          {/* Right panel */}
          <div style={{
            backgroundColor: '#2d2d2d',
            borderRadius: '12px',
            padding: '20px',
            boxShadow: '0 4px 6px rgba(0, 0, 0, 0.3)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            flex: 1,
            minWidth: '300px'
          }}>
            <h3>Software Output</h3>
            <div style={{ fontSize: '1.2em', marginBottom: '10px', fontFamily: 'monospace' }}>
              Output: <span style={{ color: '#51cf66' }}>{state.outputRot.toFixed(3)}</span> rot
            </div>

            <div style={{
              background: isSafe ? 'rgba(81, 207, 102, 0.15)' : 'rgba(255, 107, 107, 0.15)',
              borderLeft: `4px solid ${isSafe ? '#51cf66' : '#ff6b6b'}`,
              padding: '10px',
              marginBottom: '15px',
              borderRadius: '4px',
              fontSize: '0.9em',
              width: '100%',
              boxSizing: 'border-box'
            }}>
              <strong>{isSafe ? 'SAFE!' : 'UNSAFE!'}</strong>{' '}
              {isSafe
                  ? 'The wrap point is hidden inside the hard stop.'
                  : 'The sensor may change value sharply during movement.'
              }
            </div>

            <canvas
                ref={graphCanvasRef}
                width={450}
                height={200}
                style={{
                  backgroundColor: '#000',
                  borderRadius: '8px',
                  border: '1px solid #444',
                  marginBottom: '10px'
                }}
            />

            {/* Controls */}
            <div style={{
              width: '100%',
              display: 'flex',
              flexDirection: 'column',
              gap: '15px',
              background: 'rgba(0, 0, 0, 0.2)',
              padding: '15px',
              borderRadius: '8px'
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '10px' }}>
                <label style={{ color: '#ff6b6b' }}>Discontinuity</label>
                <input
                    type="range"
                    min="-0.5"
                    max="0.5"
                    step="0.01"
                    value={state.discontinuity}
                    onChange={(e) => updateState({ discontinuity: parseFloat(e.target.value) })}
                    style={{
                      flex: 1,
                      margin: '0 10px',
                      accentColor: '#ff6b6b',
                      minWidth: '150px',
                      cursor: 'pointer'
                    }}
                />
                <div style={{
                  fontFamily: 'monospace',
                  background: '#000',
                  border: '1px solid #444',
                  padding: '5px 10px',
                  borderRadius: '4px',
                  minWidth: '60px',
                  textAlign: 'right',
                  color: '#ff6b6b'
                }}>
                  {state.discontinuity.toFixed(2)}
                </div>
              </div>

              <div style={{ fontSize: '0.8em', color: '#888', textAlign: 'center' }}>
                Range: [{state.discontinuity.toFixed(2)}, {(state.discontinuity + 1).toFixed(2)}) rotations
              </div>

              <hr style={{ border: '0', borderTop: '1px solid #444', width: '100%', margin: '10px 0' }} />

              <div style={{ display: 'flex', gap: '10px', justifyContent: 'center' }}>
                <button
                    onClick={() => updateState({ isSpinning: !state.isSpinning })}
                    style={{
                      backgroundColor: '#4dabf7',
                      color: '#fff',
                      border: 'none',
                      padding: '8px 16px',
                      borderRadius: '4px',
                      cursor: 'pointer',
                      fontWeight: 'bold',
                      transition: 'background 0.2s'
                    }}
                    onMouseEnter={(e) => (e.target.style.backgroundColor = '#3b8dbf')}
                    onMouseLeave={(e) => (e.target.style.backgroundColor = '#4dabf7')}
                >
                  Auto-Spin
                </button>

                <button
                    onClick={handleReset}
                    style={{
                      backgroundColor: '#555',
                      color: '#fff',
                      border: 'none',
                      padding: '8px 16px',
                      borderRadius: '4px',
                      cursor: 'pointer',
                      fontWeight: 'bold',
                      transition: 'background 0.2s'
                    }}
                    onMouseEnter={(e) => (e.target.style.backgroundColor = '#666')}
                    onMouseLeave={(e) => (e.target.style.backgroundColor = '#555')}
                >
                  Reset
                </button>
              </div>
            </div>

          </div>
        </div>
      </div>
  );
}
