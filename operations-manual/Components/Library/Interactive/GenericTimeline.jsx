"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Timeline Component - Highly configurable timeline display
 * @param {Object} props - Component properties
 * @param {Array} props.items - Array of timeline items
 * @param {string} props.orientation - Orientation: 'vertical', 'horizontal'
 * @param {string} props.variant - Variant: 'default', 'minimal', 'cards', 'dots'
 * @param {boolean} props.interactive - Enable interactive features
 * @param {Object} props.animation - Animation configuration
 * @param {Object} props.customStyles - Override default styles
 */
export const GenericTimeline = ({
  items = [],
  orientation = 'vertical',
  variant = 'default',
  interactive = true,
  animation = { enabled: true, stagger: 200 },
  customStyles = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [activeItem, setActiveItem] = useState(0);
  const [visibleItems, setVisibleItems] = useState([]);

  useEffect(() => {
    setMounted(true);
    
    if (animation.enabled) {
      items.forEach((_, index) => {
        setTimeout(() => {
          setVisibleItems(prev => [...prev, index]);
        }, index * animation.stagger);
      });
    } else {
      setVisibleItems(items.map((_, index) => index));
    }
  }, [animation.enabled, animation.stagger, items.length]);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';

  // Orientation configurations
  const orientationConfig = {
    vertical: {
      display: 'flex',
      flexDirection: 'column',
      position: 'relative'
    },
    horizontal: {
      display: 'flex',
      flexDirection: 'row',
      overflowX: 'auto',
      position: 'relative',
      padding: '40px 0'
    }
  };

  // Variant configurations
  const variantConfig = {
    default: {
      lineColor: isDark ? 'rgba(255, 255, 255, 0.2)' : 'rgba(0, 0, 0, 0.2)',
      nodeColor: isDark ? '#a78bfa' : '#6366f1',
      activeNodeColor: isDark ? '#06b6d4' : '#0891b2'
    },
    minimal: {
      lineColor: isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
      nodeColor: isDark ? '#64748b' : '#9ca3af',
      activeNodeColor: isDark ? '#f1f5f9' : '#374151'
    },
    cards: {
      lineColor: isDark ? 'rgba(255, 255, 255, 0.15)' : 'rgba(0, 0, 0, 0.15)',
      nodeColor: 'transparent',
      activeNodeColor: 'transparent'
    },
    dots: {
      lineColor: 'transparent',
      nodeColor: isDark ? 'rgba(255, 255, 255, 0.3)' : 'rgba(0, 0, 0, 0.3)',
      activeNodeColor: isDark ? '#06b6d4' : '#0891b2'
    }
  };

  const containerStyle = {
    ...orientationConfig[orientation],
    margin: '40px 0',
    ...customStyles
  };

  const currentVariant = variantConfig[variant];

  // Render timeline line
  const renderTimelineLine = () => {
    if (variant === 'dots') return null;

    const lineStyle = {
      position: 'absolute',
      background: currentVariant.lineColor,
      zIndex: 1
    };

    if (orientation === 'vertical') {
      return (
        <div style={{
          ...lineStyle,
          left: '20px',
          top: '0',
          bottom: '0',
          width: '2px',
          transform: 'translateX(-50%)'
        }} />
      );
    } else {
      return (
        <div style={{
          ...lineStyle,
          top: '20px',
          left: '0',
          right: '0',
          height: '2px',
          transform: 'translateY(-50%)'
        }} />
      );
    }
  };

  // Render individual timeline item
  const renderTimelineItem = (item, index) => {
    const isVisible = visibleItems.includes(index);
    const isActive = interactive && activeItem === index;

    const itemStyle = {
      position: 'relative',
      display: 'flex',
      alignItems: orientation === 'vertical' ? 'flex-start' : 'center',
      flexDirection: orientation === 'vertical' ? 'row' : 'column',
      marginBottom: orientation === 'vertical' ? '40px' : '0',
      marginRight: orientation === 'horizontal' ? '40px' : '0',
      minWidth: orientation === 'horizontal' ? '300px' : 'auto',
      opacity: animation.enabled ? (isVisible ? 1 : 0) : 1,
      transform: animation.enabled 
        ? (isVisible ? 'translateY(0)' : 'translateY(20px)') 
        : 'none',
      transition: 'all 0.6s cubic-bezier(0.4, 0, 0.2, 1)',
      cursor: interactive ? 'pointer' : 'default'
    };

    const nodeStyle = {
      width: '40px',
      height: '40px',
      borderRadius: '50%',
      background: isActive ? currentVariant.activeNodeColor : currentVariant.nodeColor,
      border: variant === 'cards' 
        ? `3px solid ${isActive ? currentVariant.activeNodeColor : currentVariant.nodeColor}`
        : 'none',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 2,
      position: 'relative',
      marginRight: orientation === 'vertical' ? '24px' : '0',
      marginBottom: orientation === 'horizontal' ? '16px' : '0',
      flexShrink: 0,
      transition: 'all 0.3s ease',
      fontSize: '18px',
      color: 'white',
      fontWeight: 'bold'
    };

    const contentStyle = {
      flex: 1,
      padding: variant === 'cards' ? '24px' : '0',
      background: variant === 'cards' 
        ? (isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.02)')
        : 'transparent',
      borderRadius: variant === 'cards' ? '16px' : '0',
      border: variant === 'cards' 
        ? (isDark ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.05)')
        : 'none',
      backdropFilter: variant === 'cards' ? 'blur(10px)' : 'none',
      maxWidth: orientation === 'horizontal' ? '280px' : 'none'
    };

    return (
      <div
        key={index}
        style={itemStyle}
        onClick={() => interactive && setActiveItem(index)}
        onMouseEnter={() => interactive && setActiveItem(index)}
      >
        {/* Timeline Node */}
        <div style={nodeStyle}>
          {item.icon || (index + 1)}
        </div>

        {/* Content */}
        <div style={contentStyle}>
          {/* Date/Time */}
          {item.date && (
            <div style={{
              fontSize: '14px',
              color: isDark ? '#a78bfa' : '#6366f1',
              fontWeight: '600',
              marginBottom: '8px'
            }}>
              {item.date}
            </div>
          )}

          {/* Title */}
          {item.title && (
            <h3 style={{
              margin: '0 0 12px 0',
              fontSize: 'clamp(18px, 2.5vw, 24px)',
              fontWeight: '700',
              color: isDark ? '#f1f5f9' : '#1f2937'
            }}>
              {item.title}
            </h3>
          )}

          {/* Description */}
          {item.description && (
            <p style={{
              margin: '0 0 16px 0',
              color: isDark ? '#cbd5e1' : '#6b7280',
              lineHeight: '1.6'
            }}>
              {item.description}
            </p>
          )}

          {/* Tags */}
          {item.tags && item.tags.length > 0 && (
            <div style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '8px',
              marginBottom: '16px'
            }}>
              {item.tags.map((tag, tagIndex) => (
                <span
                  key={tagIndex}
                  style={{
                    background: isDark ? 'rgba(167, 139, 250, 0.2)' : 'rgba(99, 102, 241, 0.1)',
                    color: isDark ? '#a78bfa' : '#6366f1',
                    padding: '4px 12px',
                    borderRadius: '12px',
                    fontSize: '12px',
                    fontWeight: '600'
                  }}
                >
                  {tag}
                </span>
              ))}
            </div>
          )}

          {/* Link/Action */}
          {item.link && (
            <a
              href={item.link.href}
              style={{
                color: isDark ? '#06b6d4' : '#0891b2',
                textDecoration: 'none',
                fontWeight: '600',
                fontSize: '14px',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px'
              }}
              target="_blank"
              rel="noopener noreferrer"
            >
              {item.link.text} →
            </a>
          )}

          {/* Custom content */}
          {item.content && (
            <div style={{ marginTop: '16px' }}>
              {item.content}
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div style={containerStyle} {...props}>
      {renderTimelineLine()}
      {items.map(renderTimelineItem)}
    </div>
  );
};
