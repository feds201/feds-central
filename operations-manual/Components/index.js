'use client';
// ============================================================================
// FEDS-Handbook Components Library
// ============================================================================
// A comprehensive, parameter-driven components library for creating
// any widget or UI element needed across the FEDS Handbook.
//
// Components are organized into logical categories:
// - Base: Fundamental building blocks (Button, Card, Hero)
// - Core: Essential widgets and containers
// - Layout: Grid systems and layout components
// - Data: Data visualization and stats components
// - Interactive: Interactive elements and timelines
// - Navigation: Navigation and menu components
// ============================================================================

// ============================================================================
// BASE COMPONENTS - Fundamental building blocks
// ============================================================================
export { GenericButton } from './Library/Base/GenericButton';
export { GenericCard } from './Library/Base/GenericCard';
export { GenericHero } from './Library/Base/GenericHero';

// ============================================================================
// CORE COMPONENTS - Essential widgets and containers
// ============================================================================
export { GenericWidget } from './Library/Core/GenericWidget';

// ============================================================================
// LAYOUT COMPONENTS - Grid systems and layout
// ============================================================================
export { GenericGrid } from './Library/Layout/GenericGrid';

// ============================================================================
// DATA COMPONENTS - Data visualization and statistics
// ============================================================================
export { GenericStats } from './Library/Data/GenericStats';

// ============================================================================
// INTERACTIVE COMPONENTS - Interactive elements
// ============================================================================
export { GenericTimeline } from './Library/Interactive/GenericTimeline';

// ============================================================================
// NAVIGATION COMPONENTS - Navigation and menus
// ============================================================================
export { GenericNavigation } from './Library/Navigation/GenericNavigation';

// ============================================================================
// CONVENIENCE EXPORTS - Pre-configured generic components
// ============================================================================
// These are the generic components configured for common use cases

import React from 'react';
import { GenericCard } from './Library/Base/GenericCard';
import { GenericHero } from './Library/Base/GenericHero';
import { GenericWidget } from './Library/Core/GenericWidget';
import { GenericGrid } from './Library/Layout/GenericGrid';
import { GenericStats } from './Library/Data/GenericStats';
import { GenericTimeline } from './Library/Interactive/GenericTimeline';
import { GenericNavigation } from './Library/Navigation/GenericNavigation';

// Simple working slider component
const WorkingSlider = ({ label, min, max, step, defaultValue, icon, onChange }) => {
  const [value, setValue] = useState(defaultValue);
  
  const handleChange = (e) => {
    const newValue = parseFloat(e.target.value);
    setValue(newValue);
    if (onChange) onChange(newValue);
  };

  return (
    <div style={{ 
      padding: '16px', 
      background: 'rgba(255,255,255,0.1)', 
      borderRadius: '8px', 
      marginBottom: '16px' 
    }}>
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'space-between', 
        marginBottom: '12px' 
      }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <span style={{ fontSize: '20px', marginRight: '8px' }}>{icon}</span>
          <label style={{ fontWeight: 'bold', fontSize: '14px', color: 'white' }}>{label}</label>
        </div>
        <span style={{ 
          fontSize: '18px', 
          fontWeight: 'bold', 
          color: '#667eea',
          backgroundColor: 'rgba(255,255,255,0.2)',
          padding: '4px 8px',
          borderRadius: '4px'
        }}>
          {value.toFixed(1)}
        </span>
      </div>
      
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={handleChange}
        style={{
          width: '100%',
          height: '6px',
          borderRadius: '3px',
          background: '#ddd',
          outline: 'none',
          opacity: '0.7',
          transition: 'opacity 0.2s',
          cursor: 'pointer'
        }}
        onMouseOver={(e) => e.target.style.opacity = '1'}
        onMouseOut={(e) => e.target.style.opacity = '0.7'}
      />
      
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        fontSize: '12px', 
        marginTop: '8px', 
        opacity: 0.7,
        color: 'white'
      }}>
        <span>{min}</span>
        <span>Current: {value.toFixed(1)}</span>
        <span>{max}</span>
      </div>
    </div>
  );
};

// Pre-configured Hero components
export const ProgrammingHero = (props) => (
  <GenericHero
    title="Welcome to Programming Excellence"
    subtitle="Where Code Meets Competition"
    description="Programming in FIRST Robotics isn't just about writing code—it's about bringing mechanical marvels to life."
    backgroundType="gradient"
    backgroundValue="linear-gradient(135deg, #667eea 0%, #764ba2 25%, #f093fb 50%, #f5576c 75%, #667eea 100%)"
    particles={[
      { symbol: '💻', transform: 'translateX(10px)' },
      { symbol: '🤖', transform: 'translateX(-10px)' },
      { symbol: '⚡', transform: 'translateX(5px)' },
      { symbol: '🚀', transform: 'translateX(-5px)' }
    ]}
    height="lg"
    animation={{ enabled: true }}
    {...props}
  />
);

export const HeroSection = (props) => (
  <GenericHero
    title="FEDS 201 Robotics"
    subtitle="Building Tomorrow's Engineers Today"
    description="Discover innovation, excellence, and championship performance in competitive robotics."
    backgroundType="gradient"
    backgroundValue="linear-gradient(135deg, #1e293b 0%, #0f172a 25%, #7c3aed 50%, #06b6d4 75%, #1e293b 100%)"
    height="lg"
    {...props}
  />
);

// Pre-configured Card components (for backward compatibility)
export const ModernCard = (props) => (
  <GenericCard
    variant="modern"
    size="lg"
    bgPattern='dots'
    interactive={true}
    animation={{ enabled: true, hover: true }}
    {...props}
  />
);

export const ResourceWidget = (props) => (
  <GenericWidget
    variant="card"  
    size="sm"
    interactive={true}
    {...props}
  />
);

// Pre-configured Stats components
export const StatsSection = (props) => (
  <GenericStats
    layout="horizontal"
    variant="gradient"
    countUp={true}
    animation={{ enabled: true, duration: 2000, delay: 100 }}
    stats={[
      { value: 23, label: 'Years of Excellence', icon: '🏆', suffix: '+' },
      { value: 150, label: 'Students Impacted', icon: '👥', suffix: '+' },
      { value: 50, label: 'Competitions Won', icon: '🥇', suffix: '+' },
      { value: 12, label: 'Championship Titles', icon: '🏆' }
    ]}
    {...props}
  />
);

export const SoftwareStats = (props) => (
  <GenericStats
    layout="grid"
    variant="cards"
    countUp={true}
    stats={[
      { value: 15000, label: 'Lines of Code', icon: '💻', suffix: '+' },
      { value: 25, label: 'Web Applications', icon: '🌐', suffix: '+' },
      { value: 8, label: 'Mobile Apps', icon: '📱' },
      { value: 50, label: 'Automated Tests', icon: '🔧', suffix: '+' }
    ]}
    {...props}
  />
);

// Pre-configured Grid components
export const ModernWidgetGrid = (props) => (
  <GenericGrid
    layout="responsive"
    columns={{ xs: 1, sm: 2, md: 3, lg: 4 }}
    gap="24px"
    animation={{ enabled: true, stagger: 100 }}
    {...props}
  />
);

export const ProgrammingWingsGrid = (props) => (
  <GenericGrid
    layout="responsive" 
    columns={{ xs: 1, sm: 1, md: 2, lg: 2 }}
    gap="32px"
    animation={{ enabled: true, stagger: 200 }}
    {...props}
  />
);

// Pre-configured Timeline components
export const InteractiveTimeline = (props) => (
  <GenericTimeline
    orientation="vertical"
    variant="cards"
    interactive={true}
    animation={{ enabled: true, stagger: 200 }}
    {...props}
  />
);

// Pre-configured Navigation components
export const TeamStructureGrid = (props) => (
  <GenericNavigation
    layout="grid"
    variant="cards"
    animated={true}
    {...props}
  />
);

// Specialized components that use generic components internally
export const SoftwareBenefitCard = ({ icon, title, description, ...props }) => (
  <GenericCard
    variant="glass"
    size="md"
    interactive={false}
    animation={{ enabled: true, hover: false }}
    {...props}
  >
    <div style={{ textAlign: 'center' }}>
      <div style={{ fontSize: '48px', marginBottom: '16px' }}>{icon}</div>
      <h3 style={{ fontSize: '20px', fontWeight: '700', marginBottom: '12px' }}>{title}</h3>
      <p style={{ color: 'rgba(255, 255, 255, 0.8)', lineHeight: '1.6' }}>{description}</p>
    </div>
  </GenericCard>
);

export const SoftwareSkillsMatrix = (props) => (
  <GenericWidget
    title="Technology Stack"
    variant="glass"
    size="lg"
    {...props}
  >
    <GenericGrid
      layout="responsive"
      columns={{ xs: 2, sm: 3, md: 4 }}
      gap="16px"
      items={[
        'React', 'Next.js', 'Node.js', 'Python',
        'Flutter', 'Firebase', 'PostgreSQL', 'Docker'
      ]}
    />
  </GenericWidget>
);

export const SoftwarePath = (props) => (
  <GenericTimeline
    orientation="vertical"
    variant="default"
    interactive={true}
    items={[
      {
        title: 'Web Development Fundamentals',
        description: 'Learn HTML, CSS, JavaScript, and modern frameworks',
        icon: '🌐',
        date: 'Month 1-2'
      },
      {
        title: 'Backend Development', 
        description: 'Master server-side programming and databases',
        icon: '⚙️',
        date: 'Month 3-4'
      },
      {
        title: 'Mobile Development',
        description: 'Build cross-platform mobile applications',
        icon: '📱', 
        date: 'Month 5-6'
      },
      {
        title: 'Data Science & AI',
        description: 'Implement machine learning and analytics',
        icon: '🤖',
        date: 'Month 7+'
      }
    ]}
    {...props}
  />
);

export const SoftwareTechStack = (props) => (
  <GenericGrid
    layout="responsive"
    columns={{ xs: 1, sm: 2, md: 3 }}
    gap="20px"
    items={[
      {
        title: 'Frontend',
        content: 'React, Next.js, TypeScript'
      },
      {
        title: 'Backend', 
        content: 'Node.js, Python, Express'
      },
      {
        title: 'Database',
        content: 'PostgreSQL, Firebase, MongoDB'
      },
      {
        title: 'Mobile',
        content: 'Flutter, React Native'
      },
      {
        title: 'Cloud',
        content: 'AWS, Vercel, Firebase'
      },
      {
        title: 'AI/ML',
        content: 'TensorFlow, PyTorch, scikit-learn'
      }
    ]}
    {...props}
  />
);

export const SoftwareProjectsDemo = (props) => (
  <GenericWidget
    title="Interactive Project Gallery"
    subtitle="Explore our software projects"
    variant="gradient"
    size="xl"
    interactive={true}
    {...props}
  >
    <p>Click to explore our comprehensive software project portfolio...</p>
  </GenericWidget>
);

export const WingComparisonWidget = (props) => (
  <GenericGrid
    layout="responsive"
    columns={{ xs: 1, sm: 1, md: 2 }}
    gap="32px"
    items={[
      {
        title: 'FRC Wing',
        description: 'Robot programming, autonomous systems, real-time control'
      },
      {
        title: 'Software Wing', 
        description: 'Web apps, mobile development, data analytics, AI/ML'
      }
    ]}
    renderItem={(item) => (
      <GenericCard variant="modern" size="lg" interactive={false}>
        <h3>{item.title}</h3>
        <p>{item.description}</p>
      </GenericCard>
    )}
    {...props}
  />
);

export const InteractiveStatsWidget = (props) => (
  <GenericStats
    layout="carousel"
    variant="gradient" 
    countUp={true}
    {...props}
  />
);

// Ultra-simple slider that WILL work
const BasicSlider = ({ label, min, max, step, defaultValue, icon, onChange }) => {
  const [value, setValue] = useState(defaultValue);
  
  const handleChange = (e) => {
    const newValue = parseFloat(e.target.value);
    setValue(newValue);
    console.log(`${label}: ${newValue}`); // Debug log
    if (onChange) onChange(newValue);
  };

  return (
    <div style={{ 
      padding: '20px', 
      margin: '10px 0',
      background: 'rgba(255,255,255,0.2)', 
      borderRadius: '10px',
      border: '1px solid rgba(255,255,255,0.3)'
    }}>
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'space-between', 
        marginBottom: '15px' 
      }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <span style={{ fontSize: '24px', marginRight: '10px' }}>{icon}</span>
          <label style={{ 
            fontWeight: 'bold', 
            fontSize: '16px', 
            color: 'white',
            textShadow: '0 1px 2px rgba(0,0,0,0.5)'
          }}>
            {label}
          </label>
        </div>
        <div style={{ 
          fontSize: '20px', 
          fontWeight: 'bold', 
          color: '#00ff00',
          backgroundColor: 'rgba(0,0,0,0.5)',
          padding: '8px 12px',
          borderRadius: '6px',
          minWidth: '60px',
          textAlign: 'center'
        }}>
          {value.toFixed(1)}
        </div>
      </div>
      
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={handleChange}
        style={{
          width: '100%',
          height: '30px',
          cursor: 'pointer',
          margin: '10px 0'
        }}
      />
      
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        fontSize: '14px', 
        color: 'rgba(255,255,255,0.8)',
        marginTop: '10px'
      }}>
        <span>Min: {min}</span>
        <span style={{ fontWeight: 'bold' }}>Value: {value.toFixed(1)}</span>
        <span>Max: {max}</span>
      </div>
    </div>
  );
};

// V-DES Interactive Calculator with basic sliders
export const VDESCalculator = (props) => {
  const [scores, setScores] = useState({
    disruption: 2.5,
    control: 3.0,
    pressure: 2.8,
    adaptation: 3.2
  });

  const updateScore = (metric, value) => {
    console.log(`Updating ${metric} to ${value}`); // Debug log
    const newScores = { ...scores, [metric]: value };
    setScores(newScores);
    if (props.onScoreChange) {
      props.onScoreChange(newScores);
    }
  };

  const overallScore = ((scores.disruption + scores.control + scores.pressure + scores.adaptation) / 4).toFixed(2);
  const vectorMagnitude = Math.sqrt(scores.disruption**2 + scores.control**2 + scores.pressure**2 + scores.adaptation**2).toFixed(2);

  return (
    <GenericWidget
      title="🎮 V-DES Calculator (TEST)"
      subtitle={`Live Score: ${overallScore}/4.0`}
      variant="glass"
      size="xl"
      interactive={true}
      {...props}
    >
      <div style={{ padding: '10px' }}>
        <BasicSlider
          label="Disruption Score"
          min={0}
          max={4.0}
          step={0.1}
          defaultValue={2.5}
          icon="🔥"
          onChange={(value) => updateScore('disruption', value)}
        />
        <BasicSlider
          label="Control Score" 
          min={0}
          max={4.0}
          step={0.1}
          defaultValue={3.0}
          icon="🎮"
          onChange={(value) => updateScore('control', value)}
        />
        <BasicSlider
          label="Pressure Score"
          min={0}
          max={4.0}
          step={0.1}
          defaultValue={2.8}
          icon="⚡"
          onChange={(value) => updateScore('pressure', value)}
        />
        <BasicSlider
          label="Adaptation Score"
          min={0}
          max={4.0}
          step={0.1}
          defaultValue={3.2}
          icon="🧬"
          onChange={(value) => updateScore('adaptation', value)}
        />
        
        <div style={{ 
          marginTop: '30px', 
          padding: '20px', 
          background: 'linear-gradient(135deg, rgba(102, 126, 234, 0.3), rgba(118, 75, 162, 0.3))', 
          borderRadius: '10px',
          textAlign: 'center',
          border: '2px solid rgba(102, 126, 234, 0.5)'
        }}>
          <div style={{ fontSize: '28px', fontWeight: 'bold', marginBottom: '10px', color: '#00ff00' }}>
            🎯 Vector Magnitude: {vectorMagnitude}
          </div>
          <div style={{ fontSize: '16px', color: 'white', marginBottom: '10px' }}>
            ||DIV|| = √(D² + C² + P² + A²)
          </div>
          <div style={{ fontSize: '14px', color: 'rgba(255,255,255,0.8)' }}>
            🔥{scores.disruption.toFixed(1)} | 🎮{scores.control.toFixed(1)} | ⚡{scores.pressure.toFixed(1)} | 🧬{scores.adaptation.toFixed(1)}
          </div>
        </div>
      </div>
    </GenericWidget>
  );
};


export const VDESTierSimulator = (props) => {
  const [currentScore, setCurrentScore] = useState(3.125); // Average of default values
  
  React.useEffect(() => {
    if (props.score) {
      setCurrentScore(props.score);
    }
  }, [props.score]);

  const getTierInfo = (score) => {
    if (score >= 4.5) return { tier: 'S+', name: 'Elite Lockdown Specialist', emoji: '👑', color: '#FFD700' };
    if (score >= 4.0) return { tier: 'S', name: 'Dominant Defender', emoji: '🥇', color: '#C0C0C0' };
    if (score >= 3.5) return { tier: 'A+', name: 'Excellent Defender', emoji: '🥈', color: '#CD7F32' };
    if (score >= 3.0) return { tier: 'A', name: 'Good Defender', emoji: '🥉', color: '#90EE90' };
    if (score >= 2.5) return { tier: 'B+', name: 'Average Defender', emoji: '📊', color: '#87CEEB' };
    return { tier: 'B-C', name: 'Below Average', emoji: '📉', color: '#F0E68C' };
  };

  const tierInfo = getTierInfo(currentScore);

  return (
    <GenericWidget
      title="🏆 Live Tier Classification"
      subtitle="Real-time tier updates"
      variant="gradient"
      size="lg"
      interactive={true}
      {...props}
    >
      <div style={{ textAlign: 'center', padding: '20px' }}>
        <div style={{ 
          fontSize: '64px', 
          marginBottom: '16px',
          transition: 'all 0.3s ease',
          transform: currentScore >= 4.0 ? 'scale(1.1)' : 'scale(1.0)'
        }}>
          {tierInfo.emoji}
        </div>
        <h3 style={{ 
          fontSize: '28px', 
          marginBottom: '8px',
          color: tierInfo.color,
          transition: 'color 0.3s ease'
        }}>
          {tierInfo.tier} Tier
        </h3>
        <p style={{ color: 'rgba(255,255,255,0.8)', marginBottom: '16px' }}>
          {tierInfo.name}
        </p>
        <div style={{ 
          fontSize: '36px', 
          fontWeight: 'bold',
          transition: 'all 0.3s ease',
          color: tierInfo.color
        }}>
          {currentScore.toFixed(2)}/5.0
        </div>
        
        <div style={{ 
          marginTop: '20px',
          padding: '12px',
          background: 'rgba(255,255,255,0.1)',
          borderRadius: '8px',
          fontSize: '14px'
        }}>
          <div style={{ marginBottom: '8px' }}>
            **Performance Percentile:** Top {Math.max(2, Math.round((5-currentScore) * 20))}%
          </div>
          <div>
            **Strategic Value:** {currentScore >= 4.0 ? 'Game Changing' : currentScore >= 3.0 ? 'High Impact' : 'Moderate Impact'}
          </div>
        </div>
      </div>
    </GenericWidget>
  );
}


// ============================================================================
// V-DES Dashboard - Coordinated V-DES Calculator and Tier Simulator
// This component combines the V-DES Calculator and Tier Simulator into a single dashboard
// for easy access and interaction.

// Coordinated V-DES Dashboard
export const VDESDashboard = (props) => {
  const [globalScore, setGlobalScore] = useState(3.125);

  const handleScoreUpdate = (scores) => {
    const average = (scores.disruption + scores.control + scores.pressure + scores.adaptation) / 4;
    setGlobalScore(average);
  };

  return (
    <GenericGrid
      layout="responsive"
      columns={{ xs: 1, sm: 1, md: 2 }}
      gap="32px"
      {...props}
    >
      <VDESCalculator onScoreChange={handleScoreUpdate} />
      <VDESTierSimulator score={globalScore} />
    </GenericGrid>
  );
};

// ============================================================================
// EXAMPLE USAGE PATTERNS
// ============================================================================
/*

// Creating a custom hero section:
<GenericHero
  title="My Custom Title"
  subtitle="Custom subtitle"
  backgroundType="gradient"
  backgroundValue="linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
  buttons={[
    { text: 'Get Started', style: 'primary', onClick: () => {} },
    { text: 'Learn More', style: 'secondary', href: '/learn' }
  ]}
  particles={[
    { symbol: '🚀', transform: 'translateX(10px)' },
    { symbol: '⚡', transform: 'translateX(-10px)' }
  ]}
  height="lg"
/>

// Creating a stats section:
<GenericStats
  layout="horizontal"
  variant="cards"
  countUp={true}
  stats={[
    { value: 100, label: 'Projects', icon: '📊', suffix: '+' },
    { value: 50, label: 'Students', icon: '👥' },
    { value: 25, label: 'Awards', icon: '🏆' }
  ]}
/>

// Creating a timeline:
<GenericTimeline
  orientation="vertical"
  variant="cards"
  interactive={true}
  items={[
    {
      title: 'Event 1',
      date: '2024',
      description: 'Description of event',
      icon: '🎯'
    }
  ]}
/>

// Creating a grid of cards:
<GenericGrid
  layout="responsive"
  columns={{ xs: 1, sm: 2, md: 3 }}
  items={cardData}
  renderItem={(item) => (
    <GenericCard variant="modern" {...item} />
  )}
/>

// Creating a custom widget:
<GenericWidget
  title="Custom Widget"
  icon="🔧"
  variant="glass"
  size="md"
  interactive={true}
  link="/custom-page"
>
  <p>Custom content goes here</p>
</GenericWidget>

*/
