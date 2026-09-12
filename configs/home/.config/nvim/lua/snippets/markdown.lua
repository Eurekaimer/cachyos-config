-- Markdown-only snippets: TeX math, Obsidian callouts.
--
-- Ported from the Obsidian LaTeX Suite configuration in
-- `Math/.obsidian/plugins/obsidian-latex-suite/data.json`, which marks almost
-- every math snippet `mA`: math mode only, and expand as soon as the trigger is
-- typed. So the math snippets here are autosnippets gated by `in_math()`, and
-- <Tab> is only for jumping between placeholders and for the few triggers that
-- must stay manual.
--
-- Two rules keep autosnippets from firing too early:
--
-- 1. wordTrig. Triggers made only of letters (`sum`, `eta`, `prod`) need a word
--    boundary, otherwise `beta` would expand into `b` + `\eta`. Triggers
--    containing punctuation (`//`, `lr(`, `@a`) must not require one, or they
--    would never match.
--
-- 2. Prefix conflicts. A trigger that is a strict prefix of a longer one cannot
--    be an autosnippet, because it fires before the longer trigger is finished:
--    typing `aligned` would expand `align` at the sixth character. The longer
--    trigger auto-expands; the shorter stays on <Tab>. Suffix pairs are safe
--    (`ddot` ends with `dot`), and there the longer one wins on `priority`.
--    Deferred to <Tab>: align, lim, mat, par, scr, aln.
--
-- fmta uses `<>` as its placeholder delimiter, so a literal `>` cannot appear in
-- an fmt() format string; callouts are built from text_node instead.
local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node

-- True when the cursor sits inside inline `$...$` or display `$$...$$` math.
-- Display math may span lines, so every line up to the cursor is scanned for
-- unescaped `$$` pairs; inline math cannot span lines, so the current line is
-- then scanned for an odd number of remaining single `$`.
local function in_math()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)

  local display = false
  for index, text in ipairs(lines) do
    if index == row then
      text = text:sub(1, col)
    end
    text = text:gsub("\\%$", "")
    local position = 1
    while true do
      local start = text:find("$", position, true)
      if not start then
        break
      end
      if text:sub(start + 1, start + 1) == "$" then
        display = not display
        position = start + 2
      else
        position = start + 1
      end
    end
  end
  if display then
    return true
  end

  local text = (lines[row] or ""):sub(1, col):gsub("\\%$", "")
  local singles = 0
  local position = 1
  while true do
    local start = text:find("$", position, true)
    if not start then
      break
    end
    if text:sub(start + 1, start + 1) == "$" then
      position = start + 2
    else
      singles = singles + 1
      position = start + 1
    end
  end
  return singles % 2 == 1
end

local function word(trigger)
  return trigger:match("^%a+$") ~= nil
end

-- Math snippet that expands the moment the trigger is typed (LaTeX Suite `mA`).
local function m(trigger, name, nodes, priority)
  return s({
    trig = trigger,
    name = name,
    wordTrig = word(trigger),
    condition = in_math,
    snippetType = "autosnippet",
    priority = priority,
  }, nodes)
end

-- Math snippet that waits for <Tab>: a prefix-crowded trigger, or one LaTeX
-- Suite marks `m` only.
local function tab(trigger, name, nodes)
  return s({
    trig = trigger,
    name = name,
    wordTrig = word(trigger),
    condition = in_math,
  }, nodes)
end

-- Bare environment body, shared by the matrix and environment triggers.
local function environment(default)
  return fmt([[
\begin{<>}
  <>
\end{<>}<>
]], { i(1, default), i(2), rep(1), i(0) })
end

local snippets = {
  -- Build a math block. Ungated: they exist to create `$` / `$$` in the first
  -- place. No LaTeX Suite trigger, so `mk` / `dm` match the original marks
  -- locally and expand with <Tab>.
  tab("mk", "inline math", fmt([[$<>$<>]], { i(1), i(0) })),
  tab("dm", "display math", fmt([[
$$
<>
$$<>
]], { i(1), i(0) })),

  -- Environments. `aligned` auto-expands; `align` and `aln` are its prefixes, so
  -- they stay on <Tab>.
  m("aligned", "aligned environment", environment("aligned")),
  tab("align", "aligned environment", environment("aligned")),
  s({ trig = "aln", name = "aligned equations", condition = in_math }, fmt([[
$$
\begin{aligned}
  <> &= <> \\
  <> &= <>
\end{aligned}
$$<>
]], { i(1), i(2), i(3), i(4), i(0) })),
  m("beg", "environment", fmt([[
\begin{<>}
  <>
\end{<>}<>
]], { i(1, "env"), i(2), rep(1), i(0) })),
  m("pmat", "pmatrix", fmt([[
\begin{pmatrix}
  <>
\end{pmatrix}<>
]], { i(1), i(0) })),
  m("bmat", "bmatrix", fmt([[
\begin{bmatrix}
  <>
\end{bmatrix}<>
]], { i(1), i(0) })),
  m("Bmat", "Bmatrix", fmt([[
\begin{Bmatrix}
  <>
\end{Bmatrix}<>
]], { i(1), i(0) })),
  m("vmat", "vmatrix", fmt([[
\begin{vmatrix}
  <>
\end{vmatrix}<>
]], { i(1), i(0) })),
  m("Vmat", "Vmatrix", fmt([[
\begin{Vmatrix}
  <>
\end{Vmatrix}<>
]], { i(1), i(0) })),
  m("matrix", "matrix", fmt([[
\begin{matrix}
  <>
\end{matrix}<>
]], { i(1), i(0) })),
  tab("mat", "2x2 matrix", fmt([[
\begin{bmatrix}
  <> & <> \\
  <> & <>
\end{bmatrix}<>
]], { i(1, "a"), i(2, "b"), i(3, "c"), i(4, "d"), i(0) })),
  m("cases", "cases", fmt([[
\begin{cases}
  <>
\end{cases}<>
]], { i(1), i(0) })),
  m("arrayenv", "array", fmt([[
\begin{array}
  <>
\end{array}<>
]], { i(1), i(0) })),

  -- Fractions and powers.
  m("//", "fraction", fmt([[\frac{<>}{<>}<>]], { i(1), i(2), i(0) })),
  m("bino", "binomial", fmt([[\binom{<>}{<>}<>]], { i(1), i(2), i(0) })),
  m("sr", "squared", t("^{2}")),
  m("cb", "cubed", t("^{3}")),
  m("rd", "superscript", fmt([[^{<>}<>]], { i(1), i(0) })),
  m("sts", "text subscript", fmt([[_\text{<>}<>]], { i(1), i(0) })),
  m("ee", "exponential", fmt([[e^{ <> }<>]], { i(1), i(0) })),
  m("invs", "inverse", t("^{-1}")),
  m("conj", "complex conjugate", t("^{*}")),

  -- Wrappers. The bare names wrap the next argument.
  m("text", "text environment", fmt([[\text{<>}<>]], { i(1), i(0) })),
  m("rm", "roman", fmt([[\mathrm{<>}<>]], { i(1), i(0) })),
  m("scr", "script", fmt([[\mathscr{<>}<>]], { i(1), i(0) })),
  tab("scrf", "sigma field", t("\\mathscr{F}")),
  m("mathcal", "calligraphic", fmt([[\mathcal{<>}<>]], { i(1), i(0) })),
  m("hat", "hat", fmt([[\hat{<>}<>]], { i(1), i(0) })),
  m("bar", "overline", fmt([[\overline{<>}<>]], { i(1), i(0) })),
  m("Bar", "bar", fmt([[\bar{<>}<>]], { i(1), i(0) })),
  m("ddot", "double dot", fmt([[\ddot{<>}<>]], { i(1), i(0) }), 1100),
  m("dot", "dot", fmt([[\dot{<>}<>]], { i(1), i(0) })),
  m("tilde", "tilde", fmt([[\tilde{<>}<>]], { i(1), i(0) })),
  m("und", "underline", fmt([[\underline{<>}<>]], { i(1), i(0) })),
  m("sete", "set", fmt([[\{ <> \}<>]], { i(1), i(0) })),
  m("mod", "modulus", fmt([[|<>|<>]], { i(1), i(0) })),
  m("avg", "average", fmt([[\langle <> \rangle <>]], { i(1), i(0) })),
  m("norm", "norm", fmt([[\lvert <> \rvert <>]], { i(1), i(0) })),
  m("Norm", "double norm", fmt([[\lVert <> \rVert <>]], { i(1), i(0) })),
  m("ceil", "ceiling", fmt([[\lceil <> \rceil <>]], { i(1), i(0) })),
  m("floor", "floor", fmt([[\lfloor <> \rfloor <>]], { i(1), i(0) })),
  tab("lr", "auto-sized parentheses", fmt([[\left( <> \right)<>]], { i(1), i(0) })),
  m("lr(", "auto-sized parentheses", fmt([[\left( <> \right) <>]], { i(1), i(0) })),
  m("lr[", "auto-sized brackets", fmt([[\left[ <> \right] <>]], { i(1), i(0) })),
  m("lr{", "auto-sized braces", fmt([[\left\{ <> \right\} <>]], { i(1), i(0) })),
  m("lr|", "auto-sized bars", fmt([[\left| <> \right| <>]], { i(1), i(0) })),

  -- Symbols and operators.
  m("**", "center dot", t("\\cdot")),
  m("cdot", "center dot", t("\\cdot")),
  m("xx", "times", t("\\times")),
  m("ooo", "infinity", t("\\infty")),
  m("emp", "empty set", t("\\emptyset")),
  m("eset", "empty set", t("\\emptyset")),
  m("nabl", "nabla", t("\\nabla")),
  m("del", "nabla", t("\\nabla")),
  tab("par", "partial derivative", fmt([[\frac{ \partial <> }{ \partial <> } <>]], {
    i(1, "y"),
    i(2, "x"),
    i(0),
  })),
  m("para", "parallel", t("\\parallel")),
  m("duli", "independent", t("\\mathrel{\\perp\\!\\!\\!\\perp}")),
  m("min", "min", t("\\min")),
  m("max", "max", t("\\max")),
  m("gedeng", "greater or equal", t("\\geqslant")),
  m("ledeng", "less or equal", t("\\leqslant")),
  m("simm", "similar", t("\\sim")),
  m("sim=", "simeq", t("\\simeq")),
  m("prop", "proportional", t("\\propto")),
  m("shuyu", "element of", t("\\in")),
  m("inn", "element of", t("\\in")),
  m("notin", "not element of", t("\\not\\in")),
  m("Re", "real part", t("\\mathrm{Re}")),
  m("Im", "imaginary part", t("\\mathrm{Im}")),
  m("Ker", "kernel", t("\\mathrm{Ker}")),
  m("dim", "dimension", t("\\mathrm{dim}")),
  m("trace", "trace", t("\\mathrm{Tr}")),
  m("LL", "script L", t("\\mathcal{L}")),
  m("HH", "script H", t("\\mathcal{H}")),
  m("AA", "script A", t("\\mathscr{A}")),
  m("RR", "real numbers", t("\\mathbb{R}")),
  m("CC", "complex numbers", t("\\mathbb{C}")),
  m("QQ", "rational numbers", t("\\mathbb{Q}")),
  m("ZZ", "integers", t("\\mathbb{Z}")),
  m("NN", "natural numbers", t("\\mathbb{N}")),
  m("EE", "expectation", t("\\mathbb{E}")),
  m("KK", "field", t("\\mathbb{K}")),
  m("PP", "probability", t("\\mathbb{P}")),
  m("...", "dots", t("\\dots")),
  m("+-", "plus minus", t("\\pm")),
  m("-+", "minus plus", t("\\mp")),
  m("===", "equivalent", t("\\equiv")),
  m("!=", "not equal", t("\\neq")),
  m(">=", "greater or equal", t("\\geqslant")),
  m("<=", "less or equal", t("\\leqslant")),
  m(">>", "much greater", t("\\gg")),
  m("<<", "much less", t("\\ll")),
  m("sub=", "subset or equal", t("\\subseteq")),
  m("sup=", "superset or equal", t("\\supseteq")),
  m("->", "to", t("\\to")),
  m("<->", "leftrightarrow", t("\\leftrightarrow "), 1100),
  m("!>", "mapsto", t("\\mapsto")),
  m("=>", "implies", t("\\implies")),
  m("=<", "implied by", t("\\impliedby")),

  -- Sequences.
  m("xnn", "sequence x_n", t("x_{n}")),
  m("xii", "x_i", t("x_{i}")),
  m("xjj", "x_j", t("x_{j}")),
  m("xp1", "x_{n+1}", t("x_{n+1}")),
  m("ynn", "sequence y_n", t("y_{n}")),
  m("yii", "y_i", t("y_{i}")),
  m("yjj", "y_j", t("y_{j}")),
  m("xdot", "x sequence", t("x_{1},x_{2},\\dots,x_{n}")),
  m("ydot", "y sequence", t("y_{1},y_{2},\\dots,y_{n}")),

  -- Calculus and operators.
  m("sum", "summation", fmt([[\sum\limits_{<>=<>}^{<>} <><>]], {
    i(1, "i"),
    i(2, "1"),
    i(3, "N"),
    i(4),
    i(0),
  })),
  m("prod", "product", fmt([[\prod_{<>=<>}^{<>} <><>]], {
    i(1, "i"),
    i(2, "1"),
    i(3, "N"),
    i(4),
    i(0),
  })),
  m("bigcup", "union", fmt([[\bigcup\limits_{<>=<>}^{<>} <><>]], {
    i(1, "i"),
    i(2, "1"),
    i(3, "\\infty"),
    i(4),
    i(0),
  })),
  m("bigcap", "intersection", fmt([[\bigcap\limits_{<>=<>}^{<>} <><>]], {
    i(1, "i"),
    i(2, "1"),
    i(3, "\\infty"),
    i(4),
    i(0),
  })),
  m("int", "integral", fmt([[\int_{<>}^{<>} <> \, d<> <>]], {
    i(1, "a"),
    i(2, "b"),
    i(3),
    i(4, "x"),
    i(0),
  })),
  m("dint", "definite integral", fmt([[\int_{<>}^{<>} <> \, d<> <>]], {
    i(1, "0"),
    i(2, "1"),
    i(3),
    i(4, "x"),
    i(0),
  })),
  m("oint", "contour integral", t("\\oint")),
  m("iint", "double integral", t("\\iint")),
  m("iiint", "triple integral", t("\\iiint")),
  m("oinf", "integral to infinity", fmt([[\int_{0}^{\infty} <> \, d<> <>]], {
    i(1),
    i(2, "x"),
    i(0),
  })),
  m("infi", "integral over R", fmt([[\int_{-\infty}^{\infty} <> \, d<> <>]], {
    i(1),
    i(2, "x"),
    i(0),
  })),
  m("ddt", "time derivative", t("\\frac{d}{dt} ")),
  m("lim", "limit", fmt([[\lim_{<> \to <>} <><>]], { i(1, "x"), i(2, "0"), i(3), i(0) })),
  tab("limt", "limit", fmt([[\lim\limits_{ <> \to <> } <>]], { i(1, "n"), i(2, "\\infty"), i(0) })),
  m("suplim", "limit superior", fmt([[\varlimsup\limits_{ <> \to <> } <>]], {
    i(1, "n"),
    i(2, "\\infty"),
    i(0),
  })),
  m("inflim", "limit inferior", fmt([[\varliminf\limits_{ <> \to <> } <>]], {
    i(1, "n"),
    i(2, "\\infty"),
    i(0),
  })),
  tab("tayl", "Taylor expansion", fmt([[
<>(<> + <>) = <>(<>) + <>'(<>)<> + <>''(<>) \frac{<>^{2}}{2!} + \dots<>
]], {
    i(1, "f"),
    i(2, "x"),
    i(3, "h"),
    rep(1),
    rep(2),
    rep(1),
    rep(2),
    rep(3),
    rep(1),
    rep(2),
    rep(3),
    i(0),
  })),

  -- Probability and statistics.
  m("measpace", "measurable space", t("(\\Omega,\\mathscr{F})")),
  m("probspace", "probability space", t("(\\Omega,\\mathscr{F},P)")),
  m("IID", "iid", t("\\overset{IID}{\\sim}")),
  m("meato", "implies", t("\\Rightarrow")),
  m("holder", "Hölder", t("H \\ddot{o} lder")),

  -- Greek letters, mirroring the `@` shortcuts.
  m("@a", "alpha", t("\\alpha")),
  m("@b", "beta", t("\\beta")),
  m("@g", "gamma", t("\\gamma")),
  m("@G", "Gamma", t("\\Gamma")),
  m("@d", "delta", t("\\delta")),
  m("@D", "Delta", t("\\Delta")),
  m("@e", "varepsilon", t("\\varepsilon")),
  m("@z", "zeta", t("\\zeta")),
  m("@t", "theta", t("\\theta")),
  m("@T", "Theta", t("\\Theta")),
  m("@i", "iota", t("\\iota")),
  m("@k", "kappa", t("\\kappa")),
  m("@l", "lambda", t("\\lambda")),
  m("@L", "Lambda", t("\\Lambda")),
  m("@s", "sigma", t("\\sigma")),
  m("@S", "Sigma", t("\\Sigma")),
  m("@u", "upsilon", t("\\upsilon")),
  m("@U", "Upsilon", t("\\Upsilon")),
  m("@o", "omega", t("\\omega")),
  m("@O", "Omega", t("\\Omega")),
  m("@m", "mu", t("\\mu")),
  m("@n", "nu", t("\\nu")),
  m("@p", "pi", t("\\pi")),
  m("@r", "rho", t("\\rho")),
  m("@f", "phi", t("\\phi")),
  m("@c", "chi", t("\\chi")),
  m("@x", "xi", t("\\xi")),
  m("@y", "psi", t("\\psi")),
  m(":e", "varepsilon", t("\\varepsilon")),
  m(":t", "vartheta", t("\\vartheta")),
}

-- Obsidian callouts, generated so every type shares one template. Each snippet
-- writes `> [!type] title`, then a quoted body line: the cursor starts there and
-- `fo+=r` adds `> ` to every following line. That line holds only `> `, never a
-- list marker, because `r` re-inserts the recognized leader (including `- [ ] `)
-- on <Enter> and would double it. An empty body line ends the callout; <CR> on
-- it collapses the whole run (see config/keymaps.lua).
local callout_types = {
  "note",
  "tip",
  "important",
  "warning",
  "question",
  "todo",
  "info",
  "success",
  "danger",
  "failure",
  "bug",
  "example",
  "quote",
  "abstract",
  "summary",
  "tldr",
  "hint",
  "caution",
  "attention",
  "cite",
}

for _, kind in ipairs(callout_types) do
  snippets[#snippets + 1] = s({ trig = "callouts-" .. kind, name = "Obsidian " .. kind .. " callout" }, {
    t("> [!" .. kind .. "] "),
    i(1, "title"),
    t({ "", "> " }),
    i(0),
  })
end

-- Autosnippets that are not math-gated: they build the math block itself.
local autosnippets = {
  s({ trig = "mk", name = "inline math", wordTrig = true, snippetType = "autosnippet" }, fmt([[$<>$<>]], {
    i(1),
    i(0),
  })),
  s({ trig = "dm", name = "display math", wordTrig = true, snippetType = "autosnippet" }, fmt([[
$$
<>
$$<>
]], { i(1), i(0) })),
}

return snippets, autosnippets
