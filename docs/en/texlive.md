# TeX Live

[简体中文](../zh-CN/texlive.md)

TeX Live is installed from the CachyOS/Arch repository — not from upstream or a
manual tarball — so it rolls with the system and upgrades through the usual
`pacman -Syu`.

## Installed packages

| Package | Role |
|---|---|
| `texlive-basic` | Core format files and the standard engines |
| `texlive-binextra` | Additional binaries such as `latexmk` |
| `texlive-latexrecommended` | Recommended LaTeX packages |
| `texlive-fontsrecommended` | Recommended font families |
| `texlive-xetex` | XeTeX engine support |
| `texlive-langchinese` | Chinese typesetting (`ctex`, `xeCJK`) |

Dependencies pull in `texlive-bin` (the engines and `tlmgr`), `texlive-latex`,
and `texlive-langcjk` automatically.

## Verification

After a restore the engines should be on `PATH`:

```bash
pdflatex --version    # pdfTeX ... (TeX Live 2026/Arch Linux)
xelatex --version     # XeTeX ... (TeX Live 2026/Arch Linux)
latexmk --version
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

`packages/pacman-explicit.txt` lists the six packages above;
`./scripts/install-packages.sh` installs them together with their dependencies,
so a fresh restore gets a working LaTeX toolchain with no extra steps.
