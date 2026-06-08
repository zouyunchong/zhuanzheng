#!/usr/bin/env bash
set -euo pipefail

export GH_PAGER=cat

# 个人 GitHub 账号：zouyunchong
# SSH Host：github-personal（~/.ssh/config）
# 公开仓库：zouyunchong/zhuanzheng
REPO="zouyunchong/zhuanzheng"
REMOTE="git@github-personal:zouyunchong/zhuanzheng.git"
PAGES_URL="https://zouyunchong.github.io/zhuanzheng/"
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
OLD_PUBLIC_REPO="git@github-personal:zouyunchong/zouyunchong.github.io.git"
OLD_PUBLIC_DIR="/tmp/zouyunchong-pages-cleanup"

echo "→ 个人账号: zouyunchong"
echo "→ 仓库: $REPO"
echo "→ Pages 地址: $PAGES_URL"
echo ""

# ── 1. 确保远程仓库存在 ──
if ! git ls-remote "$REMOTE" &>/dev/null; then
  echo "⚠  远程仓库尚未创建。"
  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    echo "→ 创建公开仓库 ..."
    gh repo create "$REPO" --public --description "邹云冲 · 试用期转正答辩"
  else
    echo "请先在 https://github.com/new 创建公开仓库 zhuanzheng，然后重新运行 ./deploy.sh"
    exit 1
  fi
fi

# ── 2. 推送代码 ──
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

echo "→ 推送到 GitHub ..."
git push -u origin main

# ── 3. 确保 GitHub Pages 已开启 ──
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "→ 检查 GitHub Pages ..."
  if gh api "repos/$REPO/pages" --jq .html_url &>/dev/null; then
    echo "  Pages 已开启"
  else
    gh api "repos/$REPO/pages" -X POST \
      -f build_type=legacy \
      -f "source[branch]=main" \
      -f "source[path]=/" \
      --silent && echo "  Pages 已开启" || echo "  请在 Settings → Pages 手动开启"
  fi
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
      || true
  fi
fi

echo ""
echo "✓ 部署完成"
echo "  仓库: https://github.com/$REPO"
echo "  访问: $PAGES_URL"
echo "  （更新后约 1 分钟生效）"
