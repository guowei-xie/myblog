---
title: 回归诊断中的强影响点：从标准化残差到影响图
author: xiebro
date: '2026-07-15'
slug: []
categories:
  - R
tags:
  - Regression
  - Diagnostics
  - Influential-Points
math: true
---





在解释性建模里，拟合出一条回归线只是开始。真正的问题往往是：**这条线可信吗？会不会有那么一两条记录，在背后悄悄操纵着整个方程？**《数据科学家的实用统计学》（Bruce、Bruce、Gedeck）第 4 章"回归诊断"给出了一套判断工具——它们不直接关乎预测准确度，却能告诉你模型对数据的拟合到底稳不稳。

本文用一份**模拟数据**把这套诊断量逐一演示出来：每个指标度量什么、经验阈值怎么定、图怎么读、最后怎么据此做决策。主线严格沿用书中这一节的术语与阈值（标准化残差、杠杆值、库克距离，以及本章的招牌可视化——影响图/气泡图）；文末再单开一节，补上书中未涉及、但经典回归诊断教材（如 Montgomery）常用的三个"删除诊断"——DFFITS、DFBETAS、COVRATIO。

## 三种"不正常"的点

开始之前先厘清三个容易混为一谈的概念，它们**彼此并不等价**：

- **离群值（outlier）**：实际 $y$ 与预测值相距很远的记录，表现为**大残差**，是 $y$ 方向上的异常。
- **高杠杆点（high leverage）**：自变量取值远离其余数据的记录，是 $x$ 方向上的异常。书里把杠杆定义为"单条记录对回归方程所产生影响的大小"。
- **强影响点（influential point）**：书中的定义是——"一个值一旦缺失就会显著改变回归方程"。关键在于，这样的点**未必**伴随大残差。

一个点可以是高杠杆却毫无影响；也可以残差很大却撼动不了方程。真正危险的，是那种"既在 $x$ 方向极端、又偏离趋势"的点。下面我们就人为造出这三类点，看各个指标分别能抓住谁。

## 模拟数据

构造一个一元线性回归的样本——一元的好处是能直接在散点图上画出回归线、肉眼看到"线被带偏"。这些诊断量对多元回归同样适用，只是无法再用一张二维散点图直观呈现。

真实关系设为 $y = 3 + 1.5x + \varepsilon$，先生成 40 个"干净"的点，再刻意植入三个特殊点 A、B、C：


``` r
library(tidyverse)
set.seed(2026)

n_base  <- 40
x_base  <- runif(n_base, 4, 12)
y_base  <- 3 + 1.5 * x_base + rnorm(n_base, 0, 1.2)
base    <- tibble(x = x_base, y = y_base, label = "normal")

# B：x 居中、y 大幅偏离 —— 离群点
# C：x 偏大、y 明显偏离趋势 —— 强影响点
xB <- 7;  yB <- 3 + 1.5 * xB + 9
xC <- 13; yC <- 7

# A：x 最极端（高杠杆），但 y 落在"其余数据所隐含的那条线"上 —— 顺趋势
# 这样它虽然杠杆最高，加入后几乎不改变方程，是"好杠杆点"的典型
rest    <- bind_rows(base, tibble(x = c(xB, xC), y = c(yB, yC), label = c("B", "C")))
xA      <- 17
yA      <- as.numeric(predict(lm(y ~ x, data = rest),
                              newdata = tibble(x = xA))) + 0.6

special <- tibble(label = c("A", "B", "C"),
                  x = c(xA, xB, xC),
                  y = c(yA, yB, yC))

dat <- bind_rows(base, special) |> mutate(obs = row_number())
n   <- nrow(dat)   # 样本量
p   <- 1           # 预测变量个数（系数个数为 p + 1）
```

先拟合全量回归，并和"剔除 C 之后"的回归放在一张图上对比：


``` r
fit    <- lm(y ~ x, data = dat)
fit_noC <- lm(y ~ x, data = filter(dat, label != "C"))

pts <- dat |>
  mutate(kind = recode(label,
                       normal = "normal",
                       A = "A: high leverage",
                       B = "B: outlier",
                       C = "C: influential"))

lab_pts <- filter(pts, label != "normal")

ggplot(pts, aes(x, y)) +
  geom_point(data = filter(pts, label == "normal"),
             color = palette_blog["ash"], size = 2, alpha = 0.8) +
  geom_abline(intercept = coef(fit)[1], slope = coef(fit)[2],
              color = palette_blog["blue"], linewidth = 0.9) +
  geom_abline(intercept = coef(fit_noC)[1], slope = coef(fit_noC)[2],
              color = palette_blog["rose"], linewidth = 0.9, linetype = 2) +
  geom_point(data = lab_pts, aes(color = kind), size = 3.4) +
  geom_text(data = lab_pts, aes(label = label, color = kind),
            vjust = -1, fontface = "bold", show.legend = FALSE) +
  annotate("text", x = 15.5, y = 27, label = "fit: all data",
           color = palette_blog["blue"], hjust = 0, size = 3.4) +
  annotate("text", x = 15.5, y = 23.2, label = "fit: without C",
           color = palette_blog["rose"], hjust = 0, size = 3.4) +
  scale_color_manual(values = unname(palette_blog[c("sage", "gold", "rose")])) +
  labs(title = "Three kinds of unusual points",
       subtitle = "Dropping the single point C visibly rotates the regression line",
       x = "x", y = "y", color = NULL) +
  theme_blog()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig-scatter-1.png" alt="" width="888" />

三个点各司其职：**A** 在最右端（$x$ 极端），但正好落在其余点隐含的那条线上；**B** 的 $x$ 很普通，却高高地偏离；**C** 的 $x$ 偏大、$y$ 又明显偏低。注意实线（全量）与虚线（剔除 C）之间的夹角——只删掉 C 一个点，斜率就从 1.05 跳到 1.33。这正是书中图 4-5 想说的：**一个点能不能左右回归线，和它残差大不大，是两回事。**

下面把五个诊断量一次性算出来备用。它们全部来自 base R，无需额外依赖：


``` r
d <- dat |>
  mutate(
    hat       = hatvalues(fit),
    std_resid = rstandard(fit),
    cooks     = cooks.distance(fit),
    dffits    = dffits(fit),
    covratio  = covratio(fit)
  )

thr <- list(
  hat     = 2 * (p + 1) / n,          # 杠杆值阈值
  cooks   = 4 / (n - p - 1),          # 库克距离阈值
  dffits  = 2 * sqrt((p + 1) / n),    # DFFITS 阈值
  dfbetas = 2 / sqrt(n),              # DFBETAS 阈值
  covr    = 3 * (p + 1) / n           # COVRATIO 阈值（偏离 1 的幅度）
)
```

为了少写重复代码，先定义一个通用的"索引图"函数——横轴是观测序号，纵轴是某个诊断量，把 A/B/C 三点高亮出来：


``` r
hl <- c(normal = unname(palette_blog["ash"]),
        A = unname(palette_blog["sage"]),
        B = unname(palette_blog["gold"]),
        C = unname(palette_blog["rose"]))

index_plot <- function(df, yvar, title, ylab, hlines) {
  ggplot(df, aes(obs, .data[[yvar]])) +
    geom_hline(yintercept = hlines, linetype = 2,
               color = palette_blog["ink"], linewidth = 0.4) +
    geom_segment(aes(xend = obs, yend = 0, color = label), linewidth = 0.4) +
    geom_point(aes(color = label, size = label != "normal")) +
    geom_text(data = filter(df, label != "normal"),
              aes(label = label, color = label),
              vjust = -0.9, fontface = "bold", size = 3.4, show.legend = FALSE) +
    scale_color_manual(values = hl, guide = "none") +
    scale_size_manual(values = c(1.6, 3), guide = "none") +
    labs(title = title, x = "observation index", y = ylab) +
    theme_blog()
}
```

## 指标一 · 标准化残差：抓离群值

标准化残差是残差除以它自己的标准误，可以读作"偏离回归线多少个标准误"：

$$
r_i = \frac{e_i}{\hat\sigma \sqrt{1 - h_{ii}}}
$$

书中用它判定离群值，经验阈值是 $\pm 2.5$。在 R 里用 `rstandard()`：


``` r
index_plot(d, "std_resid",
           "Standardized residuals catch the outlier",
           "standardized residual", hlines = c(-2.5, 2.5))
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig-stdresid-1.png" alt="" width="888" />

**B** 冲出了 $\pm 2.5$ 的红线（3.26），**C** 更是低到 -4.88。但请注意 **A**：它的标准化残差只有 0.18，完全正常。**标准化残差只看 $y$ 方向的偏离，对"藏在 $x$ 极端处"的高杠杆点 A 视而不见。**

## 指标二 · 杠杆值：抓 x 方向的极端

杠杆值来自帽子矩阵。多元回归可写成 $\hat{Y} = HY$，其中

$$
H = X (X^{\top} X)^{-1} X^{\top}
$$

被称作帽子矩阵（它给 $Y$"戴上帽子"变成 $\hat{Y}$）。它的对角线元素 $h_{ii}$ 就是第 $i$ 个观测的杠杆值，衡量该点自变量取值有多"极端"。书中的经验法则是：超过 $2(p+1)/n$ 即为高杠杆。R 里用 `hatvalues()`：


``` r
index_plot(d, "hat",
           "Leverage catches the extreme-x points",
           "leverage (hat value)", hlines = thr$hat)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig-leverage-1.png" alt="" width="888" />

这次换成 **A** 和 **C** 越线，而残差巨大的 **B** 却贴在底部——它的 $x$ 太普通了。杠杆值**完全不看响应变量 $y$**，只问"$x$ 有多极端"。可见它和标准化残差恰好互补：一个管 $x$，一个管 $y$，**但两者单独都不足以判断'影响'。**

## 指标三 · 库克距离：抓真正的强影响点

库克距离（Cook's distance）把前两者**合二为一**——它同时吃进残差大小与杠杆：

$$
D_i = \frac{r_i^{2}}{p + 1} \cdot \frac{h_{ii}}{1 - h_{ii}}
$$

直觉上，只有"残差大 **且** 杠杆高"的点，$D_i$ 才会同时被两个因子放大。书中给的经验阈值是 $4/(n - p - 1)$。R 里用 `cooks.distance()`：


``` r
index_plot(d, "cooks",
           "Cook's distance isolates the truly influential point",
           "Cook's distance", hlines = thr$cooks)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig-cooks-1.png" alt="" width="888" />

结果一目了然：**C 一骑绝尘**（$D_C =$ 1.74），把阈值线远远甩在下面；**B** 只是勉强越线（残差大但杠杆低）；而杠杆最高的 **A**，库克距离几乎是 0（0.008）——**因为它顺着趋势，删掉它方程根本不动。** 这就是"高杠杆 ≠ 强影响"最干净的证据。

## 影响图：一张图看全

书中这一节的招牌可视化，是把**标准化残差、杠杆值、库克距离**三者塞进同一张图——横轴放杠杆值，纵轴放标准化残差，**点的大小随库克距离变化**，库克距离超阈值的点用实心圆。这就是所谓的**影响图**（influence plot），也叫**气泡图**（bubble plot）。这里复刻书中图 4-6：


``` r
d <- d |> mutate(flagged = cooks > thr$cooks)

ggplot(d, aes(hat, std_resid)) +
  geom_hline(yintercept = c(-2.5, 2.5), linetype = 2,
             color = palette_blog["ash"], linewidth = 0.4) +
  geom_vline(xintercept = thr$hat, linetype = 2,
             color = palette_blog["ash"], linewidth = 0.4) +
  geom_point(aes(size = cooks, fill = flagged, color = flagged),
             shape = 21, alpha = 0.75) +
  geom_text(data = filter(d, label != "normal"),
            aes(label = label), fontface = "bold",
            vjust = -1.1, size = 3.6, color = palette_blog["ink"]) +
  scale_size_area(max_size = 13, guide = "none") +
  scale_fill_manual(values = c(`TRUE` = unname(palette_blog["rose"]),
                               `FALSE` = "white"), guide = "none") +
  scale_color_manual(values = c(`TRUE` = unname(palette_blog["rose"]),
                                `FALSE` = unname(palette_blog["ash"])),
                     guide = "none") +
  annotate("text", x = thr$hat, y = 4.6,
           label = "leverage threshold", hjust = -0.05,
           color = palette_blog["ash"], size = 3.2) +
  coord_cartesian(ylim = c(-6.4, 5), clip = "off") +
  labs(title = "Influence (bubble) plot",
       subtitle = "x = leverage, y = standardized residual, bubble area = Cook's distance",
       x = "leverage (hat value)", y = "standardized residual") +
  theme_blog()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig-bubble-1.png" alt="" width="888" />

怎么读这张图？

- **横轴越靠右**，杠杆越高；**纵轴越远离 0**，残差越大；**气泡越大**，库克距离越大（影响越强）。
- **C** 落在右下方，又高杠杆又大负残差，气泡最大且填成实心——**一眼锁定的强影响点**。
- **B** 在左上：残差大（越过了 $y=2.5$）但紧贴左侧，杠杆低，气泡不大——**只是个离群点**。
- **A** 在最右侧、贴着 $y=0$：杠杆最高，但残差近乎为零，气泡小到几乎看不见——**高杠杆，零影响**。

一句话：**真正该警惕的，是那些又靠右、又远离中线、气泡又大的点。**

## 剔除强影响点，方程变了多少

诊断出 C 之后，最实在的检验就是把它删掉，看系数变化多大——这对应书中的表 4-2：


``` r
comp <- tibble(
  term       = c("Intercept (b0)", "Slope (b1)"),
  full       = round(coef(fit), 2),
  without_C  = round(coef(fit_noC), 2)
) |>
  mutate(change_pct = round((without_C - full) / abs(full) * 100, 1))

knitr::kable(comp, col.names = c("Coefficient", "All data", "Without C", "Change (%)"),
             align = "lrrr")
```



|Coefficient    | All data| Without C| Change (%)|
|:--------------|--------:|---------:|----------:|
|Intercept (b0) |     6.08|      4.42|      -27.3|
|Slope (b1)     |     1.05|      1.33|       26.7|

斜率从 1.05 抬到 1.33（约 +26%），截距也大幅回落——**单单一个点，就足以改写"$x$ 每增加一个单位、$y$ 平均变化多少"这个核心结论。** 在小样本里，这种事必须查清楚：是录入错误？是量纲不一致？还是一笔本就不该纳入的异常记录？

> 书中也提醒：对**大数据**里的预测型回归，单个点几乎不可能有这么大权重，识别强影响点意义有限；但在**异常检测**场景里，找出这种点恰恰是全部目的所在。

## 书外延伸：删除诊断三兄弟

到这里，书中这一节的内容就讲完了。不过实务中还有三个更细的诊断量常被用到——它们不在本书范围内，属于经典回归诊断教材（如 Montgomery《线性回归分析导论》）的标准配置。三者共享同一个思想：**删掉第 $i$ 个点，重新拟合，看某个量变化了多少。** R 里一行 `influence.measures(fit)` 就能把它们全部算出来，这里为了对照阈值分开计算。

**DFFITS** 度量删掉第 $i$ 点后，**它自己的拟合值**变化了多少个标准误：

$$
\text{DFFITS}_i = \frac{\hat{y}_i - \hat{y}_{(i)}}{\hat\sigma_{(i)} \sqrt{h_{ii}}}
$$

经验阈值 $2\sqrt{(p+1)/n}$。它和库克距离高度相关，可看作后者"针对单点自身拟合值"的视角。

**DFBETAS** 更细，度量删掉第 $i$ 点后，**每个回归系数**各自变化了多少个标准误：

$$
\text{DFBETAS}_{j,i} = \frac{\hat\beta_j - \hat\beta_{j(i)}}{\hat\sigma_{(i)} \sqrt{(X^{\top} X)^{-1}_{jj}}}
$$

经验阈值 $2/\sqrt{n}$。它的独特价值是**能定位到具体系数**——告诉你这个点到底动了哪一个 $\beta$：


``` r
dfb <- dfbetas(fit) |>
  as_tibble() |>
  rename(`Intercept (b0)` = `(Intercept)`, `Slope (b1)` = x) |>
  mutate(obs = dat$obs, label = dat$label) |>
  pivot_longer(c(`Intercept (b0)`, `Slope (b1)`),
               names_to = "coef", values_to = "dfbetas")

ggplot(dfb, aes(obs, dfbetas)) +
  geom_hline(yintercept = c(-thr$dfbetas, thr$dfbetas), linetype = 2,
             color = palette_blog["ink"], linewidth = 0.4) +
  geom_segment(aes(xend = obs, yend = 0, color = label), linewidth = 0.4) +
  geom_point(aes(color = label, size = label != "normal")) +
  geom_text(data = filter(dfb, label != "normal"),
            aes(label = label, color = label),
            vjust = -0.7, fontface = "bold", size = 3, show.legend = FALSE) +
  scale_color_manual(values = hl, guide = "none") +
  scale_size_manual(values = c(1.4, 2.6), guide = "none") +
  facet_wrap(~ coef) +
  labs(title = "DFBETAS pinpoints which coefficient a point distorts",
       x = "observation index", y = "DFBETAS") +
  theme_blog()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig-dfbetas-1.png" alt="" width="888" />

两个面板里都是 **C** 冲得最远——它同时把截距和斜率拽出了阈值带，而 A、B 基本安分。这与前面"删掉 C 系数剧变"的结论完全吻合。

**COVRATIO** 换了个角度，度量删掉第 $i$ 点后，**系数估计的精度**（协方差矩阵行列式）变化多少：

$$
\text{COVRATIO}_i = \frac{\det\big(\hat\sigma_{(i)}^{2} (X_{(i)}^{\top} X_{(i)})^{-1}\big)}{\det\big(\hat\sigma^{2} (X^{\top} X)^{-1}\big)}
$$

经验阈值是偏离 1 的幅度超过 $3(p+1)/n$，即 $\lvert \text{COVRATIO}_i - 1 \rvert \ge 3(p+1)/n$。它的读法很特别：

- $\text{COVRATIO}_i > 1$：删掉该点会让估计**变差**——说明它是个**提升精度的"好"点**；
- $\text{COVRATIO}_i < 1$：删掉该点会让估计**变好**——说明它在**拖累精度**。


``` r
band <- c(1 - thr$covr, 1 + thr$covr)
ggplot(d, aes(obs, covratio)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = band[1], ymax = band[2],
           fill = palette_blog["ash"], alpha = 0.15) +
  geom_hline(yintercept = 1, linetype = 2,
             color = palette_blog["ink"], linewidth = 0.4) +
  geom_point(aes(color = label, size = label != "normal")) +
  geom_text(data = filter(d, label != "normal"),
            aes(label = label, color = label),
            vjust = -0.9, fontface = "bold", size = 3.4, show.legend = FALSE) +
  scale_color_manual(values = hl, guide = "none") +
  scale_size_manual(values = c(1.6, 3), guide = "none") +
  labs(title = "COVRATIO separates good leverage from bad",
       subtitle = "Above the band = improves precision; below = hurts precision",
       x = "observation index", y = "COVRATIO") +
  theme_blog()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig-covratio-1.png" alt="" width="888" />

这张图最有意思：前面所有指标都对 **A** 网开一面，唯独 COVRATIO 把它拎了出来——A 的 COVRATIO 高达 1.56（远在带子上方），意思是**这个高杠杆点其实在帮你稳住估计，删了反而更不准**，是名副其实的"好杠杆点"。而 **C** 掉到 0.21（带子下方很远），删掉它精度会明显改善——**坏点实锤**。

最后把三个点在全部指标上的表现汇成一张对照表，看"哪种点被哪个指标抓住"：


``` r
mark <- function(cond) ifelse(cond, "✔", "–")

summ <- d |>
  filter(label != "normal") |>
  transmute(
    Point            = label,
    `Std. residual`  = mark(abs(std_resid) > 2.5),
    `Leverage`       = mark(hat > thr$hat),
    `Cook's D`       = mark(cooks > thr$cooks),
    DFFITS           = mark(abs(dffits) > thr$dffits),
    COVRATIO         = mark(abs(covratio - 1) > thr$covr)
  )

knitr::kable(summ, align = "lccccc")
```



|Point | Std. residual | Leverage | Cook's D | DFFITS | COVRATIO |
|:-----|:-------------:|:--------:|:--------:|:------:|:--------:|
|A     |      –       |    ✔     |    –    |   –   |    ✔     |
|B     |       ✔       |    –    |    ✔     |   ✔    |    ✔     |
|C     |       ✔       |    ✔     |    ✔     |   ✔    |    ✔     |

- **A（高杠杆点）**：只被 COVRATIO 标记，且是"好"的那种——其余指标都判它无害。
- **B（离群点）**：残差类指标抓得住，杠杆类指标漏掉它。
- **C（强影响点）**：几乎被所有指标同时点名——这才是真正要动手处理的对象。

## 小结

回归诊断这一套指标，各有各的"视角"：

- **标准化残差**盯 $y$ 方向的偏离（离群值）；
- **杠杆值**盯 $x$ 方向的极端；
- **库克距离 / DFFITS**把两者合起来，度量综合影响，锁定强影响点；
- **DFBETAS**进一步定位到"动了哪个系数"；
- **COVRATIO**换到"估计精度"的维度，还能区分好杠杆与坏杠杆。

实践上有个顺手的顺序：**先看影响图**一眼扫出可疑的大气泡 → **用删除诊断**（DFBETAS）查它到底扰动了哪个系数、扰动多大 → **结合业务判断**是修正、剔除还是保留。别忘了书里的提醒：小样本里单点足以改写结论，务必查清；而在大数据的预测任务里，与其纠结单点，不如把"识别强影响点"的力气留给真正需要它的异常检测场景。
