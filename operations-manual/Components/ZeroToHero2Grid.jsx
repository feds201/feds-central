'use client';
import React from 'react';
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

export const ZeroToHero2Grid = () => (
    <GenericGrid layout="responsive" columns={{ xs: 1, sm: 2 }} gap="16px" items={[
        { title: "The Architecture", icon: "🏛️", description: "Why we split code into different files instead of one giant file of doom." },
        { title: "RobotContainer", icon: "📦", description: "The brain of the operation: where buttons meet actions." },
        { title: "The Command Lifecycle", icon: "♻️", description: "Init -> Execute -> End. The circle of life for code." },
        { title: "Triggers & Bindings", icon: "🎮", description: "Making controller buttons actually do stuff." }
    ]}
    renderItem={(item) => <ModernCard {...item} variant="elevated" size="sm" />}
    />
);
