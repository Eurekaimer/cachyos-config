// demo.typ — 验证生成器输出的 Typst 语法是否可编译
// 每段注释给出触发词；实际内容是展开后的结果（snippets 只能手动触发）

#set page(width: 14cm, height: auto)

// @a  ff  sq  sr
$ alpha + frac(1, 2) + sqrt(x) + y^2 $

// @G  @l  @O  @p
$ Gamma + lambda + Omega + pi $

// sum  prod  int  dint
$ sum_(i=1)^n i = frac(n(n+1), 2) $
$ product_(i=1)^n i = n! $
$ integral_0^1 x^2 dif x = frac(1, 3) $

// iint  iiint  oint  oinf  infi
$ integral.double integral.triple integral.cont $
$ integral_0^oo e^(-x) dif x = 1 $
$ integral_(-oo)^oo e^(-x^2) dif x = sqrt(pi) $

// lim  limt  suplim  inflim
$ lim_(x -> oo) frac(1, x) = 0 $
$ limsup_(n -> oo) a_n $

// ddt  par
$ frac(dif, dif t) + frac(partial y, partial x) $

// mat  pmat  bmat  vmat  matrix  colv
$ mat(1, 2; 3, 4) quad mat(1, 2; 3, 4) quad mat(delim: "[", 1, 2; 3, 4) $
$ mat(delim: "|", 1, 2; 3, 4) quad vec(1, 2) $

// cases
$ cases(x & "if" x > 0, -x & "otherwise") $

// align（Typst 行末单反斜杠换行，& 对齐）
$
  a &= b + c \
  d &= e + f
$

// 花体 / 数集 / 尖括号 / 花括号
$ cal(A) + cal(F) + bb(R) + bb(E) + chevron.l x, y chevron.r + brace.l 1, 2 brace.r $

// 范数、绝对值、取整、迹
$ abs(x) + norm(v) + floor(x) + ceil(x) + "Tr" $

// accents
$ arrow(v) + dot(x) + dot.double(x) + hat(x) + tilde(x) + overline(x) + underline(x) $

// IID（attach 把 iid 放在 ∼ 上方）
$ attach(tilde.op, t: "iid") $

// 概率
$ bb(E)[X] + "Var"[X] + "Cov"(X, Y) + bb(P)(A) + bb(P)(A | B) $

// 关系与箭头
$ plus.minus times dot.op eq.not gt.eq.slant lt.eq.slant approx prop arrow.l.r arrow.r arrow.r.double.long $
