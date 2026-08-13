#!/usr/bin/env python3
"""Diff two `dump_visual.lua` artifacts.

    compare.py layout  lvim.json lazy.json      # options that move glyphs
    compare.py theme   lvim.json lazy.json [n]  # highlight groups that differ
    compare.py group   lvim.json lazy.json Normal Comment ...

Exit status is 1 when anything differs, so this can gate the suite.
"""

import json
import re
import sys

# Groups nobody sees: plugin-private namespaces that exist in one config only.
IGNORE_PREFIXES = (
    "Lazy", "Noice", "Snacks", "Blink", "Avante", "Octo", "Trouble", "WhichKey",
    "Telescope", "NvimTree", "Alpha", "Minimap", "Navic", "Outline", "GrugFar",
    "Mason", "Notify", "Rainbow", "IndentBlankline", "Illuminate", "Flash",
    "MiniIndentscope", "BufferLine", "Headline", "RenderMarkdown", "Ibl",
    "Lir", "Dap", "Neotest", "Aerial", "Cmp", "Luasnip", "Fidget", "Toggleterm",
    "Sayonara", "Accordion", "Persistence", "TS", "Playground", "Colorizer",
)

# The furniture a user actually looks at all day, checked first and always.
CORE = [
    "Normal", "NormalNC", "NormalFloat", "FloatBorder", "Comment", "String",
    "Character", "Number", "Boolean", "Function", "Identifier", "Keyword",
    "Statement", "Conditional", "Repeat", "Operator", "Type", "Constant",
    "PreProc", "Special", "Todo", "Error", "ErrorMsg", "WarningMsg", "MoreMsg",
    "ModeMsg", "Question", "Title", "Directory", "CursorLine", "CursorLineNr",
    "LineNr", "SignColumn", "FoldColumn", "Folded", "ColorColumn", "Visual",
    "VisualNOS", "Search", "IncSearch", "CurSearch", "MatchParen", "Pmenu",
    "PmenuSel", "PmenuSbar", "PmenuThumb", "StatusLine", "StatusLineNC",
    "TabLine", "TabLineSel", "TabLineFill", "WinSeparator", "VertSplit",
    "NonText", "Whitespace", "SpecialKey", "EndOfBuffer", "Conceal",
    "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "Cursor", "TermCursor",
    "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint",
    "DiagnosticUnderlineError", "DiagnosticUnderlineWarn", "DiagnosticVirtualTextError",
    "@variable", "@function", "@keyword", "@string", "@comment", "@type",
    "@constant", "@property", "@field", "@parameter", "@operator", "@punctuation.bracket",
    "@punctuation.delimiter", "@constructor", "@number", "@boolean", "@label",
    "@function.call", "@method", "@variable.builtin", "@type.builtin",
]


# lualine numbers a highlight group per component in load order, so the same
# component is `lualine_y_21_normal` in one editor and `lualine_y_23_normal` in
# the other. The rendered statusline is compared instead, by cmd_layout.
LUALINE_INDEXED = re.compile(r"^lualine_[a-z]_\d+")


def load(path):
    with open(path) as fd:
        return json.load(fd)


def fmt(attrs):
    if not attrs:
        return "(undefined)"
    bits = []
    for key in ("fg", "bg", "sp"):
        if attrs.get(key):
            bits.append(f"{key}={attrs[key]}")
    for key in ("bold", "italic", "underline", "undercurl", "reverse", "strikethrough"):
        if attrs.get(key):
            bits.append(key)
    return " ".join(bits) or "(cleared)"


def visible(attrs):
    """Only the parts a screen shows: link names and other bookkeeping are not."""
    if not attrs:
        return None
    return {
        k: v
        for k, v in attrs.items()
        if k != "link" and v not in (None, False)
    }


def normalise(key, value):
    """lualine numbers its generated highlight groups in load order, so
    `lualine_a_3_normal` and `lualine_a_5_normal` are the same group drawn the
    same way. The digits are internal; strip them before comparing."""
    if key in ("statusline", "winbar", "tabline") and isinstance(value, str):
        return re.sub(r"_\d+", "_N", value)
    return value


def cmd_layout(a, b):
    diffs = 0
    print(f"{'OPTION':<16} {'lvim':<34} lazyvim")
    for key in sorted(set(a["layout"]) | set(b["layout"])):
        va, vb = a["layout"].get(key), b["layout"].get(key)
        if normalise(key, va) == normalise(key, vb):
            continue
        diffs += 1
        print(f"{key:<16} {str(va)[:34]:<34} {str(vb)[:44]}")
    print(f"\n{diffs} layout option(s) differ")
    return 1 if diffs else 0


def cmd_theme(a, b, limit=60):
    ga, gb = a["groups"], b["groups"]
    core_diffs, shared_diffs, one_sided = [], [], []
    for name in sorted(set(ga) | set(gb)):
        va, vb = visible(ga.get(name)), visible(gb.get(name))
        if va == vb:
            continue
        if name in CORE:
            core_diffs.append((name, ga.get(name), gb.get(name)))
        elif va is None or vb is None:
            # A group only one editor defines, because only one has the plugin
            # that names it. Nothing to match: the palette behind it is shared.
            one_sided.append(name)
        elif not name.startswith(IGNORE_PREFIXES) and not LUALINE_INDEXED.match(name):
            shared_diffs.append((name, ga.get(name), gb.get(name)))

    print(f"colourscheme: lvim={a.get('colorscheme')} lazyvim={b.get('colorscheme')}")
    print(f"\nCORE groups differing: {len(core_diffs)}/{len(CORE)}")
    for name, va, vb in core_diffs[:limit]:
        print(f"  {name:<34} lvim: {fmt(va):<44} lazyvim: {fmt(vb)}")
    print(f"\nshared groups differing: {len(shared_diffs)}")
    for name, va, vb in shared_diffs[:limit]:
        print(f"  {name:<34} lvim: {fmt(va):<44} lazyvim: {fmt(vb)}")
    print(f"\ndefined on one side only (not comparable): {len(one_sided)}")
    return 1 if (core_diffs or shared_diffs) else 0


def cmd_group(a, b, names):
    for name in names:
        va, vb = a["groups"].get(name), b["groups"].get(name)
        flag = "same" if visible(va) == visible(vb) else "DIFF"
        print(f"{name:<34} [{flag}]\n    lvim:    {fmt(va)}\n    lazyvim: {fmt(vb)}")
    return 0


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    cmd, a, b = argv[1], load(argv[2]), load(argv[3])
    if cmd == "layout":
        return cmd_layout(a, b)
    if cmd == "theme":
        return cmd_theme(a, b, int(argv[4]) if len(argv) > 4 else 60)
    if cmd == "group":
        return cmd_group(a, b, argv[4:])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
