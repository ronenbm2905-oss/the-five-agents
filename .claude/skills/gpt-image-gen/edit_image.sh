#!/usr/bin/env bash
# gpt-image-gen — עריכה/יצירה מתמונת ייחוס (image-to-image) דרך /v1/images/edits
#
# שימוש:
#   bash .claude/skills/gpt-image-gen/edit_image.sh \
#     -i "yuval/reference/ronen-portrait.jpg" \
#     -o "yuval/Outputs/2026-09-05-slug" \
#     -f "/path/to/prompt.txt" \
#     [-s 1024x1536] [-q high]
#
# -i  תמונת מקור (jpg/png/webp). ניתן לחזור על הדגל עד 10 פעמים.
# -o  נתיב פלט בלי סיומת (נוצרים .png ו-.txt)
# -p  prompt כטקסט  |  -f  קובץ שמכיל את ה-prompt (מומלץ — בלי בעיות ציטוט)
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

IMAGES=(); OUT=""; PROMPT=""; PROMPT_FILE=""; SIZE="1024x1536"; QUALITY="high"
while [ $# -gt 0 ]; do
  case "$1" in
    -i) IMAGES+=("$2"); shift 2;;
    -o) OUT="$2"; shift 2;;
    -p) PROMPT="$2"; shift 2;;
    -f) PROMPT_FILE="$2"; shift 2;;
    -s) SIZE="$2"; shift 2;;
    -q) QUALITY="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done

[ "${#IMAGES[@]}" -gt 0 ] || { echo "חסר -i (תמונת מקור)" >&2; exit 1; }
[ -n "$OUT" ] || { echo "חסר -o (נתיב פלט)" >&2; exit 1; }
[ -n "$PROMPT_FILE" ] && PROMPT="$(cat "$PROMPT_FILE")"
[ -n "$PROMPT" ] || { echo "חסר -p או -f (prompt)" >&2; exit 1; }
for img in "${IMAGES[@]}"; do
  [ -s "$img" ] || { echo "תמונת מקור לא קיימת/ריקה: $img" >&2; exit 1; }
done

set -a; source .env; set +a
: "${OPENAI_API_KEY:?OPENAI_API_KEY ריק/חסר ב-.env}"

JQ=""
if command -v jq >/dev/null 2>&1; then JQ="jq"; else
  JQ="$(ls "$LOCALAPPDATA"/Microsoft/WinGet/Packages/jqlang.jq_*/jq.exe 2>/dev/null | head -1 || true)"
  [ -n "$JQ" ] && [ -x "$JQ" ] || JQ=""
fi
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c "import sys" >/dev/null 2>&1; then PY="$c"; break; fi
done
[ -n "$JQ" ] || [ -n "$PY" ] || { echo "אין כלי decode: winget install jqlang.jq" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
RESP="${OUT}.response.json"   # ייחודי לכל ריצה — מאפשר ריצות מקביליות
trap 'rm -f "$RESP"' EXIT
printf '%s\n' "$PROMPT" > "${OUT}.txt"

# --- בניית הבקשה כ-multipart. image[] מאפשר כמה תמונות ייחוס. ---
ARGS=( -sS -X POST "https://api.openai.com/v1/images/edits"
       -H "Authorization: Bearer $OPENAI_API_KEY"
       -F "model=gpt-image-2"
       -F "prompt=$PROMPT"
       -F "size=$SIZE"
       -F "quality=$QUALITY" )
for img in "${IMAGES[@]}"; do ARGS+=( -F "image[]=@${img}" ); done

echo "Calling OpenAI Images EDITS API (gpt-image-2) with ${#IMAGES[@]} reference image(s)..."
curl "${ARGS[@]}" > "$RESP"

if [ -n "$JQ" ] && "$JQ" -e '.error' "$RESP" >/dev/null 2>&1; then
  echo "=== API ERROR ==="; "$JQ" '.error' "$RESP"; rm -f "$RESP"; exit 1
fi

if [ -n "$JQ" ]; then
  "$JQ" -j '.data[0].b64_json // empty' "$RESP" | base64 -d > "${OUT}.png"
else
  "$PY" - "$RESP" "${OUT}.png" <<'PY'
import base64, json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
if data.get("error"):
    sys.exit("API error: %s" % data["error"])
with open(sys.argv[2], "wb") as f:
    f.write(base64.b64decode(data["data"][0]["b64_json"]))
PY
fi
rm -f "$RESP"

[ -s "${OUT}.png" ] || { echo "כשלון: ${OUT}.png ריק/חסר." >&2; exit 1; }
SIG="$(head -c 8 "${OUT}.png" | od -An -tx1 | tr -d ' \n')"
[ "$SIG" = "89504e470d0a1a0a" ] || echo "אזהרה: חתימת PNG לא תקינה." >&2
ls -l "${OUT}.png"
echo "OK: ${OUT}.png"
