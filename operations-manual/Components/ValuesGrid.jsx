'use client';
import React from 'react';
import { GenericGrid } from './Library/Layout/GenericGrid';
import { GenericWidget } from './Library/Core/GenericWidget';

export const ValuesGrid = () => (
  <GenericGrid
    layout="masonry"
    columns={{ xs: 1, sm: 2, md: 3 }}
    gap="24px"
    animation={{ enabled: true, stagger: 100 }}
    items={[
      {
        title: 'Innovation',
        description: 'Pushing the boundaries of what\'s possible in competitive robotics.',
        icon: '💡'
      },
      {
        title: 'Excellence',
        description: 'Maintaining the highest standards in everything we do.',
        icon: '🏆'
      },
      {
        title: 'Collaboration',
        description: 'Working together to achieve extraordinary results.',
        icon: '🤝'
      },
      {
        title: 'Learning',
        description: 'Continuously growing through hands-on experience.',
        icon: '📚'
      },
      {
        title: 'Impact',
        description: 'Making a positive difference in our community.',
        icon: '🌟'
      },
      {
        title: 'Sustainability',
        description: 'Building responsibly for future generations.',
        icon: '🌱'
      }
    ]}
    renderItem={({ title, description, icon }) => (
      <GenericWidget
        title={title}
        subtitle={description}
        icon={icon}
        variant="glass"
        size="md"
        interactive={false}
      />
    )}
  />
);
