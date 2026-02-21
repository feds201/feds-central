"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

export const StatsCard = ({
  value,
  label,
  icon,
  description,
  trend,
  trendDirection = 'up',
  color,
  gradient,
  size = 'medium',
  animated = true,
  className = '',
  style = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isVisible, setIsVisible] = useState(false);
  
  useEffect(() => {
    setMounted(true);
    if (animated) {
      const timer = setTimeout(() => setIsVisible(true), 100);
      return () => clearTimeout(timer);
    } else {
      setIsVisible(true);
    }
  }, [animated]);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const sizes = {
    small: {
      padding: '20px',
      valueSize: '24px',
      labelSize: '14px',
      iconSize: '32px'
    },
    medium: {
      padding: '32px 24px',
      valueSize: '36px',
      labelSize: '16px',
      iconSize: '40px'
    },
    large: {
      padding: '40px 32px',
      valueSize: '48px',
      labelSize: '18px',
      iconSize: '48px'
    }
  };
  
  const cardStyle = {
    background: gradient || (isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)'),
    borderRadius: '20px',
    padding: sizes[size].padding,
    textAlign: 'center',
    transition: 'all 0.3s ease',
    cursor: 'pointer',
    border: isDark 
      ? '1px solid rgba(255, 255, 255, 0.1)'
      : '1px solid rgba(0, 0, 0, 0.05)',
    transform: isVisible ? 'translateY(0) scale(1)' : 'translateY(20px) scale(0.95)',
    opacity: isVisible ? 1 : 0,
    position: 'relative',
    overflow: 'hidden',
    ...style
  };
  
  const valueStyle = {
    fontSize: sizes[size].valueSize,
    fontWeight: '800',
    marginBottom: '8px',
    background: gradient || color || 'linear-gradient(135deg, #f093fb 0%, #4facfe 100%)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
    backgroundClip: 'text',
    transition: 'all 0.5s ease'
  };
  
  return (
    <div 
      style={cardStyle} 
      className={className}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translateY(-8px) scale(1.02)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0) scale(1)';
      }}
      {...props}
    >
      {icon && (
        <div style={{
          fontSize: sizes[size].iconSize,
          marginBottom: '16px',
          animation: animated ? 'bounce 2s infinite' : 'none'
        }}>
          {icon}
        </div>
      )}
      
      <div style={valueStyle}>
        {value}
      </div>
      
      <div style={{
        fontSize: sizes[size].labelSize,
        fontWeight: '600',
        color: isDark ? '#cbd5e1' : '#475569',
        marginBottom: description ? '8px' : '0'
      }}>
        {label}
      </div>
      
      {description && (
        <div style={{
          fontSize: '14px',
          color: isDark ? '#94a3b8' : '#64748b',
          marginBottom: trend ? '8px' : '0'
        }}>
          {description}
        </div>
      )}
      
      {trend && (
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '4px',
          fontSize: '12px',
          fontWeight: '600',
          color: trendDirection === 'up' ? '#10b981' : trendDirection === 'down' ? '#ef4444' : '#6b7280'
        }}>
          <span>
            {trendDirection === 'up' ? '↗️' : trendDirection === 'down' ? '↘️' : '➡️'}
          </span>
          {trend}
        </div>
      )}
      
      <style jsx>{`
        @keyframes bounce {
          0%, 20%, 53%, 80%, 100% { transform: translate3d(0,0,0); }
          40%, 43% { transform: translate3d(0, -5px, 0); }
          70% { transform: translate3d(0, -3px, 0); }
          90% { transform: translate3d(0, -1px, 0); }
        }
      `}</style>
    </div>
  );
};

export const ProgressBar = ({
  value = 0,
  max = 100,
  label,
  color,
  gradient,
  size = 'medium',
  animated = true,
  showValue = true,
  className = '',
  style = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [animatedValue, setAnimatedValue] = useState(0);
  
  useEffect(() => {
    setMounted(true);
    if (animated) {
      const timer = setTimeout(() => {
        setAnimatedValue(value);
      }, 100);
      return () => clearTimeout(timer);
    } else {
      setAnimatedValue(value);
    }
  }, [value, animated]);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  const percentage = Math.min(Math.max((animatedValue / max) * 100, 0), 100);
  
  const sizes = {
    small: { height: '6px', fontSize: '14px' },
    medium: { height: '8px', fontSize: '16px' },
    large: { height: '12px', fontSize: '18px' }
  };
  
  return (
    <div style={{ ...style }} className={className} {...props}>
      {label && (
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '8px',
          fontSize: sizes[size].fontSize,
          fontWeight: '600',
          color: isDark ? '#f1f5f9' : '#1e293b'
        }}>
          <span>{label}</span>
          {showValue && <span>{Math.round(percentage)}%</span>}
        </div>
      )}
      
      <div style={{
        background: isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        borderRadius: '8px',
        height: sizes[size].height,
        overflow: 'hidden',
        position: 'relative'
      }}>
        <div style={{
          background: gradient || color || '#667eea',
          height: '100%',
          width: `${percentage}%`,
          borderRadius: '8px',
          transition: animated ? 'width 1.5s cubic-bezier(0.4, 0, 0.2, 1)' : 'none',
          position: 'relative',
          overflow: 'hidden'
        }}>
          {animated && (
            <div style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)',
              animation: 'shimmer 2s infinite'
            }} />
          )}
        </div>
      </div>
      
      <style jsx>{`
        @keyframes shimmer {
          0% { transform: translateX(-100%); }
          100% { transform: translateX(100%); }
        }
      `}</style>
    </div>
  );
};

export const MetricCard = ({
  metrics = [],
  title,
  layout = 'grid',
  className = '',
  style = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  return (
    <div style={{
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      borderRadius: '24px',
      padding: '32px',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 20px 40px -12px rgba(255, 255, 255, 0.1)'
        : '0 20px 40px -12px rgba(0, 0, 0, 0.1)',
      ...style
    }} className={className} {...props}>
      
      {title && (
        <h3 style={{
          fontSize: '24px',
          fontWeight: '800',
          marginBottom: '24px',
          color: isDark ? '#f1f5f9' : '#1e293b',
          textAlign: 'center'
        }}>
          {title}
        </h3>
      )}
      
      <div style={{
        display: layout === 'grid' ? 'grid' : 'flex',
        gridTemplateColumns: layout === 'grid' ? 'repeat(auto-fit, minmax(200px, 1fr))' : undefined,
        flexDirection: layout === 'vertical' ? 'column' : 'row',
        gap: '20px',
        flexWrap: layout === 'horizontal' ? 'wrap' : undefined
      }}>
        {metrics.map((metric, index) => (
          <StatsCard
            key={index}
            value={metric.value}
            label={metric.label}
            icon={metric.icon}
            description={metric.description}
            color={metric.color}
            size="small"
            animated={true}
            style={{ 
              animationDelay: `${index * 100}ms`,
              minWidth: layout === 'horizontal' ? '200px' : undefined
            }}
          />
        ))}
      </div>
    </div>
  );
};
