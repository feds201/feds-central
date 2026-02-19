"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Grid Component - Highly configurable grid layout component
 * @param {Object} props - Component properties
 * @param {Array} props.items - Array of items to display in grid
 * @param {string} props.layout - Grid layout: 'auto', 'fixed', 'masonry', 'responsive'
 * @param {Object} props.columns - Column configuration
 * @param {string} props.gap - Grid gap (CSS value)
 * @param {Object} props.itemProps - Props to pass to each item
 * @param {Function} props.renderItem - Custom render function for items
 * @param {React.Component} props.children - Custom content (overrides items)
 * @param {Object} props.animation - Animation configuration
 * @param {Object} props.spacing - Spacing configuration
 * @param {Object} props.customStyles - Override default styles
 */
export const GenericGrid = ({
  items = [],
  layout = 'responsive',
  columns = { xs: 1, sm: 2, md: 3, lg: 4 },
  gap = '24px',
  itemProps = {},
  renderItem,
  children,
  animation = { enabled: true, stagger: 100 },
  spacing = { margin: '40px 0' },
  customStyles = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [visibleItems, setVisibleItems] = useState([]);

  useEffect(() => {
    setMounted(true);
    
    if (animation.enabled && items.length > 0) {
      // Stagger animation for items
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

  // Layout configurations
  const layoutConfig = {
    auto: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))'
    },
    fixed: {
      display: 'grid',
      gridTemplateColumns: `repeat(${columns.md || 3}, 1fr)`
    },
    masonry: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
      gridAutoRows: 'auto'
    },
    responsive: {
      display: 'grid',
      gridTemplateColumns: `repeat(${columns.xs || 1}, 1fr)`,
      '@media (min-width: 640px)': {
        gridTemplateColumns: `repeat(${columns.sm || 2}, 1fr)`
      },
      '@media (min-width: 768px)': {
        gridTemplateColumns: `repeat(${columns.md || 3}, 1fr)`
      },
      '@media (min-width: 1024px)': {
        gridTemplateColumns: `repeat(${columns.lg || 4}, 1fr)`
      }
    }
  };

  const gridStyle = {
    ...layoutConfig[layout],
    gap,
    margin: spacing.margin,
    padding: spacing.padding || '0',
    ...customStyles
  };

  // Render individual item
  const renderGridItem = (item, index) => {
    const isVisible = visibleItems.includes(index);
    
    const itemStyle = {
      opacity: animation.enabled ? (isVisible ? 1 : 0) : 1,
      transform: animation.enabled ? (isVisible ? 'translateY(0)' : 'translateY(20px)') : 'none',
      transition: 'all 0.6s cubic-bezier(0.4, 0, 0.2, 1)',
      ...itemProps.style
    };

    if (renderItem) {
      return (
        <div key={index} style={itemStyle}>
          {renderItem(item, index)}
        </div>
      );
    }

    // Default item rendering
    return (
      <div key={index} style={{
        ...itemStyle,
        background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.02)',
        padding: '20px',
        borderRadius: '12px',
        border: isDark ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.05)',
        backdropFilter: 'blur(10px)'
      }}>
        {typeof item === 'string' ? (
          <p>{item}</p>
        ) : (
          <>
            {item.title && <h3 style={{ margin: '0 0 12px 0', color: isDark ? '#f1f5f9' : '#1f2937' }}>{item.title}</h3>}
            {item.description && <p style={{ margin: '0', color: isDark ? '#cbd5e1' : '#6b7280' }}>{item.description}</p>}
            {item.content && <div>{item.content}</div>}
          </>
        )}
      </div>
    );
  };

  return (
    <div style={gridStyle} {...props}>
      {children || items.map(renderGridItem)}
      
      <style jsx>{`
        @media (min-width: 640px) {
          .responsive-grid {
            grid-template-columns: repeat(${columns.sm || 2}, 1fr);
          }
        }
        @media (min-width: 768px) {
          .responsive-grid {
            grid-template-columns: repeat(${columns.md || 3}, 1fr);
          }
        }
        @media (min-width: 1024px) {
          .responsive-grid {
            grid-template-columns: repeat(${columns.lg || 4}, 1fr);
          }
        }
      `}</style>
    </div>
  );
};
