"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';
import Link from 'next/link';

export const Card = ({
  children,
  title,
  subtitle,
  description,
  icon,
  image,
  href,
  target,
  variant = 'default',
  size = 'medium',
  gradient,
  interactive = true,
  padding,
  className = '',
  style = {},
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
  const sizes = {
    small: {
      padding: padding || '16px',
      borderRadius: '12px',
      minHeight: '120px'
    },
    medium: {
      padding: padding || '24px',
      borderRadius: '16px',
      minHeight: '160px'
    },
    large: {
      padding: padding || '32px',
      borderRadius: '20px',
      minHeight: '200px'
    }
  };
  
  // Variant configurations
  const variants = {
    default: {
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)'
        : '1px solid rgba(0, 0, 0, 0.05)',
      boxShadow: isDark 
        ? '0 20px 40px -12px rgba(0, 0, 0, 0.8)'
        : '0 20px 40px -12px rgba(0, 0, 0, 0.1)'
    },
    elevated: {
      background: isDark 
        ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
        : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
      border: 'none',
      boxShadow: isDark 
        ? '0 25px 50px -12px rgba(0, 0, 0, 0.9), 0 0 0 1px rgba(255, 255, 255, 0.1)'
        : '0 25px 50px -12px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05)'
    },
    gradient: {
      background: gradient || 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      border: 'none',
      boxShadow: '0 20px 40px -12px rgba(102, 126, 234, 0.4)',
      color: 'white'
    },
    glass: {
      background: isDark 
        ? 'rgba(15, 23, 42, 0.8)'
        : 'rgba(255, 255, 255, 0.25)',
      backdropFilter: 'blur(20px)',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.2)'
        : '1px solid rgba(255, 255, 255, 0.3)',
      boxShadow: isDark 
        ? '0 20px 40px rgba(0, 0, 0, 0.4)'
        : '0 20px 40px rgba(0, 0, 0, 0.1)'
    }
  };
  
  const cardStyle = {
    ...sizes[size],
    ...variants[variant],
    display: 'flex',
    flexDirection: 'column',
    position: 'relative',
    overflow: 'hidden',
    cursor: (interactive && (href || onClick)) ? 'pointer' : 'default',
    transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
    transform: isHovered && interactive ? 'translateY(-8px) scale(1.02)' : 'translateY(0) scale(1)',
    textDecoration: 'none',
    color: 'inherit',
    ...style
  };
  
  const hoverOverlay = interactive && (
    <div style={{
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      background: gradient || 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      opacity: isHovered ? 0.08 : 0,
      transition: 'opacity 0.4s ease',
      borderRadius: sizes[size].borderRadius
    }} />
  );
  
  const cardContent = (
    <>
      {hoverOverlay}
      
      {/* Image */}
      {image && (
        <div style={{
          width: '100%',
          height: '200px',
          backgroundImage: `url(${image})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          borderRadius: `${parseInt(sizes[size].borderRadius) - 4}px`,
          marginBottom: '16px'
        }} />
      )}
      
      {/* Icon */}
      {icon && (
        <div style={{
          fontSize: '48px',
          marginBottom: '16px',
          transform: isHovered ? 'scale(1.1) rotate(5deg)' : 'scale(1) rotate(0deg)',
          transition: 'transform 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
          position: 'relative',
          zIndex: 1,
          alignSelf: 'flex-start'
        }}>
          {icon}
        </div>
      )}
      
      {/* Title */}
      {title && (
        <h3 style={{
          fontSize: size === 'large' ? '24px' : size === 'medium' ? '20px' : '18px',
          fontWeight: '700',
          marginBottom: subtitle || description ? '8px' : '16px',
          color: variant === 'gradient' ? 'white' : isDark ? '#f1f5f9' : '#1e293b',
          lineHeight: '1.3',
          position: 'relative',
          zIndex: 1
        }}>
          {title}
        </h3>
      )}
      
      {/* Subtitle */}
      {subtitle && (
        <div style={{
          fontSize: '14px',
          fontWeight: '600',
          color: variant === 'gradient' ? 'rgba(255, 255, 255, 0.8)' : isDark ? '#a78bfa' : '#6366f1',
          marginBottom: description ? '12px' : '16px',
          position: 'relative',
          zIndex: 1
        }}>
          {subtitle}
        </div>
      )}
      
      {/* Description */}
      {description && (
        <p style={{
          color: variant === 'gradient' ? 'rgba(255, 255, 255, 0.9)' : isDark ? '#cbd5e1' : '#64748b',
          lineHeight: '1.6',
          fontSize: '16px',
          flex: 1,
          position: 'relative',
          zIndex: 1,
          margin: '0 0 16px 0'
        }}>
          {description}
        </p>
      )}
      
      {/* Children content */}
      <div style={{
        position: 'relative',
        zIndex: 1,
        flex: 1
      }}>
        {children}
      </div>
    </>
  );
  
  const eventHandlers = {
    onMouseEnter: () => interactive && setIsHovered(true),
    onMouseLeave: () => setIsHovered(false),
    onClick,
    ...props
  };
  
  if (href) {
    return (
      <Link href={href} target={target} style={cardStyle} className={className} {...eventHandlers}>
        {cardContent}
      </Link>
    );
  }
  
  return (
    <div style={cardStyle} className={className} {...eventHandlers}>
      {cardContent}
    </div>
  );
};
