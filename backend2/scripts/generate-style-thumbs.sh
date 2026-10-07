#!/usr/bin/env bash
#
# generate-style-thumbs.sh
#
# Generiert Vorschaubilder fuer die 11 neuen Engel-Stile ueber das lokal
# laufende backend2 (Cloudflare Workers AI, Flux-Modell) und speichert sie
# direkt unter dem jeweiligen Stilnamen in StyleThumbs/.
#
# Nutzung:
#   cd backend2/scripts
#   ./generate-style-thumbs.sh
#
# Voraussetzung: backend2 laeuft lokal (pm2 status) und backend2/.env ist
# befuellt (PORT, API_KEY, CF_ACCOUNT_ID, CF_API_TOKEN).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${BACKEND_DIR}/.env"
OUTPUT_DIR="${SCRIPT_DIR}/StyleThumbs"

if [ ! -f "$ENV_FILE" ]; then
  echo "Fehler: ${ENV_FILE} nicht gefunden. Erst backend2/.env aus .env.example anlegen." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

PORT="${PORT:-3006}"
BACKEND_URL="http://127.0.0.1:${PORT}"

if [ -z "${API_KEY:-}" ]; then
  echo "Hinweis: API_KEY ist in ${ENV_FILE} leer -- Anfragen laufen ohne X-API-Key-Header."
fi

# Immer derselbe Basis-Prompt fuer alle 11 Stile, nur der Stil-Zusatz
# unterscheidet sich -- so sind die Vorschaubilder untereinander vergleichbar.
BASE_PROMPT="a divine angel with glowing wings"

# Reihenfolge der Stile (Bash-Arrays sind geordnet, assoziative Arrays nicht).
ORDER=(
  "Himmelslicht"
  "Heiligenfeuer"
  "Lichtkranz"
  "Reinheit"
  "Morgenröte"
  "Auferstehung"
  "Erzengel"
  "Himmelsschmiede"
  "Seelenwächter"
  "Heiligtum"
  "Segensrunen"
)

declare -A SUFFIXES=(
  ["Himmelslicht"]=", divine light angelic style, radiant golden glow, soft heavenly light, pure white wings, cinematic lighting, highly detailed, celestial atmosphere"
  ["Heiligenfeuer"]=", holy fire angelic style, blazing golden flames, righteous light, warm radiant glow, cinematic, highly detailed"
  ["Lichtkranz"]=", angelic halo style, glowing aureole, soft white and gold energy, ethereal, glowing light rays, highly detailed, dramatic lighting"
  ["Reinheit"]=", angelic purity style, pristine white light, serene glowing aura, blessed magic, highly detailed, peaceful atmosphere"
  ["Morgenröte"]=", golden dawn angelic style, warm sunrise sky, radiant altar of light, uplifting lighting, highly detailed, celestial atmosphere"
  ["Auferstehung"]=", resurrection angelic style, divine rebirth magic, glowing white light runes, soft heavenly mist, highly detailed, sacred atmosphere"
  ["Erzengel"]=", archangel royal style, ornate celestial armor, regal radiant wings, glowing halo of light, highly detailed, majestic and powerful"
  ["Himmelsschmiede"]=", celestial forge angelic style, divine machinery, glowing golden light engines, heavenly workshop, highly detailed, radiant sci-fi fantasy"
  ["Seelenwächter"]=", soul guardian angelic style, radiant protector spirit, flowing light robes, glowing guiding wisps, highly detailed, serene atmosphere"
  ["Heiligtum"]=", holy sanctuary angelic style, ancient temple of light, soft golden mist, sacred stone, highly detailed, peaceful atmosphere"
  ["Segensrunen"]=", sacred glyph angelic style, glowing holy runes, divine sigils, radiant magical energy, highly detailed, mystical light atmosphere"
)

mkdir -p "$OUTPUT_DIR"
echo "Ausgabeordner: ${OUTPUT_DIR}"
echo

failed=()

for name in "${ORDER[@]}"; do
  suffix="${SUFFIXES[$name]}"
  prompt="${BASE_PROMPT}${suffix}"
  dest="${OUTPUT_DIR}/${name}.png"
  tmp_file="$(mktemp)"

  echo "==> ${name}"

  attempt=1
  max_attempts=2
  success=0

  while [ "$attempt" -le "$max_attempts" ]; do
    http_code=$(curl -s -o "$tmp_file" -w "%{http_code}" -X POST "${BACKEND_URL}/api/generate" \
      -H "Content-Type: application/json" \
      -H "X-API-Key: ${API_KEY:-}" \
      -d "{\"prompt\":\"${prompt}\",\"model\":\"flux\"}")

    if [ "$http_code" = "200" ]; then
      mv "$tmp_file" "$dest"
      echo "    gespeichert: ${dest}"
      success=1
      break
    fi

    echo "    Versuch ${attempt}/${max_attempts} fehlgeschlagen (Status ${http_code}):"
    sed 's/^/      /' "$tmp_file"
    echo
    attempt=$((attempt + 1))
    [ "$attempt" -le "$max_attempts" ] && sleep 3
  done

  if [ "$success" -ne 1 ]; then
    failed+=("$name")
  fi

  rm -f "$tmp_file"
  sleep 1
  echo
done

echo "Fertig."
if [ "${#failed[@]}" -gt 0 ]; then
  echo "Fehlgeschlagen: ${failed[*]}"
  echo "Diese Stile einfach erneut mit angepasstem Prompt-Zusatz versuchen (Skript-Variable SUFFIXES)."
  exit 1
fi

echo "Alle 11 Bilder liegen in ${OUTPUT_DIR}/"
