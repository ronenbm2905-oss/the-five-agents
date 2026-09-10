#!/usr/bin/env bash
# בונה את קבצי הלוגו של א.מ.ר: שלושה SVG עם הגופן Varela Round מוטמע כ-base64
# (כל קובץ self-contained ומרנדר נכון גם בלי הגופן מותקן), עמוד תצוגה, וייצוא PNG.
#
# הרצה מתוך שורש הפרויקט:  bash yuval/brand/build-logo.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
B=yuval/brand

HE="$(cat "$B/varela-round-hebrew.b64")"
LA="$(cat "$B/varela-round-latin.b64")"

# בלוק ה-@font-face המשותף. ה-unicode-range מפריד בין תת-הקבוצה העברית
# (האותיות) ללטינית (המפריד ·) כדי שכל תו יימשך מהקובץ הנכון.
FONTCSS="@font-face{font-family:'AMR Round';font-style:normal;font-weight:400;src:url(data:font/woff2;base64,${HE}) format('woff2');unicode-range:U+0307-0308,U+0590-05FF,U+200C-2010,U+20AA,U+25CC,U+FB1D-FB4F;}
@font-face{font-family:'AMR Round';font-style:normal;font-weight:400;src:url(data:font/woff2;base64,${LA}) format('woff2');unicode-range:U+0000-00FF,U+2000-206F;}"

NAVY="#0E2A55"
SKY="#3B9DF5"
PAPER="#F5F8FC"

# viewBox חתוכים לגבולות התוכן בפועל + מרווח נשימה אחיד.
VB_FULL="130 28 500 268"   # אותיות + טאגליין
VB_MARK="87 35 466 168"    # אותיות בלבד

# --- 1. לוקאפ מלא: אותיות + טאגליין, רקע שקוף ---
cat > "$B/logo-amr.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="${VB_FULL}" width="500" height="268" role="img" aria-label="א.מ.ר — אמינות, מעקב, רוגע">
<style>
${FONTCSS}
.wm{font-family:'AMR Round';font-size:170px;letter-spacing:2px}
.tl{font-family:'AMR Round';font-size:32px;letter-spacing:5px;fill:${NAVY};fill-opacity:.62}
</style>
<text class="wm" x="380" y="175" text-anchor="middle" direction="rtl"><tspan fill="${NAVY}">א.</tspan><tspan fill="${SKY}">מ</tspan><tspan fill="${NAVY}">.ר</tspan></text>
<text class="tl" x="380" y="248" text-anchor="middle" direction="rtl">אמינות · מעקב · רוגע</text>
</svg>
EOF

# --- 2. מארק בלבד (אווטאר / favicon / שימוש בקטן) ---
cat > "$B/logo-amr-mark.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="${VB_MARK}" width="466" height="168" role="img" aria-label="א.מ.ר">
<style>
${FONTCSS}
.wm{font-family:'AMR Round';font-size:170px;letter-spacing:2px}
</style>
<text class="wm" x="320" y="170" text-anchor="middle" direction="rtl"><tspan fill="${NAVY}">א.</tspan><tspan fill="${SKY}">מ</tspan><tspan fill="${NAVY}">.ר</tspan></text>
</svg>
EOF

# --- 3. גרסה הפוכה: על רקע נייבי ---
cat > "$B/logo-amr-inverse.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="${VB_FULL}" width="500" height="268" role="img" aria-label="א.מ.ר — אמינות, מעקב, רוגע">
<style>
${FONTCSS}
.wm{font-family:'AMR Round';font-size:170px;letter-spacing:2px}
.tl{font-family:'AMR Round';font-size:32px;letter-spacing:5px;fill:#FFFFFF;fill-opacity:.70}
</style>
<rect x="130" y="28" width="500" height="268" fill="${NAVY}"/>
<text class="wm" x="380" y="175" text-anchor="middle" direction="rtl"><tspan fill="#FFFFFF">א.</tspan><tspan fill="${SKY}">מ</tspan><tspan fill="#FFFFFF">.ר</tspan></text>
<text class="tl" x="380" y="248" text-anchor="middle" direction="rtl">אמינות · מעקב · רוגע</text>
</svg>
EOF

# --- 4. גרסת ייחוס ליובל: הלוקאפ על רקע נייר, מסגור נדיב ---
cat > "$B/logo-amr-ref.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 480" width="1024" height="480" role="img" aria-label="א.מ.ר — אמינות, מעקב, רוגע">
<style>
${FONTCSS}
.wm{font-family:'AMR Round';font-size:210px;letter-spacing:2px}
.tl{font-family:'AMR Round';font-size:40px;letter-spacing:6px;fill:${NAVY};fill-opacity:.62}
</style>
<rect width="1024" height="480" fill="${PAPER}"/>
<text class="wm" x="512" y="262" text-anchor="middle" direction="rtl"><tspan fill="${NAVY}">א.</tspan><tspan fill="${SKY}">מ</tspan><tspan fill="${NAVY}">.ר</tspan></text>
<text class="tl" x="512" y="352" text-anchor="middle" direction="rtl">אמינות · מעקב · רוגע</text>
</svg>
EOF

# --- 5. עמוד תצוגה ---
# ה-SVG מוטמע inline ולא כ-<img src>: הדפדפן ממיר קובץ מקומי ל-data URL
# וקישורים יחסיים נשברים. בלוק הגופן מופיע פעם אחת ב-<style> של הדף.
SVG_FULL='<svg viewBox="'"${VB_FULL}"'" xmlns="http://www.w3.org/2000/svg"><text class="wm" x="380" y="175" text-anchor="middle" direction="rtl"><tspan fill="'"${NAVY}"'">א.</tspan><tspan fill="'"${SKY}"'">מ</tspan><tspan fill="'"${NAVY}"'">.ר</tspan></text><text class="tl" x="380" y="248" text-anchor="middle" direction="rtl">אמינות · מעקב · רוגע</text></svg>'
SVG_INV='<svg viewBox="'"${VB_FULL}"'" xmlns="http://www.w3.org/2000/svg"><text class="wm" x="380" y="175" text-anchor="middle" direction="rtl"><tspan fill="#fff">א.</tspan><tspan fill="'"${SKY}"'">מ</tspan><tspan fill="#fff">.ר</tspan></text><text class="tl tl-inv" x="380" y="248" text-anchor="middle" direction="rtl">אמינות · מעקב · רוגע</text></svg>'
SVG_MARK='<svg viewBox="'"${VB_MARK}"'" xmlns="http://www.w3.org/2000/svg"><text class="wm" x="320" y="170" text-anchor="middle" direction="rtl"><tspan fill="'"${NAVY}"'">א.</tspan><tspan fill="'"${SKY}"'">מ</tspan><tspan fill="'"${NAVY}"'">.ר</tspan></text></svg>'

cat > "$B/logo-amr-preview.html" <<EOF
<!doctype html><html lang="he" dir="rtl"><head><meta charset="utf-8">
<title>א.מ.ר — לוגו</title>
<style>
${FONTCSS}
*{box-sizing:border-box;margin:0}
body{background:${PAPER};font-family:'AMR Round',system-ui,sans-serif}
.sheet{width:960px;margin:0 auto;padding:44px 40px;display:flex;flex-direction:column;gap:30px}
.card{background:#fff;border-radius:20px;padding:34px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 18px rgba(14,42,85,.07)}
.card.dark{background:${NAVY}}
.card svg{width:100%;max-width:440px;height:auto;display:block}
.card.small svg{max-width:150px}
.row{display:flex;gap:30px;align-items:stretch}
.row>div{flex:1;display:flex;flex-direction:column}
.row .card{flex:1}
.lbl{font-size:15px;color:${NAVY};opacity:.55;margin-bottom:9px}
.wm{font-family:'AMR Round';font-size:170px;letter-spacing:2px}
.tl{font-family:'AMR Round';font-size:32px;letter-spacing:5px;fill:${NAVY};fill-opacity:.62}
.tl-inv{fill:#fff;fill-opacity:.70}
</style></head><body>
<div class="sheet">
  <div><div class="lbl">לוקאפ ראשי</div><div class="card">${SVG_FULL}</div></div>
  <div class="row">
    <div><div class="lbl">גרסה הפוכה</div><div class="card dark">${SVG_INV}</div></div>
    <div><div class="lbl">מארק בלבד</div><div class="card">${SVG_MARK}</div></div>
  </div>
  <div><div class="lbl">מבחן קריאות בקטן</div><div class="card small">${SVG_FULL}</div></div>
</div>
</body></html>
EOF

# --- 6. ייצוא PNG דרך Edge headless ---
# אין ImageMagick/rsvg על המכונה; Edge מרנדר SVG נאמנה כולל הגופן המוטמע.
# cygpath ממיר לנתיב Windows בזמן ריצה, כדי לא לכתוב backslashes בסקריפט.
EDGE="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
if [ -x "$EDGE" ]; then
  shot() { # shot <basename> <w> <h> <device-scale>
    local svg png
    svg="$(cygpath -w "$PWD/$B/$1.svg")"
    png="$(cygpath -w "$PWD/$B/$1.png")"
    "$EDGE" --headless --disable-gpu --no-sandbox --hide-scrollbars \
      --force-device-scale-factor="$4" --default-background-color=00000000 \
      --window-size="$2,$3" --screenshot="$png" "$svg" >/dev/null 2>&1
  }
  shot logo-amr         500 268 3
  shot logo-amr-mark    466 168 3
  shot logo-amr-inverse 500 268 3
  shot logo-amr-ref    1024 480 1
else
  echo "אזהרה: msedge.exe לא נמצא — ה-PNG לא יוצאו." >&2
fi

ls -l "$B"/logo-amr*.svg "$B"/logo-amr*.png
echo "OK"
