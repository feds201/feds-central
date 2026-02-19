"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Navigation Component - Highly configurable navigation widget
 * @param {Object} props - Component properties
 * @param {Array} props.items - Navigation items
 * @param {string} props.layout - Layout: 'horizontal', 'vertical', 'grid', 'tabs'
 * @param {string} props.variant - Variant: 'default', 'pills', 'underline', 'cards'
 * @param {boolean} props.animated - Enable animations
 * @param {string} props.activeItem - Currently active item
 * @param {Function} props.onItemClick - Item click handler
 * @param {Object} props.customStyles - Override default styles
 */
export const GenericNavigation = ({
  items = [],
  layout = 'horizontal',
  variant = 'default',
  animated = true,
  activeItem,
  onItemClick,
  customStyles = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [currentActive, setCurrentActive] = useState(activeItem || (items[0]?.id || 0));

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (activeItem !== undefined) {
      setCurrentActive(activeItem);
    }
  }, [activeItem]);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';

  // Layout configurations
  const layoutConfig = {
    horizontal: {
      display: 'flex',
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: '8px'
    },
    vertical: {
      display: 'flex',
      flexDirection: 'column',
      gap: '4px'
    },
    grid: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
      gap: '12px'
    },
    tabs: {
      display: 'flex',
      flexDirection: 'row',
      borderBottom: isDark 
        ? '1px solid rgba(255, 255, 255, 0.1)' 
        : '1px solid rgba(0, 0, 0, 0.1)',
      gap: '0'
    }
  };

  // Variant configurations
  const variantConfig = {
    default: {
      itemStyle: {
        padding: '12px 20px',
        background: 'transparent',
        border: isDark 
          ? '1px solid rgba(255, 255, 255, 0.1)' 
          : '1px solid rgba(0, 0, 0, 0.1)',
        borderRadius: '8px',
        color: isDark ? '#cbd5e1' : '#6b7280'
      },
      activeStyle: {
        background: isDark ? 'rgba(167, 139, 250, 0.2)' : 'rgba(99, 102, 241, 0.1)',
        borderColor: isDark ? '#a78bfa' : '#6366f1',
        color: isDark ? '#a78bfa' : '#6366f1'
      }
    },
    pills: {
      itemStyle: {
        padding: '10px 18px',
        background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.05)',
        border: 'none',
        borderRadius: '20px',
        color: isDark ? '#cbd5e1' : '#6b7280'
      },
      activeStyle: {
        background: isDark 
          ? 'linear-gradient(135deg, #a78bfa 0%, #06b6d4 100%)' 
          : 'linear-gradient(135deg, #6366f1 0%, #0891b2 100%)',
        color: 'white'
      }
    },
    underline: {
      itemStyle: {
        padding: '12px 16px',
        background: 'transparent',
        border: 'none',
        borderBottom: '2px solid transparent',
        borderRadius: '0',
        color: isDark ? '#cbd5e1' : '#6b7280'
      },
      activeStyle: {
        borderBottomColor: isDark ? '#06b6d4' : '#0891b2',
        color: isDark ? '#06b6d4' : '#0891b2'
      }
    },
    cards: {
      itemStyle: {
        padding: '16px 20px',
        background: isDark ? 'rgba(255, 255, 255, 0.02)' : 'rgba(0, 0, 0, 0.02)',
        border: isDark 
          ? '1px solid rgba(255, 255, 255, 0.05)' 
          : '1px solid rgba(0, 0, 0, 0.05)',
        borderRadius: '12px',
        color: isDark ? '#cbd5e1' : '#6b7280',
        backdropFilter: 'blur(10px)'
      },
      activeStyle: {
        background: isDark ? 'rgba(167, 139, 250, 0.1)' : 'rgba(99, 102, 241, 0.05)',
        borderColor: isDark ? '#a78bfa' : '#6366f1',
        color: isDark ? '#a78bfa' : '#6366f1',
        boxShadow: isDark 
          ? '0 4px 20px rgba(167, 139, 250, 0.3)' 
          : '0 4px 20px rgba(99, 102, 241, 0.2)'
      }
    }
  };

  const containerStyle = {
    ...layoutConfig[layout],
    margin: '20px 0',
    ...customStyles
  };

  const currentVariant = variantConfig[variant];

  const handleItemClick = (item, index) => {
    setCurrentActive(item.id || index);
    if (onItemClick) onItemClick(item, index);
    if (item.href) {
      window.open(item.href, item.external ? '_blank' : '_self');
    }
  };

  // Render individual navigation item
  const renderNavItem = (item, index) => {
    const isActive = currentActive === (item.id || index);
    
    const itemStyle = {
      ...currentVariant.itemStyle,
      ...(isActive ? currentVariant.activeStyle : {}),
      cursor: 'pointer',
      textDecoration: 'none',
      fontWeight: isActive ? '600' : '500',
      fontSize: '14px',
      transition: animated ? 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)' : 'none',
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      minWidth: layout === 'tabs' ? '120px' : 'auto',
      justifyContent: layout === 'tabs' ? 'center' : 'flex-start',
      position: 'relative',
      overflow: 'hidden'
    };

    const hoverStyle = {
      background: isActive 
        ? itemStyle.background 
        : (isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.05)'),
      transform: animated ? 'translateY(-1px)' : 'none'
    };

    return (
      <div
        key={item.id || index}
        style={itemStyle}
        onClick={() => handleItemClick(item, index)}
        onMouseEnter={(e) => {
          if (animated && !isActive) {
            Object.assign(e.target.style, hoverStyle);
          }
        }}
        onMouseLeave={(e) => {
          if (animated && !isActive) {
            Object.assign(e.target.style, {
              background: currentVariant.itemStyle.background,
              transform: 'translateY(0)'
            });
          }
        }}
      >
        {/* Icon */}
        {item.icon && (
          <span style={{
            fontSize: '16px',
            display: 'flex',
            alignItems: 'center'
          }}>
            {item.icon}
          </span>
        )}

        {/* Label */}
        <span>{item.label || item.title || item.text}</span>

        {/* Badge/Count */}
        {item.badge && (
          <span style={{
            background: isDark ? '#ef4444' : '#dc2626',
            color: 'white',
            fontSize: '11px',
            padding: '2px 6px',
            borderRadius: '10px',
            fontWeight: '600',
            minWidth: '18px',
            height: '18px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            {item.badge}
          </span>
        )}

        {/* Active indicator for tabs */}
        {layout === 'tabs' && variant === 'underline' && isActive && (
          <div style={{
            position: 'absolute',
            bottom: '-1px',
            left: '0',
            right: '0',
            height: '2px',
            background: isDark ? '#06b6d4' : '#0891b2',
            borderRadius: '1px'
          }} />
        )}

        {/* Ripple effect */}
        {animated && (
          <div style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            width: '0',
            height: '0',
            background: 'rgba(255, 255, 255, 0.2)',
            borderRadius: '50%',
            transform: 'translate(-50%, -50%)',
            transition: 'width 0.3s ease, height 0.3s ease',
            pointerEvents: 'none'
          }} />
        )}
      </div>
    );
  };

  return (
    <nav style={containerStyle} {...props}>
      {items.map(renderNavItem)}
    </nav>
  );
};
