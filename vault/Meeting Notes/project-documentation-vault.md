# Project Documentation Vault

## Overview
תיעוד קובץ-אחר-קובץ של כל פרויקט "צוות חמשת הסוכנים", שנבנה כ-Obsidian vault תחת `vault/`. הליבה היא התיקייה `File Docs/` — פתק `.md` לכל קובץ בפרויקט המסביר **מה הקובץ עושה**, **למי הוא משויך** (איזה סוכן/תשתית), ו**קבצים קשורים** ב-`[[wikilinks]]`. בנוסף הוקמו תיקיות התקן של סקיל `obsidian-vault-workflow` (Meeting Notes / Content Briefs / Publishing Log / Brand Guidelines), כל אחת עם `_index.md`. מטרת ה-vault: לשמש זיכרון ארוך-טווח ומפת-פרויקט שסשן עתידי טוען לפני עבודה.

## Open Questions
- האם לפצל את `[[yael-style-guide]]` ל-Brand Guidelines נפרד, או להשאיר את התיעוד שלו תחת File Docs? (כרגע רק File Docs)
- קבצי `.obsidian/` תועדו כפתק יחיד ([[config-obsidian]]) ולא קובץ-לכל-json — לבדוק אם נדרש פירוט עמוק יותר.

## Session Log

### 2026-07-07 — הקמת vault תיעוד הפרויקט [shipped]
- **What was done:** הורדו 3 סקילים של Obsidian מהריפו `ZeremItay/the-5-agents-obsidian` (bases / markdown / vault-workflow) ל-`.claude/skills/`. נסרק כל הפרויקט ונוצרו 24 פתקי תיעוד ב-`vault/File Docs/` (סוכנים, סקילים, קונפיג, Content, Output, סביבות עבודה) + `_index.md`. הוקמו 4 תיקיות תקן עם אינדקסים.
- **Decisions:** בחרתי במבנה `File Docs/` (פתק לכל קובץ) כי הבקשה המפורשת הייתה תיעוד קובץ-אחר-קובץ — מעבר למבנה הסשן-לוג הסטנדרטי של הסקיל. שמות קבצים ב-ASCII (slugs) לחוסן ה-`[[wikilinks]]`, עם כותרות בעברית בגוף. זוגות קבצים צמודים (md+html של Output, png+txt של יובל) אוחדו לפתק אחד.
- **Notes / Caveats:** ה-vault יושב תחת `vault/`, בעוד `.obsidian/` בשורש הופך את כל הפרויקט ל-vault של Obsidian — שני הדברים עקביים. המשתמש ביקש להפעיל את `obsidian-vault-workflow` בתחילת כל סשן/פקודה; הומלץ לו לעגן זאת דרך hook ב-settings.json כדי שיהיה אכיפתי.
- **Related:** [[skill-obsidian-vault-workflow]], [[agent-reuven]], [[content-readme]], [[output-readme]]
