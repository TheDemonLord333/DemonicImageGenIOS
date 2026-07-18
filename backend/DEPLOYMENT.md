# Demonic Pic Gen Backend – Setup auf Debian 12

Dieses Backend nimmt Anfragen von der iOS App entgegen, reichert den Prompt an
und leitet ihn an die kostenlose [Pollinations](https://pollinations.ai) Image
API weiter. Es läuft als Node.js/Express-Server hinter einem Nginx-Reverse-Proxy
mit HTTPS.

## Voraussetzungen

- Debian 12 Rootserver mit SSH-Zugang
- Eine Domain (oder Subdomain), die auf die Server-IP zeigt, z.B.
  `api.deinedomain.de` (empfohlen für HTTPS via Let's Encrypt)

## 1. System aktualisieren

```bash
apt update && apt upgrade -y
```

## 2. Node.js installieren

Node 20 LTS über NodeSource:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
node -v   # sollte v20.x zeigen
npm -v
```

## 3. Firewall einrichten (UFW)

```bash
apt install -y ufw
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

## 4. Einen dedizierten Nutzer anlegen (statt als root zu laufen)

```bash
adduser demonic --disabled-password --gecos ""
```

Noch als root PM2 global installieren (globale npm-Pakete landen unter
`/usr/lib/node_modules` und brauchen root-Rechte; der `demonic`-Nutzer würde
hier mit `EACCES` scheitern):

```bash
npm install -g pm2
```

## 5. Code auf den Server bringen

Als Nutzer `demonic`:

```bash
su - demonic
git clone https://github.com/TheDemonLord333/DemonicImageGenIOS.git
cd DemonicImageGenIOS/backend
```

(Alternativ per `scp -r backend/ demonic@dein-server:/home/demonic/backend`.)

## 6. Abhängigkeiten installieren

```bash
npm install --production
```

## 7. Konfiguration anlegen

```bash
cp .env.example .env
nano .env
```

Wichtige Werte:

- `PORT` – intern genutzter Port (Standard `3005`, Nginx leitet später darauf weiter)
- `API_KEY` – setz hier ein zufälliges, langes Geheimnis (z.B. mit
  `openssl rand -hex 32` erzeugt), damit nicht jeder deinen Server als
  kostenlosen Bilder-Proxy missbrauchen kann. Trage denselben Wert später in
  der App unter Einstellungen → API-Key ein.
- `RATE_LIMIT_MAX_REQUESTS` – wie viele Anfragen eine IP pro Minute stellen darf

## 8. Mit PM2 dauerhaft laufen lassen

PM2 hält den Prozess am Leben und startet ihn nach einem Server-Neustart automatisch neu
(als `demonic`-Nutzer, das `pm2`-Kommando selbst wurde bereits in Schritt 4 als root
installiert):

```bash
pm2 start ecosystem.config.js
pm2 save
```

Autostart beim Booten einrichten (den Befehl ausführen, den `pm2 startup`
ausgibt – er muss als root ausgeführt werden):

```bash
pm2 startup
# gibt einen sudo-Befehl aus, z.B.:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u demonic --hp /home/demonic
```

Danach als root:

```bash
exit   # zurück zu root
<den von pm2 startup ausgegebenen Befehl ausführen>
```

Nützliche PM2-Befehle:

```bash
pm2 status
pm2 logs demonic-pic-gen-backend
pm2 restart demonic-pic-gen-backend
```

## 9. Nginx als Reverse Proxy

```bash
apt install -y nginx
```

Neue Site-Konfiguration anlegen:

```bash
nano /etc/nginx/sites-available/demonic-pic-gen
```

Inhalt:

```nginx
server {
    listen 80;
    server_name api.deinedomain.de;

    client_max_body_size 5m;

    location / {
        proxy_pass http://127.0.0.1:3005;
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
ln -s /etc/nginx/sites-available/demonic-pic-gen /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## 10. HTTPS mit Let's Encrypt (Certbot)

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d api.deinedomain.de
```

Certbot richtet automatisch HTTPS ein und verlängert das Zertifikat
regelmäßig. Test des Auto-Renewals:

```bash
certbot renew --dry-run
```

## 11. Testen

```bash
curl https://api.deinedomain.de/api/health
# -> {"status":"ok","uptime":123.45}

curl -X POST https://api.deinedomain.de/api/generate \
  -H "Content-Type: application/json" \
  -H "X-API-Key: DEIN_API_KEY" \
  -d '{"prompt":"a demon king on a throne of bones","width":1024,"height":1024}' \
  --output test.jpg
```

Wenn `test.jpg` ein Bild ist, funktioniert das Backend.

## 12. iOS App konfigurieren

In der App unter **Einstellungen**:

- **Backend-URL**: `https://api.deinedomain.de`
- **API-Key**: der Wert aus deiner `.env`

Mit "Verbindung testen" prüfst du, ob die App den `/api/health`-Endpunkt
erreicht.

## 13. Updates einspielen

```bash
su - demonic
cd DemonicImageGenIOS
git pull
cd backend
npm install --production
pm2 restart demonic-pic-gen-backend
```

## Sicherheitshinweise

- Setze unbedingt einen `API_KEY`, sonst kann jeder, der die URL kennt,
  über deinen Server kostenlos Bilder generieren.
- Das Rate-Limiting im Backend (`express-rate-limit`) schützt zusätzlich vor
  Missbrauch.
- Halte Node.js, npm-Pakete und das Betriebssystem regelmäßig aktuell
  (`apt update && apt upgrade`, `npm outdated`).
