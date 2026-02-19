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

export const SubgroupsGrid = () => {
  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(min(350px, 100%), 1fr))',
      gap: 'clamp(16px, 4vw, 32px)',
      margin: 'clamp(30px, 8vw, 60px) 0',
      padding: '0 clamp(16px, 4vw, 0px)'
    }}>
     <GenericCard
      icon="💻"
      title="Programming"
      description="Explore two powerful wings of the Programming team: FRC  and Software. Learn how we build, organize, and maintain our robot’s codebase using Java and WPILib, while also diving into web technologies that power our custom scouting platform. Master programming languages and tools that make data-driven robotics possible."
      href="/Home/Programming"
      gradient="linear-gradient(135deg, #667eea 0%,#764ba2 100%)"
      customStyles={{ backgroundColor: 'rgba(54, 98, 180, 0.26)', color: 'white', boxShadow: '0 4px 8px rgba(255, 255, 255, 0.1)' }}
    />

    <GenericCard
      icon="🔌"
      title="Electrical Systems"
      description="Understand how power flows through the robot. Dive into wiring best practices, sensor integration, power management, and safety standards. This section teaches how to bring a robot to life—reliably and safely—through clean, efficient electrical work."
      href="/Home/Electrical"
      gradient="linear-gradient(135deg, #f59e0b 0%, #d97706 100%)"
      customStyles={{
        backgroundColor: "rgba(54, 98, 180, 0.26)",
        color: "white",
        boxShadow: "0 4px 8px rgba(255, 255, 255, 0.1)",
      }}
    />

    <GenericCard
      icon="🧊"
      title="CAD & Design"
      description="Get started with Onshape and explore everything a CAD designer needs to succeed—from 3D modeling and mechanical layout to design reviews and manufacturing drawings. Learn the skills to translate imagination into engineered reality."
      href="/Home/CAD/Introduction"
      gradient="linear-gradient(135deg, #10b981 0%, #059669 100%)"
      customStyles={{
        backgroundColor: "rgba(54, 98, 180, 0.26)",
        color: "white",
        boxShadow: "0 4px 8px rgba(255, 255, 255, 0.1)",
      }}
    />

    <GenericCard
      icon="⚙️"
      title="Mechanical Engineering"
      description="Welcome to the Mechanical Subgroup of FEDS201! This section includes design resources, tool guides, project logs, and lessons learned. From alignment issues to tool wear, dive deep into real-world mechanical problem-solving and documentation of past builds and assemblies."
      href="/Home/Mechanical/Index"
      gradient="linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)"
      customStyles={{
        backgroundColor: "rgba(54, 98, 180, 0.26)",
        color: "white",
        boxShadow: "0 4px 8px rgba(255, 255, 255, 0.1)",
      }}
    />

    <GenericCard
      icon="💡"
      title="Strategy & Scouting"
      description="Explore the evolution of FEDS201’s scouting systems—from the Paper Era to our advanced digital platforms. Learn how we collect data, analyze performance, and build match-winning strategies. Includes historical archives, technical documents, and our custom scouting tools."
      href="/Home/Strategy/Tools&Setup"
      gradient="linear-gradient(135deg, #06b6d4 0%, #0891b2 100%)"
      customStyles={{
        backgroundColor: "rgba(54, 98, 180, 0.26)",
        color: "white",
        boxShadow: "0 4px 8px rgba(255, 255, 255, 0.1)",
      }}
    />

    <GenericCard
      icon="🛡️"
      title="People & Culture"
      description="Discover the heartbeat of FEDS201: Safety, Outreach, Business, Advocacy, Fundraising, and Team Culture. This section houses resources that empower leadership, promote STEM initiatives, and shape a strong, inclusive team identity."
      href="/Home/PandC/Index"
      gradient="linear-gradient(135deg, #ef4444 0%, #dc2626 100%)"
      customStyles={{
        backgroundColor: "rgba(54, 98, 180, 0.26)",
        color: "white",
        boxShadow: "0 4px 8px rgba(255, 255, 255, 0.1)",
      }}
    />
    </div>
  );
};
