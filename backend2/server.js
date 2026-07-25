// Demonic Pic Gen - Backend 2 (Cloudflare Workers AI)
//
// Zweites, alternatives Backend zu backend/. Nimmt Bildanfragen der iOS App
// entgegen, validiert und begrenzt sie, und leitet sie an die Cloudflare
// Workers AI REST-API weiter: https://developers.cloudflare.com/workers-ai/

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const fetch = require('node-fetch');

const PORT = process.env.PORT || 3006;
const API_KEY = process.env.API_KEY || '';
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
const RATE_LIMIT_WINDOW_MS = Number(process.env.RATE_LIMIT_WINDOW_MS) || 60_000;
const RATE_LIMIT_MAX_REQUESTS = Number(process.env.RATE_LIMIT_MAX_REQUESTS) || 20;
const CF_ACCOUNT_ID = process.env.CF_ACCOUNT_ID || '';
const CF_API_TOKEN = process.env.CF_API_TOKEN || '';

const MIN_DIMENSION = 256;
const MAX_DIMENSION = 1536;
const MAX_PROMPT_LENGTH = 800;

// Kurznamen (wie sie die App verschickt) -> tatsaechliche Workers AI Modelle.
const MODEL_MAP = {
  flux: '@cf/black-forest-labs/flux-1-schnell',
  'stable-diffusion-xl': '@cf/stabilityai/stable-diffusion-xl-base-1.0',
  lightning: '@cf/bytedance/stable-diffusion-xl-lightning',
  dreamshaper: '@cf/lykon/dreamshaper-8-lcm',
};
const DEFAULT_MODEL_KEY = 'flux';

const app = express();

// Hinter Nginx: dem ersten Hop vertrauen, damit req.ip und der
// X-Forwarded-For-Header korrekt fuer express-rate-limit ausgewertet werden.
app.set('trust proxy', 1);

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: CORS_ORIGIN }));
app.use(express.json({ limit: '10kb' }));
app.use(morgan('combined'));

app.use(
  rateLimit({
    windowMs: RATE_LIMIT_WINDOW_MS,
    max: RATE_LIMIT_MAX_REQUESTS,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Zu viele Anfragen. Bitte warte kurz und versuche es erneut.' },
  })
);

function requireApiKey(req, res, next) {
  if (!API_KEY) return next();
  const providedKey = req.header('X-API-Key');
  if (providedKey !== API_KEY) {
    return res.status(401).json({ error: 'Ungueltiger oder fehlender API-Key.' });
  }
  next();
}

function clampDimension(value, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.min(MAX_DIMENSION, Math.max(MIN_DIMENSION, Math.round(number)));
}

app.get('/api/health', (req, res) => {
  const configured = Boolean(CF_ACCOUNT_ID && CF_API_TOKEN);
  res.json({ status: configured ? 'ok' : 'misconfigured', uptime: process.uptime() });
});

app.post('/api/generate', requireApiKey, async (req, res) => {
  if (!CF_ACCOUNT_ID || !CF_API_TOKEN) {
    return res.status(500).json({ error: 'Backend ist nicht konfiguriert (CF_ACCOUNT_ID / CF_API_TOKEN fehlen).' });
  }

  const { prompt, width, height, seed, model } = req.body || {};

  if (typeof prompt !== 'string' || prompt.trim().length === 0) {
    return res.status(400).json({ error: 'Prompt darf nicht leer sein.' });
  }
  if (prompt.length > MAX_PROMPT_LENGTH) {
    return res.status(400).json({ error: `Prompt ist zu lang (max. ${MAX_PROMPT_LENGTH} Zeichen).` });
  }

  const safeWidth = clampDimension(width, 1024);
  const safeHeight = clampDimension(height, 1024);
  const safeSeed = Number.isFinite(Number(seed)) ? Math.floor(Number(seed)) : Math.floor(Math.random() * 2 ** 31);
  const modelKey = MODEL_MAP[model] ? model : DEFAULT_MODEL_KEY;
  const modelId = MODEL_MAP[modelKey];

  const cfURL = `https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/ai/run/${modelId}`;

  try {
    const cfResponse = await fetch(cfURL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${CF_API_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        prompt,
        width: safeWidth,
        height: safeHeight,
        seed: safeSeed,
      }),
      signal: AbortSignal.timeout(90_000),
    });

    if (!cfResponse.ok) {
      const bodyText = await cfResponse.text().catch(() => '');
      console.error(
        `[Workers AI] Status ${cfResponse.status} fuer Modell ${modelId}\nBody: ${bodyText.slice(0, 500)}`
      );
      return res.status(502).json({ error: `Cloudflare Workers AI lieferte Status ${cfResponse.status}.` });
    }

    const contentType = cfResponse.headers.get('content-type') || '';

    // Manche Modelle (z.B. Stable Diffusion XL) liefern die Bilddaten direkt
    // binaer, andere (z.B. Flux) als JSON-Umschlag mit Base64-codiertem PNG.
    if (contentType.startsWith('image/')) {
      const buffer = await cfResponse.buffer();
      res.setHeader('Content-Type', contentType);
      res.setHeader('Cache-Control', 'no-store');
      return res.status(200).send(buffer);
    }

    const json = await cfResponse.json();
    if (!json.success || !json.result || typeof json.result.image !== 'string') {
      console.error(`[Workers AI] Unerwartetes Antwortformat:`, JSON.stringify(json).slice(0, 500));
      return res.status(502).json({ error: 'Unerwartetes Antwortformat von Cloudflare Workers AI.' });
    }

    const buffer = Buffer.from(json.result.image, 'base64');
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Cache-Control', 'no-store');
    res.status(200).send(buffer);
  } catch (error) {
    const isTimeout = error.name === 'TimeoutError' || error.name === 'AbortError';
    console.error(`[Workers AI] Fehler fuer Modell ${modelId}:`, error);
    res.status(isTimeout ? 504 : 500).json({
      error: isTimeout
        ? 'Zeitüberschreitung bei der Bildgenerierung. Bitte erneut versuchen.'
        : 'Interner Fehler bei der Bildgenerierung.',
    });
  }
});

app.use((req, res) => {
  res.status(404).json({ error: 'Route nicht gefunden.' });
});

app.listen(PORT, () => {
  console.log(`Demonic Pic Gen Backend 2 (Cloudflare Workers AI) läuft auf Port ${PORT}`);
});
