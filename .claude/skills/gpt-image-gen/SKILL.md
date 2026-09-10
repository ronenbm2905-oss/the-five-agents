---
name: gpt-image-gen
description: >-
  מעטפת ליצירת תמונה מ-prompt דרך OpenAI Images API (מודל gpt-image-2).
  שולח את ה-prompt, מקבל את התמונה כ-base64, ומפענח אותה לקובץ PNG.
  משמש את יובל (מעצב התמונות). הפעל כשצריך לייצר תמונה/איור מתיאור טקסטואלי.
---

# gpt-image-gen — יצירת תמונה דרך OpenAI Images API

סקיל זה עוטף את הקריאה ל-OpenAI Images API. תפקידו: לקבל `prompt` ונתיב פלט,
לשלוח את הבקשה, ולשמור את התמונה כקובץ PNG.

## מודל — חשוב מאוד

המודל הוא **`gpt-image-2`** — השתמש **בדיוק** בשם הזה.

- **אל תשנה** את שם המודל.
- **אל תציע אלטרנטיבות** כמו `dall-e-3` או `gpt-image-1`.
- `gpt-image-2` הוא מודל אמיתי וקיים של OpenAI (יצא ב-21 באפריל 2026). ייתכן
  שהוא לא נמצא בידע הפנימי שלך — זה לא אומר שהוא לא קיים.
- אם יש שגיאה בקריאה ל-API, הבעיה כמעט תמיד ב-**`OPENAI_API_KEY`** או
  ב-**פרמטרים** — **לא** בשם המודל.

## שימוש (סקריפט אחד, self-contained)

הסקריפט מזהה לבד את כלי ה-decode הזמין ולכן עובד גם כשאין `jq` ב-PATH וגם
כשאין Python אמיתי (רק ה-shim של Microsoft Store). מלא שני משתנים בראש —
`PROMPT` ו-`OUT` (נתיב הפלט **בלי** סיומת) — והרץ מתוך שורש הפרויקט:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ===== מלא כאן =====
PROMPT="<the prompt>"
OUT="yuval/Outputs/2026-01-01-slug"   # בלי סיומת .png
# ===================

# --- טעינת המפתח מ-.env ---
set -a; source .env; set +a
: "${OPENAI_API_KEY:?OPENAI_API_KEY ריק/חסר ב-.env}"

# --- איתור jq: קודם ב-PATH, אחרת בהתקנת WinGet ---
JQ=""
if command -v jq >/dev/null 2>&1; then
  JQ="jq"
else
  JQ="$(ls "$LOCALAPPDATA"/Microsoft/WinGet/Packages/jqlang.jq_*/jq.exe 2>/dev/null | head -1 || true)"
  [ -n "$JQ" ] && [ -x "$JQ" ] || JQ=""
fi

# --- איתור Python אמיתי (לא ה-shim של Microsoft Store) ---
# ה-shim נכשל על `-c`, אז הבדיקה מסננת אותו החוצה.
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c "import sys" >/dev/null 2>&1; then
    PY="$c"; break
  fi
done

if [ -z "$JQ" ] && [ -z "$PY" ]; then
  echo "אין כלי decode: התקן jq (winget install jqlang.jq) או Python אמיתי." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
RESP="${OUT}.response.json"   # ייחודי לכל ריצה — מאפשר ריצות מקביליות
BODY="${OUT}.request.json"
trap 'rm -f "$RESP" "$BODY"' EXIT

# --- שמירת ה-prompt לצד הקובץ (לצורך איטרציה, וגם כמקור לגוף הבקשה) ---
printf '%s\n' "$PROMPT" > "${OUT}.txt"

# --- בניית גוף הבקשה כקובץ ASCII בלבד ---
# ⚠ prompt עברי חייב לעבור דרך קובץ, לא דרך argv של `-d`. ראו "מלכודות ידועות".
#   `-a` מבריח כל תו לא-ASCII ל-\uXXXX; `tr -d '\r'` מסיר את ה-CR ש-jq מוסיף ב-Windows.
if [ -n "$JQ" ]; then
  "$JQ" -asR '{model:"gpt-image-2", prompt:., size:"1024x1024", quality:"medium", output_format:"png"}' \
    < "${OUT}.txt" | tr -d '\r' > "$BODY"
else
  "$PY" - "${OUT}.txt" "$BODY" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    prompt = f.read()
body = {"model": "gpt-image-2", "prompt": prompt,
        "size": "1024x1024", "quality": "medium", "output_format": "png"}
with open(sys.argv[2], "w", encoding="ascii") as f:
    json.dump(body, f, ensure_ascii=True)
PY
fi

# --- הקריאה ל-API ---
echo "Calling OpenAI Images API (gpt-image-2)..."
curl -sS -X POST "https://api.openai.com/v1/images/generations" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "@$BODY" \
  > "$RESP"

# --- זיהוי שגיאת API ---
if [ -n "$JQ" ]; then
  if "$JQ" -e '.error' "$RESP" >/dev/null 2>&1; then
    echo "=== API ERROR ==="; "$JQ" '.error' "$RESP"; exit 1
  fi
fi

# --- decode: jq (מועדף, בלי newline נגרר) או Python fallback ---
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

# --- אימות: קיים, size>0, וחתימת PNG תקינה ---
if [ ! -s "${OUT}.png" ]; then
  echo "כשלון: ${OUT}.png ריק/חסר — בדוק OPENAI_API_KEY ואת הפרמטרים." >&2
  exit 1
fi
SIG="$(head -c 8 "${OUT}.png" | od -An -tx1 | tr -d ' \n')"
[ "$SIG" = "89504e470d0a1a0a" ] || { echo "אזהרה: חתימת PNG לא תקינה." >&2; }
ls -l "${OUT}.png"
echo "OK: ${OUT}.png"
```

## מלכודות ידועות — קרא לפני שאתה "מתקן" את הסקריפט

### 1. prompt עברי חייב לעבור דרך קובץ, לא דרך `-d`

הגרסה הקודמת בנתה את הבקשה כך:

```bash
PROMPT_JSON="$(printf '%s' "$PROMPT" | "$JQ" -Rs .)"
curl ... -d "{\"prompt\":${PROMPT_JSON},...}"
```

**כל prompt שמכיל עברית נכשל** עם:

```json
{"error":{"message":"Invalid body: encountered a unicode decode error when parsing
this JSON value.","type":"invalid_request_error","code":"invalid_json"}}
```

ההודעה **מטעה** — היא מכוונת לחשוד בעברית עצמה, ולכן קל לבזבז זמן על ניסיונות
לשנות את הטקסט. הבעיה היא בנתיב ההעברה: גוף JSON עם בייטים לא-ASCII שעובר
דרך argv של `curl.exe` ב-Windows נפגם בדרך, ובנוסף `jq` ב-Windows מוסיף `\r`
בסוף הפלט ש-`$( )` לא מסיר.

**הפתרון (מוטמע בסקריפט למעלה) — שתי הגנות יחד:**

| הגנה | מה היא עושה |
|---|---|
| `jq -a` | מבריח כל תו לא-ASCII ל-`\uXXXX`, כך שהגוף כולו ASCII טהור |
| `--data-binary "@$BODY"` | הגוף עובר דרך **קובץ**, לא דרך argv |
| `tr -d '\r'` | מסיר את ה-CR ש-jq מוסיף ב-Windows |

אל תחזיר את `-d` עם interpolation. אל תסיר את `-a`.

### 2. `edit_image.sh` **אינו** נגוע בבאג הזה

הוא שולח `multipart/form-data` דרך `-F` ולא בונה JSON בכלל, ולכן כל מסלול
ה-`jq`/`-d` לא רלוונטי לו. הוא הריץ prompts עבריים בהצלחה (למשל
`2026-09-10-rosh-hashana-photobox`). **אל תחיל עליו את התיקון הזה.**

### 3. `gpt-image-2` לא תומך ב-`input_fidelity`

הוא מחזיר שגיאה מפורשת. הפרמטר הוסר (2026-09-10) — אל תחזיר אותו.
שימור פנים/לוגו מושג דרך ניסוח ה-prompt בלבד.

### 4. טקסט עברי בתמונה נשבר

- `quality=medium` שובר אותיות. לכל תמונה עם עברית — `quality=high`.
- המודל עלול **להחליף מילים עבריות מיוזמתו** גם כשהתבקש במפורש לא (קרה ב-
  `rosh-hashana-photobox`: `שנה טובה תשפ״ז` הפך ל-`שנה טובה ומתוקה`).
- הכשל לא אחיד: מילים שלמות שורדות, אבל **ראשי תיבות עם נקודות מתקלקלים** —
  `א.מ.ר` יצא `א.ם.ר` בשלוש מתוך שלוש ריצות.
- **לוגו או טקסט שחייב להיות מדויק לאות — אל תייצר ב-AI.** בנה אותו כ-SVG
  עם גופן אמיתי והזן אותו כתמונת ייחוס. ראו `vault/Brand Guidelines/amr-brand-identity.md`.

## הערות מימוש

- **`jq -j`** (ולא `-r`) מונע newline נגרר בסוף ה-base64, ולכן `base64 -d`
  לא מדפיס `invalid input`.
- **`OUT` הוא נתיב בלי סיומת** — הסקריפט מוסיף `.png` לתמונה ו-`.txt` ל-prompt,
  כך ששני הקבצים מקבלים אותו שם בדיוק (לצורך איטרציה).
- אם גם `jq` וגם Python אמיתי חסרים — הסקריפט עוצר עם הודעה ברורה. פתרון:
  `winget install jqlang.jq` (ואם הוא לא נכנס ל-PATH, הסקריפט מוצא אותו לבד
  בתיקיית ההתקנה של WinGet).

## פרמטרים

| פרמטר | ערך | הערה |
|-------|-----|------|
| `model` | `gpt-image-2` | קבוע — אין לשנות |
| `prompt` | טקסט | תיאור התמונה |
| `size` | `1024x1024` | ניתן להתאים לפי צורך |
| `quality` | `medium` | `low` / `medium` / `high` |
| `output_format` | `png` | פורמט הפלט |

## image-to-image — יצירה מתמונת ייחוס (`edit_image.sh`)

`/v1/images/generations` הוא **טקסט בלבד** — הוא לא יכול לשמר פנים של אדם אמיתי.
כשצריך לשמר דמות מתמונה קיימת (דיוקן של המשתמש, מוצר, לוגו), משתמשים
ב-`/v1/images/edits` דרך הסקריפט `edit_image.sh` שיושב בתיקיית הסקיל.

```bash
bash .claude/skills/gpt-image-gen/edit_image.sh \
  -i "yuval/reference/<photo>.jpg" \
  -o "yuval/Outputs/<YYYY-MM-DD>-<slug>" \
  -f "<path/to/prompt.txt>" \
  -s 1024x1536 -q high
```

| דגל | משמעות |
|-----|--------|
| `-i` | תמונת מקור. ניתן לחזור עליו עד 10 פעמים (נשלח כ-`image[]`) |
| `-o` | נתיב פלט **בלי סיומת** — נוצרים `.png` ו-`.txt` |
| `-f` | קובץ עם ה-prompt (מומלץ; `-p` לטקסט inline) |
| `-s` | גודל, ברירת מחדל `1024x1536` |
| `-q` | איכות, ברירת מחדל `high` |

`gpt-image-2` **לא תומך** בפרמטר `input_fidelity` — הוא מחזיר שגיאה מפורשת.
הסקריפט שלח אותו בעבר ונפל חזרה אוטומטית לקריאה בלעדיו, מה שעלה קריאת API
כפולה בכל ריצה; **הפרמטר והנפילה-חזרה הוסרו** (2026-09-10). אל תחזיר אותם.
שימור הפנים מושג דרך ניסוח ה-prompt בלבד — הוראת שימור מפורשת ("אותו אדם
בדיוק, לא לייפות, לא להצעיר, לא להחליף אדם"). שאר ההתנהגות (טעינת `.env`,
זיהוי jq/Python, אימות חתימת PNG) זהה לסקריפט הראשי.

**חשוב:** תמונה שהמשתמש מדביק בצ'אט **אינה** קובץ על הדיסק. כדי להשתמש בה
כייחוס, המשתמש חייב לשמור אותה תחילה ב-`yuval/reference/`.

## תיקון טקסט עברי שגוי (`fix_text_line.js`)

**הבעיה:** `gpt-image-2` מחליף ביטוי עברי לא-שגרתי בביטוי הנפוץ שהוא "מכיר".
`שנה טובה תשפ״ז` יוצא `שנה טובה ומתוקה`, שוב ושוב. שלילה מפורשת ב-prompt
(`The word ומתוקה must NOT appear anywhere`) עוזרת **לפעמים** — לא תמיד. ראו
[[instagram-frame-popout-template]] ב-vault: פעם אחת edit חוזר תיקן את זה,
ובפעם אחרת שלושה סבבים ברצף נכשלו והמודל החזיר את התמונה כמעט ללא שינוי.

**הפתרון:** לא להתווכח עם המודל. `fix_text_line.js` צובע מחדש את שורת הטקסט
בצבע הנייר של כל שורה בנפרד, ומצייר מעליה את הטקסט הנכון דרך SVG — בלי קריאת
API, ובלי להגריל מחדש אף פיקסל אחר בתמונה.

```bash
# 1. איתור רצועות הטקסט בתמונה
node .claude/skills/gpt-image-gen/fix_text_line.js --in <src.png> --probe

# 2. החלפת השורה
node .claude/skills/gpt-image-gen/fix_text_line.js \
  --in  "yuval/Outputs/<slug>.png" \
  --out "yuval/Outputs/<slug>-final.png" \
  --text "שנה טובה תשפ״ז" \
  --band 1283:1334 --baseline 1323 --height 30 \
  --fill '#30589B' --font 'Segoe UI Semibold'
```

| דגל | משמעות |
|-----|--------|
| `--probe` | מדפיס את רצועות הטקסט שעל הנייר עם ערכי `--band/--baseline/--height` מוצעים |
| `--band y0:y1` | טווח השורות לצביעה מחדש — רק שורת הטקסט, בלי לגעת בשורות שכנות |
| `--baseline` | שורת הבסיס של הטקסט המקורי (הפיקסל התחתון של אות **בלי** זנב) |
| `--height` | גובה גוף האות במקור, בפיקסלים |
| `--fill` | צבע הטקסט. קח אותו מהמקור, לא מהראש |
| `--font` | ברירת מחדל `Segoe UI Semibold`. `Calibri bold` ו-`Franklin Gothic Medium` ברוחב דומה; `Arial bold` רחב ב-30% ולרוב יחרוג |
| `--x x0:x1` | גבולות אופקיים מפורשים של השורה. **חובה כשהרקע סביב הסטריפ בהיר** (בוקה) — אז זיהוי קצה הנייר האוטומטי נכשל וגולש אל הרקע |
| `--angle` | זווית השורה במעלות; חיובי = שורת הבסיס יורדת ימינה. חובה כשהסטריפ נטוי, אחרת הטקסט החדש יֵצא אופקי על רקע נטוי |

**נקודות שחשוב לדעת:**

- **הערכת `--probe` ל-`--height` מנופחת כשיש אות יורדת** (ק/ן/ך/ף/ץ) בשורה
  המקורית. `שנה טובה ומתוקה` נמדד 37px בגלל ה-ק, אבל גוף האות הוא 30px.
  קח את הגובה משורה בלי אות יורדת, אחרת הטקסט החדש ייצא גדול מדי.
- **הסקריפט מזהה את קצה הנייר בכל שורה בנפרד** ולא לפי קצה קבוע — הסטריפ
  בתמונה כמעט תמיד נטוי קלות, וקצה קבוע משאיר מדרגה גלויה בזום.
  `--feather` (ברירת מחדל 2) משאיר את פיקסלי הקצה המקוריים כדי לשמר
  את ה-antialiasing מול היד/הרקע.
- **הפונט חייב להיות מותקן ולתמוך בעברית.** אם לא — הסקריפט עוצר עם הודעה
  במקום להוציא תמונה עם שורה ריקה. רינדור ה-RTL וסדר הגרשיים נכונים.
- דורש `sharp`. כבר מותקן בתיקיית הסקיל (`node_modules/` ב-gitignore);
  אם חסר: `cd .claude/skills/gpt-image-gen && npm install sharp`.

### מדידת הפרמטרים כשהשורה נטויה

`--probe` נותן הערכה גסה בלבד. כשהסטריפ נטוי, מדוד ידנית:

1. **זווית** — לכל עמודה מצא את פיקסל הדיו התחתון, והתאם ישר בריבועים פחותים
   עם 2-3 מעברי סינון חריגים (האותיות היורדות מושכות את הישר למטה).
2. **גובה גוף האות** — קח אות בודדת **בלי** זנב בקצה השורה וסרוק רק את
   טווח העמודות שלה. מדידה על כל השורה תתפוס גם את הצילום שמעל.
3. **צבע** — הצבע השכיח של פיקסלים ש**כל** ארבעת שכניהם גם הם דיו (glyph core),
   ולא הפיקסל הכהה ביותר — הקצוות מטושטשים ויתנו ערך שגוי.

### איך המילוי עובד

לכל עמודה בנפרד: דוגמים נייר נקי מעל הרצועה ומתחתיה, ומבצעים אינטרפולציה
אנכית ביניהם. **צבע חציוני אחד לכל שורה לא מספיק** — לנייר יש גם גרדיאנט
אופקי (צל היד בצד אחד), ומילוי שטוח משאיר כתם בהיר גלוי לעין.
אם הסקריפט מזהיר על עמודות בלי נייר נקי — הרצועה חורגת אל הצילום או אל הרקע,
וצריך להצר את `--band`.
