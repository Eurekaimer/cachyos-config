# Zed Math Snippets 手工测试（Markdown）

在 Zed 里打开本文件，按注释中的触发词输入，确认补全与 Tab 跳转。
下面是展开后的结果，可直接用于对照。

## 希腊字母与符号

<!-- @a + Tab → \alpha -->
$\alpha + \beta + \Gamma$

<!-- @l + Tab → \lambda -->
$\lambda + \mu + \nu$

<!-- RR + Tab → \mathbb{R} -->
$\mathbb{R} \subseteq \mathbb{C}$

## 分数、根号、上下标

<!-- ff + Tab：先分子，再分母，最后跳出 -->
$\frac{a+b}{c}$

<!-- sq + Tab -->
$\sqrt{x^2 + y^2}$

<!-- rd + Tab -->
$x^{n+1}$

<!-- bino + Tab -->
$\binom{n}{k}$

## 求和、积分、极限

<!-- sum + Tab：下限 i，初始值 1，上限 n，然后被求和项 -->
$$
\sum_{i=1}^{n} i = \frac{n(n+1)}{2}
$$

<!-- int + Tab -->
$\int_0^1 x^2 \, dx = \frac{1}{3}$

<!-- lim + Tab -->
$$
\lim_{x \to \infty} \frac{1}{x} = 0
$$

## 矩阵与分段函数

<!-- mat + Tab：四个元素依次跳转 -->
$$
\begin{pmatrix}
1 & 2 \\
3 & 4
\end{pmatrix}
$$

<!-- cases + Tab -->
$$
\begin{cases}
x & x > 0 \\
-x & \text{otherwise}
\end{cases}
$$

## 概率

<!-- ev + Tab → \mathbb{E}[...] -->
$\mathbb{E}[X]$

<!-- cond + Tab -->
$\mathbb{P}(A \mid B)$

## 公式模板

<!-- mk + Tab → 一对行内 $ -->
$a^2 + b^2 = c^2$

<!-- dm + Tab → $$ 行间公式 -->
$$
\text{行间公式示例}
$$

## 需要 ctrl-space 的旧触发词

这些前缀以标点结尾，Zed 不会自动弹菜单；输入后按 `ctrl-space`，再按 Tab。

<!-- -> + ctrl-space + Tab → \to -->
$x \to 0$

<!-- => + ctrl-space + Tab → \implies -->
$p \implies q$
