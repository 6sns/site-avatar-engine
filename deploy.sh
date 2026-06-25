#!/usr/bin/env bash
# Avatar Engine — GitHub Pages deploy (6sns)
# Contract: 6sns-design flow/.claude/agents/publish-agent.md
# html-file / html-landing → site-<slug>

set -euo pipefail

PROJECT_NAME="Avatar Engine"
REPO_FULL="6sns/site-avatar-engine"
URL="https://6sns.github.io/site-avatar-engine/"
GIT_USER_NAME="6sns"
GIT_USER_EMAIL="6sns@users.noreply.github.com"
REQUIRED_FILES="index.html .nojekyll"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "🔍 Pre-flight checks..."

if ! command -v gh >/dev/null 2>&1; then
  echo "❌ gh CLI не установлен. brew install gh && gh auth login"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "❌ gh не залогинен. gh auth login (аккаунт 6sns)"
  exit 1
fi

ACTIVE_USER="$(gh api user --jq .login 2>/dev/null || echo "")"
EXPECTED_USER="${REPO_FULL%%/*}"
if [[ "$ACTIVE_USER" != "$EXPECTED_USER" ]]; then
  echo "❌ Залогинен как '$ACTIVE_USER', нужен '$EXPECTED_USER'."
  echo "   gh auth switch  или  gh auth logout && gh auth login"
  exit 1
fi

for f in $REQUIRED_FILES; do
  if [[ ! -f "$f" ]]; then
    echo "❌ Отсутствует файл: $f"
    exit 1
  fi
done

if [[ ! -d assets ]]; then
  echo "❌ Отсутствует папка: assets"
  exit 1
fi

SIZE_MB="$(du -sm . | awk '{print $1}')"
echo "✓ gh: $ACTIVE_USER, размер ${SIZE_MB} MB"

if [[ "${1:-}" == "--check" ]]; then
  echo "✓ Pre-flight passed"
  exit 0
fi

if [[ -d .git ]]; then
  MODE="re-publish"
  echo "📝 Mode: re-publish"
elif gh repo view "$REPO_FULL" >/dev/null 2>&1; then
  MODE="re-publish-clone"
  echo "📝 Mode: re-publish (clone remote history)"
  TEMP_GIT="$(mktemp -d)"
  git clone "https://github.com/${REPO_FULL}.git" "$TEMP_GIT"
  mv "$TEMP_GIT/.git" .git
  rm -rf "$TEMP_GIT"
else
  MODE="first-publish"
  echo "📝 Mode: first publish → $REPO_FULL"
  git init -b main
fi

git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

git add -A

if git diff --staged --quiet 2>/dev/null; then
  echo "ℹ️  Нет изменений — push не нужен."
  echo "🔗 $URL"
  exit 0
fi

if [[ "$MODE" == "first-publish" ]]; then
  COMMIT_MSG="Initial deploy: $PROJECT_NAME"
else
  COMMIT_MSG="Update: $PROJECT_NAME ($(date +%Y-%m-%d))"
fi

git commit -m "$COMMIT_MSG" --quiet
echo "✓ Commit: $COMMIT_MSG"

if [[ "$MODE" == "first-publish" ]]; then
  echo "🚀 Создаю repo и пушу..."
  gh repo create "$REPO_FULL" \
    --public \
    --description "$PROJECT_NAME — Design Platform" \
    --source=. \
    --push \
    --remote=origin

  echo "🔧 Включаю GitHub Pages..."
  gh api -X POST "/repos/${REPO_FULL}/pages" \
    -f "source[branch]=main" \
    -f "source[path]=/" \
    --silent 2>/dev/null || true
else
  echo "🚀 Push update..."
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "https://github.com/${REPO_FULL}.git"
  else
    git remote add origin "https://github.com/${REPO_FULL}.git"
  fi
  git push -u origin main
fi

echo "⏳ Жду Pages build..."
for i in $(seq 1 12); do
  sleep 10
  STATUS="$(gh api "/repos/${REPO_FULL}/pages/builds/latest" --jq '.status' 2>/dev/null || echo "")"
  HTTP="$(curl -s -o /dev/null -w "%{http_code}" "$URL")"
  printf "   [%2ds] build=%-10s http=%s\n" "$((i * 10))" "${STATUS:-?}" "$HTTP"
  if [[ "$HTTP" == "200" ]] && [[ "$STATUS" == "built" ]]; then
    break
  fi
  if [[ "$STATUS" == "errored" ]]; then
    echo "❌ Pages build failed"
    gh api "/repos/${REPO_FULL}/pages/builds/latest" --jq '.error.message' 2>/dev/null || true
    exit 1
  fi
done

echo ""
echo "✅ $([[ "$MODE" == "first-publish" ]] && echo "Опубликовано" || echo "Обновлено"): $PROJECT_NAME"
echo "   🔗 $URL"
echo "   📦 github.com/$REPO_FULL"
