#!/usr/bin/env bash
set -euo pipefail

# 个人 GitHub 账号：zouyunchong
# SSH Host：github-personal（~/.ssh/config）
# 私有仓库：zouyunchong/zhuanzheng
REPO="zouyunchong/zhuanzheng"
REMOTE="git@github-personal:zouyunchong/zhuanzheng.git"
PAGES_URL="https://zouyunchong.github.io/zhuanzheng/"
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
OLD_PUBLIC_REPO="git@github-personal:zouyunchong/zouyunchong.github.io.git"
OLD_PUBLIC_DIR="/tmp/zouyunchong-pages-cleanup"

echo "→ 个人账号: zouyunchong"
echo "→ 私有仓库: $REPO"
echo "→ Pages 地址: $PAGES_URL"
echo ""

# ── 1. 确保私有仓库存在 ──
if ! git ls-remote "$REMOTE" &>/dev/null; then
  echo "⚠  远程仓库尚未创建。"
  echo ""
  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    echo "→ 使用 gh 创建私有仓库 ..."
    gh repo create "$REPO" --private --description "邹云冲 · 试用期转正答辩（私有）"
  else
    echo "请先在 GitHub 创建私有仓库（一次性操作）："
    echo "  1. 打开 https://github.com/new"
    echo "  2. 用 zouyunchong 账号登录"
    echo "  3. Repository name 填: zhuanzheng"
    echo "  4. 选择 Private（私有）"
    echo "  5. 不要勾选 README，创建空仓库"
    echo "  6. 重新运行: ./deploy.sh"
    echo ""
    exit 1
  fi
fi

# ── 2. 配置本地 git 远程 ──
cd "$WORKDIR"
if ! git rev-parse --git-dir &>/dev/null; then
  git init -b main
fi

if git remote get-url origin &>/dev/null; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

git add index.html .gitignore .nojekyll deploy.sh
if git diff --cached --quiet; then
  echo "→ 无新改动"
else
  git commit -m "Update probation defense presentation"
fi

echo "→ 推送到私有仓库 ..."
git push -u origin main

# ── 3. 启用 GitHub Pages（需要 gh 已登录）──
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "→ 确保仓库为 Private ..."
  gh repo edit "$REPO" --visibility private 2>/dev/null || true

  echo "→ 启用 GitHub Pages ..."
  gh api "repos/$REPO/pages" -X POST \
    -f build_type=legacy \
    -f "source[branch]=main" \
    -f "source[path]=/" \
    2>/dev/null || gh api "repos/$REPO/pages" -X PUT \
    -f build_type=legacy \
    -f "source[branch]=main" \
    -f "source[path]=/" \
    2>/dev/null || echo "  （Pages 可能已启用，或在 Settings → Pages 手动开启）"
fi

# ── 4. 清理旧公开目录（github.io/zhuanzheng/）──
if git ls-remote "$OLD_PUBLIC_REPO" &>/dev/null; then
  if [ ! -d "$OLD_PUBLIC_DIR/.git" ]; then
    git clone "$OLD_PUBLIC_REPO" "$OLD_PUBLIC_DIR" 2>/dev/null || true
  fi
  if [ -d "$OLD_PUBLIC_DIR/zhuanzheng" ]; then
    echo "→ 移除旧公开路径 github.io/zhuanzheng/ ..."
    git -C "$OLD_PUBLIC_DIR" pull --rebase origin main 2>/dev/null || true
    git -C "$OLD_PUBLIC_DIR" rm -rf zhuanzheng
    git -C "$OLD_PUBLIC_DIR" commit -m "Remove public zhuanzheng folder (moved to private repo)" 2>/dev/null \
      && git -C "$OLD_PUBLIC_DIR" push origin main \
      && echo "  已清理旧公开副本" \
      || echo "  旧公开副本无需清理或已移除"
  fi
fi

echo ""
echo "✓ 部署完成"
echo "  仓库: https://github.com/$REPO （Private）"
echo "  访问: $PAGES_URL"
echo ""
echo "ℹ  私有仓库的 Pages 需要 GitHub Pro 才能非公开访问；"
echo "   或在仓库 Settings → Pages → Visibility 中配置访问权限。"
