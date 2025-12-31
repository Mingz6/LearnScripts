#!/usr/bin/env bash
set -euo pipefail

# 2.post-reboot-maintenance.sh
# Post-reboot macOS sanity checks + Spotlight reindex.
# Default behavior: reindex Spotlight (per user preference) unless explicitly disabled.
#
# Usage:
#   chmod +x ./2.post-reboot-maintenance.sh
#   ./2.post-reboot-maintenance.sh
#   ./2.post-reboot-maintenance.sh --no-reindex-spotlight
#
# Notes:
# - Reindex runs `sudo mdutil -E /` (can be slow + CPU heavy).

usage() {
  cat <<'EOF'
Usage:
  2.post-reboot-maintenance.sh [options]

Options:
  --reindex-spotlight     Rebuild Spotlight index for system volume (/). Requires sudo. (default)
  --no-reindex-spotlight  Do NOT rebuild Spotlight index
  --yes                Do not prompt for confirmation
  -h, --help           Show help

Examples:
  # After a reboot: check + rebuild Spotlight index (default)
  ./2.post-reboot-maintenance.sh

  # Checks only (skip Spotlight rebuild)
  ./2.post-reboot-maintenance.sh --no-reindex-spotlight
EOF
}

ASSUME_YES=0
DO_REINDEX=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) DO_REINDEX=0; shift ;;
    --reindex-spotlight) DO_REINDEX=1; shift ;;
    --no-reindex-spotlight) DO_REINDEX=0; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }

confirm() {
  local prompt="$1"
  if [[ $ASSUME_YES -eq 1 ]]; then
    return 0
  fi
  read -r -p "${prompt} [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

human_df() {
  # Print key filesystem usage lines
  df -h / 2>/dev/null | awk 'NR==1 || NR==2 {print}'
}

spotlight_status() {
  if ! command -v mdutil >/dev/null 2>&1; then
    say "mdutil not found; cannot check Spotlight status."
    return 0
  fi

  say "Spotlight status (mdutil):"
  mdutil -s / 2>&1 || true
}

spotlight_reindex() {
  if ! command -v mdutil >/dev/null 2>&1; then
    say "mdutil not found; cannot reindex Spotlight."
    return 1
  fi

  say "This will rebuild Spotlight index for / (can take a long time and use CPU)."
  if ! confirm "Proceed with Spotlight reindex?"; then
    say "Canceled."
    return 1
  fi

  # Ensure indexing is enabled then rebuild index.
  sudo mdutil -i on / || true
  sudo mdutil -E /

  say "Reindex kicked off. You can monitor progress in Activity Monitor (mds, mdworker, mdworker_shared)."
}

say "== Post-reboot macOS checks =="
say "Time: $(date)"
if command -v sw_vers >/dev/null 2>&1; then
  say "macOS: $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
fi

say ""
say "Disk usage (/):"
human_df

say ""
spotlight_status

if [[ $DO_REINDEX -eq 1 ]]; then
  say ""
  spotlight_reindex
else
  say ""
  say "Spotlight reindex skipped."
fi
