# Demonic Pic Gen Backend 2 – Cloudflare Workers AI

Zweites, alternatives Backend zu `backend/`. Funktioniert genau wie das
Node-Backend, das an Pollinations weiterleitet – nur dass hier die
Bildgenerierung über die [Cloudflare Workers AI](https://developers.cloudflare.com/workers-ai/)
REST-API läuft. Beide Backends sprechen dasselbe API-Format
(`POST /api/generate`, `GET /api/health`), die iOS App unterscheidet sie
nicht und kann in den Einstellungen zwischen ihnen umschalten.

```
iOS App → dein Node-Backend (dieser Ordner) → Cloudflare Workers AI API
```

Läuft am einfachsten direkt neben `backend/` auf demselben Debian-Rootserver
(anderer Port, eigener PM2-Prozess, eigene Nginx-Subdomain).

## Voraussetzungen

- Denselben Debian 12 Rootserver wie für `backend/` (Node.js, PM2, Nginx,
  Firewall sind dort laut `backend/DEPLOYMENT.md` bereits eingerichtet)
- Ein kostenloser [Cloudflare-Account](https://dash.cloudflare.com/sign-up)
- Eine zweite (Sub-)Domain, z.B. `api2.deinedomain.de`, die auf dieselbe
  Server-IP zeigt

## 1. Cloudflare Account-ID besorgen

Im [Cloudflare-Dashboard](https://dash.cloudflare.com/) → beliebige Domain
oder "Workers & Pages" öffnen → die **Account ID** steht rechts in der
Seitenleiste. Notieren.

## 2. API-Token mit Workers-AI-Rechten erstellen

1. [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
2. "Create Token" → "Custom Token"
3. Berechtigung hinzufügen: **Account → Workers AI → Read** (bzw. "Edit",
   falls verfügbar – für reine Bildgenerierung reicht Read)
4. Token erstellen und den Wert sicher kopieren (wird nur einmal angezeigt)

## 3. Code auf den Server bringen

Als Nutzer `demonic` (derselbe wie für `backend/`):

```bash
su - demonic
cd DemonicImageGenIOS
git pull
cd backend2
npm install --production
```

## 4. Konfiguration anlegen

```bash
cp .env.example .env
nano .env
```

Wichtige Werte:

- `PORT` – Standard `3006` (unterscheidet sich absichtlich von `backend/`s `3005`)
- `CF_ACCOUNT_ID` – aus Schritt 1
- `CF_API_TOKEN` – aus Schritt 2
- `API_KEY` – eigenes Geheimnis für die App↔Backend-Verbindung (z.B. mit
  `openssl rand -hex 32` erzeugt), unabhängig vom Cloudflare-Token. Trage
  denselben Wert später in der App unter Einstellungen → Cloudflare Workers AI
  → API-Key ein.

## 5. Mit PM2 dauerhaft laufen lassen

(PM2 ist bereits systemweit installiert, siehe `backend/DEPLOYMENT.md`.)

```bash
pm2 start ecosystem.config.js
pm2 save
```

```bash
pm2 status
pm2 logs demonic-pic-gen-backend2
```

## 6. Nginx als Reverse Proxy (neue Subdomain)

```bash
sudo -n true 2>/dev/null || exit  # als root ausfuehren
nano /etc/nginx/sites-available/demonic-pic-gen-backend2
```

Inhalt:

```nginx
server {
    listen 80;
    server_name api2.deinedomain.de;

    client_max_body_size 5m;

    location / {
        proxy_pass http://127.0.0.1:3006;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
```

Aktivieren:

```bash
ln -s /etc/nginx/sites-available/demonic-pic-gen-backend2 /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
certbot --nginx -d api2.deinedomain.de
```

## 7. Testen

```bash
curl https://api2.deinedomain.de/api/health
# -> {"status":"ok","uptime":123.45}

curl -X POST https://api2.deinedomain.de/api/generate \
  -H "Content-Type: application/json" \
  -H "X-API-Key: DEIN_API_KEY" \
  -d '{"prompt":"a demon king on a throne of bones","width":1024,"height":1024}' \
  --output test.png
file test.png
```

Falls `status` `"misconfigured"` zeigt, fehlt `CF_ACCOUNT_ID` oder
`CF_API_TOKEN` in der `.env`.

## 8. iOS App konfigurieren

In der App unter **Einstellungen**:

1. Bei "Aktives Backend" **Cloudflare Workers AI** auswählen
2. **Backend-URL**: `https://api2.deinedomain.de`
3. **API-Key**: der `API_KEY`-Wert aus Schritt 4

Node-Backend (`backend/`) und dieses zweite Backend bleiben beide
gespeichert – die Auswahl "Aktives Backend" entscheidet, welches gerade für
die Bildgenerierung benutzt wird.

## 9. Updates einspielen

```bash
su - demonic
cd DemonicImageGenIOS
git pull
cd backend2
npm install --production
pm2 restart demonic-pic-gen-backend2
```

## Verfügbare Modelle

Der Server bildet die von der App gesendete `model`-Kurzform auf echte
Workers-AI-Modelle ab (in `server.js`, `MODEL_MAP`):

| Kurzname               | Workers-AI-Modell                              |
| ----------------------- | ------------------------------------------------ |
| `flux` (Standard)       | `@cf/black-forest-labs/flux-1-schnell`           |
| `stable-diffusion-xl`   | `@cf/stabilityai/stable-diffusion-xl-base-1.0`   |
| `lightning`             | `@cf/bytedance/stable-diffusion-xl-lightning`    |
| `dreamshaper`           | `@cf/lykon/dreamshaper-8-lcm`                    |

Weitere Modelle: [Workers AI Model Catalog](https://developers.cloudflare.com/workers-ai/models/).

## Sicherheitshinweise

- `CF_API_TOKEN` niemals in die App oder ins Repo einbauen – er bleibt
  ausschließlich in der Server-`.env`. Genau deshalb existiert dieses
  Backend als Vermittler statt die App direkt mit Cloudflare sprechen zu lassen.
- Setze unbedingt einen eigenen `API_KEY`, sonst kann jeder über deine
  Server-URL auf Kosten deines Cloudflare-Kontingents Bilder generieren.
- Workers AI ist im kostenlosen Cloudflare-Plan mit einem täglichen
  Freikontingent nutzbar, darüber hinaus wird nach Nutzung abgerechnet
  (siehe [Preise](https://developers.cloudflare.com/workers-ai/platform/pricing/)).
  Das Rate-Limiting in diesem Backend hilft, unerwartete Kosten zu vermeiden.
