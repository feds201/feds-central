import { NextResponse } from 'next/server';
import { query, getConfig } from '@/lib/db';

export async function GET(
  request: Request,
  context: { params: Promise<{ team: string }> }
) {
  const params = await context.params;
  const team = params.team;
  try {
    const config = await getConfig();

    let matchData: any[] = [];
    let pitData = null;

    if (config.matchTable) {
      try {
        const res = await query(`SELECT * FROM ${config.matchTable} WHERE team = $1 OR "teamNumber" = $1`, [team]);
        matchData = res.rows;
      } catch (e) {
        console.warn('Match data fetch error', e);
      }
    }

    if (config.pitTable) {
      try {
        const res = await query(`SELECT * FROM ${config.pitTable} WHERE team = $1 OR "teamNumber" = $1 LIMIT 1`, [team]);
        pitData = res.rows[0] || null;
      } catch (e) {
        console.warn('Pit data fetch error', e);
      }
    }

    // Also fetch basic TBA and Statbotics here if possible, but easier to do it on the client so we don't block.
    // We'll return the DB data here.
    return NextResponse.json({
      team,
      pitData,
      matchData
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}