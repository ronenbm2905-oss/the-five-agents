---
file: .env.example
owner: כללי
type: config
tags:
  - file-doc
  - config
---

# .env.example — תבנית משתני סביבה

> [!info] בקצרה
> קובץ דוגמה למשתני הסביבה של הצוות. מעתיקים אותו ל-`.env` וממלאים ערכים אמיתיים. כן נשמר ב-git.

## מה הקובץ עושה

מתעד את כל משתני הסביבה שהמערכת צורכת, עם ערכים ריקים/דמה:

- `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL` (ברירת מחדל `claude-opus-4-8`) — לכל הסוכנים.
- `OPENAI_API_KEY` — ליובל (סקיל `gpt-image-gen`, מודל `gpt-image-2`).
- `SEARCH_API_KEY` — לחן (חיפוש/מחקר).
- `ENV` — סביבת ריצה.

## למי משויך

כללי — תשתית לכל הצוות.

## קבצים קשורים

- [[config-env]] — הגרסה האמיתית עם הסודות
- [[config-gitignore]] — הכלל ש`.env` מוחרג אך `.env.example` נשמר
- [[skill-gpt-image-gen]] — צורך את `OPENAI_API_KEY`
- [[agent-chen]] — צורכת את `SEARCH_API_KEY`
