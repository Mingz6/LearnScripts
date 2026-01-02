#!/usr/bin/env bash
set -euo pipefail

zshrc="$HOME/.zshrc"

# Homebrew anaconda cask installs here on Apple Silicon.
conda_bin="/opt/homebrew/anaconda3/bin/conda"

begin_marker="# --- conda (Anaconda/Miniconda) ---"
end_marker="# --- end conda ---"

new_block=$(cat <<'EOF'

# --- conda (Anaconda/Miniconda) ---
conda_base="/opt/homebrew/anaconda3"
if [ -f "$conda_base/etc/profile.d/conda.sh" ]; then
  # Fast path: defines the `conda` function without running the slower shell hook.
  . "$conda_base/etc/profile.d/conda.sh"
elif [ -x "$conda_base/bin/conda" ]; then
  # Fallback: at least put conda on PATH.
  export PATH="$conda_base/bin:$PATH"
fi
unset conda_base
# --- end conda ---
EOF
)

already_configured=0
if [[ -f "$zshrc" ]]; then
  if grep -qF "$begin_marker" "$zshrc"; then
    already_configured=1
  fi
fi

ts="$(date +%Y%m%d-%H%M%S)"

if [[ -f "$zshrc" ]] && grep -qF "$begin_marker" "$zshrc"; then
  backup="$HOME/.zshrc.bak-$ts"
  cp "$zshrc" "$backup"
  echo "Backed up $zshrc -> $backup"

  tmpfile="$(mktemp)"
  awk -v begin="$begin_marker" -v end="$end_marker" -v repl="$new_block" '
    $0 == begin { print repl; inblock=1; next }
    inblock && $0 == end { inblock=0; next }
    inblock { next }
    { print }
  ' "$zshrc" > "$tmpfile"
  mv "$tmpfile" "$zshrc"
  echo "Updated conda init block in $zshrc (faster conda.sh path)"
elif [[ "$already_configured" -eq 0 ]]; then
  if [[ -f "$zshrc" ]]; then
    backup="$HOME/.zshrc.bak-$ts"
    cp "$zshrc" "$backup"
    echo "Backed up $zshrc -> $backup"
  fi

  printf "%s\n" "$new_block" >> "$zshrc"
  echo "Added conda init block to $zshrc"
else
  echo "$zshrc already contains a conda block; no changes made"
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