'use client';
import { GenericGrid } from './Library/Layout/GenericGrid';
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

export const ZeroToHero4Grid = () => (
    <GenericGrid layout="responsive" columns={{ xs: 1, sm: 3 }} gap="16px" items={[
        { title: "Digital Input", icon: "🔘", description: "True/False. Limit Switches, Beam Breaks." },
        { title: "Encoder", icon: "📏", description: "How far/fast? Measures rotation." },
        { title: "Gyroscope (IMU)", icon: "🧭", description: "Rotation/Heading. Which way is North?" }
    ]}
    renderItem={(item) => <ModernCard {...item} variant="elevated" size="sm" />}
    />
);
