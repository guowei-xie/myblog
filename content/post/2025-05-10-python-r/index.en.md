---
title: 在Python中优雅调用R
author: xiebro
date: '2025-05-10'
slug: []
categories:
  - 工程化
tags:
  - 工程化
---

## 准备
- Python环境中安装`rpy2`包 
- R环境中安装`lazyeval`包 
- 确认R语言安装环境目录（终端输入`which R`查看）

## Python调用R示例：

```python
import os
import io
import rpy2.robjects as ro
```

```
## R was initialized outside of rpy2 (R_NilValue != NULL). Trying to use it nevertheless.
```

```python
os.environ['R_HOME'] = '/usr/local/bin/R'

# 创建R环境
r = ro.r

# 执行R代码
r('''
  df <- data.frame(
          x = c(1:10),
          y = c(1:10)
        )
  ''')

# Python获取R变量
df = ro.globalenv['df']
```


