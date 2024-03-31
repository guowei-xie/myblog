---
title: LMDI用于漏斗指标归因
author: Xiebro
date: '2024-03-15'
slug: lmdi
categories:
  - R
tags:
  - Causal-Inference
---

我们有一个结果指标***新用户购买率Y***，它由4个漏斗指标构成，分别为：***新用户注册率A***、***注册用户激活率B***、***激活用户留存率C***、***留存用户购买率D***。

即：***Y = A x B x C x D***  

我们希望通过计算因子波动对结果指标***Y***的影响，来衡量这4个指标的重要性如何。  

或是另外一个非常常见的工作场景，当Y发生了较大的波动，我们希望通过指标拆解，来清楚地说明各个因素的变动对整体的波动产生了什么样的影响。

---


```r
# 创建一个包含基期和现期漏斗指标的示例数据框
set.seed(42)
funnel_data <- 
  data.frame(Indicator = c("新用户注册率A", "注册用户激活率B", "激活用户留存率C", "留存用户购买率D"),
             Base_Rate = runif(4, min = 0.1, max = 0.5), 
             Current_Rate = runif(4, min = 0.1, max = 0.5)
)

print(funnel_data)
```

```
##         Indicator Base_Rate Current_Rate
## 1   新用户注册率A 0.4659224    0.3566982
## 2 注册用户激活率B 0.4748302    0.3076384
## 3 激活用户留存率C 0.2144558    0.3946353
## 4 留存用户购买率D 0.4321791    0.1538666
```
### LMDI（Logarithmic Mean Index Method）乘积因子拆解

```r
library(dplyr)
# 计算现期与基期结果指标Y的差异
Y0 <- prod(funnel_data$Base_Rate)
Y1 <- prod(funnel_data$Current_Rate)
Y_delta <- Y1 - Y0
# 计算平均对数权重
L <- Y_delta / (log(Y1) - log(Y0))
# 计算各指标在Y_delta中的贡献
C <- \(r0, r1)  L * log(r1 / r0)
# 计算各指标对整体变化率的贡献，即重要性
I <- \(C) C / Y_delta

result <- 
  funnel_data |>
  mutate(C = C(Base_Rate, Current_Rate),
         I = I(C))

result |> knitr::kable()
```



|Indicator       | Base_Rate| Current_Rate|          C|          I|
|:---------------|---------:|------------:|----------:|----------:|
|新用户注册率A   | 0.4659224|    0.3566982| -0.0032894|  0.2376473|
|注册用户激活率B | 0.4748302|    0.3076384| -0.0053446|  0.3861302|
|激活用户留存率C | 0.2144558|    0.3946353|  0.0075097| -0.5425513|
|留存用户购买率D | 0.4321791|    0.1538666| -0.0127172|  0.9187738|



```r
# 校验
cat(paste0("Y0: ",      round(Y0, 4),       "\n",
           "Y1: ",      round(Y1, 4),       "\n",
           "Y_delta: ", round(Y_delta, 4)), "\n",
           "SUM(C): ",  sum(result$C),      "\n",
           "SUM(I): ",  sum(result$I),      "\n")
```

```
## Y0: 0.0205
## Y1: 0.0067
## Y_delta: -0.0138 
##  SUM(C):  -0.01384152 
##  SUM(I):  1
```
从上表可以很直观的看到，造成***新用户购买率Y***下降的主因是***留存用户购买率D***
