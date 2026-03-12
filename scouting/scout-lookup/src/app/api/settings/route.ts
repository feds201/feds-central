import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const configPath = path.join(process.cwd(), 'lookup-config.json');

export async function GET() {
  try {
    if (fs.existsSync(configPath)) {
      const data = fs.readFileSync(configPath, 'utf8');
      const config = JSON.parse(data);
      // Don't send the full connection string to the client for security, just an indicator
      const safeConfig = {
        ...config,
        hasNeonUrl: !!config.neonUrl,
        neonUrl: config.neonUrl ? '••••••••••••••••' : '',
      };
      return NextResponse.json(safeConfig);
    }
    return NextResponse.json({
      hasNeonUrl: false,
      neonUrl: '',
      matchTable: '',
      pitTable: '',
      tbaKey: ''
    });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to read config' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    // If they send the masked string back, we keep the old one
    if (body.neonUrl === '••••••••••••••••') {
      if (fs.existsSync(configPath)) {
        const oldConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        body.neonUrl = oldConfig.neonUrl;
      } else {
        body.neonUrl = '';
      }
    }

    if (body.tbaKey === '••••••••••••••••') {
      if (fs.existsSync(configPath)) {
        const oldConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        body.tbaKey = oldConfig.tbaKey;
      } else {
        body.tbaKey = '';
      }
    }

    fs.writeFileSync(configPath, JSON.stringify(body, null, 2), 'utf8');
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to save config' }, { status: 500 });
  }
}