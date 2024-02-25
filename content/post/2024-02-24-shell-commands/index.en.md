---
title: Shell：个人常用但经常会忘的命令行
author: Xiebro
date: '2024-02-24'
slug: [linux]
categories:
  - shell
tags:
  - shell
  - linux
  - git
---

### linux
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
```

### 生成秘钥
```bash
# .ssh目录下
$ ssh-keygen -t rsa -C “youremail@example.com” 
```

### Git
```bash
# 查看工作区和暂存区版本差异
git diff readme.txt 

# 查看暂存区和版本库差异
git diff --cached 

# 将文件从暂存区移除
git rm --cached readme.txt

# 查看工作区和版本库差异
git diff HEAD --readme.txt 

# 回退上一版本
git reset --hard HEAD^

# 回退到第上n个版本
git reset --hard HEAD~n

# 回退到指定版本
git reset --hard commit_id

# 当文件未add到暂存区时，使其回退到上一次commit（丢弃工作区修改）
git checkout --readme.txt
 
# 当文件已add到暂存区时，将其撤回到工作区
git reset HEAD readme.txt

# 保存工作现场
git stash

# 恢复工作现场(但不删除stash内容)
git stash apply

# 恢复工作现场(并且删除stash内容)
git stash pop

# 显示所有工作现场
git stash list

# 选择要恢复的工作现场
git stash apply stash@{0}

```

