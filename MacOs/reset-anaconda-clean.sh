#!/usr/bin/env bash
set -euo pipefail

# Resets Anaconda to a "fresh install" state on macOS (Homebrew cask), then reinstalls.
# Writes verbose output to a log file to avoid overwhelming VS Code's integrated terminal.

log_dir="${TMPDIR:-/tmp}"
ts="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/reset-anaconda-$ts.log"

echo "Log: $log_file"

run() {
  # Run a command, append all output to log, and print only a short status line.
  echo "+ $*" >>"$log_file"
  "$@" >>"$log_file" 2>&1
}

backup_shell_files() {
  for f in "$HOME/.zshrc" "$HOME/.zprofile"; do
    if [[ -f "$f" ]]; then
      cp "$f" "$f.bak-$ts"
      echo "Backed up: $f -> $f.bak-$ts" | tee -a "$log_file"
    fi
  done
}

remove_conda_block_from_zshrc() {
  local zshrc="$HOME/.zshrc"
  [[ -f "$zshrc" ]] || return 0

  # Remove only the block inserted by MacOs/enable-conda.sh
  # Markers:
  #   # --- conda (Anaconda/Miniconda) ---
  #   ...
  #   # --- end conda ---
  if grep -q "^# --- conda (Anaconda/Miniconda) ---$" "$zshrc"; then
    local tmp
    tmp="$(mktemp)"
    awk '
      BEGIN{skip=0}
      /^# --- conda \(Anaconda\/Miniconda\) ---$/{skip=1; next}
      /^# --- end conda ---$/{skip=0; next}
      skip==0{print}
    ' "$zshrc" >"$tmp"
    mv "$tmp" "$zshrc"
    echo "Removed conda init block from ~/.zshrc" | tee -a "$log_file"
  fi
}

main() {
  echo "Step 1/5: Backup shell files" | tee -a "$log_file"
  backup_shell_files

  echo "Step 2/5: Uninstall Anaconda (Homebrew cask)" | tee -a "$log_file"
  # Don't fail if it's already uninstalled.
  run brew uninstall --cask anaconda || true

  echo "Step 3/5: Remove Anaconda/conda residual files" | tee -a "$log_file"
  # Remove the main install location (Apple Silicon default for this setup)
  run rm -rf /opt/homebrew/anaconda3 || true

  # Remove user-level conda state/config
  run rm -rf "$HOME/.conda" || true
  run rm -f "$HOME/.condarc" || true
  run rm -rf "$HOME/.continuum" || true

  # Remove the init block we added previously
  remove_conda_block_from_zshrc

  echo "Step 4/5: Reinstall Anaconda" | tee -a "$log_file"
  run brew install --cask anaconda

  echo "Step 5/5: Re-enable conda in zsh and verify" | tee -a "$log_file"
  # Use the repo helper to add the init block back.
  if [[ -f "$(dirname "$0")/enable-conda.sh" ]]; then
    run "$(dirname "$0")/enable-conda.sh"
  fi

  # Minimal human-friendly verification summary
  if [[ -x /opt/homebrew/anaconda3/bin/conda ]]; then
    echo "OK: conda installed at /opt/homebrew/anaconda3" | tee -a "$log_file"
    echo "Next: open a NEW terminal tab/window, then run: conda --version" | tee -a "$log_file"
  else
    echo "ERROR: conda not found at /opt/homebrew/anaconda3/bin/conda" | tee -a "$log_file"
    echo "Check log: $log_file" | tee -a "$log_file"
    exit 1
  fi

  echo "Done. Full log: $log_file"
}

main "$@"
