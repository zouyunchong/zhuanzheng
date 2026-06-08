#!/usr/bin/env bash
set -euo pipefail

# 个人 GitHub 账号：zouyunchong
# SSH Host：github-personal（~/.ssh/config 已配置，无需 gh login）
PAGES_REPO="git@github-personal:zouyunchong/zouyunchong.github.io.git"
PAGES_DIR="zhuanzheng"
PAGES_URL="https://zouyunchong.github.io/zhuanzheng/"
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
CLONE_DIR="/tmp/zouyunchong-pages-deploy"

echo "→ 个人账号: zouyunchong"
echo "→ 访问地址: $PAGES_URL"
echo ""

if [ -d "$CLONE_DIR/.git" ]; then
  echo "→ 更新 Pages 仓库 ..."
  git -C "$CLONE_DIR" pull --rebase origin main
else
  echo "→ 克隆 Pages 仓库 ..."
  git clone "$PAGES_REPO" "$CLONE_DIR"
fi

mkdir -p "$CLONE_DIR/$PAGES_DIR"
cp "$WORKDIR/index.html" "$CLONE_DIR/$PAGES_DIR/"
touch "$CLONE_DIR/$PAGES_DIR/.nojekyll"

cd "$CLONE_DIR"
git add "$PAGES_DIR/"
if git diff --cached --quiet; then
  echo "→ 无新改动，跳过提交"
else
  git commit -m "Update probation defense presentation"
  git push origin main
  echo ""
  echo "✓ 部署完成"
fi

echo "  访问地址: $PAGES_URL"
echo "  （更新后约 1 分钟生效）"
