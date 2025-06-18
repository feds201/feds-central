import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useTheme } from 'nextra-theme-docs';

const teamStats = [
  { number: "26+", label: "Years of Excellence", color: "#667eea", icon: "🏆", gradient: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" },
  { number: "16+", label: "Blue Banners", color: "#f093fb", icon: "🚩", gradient: "linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)" },
  { number: "28+", label: "Robots Built", color: "#f5576c", icon: "🤖", gradient: "linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)" },
  { number: "1000+", label: "Students Mentored", color: "#a78bfa", icon: "👥", gradient: "linear-gradient(135deg, #f59e0b 0%, #d97706 100%)" }
];

export const HeroSection = () => {
  const { theme } = useTheme()
  const [currentStat, setCurrentStat] = useState(0)
  const [mounted, setMounted] = useState(false)
  
  useEffect(() => {
    setMounted(true)
    const interval = setInterval(() => {
      setCurrentStat((prev) => (prev + 1) % teamStats.length)
    }, 3000)
    return () => clearInterval(interval)
  }, [])

  if (!mounted) return null

  const isDark = theme === 'dark'
  
  return (
    <div className="hero-section" style={{
      background: isDark 
        ? 'linear-gradient(135deg, #0f0f23 0%, #1a1a2e 25%, #16213e 50%, #0f0f23 100%)'
        : 'linear-gradient(135deg, #667eea 0%, #764ba2 25%, #f093fb 50%, #f5576c 75%, #667eea 100%)',
      minHeight: '90vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      position: 'relative',
      overflow: 'hidden',
      borderRadius: '32px',
      margin: '40px 0',
      boxShadow: isDark 
        ? '0 25px 50px -12px rgba(0, 0, 0, 0.9), 0 0 0 1px rgba(255, 255, 255, 0.1)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(255, 255, 255, 0.2)'
    }}>
      {/* Animated background particles */}
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} style={{
          position: 'absolute',
          top: `${10 + i * 15}%`,
          left: `${5 + i * 15}%`,
          width: `${80 + i * 20}px`,
          height: `${80 + i * 20}px`,
          background: isDark 
            ? `rgba(99, 102, 241, ${0.05 + i * 0.02})`
            : `rgba(255, 255, 255, ${0.1 + i * 0.02})`,
          borderRadius: '50%',
          animation: `float ${6 + i}s ease-in-out infinite ${i * 0.5}s`,
          backdropFilter: 'blur(10px)'
        }} />
      ))}
      
      <div style={{
        textAlign: 'center',
        color: 'white',
        zIndex: 10,
        maxWidth: '1000px',
        padding: '60px 40px'
      }}>
        <div style={{
          fontSize: 'clamp(56px, 10vw, 120px)',
          fontWeight: '900',
          marginBottom: '24px',
          textShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
          letterSpacing: '-0.02em',
          animation: 'slideInDown 1s ease-out',
          background: isDark 
            ? 'linear-gradient(135deg, #a78bfa 0%, #06b6d4 50%, #10b981 100%)'
            : 'linear-gradient(135deg, #ffffff 0%, #f8fafc 50%, #ffffff 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text'
        }}>
          FEDS 201
        </div>
        
        <div style={{
          fontSize: 'clamp(28px, 5vw, 42px)',
          fontWeight: '600',
          marginBottom: '32px',
          opacity: '0.95',
          animation: 'slideInUp 1s ease-out 0.2s both'
        }}>
          Championship Robotics Manual
        </div>
        
        <div style={{
          fontSize: 'clamp(18px, 2.5vw, 22px)',
          marginBottom: '48px',
          opacity: '0.9',
          lineHeight: '1.6',
          animation: 'fadeIn 1s ease-out 0.4s both',
          maxWidth: '800px',
          margin: '0 auto 48px'
        }}>
          The definitive guide to championship-level robotics operations, innovative engineering, and sustained excellence in FIRST Robotics Competition
        </div>
        
        {/* Enhanced animated stats card */}
        <div style={{
          background: isDark 
            ? 'rgba(15, 23, 42, 0.8)'
            : 'rgba(255, 255, 255, 0.25)',
          backdropFilter: 'blur(20px)',
          borderRadius: '28px',
          padding: '40px 60px',
          display: 'inline-block',
          border: isDark 
            ? '1px solid rgba(148, 163, 184, 0.2)'
            : '1px solid rgba(255, 255, 255, 0.3)',
          animation: 'slideInUp 1s ease-out 0.6s both',
          boxShadow: isDark 
            ? '0 20px 40px rgba(0, 0, 0, 0.4)'
            : '0 20px 40px rgba(0, 0, 0, 0.1)'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '20px',
            marginBottom: '12px'
          }}>
            <div style={{
              fontSize: '40px',
              animation: 'bounce 2s infinite'
            }}>
              {teamStats[currentStat].icon}
            </div>
            <div style={{
              fontSize: 'clamp(36px, 6vw, 56px)',
              fontWeight: '800',
              color: teamStats[currentStat].color,
              textShadow: '0 4px 8px rgba(0, 0, 0, 0.3)',
              transition: 'all 0.5s ease',
              filter: 'brightness(1.2)'
            }}>
              {teamStats[currentStat].number}
            </div>
          </div>
          <div style={{
            fontSize: 'clamp(14px, 2vw, 18px)',
            fontWeight: '600',
            opacity: '0.95',
            textTransform: 'uppercase',
            letterSpacing: '0.1em'
          }}>
            {teamStats[currentStat].label}
          </div>
        </div>
      </div>

      <style jsx>{`
        @keyframes float {
          0%, 100% { transform: translateY(0px) rotate(0deg); }
          50% { transform: translateY(-30px) rotate(180deg); }
        }
        @keyframes slideInDown {
          from { opacity: 0; transform: translateY(-50px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes slideInUp {
          from { opacity: 0; transform: translateY(50px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes bounce {
          0%, 20%, 53%, 80%, 100% { transform: translate3d(0,0,0); }
          40%, 43% { transform: translate3d(0, -5px, 0); }
          70% { transform: translate3d(0, -3px, 0); }
          90% { transform: translate3d(0, -1px, 0); }
        }
        .hero-section {
          background-size: 400% 400%;
          animation: gradientShift 20s ease infinite;
        }
        @keyframes gradientShift {
          0% { background-position: 0% 50%; }
          50% { background-position: 100% 50%; }
          100% { background-position: 0% 50%; }
        }
      `}</style>
    </div>
  )
}

export const ModernCard = ({ icon, title, description, link, gradient, delay = 0 }) => {
  const { theme } = useTheme()
  const [mounted, setMounted] = useState(false)
  const [isHovered, setIsHovered] = useState(false)
  
  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) return null
  
  const isDark = theme === 'dark'
  
  return (
    <Link href={link}>
      <div 
        className="modern-card"
        style={{
          background: isDark 
            ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
            : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
          borderRadius: '28px',
          padding: '48px',
          boxShadow: isDark 
            ? '0 25px 50px -12px rgba(0, 0, 0, 0.9), 0 0 0 1px rgba(255, 255, 255, 0.1)'
            : '0 25px 50px -12px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05)',
          cursor: 'pointer',
          transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          overflow: 'hidden',
          animation: `fadeInUp 0.6s ease-out ${delay}ms both`
        }}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {/* Hover overlay */}
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: gradient,
          opacity: isHovered ? 0.08 : 0,
          transition: 'opacity 0.4s ease',
          borderRadius: '28px'
        }} />
        
        {/* Icon container */}
        <div style={{
          width: '80px',
          height: '80px',
          background: gradient,
          borderRadius: '24px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '32px',
          boxShadow: '0 16px 32px -8px rgba(0, 0, 0, 0.2)',
          position: 'relative',
          zIndex: 1,
          transform: isHovered ? 'scale(1.1) rotate(5deg)' : 'scale(1) rotate(0deg)',
          transition: 'transform 0.4s cubic-bezier(0.4, 0, 0.2, 1)'
        }}>
          <div style={{ fontSize: '36px', color: 'white' }}>
            {icon}
          </div>
        </div>
        
        <h3 style={{
          fontSize: '24px',
          fontWeight: '700',
          marginBottom: '20px',
          color: isDark ? '#f1f5f9' : '#1e293b',
          lineHeight: '1.3',
          position: 'relative',
          zIndex: 1
        }}>
          {title}
        </h3>
        
        <p style={{
          color: isDark ? '#cbd5e1' : '#64748b',
          lineHeight: '1.7',
          fontSize: '16px',
          flex: 1,
          position: 'relative',
          zIndex: 1,
          marginBottom: '24px'
        }}>
          {description}
        </p>
        
        <div style={{
          color: isDark ? '#a78bfa' : '#6366f1',
          fontWeight: '600',
          fontSize: '16px',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          position: 'relative',
          zIndex: 1,
          transform: isHovered ? 'translateX(8px)' : 'translateX(0)',
          transition: 'transform 0.3s ease'
        }}>
          Explore Now
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M13.172 12l-4.95-4.95 1.414-1.414L16 12l-6.364 6.364-1.414-1.414z"/>
          </svg>
        </div>
        
        <style jsx>{`
          @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
          }
          .modern-card:hover {
            transform: translateY(-16px) scale(1.02);
          }
        `}</style>
      </div>
    </Link>
  )
}

export const StatsSection = () => {
  const { theme } = useTheme()
  const [mounted, setMounted] = useState(false)
  
  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) return null
  
  const isDark = theme === 'dark'
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(135deg, #0f172a 0%, #1e293b 100%)'
        : 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)',
      borderRadius: '32px',
      padding: '80px 60px',
      margin: '80px 0',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 25px 50px -12px rgba(0, 0, 0, 0.8)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.1)'
    }}>
      <div style={{
        textAlign: 'center',
        marginBottom: '60px'
      }}>
        <h2 style={{
          fontSize: 'clamp(32px, 5vw, 48px)',
          fontWeight: '800',
          marginBottom: '20px',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          Excellence in Numbers
        </h2>
        <p style={{
          fontSize: '20px',
          color: isDark ? '#94a3b8' : '#64748b',
          maxWidth: '600px',
          margin: '0 auto'
        }}>
          Our track record speaks for itself. These achievements represent years of dedication, innovation, and championship-level performance.
        </p>
      </div>
      
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '40px'
      }}>
        {teamStats.map((stat, index) => (
          <div key={index} style={{
            textAlign: 'center',
            padding: '40px 20px',
            borderRadius: '20px',
            background: isDark 
              ? 'rgba(255, 255, 255, 0.03)'
              : 'rgba(255, 255, 255, 0.8)',
            border: isDark 
              ? '1px solid rgba(255, 255, 255, 0.05)'
              : '1px solid rgba(255, 255, 255, 0.5)',
            backdropFilter: 'blur(10px)',
            animation: `fadeInUp 0.6s ease-out ${index * 100}ms both`
          }}>
            <div style={{
              fontSize: 'clamp(40px, 6vw, 64px)',
              fontWeight: '900',
              background: stat.gradient,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              marginBottom: '16px'
            }}>
              {stat.number}
            </div>
            <div style={{
              color: isDark ? '#cbd5e1' : '#64748b',
              fontWeight: '600',
              fontSize: '16px',
              textTransform: 'uppercase',
              letterSpacing: '0.1em'
            }}>
              {stat.label}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export const InteractiveStatsWidget = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [activeCard, setActiveCard] = useState(0);
  const [isAnimating, setIsAnimating] = useState(false);
  
  useEffect(() => {
    setMounted(true);
    const interval = setInterval(() => {
      setIsAnimating(true);
      setTimeout(() => {
        setActiveCard((prev) => (prev + 1) % teamStats.length);
        setIsAnimating(false);
      }, 300);
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      borderRadius: '32px',
      padding: '60px 40px',
      margin: '80px 0',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 25px 50px -12px rgba(0, 0, 0, 0.8)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.1)',
      position: 'relative',
      overflow: 'hidden'
    }}>
      {/* Floating background elements */}
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} style={{
          position: 'absolute',
          top: `${20 + i * 20}%`,
          right: `${10 + i * 15}%`,
          width: `${40 + i * 10}px`,
          height: `${40 + i * 10}px`,
          background: teamStats[activeCard]?.gradient,
          borderRadius: '50%',
          opacity: 0.1,
          animation: `float ${6 + i * 2}s ease-in-out infinite ${i * 0.5}s`,
          transform: isAnimating ? 'scale(1.2)' : 'scale(1)',
          transition: 'transform 0.3s ease'
        }} />
      ))}
      
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '32px',
        position: 'relative',
        zIndex: 1
      }}>
        {teamStats.map((stat, index) => (
          <div 
            key={index}
            style={{
              background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
              borderRadius: '24px',
              padding: '32px 24px',
              textAlign: 'center',
              cursor: 'pointer',
              transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
              border: activeCard === index 
                ? `3px solid ${stat.color}`
                : isDark 
                  ? '1px solid rgba(255, 255, 255, 0.1)'
                  : '1px solid rgba(0, 0, 0, 0.05)',
              transform: activeCard === index 
                ? 'translateY(-12px) scale(1.05)' 
                : 'translateY(0) scale(1)',
              boxShadow: activeCard === index
                ? `0 20px 40px -8px ${stat.color}30`
                : 'none',
              backdropFilter: 'blur(10px)',
              position: 'relative',
              overflow: 'hidden'
            }}
            onClick={() => setActiveCard(index)}
            onMouseEnter={() => setActiveCard(index)}
          >
            {/* Animated background */}
            <div style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: stat.gradient,
              opacity: activeCard === index ? 0.1 : 0.03,
              transition: 'opacity 0.4s ease'
            }} />
            
            {/* Icon with pulse effect */}
            <div style={{
              fontSize: '48px',
              marginBottom: '16px',
              transform: activeCard === index ? 'scale(1.2)' : 'scale(1)',
              transition: 'transform 0.4s ease',
              animation: activeCard === index ? 'pulse 2s infinite' : 'none',
              position: 'relative',
              zIndex: 1
            }}>
              {stat.icon}
            </div>
            
            {/* Number with count-up animation */}
            <div style={{
              fontSize: 'clamp(32px, 5vw, 48px)',
              fontWeight: '900',
              background: stat.gradient,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              marginBottom: '12px',
              transform: isAnimating && activeCard === index ? 'scale(1.1)' : 'scale(1)',
              transition: 'transform 0.3s ease',
              position: 'relative',
              zIndex: 1
            }}>
              {stat.number}
            </div>
            
            {/* Label with underline animation */}
            <div style={{
              color: isDark ? '#cbd5e1' : '#64748b',
              fontWeight: '600',
              fontSize: '14px',
              textTransform: 'uppercase',
              letterSpacing: '0.1em',
              position: 'relative',
              zIndex: 1
            }}>
              {stat.label}
              <div style={{
                height: '2px',
                background: stat.gradient,
                marginTop: '8px',
                borderRadius: '1px',
                transform: activeCard === index ? 'scaleX(1)' : 'scaleX(0)',
                transition: 'transform 0.4s ease',
                transformOrigin: 'left'
              }} />
            </div>
          </div>
        ))}
      </div>
      
      {/* Progress indicator */}
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        gap: '12px',
        marginTop: '40px',
        position: 'relative',
        zIndex: 1
      }}>
        {teamStats.map((_, index) => (
          <div
            key={index}
            style={{
              width: '12px',
              height: '12px',
              borderRadius: '50%',
              background: activeCard === index 
                ? teamStats[activeCard].gradient 
                : isDark ? 'rgba(255, 255, 255, 0.3)' : 'rgba(0, 0, 0, 0.2)',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              transform: activeCard === index ? 'scale(1.2)' : 'scale(1)'
            }}
            onClick={() => setActiveCard(index)}
          />
        ))}
      </div>
      
      <style jsx>{`
        @keyframes pulse {
          0%, 100% { transform: scale(1.2); }
          50% { transform: scale(1.3); }
        }
      `}</style>
    </div>
  );
};

export const ModernWidgetGrid = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const widgets = [
    {
      icon: '🎯',
      title: 'Purpose Statement',
      description: 'Inspire students to be STEM leaders through mentoring and innovation.',
      gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      metric: 'Mission Driven',
      value: '100%'
    },
    {
      icon: '🤝',
      title: 'Gracious Professionalism',
      description: 'Compete fiercely while treating everyone with respect and kindness.',
      gradient: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
      metric: 'Core Value',
      value: 'Always'
    },
    {
      icon: '🌱',
      title: 'Community Impact',
      description: 'Promoting STEM education in Rochester/Rochester Hills community.',
      gradient: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
      metric: 'Community Reach',
      value: 'Growing'
    }
  ];

  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
      gap: '24px',
      margin: '60px 0'
    }}>
      {widgets.map((widget, index) => (
        <div
          key={index}
          style={{
            background: isDark 
              ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
              : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
            borderRadius: '24px',
            padding: '32px',
            border: isDark 
              ? '1px solid rgba(255, 255, 255, 0.1)'
              : '1px solid rgba(0, 0, 0, 0.05)',
            boxShadow: isDark 
              ? '0 16px 32px -8px rgba(0, 0, 0, 0.6)'
              : '0 16px 32px -8px rgba(0, 0, 0, 0.1)',
            cursor: 'pointer',
            transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
            position: 'relative',
            overflow: 'hidden',
            animation: `slideInUp 0.6s ease-out ${index * 150}ms both`
          }}
          className="modern-widget"
        >
          {/* Gradient overlay */}
          <div style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            height: '4px',
            background: widget.gradient,
            borderRadius: '24px 24px 0 0'
          }} />
          
          {/* Header */}
          <div style={{
            display: 'flex',
            alignItems: 'flex-start',
            justifyContent: 'space-between',
            marginBottom: '20px'
          }}>
            <div style={{
              width: '56px',
              height: '56px',
              background: widget.gradient,
              borderRadius: '20px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '28px',
              boxShadow: '0 8px 16px rgba(0, 0, 0, 0.1)'
            }}>
              {widget.icon}
            </div>
            
            <div style={{
              textAlign: 'right'
            }}>
              <div style={{
                fontSize: '12px',
                fontWeight: '600',
                color: isDark ? '#94a3b8' : '#64748b',
                textTransform: 'uppercase',
                letterSpacing: '0.1em',
                marginBottom: '4px'
              }}>
                {widget.metric}
              </div>
              <div style={{
                fontSize: '20px',
                fontWeight: '800',
                background: widget.gradient,
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent'
              }}>
                {widget.value}
              </div>
            </div>
          </div>
          
          {/* Content */}
          <h3 style={{
            fontSize: '20px',
            fontWeight: '700',
            marginBottom: '12px',
            color: isDark ? '#f1f5f9' : '#1e293b'
          }}>
            {widget.title}
          </h3>
          
          <p style={{
            color: isDark ? '#cbd5e1' : '#64748b',
            lineHeight: '1.6',
            fontSize: '14px',
            margin: 0
          }}>
            {widget.description}
          </p>
          
          {/* Interactive indicator */}
          <div style={{
            position: 'absolute',
            bottom: '16px',
            right: '16px',
            width: '8px',
            height: '8px',
            borderRadius: '50%',
            background: widget.gradient,
            opacity: 0,
            transition: 'opacity 0.3s ease'
          }} className="widget-indicator" />
        </div>
      ))}
      
      <style jsx>{`
        .modern-widget:hover {
          transform: translateY(-8px) scale(1.02);
          box-shadow: 0 24px 48px -12px rgba(0, 0, 0, 0.2);
        }
        
        .modern-widget:hover .widget-indicator {
          opacity: 1;
        }
        
        @keyframes slideInUp {
          from { opacity: 0; transform: translateY(30px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
};

export const EnhancedHandbookHero = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  
  useEffect(() => {
    setMounted(true);
    
    const handleMouseMove = (e) => {
      setMousePosition({
        x: (e.clientX / window.innerWidth) * 100,
        y: (e.clientY / window.innerHeight) * 100
      });
    };
    
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  return (
    <div style={{
      background: isDark 
        ? `radial-gradient(circle at ${mousePosition.x}% ${mousePosition.y}%, #1a1a3e 0%, #0f0f23 50%, #1a1a2e 100%)`
        : `radial-gradient(circle at ${mousePosition.x}% ${mousePosition.y}%, #667eea 0%, #764ba2 25%, #f093fb 50%, #f5576c 100%)`,
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      position: 'relative',
      overflow: 'hidden',
      borderRadius: '32px',
      margin: '40px 0',
      boxShadow: isDark 
        ? '0 25px 50px -12px rgba(0, 0, 0, 0.9), 0 0 0 1px rgba(255, 255, 255, 0.1)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.25), 0 0 0 1px rgba(255, 255, 255, 0.2)',
      transition: 'background 0.3s ease'
    }}>
      {/* Enhanced floating particles */}
      {Array.from({ length: 12 }).map((_, i) => (
        <div key={i} style={{
          position: 'absolute',
          top: `${Math.random() * 100}%`,
          left: `${Math.random() * 100}%`,
          width: `${40 + i * 8}px`,
          height: `${40 + i * 8}px`,
          background: isDark 
            ? `rgba(167, 139, 250, ${0.05 + i * 0.01})`
            : `rgba(255, 255, 255, ${0.1 + i * 0.01})`,
          borderRadius: '50%',
          animation: `float ${6 + i * 1.5}s ease-in-out infinite ${i * 0.3}s`,
          backdropFilter: 'blur(10px)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          transform: `translate(${(mousePosition.x - 50) * 0.1}px, ${(mousePosition.y - 50) * 0.1}px)`
        }} />
      ))}
      
      {/* Content with enhanced interactivity */}
      <div style={{
        textAlign: 'center',
        color: 'white',
        zIndex: 10,
        maxWidth: '1000px',
        padding: '80px 40px',
        transform: `translate(${(mousePosition.x - 50) * 0.02}px, ${(mousePosition.y - 50) * 0.02}px)`,
        transition: 'transform 0.1s ease-out'
      }}>
        <div style={{
          fontSize: 'clamp(48px, 8vw, 96px)',
          fontWeight: '900',
          marginBottom: '32px',
          textShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
          letterSpacing: '-0.02em',
          animation: 'slideInDown 1s ease-out',
          background: 'linear-gradient(135deg, #ffffff 0%, #a78bfa 50%, #06b6d4 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          position: 'relative'
        }}>
          FEDS 201
          {/* Glowing effect */}
          <div style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'linear-gradient(135deg, #ffffff 0%, #a78bfa 50%, #06b6d4 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            filter: 'blur(20px)',
            opacity: 0.3,
            zIndex: -1
          }}>
            FEDS 201
          </div>
        </div>
        
        <div style={{
          fontSize: 'clamp(24px, 4vw, 36px)',
          fontWeight: '700',
          marginBottom: '24px',
          opacity: '0.95',
          animation: 'slideInUp 1s ease-out 0.2s both'
        }}>
          Rochester High School Robotics
        </div>
        
        <div style={{
          fontSize: 'clamp(16px, 2vw, 20px)',
          marginBottom: '48px',
          opacity: '0.9',
          lineHeight: '1.8',
          animation: 'fadeIn 1s ease-out 0.4s both',
          maxWidth: '700px',
          margin: '0 auto 48px'
        }}>
          Your comprehensive guide to joining our robotics family. From FIRST principles to technical excellence - everything you need to build lifelong skills and friendships.
        </div>
        
        {/* Enhanced buttons with glassmorphism */}
        <div style={{
          display: 'flex',
          gap: '24px',
          justifyContent: 'center',
          flexWrap: 'wrap',
          animation: 'slideInUp 1s ease-out 0.6s both'
        }}>
          <button
            style={{
              background: 'linear-gradient(135deg, rgba(102, 126, 234, 0.9) 0%, rgba(118, 75, 162, 0.9) 100%)',
              color: 'white',
              border: '1px solid rgba(255, 255, 255, 0.2)',
              borderRadius: '16px',
              padding: '20px 40px',
              fontSize: '18px',
              fontWeight: '700',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              boxShadow: '0 8px 32px rgba(102, 126, 234, 0.4)',
              backdropFilter: 'blur(10px)',
              position: 'relative',
              overflow: 'hidden'
            }}
            className="hero-button-primary"
            onClick={() => window.location.href = 'https://feds201.com/'}
          >
            <span style={{ position: 'relative', zIndex: 1 }}>🚀 Join the Team</span>
          </button>
          <button style={{
            background: 'rgba(255, 255, 255, 0.1)',
            color: 'white',
            border: '2px solid rgba(255, 255, 255, 0.3)',
            borderRadius: '16px',
            padding: '20px 40px',
            fontSize: '18px',
            fontWeight: '700',
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            backdropFilter: 'blur(10px)',
            position: 'relative',
            overflow: 'hidden'
          }}
          className="hero-button-secondary"
           onClick={() => window.location.href = 'https://feds201.com/#about-us'}
          >
            <span style={{ position: 'relative', zIndex: 1 }}>📚 Learn More</span>
          </button>
        </div>
      </div>
      
      <style jsx>{`
        .hero-button-primary:hover {
          transform: translateY(-4px) scale(1.05);
          box-shadow: 0 16px 48px rgba(102, 126, 234, 0.6);
        }
        
        .hero-button-secondary:hover {
          transform: translateY(-4px) scale(1.05);
          background: rgba(255, 255, 255, 0.2);
          border-color: rgba(255, 255, 255, 0.5);
        }
        
        .hero-button-primary::before,
        .hero-button-secondary::before {
          content: '';
          position: absolute;
          top: 0;
          left: -100%;
          width: 100%;
          height: 100%;
          background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
          transition: left 0.5s ease;
        }
        
        .hero-button-primary:hover::before,
        .hero-button-secondary:hover::before {
          left: 100%;
        }
      `}</style>
    </div>
  );
};

export const InteractiveTimeline = () => {
  const { theme } = useTheme();
  const [activePhase, setActivePhase] = useState(0);
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const phases = [
    {
      season: 'Fall',
      title: 'Training & Preparation',
      icon: '🍂',
      color: '#f59e0b',
      activities: ['Recruit new members', 'Training workshops', 'Mentoring FTC teams', 'Fundraising kickoff'],
      gradient: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)'
    },
    {
      season: 'Winter',
      title: 'Build Season',
      icon: '❄️',
      color: '#3b82f6',
      activities: ['January kickoff', 'Robot design & construction', 'Programming integration', 'Driver practice'],
      gradient: 'linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%)'
    },
    {
      season: 'Spring',
      title: 'Competition Season',
      icon: '🌸',
      color: '#10b981',
      activities: ['District competitions', 'State championship', 'World championship', 'Season celebration'],
      gradient: 'linear-gradient(135deg, #10b981 0%, #059669 100%)'
    },
    {
      season: 'Summer',
      title: 'Growth & Planning',
      icon: '☀️',
      color: '#f97316',
      activities: ['Leadership training', 'Team improvements', 'Outreach events', 'Strategic planning'],
      gradient: 'linear-gradient(135deg, #f97316 0%, #ea580c 100%)'
    }
  ];

  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      borderRadius: '32px',
      padding: '80px 40px',
      margin: '80px 0',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 25px 50px -12px rgba(0, 0, 0, 0.8)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.1)'
    }}>
      <div style={{
        textAlign: 'center',
        marginBottom: '60px'
      }}>
        <h2 style={{
          fontSize: 'clamp(32px, 5vw, 48px)',
          fontWeight: '800',
          marginBottom: '20px',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          Year-Round Excellence
        </h2>
        <p style={{
          fontSize: '20px',
          color: isDark ? '#94a3b8' : '#64748b',
          maxWidth: '600px',
          margin: '0 auto'
        }}>
          Our championship journey spans every season with dedicated focus and continuous improvement.
        </p>
      </div>
      
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '32px'
      }}>
        {phases.map((phase, index) => (
          <div 
            key={index}
            style={{
              background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
              borderRadius: '24px',
              padding: '40px',
              cursor: 'pointer',
              transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
              border: activePhase === index 
                ? `3px solid ${phase.color}`
                : isDark 
                  ? '1px solid rgba(255, 255, 255, 0.1)'
                  : '1px solid rgba(0, 0, 0, 0.05)',
              transform: activePhase === index ? 'translateY(-8px) scale(1.02)' : 'translateY(0) scale(1)',
              boxShadow: activePhase === index
                ? `0 20px 40px -12px ${phase.color}40`
                : isDark 
                  ? '0 8px 16px rgba(0, 0, 0, 0.4)'
                  : '0 8px 16px rgba(0, 0, 0, 0.1)',
              position: 'relative',
              overflow: 'hidden'
            }}
            onClick={() => setActivePhase(index)}
          >
            {/* Background gradient overlay */}
            <div style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: phase.gradient,
              opacity: activePhase === index ? 0.1 : 0.05,
              transition: 'opacity 0.4s ease'
            }} />
            
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              marginBottom: '24px',
              position: 'relative',
              zIndex: 1
            }}>
              <div style={{
                fontSize: '48px',
                transform: activePhase === index ? 'scale(1.2) rotate(10deg)' : 'scale(1)',
                transition: 'transform 0.4s ease'
              }}>
                {phase.icon}
              </div>
              <div>
                <h3 style={{
                  fontSize: '24px',
                  fontWeight: '800',
                  color: isDark ? '#f1f5f9' : '#1e293b',
                  marginBottom: '4px'
                }}>
                  {phase.season}
                </h3>
                <p style={{
                  fontSize: '16px',
                  color: phase.color,
                  fontWeight: '600'
                }}>
                  {phase.title}
                </p>
              </div>
            </div>
            
            <div style={{
              position: 'relative',
              zIndex: 1
            }}>
              {phase.activities.map((activity, actIndex) => (
                <div key={actIndex} style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  marginBottom: '12px',
                  padding: '8px 0',
                  borderBottom: actIndex < phase.activities.length - 1 
                    ? isDark 
                      ? '1px solid rgba(255, 255, 255, 0.1)'
                      : '1px solid rgba(0, 0, 0, 0.05)'
                    : 'none'
                }}>
                  <div style={{
                    width: '8px',
                    height: '8px',
                    borderRadius: '50%',
                    background: phase.gradient
                  }} />
                  <span style={{
                    color: isDark ? '#cbd5e1' : '#64748b',
                    fontSize: '14px',
                    fontWeight: '500'
                  }}>
                    {activity}
                  </span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export const TeamStructureGrid = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const subTeams = [
    {
      category: 'Technical Excellence',
      icon: '⚙️',
      gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      teams: [
        { name: 'CAD/Design', description: 'Robot design & 3D modeling', icon: '📐' },
        { name: 'Programming', description: 'Autonomous & teleoperated code', icon: '💻' },
        { name: 'Mechanical', description: 'Assembly & testing', icon: '🔧' },
        { name: 'Electrical', description: 'Wiring & control systems', icon: '⚡' }
      ]
    },
    {
      category: 'Operations & Culture',
      icon: '👥',
      gradient: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
      teams: [
        { name: 'Safety', description: 'Safety protocols & training', icon: '🛡️' },
        { name: 'Business Planning', description: 'Strategy & financial management', icon: '📊' },
        { name: 'Marketing', description: 'Brand & STEM advocacy', icon: '📢' },
        { name: 'Spirit', description: 'Team culture & identity', icon: '🎉' }
      ]
    },
    {
      category: 'Competition Operations',
      icon: '🏆',
      gradient: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
      teams: [
        { name: 'Scouting', description: 'Data analysis & strategy', icon: '🔍' },
        { name: 'Drive Team', description: 'Robot operation & coaching', icon: '🎮' },
        { name: 'Field Build', description: 'Practice field construction', icon: '🏗️' },
        { name: 'Awards', description: 'Recognition & presentations', icon: '🏅' }
      ]
    }
  ];

  return (
    <div style={{
      padding: '80px 0'
    }}>
      <div style={{
        textAlign: 'center',
        marginBottom: '60px'
      }}>
        <h2 style={{
          fontSize: 'clamp(32px, 5vw, 48px)',
          fontWeight: '800',
          marginBottom: '20px',
          background: isDark 
            ? 'linear-gradient(135deg, #a78bfa 0%, #06b6d4 50%, #10b981 100%)'
            : 'linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent'
        }}>
          Championship Team Structure
        </h2>
        <p style={{
          fontSize: '20px',
          color: isDark ? '#94a3b8' : '#64748b',
          maxWidth: '800px',
          margin: '0 auto'
        }}>
          Every member finds their place in our championship ecosystem. Multiple pathways to excellence, unified by our mission.
        </p>
      </div>
      
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
        gap: '40px'
      }}>
        {subTeams.map((category, catIndex) => (
          <div key={catIndex} style={{
            background: isDark 
              ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
              : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
            borderRadius: '28px',
            padding: '40px',
            border: isDark 
              ? '1px solid rgba(255, 255, 255, 0.1)'
              : '1px solid rgba(0, 0, 0, 0.05)',
            boxShadow: isDark 
              ? '0 20px 40px -12px rgba(0, 0, 0, 0.8)'
              : '0 20px 40px -12px rgba(0, 0, 0, 0.1)',
            position: 'relative',
            overflow: 'hidden'
          }}>
            {/* Category header */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              marginBottom: '32px'
            }}>
              <div style={{
                width: '64px',
                height: '64px',
                background: category.gradient,
                borderRadius: '20px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '28px'
              }}>
                {category.icon}
              </div>
              <h3 style={{
                fontSize: '24px',
                fontWeight: '800',
                color: isDark ? '#f1f5f9' : '#1e293b'
              }}>
                {category.category}
              </h3>
            </div>
            
            {/* Sub-teams */}
            <div style={{
              display: 'grid',
              gap: '16px'
            }}>
              {category.teams.map((team, teamIndex) => (
                <div key={teamIndex} style={{
                  background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
                  borderRadius: '16px',
                  padding: '20px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '16px',
                  transition: 'all 0.3s ease',
                  cursor: 'pointer',
                  ':hover': {
                    transform: 'translateX(8px)',
                    background: isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(255, 255, 255, 1)'
                  }
                }}>
                  <div style={{
                    fontSize: '24px',
                    minWidth: '32px'
                  }}>
                    {team.icon}
                  </div>
                  <div>
                    <h4 style={{
                      fontSize: '16px',
                      fontWeight: '700',
                      color: isDark ? '#f1f5f9' : '#1e293b',
                      marginBottom: '4px'
                    }}>
                      {team.name}
                    </h4>
                    <p style={{
                      fontSize: '14px',
                      color: isDark ? '#94a3b8' : '#64748b',
                      margin: 0
                    }}>
                      {team.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export const ProgrammingHero = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [codeExample, setCodeExample] = useState(0);
  
  useEffect(() => {
    setMounted(true);
    const interval = setInterval(() => {
      setCodeExample((prev) => (prev + 1) % 3);
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const codeExamples = [
    {
      title: "Drive Control",
      code: `public void teleopPeriodic() {
  double speed = -controller.getLeftY();
  double rotation = controller.getRightX();
  drive.arcadeDrive(speed, rotation);
}`,
      language: "java"
    },
    {
      title: "Autonomous",
      code: `public void autonomousInit() {
  trajectory = PathPlanner.loadPath(
    "ExamplePath", 4.0, 3.0);
  ramseteCommand = new RamseteCommand(
    trajectory, drive::getPose,
    new RamseteController(),
    drive::tankDriveVolts, drive);
}`,
      language: "java"
    },
    {
      title: "Vision Processing",
      code: `PhotonTrackedTarget target = 
  camera.getLatestResult()
        .getBestTarget();
if (target != null) {
  double range = 
    PhotonUtils.calculateDistanceToTarget(
      cameraHeight, targetHeight,
      cameraPitch, target.getPitch());
}`,
      language: "java"
    }
  ];
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(135deg, #1a1a2e 0%, #16213e 25%, #0f3460 50%, #533483 100%)'
        : 'linear-gradient(135deg, #667eea 0%, #764ba2 25%, #f093fb 50%, #4facfe 100%)',
      minHeight: '90vh',
      display: 'flex',
      alignItems: 'center',
      position: 'relative',
      overflow: 'hidden',
      borderRadius: '32px',
      margin: '40px 0',
      boxShadow: isDark 
        ? '0 25px 50px -12px rgba(0, 0, 0, 0.9)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.25)'
    }}>
      {/* Animated code symbols */}
      {['{}', '[]', '()', '<>', '//', '==', '&&', '||'].map((symbol, i) => (
        <div key={i} style={{
          position: 'absolute',
          top: `${10 + (i * 12)}%`,
          left: `${5 + (i * 11)}%`,
          fontSize: `${20 + i * 4}px`,
          color: isDark ? 'rgba(167, 139, 250, 0.3)' : 'rgba(255, 255, 255, 0.4)',
          fontFamily: 'monospace',
          fontWeight: 'bold',
          animation: `float ${8 + i}s ease-in-out infinite ${i * 0.5}s`,
          pointerEvents: 'none'
        }}>
          {symbol}
        </div>
      ))}
      
      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '60px',
        alignItems: 'center',
        maxWidth: '1200px',
        margin: '0 auto',
        padding: '80px 40px',
        position: 'relative',
        zIndex: 1
      }}>
        {/* Left side - Content */}
        <div style={{ color: 'white' }}>
          <div style={{
            fontSize: 'clamp(40px, 6vw, 72px)',
            fontWeight: '900',
            marginBottom: '24px',
            background: 'linear-gradient(135deg, #ffffff 0%, #a78bfa 50%, #06b6d4 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            lineHeight: '1.1'
          }}>
            Programming Excellence
          </div>
          
          <div style={{
            fontSize: 'clamp(18px, 3vw, 24px)',
            marginBottom: '32px',
            opacity: '0.95',
            lineHeight: '1.6'
          }}>
            Master the art of competitive robotics programming. From Java fundamentals to advanced autonomous systems.
          </div>
          
          <div style={{
            display: 'flex',
            gap: '20px',
            flexWrap: 'wrap'
          }}>
            <button style={{
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '12px',
              padding: '16px 32px',
              fontSize: '16px',
              fontWeight: '700',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              boxShadow: '0 8px 16px rgba(102, 126, 234, 0.4)'
            }}>
              🚀 Start Learning
            </button>
            <button style={{
              background: 'rgba(255, 255, 255, 0.1)',
              color: 'white',
              border: '2px solid rgba(255, 255, 255, 0.3)',
              borderRadius: '12px',
              padding: '16px 32px',
              fontSize: '16px',
              fontWeight: '700',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              backdropFilter: 'blur(10px)'
            }}>
              📚 View Examples
            </button>
          </div>
        </div>
        
        {/* Right side - Code Example */}
        <div style={{
          background: isDark ? 'rgba(15, 23, 42, 0.9)' : 'rgba(255, 255, 255, 0.15)',
          backdropFilter: 'blur(20px)',
          borderRadius: '20px',
          padding: '24px',
          border: '1px solid rgba(255, 255, 255, 0.2)',
          fontFamily: 'monospace',
          position: 'relative',
          overflow: 'hidden'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            marginBottom: '16px',
            paddingBottom: '12px',
            borderBottom: '1px solid rgba(255, 255, 255, 0.1)'
          }}>
            <div style={{
              width: '12px',
              height: '12px',
              borderRadius: '50%',
              background: '#ff5f56'
            }} />
            <div style={{
              width: '12px',
              height: '12px',
              borderRadius: '50%',
              background: '#ffbd2e'
            }} />
            <div style={{
              width: '12px',
              height: '12px',
              borderRadius: '50%',
              background: '#27ca3f'
            }} />
            <span style={{
              color: 'white',
              fontSize: '14px',
              fontWeight: '600',
              marginLeft: '12px'
            }}>
              {codeExamples[codeExample].title}
            </span>
          </div>
          
          <pre style={{
            color: 'white',
            fontSize: '14px',
            lineHeight: '1.6',
            margin: 0,
            whiteSpace: 'pre-wrap',
            transition: 'all 0.5s ease'
          }}>
            <code>
              {codeExamples[codeExample].code}
            </code>
          </pre>
          
          {/* Code indicators */}
          <div style={{
            display: 'flex',
            gap: '8px',
            marginTop: '16px',
            justifyContent: 'center'
          }}>
            {codeExamples.map((_, index) => (
              <div
                key={index}
                style={{
                  width: '8px',
                  height: '8px',
                  borderRadius: '50%',
                  background: codeExample === index 
                    ? '#667eea' 
                    : 'rgba(255, 255, 255, 0.3)',
                  transition: 'all 0.3s ease'
                }}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export const ProgrammingStats = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const stats = [
    { value: '50ms', label: 'Loop Cycle Time', icon: '⚡', description: 'Critical real-time performance' },
    { value: '15fps', label: 'Vision Processing', icon: '👁️', description: 'Real-time target tracking' },
    { value: '120lbs', label: 'Robot Weight', icon: '🤖', description: 'Your code controls this mass' },
    { value: '2.5min', label: 'Match Duration', icon: '⏱️', description: 'Every second counts' }
  ];
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      borderRadius: '24px',
      padding: '60px 40px',
      margin: '60px 0',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 20px 40px -12px rgba(0, 0, 0, 0.8)'
        : '0 20px 40px -12px rgba(0, 0, 0, 0.1)'
    }}>
      <div style={{
        textAlign: 'center',
        marginBottom: '50px'
      }}>
        <h2 style={{
          fontSize: 'clamp(28px, 4vw, 36px)',
          fontWeight: '800',
          marginBottom: '16px',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          Programming by the Numbers
        </h2>
        <p style={{
          color: isDark ? '#94a3b8' : '#64748b',
          fontSize: '18px'
        }}>
          Understanding the technical constraints and performance requirements
        </p>
      </div>
      
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '32px'
      }}>
        {stats.map((stat, index) => (
          <div key={index} style={{
            background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
            borderRadius: '20px',
            padding: '32px 24px',
            textAlign: 'center',
            transition: 'all 0.3s ease',
            cursor: 'pointer',
            border: isDark 
              ? '1px solid rgba(255, 255, 255, 0.1)'
              : '1px solid rgba(0, 0, 0, 0.05)',
            ':hover': {
              transform: 'translateY(-8px)'
            }
          }}>
            <div style={{
              fontSize: '40px',
              marginBottom: '16px'
            }}>
              {stat.icon}
            </div>
            <div style={{
              fontSize: 'clamp(24px, 4vw, 36px)',
              fontWeight: '800',
              marginBottom: '8px',
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent'
            }}>
              {stat.value}
            </div>
            <div style={{
              fontSize: '16px',
              fontWeight: '600',
              color: isDark ? '#cbd5e1' : '#475569',
              marginBottom: '8px'
            }}>
              {stat.label}
            </div>
            <div style={{
              fontSize: '14px',
              color: isDark ? '#94a3b8' : '#64748b'
            }}>
              {stat.description}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export const SkillsMatrix = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [selectedSkill, setSelectedSkill] = useState(0);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const skills = [
    {
      name: 'Java Fundamentals',
      level: 90,
      description: 'Object-oriented programming, inheritance, polymorphism',
      color: '#f59e0b'
    },
    {
      name: 'WPILib Framework',
      level: 85,
      description: 'Command-based programming, subsystems, and schedulers',
      color: '#10b981'
    },
    {
      name: 'Hardware Integration',
      level: 80,
      description: 'Motors, sensors, pneumatics, and CAN bus communication',
      color: '#3b82f6'
    },
    {
      name: 'Autonomous Programming',
      level: 75,
      description: 'Path planning, trajectory following, and state machines',
      color: '#8b5cf6'
    },
    {
      name: 'Computer Vision',
      level: 70,
      description: 'OpenCV, PhotonVision, and real-time image processing',
      color: '#ef4444'
    },
    {
      name: 'Debugging & Testing',
      level: 88,
      description: 'Unit testing, simulation, and systematic troubleshooting',
      color: '#06b6d4'
    }
  ];
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      borderRadius: '24px',
      padding: '50px 40px',
      margin: '60px 0',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 20px 40px -12px rgba(0, 0, 0, 0.8)'
        : '0 20px 40px -12px rgba(0, 0, 0, 0.1)'
    }}>
      <div style={{
        textAlign: 'center',
        marginBottom: '40px'
      }}>
        <h3 style={{
          fontSize: 'clamp(24px, 4vw, 32px)',
          fontWeight: '800',
          marginBottom: '16px',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          Essential Programming Skills
        </h3>
        <p style={{
          color: isDark ? '#94a3b8' : '#64748b',
          fontSize: '16px'
        }}>
          Master these core competencies for FRC programming success
        </p>
      </div>
      
      <div style={{
        display: 'grid',
        gap: '24px'
      }}>
        {skills.map((skill, index) => (
          <div 
            key={index}
            style={{
              background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
              borderRadius: '16px',
              padding: '24px',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              border: selectedSkill === index 
                ? `2px solid ${skill.color}`
                : isDark 
                  ? '1px solid rgba(255, 255, 255, 0.1)'
                  : '1px solid rgba(0, 0, 0, 0.05)',
              transform: selectedSkill === index ? 'scale(1.02)' : 'scale(1)'
            }}
            onClick={() => setSelectedSkill(index)}
          >
            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: '12px'
            }}>
              <span style={{
                fontSize: '18px',
                fontWeight: '700',
                color: isDark ? '#f1f5f9' : '#1e293b'
              }}>
                {skill.name}
              </span>
              <span style={{
                fontSize: '16px',
                fontWeight: '600',
                color: skill.color
              }}>
                {skill.level}%
              </span>
            </div>
            
            <div style={{
              background: isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
              borderRadius: '8px',
              height: '8px',
              marginBottom: '12px',
              overflow: 'hidden'
            }}>
              <div style={{
                background: skill.color,
                height: '100%',
                width: `${skill.level}%`,
                borderRadius: '8px',
                transition: 'width 1s ease'
              }} />
            </div>
            
            <p style={{
              color: isDark ? '#cbd5e1' : '#64748b',
              fontSize: '14px',
              margin: 0,
              lineHeight: '1.5'
            }}>
              {skill.description}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
};

export const ProgrammingPath = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const pathSteps = [
    {
      phase: 'Foundation',
      title: 'Java & OOP Basics',
      duration: '2-3 weeks',
      topics: ['Variables & Methods', 'Classes & Objects', 'Inheritance', 'Debugging'],
      color: '#f59e0b'
    },
    {
      phase: 'Framework',
      title: 'WPILib & Command-Based',
      duration: '3-4 weeks',
      topics: ['Subsystems', 'Commands', 'Schedulers', 'Robot Class'],
      color: '#10b981'
    },
    {
      phase: 'Hardware',
      title: 'Sensors & Actuators',
      duration: '2-3 weeks',
      topics: ['Motor Controllers', 'Encoders', 'Gyroscopes', 'Pneumatics'],
      color: '#3b82f6'
    },
    {
      phase: 'Advanced',
      title: 'Autonomous & Vision',
      duration: '4-5 weeks',
      topics: ['Path Planning', 'PID Control', 'Computer Vision', 'State Machines'],
      color: '#8b5cf6'
    }
  ];
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      borderRadius: '24px',
      padding: '50px 40px',
      margin: '60px 0',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 20px 40px -12px rgba(255, 255, 255, 0.1)'
        : '0 20px 40px -12px rgba(0, 0, 0, 0.1)'
    }}>
      <div style={{
        textAlign: 'center',
        marginBottom: '40px'
      }}>
        <h3 style={{
          fontSize: 'clamp(24px, 4vw, 32px)',
          fontWeight: '800',
          marginBottom: '16px',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          Your Learning Pathway
        </h3>
        <p style={{
          color: isDark ? '#94a3b8' : '#64748b',
          fontSize: '16px'
        }}>
          Structured progression from beginner to advanced FRC programmer
        </p>
      </div>
      
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '32px',
        position: 'relative'
      }}>
        {pathSteps.map((step, index) => (
          <div key={index} style={{
            background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
            borderRadius: '20px',
            padding: '32px',
            position: 'relative',
            border: `2px solid ${step.color}`,
            transition: 'all 0.3s ease'
          }}>
            <div style={{
              position: 'absolute',
              top: '-12px',
              left: '24px',
              background: step.color,
              color: 'white',
              padding: '6px 16px',
              borderRadius: '12px',
              fontSize: '12px',
              fontWeight: '700',
              textTransform: 'uppercase',
              letterSpacing: '0.1em'
            }}>
              {step.phase}
            </div>
            
            <div style={{
              marginTop: '20px'
            }}>
              <h4 style={{
                fontSize: '20px',
                fontWeight: '700',
                marginBottom: '8px',
                color: isDark ? '#f1f5f9' : '#1e293b'
              }}>
                {step.title}
              </h4>
              
              <div style={{
                fontSize: '14px',
                color: step.color,
                fontWeight: '600',
                marginBottom: '20px'
              }}>
                Duration: {step.duration}
              </div>
              
              <div style={{
                display: 'grid',
                gap: '8px'
              }}>
                {step.topics.map((topic, topicIndex) => (
                  <div key={topicIndex} style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    padding: '8px 0'
                  }}>
                    <div style={{
                      width: '6px',
                      height: '6px',
                      borderRadius: '50%',
                      background: step.color
                    }} />
                    <span style={{
                      color: isDark ? '#cbd5e1' : '#64748b',
                      fontSize: '14px'
                    }}>
                      {topic}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export const LiveCodeDemo = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [activeTab, setActiveTab] = useState(0);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const demos = [
    {
      title: "Tank Drive",
      description: "Basic robot driving with tank-style controls",
      code: `public class DriveSubsystem extends SubsystemBase {
  private final WPI_TalonFX leftMotor;
  private final WPI_TalonFX rightMotor;
  
  public void tankDrive(double leftSpeed, double rightSpeed) {
    leftMotor.set(leftSpeed);
    rightMotor.set(rightSpeed);
  }
  
  public void arcadeDrive(double speed, double rotation) {
    tankDrive(speed + rotation, speed - rotation);
  }
}`
    },
    {
      title: "PID Control",
      description: "Precise position control using PID algorithms",
      code: `public class ElevatorSubsystem extends SubsystemBase {
  private final PIDController pidController;
  private final WPI_TalonFX motor;
  
  public ElevatorSubsystem() {
    pidController = new PIDController(0.5, 0.0, 0.1);
    pidController.setTolerance(0.5);
  }
  
  public void setPosition(double targetPosition) {
    double output = pidController.calculate(
      motor.getSelectedSensorPosition(), 
      targetPosition
    );
    motor.set(output);
  }
}`
    },
    {
      title: "Autonomous Command",
      description: "Sequential autonomous routine using commands",
      code: `public class AutonomousCommand extends SequentialCommandGroup {
  public AutonomousCommand(DriveSubsystem drive, ShooterSubsystem shooter) {
    addCommands(
      new DriveForwardCommand(drive, 2.0),
      new TurnToAngleCommand(drive, 90),
      new ShootCommand(shooter, 3500),
      new DriveForwardCommand(drive, 1.5)
    );
  }
}`
    }
  ];
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      borderRadius: '24px',
      padding: '50px 40px',
      margin: '60px 0',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 20px 40px -12px rgba(255, 255, 255, 0.1)'
        : '0 20px 40px -12px rgba(0, 0, 0, 0.1)'
    }}>
      <div style={{
        textAlign: 'center',
        marginBottom: '40px'
      }}>
        <h3 style={{
          fontSize: 'clamp(24px, 4vw, 32px)',
          fontWeight: '800',
          marginBottom: '16px',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          Interactive Code Examples
        </h3>
        <p style={{
          color: isDark ? '#94a3b8' : '#64748b',
          fontSize: '16px'
        }}>
          Explore real FRC code patterns and best practices
        </p>
      </div>
      
      {/* Tab Navigation */}
      <div style={{
        display: 'flex',
        gap: '8px',
        marginBottom: '24px',
        justifyContent: 'center',
        flexWrap: 'wrap'
      }}>
        {demos.map((demo, index) => (
          <button
            key={index}
            style={{
              background: activeTab === index 
                ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
                : isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)',
              color: activeTab === index ? 'white' : isDark ? '#cbd5e1' : '#64748b',
              border: 'none',
              borderRadius: '12px',
              padding: '12px 24px',
              fontSize: '14px',
              fontWeight: '600',
              cursor: 'pointer',
              transition: 'all 0.3s ease'
            }}
            onClick={() => setActiveTab(index)}
          >
            {demo.title}
          </button>
        ))}
      </div>
      
      {/* Code Display */}
      <div style={{
        background: isDark ? '#0f172a' : '#f8fafc',
        borderRadius: '16px',
        border: isDark 
          ? '1px solid rgba(255, 255, 255, 0.1)'
          : '1px solid rgba(0, 0, 0, 0.1)',
        overflow: 'hidden'
      }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          padding: '16px 24px',
          borderBottom: isDark 
            ? '1px solid rgba(255, 255, 255, 0.1)'
            : '1px solid rgba(0, 0, 0, 0.1)',
          background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.02)'
        }}>
          <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#ff5f56' }} />
          <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#ffbd2e' }} />
          <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#27ca3f' }} />
          <span style={{
            marginLeft: '12px',
            fontSize: '14px',
            fontWeight: '600',
            color: isDark ? '#f1f5f9' : '#1e293b'
          }}>
            {demos[activeTab].title}.java
          </span>
        </div>
        
        <div style={{ padding: '24px' }}>
          <div style={{
            marginBottom: '16px',
            fontSize: '14px',
            color: isDark ? '#94a3b8' : '#64748b'
          }}>
            {demos[activeTab].description}
          </div>
          
          <pre style={{
            fontFamily: 'monospace',
            fontSize: '14px',
            lineHeight: '1.6',
            color: isDark ? '#f1f5f9' : '#1e293b',
            margin: 0,
            whiteSpace: 'pre-wrap',
            overflow: 'auto'
          }}>
            <code>{demos[activeTab].code}</code>
          </pre>
        </div>
      </div>
    </div>
  );
};

export const BenefitCard = ({ icon, title, description }) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  return (
    <div 
      style={{
        background: 'linear-gradient(145deg, rgba(255, 255, 255, 0.1), rgba(255, 255, 255, 0.05))',
        backdropFilter: 'blur(20px)',
        border: '1px solid rgba(255, 255, 255, 0.2)',
        borderRadius: '20px',
        padding: '32px',
        textAlign: 'center',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        position: 'relative',
        overflow: 'hidden',
        cursor: 'pointer',
        transform: isHovered ? 'translateY(-8px) scale(1.02)' : 'translateY(0) scale(1)',
        boxShadow: isHovered ? '0 20px 40px rgba(0, 0, 0, 0.15)' : 'none'
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <div style={{
        fontSize: '48px',
        marginBottom: '16px',
        display: 'block'
      }}>
        {icon}
      </div>
      <h3 style={{
        fontSize: '20px',
        fontWeight: '700',
        marginBottom: '12px',
        color: isDark ? '#f1f5f9' : '#1e293b'
      }}>
        {title}
      </h3>
      <p style={{
        color: isDark ? '#cbd5e1' : '#64748b',
        lineHeight: '1.6',
        margin: 0
      }}>
        {description}
      </p>
    </div>
  );
};

export const TechStack = () => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  return (
    <div style={{
      background: 'linear-gradient(145deg, rgba(102, 126, 234, 0.1), rgba(118, 75, 162, 0.1))',
      borderRadius: '20px',
      padding: '32px',
      margin: '40px 0',
      border: '1px solid rgba(102, 126, 234, 0.2)'
    }}>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '32px'
      }}>
        <div>
          <div style={{
            color: '#667eea',
            display: 'block',
            marginBottom: '16px',
            fontSize: '18px',
            fontWeight: '700'
          }}>
            Languages & Frameworks:
          </div>
          <ul style={{ margin: 0, paddingLeft: '0', listStyle: 'none' }}>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>Java</strong>: Primary language with WPILib framework
            </li>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>C++</strong>: Advanced performance programming
            </li>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>Python</strong>: Vision processing and data analysis
            </li>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>LabVIEW</strong>: Graphical programming alternative
            </li>
          </ul>
        </div>
        
        <div>
          <div style={{
            color: '#667eea',
            display: 'block',
            marginBottom: '16px',
            fontSize: '18px',
            fontWeight: '700'
          }}>
            Key Technologies:
          </div>
          <ul style={{ margin: 0, paddingLeft: '0', listStyle: 'none' }}>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>WPILib</strong>: FIRST's robotics library
            </li>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>NetworkTables</strong>: Real-time data sharing
            </li>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>PathPlanner</strong>: Autonomous path generation
            </li>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>PhotonVision</strong>: Computer vision processing
            </li>
            <li style={{ margin: '8px 0', paddingLeft: '20px', position: 'relative' }}>
              <span style={{ position: 'absolute', left: '0', color: '#667eea' }}>▶</span>
              <strong>Phoenix & REV Libraries</strong>: Motor controller APIs
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export const ResourceWidget = ({ icon, title, link, displayUrl }) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  return (
    <div 
      style={{
        background: 'linear-gradient(145deg, rgba(255, 255, 255, 0.1), rgba(255, 255, 255, 0.05))',
        backdropFilter: 'blur(20px)',
        border: isHovered ? 'rgba(255, 255, 255, 0.4)' : 'rgba(255, 255, 255, 0.2)',
        borderWidth: '1px',
        borderStyle: 'solid',
        borderRadius: '20px',
        padding: '24px',
        display: 'flex',
        alignItems: 'center',
        gap: '16px',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        cursor: 'pointer',
        position: 'relative',
        overflow: 'hidden',
        transform: isHovered ? 'translateY(-8px) scale(1.02)' : 'translateY(0) scale(1)',
        boxShadow: isHovered ? '0 20px 40px rgba(0, 0, 0, 0.15)' : 'none'
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onClick={() => window.open(link, '_blank')}
    >
      {isHovered && (
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'linear-gradient(135deg, rgba(102, 126, 234, 0.1), rgba(118, 75, 162, 0.1))',
          borderRadius: '20px'
        }} />
      )}
      
      <div style={{
        fontSize: '32px',
        width: '60px',
        height: '60px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #667eea, #764ba2)',
        borderRadius: '16px',
        position: 'relative',
        zIndex: 1
      }}>
        {icon}
      </div>
      
      <div style={{ position: 'relative', zIndex: 1 }}>
        <h4 style={{
          fontSize: '18px',
          fontWeight: '700',
          margin: '0 0 8px 0',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          {title}
        </h4>
        <div style={{
          color: '#667eea',
          textDecoration: 'none',
          fontWeight: '600',
          fontSize: '14px'
        }}>
          {displayUrl}
        </div>
      </div>
    </div>
  );
};

export const EnhancedButton = ({ 
  children, 
  variant = 'primary', 
  onClick, 
  href,
  ...props 
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const baseStyles = {
    border: 'none',
    borderRadius: '16px',
    padding: '20px 40px',
    fontSize: '18px',
    fontWeight: '700',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    position: 'relative',
    overflow: 'hidden',
    textDecoration: 'none',
    display: 'inline-block'
  };
  
  const primaryStyles = {
    ...baseStyles,
    background: 'linear-gradient(135deg, rgba(102, 126, 234, 0.9) 0%, rgba(118, 75, 162, 0.9) 100%)',
    color: 'white',
    border: '1px solid rgba(255, 255, 255, 0.2)',
    boxShadow: '0 8px 32px rgba(102, 126, 234, 0.4)',
    backdropFilter: 'blur(10px)',
    transform: isHovered ? 'translateY(-4px) scale(1.05)' : 'translateY(0) scale(1)',
    boxShadow: isHovered ? '0 16px 48px rgba(102, 126, 234, 0.6)' : '0 8px 32px rgba(102, 126, 234, 0.4)'
  };
  
  const secondaryStyles = {
    ...baseStyles,
    background: 'rgba(255, 255, 255, 0.1)',
    color: 'white',
    border: '2px solid rgba(255, 255, 255, 0.3)',
    backdropFilter: 'blur(10px)',
    transform: isHovered ? 'translateY(-4px) scale(1.05)' : 'translateY(0) scale(1)',
    background: isHovered ? 'rgba(255, 255, 255, 0.2)' : 'rgba(255, 255, 255, 0.1)',
    borderColor: isHovered ? 'rgba(255, 255, 255, 0.5)' : 'rgba(255, 255, 255, 0.3)'
  };
  
  const styles = variant === 'primary' ? primaryStyles : secondaryStyles;
  
  const handleClick = () => {
    if (href) {
      window.location.href = href;
    } else if (onClick) {
      onClick();
    }
  };
  
  return (
    <button
      style={styles}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onClick={handleClick}
      {...props}
    >
      {isHovered && (
        <div style={{
          content: '',
          position: 'absolute',
          top: 0,
          left: '-100%',
          width: '100%',
          height: '100%',
          background: 'linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent)',
          transition: 'left 0.5s ease',
          left: '100%'
        }} />
      )}
      <span style={{ position: 'relative', zIndex: 1 }}>
        {children}
      </span>
    </button>
  );
};
