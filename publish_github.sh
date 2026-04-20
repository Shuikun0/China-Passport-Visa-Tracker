#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/Shuikun0/China-Passport-Visa-Tracker.git"
REPO_URL="${1:-$REPO_URL_DEFAULT}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Working directory: $SCRIPT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "==> Initializing git repository..."
  git init
fi

if [ -z "$(git remote 2>/dev/null || true)" ]; then
  echo "==> Adding remote origin: $REPO_URL"
  git remote add origin "$REPO_URL"
else
  if git remote get-url origin >/dev/null 2>&1; then
    CURRENT_REMOTE="$(git remote get-url origin)"
    if [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
      echo "==> Updating origin URL"
      git remote set-url origin "$REPO_URL"
    fi
  else
    echo "==> Adding missing origin remote"
    git remote add origin "$REPO_URL"
  fi
fi

if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "==> No commits found. Creating initial commit..."
  git add .
  git commit -m "Initial commit"
fi

echo "==> Switching branch to main"
git branch -M main

echo "==> Pushing to origin/main..."
if git push -u origin main; then
  echo
  echo "✅ Push successful."
  echo "Repository: $REPO_URL"
  exit 0
fi

echo
echo "❌ Push failed (likely due to authentication)."
echo
echo "Try one of these:"
echo "1) HTTPS + Personal Access Token:"
echo "   git push -u origin main"
echo
echo "2) SSH (if key already configured):"
echo "   git remote set-url origin git@github.com:Shuikun0/China-Passport-Visa-Tracker.git"
echo "   git push -u origin main"
exit 1

