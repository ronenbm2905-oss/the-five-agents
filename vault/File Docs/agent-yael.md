---
file: .claude/agents/yael.md
owner: יעל
type: agent-subagent
tags:
  - file-doc
  - agent
  - yael
---

# יעל — כותבת התוכן

> [!info] בקצרה
> הגדרת הסוכנת יעל: מושכת מאמרי גלם מ-`Content/`, משכתבת אותם בסגנון הצוות, ושומרת תוצרי Markdown + HTML ב-`Output/`.

## מה הקובץ עושה

מגדיר את יעל כ-subagent עם הכלים `Read, Write, Edit, Glob, Grep` (מודל opus). ה-flow שלה:

1. מושכת מאמר גלם מ-`Content/`.
2. **קוראת את הסגנון** מ-[[yael-style-guide]] ומ-[[yael-reference-readme]] בתחילת כל משימה.
3. משכתבת בקול של הצוות; מסמנת צורך בתמונות עם placeholder `{{IMAGE_NEEDED: "..."}}`.
4. שומרת שני קבצים ב-`Output/`: `.md` ו-`.html` עצמאי (RTL, CSS פנימי).
5. מחזירה לראובן סיכום + רשימת ה-placeholders עבור [[agent-yuval]].

## למי משויך

הסוכנת יעל. מופעלת על ידי [[agent-reuven]].

## קבצים קשורים

- [[agent-reuven]] — מי שמפעיל אותה
- [[yael-style-guide]] — מדריך הסגנון שהיא קוראת
- [[yael-reference-readme]] — דוגמאות סגנון שהיא לומדת מהן
- [[content-readme]] — מקור חומרי הגלם שלה
- [[output-readme]] — היעד לתוצרים שלה
- [[agent-yuval]] — מקבל את ה-`{{IMAGE_NEEDED}}` שהיא מסמנת
- [[output-zone-defense]] — דוגמה לתוצר מוגמר שלה
