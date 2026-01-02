#!/usr/bin/env bash
set -euo pipefail

zshrc="$HOME/.zshrc"

mkdir -p "$HOME/.nvm"

block=$'\n# --- nvm (Node Version Manager) ---\n# Keep startup fast: do NOT source nvm.sh here.\n# nvm will be lazy-loaded by the per-repo `.env.local` hook (see ~/.zshrc).\nexport NVM_DIR="$HOME/.nvm"\n# --- end nvm ---\n'

already_configured=0
if [[ -f "$zshrc" ]]; then
  if grep -qE '(^|\s)(export\s+)?NVM_DIR=' "$zshrc"; then
    already_configured=1
  fi
fi

if [[ "$already_configured" -eq 0 ]]; then
  if [[ -f "$zshrc" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    backup="$HOME/.zshrc.bak-$ts"
    cp "$zshrc" "$backup"
    echo "Backed up $zshrc -> $backup"
  fi

  printf "%s" "$block" >> "$zshrc"
  echo "Added nvm init block to $zshrc"
else
  echo "$zshrc already contains nvm configuration; no changes made"
fi

echo "---"
if [[ -f /opt/homebrew/opt/nvm/nvm.sh ]]; then
  echo "Found: /opt/homebrew/opt/nvm/nvm.sh"
else
  echo "Missing: /opt/homebrew/opt/nvm/nvm.sh (brew reinstall nvm?)"
fi

echo "---"
# Validate in a fresh login shell so we don't depend on current terminal state.
zsh -lc 'export NVM_DIR="$HOME/.nvm"; if [[ -s /opt/homebrew/opt/nvm/nvm.sh ]]; then source /opt/homebrew/opt/nvm/nvm.sh; command -v nvm && nvm --version && nvm ls; else echo "Missing: /opt/homebrew/opt/nvm/nvm.sh"; fi'