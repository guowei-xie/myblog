---
title: Shiny-Server部署
author: Xiebro
date: '2024-04-28'
slug: shiny-server
categories:
  - 工程化
tags:
  - 工程化
  - linux
---

在ubuntu系统部署[shiny-server](https://posit.co/download/shiny-server/)的流程记录

```bash
# 登录服务器后，进入根目录下的/srv路径
cd /srv

# 按照官网提供的方法进行安装, 依次执行：
sudo apt-get install gdebi-core
sudo wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.1017-amd64.deb
sudo gdebi shiny-server-1.5.22.1017-amd64.deb
```
安装成功后，在本地浏览器访问shiny-server的默认监听端口3838  
例如：xxx.xxx.xxx.xxx:3838  
可访问shiny-server的demo页面（前提是该端口已经在控制台开放）

## Config
```bash
# 进入shiny-server的配置文件路径
cd /etc/shiny-server

# sudo权限下编辑并保存配置文件
sudo vim shiny-server.conf
```
配置文件内容如下：
```yaml
# Instruct Shiny Server to run applications as the user "shiny"
run_as shiny;

# Define a server that listens on port 3838
server {
  listen 3838;

  # Define a location at the base URL
  location / {

    # Host the directory of Shiny Apps stored in this directory
    site_dir /srv/shiny-server;

    # Log all Shiny output to files in this directory
    log_dir /var/log/shiny-server;

    # When a user visits the base URL rather than a particular application,
    # an index of the applications available in this directory will be shown.
    directory_index on;
  }
}
```
- 一般情况下配置文件不需要修改，如果3838端口未开放，可修改为已开放的端口；
- 不过需要注意```run_as shiny;```这行，表明服务会默认以`shiny`用户运行，但此时服务器中还没有该用户，故需创建并赋予root权限
```bash
# 创建用户：shiny
sudo su
useradd shiny 
passwd shiny

# 赋予权限
chmod +w /etc/sudoers # 将`权限配置文件`更改为"可写"属性
sudo vim /etc/sudoers # 编辑`权限配置文件`
```

权限配置文件`sudoers`修改内容如下：
在root权限下添加shiny用户并保存
```yaml
# User privilege specification
root    ALL=(ALL:ALL) ALL
shiny   ALL=(ALL:ALL) ALL
```
安全起见，修改完成后恢复`sudoers`文件的"只读"属性
```base
chmod -w /etc/sudoers
```

## 部署Shiny应用
- 将已完成的shiny项目上传(移动或git克隆到)```srv/shiny-server/```路径下，当shiny-server服务启动后，会默认以项目文件名称作为访问路径，例如：xxx.xxx.xxx.xxx:3838/My-app

## Shiny-Server服务控制
```bash
# 启动
sudo systemctl start shiny-server 
# 停止
sudo systemctl stop shiny-server 
# 重启
sudo systemctl restart shiny-server 
```

## Shiny-Sever服务日志
```
cd /var/log/shiny-sever/
```







