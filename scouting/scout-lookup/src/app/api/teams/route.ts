import { NextResponse } from 'next/server';
import { query, getConfig } from '@/lib/db';

export async function GET() {
  try {
    const config = await getConfig();
    if (!config.matchTable && !config.pitTable) {
      return NextResponse.json({ error: 'Tables not configured in Settings.' }, { status: 400 });
    }

    const teamSet = new Set<string>();

    if (config.matchTable) {
      try {
        // Try 'team' and 'teamNumber' as common column names
        const res = await query(`
          SELECT team FROM ${config.matchTable}
        `).catch(() => query(`SELECT "teamNumber" as team FROM ${config.matchTable}`));
        
        res.rows.forEach(r => {
          if (r.team) teamSet.add(r.team.toString());
        });
      } catch (e) {
        console.warn('Could not fetch from match table:', e);
      }
    }

    if (config.pitTable) {
      try {
        const res = await query(`
          SELECT team FROM ${config.pitTable}
        `).catch(() => query(`SELECT "teamNumber" as team FROM ${config.pitTable}`));
        
        res.rows.forEach(r => {
          if (r.team) teamSet.add(r.team.toString());
        });
      } catch (e) {
        console.warn('Could not fetch from pit table:', e);
      }
    }

    const teams = Array.from(teamSet).sort((a, b) => parseInt(a) - parseInt(b));
    return NextResponse.json({ teams });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}