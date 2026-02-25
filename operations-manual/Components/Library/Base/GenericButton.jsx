"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Button Component - Highly configurable button component
 * @param {Object} props - Component properties
 * @param {React.Component|string} props.children - Button content
 * @param {string} props.variant - Button variant: 'primary', 'secondary', 'outline', 'ghost', 'gradient'
 * @param {string} props.size - Button size: 'sm', 'md', 'lg', 'xl'
 * @param {string} props.gradient - CSS gradient for gradient variant
 * @param {string} props.icon - Icon (emoji or component)
 * @param {string} props.iconPosition - Icon position: 'left', 'right'
 * @param {boolean} props.loading - Show loading state
 * @param {boolean} props.disabled - Disable button
 * @param {string} props.href - Link URL (makes button act as link)
 * @param {boolean} props.fullWidth - Make button full width
 * @param {Function} props.onClick - Click handler
 * @param {Object} props.customStyles - Override default styles
 */
export const GenericButton = ({
  children,
  variant = 'primary',
  size = 'md',
  gradient = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  icon,
  iconPosition = 'left',
  loading = false,
  disabled = false,
  href,
  fullWidth = false,
  onClick,
  customStyles = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  const [isPressed, setIsPressed] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  // Size configurations
  const sizeConfig = {
    sm: { padding: '8px 16px', fontSize: '14px', iconSize: '16px', height: '36px' },
    md: { padding: '12px 24px', fontSize: '16px', iconSize: '20px', height: '44px' },
    lg: { padding: '16px 32px', fontSize: '18px', iconSize: '24px', height: '52px' },
    xl: { padding: '20px 40px', fontSize: '20px', iconSize: '28px', height: '60px' }
  };
  
  // Variant configurations
  const variants = {
    primary: {
      background: gradient,
      color: 'white',
      border: 'none',
      shadow: '0 4px 14px 0 rgba(102, 126, 234, 0.3)',
      hoverShadow: '0 6px 20px 0 rgba(102, 126, 234, 0.4)'
    },
    secondary: {
      background: isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)',
      color: isDark ? '#f1f5f9' : '#374151',
      border: isDark ? '1px solid rgba(255, 255, 255, 0.2)' : '1px solid rgba(0, 0, 0, 0.1)',
      shadow: '0 2px 8px 0 rgba(0, 0, 0, 0.1)',
      hoverShadow: '0 4px 12px 0 rgba(0, 0, 0, 0.15)'
    },
    outline: {
      background: 'transparent',
      color: isDark ? '#a78bfa' : '#6366f1',
      border: `2px solid ${isDark ? '#a78bfa' : '#6366f1'}`,
      shadow: 'none',
      hoverShadow: '0 4px 12px 0 rgba(99, 102, 241, 0.2)'
    },
    ghost: {
      background: 'transparent',
      color: isDark ? '#cbd5e1' : '#64748b',
      border: 'none',
      shadow: 'none',
      hoverShadow: 'none'
    },
    gradient: {
      background: gradient,
      color: 'white',
      border: 'none',
      shadow: '0 8px 32px 0 rgba(102, 126, 234, 0.4)',
      hoverShadow: '0 12px 40px 0 rgba(102, 126, 234, 0.5)'
    }
  };
  
  const currentVariant = variants[variant];
  const currentSize = sizeConfig[size];
  
  const buttonStyle = {
    background: currentVariant.background,
    color: currentVariant.color,
    border: currentVariant.border,
    borderRadius: '12px',
    padding: currentSize.padding,
    fontSize: currentSize.fontSize,
    fontWeight: '600',
    height: currentSize.height,
    cursor: disabled ? 'not-allowed' : 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '8px',
    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
    textDecoration: 'none',
    outline: 'none',
    position: 'relative',
    overflow: 'hidden',
    opacity: disabled ? 0.6 : 1,
    width: fullWidth ? '100%' : 'auto',
    boxShadow: !disabled && !loading ? currentVariant.shadow : 'none',
    transform: isPressed ? 'scale(0.98)' : isHovered && !disabled ? 'translateY(-2px)' : 'translateY(0)',
    ...customStyles
  };
  
  // Hover effects
  const hoverStyle = {
    boxShadow: !disabled && !loading ? currentVariant.hoverShadow : buttonStyle.boxShadow,
    background: variant === 'ghost' && isHovered 
      ? (isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)')
      : currentVariant.background
  };
  
  const handleClick = (e) => {
    if (disabled || loading) return;
    if (onClick) onClick(e);
    if (href) window.open(href, '_blank');
  };
  
  const iconElement = icon && (
    <span style={{
      fontSize: currentSize.iconSize,
      lineHeight: 1,
      display: 'flex',
      alignItems: 'center'
    }}>
      {typeof icon === 'string' ? icon : icon}
    </span>
  );
  
  const loadingSpinner = (
    <div style={{
      width: currentSize.iconSize,
      height: currentSize.iconSize,
      border: `2px solid ${currentVariant.color}`,
      borderTop: '2px solid transparent',
      borderRadius: '50%',
      animation: 'spin 1s linear infinite'
    }} />
  );
  
  const ButtonContent = () => (
    <button
      style={{
        ...buttonStyle,
        ...(isHovered ? hoverStyle : {})
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onMouseDown={() => setIsPressed(true)}
      onMouseUp={() => setIsPressed(false)}
      onClick={handleClick}
      disabled={disabled || loading}
      {...props}
    >
      {/* Background animation overlay */}
      <div style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(255, 255, 255, 0.1)',
        opacity: isHovered && !disabled ? 1 : 0,
        transition: 'opacity 0.3s ease'
      }} />
      
      {/* Content */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        position: 'relative',
        zIndex: 1
      }}>
        {loading && loadingSpinner}
        {!loading && icon && iconPosition === 'left' && iconElement}
        <span>{children}</span>
        {!loading && icon && iconPosition === 'right' && iconElement}
      </div>
      
      <style jsx>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </button>
  );
  
  return href && !disabled && !loading ? (
    <a href={href} style={{ textDecoration: 'none' }} target="_blank" rel="noopener noreferrer">
      <ButtonContent />
    </a>
  ) : (
    <ButtonContent />
  );
};
