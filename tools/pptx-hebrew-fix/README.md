# תיקון מצגות עבריות ל-PowerPoint

מתקן מצגת `.pptx` עברית שמתעוותת ב-PowerPoint בגלל **RTL מדומה** — טקסט
שנעטף בתווי בקרה בלתי-נראים של Unicode במקום להכריז על כיווניות כמאפיין
פסקה. ראו `vault/Meeting Notes/pptx-hebrew-rtl-repair.md` לאבחון המלא.

## מה מתוקן

| פגם | תיקון |
|---|---|
| `U+202B`/`U+202C` עוטפים כל מחרוזת עברית | הסרה מלאה |
| אין `rtl="1"` באף פסקה | נוסף לכל פסקה עברית + לברירות המחדל ב-slideMaster / notesMaster |
| `lang="en-US"` על טקסט עברי | `he-IL`, כדי ש-PowerPoint יבחר את פונט ה-complex-script |
| `[Content_Types].xml` לא ראשון בארכיון, רשומות-תיקייה מיותרות | אריזה מחדש לפי OPC |

## שימוש

```bash
# שמירת הפונטים המקוריים — מטריקות זהות, אפס סיכון גלישה חדש
python3 fix.py deck.pptx fixed.pptx

# החלפה לפונט שקיים בכל Office (Arial), כולל bold לכותרות
python3 fix.py deck.pptx fixed-arial.pptx --swap-fonts

# אחרי --swap-fonts: מקטין רק את הפסקאות שהפונט הרחב דחף לשורה נוספת.
# דורש את קובצי ה-TTF המקוריים תחת ./fonts/ ואת Liberation Sans (מטריקות Arial).
python3 fitpass.py fixed-arial.pptx
```

## אימות

```bash
python3 <skill>/scripts/office/validate.py fixed.pptx --original deck.pptx
```

## אזהרה

`fitpass.py` משווה רוחבי טקסט מטבלאות הפונט, לא מרינדור. זה תופס גלישה
שנובעת מהחלפת פונט, אבל **אינו מחליף בדיקה בעיניים** ב-PowerPoint עצמו.
