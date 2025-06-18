import React from 'react';
import Chatbot from './pages/Chatbot';
import { Navbar, useConfig } from "nextra-theme-docs";
import { useRouter } from "next/router";

export default {
    head() {
        const { asPath, defaultLocale, locale } = useRouter();
        const { frontMatter } = useConfig();
        const url =
            'https://feds201.com' +
            (defaultLocale === locale ? asPath : `/${locale}${asPath}`);

        return (
            <>
                <meta property="og:url" content={url} />
                <meta property="og:title" content={frontMatter.title || 'FEDS201'} />
                <meta property="og:image" content={frontMatter.image || 'https://i.imgur.com/9O6F2mo.png'} />
                <meta property="og:description" content={frontMatter.description || 'FEDS201 - Advanced Robotics Team Operations Manual'} />
                <meta name="titleSuffix" content="FEDS201" />
                <meta name="description" content="FEDS201 - Advanced Robotics Team Operations Manual" />
                <link rel="icon" href="https://i.imgur.com/9O6F2mo.png" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <meta name="twitter:card" content="summary_large_image" />
                <meta name="twitter:site" content="@feds201" />
                <meta name="msapplication-TileColor" content="#1a365d" />
                <meta name="theme-color" content="#1a365d" />
                <meta name="google-site-verification" content="0LNTJPoseM_CflO4_VtHt5-HsjPSnKEunUGr7-APSZI" />
                
                {/* Enhanced fonts */}
                <link rel="preconnect" href="https://fonts.googleapis.com" />
                <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
                <link
                    href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap"
                    rel="stylesheet"
                />
                
                {/* Custom CSS for enhanced theme */}
                <style jsx global>{`
                    :root {
                        --primary-hue: 210;
                        --primary-saturation: 65%;
                        --primary-lightness: 45%;
                        --gradient-primary: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        --gradient-secondary: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                        --shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
                        --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                        --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
                    }
                    
                    .nextra-nav-container {
                        backdrop-filter: blur(12px);
                        background: rgba(255, 255, 255, 0.85);
                        border-bottom: 1px solid rgba(0, 0, 0, 0.05);
                        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                    }
                    
                    .dark .nextra-nav-container {
                        background: rgba(17, 24, 39, 0.85);
                        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
                    }
                    
                    .nextra-sidebar {
                        border-right: 1px solid rgba(0, 0, 0, 0.05);
                        backdrop-filter: blur(8px);
                    }
                    
                    .dark .nextra-sidebar {
                        border-right: 1px solid rgba(255, 255, 255, 0.1);
                    }
                    
                    .nextra-sidebar a {
                        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
                        border-radius: 8px;
                        margin: 2px 0;
                    }
                    
                    .nextra-sidebar a:hover {
                        background: rgba(99, 102, 241, 0.1);
                        transform: translateX(2px);
                    }
                    
                    .nextra-toc a {
                        transition: all 0.2s ease;
                        border-radius: 4px;
                        padding: 2px 8px;
                    }
                    
                    .nextra-toc a:hover {
                        background: rgba(99, 102, 241, 0.1);
                        color: #6366f1;
                    }
                    
                    /* Enhanced code blocks */
                    pre {
                        border: 1px solid rgba(0, 0, 0, 0.1);
                        box-shadow: var(--shadow-sm);
                        border-radius: 12px;
                        font-family: 'JetBrains Mono', monospace;
                    }
                    
                    .dark pre {
                        border: 1px solid rgba(255, 255, 255, 0.1);
                    }
                    
                    /* Beautiful search */
                    .nextra-search input {
                        border: 1px solid rgba(0, 0, 0, 0.1);
                        border-radius: 12px;
                        transition: all 0.3s ease;
                        box-shadow: var(--shadow-sm);
                    }
                    
                    .nextra-search input:focus {
                        border-color: #6366f1;
                        box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
                    }
                    
                    /* Smooth animations */
                    * {
                        transition: color 0.2s ease, background-color 0.2s ease, border-color 0.2s ease;
                    }
                    
                    /* Enhanced buttons */
                    button {
                        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
                    }
                    
                    button:hover {
                        transform: translateY(-1px);
                        box-shadow: var(--shadow-md);
                    }
                `}</style>
            </>
        );
    },

    logo: (
        <div style={{ 
            display: 'flex', 
            alignItems: 'center',
            gap: '12px',
            transition: 'all 0.3s ease'
        }}>
            <div style={{
                position: 'relative',
                display: 'inline-block'
            }}>
                <img
                    src="https://i.imgur.com/9O6F2mo.png"
                    alt="FEDS201"
                    width="36"
                    height="36"
                    style={{ 
                        borderRadius: '12px', 
                        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                        boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
                        border: '2px solid rgba(255, 255, 255, 0.2)',
                    }}
                    onMouseEnter={(e) => {
                        e.target.style.transform = 'scale(1.1) rotate(5deg)';
                        e.target.style.boxShadow = '0 8px 25px rgba(0, 0, 0, 0.25)';
                    }}
                    onMouseLeave={(e) => {
                        e.target.style.transform = 'scale(1) rotate(0deg)';
                        e.target.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.15)';
                    }}
                />
                <div style={{
                    position: 'absolute',
                    top: '-2px',
                    right: '-2px',
                    width: '12px',
                    height: '12px',
                    background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                    borderRadius: '50%',
                    border: '2px solid white',
                    animation: 'pulse 2s infinite'
                }} />
            </div>
            <div>
                <div style={{ 
                    fontWeight: '700',
                    fontSize: '18px',
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                    backgroundClip: 'text',
                    letterSpacing: '-0.025em'
                }}>
                    FEDS Operational Manual
                </div>
                <div style={{
                    fontSize: '11px',
                    color: '#6b7280',
                    fontWeight: '500',
                    marginTop: '2px',
                    letterSpacing: '0.025em'
                }}>
                    FEDS 201 FRC Robotics Team
                </div>
            </div>
            <style jsx>{`
                @keyframes pulse {
                    0%, 100% { opacity: 1; }
                    50% { opacity: 0.5; }
                }
            `}</style>
        </div>
    ),

    project: {
        link: 'https://github.com/feds201/FEDS-Handbook',
        icon: (
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 0C5.374 0 0 5.373 0 12 0 17.302 3.438 21.8 8.207 23.387c.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0112 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z"/>
            </svg>
        )
    },

    chat: {
        link: 'https://feds-handbook.vercel.app/Chatbot',
        icon: (
            <div style={{
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                borderRadius: '8px',
                padding: '6px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                transition: 'all 0.3s ease'
            }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="white">
                    <path d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                </svg>
            </div>
        )
    },

    docsRepositoryBase: 'https://github.com/feds201/FEDS-Handbook/tree/main',

    footer: {
        text: (
            <div style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '16px',
                padding: '24px 0',
                borderTop: '1px solid rgba(0, 0, 0, 0.1)'
            }}>
                <div style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    flexWrap: 'wrap',
                    gap: '16px'
                }}>
                    <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '24px',
                        flexWrap: 'wrap'
                    }}>
                        <a 
                            href="https://feds201.com" 
                            target="_blank" 
                            rel="noopener noreferrer"
                            style={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: '8px',
                                fontWeight: '600',
                                color: '#374151',
                                textDecoration: 'none',
                                transition: 'all 0.2s ease'
                            }}
                            onMouseEnter={(e) => {
                                e.target.style.color = '#6366f1';
                                e.target.style.transform = 'translateY(-1px)';
                            }}
                            onMouseLeave={(e) => {
                                e.target.style.color = '#374151';
                                e.target.style.transform = 'translateY(0)';
                            }}
                        >
                            <img 
                                src="https://i.imgur.com/9O6F2mo.png" 
                                alt="FEDS201" 
                                width="20" 
                                height="20" 
                                style={{ borderRadius: '4px' }}
                            />
                            FEDS201
                        </a>
                        <a 
                            href="https://rhs-csclub.vercel.app" 
                            target="_blank" 
                            rel="noopener noreferrer"
                            style={{
                                color: '#6b7280',
                                textDecoration: 'none',
                                fontSize: '14px',
                                fontWeight: '500',
                                transition: 'color 0.2s ease'
                            }}
                            onMouseEnter={(e) => e.target.style.color = '#6366f1'}
                            onMouseLeave={(e) => e.target.style.color = '#6b7280'}
                        >
                            CS-Club
                        </a>
                    </div>
                    <div style={{
                        fontSize: '14px',
                        color: '#9ca3af',
                        fontWeight: '500'
                    }}>
                        © {new Date().getFullYear()} All rights reserved
                    </div>
                </div>
                <div style={{
                    fontSize: '12px',
                    color: '#9ca3af',
                    textAlign: 'center',
                    fontStyle: 'italic'
                }}>
                    Empowering the next generation of Falcons
                </div>
            </div>
        ),
    },

    useNextSeoProps() {
        const { asPath } = useRouter()
        if (asPath !== '/') {
            return {
                titleTemplate: '%s – FEDS201 Operational Manual'
            }
        }
        return {
            title: 'FEDS201 Operational Manual – Advanced Robotics Team',
            description: 'Complete operational manual for FEDS201 advanced robotics team operations, procedures, and best practices.'
        }
    },

    sidebar: {
        defaultMenuCollapseLevel: 1,
        autoCollapse: true,
        toggleButton: true,
    },

    navigation: {
        prev: true,
        next: true,
    },

    toc: {
        backToTop: true,
        float: true,
    },

    editLink: {
        text: 'Edit this page on GitHub →'
    },

    feedback: {
        content: 'Question? Give us feedback →',
        labels: 'feedback'
    },

    gitTimestamp: ({ timestamp }) => (
        <div style={{ color: '#6b7280', fontSize: '14px' }}>
            Last updated on {timestamp.toLocaleDateString()}
        </div>
    ),

    darkMode: true,
    nextThemes: {
        defaultTheme: 'system'
    }
};
