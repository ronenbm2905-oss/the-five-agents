#!/usr/bin/env node
// gpt-image-gen — החלפה דטרמיניסטית של שורת טקסט בתמונה שנוצרה.
//
// למה זה קיים: gpt-image-2 מחליף ביטויים עבריים לא-שגרתיים בביטוי נפוץ שהוא
// "מכיר" (למשל "שנה טובה תשפ״ז" -> "שנה טובה ומתוקה"), ועריכה חוזרת דרך
// /v1/images/edits לא תמיד מתקנת את זה. הסקריפט הזה צובע מחדש את שורת הטקסט
// בצבע הנייר, ומצייר מעליה את הטקסט הנכון — בלי קריאת API ובלי להגריל מחדש
// שום פיקסל אחר בתמונה.
//
// דרישה: sharp (מותקן בתיקיית הסקיל).
//
// שימוש:
//   node fix_text_line.js --in <src.png> --probe
//   node fix_text_line.js --in <src.png> --out <dst.png> --text "שנה טובה תשפ״ז" \
//     --band 1287:1332 --baseline 1319 --height 25 --x 330:644 --angle 4.13 \
//     [--fill '#264E8C'] [--font 'Segoe UI Semibold'] [--weight normal] [--feather 2]

const sharp = require('sharp');

const argv = process.argv.slice(2);
const arg = (n, d) => { const i = argv.indexOf('--' + n); return i === -1 ? d : argv[i + 1]; };
const flag = n => argv.includes('--' + n);

const SRC = arg('in'), DST = arg('out'), TEXT = arg('text');
const FONT = arg('font', 'Segoe UI Semibold'), WEIGHT = arg('weight', 'normal');
const FILL = arg('fill', '#30589B');
const FEATHER = Number(arg('feather', 2));
const ANGLE = Number(arg('angle', 0));   // מעלות; חיובי = שורת הבסיס יורדת ימינה
const XSPAN = arg('x');                  // "x0:x1" — גבולות אופקיים מפורשים של השורה

if (!SRC) { console.error('חסר --in'); process.exit(1); }

(async () => {
  const img = sharp(SRC);
  const { width: W, height: H } = await img.metadata();
  const { data, info } = await img.raw().toBuffer({ resolveWithObject: true });
  const C = info.channels;
  const at = (x, y) => { const i = (y * W + x) * C; return [data[i], data[i + 1], data[i + 2]]; };

  // גבולות הנייר בשורה נתונה, בסריקה פנימה מבחוץ. עובד כשמסביב לסטריפ יש עור
  // או רקע כהה; כשהרקע בהיר (בוקה) הזיהוי נכשל — אז מעבירים --x מפורש.
  const isPaper = (x, y) => { const [r, g, b] = at(x, y); return r > 195 && g > 195 && b > 195; };
  const run = (x, y, n) => { for (let k = 0; k < n; k++) if (!isPaper(x + k, y)) return false; return true; };
  const midX = Math.floor(W / 2);
  const paperEdges = y => {
    let L = null, R = null;
    for (let x = 0; x < midX; x++) if (run(x, y, 5)) { L = x; break; }
    for (let x = W - 1; x > midX; x--) if (run(x - 4, y, 5)) { R = x; break; }
    return (L === null || R === null) ? null : { L, R };
  };

  // ---- probe: רצועות הטקסט שעל הנייר ----
  // סופר דיו רק *בתוך* הנייר, אחרת הרקע המטושטש נספר כטקסט ומאחד הכל לרצועה אחת.
  if (flag('probe')) {
    const isInk = (r, g, b) => (r + g + b) / 3 < 170;
    const bands = []; let cur = null;
    for (let y = Math.floor(H * 0.70); y < H; y++) {
      const e = paperEdges(y);
      if (!e) { if (cur) { if (cur.y1 - cur.y0 > 2) bands.push(cur); cur = null; } continue; }
      let n = 0, minX = W, maxX = 0;
      for (let x = e.L + 3; x <= e.R - 3; x++) if (isInk(...at(x, y))) { n++; if (x < minX) minX = x; if (x > maxX) maxX = x; }
      if (n > 3) cur = cur ? { ...cur, y1: y, minX: Math.min(cur.minX, minX), maxX: Math.max(cur.maxX, maxX) } : { y0: y, y1: y, minX, maxX };
      else if (cur) { if (cur.y1 - cur.y0 > 2) bands.push(cur); cur = null; }
    }
    if (cur && cur.y1 - cur.y0 > 2) bands.push(cur);
    console.log(`image ${W}x${H}`);
    bands.forEach((b, i) => console.log(`band ${i}: --band ${b.y0 - 5}:${b.y1 + 7} --baseline ${b.y1} --height ${b.y1 - b.y0 + 1} --x ${b.minX}:${b.maxX}`));
    console.log('');
    console.log('הערכים הם הערכה בלבד. אם השורה נטויה או שיש בה אות יורדת (ק/ן/ך/ף/ץ),');
    console.log('הרצועה נמרחת על יותר שורות ו---height ייצא מנופח — מדוד אות בודדת.');
    return;
  }

  if (!DST || !TEXT) { console.error('חסר --out או --text'); process.exit(1); }
  const [BY0, BY1] = (arg('band', '') || '').split(':').map(Number);
  const BASELINE = Number(arg('baseline'));
  const TARGET_H = Number(arg('height'));
  if (!BY0 || !BY1 || !BASELINE || !TARGET_H) { console.error('חסר --band / --baseline / --height'); process.exit(1); }

  // ---- 1. צביעה מחדש של הרצועה בצבע הנייר ----
  // FEATHER פיקסלים בכל קצה נשארים כמו שהם, כדי לשמר את ה-antialiasing של גבול הנייר.
  let rowSpan = new Map();   // y -> {L, R} של האזור לצביעה
  let centerX;

  if (XSPAN) {
    // מלבן מסובב סביב מרכז השורה, נחתך לפי שורות סריקה.
    const [x0, x1] = XSPAN.split(':').map(Number);
    const th = ANGLE * Math.PI / 180;
    centerX = (x0 + x1) / 2;
    const cy = (BY0 + BY1) / 2;
    const halfL = (x1 - x0) / 2 / Math.cos(th) + 4;
    const halfHt = (BY1 - BY0) / 2;
    const cos = Math.cos(th), sin = Math.sin(th);
    const corners = [[-halfL, -halfHt], [halfL, -halfHt], [halfL, halfHt], [-halfL, halfHt]]
      .map(([u, v]) => [centerX + u * cos - v * sin, cy + u * sin + v * cos]);
    const yTop = Math.floor(Math.min(...corners.map(c => c[1])));
    const yBot = Math.ceil(Math.max(...corners.map(c => c[1])));
    for (let y = Math.max(0, yTop); y <= Math.min(H - 1, yBot); y++) {
      const hits = [];
      for (let i = 0; i < 4; i++) {
        const [ax, ay] = corners[i], [bx, by] = corners[(i + 1) % 4];
        if ((ay <= y && by > y) || (by <= y && ay > y)) hits.push(ax + (y - ay) / (by - ay) * (bx - ax));
      }
      if (hits.length >= 2) rowSpan.set(y, { L: Math.round(Math.min(...hits)), R: Math.round(Math.max(...hits)) });
    }
  } else {
    for (let y = BY0; y <= BY1; y++) {
      const e = paperEdges(y);
      if (!e) { console.error(`זיהוי קצה הנייר נכשל בשורה ${y} — העבר --x מפורש`); process.exit(1); }
      rowSpan.set(y, e);
    }
    const mid = rowSpan.get(BASELINE) || [...rowSpan.values()][rowSpan.size >> 1];
    centerX = (mid.L + mid.R) / 2;
  }

  // המילוי הוא אינטרפולציה אנכית לכל עמודה בנפרד: דוגמים נייר נקי מעל הרצועה
  // ומתחתיה, ומשלבים ביניהם. צבע חציוני אחד לכל שורה לא מספיק — לנייר יש גם
  // גרדיאנט אופקי (צל היד בצד אחד), והוא היה משאיר כתם גלוי.
  const colSpan = new Map();   // x -> {yTop, yBot} בתוך הרצועה
  for (const [y, { L, R }] of rowSpan) {
    for (let x = Math.max(0, L + FEATHER); x <= Math.min(W - 1, R - FEATHER); x++) {
      const c = colSpan.get(x);
      if (!c) colSpan.set(x, { yTop: y, yBot: y });
      else { if (y < c.yTop) c.yTop = y; if (y > c.yBot) c.yBot = y; }
    }
  }
  const samplePaper = (x, y0, dir) => {   // ממוצע של עד 4 פיקסלי נייר בכיוון dir
    const acc = [0, 0, 0]; let n = 0;
    for (let k = 1; k <= 8 && n < 4; k++) {
      const y = y0 + dir * k;
      if (y < 0 || y >= H) break;
      const [r, g, b] = at(x, y);
      if (r > 200 && g > 200 && b > 200) { acc[0] += r; acc[1] += g; acc[2] += b; n++; }
    }
    return n ? acc.map(v => v / n) : null;
  };
  let unfilled = 0;
  for (const [x, { yTop, yBot }] of colSpan) {
    const above = samplePaper(x, yTop, -1), below = samplePaper(x, yBot, +1);
    const src = above && below ? null : (above || below);
    if (!above && !below) { unfilled++; continue; }
    const span = Math.max(1, yBot - yTop);
    for (let y = yTop; y <= yBot; y++) {
      const t = (y - yTop) / span;
      const c = src || [0, 1, 2].map(k => above[k] + (below[k] - above[k]) * t);
      const i = (y * W + x) * C;
      data[i] = Math.round(c[0]); data[i + 1] = Math.round(c[1]); data[i + 2] = Math.round(c[2]);
    }
  }
  if (unfilled) console.warn(`אזהרה: ${unfilled} עמודות ללא נייר נקי מעל או מתחת — הרצועה כנראה חורגת אל התמונה/הרקע.`);
  const cleaned = await sharp(data, { raw: { width: W, height: H, channels: C } }).png().toBuffer();

  // ---- 2. התאמת גודל הפונט כך שגובה הדיו יהיה בדיוק TARGET_H ----
  const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const probeSvg = fs => `<svg xmlns="http://www.w3.org/2000/svg" width="2400" height="400"><rect width="2400" height="400" fill="white"/><text x="1200" y="300" font-family="${FONT}" font-size="${fs}" font-weight="${WEIGHT}" fill="#000" text-anchor="middle">${esc(TEXT)}</text></svg>`;
  const inkBox = async fs => {
    const { data: d, info: n } = await sharp(Buffer.from(probeSvg(fs))).raw().toBuffer({ resolveWithObject: true });
    let minX = n.width, maxX = 0, minY = n.height, maxY = 0;
    for (let y = 0; y < n.height; y++) for (let x = 0; x < n.width; x++) {
      if (d[(y * n.width + x) * n.channels] < 128) { if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y; }
    }
    if (maxX === 0) { console.error(`הפונט "${FONT}" לא רינדר כלום — כנראה לא מותקן או בלי גליפים עבריים.`); process.exit(1); }
    return { w: maxX - minX + 1, h: maxY - minY + 1, baselineOffset: maxY - 300 };
  };
  let fs = 100, box = await inkBox(fs);
  fs = Math.round(fs * TARGET_H / box.h); box = await inkBox(fs);

  const spanW = XSPAN
    ? Number(XSPAN.split(':')[1]) - Number(XSPAN.split(':')[0]) + 1
    : (() => { const m = [...rowSpan.values()][rowSpan.size >> 1]; return m.R - m.L + 1; })();
  console.log(`font-size ${fs} -> ink ${box.w}x${box.h}px | centre x=${Math.round(centerX)} | angle ${ANGLE}deg | reference span ${spanW}px`);
  if (box.w > spanW) console.warn(`אזהרה: הטקסט החדש (${box.w}px) רחב מהשורה המקורית (${spanW}px) — שקול --height קטן יותר או פונט צר יותר.`);

  // ---- 3. ציור השורה המתוקנת ----
  const cx = Math.round(centerX), by = Math.round(BASELINE - box.baselineOffset);
  const rot = ANGLE ? ` transform="rotate(${ANGLE}, ${cx}, ${by})"` : '';
  const textSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><text x="${cx}" y="${by}"${rot} font-family="${FONT}" font-size="${fs}" font-weight="${WEIGHT}" fill="${FILL}" text-anchor="middle">${esc(TEXT)}</text></svg>`;
  await sharp(cleaned).composite([{ input: Buffer.from(textSvg), top: 0, left: 0 }]).png().toFile(DST);
  console.log('OK:', DST);
})();
