"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

export const Tabs = ({
  tabs = [],
  defaultTab = 0,
  variant = 'default',
  size = 'medium',
  onChange,
  className = '',
  style = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [activeTab, setActiveTab] = useState(defaultTab);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const handleTabChange = (index) => {
    setActiveTab(index);
    onChange?.(index);
  };
  
  const sizes = {
    small: { padding: '8px 16px', fontSize: '14px' },
    medium: { padding: '12px 20px', fontSize: '16px' },
    large: { padding: '16px 24px', fontSize: '18px' }
  };
  
  return (
    <div style={{ ...style }} className={className} {...props}>
      {/* Tab Headers */}
      <div style={{
        display: 'flex',
        background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.05)',
        borderRadius: '12px',
        padding: '4px',
        marginBottom: '24px',
        gap: variant === 'pills' ? '8px' : '0',
        flexWrap: 'wrap'
      }}>
        {tabs.map((tab, index) => (
          <button
            key={index}
            onClick={() => handleTabChange(index)}
            style={{
              ...sizes[size],
              background: activeTab === index 
                ? (isDark ? '#374151' : '#ffffff') 
                : 'transparent',
              border: 'none',
              borderRadius: variant === 'pills' ? '8px' : '8px',
              color: activeTab === index 
                ? (isDark ? '#f1f5f9' : '#1e293b')
                : (isDark ? '#94a3b8' : '#64748b'),
              fontWeight: activeTab === index ? '600' : '500',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              flex: variant === 'pills' ? '0 0 auto' : '1',
              minWidth: variant === 'pills' ? 'auto' : '0',
              boxShadow: activeTab === index ? '0 2px 8px rgba(0, 0, 0, 0.1)' : 'none',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px'
            }}
          >
            {tab.icon && <span>{tab.icon}</span>}
            <span>{tab.label}</span>
            {tab.badge && (
              <span style={{
                background: '#ef4444',
                color: 'white',
                borderRadius: '12px',
                padding: '2px 8px',
                fontSize: '12px',
                fontWeight: '600'
              }}>
                {tab.badge}
              </span>
            )}
          </button>
        ))}
      </div>
      
      {/* Tab Content */}
      <div>
        {tabs[activeTab]?.content}
      </div>
    </div>
  );
};

export const Accordion = ({
  items = [],
  allowMultiple = false,
  defaultOpen = [],
  variant = 'default',
  className = '',
  style = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [openItems, setOpenItems] = useState(new Set(defaultOpen));
  
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';
  
  const toggleItem = (index) => {
    const newOpenItems = new Set(openItems);
    
    if (newOpenItems.has(index)) {
      newOpenItems.delete(index);
    } else {
      if (!allowMultiple) {
        newOpenItems.clear();
      }
      newOpenItems.add(index);
    }
    
    setOpenItems(newOpenItems);
  };
  
  return (
    <div style={{ ...style }} className={className} {...props}>
      {items.map((item, index) => {
        const isOpen = openItems.has(index);
        
        return (
          <div
            key={index}
            style={{
              background: isDark 
                ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
                : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
              borderRadius: '16px',
              marginBottom: '12px',
              border: isDark 
                ? '1px solid rgba(255, 255, 255, 0.1)'
                : '1px solid rgba(0, 0, 0, 0.05)',
              overflow: 'hidden',
              transition: 'all 0.3s ease'
            }}
          >
            {/* Header */}
            <button
              onClick={() => toggleItem(index)}
              style={{
                width: '100%',
                padding: '20px 24px',
                background: 'transparent',
                border: 'none',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                cursor: 'pointer',
                color: isDark ? '#f1f5f9' : '#1e293b',
                fontSize: '18px',
                fontWeight: '600',
                textAlign: 'left'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                {item.icon && <span>{item.icon}</span>}
                <span>{item.title}</span>
              </div>
              
              <span style={{
                transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                transition: 'transform 0.3s ease',
                fontSize: '16px'
              }}>
                ▼
              </span>
            </button>
            
            {/* Content */}
            <div style={{
              maxHeight: isOpen ? '1000px' : '0',
              overflow: 'hidden',
              transition: 'max-height 0.3s ease'
            }}>
              <div style={{
                padding: '0 24px 24px 24px',
                color: isDark ? '#cbd5e1' : '#64748b',
                lineHeight: '1.6'
              }}>
                {item.content}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
};

export const Modal = ({
  isOpen = false,
  onClose,
  title,
  children,
  size = 'medium',
  variant = 'default',
  className = '',
  style = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  if (!mounted || !isOpen) return null;
  
  const isDark = theme === 'dark';
  
  const sizes = {
    small: { maxWidth: '400px' },
    medium: { maxWidth: '600px' },
    large: { maxWidth: '800px' },
    fullscreen: { maxWidth: '95vw', maxHeight: '95vh' }
  };
  
  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(0, 0, 0, 0.5)',
        backdropFilter: 'blur(8px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: '20px',
        animation: 'fadeIn 0.3s ease'
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          onClose?.();
        }
      }}
    >
      <div
        style={{
          background: isDark 
            ? 'linear-gradient(145deg, #1e293b 0%, #0f172a 100%)'
            : 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
          borderRadius: '24px',
          ...sizes[size],
          width: '100%',
          border: isDark 
            ? '1px solid rgba(255, 255, 255, 0.1)'
            : '1px solid rgba(0, 0, 0, 0.05)',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.8)',
          animation: 'slideIn 0.3s ease',
          ...style
        }}
        className={className}
        {...props}
      >
        {/* Header */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '24px 32px',
          borderBottom: isDark 
            ? '1px solid rgba(255, 255, 255, 0.1)'
            : '1px solid rgba(0, 0, 0, 0.05)'
        }}>
          {title && (
            <h2 style={{
              fontSize: '24px',
              fontWeight: '700',
              color: isDark ? '#f1f5f9' : '#1e293b',
              margin: 0
            }}>
              {title}
            </h2>
          )}
          
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              fontSize: '24px',
              cursor: 'pointer',
              color: isDark ? '#94a3b8' : '#64748b',
              padding: '8px',
              borderRadius: '8px',
              transition: 'all 0.2s ease'
            }}
            onMouseEnter={(e) => {
              e.target.style.background = isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)';
            }}
            onMouseLeave={(e) => {
              e.target.style.background = 'none';
            }}
          >
            ✕
          </button>
        </div>
        
        {/* Content */}
        <div style={{ padding: '32px' }}>
          {children}
        </div>
      </div>
      
      <style jsx>{`
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes slideIn {
          from { opacity: 0; transform: translateY(-20px) scale(0.95); }
          to { opacity: 1; transform: translateY(0) scale(1); }
        }
      `}</style>
    </div>
  );
};
