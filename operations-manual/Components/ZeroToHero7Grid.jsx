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

export const ZeroToHero7Grid = () => (
    <GenericGrid layout="responsive" columns={{ xs: 1, sm: 2 }} gap="16px" items={[
        { title: "SequentialCommandGroup", icon: "⬇️", description: "The To-Do List. Runs A, then B, then C. (e.g., Drive -> Aim -> Shoot)." },
        { title: "ParallelCommandGroup", icon: "🤝", description: "The Multitasker. Runs A and B at the same time. Ends when ALL are done." },
        { title: "ParallelRaceGroup", icon: "🏁", description: "The Race. Runs A and B. Ends when the FIRST one finishes. (e.g., 'Run Intake' vs '5 Second Timer')." },
        { title: "ParallelDeadlineGroup", icon: "👑", description: "The Leader. Runs A and B. Ends when the LEADER (A) finishes. (e.g., 'Follow Path' while 'Spinning Intake')." }
    ]}
    renderItem={(item) => <ModernCard {...item} variant="elevated" size="sm" />}
    />
);
