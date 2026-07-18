// Demonic Pic Gen - Backend
//
// Nimmt Bildanfragen der iOS App entgegen, validiert und begrenzt sie,
// und leitet sie an die kostenlose Pollinations Image API weiter.

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const fetch = require('node-fetch');

const PORT = process.env.PORT || 3005;
const API_KEY = process.env.API_KEY || '';
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
const RATE_LIMIT_WINDOW_MS = Number(process.env.RATE_LIMIT_WINDOW_MS) || 60_000;
const RATE_LIMIT_MAX_REQUESTS = Number(process.env.RATE_LIMIT_MAX_REQUESTS) || 20;

const MIN_DIMENSION = 256;
const MAX_DIMENSION = 1536;
const MAX_PROMPT_LENGTH = 800;
const ALLOWED_MODELS = new Set(['flux', 'turbo', 'flux-realism', 'flux-anime', 'flux-3d']);

const app = express();

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
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.post('/api/generate', requireApiKey, async (req, res) => {
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
  const safeModel = ALLOWED_MODELS.has(model) ? model : 'flux';

  const pollinationsURL =
    `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}` +
    `?width=${safeWidth}&height=${safeHeight}&seed=${safeSeed}&model=${safeModel}` +
    `&nologo=true&safe=true`;

  try {
    const upstreamResponse = await fetch(pollinationsURL, {
      signal: AbortSignal.timeout(90_000),
    });

    if (!upstreamResponse.ok) {
      return res.status(502).json({ error: `Pollinations lieferte Status ${upstreamResponse.status}.` });
    }

    const contentType = upstreamResponse.headers.get('content-type') || 'image/jpeg';
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'no-store');

    const buffer = await upstreamResponse.buffer();
    res.status(200).send(buffer);
  } catch (error) {
    const isTimeout = error.name === 'TimeoutError' || error.name === 'AbortError';
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
  console.log(`Demonic Pic Gen Backend läuft auf Port ${PORT}`);
});
