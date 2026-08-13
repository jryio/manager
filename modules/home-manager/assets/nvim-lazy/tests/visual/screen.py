#!/usr/bin/env python3
"""Read `tmux capture-pane -e` output as a grid of coloured cells.

    screen.py show  a.ansi              # every distinct colour pair, with samples
    screen.py rows  a.ansi [n [m]]      # rows n..m as text, with their colours
    screen.py diff  a.ansi b.ansi       # cell-by-cell colour differences

A screenshot is only useful here if the colours are comparable, so each cell is
reduced to (char, fg, bg, attrs) and everything else is thrown away.
"""

import re
import sys
from collections import Counter

SGR = re.compile(r"\x1b\[([0-9;:]*)m")

# tmux writes the 16 ANSI colours as indices; they resolve against the terminal
# palette, which both editors get from the same Ghostty config, so they compare
# as names rather than as hex.
BASIC = {
    30: "black", 31: "red", 32: "green", 33: "yellow", 34: "blue",
    35: "magenta", 36: "cyan", 37: "white", 39: "default",
    90: "brblack", 91: "brred", 92: "brgreen", 93: "bryellow", 94: "brblue",
    95: "brmagenta", 96: "brcyan", 97: "brwhite",
}


class Pen:
    __slots__ = ("fg", "bg", "bold", "italic", "underline", "reverse")

    def __init__(self):
        self.reset()

    def reset(self):
        self.fg = "default"
        self.bg = "default"
        self.bold = self.italic = self.underline = self.reverse = False

    def copy(self):
        p = Pen()
        for s in Pen.__slots__:
            setattr(p, s, getattr(self, s))
        return p

    def key(self):
        attrs = "".join(
            f
            for f, on in (("b", self.bold), ("i", self.italic), ("u", self.underline), ("r", self.reverse))
            if on
        )
        return (self.fg, self.bg, attrs)

    def apply(self, params):
        codes = [int(p) if p else 0 for p in params.split(";")] if params else [0]
        i = 0
        while i < len(codes):
            c = codes[i]
            if c == 0:
                self.reset()
            elif c == 1:
                self.bold = True
            elif c == 3:
                self.italic = True
            elif c == 4:
                self.underline = True
            elif c == 7:
                self.reverse = True
            elif c in (22, 23, 24, 27):
                setattr(self, {22: "bold", 23: "italic", 24: "underline", 27: "reverse"}[c], False)
            elif c in BASIC:
                self.fg = BASIC[c]
            elif c in (40, 49) or 41 <= c <= 47 or 100 <= c <= 107:
                self.bg = BASIC.get(c - 10, "default")
            elif c in (38, 48):
                target = "fg" if c == 38 else "bg"
                if i + 1 < len(codes) and codes[i + 1] == 2:
                    r, g, b = (codes[i + 2], codes[i + 3], codes[i + 4])
                    setattr(self, target, "#%02X%02X%02X" % (r, g, b))
                    i += 4
                elif i + 1 < len(codes) and codes[i + 1] == 5:
                    setattr(self, target, "idx%d" % codes[i + 2])
                    i += 2
            i += 1


def parse(path):
    """-> list of rows, each a list of (char, (fg, bg, attrs))."""
    grid = []
    pen = Pen()
    for line in open(path, encoding="utf-8", errors="replace").read().split("\n"):
        row = []
        pos = 0
        for m in SGR.finditer(line):
            for ch in line[pos : m.start()]:
                row.append((ch, pen.key()))
            pen.apply(m.group(1))
            pos = m.end()
        for ch in line[pos:]:
            row.append((ch, pen.key()))
        grid.append(row)
    return grid


def swatch(key):
    fg, bg, attrs = key
    return f"fg={fg:<9} bg={bg:<9} {attrs or '-'}"


def visible_key(ch, key):
    """What the eye can actually tell apart in this cell.

    A blank cell paints no glyph, so its foreground colour is invisible: alpha
    writes its banner padding in the banner's highlight and snacks writes the
    same spaces in Normal, which is a difference in the escape sequence and not
    on the screen. Underline and reverse do show through a space, so they stay.
    """
    fg, bg, attrs = key
    if ch.strip() == "":
        return ("-", bg, "".join(a for a in attrs if a in "ur"))
    return key


def cmd_show(path):
    grid = parse(path)
    seen = {}
    counts = Counter()
    for row in grid:
        for ch, key in row:
            counts[key] += 1
            if ch != " " and key not in seen:
                seen[key] = ch
    print(f"{path}: {len(grid)} rows, {len(counts)} colour pairs")
    for key, n in counts.most_common():
        print(f"  {n:>6} cells  {swatch(key)}  e.g. {seen.get(key, ' ')!r}")


def cmd_rows(path, lo=0, hi=None):
    grid = parse(path)
    hi = len(grid) if hi is None else hi
    for i, row in enumerate(grid[lo:hi], start=lo):
        text = "".join(ch for ch, _ in row).rstrip()
        keys = []
        for _, key in row:
            if not keys or keys[-1] != key:
                keys.append(key)
        print(f"{i:>3} | {text}")
        if text:
            print(f"    +-> {'  |  '.join(swatch(k) for k in keys[:6])}")


def cmd_diff(a_path, b_path):
    a, b = parse(a_path), parse(b_path)
    rows = max(len(a), len(b))
    same_text = 0
    colour_only = Counter()
    text_diff = []
    for r in range(rows):
        ra = a[r] if r < len(a) else []
        rb = b[r] if r < len(b) else []
        ta = "".join(c for c, _ in ra).rstrip()
        tb = "".join(c for c, _ in rb).rstrip()
        if ta == tb:
            same_text += 1
            for c in range(min(len(ra), len(rb))):
                ka = visible_key(*ra[c])
                kb = visible_key(*rb[c])
                if ra[c][0] == rb[c][0] and ka != kb:
                    colour_only[(ka, kb)] += 1
        else:
            text_diff.append((r, ta, tb))

    print(f"rows identical in text: {same_text}/{rows}")
    if colour_only:
        print("\ncolour differences on identical text:")
        for (ka, kb), n in colour_only.most_common(30):
            print(f"  {n:>5} cells  A {swatch(ka)}   ->   B {swatch(kb)}")
    else:
        print("\nno colour differences on identical text")
    if text_diff:
        print(f"\n{len(text_diff)} rows differ in text:")
        for r, ta, tb in text_diff[:25]:
            print(f"  row {r:>3}\n    A: {ta}\n    B: {tb}")
    return 1 if (colour_only or text_diff) else 0


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "show":
        return cmd_show(argv[2]) or 0
    if cmd == "rows":
        lo = int(argv[3]) if len(argv) > 3 else 0
        hi = int(argv[4]) if len(argv) > 4 else None
        return cmd_rows(argv[2], lo, hi) or 0
    if cmd == "diff":
        return cmd_diff(argv[2], argv[3])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
