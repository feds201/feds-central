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

export const ZTH1Grid1 = () => (
  <GenericGrid
    layout="responsive"
    columns={{ xs: 1, sm: 2, md: 3 }}
    gap="16px"
    items={[
      {
        title: "WPILib Fundamentals",
        icon: "📚",
        description: "Understand what WPILib is and why it's crucial for FRC"
      },
      {
        title: "Project Creation",
        icon: "⚙️",
        description: "Learn how to create your first robot project"
      },
      {
        title: "Naming Conventions",
        icon: "🔤",
        description: "Master the ancient art of not calling everything 'thing1'"
      },
      {
        title: "Motor Control",
        icon: "🌀",
        description: "Make motors spin without accidentally launching your robot into orbit"
      },
      {
        title: "Controller Input",
        icon: "🎮",
        description: "Turn button mashing into precision engineering"
      },
      {
        title: "Team Programming",
        icon: "🧠",
        description: "Write code so good your teammates will think you're a wizard"
      }
    ]}
    renderItem={(item) => (
      <ModernCard
        variant="elevated"
        size="sm"
        interactive={true}
        icon={item.icon}
        title={item.title}
        description={item.description}
      />
    )}
  />
);

export const ZTH1Grid2 = () => (
  <GenericGrid
    layout="responsive"
    columns={{ xs: 1, sm: 3 }}
    gap="20px"
    items={[
      {
        title: "WPILib VS Code",
        icon: "🔧",
        description: "The chosen IDE of robot overlords everywhere",
        href: "https://github.com/wpilibsuite/allwpilib/releases"
      },
      {
        title: "Java Development Kit",
        icon: "☕",
        description: "Essential coffee-powered runtime for your code",
        href: "https://www.oracle.com/java/technologies/javase-jdk11-downloads.html"
      },
      {
        title: "Git Client",
        icon: "📝",
        description: "For when you inevitably break everything and need to time travel",
        href: "https://www.git-scm.com/download/win"
      }
    ]}
    renderItem={(item) => (
      <ModernCard
        variant="elevated"
        size="md"
        interactive={true}
        icon={item.icon}
        title={item.title}
        description={item.description}
        href={item.href}
      />
    )}
  />
);

export const ZTH1Grid3 = () => (
<GenericGrid
  layout="responsive"
  columns={{ xs: 1, sm: 2, md: 4 }}
  gap="20px"
  items={[
    {
      title: "camelCase",
      subtitle: "Variables & Methods",
      description: "Used for: variables, method names, field names → leftMotor, getSpeed(), isArmAtTarget() (like a camel, but for code!)",
      icon: "🐪"
    },
    {
      title: "PascalCase",
      subtitle: "Classes & Interfaces",
      description: "Used for: class names, interface names → DriveBase, ArmSubsystem, ShooterCommand (fancy like Pascal!)",
      icon: "📦"
    },
    {
      title: "UPPER_CASE",
      subtitle: "Constants & Enums",
      description: "Used for: final static variables, enum values → ARM_MOTOR_ID, MAX_SPEED, DriverStation.Alliance.RED",
      icon: "📢"
    },
    {
      title: "descriptive_names",
      subtitle: "Universal Rule",
      description: "Used EVERYWHERE: No more 'x', 'temp', or 'thing1' - make it obvious what it does! Your 3 AM self will thank you!",
      icon: "🏆"
    }
  ]}
  renderItem={(item) => (
    <ModernCard
      variant="elevated"
      size="md"
      interactive={true}
      icon={item.icon}
      title={item.title}
      subtitle={item.subtitle}
      description={item.description}
    />
  )}
/>
);

export const ZTH1Grid4 = () => (
<GenericGrid
  layout="responsive"
  columns={{ xs: 1, sm: 2, md: 3 }}
  gap="20px"
  items={[
    {
      title: "Clear Documentation",
      icon: "📝",
      description: "Write comments like your worst enemy will maintain your code (plot twist: it's you in 6 months!)"
    },
    {
      title: "Modular Design",
      icon: "🧩",
      description: "Break big scary problems into tiny, manageable, less-scary problems"
    },
    {
      title: "Safety First",
      icon: "🛡️",
      description: "Always include safety checks - nobody wants to explain why the robot launched itself"
    },
    {
      title: "Consistent Patterns",
      icon: "🔄",
      description: "Use patterns so predictable that even your robot could write them"
    },
    {
      title: "Team Reviews",
      icon: "👥",
      description: "Regular 'constructive criticism' sessions (aka friendly code roasting)"
    },
    {
      title: "Learning Culture",
      icon: "🎯",
      description: "Where 'I don't know' is the start of an adventure, not an embarrassment"
    }
  ]}
  renderItem={(item) => (
    <ModernCard
      variant="elevated"
      size="md"
      interactive={true}
      icon={item.icon}
      title={item.title}
      description={item.description}
    />
  )}
/>
);

export const ZTH1Grid5 = () => (
<GenericGrid
  layout="responsive"
  columns={{ xs: 1, sm: 2, md: 3 }}
  gap="16px"
  items={[
    {
      title: "What WPILib is",
      description: "And why it's your new best friend in robot programming",
      icon: "🤝"
    },
    {
      title: "How to create",
      description: "A robot project without breaking anything (probably)",
      icon: "🏗️"
    },
    {
      title: "Naming conventions",
      description: "For code that doesn't make people cry",
      icon: "😊"
    },
    {
      title: "Basic motor control",
      description: "Making things spin since 2024!",
      icon: "🌪️"
    },
    {
      title: "Controller integration",
      description: "Turning button mashing into precision control",
      icon: "🎯"
    },
    {
      title: "Team programming",
      description: "How to code with others without starting a war",
      icon: "☮️"
    }
  ]}
  renderItem={(item) => (
    <ModernCard
      variant="modern"
      size="sm"
      interactive={false}
      icon={item.icon}
      title={item.title}
      description={item.description}
    />
  )}
/>
);

export const ZTH1Grid6 = () => (
  <GenericGrid
    layout="responsive"
    columns={{ xs: 1, sm: 2 }}
    gap="20px"
    items={[
      {
        title: "Subsystem Architecture",
        description: "Deep dive into the Command-Based framework (spoiler: it's actually pretty cool!)",
        icon: "🏗️"
      },
      {
        title: "Sensor Integration",
        description: "Reading encoders, gyroscopes, and limit switches (give your robot superpowers!)",
        icon: "🦸‍♂️"
      },
      {
        title: "Autonomous Commands",
        description: "Teaching your robot to think for itself (what could go wrong?)",
        icon: "🤖"
      },
      {
        title: "Advanced Motor Control",
        description: "PID, Motion Magic, and velocity control (the fancy stuff!)",
        icon: "✨"
      }
    ]}
    renderItem={(item) => (
      <ModernCard
        variant="elevated"
        size="md"
        interactive={true}
        icon={item.icon}
        title={item.title}
        description={item.description}
      />
    )}
  />
);
