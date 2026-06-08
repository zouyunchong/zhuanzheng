#!/usr/bin/env bash
set -euo pipefail

# 个人 GitHub 账号：zouyunchong
# SSH Host：github-personal（见 ~/.ssh/config）
REPO="zouyunchong/zhuanzheng"
REMOTE="git@github-personal:zouyunchong/zhuanzheng.git"
PAGES_URL="https://zouyunchong.github.io/zhuanzheng/"

cd "$(dirname "$0")"

echo "→ 目标仓库: $REPO"
echo "→ Pages 地址: $PAGES_URL"
echo ""

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  git init -b main
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$REMOTE"
else
  git remote set-url origin "$REMOTE"
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "请先登录个人 GitHub 账号 zouyunchong（浏览器授权）："
  echo "  gh auth login --hostname github.com --git-protocol ssh --web"
  echo ""
  echo "登录完成后重新运行: ./deploy.sh"
  exit 1
fi

LOGIN=$(gh api user --jq .login)
if [ "$LOGIN" != "zouyunchong" ]; then
  echo "当前 gh 登录账号是: $LOGIN"
  echo "请切换到个人账号 zouyunchong："
  echo "  gh auth logout"
  echo "  gh auth login --hostname github.com --git-protocol ssh --web"
  exit 1
fi

if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "→ 创建仓库 $REPO ..."
  gh repo create "$REPO" --public --source=. --remote=origin --description "邹云冲 · 试用期转正答辩"
else
  echo "→ 仓库已存在"
fi

git add -A
if git diff --cached --quiet; then
  echo "→ 无新改动"
else
  git commit -m "Update probation defense presentation"
fi

echo "→ 推送到 GitHub ..."
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" git push -u origin main

echo "→ 启用 GitHub Pages ..."
gh api "repos/$REPO/pages" -X POST \
  -f build_type=legacy \
  -f "source[branch]=main" \
  -f "source[path]=/" \
  2>/dev/null || gh api "repos/$REPO/pages" -X PUT \
  -f build_type=legacy \
  -f "source[branch]=main" \
  -f "source[path]=/"

echo ""
echo "✓ 部署完成"
echo "  访问地址: $PAGES_URL"
echo "  （首次部署约 1–2 分钟生效）"
