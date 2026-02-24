#!/usr/bin/env bash

set -euo pipefail

# Ensure we're inside a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not here buddy"
  exit 1
}

# Ensure clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree not clean."
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "You must be on dev to run gitshove."
  exit 1
fi

echo "Current branch: $CURRENT_BRANCH"

echo "Pulling latest on $CURRENT_BRANCH..."
git pull origin "$CURRENT_BRANCH"

echo "Pushing $CURRENT_BRANCH..."
git push origin "$CURRENT_BRANCH"

echo "Switching to main..."
git checkout main

echo "Pulling latest main..."
git pull origin main

echo "Merging $CURRENT_BRANCH into main..."
git merge "$CURRENT_BRANCH"

echo "Pushing main..."
git push origin main

echo "Switching back to $CURRENT_BRANCH..."
git checkout "$CURRENT_BRANCH"

echo "Done."
