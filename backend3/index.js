const express = require('express');
const app = express();
const PORT = 3011;

app.use(express.json());

app.get('/health', (req, res) => res.json({ ok: true, backend: 'backend3' }));

app.post('/api/generate/nsfw', (req, res) => {
  const { prompt, isSpicy } = req.body || {};
  res.json({ success: true, backend: 'backend3', prompt, isSpicy });
});

app.listen(PORT, '127.0.0.1', (err) => {
  if (err) { console.error('Start fehlgeschlagen:', err.message); process.exit(1); }
  console.log(`backend3 läuft auf 127.0.0.1:${PORT}`);
});
