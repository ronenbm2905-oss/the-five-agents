---
file: .claude/skills/gpt-image-gen/SKILL.md
owner: יובל
type: skill
tags:
  - file-doc
  - skill
  - yuval
---

# סקיל gpt-image-gen

> [!info] בקצרה
> מעטפת סקריפט ליצירת תמונה מ-`prompt` דרך OpenAI Images API (מודל `gpt-image-2`). שולח את הבקשה ושומר PNG.

## מה הקובץ עושה

סקריפט bash עצמאי (self-contained) שמקבל `PROMPT` ו-`OUT`, טוען את `OPENAI_API_KEY` מ-`.env`, קורא ל-API ומפענח את ה-base64 ל-PNG. מזהה לבד `jq` או Python אמיתי (עוקף את ה-shim של Microsoft Store), שומר את ה-prompt לצד הקובץ, ומאמת את חתימת ה-PNG.

> [!warning] מודל קבוע
> המודל הוא `gpt-image-2` בדיוק — אין לשנות ואין להציע אלטרנטיבות. שגיאות כמעט תמיד נובעות מ-`OPENAI_API_KEY` או מהפרמטרים.

## למי משויך

כלי של [[agent-yuval]] — הוא הסוכן היחיד שמריץ אותו.

## קבצים קשורים

- [[agent-yuval]] — הצרכן היחיד של הסקיל
- [[config-env]] — מקור ה-`OPENAI_API_KEY`
- [[config-env-example]] — מתעד את המשתנה הנדרש
- [[yuval-outputs-readme]] — לאן נשמרים הפלטים
- [[yuval-image-horse]] — דוגמה לתוצר של הסקיל
