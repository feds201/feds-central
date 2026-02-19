'use client';
import Link from 'next/link';

export const BuildKnowledgeSection = () => {
  return (
    <div
      style={{
        textAlign: "center",
        padding: "clamp(40px, 10vw, 80px) clamp(20px, 6vw, 40px)",
        background: "linear-gradient(135deg, #1e293b 0%, #0f172a 100%)",
        borderRadius: "clamp(16px, 4vw, 32px)",
        color: "white",
        margin: "clamp(40px, 10vw, 80px) clamp(16px, 4vw, 0px)",
        position: "relative",
        overflow: "hidden",
      }}
    >  <div
        style={{
          position: "absolute",
          top: "clamp(10px, 3vw, 20px)",
          left: "clamp(10px, 3vw, 20px)",
          fontSize: "clamp(50px, 12vw, 100px)",
          opacity: "0.1",
        }}
      >
        🚀
      </div>

      <h2
        style={{
          fontSize: "clamp(36px, 6vw, 56px)",
          fontWeight: "800",
          marginBottom: "24px",
          textShadow: "0 4px 8px rgba(0, 0, 0, 0.3)",
        }}
      >
        Ready to Build Knowledge?
      </h2>  <p
        style={{
          fontSize: "clamp(16px, 4vw, 22px)",
          opacity: "0.9",
          marginBottom: "clamp(32px, 8vw, 48px)",
          maxWidth: "700px",
          margin: "0 auto clamp(32px, 8vw, 48px)",
          lineHeight: "1.6",
        }}
      >
        Join the legacy of innovation, excellence, and performance. Your journey to
        robotics mastery starts here.
      </p>
      <div
        style={{
          display: "flex",
          gap: "clamp(12px, 4vw, 24px)",
          justifyContent: "center",
          flexWrap: "wrap",
          padding: "0 clamp(16px, 4vw, 0px)",
        }}
      >
        <Link href="/Home/Programming">      <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "clamp(12px, 3vw, 16px)",
              background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
              padding: "clamp(16px, 4vw, 20px) clamp(28px, 7vw, 40px)",
              borderRadius: "clamp(12px, 3vw, 16px)",
              fontWeight: "600",
              fontSize: "clamp(16px, 4vw, 18px)",
              textDecoration: "none",
              color: "white",
              transition: "all 0.3s ease",
              cursor: "pointer",
              boxShadow: "0 8px 16px -4px rgba(102, 126, 234, 0.4)",
            }}
          >
            Start Your Journey
          </div>
        </Link>

        <Link href="/FEDSHandbook">      <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "clamp(12px, 3vw, 16px)",
              background: "rgba(255, 255, 255, 0.1)",
              padding: "clamp(16px, 4vw, 20px) clamp(28px, 7vw, 40px)",
              borderRadius: "clamp(12px, 3vw, 16px)",
              fontWeight: "600",
              fontSize: "clamp(16px, 4vw, 18px)",
              textDecoration: "none",
              color: "white",
              transition: "all 0.3s ease",
              cursor: "pointer",
              border: "1px solid rgba(255, 255, 255, 0.2)",
              backdropFilter: "blur(10px)",
            }}
          >
            Team Handbook
          </div>
        </Link>
      </div>
    </div>
  );
};
