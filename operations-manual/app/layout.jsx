import { Footer, Layout, Navbar } from 'nextra-theme-docs'
import { Head, Banner, Search } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import StyledComponentsRegistry from '../lib/registry'
import 'nextra-theme-docs/style.css'
import '../global.css'

export const viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#1a365d',
}

export const metadata = {
  title: {
    template: '%s – FEDS201 Operational Manual',
    default: 'FEDS201 Operational Manual – Advanced Robotics Team'
  },
  description: "Complete operational manual for FEDS201 advanced robotics team operations, procedures, and best practices.",
  applicationName: 'FEDS201 Operational Manual',
  openGraph: {
    siteName: 'FEDS201',
    url: 'https://feds201.com',
    title: 'FEDS201',
    description: 'FEDS201 - Advanced Robotics Team Operations Manual',
    images: [
      {
        url: 'https://i.imgur.com/7grZvaT.png',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    site: '@feds201',
  },
  icons: {
    icon: 'https://i.imgur.com/pEpTlKh.png',
  },
  other: {
    'google-site-verification': '0LNTJPoseM_CflO4_VtHt5-HsjPSnKEunUGr7-APSZI',
  }
}

const Logo = () => (
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
  </div>
)

const FooterContent = () => (
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
    <div
      className="footer-grid"
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
        gap: "2rem",
      }}
    >
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

      <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
        <h4 style={{ fontWeight: 700, fontSize: "1rem", marginBottom: "0.25rem" }}>Community</h4>
        <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", opacity: 0.8 }}>
          <a href="https://feds201.com/#sponsor-relations" className="footer-link">Sponsors</a>
          <a href="https://venmo.com/stemunited201" className="footer-link">Donate</a>
          <a href="https://feds201.com/#agent-progress-tracker" className="footer-link">Agent Portal</a>
          <a href="https://docs.google.com/forms/d/e/1FAIpQLScaCG7IO5z2rkSXDnx14QGBRQCL5hUfY9YVSUvCFXrbXyF-rA/viewform" className="footer-link">Contact Us</a>
        </div>
      </div>

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

    <div style={{ width: "100%", height: "1px", background: "rgba(0,0,0,0.08)" }} />

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
  </div>
)

export default async function RootLayout({ children }) {
  const pageMap = await getPageMap()
  return (
    <html lang="en" suppressHydrationWarning>
      <Head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin=""
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-6MLHZ8LFC0"></script>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('js', new Date());
              gtag('config', 'G-6MLHZ8LFC0');
              gtag('config', 'G-N3TT9XBHV0');
            `,
          }}
        />
      </Head>
      <body suppressHydrationWarning>
        <StyledComponentsRegistry>
            <Layout
              navbar={
                <Navbar
                    logo={<Logo />}
                    projectLink="https://github.com/feds201/FEDS-Handbook"
                />
              }
              pageMap={pageMap}
              docsRepositoryBase="https://github.com/feds201/FEDS-Handbook/tree/main"
              editLink="Edit this page on GitHub →"
              sidebar={{ defaultMenuCollapseLevel: 1, autoCollapse: true, toggleButton: true }}
              footer={<Footer><FooterContent /></Footer>}
              toc={{ float: true, backToTop: true }}
              feedback={{ content: "Question? Give us feedback →", labels: "feedback" }}
              nextThemes={{ defaultTheme: 'dark' }}
            >
              {children}
            </Layout>
        </StyledComponentsRegistry>
      </body>
    </html>
  )
}
