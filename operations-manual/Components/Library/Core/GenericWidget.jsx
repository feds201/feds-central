"use client";
"use client";
import { useState, useEffect } from 'react';
import { useTheme } from 'nextra-theme-docs';

/**
 * Generic Widget Component - Highly configurable widget container
 * @param {Object} props - Component properties
 * @param {string} props.title - Widget title
 * @param {string} props.subtitle - Widget subtitle
 * @param {React.Component} props.icon - Widget icon
 * @param {React.Component} props.children - Widget content
 * @param {string} props.variant - Variant: 'default', 'card', 'minimal', 'glass', 'gradient', 'comparison', 'techStack', 'skillsMatrix', 'learningPath', 'projectsDemo'
 * @param {string} props.size - Size: 'sm', 'md', 'lg', 'xl'
 * @param {boolean} props.interactive - Enable interactive features
 * @param {string} props.link - Link URL (makes widget clickable)
 * @param {Object} props.animation - Animation configuration
 * @param {Object} props.spacing - Spacing configuration
 * @param {Object} props.customStyles - Override default styles
 * @param {Object} props.data - Data object for specialized widgets
 */
export const GenericWidget = ({
  title,
  subtitle,
  icon,
  children,
  variant = 'default',
  size = 'md',
  interactive = false,
  link,
  animation = { enabled: true, hover: true },
  spacing = { padding: '24px', margin: '0' },
  customStyles = {},
  data = {},
  onClick,
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  const [activeTab, setActiveTab] = useState(0);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;
  
  const isDark = theme === 'dark';

  // Specialized widget renderers
  const renderComparison = () => {
    const { leftSide, rightSide } = data;
    return (
      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '32px',
        alignItems: 'start'
      }}>
        <div style={{
          background: isDark ? 'rgba(59, 130, 246, 0.1)' : 'rgba(59, 130, 246, 0.05)',
          borderRadius: '16px',
          padding: '24px',
          border: '2px solid rgba(59, 130, 246, 0.2)'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            marginBottom: '16px'
          }}>
            <span style={{ fontSize: '24px', marginRight: '12px' }}>{leftSide.icon}</span>
            <h3 style={{
              fontSize: '18px',
              fontWeight: '600',
              color: isDark ? '#f1f5f9' : '#1e293b',
              margin: 0
            }}>{leftSide.title}</h3>
          </div>
          <ul style={{
            listStyle: 'none',
            padding: 0,
            margin: 0
          }}>
            {leftSide.items.map((item, i) => (
              <li key={i} style={{
                padding: '8px 0',
                color: isDark ? '#cbd5e1' : '#475569',
                fontSize: '14px'
              }}>
                ✓ {item}
              </li>
            ))}
          </ul>
        </div>
        
        <div style={{
          background: isDark ? 'rgba(147, 51, 234, 0.1)' : 'rgba(147, 51, 234, 0.05)',
          borderRadius: '16px',
          padding: '24px',
          border: '2px solid rgba(147, 51, 234, 0.2)'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            marginBottom: '16px'
          }}>
            <span style={{ fontSize: '24px', marginRight: '12px' }}>{rightSide.icon}</span>
            <h3 style={{
              fontSize: '18px',
              fontWeight: '600',
              color: isDark ? '#f1f5f9' : '#1e293b',
              margin: 0
            }}>{rightSide.title}</h3>
          </div>
          <ul style={{
            listStyle: 'none',
            padding: 0,
            margin: 0
          }}>
            {rightSide.items.map((item, i) => (
              <li key={i} style={{
                padding: '8px 0',
                color: isDark ? '#cbd5e1' : '#475569',
                fontSize: '14px'
              }}>
                ✓ {item}
              </li>
            ))}
          </ul>
        </div>
      </div>
    );
  };

  const renderTechStack = () => {
    const { categories } = data;
    return (
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '24px'
      }}>
        {categories.map((category, i) => (
          <div key={i} style={{
            background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
            borderRadius: '16px',
            padding: '24px',
            border: isDark ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.05)'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              marginBottom: '16px'
            }}>
              <span style={{ fontSize: '24px', marginRight: '12px' }}>{category.icon}</span>
              <h4 style={{
                fontSize: '16px',
                fontWeight: '600',
                color: isDark ? '#f1f5f9' : '#1e293b',
                margin: 0
              }}>{category.name}</h4>
            </div>
            <div style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '8px'
            }}>
              {category.technologies.map((tech, j) => (
                <span key={j} style={{
                  background: isDark ? 'rgba(59, 130, 246, 0.2)' : 'rgba(59, 130, 246, 0.1)',
                  color: isDark ? '#93c5fd' : '#3b82f6',
                  padding: '4px 12px',
                  borderRadius: '12px',
                  fontSize: '12px',
                  fontWeight: '500'
                }}>
                  {tech}
                </span>
              ))}
            </div>
          </div>
        ))}
      </div>
    );
  };

  const renderSkillsMatrix = () => {
    const { skills } = data;
    return (
      <div style={{
        overflow: 'auto'
      }}>
        <table style={{
          width: '100%',
          borderCollapse: 'collapse'
        }}>
          <thead>
            <tr>
              <th style={{
                textAlign: 'left',
                padding: '12px',
                borderBottom: isDark ? '2px solid rgba(255, 255, 255, 0.1)' : '2px solid rgba(0, 0, 0, 0.1)',
                color: isDark ? '#f1f5f9' : '#1e293b',
                fontWeight: '600'
              }}>Skill</th>
              <th style={{
                textAlign: 'left',
                padding: '12px',
                borderBottom: isDark ? '2px solid rgba(255, 255, 255, 0.1)' : '2px solid rgba(0, 0, 0, 0.1)',
                color: isDark ? '#f1f5f9' : '#1e293b',
                fontWeight: '600'
              }}>Beginner</th>
              <th style={{
                textAlign: 'left',
                padding: '12px',
                borderBottom: isDark ? '2px solid rgba(255, 255, 255, 0.1)' : '2px solid rgba(0, 0, 0, 0.1)',
                color: isDark ? '#f1f5f9' : '#1e293b',
                fontWeight: '600'
              }}>Intermediate</th>
              <th style={{
                textAlign: 'left',
                padding: '12px',
                borderBottom: isDark ? '2px solid rgba(255, 255, 255, 0.1)' : '2px solid rgba(0, 0, 0, 0.1)',
                color: isDark ? '#f1f5f9' : '#1e293b',
                fontWeight: '600'
              }}>Advanced</th>
            </tr>
          </thead>
          <tbody>
            {skills.map((skill, i) => (
              <tr key={i}>
                <td style={{
                  padding: '12px',
                  borderBottom: isDark ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                  color: isDark ? '#f1f5f9' : '#1e293b',
                  fontWeight: '500'
                }}>{skill.name}</td>
                <td style={{
                  padding: '12px',
                  borderBottom: isDark ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                  color: isDark ? '#cbd5e1' : '#475569',
                  fontSize: '14px'
                }}>{skill.beginner}</td>
                <td style={{
                  padding: '12px',
                  borderBottom: isDark ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                  color: isDark ? '#cbd5e1' : '#475569',
                  fontSize: '14px'
                }}>{skill.intermediate}</td>
                <td style={{
                  padding: '12px',
                  borderBottom: isDark ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
                  color: isDark ? '#cbd5e1' : '#475569',
                  fontSize: '14px'
                }}>{skill.advanced}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  };

  const renderLearningPath = () => {
    const { phases } = data;
    return (
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '24px'
      }}>
        {phases.map((phase, i) => (
          <div key={i} style={{
            display: 'flex',
            alignItems: 'flex-start',
            gap: '20px'
          }}>
            <div style={{
              width: '40px',
              height: '40px',
              borderRadius: '50%',
              background: `linear-gradient(135deg, hsl(${i * 90}deg, 70%, 50%), hsl(${i * 90 + 45}deg, 70%, 60%))`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontWeight: 'bold',
              fontSize: '16px',
              flexShrink: 0
            }}>
              {i + 1}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                marginBottom: '8px'
              }}>
                <h4 style={{
                  fontSize: '18px',
                  fontWeight: '600',
                  color: isDark ? '#f1f5f9' : '#1e293b',
                  margin: 0
                }}>{phase.title}</h4>
                <span style={{
                  background: isDark ? 'rgba(59, 130, 246, 0.2)' : 'rgba(59, 130, 246, 0.1)',
                  color: isDark ? '#93c5fd' : '#3b82f6',
                  padding: '2px 8px',
                  borderRadius: '8px',
                  fontSize: '12px',
                  fontWeight: '500'
                }}>
                  {phase.duration}
                </span>
              </div>
              <p style={{
                color: isDark ? '#cbd5e1' : '#475569',
                fontSize: '14px',
                margin: '0 0 12px 0'
              }}>
                Skills: {phase.skills.join(', ')}
              </p>
              <p style={{
                color: isDark ? '#94a3b8' : '#64748b',
                fontSize: '14px',
                margin: 0
              }}>
                Projects: {phase.projects.join(', ')}
              </p>
            </div>
          </div>
        ))}
      </div>
    );
  };

  const renderProjectsDemo = () => {
    const { projects } = data;
    return (
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
        gap: '24px'
      }}>
        {projects.map((project, i) => (
          <div key={i} style={{
            background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(255, 255, 255, 0.8)',
            borderRadius: '16px',
            padding: '24px',
            border: isDark ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.05)',
            transition: 'all 0.3s ease',
            cursor: 'pointer'
          }}>
            <div style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'flex-start',
              marginBottom: '12px'
            }}>
              <h4 style={{
                fontSize: '16px',
                fontWeight: '600',
                color: isDark ? '#f1f5f9' : '#1e293b',
                margin: 0
              }}>{project.name}</h4>
              <span style={{
                background: project.status === 'Production' 
                  ? (isDark ? 'rgba(34, 197, 94, 0.2)' : 'rgba(34, 197, 94, 0.1)')
                  : project.status === 'Active'
                  ? (isDark ? 'rgba(59, 130, 246, 0.2)' : 'rgba(59, 130, 246, 0.1)')
                  : (isDark ? 'rgba(245, 158, 11, 0.2)' : 'rgba(245, 158, 11, 0.1)'),
                color: project.status === 'Production'
                  ? (isDark ? '#86efac' : '#22c55e')
                  : project.status === 'Active'
                  ? (isDark ? '#93c5fd' : '#3b82f6')
                  : (isDark ? '#fcd34d' : '#f59e0b'),
                padding: '2px 8px',
                borderRadius: '8px',
                fontSize: '11px',
                fontWeight: '500'
              }}>
                {project.status}
              </span>
            </div>
            <p style={{
              color: isDark ? '#cbd5e1' : '#475569',
              fontSize: '14px',
              margin: '0 0 12px 0',
              lineHeight: '1.4'
            }}>
              {project.description}
            </p>
            <div style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '6px',
              marginBottom: '12px'
            }}>
              {project.tech.map((tech, j) => (
                <span key={j} style={{
                  background: isDark ? 'rgba(147, 51, 234, 0.2)' : 'rgba(147, 51, 234, 0.1)',
                  color: isDark ? '#c4b5fd' : '#9333ea',
                  padding: '2px 8px',
                  borderRadius: '8px',
                  fontSize: '11px',
                  fontWeight: '500'
                }}>
                  {tech}
                </span>
              ))}
            </div>
            <p style={{
              color: isDark ? '#f59e0b' : '#d97706',
              fontSize: '12px',
              fontWeight: '500',
              margin: 0
            }}>
              Impact: {project.impact}
            </p>
          </div>
        ))}
      </div>
    );
  };

  const baseStyle = {
    background: isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.02)',
    border: isDark ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.05)',
    borderRadius: '16px',
    backdropFilter: 'blur(10px)',
    shadow: isDark 
      ? '0 4px 20px rgba(0, 0, 0, 0.3)' 
      : '0 4px 20px rgba(0, 0, 0, 0.1)',
    hoverShadow: isDark 
      ? '0 8px 30px rgba(0, 0, 0, 0.4)' 
      : '0 8px 30px rgba(0, 0, 0, 0.15)'
  };

  const variantConfig = {
    default: baseStyle,
    card: {
      ...baseStyle,
      background: isDark ? '#1e293b' : '#ffffff',
      border: 'none',
      borderRadius: '20px',
      backdropFilter: 'none',
      shadow: isDark 
        ? '0 10px 30px rgba(0, 0, 0, 0.5)' 
        : '0 10px 30px rgba(0, 0, 0, 0.1)',
      hoverShadow: isDark 
        ? '0 20px 40px rgba(0, 0, 0, 0.6)' 
        : '0 20px 40px rgba(0, 0, 0, 0.15)'
    },
    minimal: {
      background: 'transparent',
      border: isDark ? '1px solid rgba(255, 255, 255, 0.1)' : '1px solid rgba(0, 0, 0, 0.1)',
      borderRadius: '12px',
      backdropFilter: 'none',
      shadow: 'none',
      hoverShadow: isDark 
        ? '0 4px 20px rgba(0, 0, 0, 0.2)' 
        : '0 4px 20px rgba(0, 0, 0, 0.05)'
    },
    glass: {
      background: isDark 
        ? 'rgba(255, 255, 255, 0.1)' 
        : 'rgba(255, 255, 255, 0.25)',
      border: isDark 
        ? '1px solid rgba(255, 255, 255, 0.2)' 
        : '1px solid rgba(255, 255, 255, 0.3)',
      borderRadius: '20px',
      backdropFilter: 'blur(20px)',
      shadow: isDark 
        ? '0 8px 32px rgba(0, 0, 0, 0.4)' 
        : '0 8px 32px rgba(31, 38, 135, 0.37)',
      hoverShadow: isDark 
        ? '0 12px 40px rgba(0, 0, 0, 0.5)' 
        : '0 12px 40px rgba(31, 38, 135, 0.5)'
    },
    gradient: {
      background: 'linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%)',
      border: '1px solid rgba(102, 126, 234, 0.2)',
      borderRadius: '20px',
      backdropFilter: 'blur(20px)',
      shadow: '0 8px 32px rgba(102, 126, 234, 0.2)',
      hoverShadow: '0 12px 40px rgba(102, 126, 234, 0.3)'
    }
  };

  const sizeConfig = {
    sm: {
      padding: '16px',
      minHeight: '200px',
      iconSize: '20px',
      titleSize: '16px',
      subtitleSize: '14px'
    },
    md: {
      padding: '24px',
      minHeight: '250px',
      iconSize: '24px',
      titleSize: '18px',
      subtitleSize: '16px'
    },
    lg: {
      padding: '32px',
      minHeight: '300px',
      iconSize: '28px',
      titleSize: '20px',
      subtitleSize: '18px'
    },
    xl: {
      padding: '40px',
      minHeight: '350px',
      iconSize: '32px',
      titleSize: '22px',
      subtitleSize: '20px'
    }
  };

  const currentSize = sizeConfig[size];
  const currentVariant = variantConfig[variant] || baseStyle;

  const widgetStyle = {
    ...currentVariant,
    padding: spacing.padding || currentSize.padding,
    margin: spacing.margin,
    minHeight: currentSize.minHeight,
    display: 'flex',
    flexDirection: 'column',
    position: 'relative',
    cursor: (interactive || link || onClick) ? 'pointer' : 'default',
    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
    transform: animation.hover && isHovered ? 'translateY(-5px)' : 'translateY(0)',
    boxShadow: animation.hover && isHovered ? currentVariant.hoverShadow : currentVariant.shadow,
    ...customStyles
  };

  const handleClick = (e) => {
    if (onClick) onClick(e);
    if (link) window.open(link, '_blank');
  };

  const WidgetContent = () => (
    <div
      style={widgetStyle}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onClick={handleClick}
      {...props}
    >
      {/* Header */}
      {(icon || title || subtitle) && (
        <div style={{
          display: 'flex',
          alignItems: 'flex-start',
          gap: '16px',
          marginBottom: children ? '20px' : '0'
        }}>
          {/* Icon */}
          {icon && (
            <div style={{
              fontSize: currentSize.iconSize,
              color: isDark ? '#a78bfa' : '#6366f1',
              flexShrink: 0,
              display: 'flex',
              alignItems: 'center',
              marginTop: '4px'
            }}>
              {icon}
            </div>
          )}

          {/* Title and Subtitle */}
          <div style={{ flex: 1 }}>
            {title && (
              <h3 style={{
                margin: '0 0 8px 0',
                fontSize: currentSize.titleSize,
                fontWeight: '700',
                color: isDark ? '#f1f5f9' : '#1f2937',
                lineHeight: '1.3'
              }}>
                {title}
                <br />
              </h3>
            )}
            
            {subtitle && (
              <p style={{
                margin: '0',
                fontSize: currentSize.subtitleSize,
                color: isDark ? '#cbd5e1' : '#6b7280',
                lineHeight: '1.5'
              }}>
                {subtitle}
              </p>
            )}
          </div>
        </div>
      )}      {/* Content */}
      {variant === 'comparison' && renderComparison()}
      {variant === 'techStack' && renderTechStack()}
      {variant === 'skillsMatrix' && renderSkillsMatrix()}
      {variant === 'learningPath' && renderLearningPath()}
      {variant === 'projectsDemo' && renderProjectsDemo()}
      
      {children && !['comparison', 'techStack', 'skillsMatrix', 'learningPath', 'projectsDemo'].includes(variant) && (
        <div style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column'
        }}>
          {children}
        </div>
      )}

      {/* Link indicator */}
      {link && (
        <div style={{
          position: 'absolute',
          top: '16px',
          right: '16px',
          fontSize: '16px',
          color: isDark ? '#64748b' : '#9ca3af',
          opacity: 0.7,
          transition: 'opacity 0.3s ease'
        }}>
          ↗
        </div>
      )}

      {/* Hover overlay for interactive widgets */}
      {(interactive || link || onClick) && (
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(255, 255, 255, 0.05)',
          borderRadius: 'inherit',
          opacity: isHovered ? 1 : 0,
          transition: 'opacity 0.3s ease',
          pointerEvents: 'none'
        }} />
      )}

      <style jsx>{`
        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      `}</style>
    </div>
  );

  return animation.enabled ? (
    <div style={{
      animation: 'slideIn 0.6s ease-out'
    }}>
      <WidgetContent />
    </div>
  ) : (
    <WidgetContent />
  );
};
