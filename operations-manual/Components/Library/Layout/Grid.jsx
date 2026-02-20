"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

export const Grid = ({
  children,
  columns = 'auto-fit',
  minColumnWidth = '280px',
  gap = '24px',
  responsive = true,
  align = 'stretch',
  justify = 'start',
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
  
  // Handle different column configurations
  const getGridColumns = () => {
    if (typeof columns === 'number') {
      return `repeat(${columns}, 1fr)`;
    }
    if (typeof columns === 'string' && columns.includes('repeat')) {
      return columns;
    }
    if (columns === 'auto-fit') {
      return `repeat(auto-fit, minmax(${minColumnWidth}, 1fr))`;
    }
    if (columns === 'auto-fill') {
      return `repeat(auto-fill, minmax(${minColumnWidth}, 1fr))`;
    }
    return columns;
  };
  
  // Responsive breakpoints
  const getResponsiveColumns = () => {
    if (!responsive) return getGridColumns();
    
    const baseColumns = getGridColumns();
    return {
      default: baseColumns,
      tablet: typeof columns === 'number' && columns > 2 ? 'repeat(2, 1fr)' : baseColumns,
      mobile: 'repeat(1, 1fr)'
    };
  };
  
  const responsiveColumns = getResponsiveColumns();
  
  const gridStyle = {
    display: 'grid',
    gridTemplateColumns: typeof responsiveColumns === 'object' ? responsiveColumns.default : responsiveColumns,
    gap,
    alignItems: align,
    justifyItems: justify,
    width: '100%',
    ...style
  };
  
  return (
    <>
      <div style={gridStyle} className={className} {...props}>
        {children}
      </div>
      
      {responsive && typeof responsiveColumns === 'object' && (
        <style jsx>{`
          @media (max-width: 768px) {
            div {
              grid-template-columns: ${responsiveColumns.tablet} !important;
            }
          }
          @media (max-width: 480px) {
            div {
              grid-template-columns: ${responsiveColumns.mobile} !important;
            }
          }
        `}</style>
      )}
    </>
  );
};

export const GridItem = ({
  children,
  colSpan = 1,
  rowSpan = 1,
  className = '',
  style = {},
  ...props
}) => {
  const itemStyle = {
    gridColumn: colSpan > 1 ? `span ${colSpan}` : 'auto',
    gridRow: rowSpan > 1 ? `span ${rowSpan}` : 'auto',
    ...style
  };
  
  return (
    <div style={itemStyle} className={className} {...props}>
      {children}
    </div>
  );
};
