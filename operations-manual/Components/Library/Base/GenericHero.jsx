"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Hero Component - Highly configurable hero section
 * @param {Object} props - Component properties
 * @param {string} props.title - Main hero title
 * @param {string} props.subtitle - Hero subtitle
 * @param {string} props.description - Hero description
 * @param {string} props.backgroundType - Background type: 'gradient', 'image', 'pattern', 'video'
 * @param {string} props.backgroundValue - Background value (gradient, image URL, etc.)
 * @param {Array} props.particles - Particle configuration for animated background
 * @param {Array} props.buttons - Button configuration array
 * @param {Array} props.codeExamples - Code examples for programming-focused heroes
 * @param {string} props.height - Hero height: 'sm', 'md', 'lg', 'full'
 * @param {string} props.textAlign - Text alignment: 'left', 'center', 'right'
 * @param {Object} props.overlay - Overlay configuration
 * @param {React.Component} props.children - Custom content
 * @param {Object} props.animation - Animation configuration
 */
export const GenericHero = ({
  title,
  subtitle,
  description,
  titleColor = 'linear-gradient(135deg, #ffffff 0%, #a78bfa 50%, #06b6d4 100%)',
  backgroundType = 'gradient',
  backgroundValue = 'linear-gradient(135deg,rgb(103, 46, 194) 0%,rgb(14, 68, 218) 100%)',
  particles = [],
  buttons = [],
  codeExamples = [],
  height = 'lg',
  textAlign = 'center',
  overlay = { enabled: false },
  children,
  animation = { enabled: true },
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [currentStat, setCurrentStat] = useState(0);
  const [currentCodeExample, setCurrentCodeExample] = useState(0);
  
  useEffect(() => {
    setMounted(true);
    if (animation.enabled && particles.length > 0) {
      const interval = setInterval(() => {
        setCurrentStat((prev) => (prev + 1) % particles.length);
      }, 3000);
      return () => clearInterval(interval);
    }
    if (animation.enabled && codeExamples.length > 0) {
      const codeInterval = setInterval(() => {
        setCurrentCodeExample((prev) => (prev + 1) % codeExamples.length);
      }, 4000);
      return () => clearInterval(codeInterval);
    }
  }, [animation.enabled, particles.length, codeExamples.length]);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  // Height configurations
  const heightConfig = {
    sm: { minHeight: '50vh' },
    md: { minHeight: '70vh' },
    lg: { minHeight: '90vh' },
    full: { minHeight: '100vh' }
  };
  
  // Background configurations
  const getBackground = () => {
    switch (backgroundType) {
      case 'gradient':
        return backgroundValue;
      case 'image':
        return `url(${backgroundValue})`;
      case 'pattern':
        return backgroundValue;
      case 'video':
        return 'transparent';
      default:
        return backgroundValue;
    }
  };
  
  const heroStyle = {
    background: getBackground(),
    ...heightConfig[height],
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    overflow: 'hidden',
    borderRadius: '32px',
    margin: '40px 0',
    boxShadow: isDark 
      ? '0 25px 50px -12px rgba(0, 0, 0, 0.9)'
      : '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
    backgroundSize: backgroundType === 'image' ? 'cover' : 'auto',
    backgroundPosition: backgroundType === 'image' ? 'center' : 'auto',
    backgroundRepeat: backgroundType === 'image' ? 'no-repeat' : 'auto'
  };
  
  // Animated particles/symbols
  const renderParticles = () => {
    if (!animation.enabled || particles.length === 0) return null;
    
    return particles.map((particle, i) => (
      <div key={i} style={{
        position: 'absolute',
        top: `${10 + (i * 12)}%`,
        left: `${5 + (i * 11)}%`,
        fontSize: `${20 + i * 4}px`,
        color: isDark ? 'rgba(167, 139, 250, 0.3)' : 'rgba(255, 255, 255, 0.4)',
        fontFamily: particle.fontFamily || 'inherit',
        fontWeight: 'bold',
        animation: `float ${8 + i}s ease-in-out infinite ${i * 0.5}s`,
        pointerEvents: 'none',
        transform: particle.transform || 'none'
      }}>
        {particle.symbol || particle.content}
      </div>
    ));
  };
  
  return (
    <div style={heroStyle} {...props}>
      {/* Video Background */}
      {backgroundType === 'video' && (
        <video
          autoPlay
          loop
          muted
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            zIndex: 0
          }}
        >
          <source src={backgroundValue} type="video/mp4" />
        </video>
      )}
      
      {/* Overlay */}
      {overlay.enabled && (
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: overlay.color || 'rgba(0, 0, 0, 0.4)',
          zIndex: 1
        }} />
      )}
      
      {/* Animated particles */}
      {renderParticles()}
      
      {/* Content */}
      <div style={{
        textAlign,
        color: 'white',
        zIndex: 10,
        maxWidth: '1000px',
        padding: '60px 40px',
        position: 'relative'
      }}>
        {/* Title */}
        {title && (
          <div style={{
            fontSize: 'clamp(40px, 6vw, 72px)',
            fontWeight: '900',
            marginBottom: '24px',
            background: titleColor,
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            lineHeight: '1.1',
            animation: animation.enabled ? 'slideInDown 1s ease-out' : 'none'
          }}>
            {title}
          </div>
        )}
        
        {/* Subtitle */}
        {subtitle && (
          <div style={{
            fontSize: 'clamp(18px, 3vw, 24px)',
            marginBottom: '32px',
            opacity: '0.95',
            lineHeight: '1.6',
            animation: animation.enabled ? 'slideInUp 1s ease-out 0.2s both' : 'none'
          }}>
            {subtitle}
          </div>
        )}
        
        {/* Description */}
        {description && (
          <div style={{
            fontSize: 'clamp(16px, 2.5vw, 20px)',
            marginBottom: '48px',
            opacity: '0.9',
            lineHeight: '1.6',
            animation: animation.enabled ? 'fadeIn 1s ease-out 0.4s both' : 'none',
            maxWidth: '800px',
            margin: '0 auto 48px'
          }}>
            {description}
          </div>
        )}
        
        {/* Buttons */}
        {buttons.length > 0 && (
          <div style={{
            display: 'flex',
            gap: '20px',
            flexWrap: 'wrap',
            justifyContent: textAlign === 'center' ? 'center' : textAlign === 'right' ? 'flex-end' : 'flex-start',
            animation: animation.enabled ? 'slideInUp 1s ease-out 0.6s both' : 'none'
          }}>
            {buttons.map((button, index) => (
              <button
                key={index}
                style={{
                  background: button.style === 'primary' 
                    ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
                    : 'rgba(255, 255, 255, 0.1)',
                  color: 'white',
                  border: button.style === 'primary' 
                    ? 'none' 
                    : '2px solid rgba(255, 255, 255, 0.3)',
                  borderRadius: '12px',
                  padding: '16px 32px',
                  fontSize: '16px',
                  fontWeight: '700',
                  cursor: 'pointer',
                  transition: 'all 0.3s ease',
                  backdropFilter: button.style !== 'primary' ? 'blur(10px)' : 'none',
                  boxShadow: button.style === 'primary' 
                    ? '0 8px 32px rgba(102, 126, 234, 0.4)' 
                    : 'none'
                }}
                onClick={button.onClick}
              >
                {button.icon && <span style={{ marginRight: '8px' }}>{button.icon}</span>}
                {button.text}
              </button>
            ))}
          </div>        )}
        
        {/* Code Examples - for programming-focused heroes */}
        {codeExamples.length > 0 && (
          <div style={{
            marginTop: '60px',
            display: 'grid',
            gridTemplateColumns: codeExamples.length > 1 ? '1fr 1fr' : '1fr',
            gap: '40px',
            alignItems: 'flex-start',
            maxWidth: '1000px',
            width: '100%',
            animation: animation.enabled ? 'slideInUp 1s ease-out 0.8s both' : 'none'
          }}>
            <div style={{
              color: 'white',
              display: 'flex',
              flexDirection: 'column',
              gap: '20px'
            }}>
              {codeExamples.length > 1 && (
                <div style={{
                  display: 'flex',
                  gap: '12px',
                  marginBottom: '20px'
                }}>
                  {codeExamples.map((_, i) => (
                    <button
                      key={i}
                      onClick={() => setCurrentCodeExample(i)}
                      style={{
                        background: i === currentCodeExample 
                          ? 'rgba(255, 255, 255, 0.3)' 
                          : 'rgba(255, 255, 255, 0.1)',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '8px 16px',
                        color: 'white',
                        fontSize: '14px',
                        cursor: 'pointer',
                        transition: 'all 0.3s ease'
                      }}
                    >
                      {codeExamples[i].title}
                    </button>
                  ))}
                </div>
              )}
              <div style={{
                background: 'rgba(0, 0, 0, 0.4)',
                borderRadius: '16px',
                padding: '24px',
                backdropFilter: 'blur(10px)',
                border: '1px solid rgba(255, 255, 255, 0.1)'
              }}>
                <div style={{
                  fontSize: '14px',
                  color: 'rgba(255, 255, 255, 0.7)',
                  marginBottom: '12px',
                  fontWeight: '500'
                }}>
                  {codeExamples[currentCodeExample]?.title}
                </div>
                <pre style={{
                  margin: 0,
                  fontSize: '13px',
                  lineHeight: '1.6',
                  color: '#f8f8f2',
                  fontFamily: 'Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
                  overflow: 'auto'
                }}>
                  <code>{codeExamples[currentCodeExample]?.code}</code>
                </pre>
              </div>
            </div>
            
            {codeExamples.length > 1 && (
              <div style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '20px',
                color: 'white'
              }}>
                <h3 style={{
                  fontSize: '24px',
                  fontWeight: '700',
                  margin: '0 0 16px 0'
                }}>
                  Code in Action
                </h3>
                <p style={{
                  fontSize: '16px',
                  lineHeight: '1.6',
                  opacity: '0.9',
                  margin: 0
                }}>
                  See real examples of how we build competitive robotics software, 
                  from basic robot control to advanced autonomous systems.
                </p>
                <div style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: '8px',
                  marginTop: '20px'
                }}>
                  {['Java', 'Python', 'JavaScript', 'C++'].map((lang, i) => (
                    <span key={i} style={{
                      background: 'rgba(255, 255, 255, 0.1)',
                      padding: '4px 12px',
                      borderRadius: '12px',
                      fontSize: '12px',
                      fontWeight: '500',
                      border: '1px solid rgba(255, 255, 255, 0.2)'
                    }}>
                      {lang}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
        
        {/* Custom children */}
        {children && (
          <div style={{
            marginTop: '40px',
            animation: animation.enabled ? 'fadeIn 1s ease-out 0.8s both' : 'none'
          }}>
            {children}
          </div>
        )}
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
      `}</style>
    </div>
  );
};
