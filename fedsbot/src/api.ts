import express, { Request, Response } from 'express';
import crypto from 'crypto';
import { execSync, spawn } from 'child_process';
import { streamAgentSession, streamResumeAgentSession } from './agent.js';

export function createServer(port: number, webhookSecret: string, apiKey: string) {
  const app = express();

  // GitHub webhook — raw body for HMAC verification
  app.post(
    '/webhook/github',
    express.raw({ type: 'application/json' }),
    (req: Request, res: Response) => {
      const signature = req.headers['x-hub-signature-256'] as string;
      if (!signature) {
        res.status(401).json({ error: 'Missing signature' });
        return;
      }

      const body = req.body as Buffer;
      const expected =
        'sha256=' +
        crypto.createHmac('sha256', webhookSecret).update(body).digest('hex');

      if (
        signature.length !== expected.length ||
        !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))
      ) {
        res.status(401).json({ error: 'Invalid signature' });
        return;
      }

      const payload = JSON.parse(body.toString());

      if (payload.ref !== 'refs/heads/main') {
        res.json({ status: 'ignored', reason: 'not main branch' });
        return;
      }

      console.log('Received push to main, updating...');

      try {
        const oldHead = execSync('git rev-parse HEAD').toString().trim();
        execSync('git fetch origin main');
        execSync('git reset --hard');
        execSync('git clean -fd');
        execSync('git checkout main');
        execSync('git reset --hard origin/main');
        const newHead = execSync('git rev-parse HEAD').toString().trim();

        if (oldHead !== newHead) {
          const changedFiles = execSync(
            `git diff --name-only ${oldHead} ${newHead} -- fedsbot/`
          ).toString().trim();

          if (changedFiles) {
            console.log('Fedsbot files changed, reinstalling and restarting...');
            execSync('npm install', { cwd: 'fedsbot' });
            // Restart in background — this process will be killed by the restart
            spawn('sh', ['-c', 'sleep 1 && rc-service fedsbot restart'], {
              detached: true,
              stdio: 'ignore',
            }).unref();
          }
        }

        res.json({ status: 'updated', oldHead, newHead });
      } catch (err) {
        console.error('Webhook update failed:', err);
        res.status(500).json({ error: 'Update failed' });
      }
    }
  );

  // JSON body parser for API routes
  app.use('/api', express.json());

  // SSE chat endpoint
  app.post('/api/chat', async (req: Request, res: Response) => {
    console.log('[chat] Request received');

    if (req.headers['x-api-key'] !== apiKey) {
      console.log('[chat] Auth failed');
      res.status(401).json({ error: 'Invalid API key' });
      return;
    }

    const { message, sessionId } = req.body ?? {};
    if (!message || typeof message !== 'string') {
      console.log('[chat] Missing message');
      res.status(400).json({ error: 'Missing message' });
      return;
    }

    console.log(`[chat] message="${message.slice(0, 80)}" sessionId=${sessionId ?? 'new'}`);

    // SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    try {
      console.log('[chat] Creating agent session...');
      const stream = sessionId
        ? streamResumeAgentSession(sessionId, message)
        : streamAgentSession(message);

      for await (const event of stream) {
        console.log(`[chat] Event: ${event.type}${event.type === 'delta' ? '' : ' ' + JSON.stringify(event).slice(0, 200)}`);
        res.write(`event: ${event.type}\ndata: ${JSON.stringify(event)}\n\n`);
      }
      console.log('[chat] Stream complete');
    } catch (err: any) {
      console.error('[chat] Error:', err);
      res.write(`event: error\ndata: ${JSON.stringify({ type: 'error', message: err.message ?? 'Unknown error' })}\n\n`);
    }

    res.end();
  });

  const server = app.listen(port, () => {
    console.log(`Express server listening on port ${port}`);
  });

  return server;
}
