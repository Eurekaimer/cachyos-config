-- Markdown-only TeX snippets. `mk` and `dm` auto-expand; the rest expand with Tab.
local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmta
local i = ls.insert_node
local s = ls.snippet

local snippets = {
  s({ trig = "fr", name = "fraction" }, fmt([[\frac{<>}{<>}<>]], { i(1), i(2), i(0) })),
  s({ trig = "sq", name = "square root" }, fmt([[\sqrt{<>}<>]], { i(1), i(0) })),
  s({ trig = "sum", name = "summation" }, fmt([[\sum_{<>=<>}^{<>} <><>]], {
    i(1, "i"),
    i(2, "1"),
    i(3, "n"),
    i(4),
    i(0),
  })),
  s({ trig = "int", name = "integral" }, fmt([[\int_{<>}^{<>} <> \,\mathrm{d}<><>]], {
    i(1, "a"),
    i(2, "b"),
    i(3, "f(x)"),
    i(4, "x"),
    i(0),
  })),
  s({ trig = "lim", name = "limit" }, fmt([[\lim_{<> \to <>} <><>]], {
    i(1, "x"),
    i(2, "0"),
    i(3),
    i(0),
  })),
  s({ trig = "vec", name = "vector" }, fmt([[\vec{<>}<>]], { i(1), i(0) })),
  s({ trig = "bf", name = "bold math" }, fmt([[\mathbf{<>}<>]], { i(1), i(0) })),
  s({ trig = "lr", name = "auto-sized parentheses" }, fmt([[\left( <> \right)<>]], { i(1), i(0) })),
  s({ trig = "mat", name = "2x2 matrix" }, fmt([[
\begin{bmatrix}
  <> & <> \\
  <> & <>
\end{bmatrix}<>
]], { i(1, "a"), i(2, "b"), i(3, "c"), i(4, "d"), i(0) })),
  s({ trig = "cases", name = "piecewise cases" }, fmt([[
\begin{cases}
  <> & <>, \\
  <> & <>.
\end{cases}<>
]], { i(1), i(2, "condition"), i(3), i(4, "otherwise"), i(0) })),
  s({ trig = "aln", name = "aligned equations" }, fmt([[
$$
\begin{aligned}
  <> &= <> \\
  <> &= <>
\end{aligned}
$$<>
]], { i(1), i(2), i(3), i(4), i(0) })),
}

local autosnippets = {
  s({ trig = "mk", name = "inline math", wordTrig = true }, fmt([[$<>$<>]], { i(1), i(0) })),
  s({ trig = "dm", name = "display math", wordTrig = true }, fmt([[
$$
<>
$$<>
]], { i(1), i(0) })),
}

return snippets, autosnippets
