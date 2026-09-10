#!/usr/bin/env bash
# מרכיב פוסט סופי: איור שנוצר ב-AI + כותרת עברית בטיפוגרפיה אמיתית.
#
# למה בכלל: gpt-image-2 מסרב לרנדר מחרוזת עברית נתונה — הוא ממציא טקסט משלו
# (מתועד ב-vault/Brand Guidelines/amr-brand-identity.md). הכותרת נכתבת כאן
# בגופן המותג, ולכן היא תמיד מדויקת לאות וניתנת להחלפה בלי לייצר תמונה מחדש.
#
# שימוש:
#   bash yuval/brand/compose-post.sh -a <art.png> -t "<כותרת>" -o <out-בלי-סיומת> [-r square|4x5]
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
B=yuval/brand

ART=""; TEXT=""; OUT=""; RATIO="square"
while [ $# -gt 0 ]; do
  case "$1" in
    -a) ART="$2"; shift 2;;
    -t) TEXT="$2"; shift 2;;
    -o) OUT="$2"; shift 2;;
    -r) RATIO="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done
[ -s "$ART" ] || { echo "חסר/ריק -a (איור): $ART" >&2; exit 1; }
[ -n "$TEXT" ] || { echo "חסר -t (כותרת)" >&2; exit 1; }
[ -n "$OUT" ]  || { echo "חסר -o (נתיב פלט)" >&2; exit 1; }

case "$RATIO" in
  square) CANVAS_H=1024; BAND=170; ART_W=854; FS=58;;
  4x5)    CANVAS_H=1280; BAND=256; ART_W=1024; FS=76;;
  *) echo "-r חייב להיות square או 4x5" >&2; exit 1;;
esac

HE="$(cat "$B/varela-round-hebrew.b64")"
LA="$(cat "$B/varela-round-latin.b64")"
NAVY="#0E2A55"

mkdir -p "$(dirname "$OUT")"
HTML="${OUT}.compose.html"
# הרקע: אותה תמונה נמתחת פי-100 לגובה ומוצמדת לראש, כך שנראית רק שורת
# הפיקסלים העליונה של האיור. זו התאמת צבע מושלמת לרקע האיור בלי לדגום פיקסלים
# (הדפדפן חוסם getImageData על קובץ מקומי).
ART_BASENAME="$(basename "$ART")"
ART_COPY="$(dirname "$OUT")/$ART_BASENAME"
[ "$(cd "$(dirname "$ART")" && pwd)/$ART_BASENAME" = "$(cd "$(dirname "$OUT")" && pwd)/$ART_BASENAME" ] && COPIED=0 || { cp -f "$ART" "$ART_COPY"; COPIED=1; }

cat > "$HTML" <<HTMLEOF
<!doctype html><html lang="he" dir="rtl"><head><meta charset="utf-8"><style>
@font-face{font-family:'AMR Round';font-weight:400;src:url(data:font/woff2;base64,${HE}) format('woff2');unicode-range:U+0307-0308,U+0590-05FF,U+200C-2010,U+20AA,U+25CC,U+FB1D-FB4F;}
@font-face{font-family:'AMR Round';font-weight:400;src:url(data:font/woff2;base64,${LA}) format('woff2');unicode-range:U+0000-00FF,U+2000-206F;}
*{margin:0;padding:0;box-sizing:border-box}
.c{position:relative;width:1024px;height:${CANVAS_H}px;overflow:hidden;
   background:url('${ART_BASENAME}') no-repeat top center;background-size:1024px 102400px}
.band{height:${BAND}px;display:flex;align-items:center;justify-content:flex-start;padding:0 58px}
.h{font-family:'AMR Round',sans-serif;font-size:${FS}px;color:${NAVY};
   letter-spacing:.5px;line-height:1.1;white-space:nowrap}
.art{display:block;width:${ART_W}px;margin:0 auto}
</style></head><body>
<div class="c"><div class="band"><div class="h">${TEXT}</div></div>
<img class="art" src="${ART_BASENAME}" alt=""></div>
</body></html>
HTMLEOF

EDGE="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
[ -x "$EDGE" ] || { echo "msedge.exe לא נמצא" >&2; exit 1; }
"$EDGE" --headless --disable-gpu --no-sandbox --hide-scrollbars \
  --force-device-scale-factor=1 --window-size="1024,${CANVAS_H}" \
  --screenshot="$(cygpath -w "$PWD/${OUT}.png")" \
  "$(cygpath -w "$PWD/${HTML}")" >/dev/null 2>&1

rm -f "$HTML"; [ "$COPIED" = 1 ] && rm -f "$ART_COPY"; true
[ -s "${OUT}.png" ] || { echo "כשלון: ${OUT}.png ריק/חסר" >&2; exit 1; }
ls -l "${OUT}.png"
