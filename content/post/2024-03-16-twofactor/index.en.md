---
title: 因果推断：两种结构比率归因方法
author: Xiebro
date: '2024-03-16'
slug: twofactor
categories:
  - 因果推断
tags:
  - 因果推断
---

在一些工作场景当中，比如渠道广告投放，假如这月与上月相比，总投放转化率出现了差异，那么，作为指导业务决策的数据分析师，我们需要讲清楚：两次投放转化率的差异，有多少是来自于渠道占比变化的结果，又有多少是来自渠道本身转化率波动的结果。

构造一份演示数据：

```r
dat <- data.frame(
  dim = c("A", "B", "C", "D", "E"),            # 渠道名称
  base_prop = c(0.2, 0.3, 0.1, 0.2, 0.2),      # 上月(基期)各渠道用户数量占比
  base_rate = c(0.1, 0.2, 0.15, 0.12, 0.05),    # 上月(基期)各渠道用户转化率
  curr_prop = c(0.25, 0.25, 0.15, 0.2, 0.15),  # 本月(现期)各渠道用户数量占比
  curr_rate = c(0.08, 0.15, 0.09, 0.1, 0.07)  # 本月(现期)各渠道用户转化率
)

dat |> knitr::kable()
```



|dim | base_prop| base_rate| curr_prop| curr_rate|
|:---|---------:|---------:|---------:|---------:|
|A   |       0.2|      0.10|      0.25|      0.08|
|B   |       0.3|      0.20|      0.25|      0.15|
|C   |       0.1|      0.15|      0.15|      0.09|
|D   |       0.2|      0.12|      0.20|      0.10|
|E   |       0.2|      0.05|      0.15|      0.07|

```r
base_cvr <- sum(dat$base_prop * dat$curr_rate)
curr_cvr <-  sum(dat$curr_prop * dat$curr_rate)

cat(paste0("基期总转化率：",    base_cvr,  "\n",
           "现期总转化率：",    curr_cvr,  "\n",
           "Diff(现期-基期)：", curr_cvr - base_cvr, "\n"))
```

```
## 基期总转化率：0.104
## 现期总转化率：0.1015
## Diff(现期-基期)：-0.0025
```

本月与上月相比，转化率下跌了0.25pp，量化其中有几个pp来自于渠道占比变化，又有几个pp来自于渠道率值波动。如此，我们可以对业务进行指导：***调整渠道结构*** or ***优化渠道率值***

---

### Shapley-value：量化结构与率值的贡献度变化

```r
library(dplyr)

# 量化公式
qt_r <- \(r0, r1, p0, p1) (r1 - r0) * (p1 + p0) / 2
qt_p <- \(r0, r1, p0, p1) (p1 - p0) * (r1 + r0) / 2

# 量化结果
result <- 
  dat |>
  mutate(r.eff = qt_r(base_cvr, curr_cvr, base_prop, curr_prop),
         p.eff = qt_p(base_cvr, curr_cvr, base_prop, curr_prop),
         tot.eff = r.eff + p.eff)

result |> knitr::kable()
```



|dim | base_prop| base_rate| curr_prop| curr_rate|      r.eff|      p.eff|   tot.eff|
|:---|---------:|---------:|---------:|---------:|----------:|----------:|---------:|
|A   |       0.2|      0.10|      0.25|      0.08| -0.0005625|  0.0051375|  0.004575|
|B   |       0.3|      0.20|      0.25|      0.15| -0.0006875| -0.0051375| -0.005825|
|C   |       0.1|      0.15|      0.15|      0.09| -0.0003125|  0.0051375|  0.004825|
|D   |       0.2|      0.12|      0.20|      0.10| -0.0005000|  0.0000000| -0.000500|
|E   |       0.2|      0.05|      0.15|      0.07| -0.0004375| -0.0051375| -0.005575|

```r
# 校验：
tot_p.eff <- round(sum(result$p.eff), 4)
tot_r.eff <- round(sum(result$r.eff), 4)

cat(paste0("占比变化影响：", tot_p.eff, "\n",
           "率值波动影响：", tot_r.eff, "\n",
           "占比率值共同影响：", tot_p.eff + tot_r.eff, "\n"))
```

```
## 占比变化影响：0
## 率值波动影响：-0.0025
## 占比率值共同影响：-0.0025
```

---

### 双因素分析法：量化结构与率值对期望值的影响

```r
# 量化公式
qt_r <- \(r0, r1, p1) (r1 - r0) * p1
qt_p <- \(p0, p1, r0, e) (p1 - p0) * (r0 - e)

# 期望值计算
exp <- sum(dat$base_prop * dat$base_rate)
  
# 量化结果
result <- 
  dat |>
  mutate(r.eff = qt_r(base_cvr, curr_cvr, curr_prop),
         p.eff = qt_p(base_prop, curr_prop, base_cvr, exp),
         tot.eff = r.eff + p.eff)

result |> knitr::kable()
```



|dim | base_prop| base_rate| curr_prop| curr_rate|     r.eff|    p.eff|   tot.eff|
|:---|---------:|---------:|---------:|---------:|---------:|--------:|---------:|
|A   |       0.2|      0.10|      0.25|      0.08| -0.000625| -0.00125| -0.001875|
|B   |       0.3|      0.20|      0.25|      0.15| -0.000625|  0.00125|  0.000625|
|C   |       0.1|      0.15|      0.15|      0.09| -0.000375| -0.00125| -0.001625|
|D   |       0.2|      0.12|      0.20|      0.10| -0.000500|  0.00000| -0.000500|
|E   |       0.2|      0.05|      0.15|      0.07| -0.000375|  0.00125|  0.000875|

```r
# 校验：
tot_p.eff <- round(sum(result$p.eff), 4)
tot_r.eff <- round(sum(result$r.eff), 4)

cat(paste0("占比变化影响：", tot_p.eff, "\n",
           "率值波动影响：", tot_r.eff, "\n",
           "占比率值共同影响：", tot_p.eff + tot_r.eff, "\n"))
```

```
## 占比变化影响：0
## 率值波动影响：-0.0025
## 占比率值共同影响：-0.0025
```


