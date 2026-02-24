# gitshove
# --------
# A much faster way to merge into main safely for anyone that works primarily on dev.
#
# Workflow:
#   1. Ensures working tree is clean
#   2. Ensures you are on 'dev'
#   3. Pulls + pushes dev
#   4. Switches to main and updates it
#   5. Prompts for confirmation
#   6. Merges dev -> main
#   7. Pushes main
#   8. Returns to dev
#
# Stops immediately on:
#   - Uncommitted changes
#   - Merge conflicts
#   - Any command failure
#
# Install as git alias:
#   git config --global alias.shove "!bash $HOME/scripts/gitshove.sh"
#
# Usage:
#   git shove


#!/usr/bin/env bash
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

set -euo pipefail

# Ensure we're inside a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "No git in here buddy"
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

echo -e "${BLUE}Current branch: $CURRENT_BRANCH${NC}"

echo -e "${BLUE}Pulling latest on $CURRENT_BRANCH...${NC}"
git pull origin "$CURRENT_BRANCH"

echo -e "${YELLOW}Pushing $CURRENT_BRANCH...${NC}"
git push origin "$CURRENT_BRANCH"

echo -e "\n${YELLOW}=== Syncing dev branch ===${NC}"
echo "Switching to main..."
git checkout main

echo "Pulling latest main..."
git pull origin main

#confirmation before merging
read -p "Merge dev into main and push? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo -e "${RED}Aborted.${NC}"
  git checkout "$CURRENT_BRANCH"
  exit 1
fi

# Merge dev into main (fast-forward only)
echo -e "\n${YELLOW}=== Merging dev into main ===${NC}"

if ! git merge dev --ff-only --no-edit; then
  echo "Fast-forward merge failed."
  echo "main has diverged from dev."
  echo "Rebase dev onto main first:"
  echo "  git checkout dev"
  echo "  git pull origin main --rebase"
  exit 1
fi

echo "Pushing main..."
git push origin main

echo "Switching back to $CURRENT_BRANCH..."
git checkout "$CURRENT_BRANCH"

echo -e "${GREEN}Done.${NC}"


