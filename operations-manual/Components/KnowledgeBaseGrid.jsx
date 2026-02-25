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

export const KnowledgeBaseGrid = () => {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(min(350px, 100%), 1fr))",
        gap: "clamp(16px, 4vw, 32px)",
        margin: "clamp(30px, 8vw, 60px) 0",
        padding: "0 clamp(16px, 4vw, 0px)",
      }}
    >
      <GenericCard
        title="FEDS Handbook"
        description="The complete guide to everything you need to know as a FEDS member. Team structure, culture, tools, and resources for success."
        href="/FEDSHandbook"
        gradient="linear-gradient(135deg, #06b6d4 0%, #0891b2 100%)"
        icon="👥"
        customStyles={{
          backgroundColor: "rgba(54, 98, 180, 0.26)",
          color: "white",
          boxShadow: "0 4px 8px rgba(255, 255, 255, 0.1)",
        }}
      />
    </div>
  );
};
