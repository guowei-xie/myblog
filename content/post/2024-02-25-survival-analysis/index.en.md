---
title: Kaplan-Meier生存分析
author: xiebro
date: '2024-02-25'
slug: survival-analysis
categories:
  - R
tags:
  - R可视化
  - Kaplan-Meier

---



***Kaplan-Meier***生存分析：探索客户的生存概率随时间的变化，并可视化生存曲线，显示客户在不同时间点的**生存概率**。

数据集下载：[Telco-Customer-Churn.csv](datasets/Telco-Customer-Churn.csv)

### 数据集概览

```r
library(tidyverse)

dat <- 
  read.csv("datasets/Telco-Customer-Churn.csv") %>% 
  mutate(churn = if_else(Churn == "Yes", 1L, 0L))

dat %>%  glimpse()
```

```
## Rows: 7,043
## Columns: 22
## $ customerID       <chr> "7590-VHVEG", "5575-GNVDE", "3668-QPYBK", "7795-CFOCW…
## $ gender           <chr> "Female", "Male", "Male", "Male", "Female", "Female",…
## $ SeniorCitizen    <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
## $ Partner          <chr> "Yes", "No", "No", "No", "No", "No", "No", "No", "Yes…
## $ Dependents       <chr> "No", "No", "No", "No", "No", "No", "Yes", "No", "No"…
## $ tenure           <int> 1, 34, 2, 45, 2, 8, 22, 10, 28, 62, 13, 16, 58, 49, 2…
## $ PhoneService     <chr> "No", "Yes", "Yes", "No", "Yes", "Yes", "Yes", "No", …
## $ MultipleLines    <chr> "No phone service", "No", "No", "No phone service", "…
## $ InternetService  <chr> "DSL", "DSL", "DSL", "DSL", "Fiber optic", "Fiber opt…
## $ OnlineSecurity   <chr> "No", "Yes", "Yes", "Yes", "No", "No", "No", "Yes", "…
## $ OnlineBackup     <chr> "Yes", "No", "Yes", "No", "No", "No", "Yes", "No", "N…
## $ DeviceProtection <chr> "No", "Yes", "No", "Yes", "No", "Yes", "No", "No", "Y…
## $ TechSupport      <chr> "No", "No", "No", "Yes", "No", "No", "No", "No", "Yes…
## $ StreamingTV      <chr> "No", "No", "No", "No", "No", "Yes", "Yes", "No", "Ye…
## $ StreamingMovies  <chr> "No", "No", "No", "No", "No", "Yes", "No", "No", "Yes…
## $ Contract         <chr> "Month-to-month", "One year", "Month-to-month", "One …
## $ PaperlessBilling <chr> "Yes", "No", "Yes", "No", "Yes", "Yes", "Yes", "No", …
## $ PaymentMethod    <chr> "Electronic check", "Mailed check", "Mailed check", "…
## $ MonthlyCharges   <dbl> 29.85, 56.95, 53.85, 42.30, 70.70, 99.65, 89.10, 29.7…
## $ TotalCharges     <dbl> 29.85, 1889.50, 108.15, 1840.75, 151.65, 820.50, 1949…
## $ Churn            <chr> "No", "No", "Yes", "No", "Yes", "Yes", "No", "No", "Y…
## $ churn            <int> 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0,…
```


### 生存分析
#### 1. 初步探查，整体生存趋势

```r
library(survival) # 进行生存分析的函数和工具
library(survminer) # 用于生存分析结果的可视化
library(hrbrthemes) # 用于设置可视化主题

# Kaplan-Meier Analysis
km_fit <- survfit(Surv(tenure, churn) ~ 1, data = dat)

km_fit %>% 
  ggsurvplot(
    data     = dat,
    linetype = "solid",
    conf.int = FALSE,
    ggtheme  = theme_ipsum(),
    xlab = "Time",
    ylab = "Surv. Prob"
  )
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-2-1.png" width="672" />

#### 2. 维度探查，不同特征人群的生存趋势
封装函数，方便多次画图使用

```r
pals <- rownames(RColorBrewer::brewer.pal.info)

sc <- . %>%
  ggsurvplot(
    data     = dat,
    linetype = "solid",
    conf.int = FALSE,
    pval     = TRUE,
    censor   = FALSE,
    palette  = sample(pals, 1),
    ggtheme  = theme_ipsum(),
    break.time.by = 14,
    xlab = "Time",
    ylab = "Surv. Prob"
  )
```
- by gender:

```r
gender_fit <- survfit(Surv(tenure, churn) ~ gender, data = dat)
sc(gender_fit)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-4-1.png" width="672" />

- by PaymentMethod:

```r
payment_method <- survfit(Surv(tenure, churn) ~ PaymentMethod, data = dat)
sc(payment_method)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-5-1.png" width="672" />

#### 3. 使用迭代法快速扫描维度

```r
library(gridExtra)

# 需要扫描的维度
cols <-
  c(
    "PhoneService",
    "TechSupport",
    "StreamingTV",
    "StreamingMovies"
  )

plots <- 
  cols %>% 
  # 这里引入了meta programming的编程思想，用函数生成函数
  map_chr( ~ sprintf("survfit(Surv(tenure, churn) ~ %s, data = dat)", .x)) %>% 
  map(~ eval(parse(text = .))) %>% 
  map(sc) %>% 
  # 从ggsurvplot对象中提取图片
  map(pluck, "plot")

do.call(grid.arrange, plots)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-6-1.png" width="672" />






