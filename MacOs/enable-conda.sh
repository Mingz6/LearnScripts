#!/usr/bin/env bash
set -euo pipefail

zshrc="$HOME/.zshrc"

# Homebrew anaconda cask installs here on Apple Silicon.
conda_bin="/opt/homebrew/anaconda3/bin/conda"

already_configured=0
if [[ -f "$zshrc" ]]; then
  if grep -qE 'conda \(Anaconda/Miniconda\)|shell\.zsh hook|/anaconda3/bin/conda|conda\.sh|__conda_setup' "$zshrc"; then
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

  cat >> "$zshrc" <<'EOF'

# --- conda (Anaconda/Miniconda) ---
if [ -x "/opt/homebrew/anaconda3/bin/conda" ]; then
  __conda_setup="$("/opt/homebrew/anaconda3/bin/conda" "shell.zsh" "hook" 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    export PATH="/opt/homebrew/anaconda3/bin:$PATH"
  fi
  unset __conda_setup
fi
# --- end conda ---
EOF

  echo "Added conda init block to $zshrc"
else
  echo "$zshrc already contains conda configuration; no changes made"
fi

echo "---"
if [[ -x "$conda_bin" ]]; then
  echo "Found: $conda_bin"
else
  echo "Missing: $conda_bin"
  echo "Try: brew reinstall --cask anaconda"
  exit 1
fi

echo "---"
# Validate in a fresh login shell.
zsh -lc 'source ~/.zshrc; command -v conda; conda --version; conda info --base'