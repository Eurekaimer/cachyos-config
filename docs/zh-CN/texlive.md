# TeX Live

[English](../en/texlive.md)

TeX Live 直接以 CachyOS/Arch 仓库软件包安装——不从上游手动打包、不下载
tarball——随系统滚动，通过常规 `pacman -Syu` 升级。

## 已安装的软件包

| 软件包 | 作用 |
|---|---|
| `texlive-basic` | 核心格式文件与标准引擎 |
| `texlive-binextra` | 附加二进制工具，如 `latexmk` |
| `texlive-latexrecommended` | 推荐 LaTeX 宏包 |
| `texlive-fontsrecommended` | 推荐字体族 |
| `texlive-xetex` | XeTeX 引擎支持 |
| `texlive-langchinese` | 中文排版支持（`ctex`、`xeCJK`） |

`texlive-bin`（引擎与 `tlmgr`）、`texlive-latex`、`texlive-langcjk` 作为依赖
自动带入。

## 验证

恢复后各引擎应已在 `PATH` 中：

```bash
pdflatex --version    # pdfTeX ... (TeX Live 2026/Arch Linux)
xelatex --version     # XeTeX ... (TeX Live 2026/Arch Linux)
latexmk --version
lualatex --version
tlmgr --version
```

## 中文文档

中文排版使用 `xelatex` 配合系统中文字体（Noto Sans CJK 已安装）。`ctex`
文档类可直接使用：

```bash
printf '\\documentclass[UTF8]{ctexart}\n\\begin{document}\n你好，世界。\n\\end{document}\n' > /tmp/hello.tex
xelatex /tmp/hello.tex    # 生成 /tmp/hello.pdf
```

## 恢复行为

`packages/pacman-explicit.txt` 收录上表六个软件包；`./scripts/install-packages.sh`
会连同依赖一起安装，全新恢复即可得到可用的 LaTeX 工具链，无需额外步骤。
