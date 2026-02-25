# This is a helper script to merge dev into main with some safety checks and prompts.
# Removes  the friction of manually checking out, syncing, merging, and pushing between branches.
# Shows commit and diff summary before merging.

# Install: git config --global alias.shove "!bash $HOME/scripts/gitshove.sh"
# Run:     git shove

#!/usr/bin/env bash

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

set -euo pipefail

# Ensure inside git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo -e "${RED}Not a git repo...${NC}"
  exit 1
}

# Ensure clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo -e "${RED}This tree needs pruning... run 'git status'${NC}"
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Enforce dev workflow
if [[ "$CURRENT_BRANCH" != "dev" ]]; then
  echo -e "${YELLOW}You are on '$CURRENT_BRANCH' branch.${NC}"
  read -p "Switch to 'dev' and continue? (y/N): " SWITCH

  if [[ "$SWITCH" != "y" && "$SWITCH" != "Y" ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 1
  fi

  git checkout dev >/dev/null
fi

# Sync dev
echo -e "${BLUE}→ Syncing dev${NC}"
git pull origin dev --quiet
git push origin dev --quiet

# Switch to main
echo -e "${BLUE}→ Switching to main${NC}"
git checkout main >/dev/null
git pull origin main --quiet

# Check if anything to merge
if [[ -z "$(git log main..dev --oneline)" ]]; then
  echo -e "${GREEN}Main is already up to date.${NC}"
  git checkout dev >/dev/null
  exit 0
fi

# Show commits
echo -e "\n${YELLOW}Commits to be merged:${NC}"
git log main..dev --oneline

# Show diff stats
echo -e "\n${YELLOW}Change summary:${NC}"
git diff --stat main..dev

echo ""
read -p "Merge dev into main? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo -e "${RED}Merge confidence level: insufficient.${NC}"
  git checkout dev >/dev/null
  exit 1
fi

echo -e "${BLUE}→ Fast-forward merging dev → main${NC}"

# Attempt fast-forward merge
if ! git merge dev --ff-only --no-edit >/dev/null; then
  echo -e "${RED}Fast-forward merge failed.${NC}"
  echo "Rebase dev onto main:"
  echo "  git checkout dev"
  echo "  git pull origin main --rebase"
  git checkout dev >/dev/null
  exit 1
fi

# Push main
echo -e "${BLUE}→ Pushing main${NC}"
git push origin main --quiet

git checkout dev >/dev/null
echo -e "${GREEN}✔ Merge complete!${NC}"