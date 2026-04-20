#!/usr/bin/env bash
set -euo pipefail

# Usage examples:
#   bash setup_ssh_and_push.sh
#   bash setup_ssh_and_push.sh --email "you@example.com"
#   bash setup_ssh_and_push.sh --repo "git@github.com:Shuikun0/China-Passport-Visa-Tracker.git" --push

EMAIL=""
REPO_SSH_URL="git@github.com:Shuikun0/China-Passport-Visa-Tracker.git"
DO_PUSH="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --email)
      EMAIL="${2:-}"
      shift 2
      ;;
    --repo)
      REPO_SSH_URL="${2:-}"
      shift 2
      ;;
    --push)
      DO_PUSH="true"
      shift
      ;;
    -h|--help)
      echo "Usage: bash setup_ssh_and_push.sh [--email you@example.com] [--repo git@github.com:user/repo.git] [--push]"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"
      exit 1
      ;;
  esac
done

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

SSH_DIR="${HOME}/.ssh"
KEY_PATH="${SSH_DIR}/id_ed25519"
PUB_KEY_PATH="${KEY_PATH}.pub"

echo "==> Project: ${PROJECT_DIR}"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -f "$KEY_PATH" && -f "$PUB_KEY_PATH" ]]; then
  echo "==> Found existing SSH key: $KEY_PATH"
else
  if [[ -z "$EMAIL" ]]; then
    EMAIL="github-key-$(date +%Y%m%d)@local"
  fi
  echo "==> Creating new SSH key (ed25519) with comment: $EMAIL"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH"
fi

echo "==> Starting ssh-agent and adding key"
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$KEY_PATH" >/dev/null

PUB_KEY_CONTENT="$(cat "$PUB_KEY_PATH")"
echo
echo "===== PUBLIC KEY (add this to GitHub) ====="
echo "$PUB_KEY_CONTENT"
echo "==========================================="
echo

if command -v pbcopy >/dev/null 2>&1; then
  printf "%s" "$PUB_KEY_CONTENT" | pbcopy
  echo "==> Public key copied to clipboard."
fi

echo
echo "Next step (manual, one-time):"
echo "1) Open: https://github.com/settings/keys"
echo "2) Click 'New SSH key' and paste the copied public key"
echo
echo "After saving key on GitHub, press Enter to continue test..."
read -r

echo "==> Testing SSH auth to GitHub"
set +e
SSH_TEST_OUTPUT="$(ssh -T git@github.com 2>&1)"
SSH_TEST_EXIT=$?
set -e

echo "$SSH_TEST_OUTPUT"
if [[ $SSH_TEST_EXIT -ne 0 && $SSH_TEST_OUTPUT != *"successfully authenticated"* ]]; then
  echo
  echo "❌ SSH auth still not ready. Please ensure the key is added to GitHub."
  exit 1
fi

echo "==> SSH auth looks good."

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    echo "==> Setting origin to SSH URL"
    git remote set-url origin "$REPO_SSH_URL"
  else
    echo "==> Adding origin with SSH URL"
    git remote add origin "$REPO_SSH_URL"
  fi
else
  echo "==> Initializing git repository"
  git init
  git remote add origin "$REPO_SSH_URL"
fi

echo "==> Current remote:"
git remote -v

if [[ "$DO_PUSH" == "true" ]]; then
  if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "==> No commits yet. Creating initial commit..."
    git add .
    git commit -m "Initial commit"
  fi
  git branch -M main
  echo "==> Pushing to origin/main ..."
  git push -u origin main
  echo "✅ Push done."
else
  echo
  echo "Ready to push. Run:"
  echo "  git branch -M main"
  echo "  git push -u origin main"
  echo
  echo "Or rerun this script with --push:"
  echo "  bash setup_ssh_and_push.sh --push"
fi

