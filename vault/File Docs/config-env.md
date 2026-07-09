---
file: .env
owner: כללי
type: config-secret
tags:
  - file-doc
  - config
  - secret
---

# .env — משתני הסביבה האמיתיים

> [!warning] סודי
> מכיל מפתחות API אמיתיים. מוחרג מ-git (ראו [[config-gitignore]]). אין להעלות אותו ואין להדפיס את תוכנו.

## מה הקובץ עושה

הגרסה הממשית של [[config-env-example]] — מחזיק את הערכים האמיתיים של `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `SEARCH_API_KEY` וכו'. סקריפט [[skill-gpt-image-gen]] טוען ממנו את המפתח בזמן ריצה (`source .env`).

## למי משויך

כללי — תשתית סודית לכל הצוות.

## קבצים קשורים

- [[config-env-example]] — התבנית שממנה נוצר
- [[config-gitignore]] — מה שמחריג אותו מ-git
- [[skill-gpt-image-gen]] — טוען ממנו את `OPENAI_API_KEY`
