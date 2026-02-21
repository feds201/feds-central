'use client';
import { GenericCard } from './Library/Base/GenericCard';

const ModernCard = (props) => (
  <GenericCard
    variant="modern"
    size="lg"
    interactive={true}
    animation={{ enabled: true, hover: true }}
    {...props}
  />
);

export const SustainabilitySection = () => {
  return (
    <div
        style={{
          background: "linear-gradient(135deg, #10b981 0%, #059669 100%)",
          borderRadius: "clamp(16px, 4vw, 32px)",
          padding: "clamp(30px, 8vw, 60px) clamp(20px, 6vw, 40px)",
          margin: "clamp(40px, 10vw, 80px) clamp(16px, 4vw, 0px)",
          color: "white",
          textAlign: "center",
          position: "relative",
          overflow: "hidden",
        }}
      >  <div
        style={{
          position: "absolute",
          top: "10px",
          right: "clamp(10px, 3vw, 20px)",
          fontSize: "clamp(60px, 15vw, 120px)",
          opacity: "0.1",
        }}
      >
        🌱
      </div>

      <h2
        style={{
          fontSize: "clamp(28px, 4vw, 40px)",
          fontWeight: "800",
          marginBottom: "24px",
        }}
      >
        Environmental Leadership Initiative
      </h2>  <p
        style={{
          fontSize: "clamp(16px, 4vw, 18px)",
          marginBottom: "clamp(24px, 6vw, 40px)",
          opacity: "0.95",
          maxWidth: "800px",
          margin: "0 auto clamp(24px, 6vw, 40px)",
          lineHeight: "1.6",
        }}
      >
        Inspired by FRC rule G201, we're pioneering sustainable robotics practices.
        Our mission: cultivate environmental consciousness while maintaining
        championship performance.
      </p>
      <div
        style={{
          display: "inline-flex",
          alignItems: "center",
          gap: "clamp(12px, 3vw, 16px)",
          background: "rgba(255, 255, 255, 0.2)",
          padding: "clamp(16px, 4vw, 20px) clamp(24px, 6vw, 32px)",
          borderRadius: "clamp(12px, 3vw, 16px)",
          backdropFilter: "blur(10px)",
          border: "1px solid rgba(255, 255, 255, 0.3)",
          cursor: "pointer",
          transition: "all 0.3s ease",
        }}
        onClick={() =>
          window.open("https://feds201.github.io/G201-Calculator/", "_blank")
        }
      >
        <span style={{ fontSize: '20px' }}>📈</span>
        <span style={{ fontWeight: "600", fontSize: "clamp(16px, 4vw, 18px)" }}>
          Launch G201 Impact Calculator
        </span>
      </div>
    </div>
  );
};
