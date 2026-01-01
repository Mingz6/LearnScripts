#!/usr/bin/env bash
set -euo pipefail

zshrc="$HOME/.zshrc"

mkdir -p "$HOME/.nvm"

block=$'\n# --- nvm (Node Version Manager) ---\nexport NVM_DIR="$HOME/.nvm"\n[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"\n[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"\n# --- end nvm ---\n'

already_configured=0
if [[ -f "$zshrc" ]]; then
  if grep -qE '(^|\s)(export\s+)?NVM_DIR=|/opt/homebrew/opt/nvm/nvm\.sh|bash_completion\.d/nvm' "$zshrc"; then
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
zsh -lc 'source ~/.zshrc >/dev/null 2>&1; command -v nvm && nvm --version && nvm ls'