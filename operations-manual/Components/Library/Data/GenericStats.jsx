"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Stats Component - Highly configurable statistics display
 * @param {Object} props - Component properties
 * @param {Array} props.stats - Array of stat objects
 * @param {string} props.layout - Layout: 'horizontal', 'vertical', 'grid', 'carousel'
 * @param {Object} props.animation - Animation configuration
 * @param {string} props.variant - Variant: 'default', 'gradient', 'minimal', 'cards'
 * @param {boolean} props.countUp - Enable count-up animation for numbers
 * @param {Object} props.spacing - Spacing configuration
 * @param {Object} props.customStyles - Override default styles
 */
export const GenericStats = ({
  stats = [],
  layout = 'horizontal',
  animation = { enabled: true, duration: 2000, delay: 100 },
  variant = 'default',
  countUp = true,
  spacing = { margin: '60px 0', padding: '40px' },
  customStyles = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [animatedValues, setAnimatedValues] = useState({});

  useEffect(() => {
    setMounted(true);
    
    if (animation.enabled && countUp) {
      // Animate numbers
      stats.forEach((stat, index) => {
        if (typeof stat.value === 'number') {
          const startTime = Date.now() + (index * animation.delay);
          const animate = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / animation.duration, 1);
            const easeOutCubic = 1 - Math.pow(1 - progress, 3);
            const currentValue = Math.floor(stat.value * easeOutCubic);
            
            setAnimatedValues(prev => ({
              ...prev,
              [index]: currentValue
            }));
            
            if (progress < 1) {
              requestAnimationFrame(animate);
            }
          };
          
          setTimeout(() => requestAnimationFrame(animate), index * animation.delay);
        }
      });
    } else {
      // Set final values immediately
      const finalValues = {};
      stats.forEach((stat, index) => {
        finalValues[index] = stat.value;
      });
      setAnimatedValues(finalValues);
    }
  }, [animation.enabled, animation.duration, animation.delay, countUp, stats]);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';

  // Layout configurations
  const layoutConfig = {
    horizontal: {
      display: 'flex',
      flexDirection: 'row',
      flexWrap: 'wrap',
      justifyContent: 'space-around',
      gap: '32px'
    },
    vertical: {
      display: 'flex',
      flexDirection: 'column',
      gap: '24px',
      maxWidth: '400px',
      margin: '0 auto'
    },
    grid: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
      gap: '32px'
    },
    carousel: {
      display: 'flex',
      overflowX: 'auto',
      gap: '24px',
      padding: '20px 0',
      scrollBehavior: 'smooth'
    }
  };

  // Variant configurations
  const variantConfig = {
    default: {
      background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.02)',
      border: isDark ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.05)',
      padding: '32px',
      borderRadius: '16px',
      backdropFilter: 'blur(10px)'
    },
    gradient: {
      background: 'linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%)',
      border: '1px solid rgba(102, 126, 234, 0.2)',
      padding: '32px',
      borderRadius: '20px',
      backdropFilter: 'blur(20px)'
    },
    minimal: {
      background: 'transparent',
      border: 'none',
      padding: '16px',
      borderRadius: '0'
    },
    cards: {
      background: isDark ? '#1e293b' : '#ffffff',
      border: 'none',
      padding: '32px',
      borderRadius: '20px',
      boxShadow: isDark 
        ? '0 10px 30px rgba(0, 0, 0, 0.5)' 
        : '0 10px 30px rgba(0, 0, 0, 0.1)'
    }
  };

  const containerStyle = {
    ...layoutConfig[layout],
    margin: spacing.margin,
    padding: layout === 'carousel' ? '0' : spacing.padding,
    ...customStyles
  };

  const currentVariant = variantConfig[variant];

  // Render individual stat
  const renderStat = (stat, index) => {
    const displayValue = animatedValues[index] !== undefined 
      ? animatedValues[index] 
      : stat.value;

    const statStyle = {
      ...currentVariant,
      textAlign: 'center',
      minWidth: layout === 'carousel' ? '200px' : 'auto',
      flexShrink: layout === 'carousel' ? 0 : 1,
      transform: animation.enabled ? `translateY(${index * 10}px)` : 'none',
      animation: animation.enabled ? `slideUp 0.8s ease-out ${index * 0.1}s both` : 'none',
      cursor: stat.onClick ? 'pointer' : 'default',
      transition: 'all 0.3s ease'
    };

    return (
      <div 
        key={index} 
        style={statStyle}
        onClick={stat.onClick}
        onMouseEnter={(e) => {
          if (stat.onClick) {
            e.target.style.transform = 'translateY(-5px)';
          }
        }}
        onMouseLeave={(e) => {
          if (stat.onClick) {
            e.target.style.transform = 'translateY(0)';
          }
        }}
      >
        {/* Icon */}
        {stat.icon && (
          <div style={{
            fontSize: '48px',
            marginBottom: '16px',
            display: 'flex',
            justifyContent: 'center'
          }}>
            {stat.icon}
          </div>
        )}

        {/* Value */}
        <div style={{
          fontSize: 'clamp(32px, 4vw, 48px)',
          fontWeight: '900',
          marginBottom: '8px',
          background: stat.gradient || (isDark 
            ? 'linear-gradient(135deg, #a78bfa 0%, #06b6d4 100%)'
            : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'),
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          lineHeight: '1.1'
        }}>
          {stat.prefix}{displayValue}{stat.suffix}
        </div>

        {/* Label */}
        <div style={{
          fontSize: 'clamp(14px, 2vw, 18px)',
          fontWeight: '600',
          color: isDark ? '#cbd5e1' : '#64748b',
          marginBottom: stat.description ? '8px' : '0'
        }}>
          {stat.label}
        </div>

        {/* Description */}
        {stat.description && (
          <div style={{
            fontSize: '14px',
            color: isDark ? '#94a3b8' : '#9ca3af',
            lineHeight: '1.5',
            maxWidth: '200px',
            margin: '0 auto'
          }}>
            {stat.description}
          </div>
        )}

        {/* Progress bar (optional) */}
        {stat.progress !== undefined && (
          <div style={{
            marginTop: '16px',
            height: '4px',
            background: isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
            borderRadius: '2px',
            overflow: 'hidden'
          }}>
            <div style={{
              height: '100%',
              width: `${stat.progress}%`,
              background: stat.gradient || 'linear-gradient(135deg, #06b6d4 0%, #8b5cf6 100%)',
              borderRadius: '2px',
              transition: 'width 1s ease-out 0.5s'
            }} />
          </div>
        )}
      </div>
    );
  };

  return (
    <div style={containerStyle} {...props}>
      {stats.map(renderStat)}
      
      <style jsx>{`
        @keyframes slideUp {
          from {
            opacity: 0;
            transform: translateY(30px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      `}</style>
    </div>
  );
};
