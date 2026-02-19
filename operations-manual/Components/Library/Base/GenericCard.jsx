import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Card Component - Highly configurable card component
 * @param {Object} props - Component properties
 * @param {string} props.title - Card title
 * @param {string} props.description - Card description
 * @param {string|React.Component} props.icon - Icon (emoji, text, or component)
 * @param {string} props.href - Link URL
 * @param {string} props.gradient - CSS gradient for accent
 * @param {string} props.variant - Card variant: 'default', 'modern', 'minimal', 'elevated'
 * @param {string} props.size - Card size: 'sm', 'md', 'lg'
 * @param {number} props.delay - Animation delay in ms
 * @param {boolean} props.interactive - Enable hover effects
 * @param {string} props.bgPattern - Background pattern: 'dots', 'grid', 'waves', 'none'
 * @param {Object} props.customStyles - Override default styles
 * @param {React.Component} props.children - Custom content
 * @param {Function} props.onClick - Click handler
 */
export const GenericCard = ({
  title,
  description,
  icon,
  href,
  gradient = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  variant = 'default',
  size = 'md',
  delay = 0,
  interactive = true,
  bgPattern = 'none',
  customStyles = {},
  children,
  onClick,
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
  
  // Size configurations
  const sizeConfig = {
    sm: { padding: '20px', iconSize: '32px', titleSize: '18px', descSize: '14px' },
    md: { padding: '32px', iconSize: '48px', titleSize: '20px', descSize: '16px' },
    lg: { padding: '48px', iconSize: '64px', titleSize: '24px', descSize: '18px' }
  };
  
  // Variant configurations
  const variants = {
    default: {
      borderRadius: '20px',
      shadow: isDark 
        ? '0 20px 40px -12px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.1)'
        : '0 20px 40px -12px rgba(0, 0, 0, 0.1), 0 0 0 1px rgba(0, 0, 0, 0.05)',
      background: isDark 
        ? 'linear-gradient(145deg,rgb(54, 107, 192) 0%,rgb(245, 245, 245) 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)'
    },
    modern: {
      borderRadius: '28px',
      shadow: isDark 
        ? '0 0px 50px -0px rgba(78, 76, 76, 0.9), 0 0 0 1px rgba(233, 15, 15, 0.1)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.87), 0 0 0 1px rgba(0, 0, 0, 0.94)',
      background: isDark 
        ? 'linear-gradient(145deg,rgb(44, 88, 158) 0%,rgb(0, 76, 255) 100%)'
        : 'linear-gradient(145deg,rgb(0, 0, 0) 0%,rgb(5, 5, 5) 100%)'
    },
    minimal: {
      borderRadius: '16px',
      shadow: isDark 
        ? '0 8px 16px -4px rgba(0, 0, 0, 0.6)'
        : '0 8px 16px -4px rgba(0, 0, 0, 0.08)',
      background: isDark 
        ? 'rgba(15, 23, 42, 0.8)'
        : 'rgba(255, 255, 255, 0.9)'
    },
    elevated: {
      borderRadius: '24px',
      shadow: isDark 
        ? '0 32px 64px -12px rgba(0, 0, 0, 0.9)'
        : '0 32px 64px -12px rgba(0, 0, 0, 0.2)',
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)'
    },
    glass: {
      borderRadius: '24px',
      shadow: isDark
        ? '0 8px 32px 0 rgba(0, 0, 0, 0.37)'
        : '0 8px 32px 0 rgba(31, 38, 135, 0.37)',
      background: isDark
        ? 'rgba(255, 255, 255, 0.05)'
        : 'rgba(255, 255, 255, 0.25)',
      backdropFilter: 'blur(4px)',
      border: isDark
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(255, 255, 255, 0.18)'
    }
  };
  
  // Background patterns
  const patterns = {
    dots: `radial-gradient(circle at 1px 1px, ${isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'} 1px, transparent 0)`,
    grid: `linear-gradient(${isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)'} 1px, transparent 1px), linear-gradient(90deg, ${isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)'} 1px, transparent 1px)`,
    waves: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='${isDark ? '%23ffffff' : '%23000000'}' fill-opacity='0.05'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
    none: 'none'
  };
  
  const currentVariant = variants[variant] || variants.default;
  const currentSize = sizeConfig[size];
  
  const cardStyle = {
    background: currentVariant.background,
    borderRadius: currentVariant.borderRadius,
    padding: currentSize.padding,
    boxShadow: currentVariant.shadow,
    border: currentVariant.border || 'none',
    backdropFilter: currentVariant.backdropFilter || 'none',
    WebkitBackdropFilter: currentVariant.backdropFilter || 'none',
    cursor: (href || onClick) ? 'pointer' : 'default',
    transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
    position: 'relative',
    overflow: 'hidden',
    animation: `fadeInUp 0.6s ease-out ${delay}ms both`,
    transform: interactive && isHovered ? 'translateY(-8px) scale(1.02)' : 'translateY(0) scale(1)',
    backgroundImage: bgPattern !== 'none' ? patterns[bgPattern] : 'none',
    backgroundSize: bgPattern === 'dots' ? '20px 20px' : bgPattern === 'grid' ? '20px 20px' : 'auto',
    ...customStyles
  };
  
  const handleClick = () => {
    if (onClick) onClick();
    if (href) window.open(href);
  };
  
  const CardContent = () => (
    <div 
      style={cardStyle}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onClick={handleClick}
      {...props}
    >
      {/* Hover overlay */}
      {interactive && (
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: gradient,
          opacity: isHovered ? 0.3 : 0,
          transition: 'opacity 0.3s ease',
          borderRadius: currentVariant.borderRadius
        }} />
      )}
      
      {/* Icon */}
      {icon && (
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
        // <div style={{
        //   fontSize: currentSize.iconSize,
        //   marginBottom: '16px',
        //   transform: interactive && isHovered ? 'scale(1.1) rotate(5deg)' : 'scale(1) rotate(0deg)',
        //   transition: 'transform 0.3s ease',
        //   position: 'relative',
        //   zIndex: 1,
        //   display: 'flex',
        //   alignItems: 'center',
        //   justifyContent: 'center',
        //   width: 'fit-content'
        // }}>
        //   {typeof icon === 'string' ? icon : icon}
        // </div>
      )}
      
      {/* Title */}
      {title && (
        <h3 style={{
          fontSize: currentSize.titleSize,
          fontWeight: '700',
          marginBottom: '12px',
          color: isDark ? '#f1f5f9' : '#1e293b',
          lineHeight: '1.3',
          position: 'relative',
          zIndex: 1,
          margin: '0 0 12px 0'
        }}>
          {title}
        </h3>
      )}
      
      {/* Description */}
      {description && (
        <p style={{
          color: isDark ? '#cbd5e1' : '#64748b',
          lineHeight: '1.6',
          fontSize: currentSize.descSize,
          flex: 1,
          position: 'relative',
          zIndex: 1,
          margin: '0 0 16px 0'
        }}>
          {description}
        </p>
      )}
      
      {/* Custom children content */}
      {children && (
        <div style={{
          position: 'relative',
          zIndex: 1,
          flex: 1
        }}>
          {children}
        </div>
      )}
      
      {/* Link indicator */}
      {href && (
        <div style={{
          color: isDark ? '#a78bfa' : '#6366f1',
          fontWeight: '600',
          fontSize: '14px',
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          position: 'relative',
          zIndex: 1,
          transform: isHovered ? 'translateX(4px)' : 'translateX(0)',
          transition: 'transform 0.3s ease',
          marginTop: 'auto'
        }}>
          View More
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M13.172 12l-4.95-4.95 1.414-1.414L16 12l-6.364 6.364-1.414-1.414z"/>
          </svg>
        </div>
      )}
      
      <style jsx>{`
        @keyframes fadeInUp {
          from { opacity: 0; transform: translateY(30px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
  
  return <CardContent />;
};
