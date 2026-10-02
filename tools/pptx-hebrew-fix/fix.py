# -*- coding: utf-8 -*-
"""Repair a Hebrew PPTX that fakes RTL with Unicode bidi control characters.

Three defects, each fixed at the level it belongs to:
  1. U+202B/U+202C wrappers around Hebrew strings -> removed; RTL is a
     paragraph property, not payload inside the text.
  2. No rtl="1" on any <a:pPr>  -> added to every paragraph holding Hebrew.
  3. lang="en-US" on Hebrew runs -> he-IL, so PowerPoint picks the
     complex-script font and shapes the text as Hebrew.

Fonts are left alone by default: identical metrics means no new overflow.
--swap-fonts rewrites them to Office-safe faces instead.
"""
import glob, os, re, shutil, sys, zipfile

BIDI = dict.fromkeys(map(ord, '‪‫‬‭‮‎‏⁦⁧⁨⁩'), None)
HEB = re.compile(r'[֐-׿]')
# Arial for both: it ships with every Office install, covers Hebrew, and
# Liberation Sans gives us its exact metrics locally, so the swap is
# measurable rather than hoped-for. Secular One is a heavy display face with
# no bold variant, so its runs gain b="1" to keep the weight contrast.
FONT_SWAP = {'Heebo': 'Arial', 'Secular One': 'Arial'}
DISPLAY_FONT = 'Secular One'

stats = {'bidi_removed': 0, 'rtl_added': 0, 'lang_fixed': 0, 'fonts_swapped': 0, 'parts': 0}


def has_heb(xml):
    return bool(HEB.search(''.join(re.findall(r'<a:t[^>]*>(.*?)</a:t>', xml, re.S))))


def fix_para(m):
    """Add rtl="1" to a paragraph that contains Hebrew."""
    whole = m.group(0)
    if not has_heb(whole):
        return whole
    # existing <a:pPr ...> or <a:pPr .../>
    pm = re.search(r'<a:pPr\b([^>]*?)(/?)>', whole)
    if pm:
        attrs, selfclose = pm.group(1), pm.group(2)
        if 'rtl=' in attrs:
            new = pm.group(0).replace('rtl="0"', 'rtl="1"')
        else:
            new = '<a:pPr%s rtl="1"%s>' % (attrs, selfclose)
            stats['rtl_added'] += 1
        whole = whole[:pm.start()] + new + whole[pm.end():]
    else:
        whole = whole.replace('<a:p>', '<a:p><a:pPr rtl="1"/>', 1)
        stats['rtl_added'] += 1
    # endParaRPr language
    whole = re.sub(r'(<a:endParaRPr\b[^>]*?)lang="en-US"', r'\1lang="he-IL"', whole)
    return whole


def fix_run(m):
    """Set lang="he-IL" on a run whose text is Hebrew."""
    whole = m.group(0)
    if not has_heb(whole):
        return whole
    new = re.sub(r'(<a:rPr\b[^>]*?)lang="en-US"', r'\1lang="he-IL"', whole)
    if new != whole:
        stats['lang_fixed'] += 1
    return new


def strip_bidi(m):
    inner = m.group(2)
    clean = inner.translate(BIDI)
    stats['bidi_removed'] += len(inner) - len(clean)
    return m.group(1) + clean + m.group(3)


def bolden_display(m):
    """Carry the display face's weight over to Arial, which needs b="1"."""
    whole = m.group(0)
    if DISPLAY_FONT not in whole:
        return whole
    pm = re.search(r'<a:rPr\b([^>]*?)(/?)>', whole)
    if not pm or re.search(r'\bb="[01]"', pm.group(1)):
        return whole
    new = '<a:rPr%s b="1"%s>' % (pm.group(1), pm.group(2))
    stats['bolded'] = stats.get('bolded', 0) + 1
    return whole[:pm.start()] + new + whole[pm.end():]


def process(xml, swap_fonts):
    xml = re.sub(r'(<a:t[^>]*>)(.*?)(</a:t>)', strip_bidi, xml, flags=re.S)
    xml = re.sub(r'<a:p>.*?</a:p>', fix_para, xml, flags=re.S)
    xml = re.sub(r'<a:r>.*?</a:r>', fix_run, xml, flags=re.S)
    if swap_fonts:
        xml = re.sub(r'<a:r>.*?</a:r>', bolden_display, xml, flags=re.S)
        for old, new in FONT_SWAP.items():
            n = xml.count('typeface="%s"' % old)
            if n:
                xml = xml.replace('typeface="%s"' % old, 'typeface="%s"' % new)
                stats['fonts_swapped'] += n
    return xml


def main(src, dst, swap_fonts=False):
    work = dst + '.unpacked'
    shutil.rmtree(work, ignore_errors=True)
    with zipfile.ZipFile(src) as z:
        parts = [n for n in z.namelist() if not n.endswith('/')]
        data = {n: z.read(n) for n in parts}

    for name in parts:
        if not name.startswith('ppt/') or not name.endswith('.xml'):
            continue
        if '/slides/' not in name and '/slideLayouts/' not in name \
           and '/slideMasters/' not in name and '/notesSlides/' not in name:
            continue
        xml = data[name].decode('utf-8')
        new = process(xml, swap_fonts)
        if new != xml:
            data[name] = new.encode('utf-8')
            stats['parts'] += 1

    # deck-wide defaults: a Hebrew deck defaults to RTL, so the inherited
    # lvlNpPr styles in the masters must flip too -- otherwise any text the
    # author adds later in PowerPoint comes back out left-to-right.
    for name in parts:
        if name.endswith(('slideMasters/slideMaster1.xml', 'notesMasters/notesMaster1.xml')):
            x = data[name].decode('utf-8')
            n = x.count('rtl="0"')
            if n:
                data[name] = x.replace('rtl="0"', 'rtl="1"').encode('utf-8')
                stats['rtl_added'] += n

    pres = data['ppt/presentation.xml'].decode('utf-8')
    pres = pres.replace('rtl="0"', 'rtl="1"')
    if swap_fonts:
        for old, new in FONT_SWAP.items():
            pres = pres.replace('typeface="%s"' % old, 'typeface="%s"' % new)
    data['ppt/presentation.xml'] = pres.encode('utf-8')

    # OPC: [Content_Types].xml first, no directory entries
    order = ['[Content_Types].xml'] + [n for n in parts if n != '[Content_Types].xml']
    if os.path.exists(dst):
        os.remove(dst)
    with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as out:
        for n in order:
            out.writestr(n, data[n])
    return stats


if __name__ == '__main__':
    swap = '--swap-fonts' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    s = main(args[0], args[1], swap)
    print("  parts rewritten    : %d" % s['parts'])
    print("  bidi chars removed : %d" % s['bidi_removed'])
    print("  rtl=\"1\" added      : %d paragraphs" % s['rtl_added'])
    print("  lang -> he-IL      : %d runs" % s['lang_fixed'])
    if swap:
        print("  font refs swapped  : %d" % s['fonts_swapped'])
        print("  display runs bolded: %d" % s.get('bolded', 0))
