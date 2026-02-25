import React from "react";
import { Navbar, useConfig } from "nextra-theme-docs";
import { useRouter } from "next/router";

export default {
  head() {
    const { asPath, defaultLocale, locale } = useRouter();
    const { frontMatter } = useConfig();
    const url =
      "https://feds201.com" +
      (defaultLocale === locale ? asPath : `/${locale}${asPath}`);

    return (
      <>
        <meta property="og:url" content={url} />
        <meta property="og:title" content={frontMatter.title || "FEDS201"} />
        <meta
          property="og:image"
          content={frontMatter.image || "https://i.imgur.com/7grZvaT.png"}
        />
        <meta
          property="og:description"
          content={
            frontMatter.description ||
            "FEDS201 - Advanced Robotics Team Operations Manual"
          }
        />
        <meta name="titleSuffix" content="FEDS201" />
        <meta
          name="description"
          content="FEDS201 - Advanced Robotics Team Operations Manual"
        />
        <link rel="icon" href="https://i.imgur.com/pEpTlKh.png" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:site" content="@feds201" />
        <meta name="msapplication-TileColor" content="#1a365d" />
        <meta name="theme-color" content="#1a365d" />
        <meta
          name="google-site-verification"
          content="0LNTJPoseM_CflO4_VtHt5-HsjPSnKEunUGr7-APSZI"
        />
        {/* Google Analytics scripts moved to _app.js */}
        {/* Enhanced fonts moved to _document.js */}

        {/* Custom CSS for enhanced theme */}
        <style jsx global>{`
          :root {
            --primary-hue: 210;
            --primary-saturation: 65%;
            --primary-lightness: 45%;
            --gradient-primary: linear-gradient(
              135deg,
              #667eea 0%,
              #764ba2 100%
            );
            --gradient-secondary: linear-gradient(
              135deg,
              #f093fb 0%,
              #f5576c 100%
            );
            --shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1),
              0 1px 2px 0 rgba(0, 0, 0, 0.06);
            --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1),
              0 2px 4px -1px rgba(0, 0, 0, 0.06);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
              0 4px 6px -2px rgba(0, 0, 0, 0.05);
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
            font-family: "JetBrains Mono", monospace;
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
            transition: color 0.2s ease, background-color 0.2s ease,
              border-color 0.2s ease;
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
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: "12px",
        transition: "all 0.3s ease",
      }}
    >
      <div
        style={{
          position: "relative",
          display: "inline-block",
        }}
      >
        <img
          src="https://i.imgur.com/pEpTlKh.png"
          alt="FEDS201"
          width="36"
          height="36"
          style={{
            borderRadius: "12px",
            transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
            boxShadow: "0 4px 12px rgba(0, 0, 0, 0.15)",
            border: "2px solid rgba(255, 255, 255, 0.2)",
          }}
          onMouseEnter={(e) => {
            e.target.style.transform = "scale(1.1) rotate(5deg)";
            e.target.style.boxShadow = "0 8px 25px rgba(0, 0, 0, 0.25)";
          }}
          onMouseLeave={(e) => {
            e.target.style.transform = "scale(1) rotate(0deg)";
            e.target.style.boxShadow = "0 4px 12px rgba(0, 0, 0, 0.15)";
          }}
        />
        <div
          style={{
            position: "absolute",
            top: "-2px",
            right: "-2px",
            width: "12px",
            height: "12px",
            background: "linear-gradient(135deg, #10b981 0%, #059669 100%)",
            borderRadius: "50%",
            border: "2px solid white",
            animation: "pulse 2s infinite",
          }}
        />
      </div>
      <div>
        <div
          style={{
            fontWeight: "700",
            fontSize: "18px",
            background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            backgroundClip: "text",
            letterSpacing: "-0.025em",
          }}
        >
          FEDS Operational Manual
        </div>
        <div
          style={{
            fontSize: "11px",
            color: "#6b7280",
            fontWeight: "500",
            marginTop: "2px",
            letterSpacing: "0.025em",
          }}
        >
          FEDS 201 FRC Robotics Team
        </div>
      </div>
      <style jsx>{`
        @keyframes pulse {
          0%,
          100% {
            opacity: 1;
          }
          50% {
            opacity: 0.5;
          }
        }
      `}</style>
    </div>
  ),

  project: {
    link: "https://github.com/feds201/FEDS-Handbook",
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 0C5.374 0 0 5.373 0 12 0 17.302 3.438 21.8 8.207 23.387c.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0112 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
      </svg>
    ),
  },

  docsRepositoryBase: "https://github.com/feds201/FEDS-Handbook/tree/main",

    footer: {
        text: (
            <div
                style={{
                    width: "100%",
                    display: "flex",
                    flexDirection: "column",
                    gap: "3rem",
                    padding: "4rem 0 2rem",
                    borderTop: "1px solid rgba(0,0,0,0.08)",
                    fontSize: "0.9rem",
                }}
            >
                {/* Main Footer Grid */}
                <div
                    className="footer-grid"
                    style={{
                        display: "grid",
                        gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                        gap: "2rem",
                    }}
                >
                    {/* Column 1: Brand & Mission */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
                        <a
                            href="https://feds201.com"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="brand-link"
                            style={{
                                display: "flex",
                                alignItems: "center",
                                gap: "0.75rem",
                                textDecoration: "none",
                                color: "inherit",
                                width: "fit-content",
                            }}
                        >
                            <img
                                src="https://i.imgur.com/pEpTlKh.png"
                                alt="FEDS201 Logo"
                                width="40"
                                height="40"
                                style={{ borderRadius: "8px" }}
                            />
                            <span style={{ fontWeight: 700, fontSize: "1.2rem" }}>FEDS 201</span>
                        </a>
                        <p style={{ opacity: 0.7, lineHeight: "1.6" }}>
                            Inspiring students to be STEM leaders through mentoring and innovation.
                            Transforming culture by celebrating science and technology.
                        </p>
                        <div style={{ display: "flex", gap: "0.5rem", marginTop: "0.5rem" }}>
                            {/* Social Placeholders or Badges could go here */}
                            <span style={{
                                fontSize: "0.75rem",
                                padding: "0.25rem 0.75rem",
                                borderRadius: "99px",
                                background: "rgba(100,100,100,0.1)",
                                fontWeight: 600
                            }}>
                Est. 1998
              </span>
                        </div>
                    </div>

                    {/* Column 2: Discover */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
                        <h4 style={{ fontWeight: 700, fontSize: "1rem", marginBottom: "0.25rem" }}>Discover</h4>
                        <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", opacity: 0.8 }}>
                            <a href="https://feds201.com/#about-us" className="footer-link">About Us</a>
                            <a href="https://feds201.com/#feds-history" className="footer-link">FEDS' History</a>
                            <a href="#" className="footer-link">Our Robots</a>
                            <a href="https://feds201.com/#operations-home-page" className="footer-link">Key Operations</a>
                            <a href="https://feds201.com/#frc-resource-library-p-c" className="footer-link">FRC Resources</a>
                        </div>
                    </div>

                    {/* Column 3: Community */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
                        <h4 style={{ fontWeight: 700, fontSize: "1rem", marginBottom: "0.25rem" }}>Community</h4>
                        <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", opacity: 0.8 }}>
                            <a href="https://feds201.com/#sponsor-relations" className="footer-link">Sponsors</a>
                            <a href="https://venmo.com/stemunited201" className="footer-link">Donate</a>
                            <a href="https://feds201.com/#agent-progress-tracker" className="footer-link">Agent Portal</a>
                            <a href="https://docs.google.com/forms/d/e/1FAIpQLScaCG7IO5z2rkSXDnx14QGBRQCL5hUfY9YVSUvCFXrbXyF-rA/viewform" className="footer-link">Contact Us</a>
                        </div>
                    </div>

                    {/* Column 4: Contact & Motto */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
                        <div>
                            <h4 style={{ fontWeight: 700, fontSize: "1rem", marginBottom: "0.5rem" }}>Location</h4>
                            <p style={{ opacity: 0.7, lineHeight: "1.6" }}>
                                Rochester High School<br />
                                Rochester Hills, Michigan<br />
                                USA
                            </p>
                        </div>

                        <div style={{
                            padding: "1rem",
                            borderRadius: "0.75rem",
                            background: "linear-gradient(135deg, rgba(20, 184, 166, 0.1), rgba(59, 130, 246, 0.1))",
                            border: "1px solid rgba(20, 184, 166, 0.2)"
                        }}>
              <span style={{
                  display: "block",
                  fontSize: "0.75rem",
                  fontWeight: 700,
                  textTransform: "uppercase",
                  letterSpacing: "0.05em",
                  marginBottom: "0.25rem",
                  color: "#0d9488"
              }}>
                Team Motto
              </span>
                            <span style={{ fontWeight: 600, fontStyle: "italic" }}>
                "Once a FED, Always a FED"
              </span>
                        </div>
                    </div>
                </div>

                {/* Divider */}
                <div style={{ width: "100%", height: "1px", background: "rgba(0,0,0,0.08)" }} />

                {/* Bottom Bar */}
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        flexWrap: "wrap",
                        gap: "1rem",
                        fontSize: "0.85rem",
                    }}
                >
                    <div style={{ opacity: 0.6 }}>
                        © {new Date().getFullYear()} FEDS 201. All rights reserved.
                    </div>

                    <div
                        style={{
                            fontWeight: "600",
                            background: "linear-gradient(90deg, #14b8a6, #3b82f6)",
                            WebkitBackgroundClip: "text",
                            WebkitTextFillColor: "transparent",
                        }}
                    >
                        Empowering the next generation of Falcons
                    </div>
                </div>

                {/* Styles */}
                <style dangerouslySetInnerHTML={{__html: `
          .footer-link {
            text-decoration: none;
            color: inherit;
            transition: color 0.2s ease, transform 0.2s ease;
            display: inline-block;
          }
          .footer-link:hover {
            color: #14b8a6;
            transform: translateX(2px);
          }
          .brand-link:hover {
            opacity: 0.8;
          }
          @media (max-width: 768px) {
            .footer-grid {
              grid-template-columns: 1fr;
              gap: 2.5rem;
            }
          }
        `}} />
            </div>
        ),
    },
  useNextSeoProps() {
    const { asPath } = useRouter();
    if (asPath !== "/") {
      return {
        titleTemplate: "%s – FEDS201 Operational Manual",
      };
    }
    return {
      title: "FEDS201 Operational Manual – Advanced Robotics Team",
      description:
        "Complete operational manual for FEDS201 advanced robotics team operations, procedures, and best practices.",
    };
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
    text: "Edit this page on GitHub →",
  },

  feedback: {
    content: "Question? Give us feedback →",
    labels: "feedback",
  },

  gitTimestamp: ({ timestamp }) => (
    <div style={{ color: "#6b7280", fontSize: "14px" }}>
      Last updated on {timestamp.toLocaleDateString()}
    </div>
  ),
  darkMode: true,
  nextThemes: {
    defaultTheme: "dark",
  },
};
