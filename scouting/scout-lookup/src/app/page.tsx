import Link from 'next/link';
import { Search, List } from 'lucide-react';

export default function Home() {
  return (
    <div className="flex flex-col items-center justify-center my-8 gap-8" style={{ minHeight: '60vh', textAlign: 'center' }}>
      <div>
        <h1 style={{ fontSize: '4rem', color: 'var(--primary)', marginBottom: '1rem' }}>Scout Ops LookUp</h1>
        <p style={{ fontSize: '1.25rem', color: 'var(--foreground-muted)', maxWidth: '600px', margin: '0 auto' }}>
          Explore FRC team profiles, view pit scouting data, analyze match performance, and dig into external statistics from The Blue Alliance and Statbotics.
        </p>
      </div>

      <div className="flex gap-4">
        <Link href="/teams">
          <button className="flex items-center gap-2" style={{ fontSize: '1.25rem', padding: '1rem 2rem' }}>
            <Search size={24} /> Find a Team
          </button>
        </Link>
      </div>

      <div className="card mt-8" style={{ maxWidth: '600px', textAlign: 'left' }}>
        <h3 className="flex items-center gap-2 mb-2"><List size={20} color="var(--primary)" /> Getting Started</h3>
        <p style={{ color: 'var(--foreground-muted)' }}>
          To start using Scout Ops LookUp, head over to the <strong>Settings</strong> page to configure your Neon database connection string and specify your match/pit scouting table names.
        </p>
        <Link href="/settings">
          <button className="secondary mt-4">Go to Settings</button>
        </Link>
      </div>
    </div>
  );
}