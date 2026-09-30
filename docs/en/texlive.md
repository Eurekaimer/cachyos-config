# TeX Live

[简体中文](../zh-CN/texlive.md)

TeX Live is installed from the CachyOS/Arch repository — not from upstream or a
manual tarball — so it rolls with the system and upgrades through the usual
`pacman -Syu`.

## Installed packages

| Package | Role |
|---|---|
| `texlive-basic` | Core format files, the standard engines, `tlmgr` |
| `texlive-latex` | Fundamental LaTeX packages (`latex.ltx`) |
| `texlive-latexrecommended` | Recommended LaTeX packages |
| `texlive-langchinese` | Chinese typesetting (`ctex`, `xeCJK`) |

Dependencies pull in `texlive-bin` (the engines and `tlmgr`) and
`texlive-langcjk` automatically, so the four packages above are the complete
Chinese/English set. `texlive-xetex`, `texlive-binextra` and
`texlive-fontsrecommended` are deliberately NOT installed: the `xelatex`
engine and its `xelatex.ini` format definition ship with `texlive-basic`, and
`texlive-xetex` only adds Arabic/Persian font mappings. Add `texlive-binextra`
only if you need `latexmk`.

## Verification

After a restore the engines should be on `PATH`:

```bash
pdflatex --version    # pdfTeX ... (TeX Live 2026/Arch Linux)
xelatex --version     # XeTeX ... (TeX Live 2026/Arch Linux)
lualatex --version
tlmgr --version
```

## Chinese documents

Typeset Chinese with `xelatex` and a system CJK font (Noto Sans CJK is already
installed). The `ctex` document class works out of the box:

```bash
printf '\\documentclass[UTF8]{ctexart}\n\\begin{document}\n你好，世界。\n\\end{document}\n' > /tmp/hello.tex
xelatex /tmp/hello.tex    # -> /tmp/hello.pdf
```

## Restore behavior

`packages/profiles/full.txt` and `packages/profiles/minimal.txt` list the four
packages above;
`./scripts/install-packages.sh` installs them together with their dependencies,
so a fresh restore gets a working LaTeX toolchain with no extra steps.
