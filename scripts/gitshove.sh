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

# Ensure were inside a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo -e "${RED}Have you tried turning your repository off and on again?.${NC}"
  exit 1
}

# Ensure clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "This tree needs pruning... run 'git status'"
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

#Enforce dev workflow
if [[ "$CURRENT_BRANCH" != "dev" ]]; then
echo -e "${YELLOW}You are on '$CURRENT_BRANCH' branch.${NC}"
read -p "Swicth to 'dev' and continue? (y/N): " SWITCH
if [[ "$SWITCH" != "y" && "$SWITCH" != "Y" ]]; then
  echo -e "${RED}Aborted.${NC}"
  exit 1
fi
git checkout dev

# Sync dev first 
echo -e "${BLUE}→ Syncing dev${NC}"
git pull origin dev --quiet
git push origin dev --quiet

# Sync main
echo -e "${BLUE}→ Switching to main${NC}"
git checkout main >/dev/null
git pull origin main --quiet

# check for merge conflicts
if [[-z "$(git log main..dev --oneline)"]]; then
  echo -e "{GREEN}Main is up to date!${NC}"
  git checkout dev >/dev/null
  exit 0
fi

# Show summary of changes to be merged
echo -e "\n${YELLOW}Commits to be merged:${NC}"
git log main..dev --oneline

echo -e "\n${YELLOW}Change summary:${NC}"
git diff --stat main..dev --no-merges

echo ""
read -p "Merge dev into main? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo -e "${RED}Merge confidence level: insufficient.${NC}"
  git checkout dev >/dev/null
  exit 1
fi  

echo -e "${BLUE} Fast forward merging dev → main${NC}"

if ! git merge --ff-only --no-edit >/dev/null; then
  echo -e "${RED}Fast forward merge failed.${NC}"
  echo -e " Please resolve merge conflicts manually, main has trust issues.${NC}"
  git checkout dev >/dev/null
  exit 1
fi  

echo -e "${BLUE}Pushing main${NC}"
git push origin main --quiet

git checkout dev >/dev/null
echo -e "${GREEN}Merge complete!${NC}"




