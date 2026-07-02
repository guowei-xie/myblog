#!/usr/bin/env bash
# 一键部署「浑身蟹数」到生产 VPS。
#
# 用法：
#   1) 本地写好文章并构建（RStudio knit-on-save，或命令行：
#        export RSTUDIO_PANDOC="/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64"
#        Rscript -e 'blogdown::build_site(build_rmd = "content/post/<slug>/index.en.Rmd")'）
#   2) git add / git commit（务必把构建产物 public/ 一并提交——本站由 public/ 直接服务）
#   3) ./deploy.sh
#
# 一次性前置配置（只需做一次）：
#   a) 免密登录：把本机公钥装到服务器
#        ssh-copy-id xiebro
#   b) 让站点目录归 xiebro 所有，从而 git pull 无需 sudo：
#        ssh -t xiebro "sudo chown -R xiebro:xiebro /data/wwwroot/myblog"
#   若不做 (b)，把下面 REMOTE_PULL 的注释切换成带 sudo 的那行（部署时会交互式要 sudo 密码）。

set -euo pipefail

REMOTE="${BLOG_REMOTE:-xiebro}"                     # ~/.ssh/config 主机别名 -> xiebro@123.56.29.19
SITE_DIR="${BLOG_SITE_DIR:-/data/wwwroot/myblog}"   # 服务器上的 git 检出（nginx 站点根 public/ 的父目录）
URL="${BLOG_URL:-https://www.xiebro.cool/}"

cd "$(dirname "$0")"

# 0) 只发布已提交进 git 的内容
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "⚠️  有未提交的改动，请先构建并 git commit 再部署：" >&2
  git status --short >&2
  exit 1
fi

echo "==> [1/3] 推送到 origin/main"
git push origin main

echo "==> [2/3] 在 ${REMOTE} 上拉取更新（${SITE_DIR}）"
# 无 sudo 版本（已执行前置配置 b）：
ssh "$REMOTE" "git -C '${SITE_DIR}' pull --ff-only && git -C '${SITE_DIR}' log --oneline -1"
# 带 sudo 版本（未 chown 时改用这行，注释掉上面一行）：
# ssh -t "$REMOTE" "sudo git -C '${SITE_DIR}' pull --ff-only && git -C '${SITE_DIR}' log --oneline -1"

echo "==> [3/3] 校验线上状态"
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$URL")
echo "    ${URL} -> HTTP ${code}"
if [ "$code" = "200" ]; then
  echo "✅ 部署完成"
else
  echo "❌ 线上未返回 200（可能 CDN 缓存或服务异常），请检查" >&2
  exit 1
fi
