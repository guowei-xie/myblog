---
title: Commands：经常用但又经常忘的命令行
author: Xiebro
date: '2024-02-24'
slug: [linux]
categories:
  - Shell
tags:
  - shell
  - linux
  - git
  - nginx
---

### Linux
```bash
# 查询磁盘使用情况
du -d1 -h

# 查询CPU使用情况
top -d

# 查询网络情况
networkQuality

# 文件复制
cp file.txt newfile.txt
cp file.txt /path/

# 文件内容复制
cat file.txt | pbcopy  # 复制到剪贴板
pbpaste > newfile.txt  # 粘贴到新文件 

# 文件压缩
tar -zcvf abc.tar.gz directory #将目录压缩为gzip格式

# 文件解压
tar -zxvf abc.tar.gz 

# 对比两份文件
diff file1 file2

# 上传文件到云端
scp /path/to/local/file username@server:/path/to/remote/directory

# 下载文件到本地
scp username@server:/path/to/remote/file /path/to/local/directory

# 查询自身 IP
curl -v https://api.ipify.org  

# 服务重启
systemctl restart nginx  # stop/start ； mysql
```

### Git
```bash
# .ssh目录下生成公钥 -----------------------------------------------------------
$ ssh-keygen -t rsa -C “youremail@example.com” 

# rm的用法 ---------------------------------------------------------------------
rm file; git add file  # 先从工作区删除，在暂存删除内容
git rm <file>          # 把文件从工作区和暂存区同时删除
git rm --cached <file> # 把文件从暂存区删除，但保留在当前工作区中
git rm -r *            # 递归删除某个目录下的所有子目录和文件

# diff的用法 -------------------------------------------------------------------
git diff              # 工作区vs暂存区
git diff HEAD         # 工作区+暂存区vs本地仓库
git diff --cached     # 暂存区vs本地仓库
git diff HEAD~ HEAD   # 比较提交之间的差异
git diff <commit_hash> <commit_hash> # 比较提交之间的差异
git diff <branch_anme> <branch_name> # 比较分支之间的差异

# reset的三种模式 --------------------------------------------------------------
git reset --soft  # 工作区、暂存区均不丢弃
git reset --hard  # 工作区、暂存区均被丢弃
git reset --mixed # 工作区不丢弃、暂存区丢弃

git reset --hard HEAD^         # 回退到上一版本
git reset --hard HEAD~n        # 回退到第上n个版本
git reset --hard <commit_hash> # 回退到指定版本

# 当文件已add到暂存区时，将其撤回到工作区
git reset HEAD readme.txt

# stash的用法 ------------------------------------------------------------------
git stash                  # 保存工作现场
git stash apply            # 恢复工作现场(但不删除stash内容)
git stash pop              # 恢复工作现场(并且删除stash内容)
git stash list             # 显示所有工作现场
git stash apply stash@{0}  # 选择要恢复的工作现场

# .gitignore配置 ---------------------------------------------------------------
*.a            # 忽略所有.a结尾的文件
!lib.a         # 但跟踪所有的lib.a，即便之前忽略了.a文件
build/         # 忽略任何目录下名为build的文件夹
doc/*.txt      # 忽略doc/file.txt，但不会忽略doc/document/file.txt
doc/**/*.pdf   # 忽略doc/目录及其所有子目录下的.pdf文件

```
[A collection of .gitignore templates](https://github.com/github/gitignore/)


