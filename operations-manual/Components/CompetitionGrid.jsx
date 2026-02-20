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

export const CompetitionGrid = () => {
  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(min(300px, 100%), 1fr))',
      gap: 'clamp(16px, 4vw, 32px)',
      margin: 'clamp(30px, 8vw, 60px) 0',
      padding: '0 clamp(16px, 4vw, 0px)'
    }}>
      <GenericCard
        icon="🏆"
        bgPattern="waves"
        title="2025 Season Journey"
        description="Follow our weekly progression through the 2025 season. Detailed insights into our design process, challenges overcome, and lessons learned."
        href="/Home/Experiences/2025"
        gradient="linear-gradient(135deg, #f59e0b 0%, #d97706 100%)"
        customStyles={{backgroundColor: "rgba(123, 54, 180, 0.13)", color: 'white', boxShadow: '0 -10px 20px rgba(255, 255, 255, 0.3)' }}

    />

      <GenericCard
        icon="🤖"
        bgPattern="waves"
        title="Robot Safety System"
        description="Comprehensive safety protocols and systems that ensure safe robot operation in all environments. Industry-leading safety standards."
        href="/Home/Experiences/RSS"
        gradient="linear-gradient(135deg, #ef4444 0%, #dc2626 100%)"
        customStyles={{backgroundColor: "rgba(123, 54, 180, 0.13)", color: 'white', boxShadow: '0 -10px 20px rgba(255, 255, 255, 0.3)' }}

    />

      <GenericCard
        icon="⚙️"
        bgPattern="waves"
        title="Advanced Robot Design"
        description="Deep dive into our robot design methodology, from concept to championship performance. Engineering excellence in every component."
        href="/Experiences/Robot_Design/robotDesign"
        gradient="linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)"
        customStyles={{backgroundColor: "rgba(123, 54, 180, 0.13)", color: 'white', boxShadow: '0 -10px 20px rgba(255, 255, 255, 0.3)' }}

    />
    </div>
  );
};
