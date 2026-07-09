---
file: .gitignore
owner: כללי
type: config
tags:
  - file-doc
  - config
---

# .gitignore — כללי התעלמות של git

> [!info] בקצרה
> מגדיר אילו קבצים git מתעלם מהם: סודות, תלויות, לוגים, קבצי מערכת ו-IDE.

## מה הקובץ עושה

מחריג:

- **סודות:** `.env` וגרסאות local — אך **שומר** במפורש את `.env.example` (`!.env.example`).
- **תלויות:** `node_modules/`, `__pycache__/`, `venv/`, `.venv/`.
- **לוגים/זמניים:** `*.log`, `logs/`, `tmp/`, `.cache/`.
- **קבצי מערכת ו-IDE:** `.DS_Store`, `Thumbs.db`, `.vscode/`, `.idea/`, `*.swp`.

## למי משויך

כללי — היגיינת מקור לכל הפרויקט.

## קבצים קשורים

- [[config-env]] — הקובץ הסודי שמוחרג
- [[config-env-example]] — הקובץ שמוחרג מההחרגה (נשמר)
