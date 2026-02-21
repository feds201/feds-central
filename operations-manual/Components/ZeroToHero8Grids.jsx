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

export const ZTH8Grid1 = () => (
    <GenericGrid layout="responsive" columns={{ xs: 1, md: 3 }} gap="16px" items={[
        {
            title: "Step 1",
            description: "Open your log file (or connect to Sim) in AdvantageScope."
        },
        {
            title: "Step 2",
            description: "Drag the 'IntakeMechanism' field from the sidebar into the main window."
        },
        {
            title: "Step 3",
            description: "Select 'Mechanism 2D' from the popup menu. Watch it move!"
        }
    ]}
    renderItem={(item) => <ModernCard {...item} variant="glass" />}
    />
);

export const ZTH8Grid2 = () => (
    <GenericGrid layout="responsive" columns={{ xs: 1, sm: 2 }} gap="16px" items={[
        { title: "3D Field", icon: "🏟️", description: "Replay the match in 3D. Visualize robot pose, vision targets, and game pieces." },
        { title: "Line Graph", icon: "📉", description: "Drag distinct fields (PID errors, velocity, voltage) to compare them over time." },
        { title: "Mechanism 2D", icon: "⚙️", description: "Visualize the 'stick figure' robot we built in Chapter 4." },
        { title: "Console", icon: "💬", description: "Review standard output and error logs synchronized with the match timeline." },
        { title: "Swerve Visualizer", icon: "🦀", description: "See individual module vectors to debug drive issues." },
        { title: "Live & Offline", icon: "🛜", description: "Connect live to the robot for tuning, or load a log file for post-match analysis." }
    ]}
    renderItem={(item) => <ModernCard {...item} variant="elevated" size="sm" />}
    />
);
