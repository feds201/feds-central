import { useState, useEffect, useRef } from 'react';

export default function MotorVsMechanismSimulator() {
  const simCanvasRef = useRef(null);
  const graphCanvasRef = useRef(null);

  const [state, setState] = useState({
    rotorToSensor: 2.0,
    sensorToMechanism: 2.0,
    simSpeed: 1.0,
    motionMode: 'oscillate',
    time: 0,
    rotorAngle: 0,
    sensorAngle: 0,
    mechAngle: 0,
    historyMax: 300,
    historyRotor: [],
    historySensor: [],
    historyMech: [],
  });

  // Update physics
  useEffect(() => {
    const interval = setInterval(() => {
      setState(prevState => {
        let newTime = prevState.time;
        let newRotor = prevState.rotorAngle;

        if (prevState.motionMode === 'oscillate') {
          newTime += 0.03 * prevState.simSpeed;
          newRotor = Math.sin(newTime) * 720;
        } else {
          newRotor += 5 * prevState.simSpeed;
        }

        const newSensor = newRotor / prevState.rotorToSensor;
        const newMech = newSensor / prevState.sensorToMechanism;

        // Update history
        let gRotor, gSensor, gMech;
        if (prevState.motionMode === 'continuous') {
          gRotor = Math.abs(newRotor % 360);
          gSensor = Math.abs(newSensor % 360);
          gMech = Math.abs(newMech % 360);
        } else {
          gRotor = newRotor;
          gSensor = newSensor;
          gMech = newMech;
        }

        const newHistoryRotor = [...prevState.historyRotor, gRotor];
        const newHistorySensor = [...prevState.historySensor, gSensor];
        const newHistoryMech = [...prevState.historyMech, gMech];

        if (newHistoryRotor.length > prevState.historyMax) {
          newHistoryRotor.shift();
          newHistorySensor.shift();
          newHistoryMech.shift();
        }

        return {
          ...prevState,
          time: newTime,
          rotorAngle: newRotor,
          sensorAngle: newSensor,
          mechAngle: newMech,
          historyRotor: newHistoryRotor,
          historySensor: newHistorySensor,
          historyMech: newHistoryMech,
        };
      });
    }, 50);

    return () => clearInterval(interval);
  }, []);

  // Draw simulation
  useEffect(() => {
    const canvas = simCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const cx = canvas.width / 2;
    const cy = canvas.height / 2;

    const drawGear = (x, y, radius, angle, color, label, teeth = 8) => {
      ctx.save();
      ctx.translate(x, y);

      // Label
      ctx.fillStyle = color;
      ctx.font = "14px sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(label, 0, -radius - 10);

      ctx.rotate((angle * Math.PI) / 180);

      // Body
      ctx.beginPath();
      ctx.arc(0, 0, radius, 0, Math.PI * 2);
      ctx.fillStyle = '#333';
      ctx.fill();
      ctx.strokeStyle = color;
      ctx.lineWidth = 3;
      ctx.stroke();

      // Position Marker
      ctx.beginPath();
      ctx.arc(radius - 10, 0, 5, 0, Math.PI * 2);
      ctx.fillStyle = color;
      ctx.fill();

      ctx.restore();
    };

    // Draw stages
    drawGear(80, cy, 30, state.rotorAngle, '#51cf66', "Rotor", 4);

    ctx.fillStyle = '#666';
    ctx.font = "20px monospace";
    ctx.fillText("→", 130, cy + 5);
    ctx.font = "10px monospace";
    ctx.fillText(`${state.rotorToSensor}:1`, 130, cy - 10);

    drawGear(200, cy, 40, state.sensorAngle, '#4dabf7', "Sensor", 6);

    ctx.fillStyle = '#666';
    ctx.font = "20px monospace";
    ctx.fillText("→", 270, cy + 5);
    ctx.font = "10px monospace";
    ctx.fillText(`${state.sensorToMechanism}:1`, 270, cy - 10);

    drawGear(360, cy, 60, state.mechAngle, '#ff922b', "Mechanism", 12);
  }, [state.rotorAngle, state.sensorAngle, state.mechAngle, state.rotorToSensor, state.sensorToMechanism]);

  // Draw graph
  useEffect(() => {
    const canvas = graphCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const w = canvas.width;
    const h = canvas.height;
    const mid = h / 2;

    let scaleY = 0.15;
    let yOffset = mid;

    if (state.motionMode === 'continuous') {
      scaleY = 0.8;
      yOffset = h - 20;
    }

    if (state.motionMode === 'oscillate') {
      ctx.beginPath();
      ctx.strokeStyle = '#333';
      ctx.moveTo(0, mid);
      ctx.lineTo(w, mid);
      ctx.stroke();
    }

    const plotLine = (data, color) => {
      ctx.beginPath();
      ctx.strokeStyle = color;
      ctx.lineWidth = 2;

      for (let i = 0; i < data.length; i++) {
        const x = (i / state.historyMax) * w;

        if (i > 0 && Math.abs(data[i] - data[i - 1]) > 300 && state.motionMode === 'continuous') {
          ctx.moveTo(x, yOffset - (data[i] * scaleY));
          continue;
        }

        const val = data[i];
        const y = yOffset - (val * scaleY);

        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    };

    plotLine(state.historyRotor, '#51cf66');
    plotLine(state.historySensor, '#4dabf7');
    plotLine(state.historyMech, '#ff922b');
  }, [state.historyRotor, state.historySensor, state.historyMech, state.motionMode]);

  const dispRotor = Math.round(state.rotorAngle % 360);
  const dispSensor = Math.round(state.sensorAngle % 360);
  const dispMech = Math.round(state.mechAngle % 360);
  const totalRatio = (state.rotorToSensor * state.sensorToMechanism).toFixed(1);

  return (
    <div style={{
      backgroundColor: '#1a1a1a',
      color: '#e0e0e0',
      padding: '20px',
      borderRadius: '8px',
      marginTop: '20px',
      marginBottom: '20px',
      fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
    }}>
      <h2 style={{ textAlign: 'center', marginBottom: '10px' }}>Rotor vs. Sensor vs. Mechanism</h2>
      <p style={{ color: '#bbb', textAlign: 'center', marginBottom: '20px', maxWidth: '800px', margin: '0 auto 20px' }}>
        <strong>RotorToSensor:</strong> Gearing between Motor and Sensor.<br />
        <strong>SensorToMechanism:</strong> Gearing between Sensor and Output.
      </p>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '20px', justifyContent: 'center', maxWidth: '1200px', margin: '0 auto' }}>
        {/* Visualization Panel */}
        <div style={{
          backgroundColor: '#2d2d2d',
          borderRadius: '12px',
          padding: '20px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.3)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          flex: '1 1 450px',
          minWidth: '300px'
        }}>
          <h3>Visualizing the Chain</h3>
          <canvas
            ref={simCanvasRef}
            width={450}
            height={350}
            style={{
              backgroundColor: '#000',
              borderRadius: '8px',
              border: '1px solid #444',
            }}
          />
          <div style={{ display: 'flex', gap: '20px', marginTop: '10px', fontSize: '0.9em' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
              <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#51cf66' }}></div>
              Rotor (Motor)
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
              <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#4dabf7' }}></div>
              Sensor
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
              <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#ff922b' }}></div>
              Mechanism
            </div>
          </div>
          <div style={{
            marginTop: '15px',
            padding: '10px',
            background: 'rgba(0, 0, 0, 0.2)',
            borderRadius: '6px',
            fontFamily: 'monospace',
            width: '100%',
            fontSize: '0.9em',
            textAlign: 'left'
          }}>
            Rotor Pos: {dispRotor}°<br />
            Sensor Pos: {dispSensor}° (Rotor / {state.rotorToSensor.toFixed(1)})<br />
            Mech Pos: {dispMech}° (Sensor / {state.sensorToMechanism.toFixed(1)})
          </div>
        </div>

        {/* Graph Panel */}
        <div style={{
          backgroundColor: '#2d2d2d',
          borderRadius: '12px',
          padding: '20px',
          boxShadow: '0 4px 6px rgba(0, 0, 0, 0.3)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          flex: '1 1 500px',
          minWidth: '300px'
        }}>
          <h3>Position Comparison Graph</h3>
          <canvas
            ref={graphCanvasRef}
            width={500}
            height={350}
            style={{
              backgroundColor: '#000',
              borderRadius: '8px',
              border: '1px solid #444',
            }}
          />
          <div style={{ display: 'flex', gap: '20px', marginTop: '10px', fontSize: '0.9em', justifyContent: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
              <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#51cf66' }}></div>
              Rotor
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
              <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#4dabf7' }}></div>
              Sensor
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
              <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#ff922b' }}></div>
              Mech
            </div>
          </div>
        </div>
      </div>

      {/* Controls */}
      <div style={{
        backgroundColor: '#2d2d2d',
        borderRadius: '12px',
        padding: '20px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.3)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        maxWidth: '400px',
        margin: '20px auto 0',
      }}>
        <div style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: '15px' }}>
          <div>
            <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '5px' }}>Motion Mode</label>
            <select
              value={state.motionMode}
              onChange={(e) => setState({ ...state, motionMode: e.target.value })}
              style={{
                width: '100%',
                background: '#444',
                border: '1px solid #555',
                color: 'white',
                borderRadius: '4px',
                padding: '5px',
                fontFamily: 'inherit'
              }}
            >
              <option value="oscillate">Oscillate (Sine Wave)</option>
              <option value="continuous">Continuous Spin</option>
            </select>
          </div>

          <div>
            <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '5px' }}>
              RotorToSensorRatio
            </label>
            <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
              <input
                type="range"
                min="1"
                max="10"
                step="0.5"
                value={state.rotorToSensor}
                onChange={(e) => setState({ ...state, rotorToSensor: parseFloat(e.target.value) })}
                style={{ flex: 1 }}
              />
              <input
                type="number"
                value={state.rotorToSensor}
                onChange={(e) => setState({ ...state, rotorToSensor: parseFloat(e.target.value) })}
                step="0.1"
                min="0.1"
                style={{
                  width: '60px',
                  background: '#444',
                  border: '1px solid #555',
                  color: 'white',
                  borderRadius: '4px',
                  padding: '4px',
                }}
              />
            </div>
            <div style={{ fontFamily: 'monospace', color: '#aaa', marginTop: '5px', fontSize: '0.85em' }}>
              Sensor Speed = Rotor / {state.rotorToSensor.toFixed(1)}
            </div>
          </div>

          <div>
            <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '5px' }}>
              SensorToMechanismRatio
            </label>
            <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
              <input
                type="range"
                min="1"
                max="20"
                step="0.5"
                value={state.sensorToMechanism}
                onChange={(e) => setState({ ...state, sensorToMechanism: parseFloat(e.target.value) })}
                style={{ flex: 1 }}
              />
              <input
                type="number"
                value={state.sensorToMechanism}
                onChange={(e) => setState({ ...state, sensorToMechanism: parseFloat(e.target.value) })}
                step="0.1"
                min="0.1"
                style={{
                  width: '60px',
                  background: '#444',
                  border: '1px solid #555',
                  color: 'white',
                  borderRadius: '4px',
                  padding: '4px',
                }}
              />
            </div>
            <div style={{ fontFamily: 'monospace', color: '#aaa', marginTop: '5px', fontSize: '0.85em' }}>
              Mech Speed = Sensor / {state.sensorToMechanism.toFixed(1)}
            </div>
          </div>

          <div>
            <label style={{ fontWeight: 'bold' }}>
              Total Reduction: <span style={{ color: '#ff922b' }}>{totalRatio}:1</span>
            </label>
          </div>

          <div>
            <label style={{ fontWeight: 'bold', display: 'block', marginBottom: '5px' }}>
              Simulation Speed: <span>{state.simSpeed.toFixed(1)}x</span>
            </label>
            <input
              type="range"
              min="0.1"
              max="3.0"
              step="0.1"
              value={state.simSpeed}
              onChange={(e) => setState({ ...state, simSpeed: parseFloat(e.target.value) })}
              style={{ width: '100%' }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}

