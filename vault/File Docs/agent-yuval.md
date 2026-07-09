---
file: .claude/agents/yuval.md
owner: יובל
type: agent-subagent
tags:
  - file-doc
  - agent
  - yuval
---

# יובל — מעצב התמונות

> [!info] בקצרה
> הגדרת הסוכן יובל: יוצר תמונות ואיורים דרך הסקיל `gpt-image-gen`, תוך שמירה על עקביות ויזואלית מתיקיית ה-reference, ושומר ב-`yuval/Outputs/`.

## מה הקובץ עושה

מגדיר את יובל כ-subagent עם הכלים `Read, Write, Bash, Glob` (מודל opus). ה-flow שלו:

1. **סורק reference** ב-[[yuval-reference-readme]] ומנתח סגנון/פלטה/קומפוזיציה.
2. מנסח `prompt` אחד באנגלית שמשלב את הבקשה עם הסגנון.
3. מפעיל את [[skill-gpt-image-gen]] כדי לייצר PNG.
4. שומר ב-`yuval/Outputs/` את ה-`.png` + קובץ `.txt` עם ה-prompt.
5. **מאמת** שהקובץ קיים ו-size>0, ומדווח לראובן.

## למי משויך

הסוכן יובל. מופעל על ידי [[agent-reuven]].

## קבצים קשורים

- [[agent-reuven]] — מי שמפעיל אותו
- [[skill-gpt-image-gen]] — הסקיל שהוא מריץ ליצירת התמונה
- [[yuval-reference-readme]] — תמונות ההשראה שהוא לומד מהן
- [[yuval-outputs-readme]] — היעד לתוצרים שלו
- [[yuval-image-horse]] — דוגמה לתוצר שלו
- [[agent-yael]] — מספקת לו את בקשות התמונה (`{{IMAGE_NEEDED}}`)
- [[config-env]] — מכיל את `OPENAI_API_KEY` שהסקיל צורך
