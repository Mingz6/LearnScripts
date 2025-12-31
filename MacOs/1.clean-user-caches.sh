#!/usr/bin/env bash
set -euo pipefail

# 1.clean-user-caches.sh
# Safe-by-default macOS cache cleanup for current user.
# - Does NOT touch /System or /Library by default.
# - Supports dry-run preview and confirmation.
# - Targets are user-level only; some heavier caches can be excluded.

usage() {
  cat <<'EOF'
Usage:
  1.clean-user-caches.sh [options]

Options:
  --dry-run            Show what would be deleted (default)
  --yes                Actually delete without prompts
  --quit-apps          Attempt to stop some common apps before deleting their caches (pkill only; no Automation prompts)
  --quit-app           Alias of --quit-apps
  --no-quit-apps       Do NOT stop apps before deleting caches
  --graceful-quit      Use AppleScript (osascript) to quit apps first (may trigger macOS “access data from other apps” prompts)
  --exclude-vscode     Do NOT delete VS Code cache
  --exclude-apple-ui   Do NOT delete low-risk Apple UI caches (wallpaper, geod, news widget, iBooks caches)
  --exclude-siri       Do NOT delete Siri TTS cache
  --exclude-homebrew   Do NOT delete Homebrew download cache under ~/Library/Caches/Homebrew
  --exclude-xcode      Do NOT delete Xcode/Simulator caches (DerivedData, DeviceSupport, CoreSimulator/Caches)
  --exclude-apple-ml   Do NOT delete Apple media/photo analysis caches (may trigger re-analysis, CPU spike)
  --exclude-telegram   Do NOT delete Telegram media cache (will re-download media)
  --exclude-logs       Do NOT delete ~/Library/Logs (and Microsoft container Diagnostics logs)
  --exclude-wallpaper-aerials  Do NOT delete Apple Aerials wallpaper/screensaver videos (~com.apple.wallpaper/aerials)
  --include-wallpaper-aerials  Alias: include Apple Aerials videos even if excluded
  --quit-vscode        Quit VS Code (only used with --quit-apps)
  --restart-vscode     Re-open VS Code after cleanup
  --include-xcode      Alias: include Xcode cleanup even if excluded
  --include-apple-ml   Alias: include Apple ML cleanup even if excluded
  --include-telegram   Alias: include Telegram cleanup even if excluded
  --include-logs       Alias: include logs cleanup even if excluded
  --include-apple-ui   Alias: include Apple UI caches even if excluded
  --include-siri       Alias: include Siri cache even if excluded
  --include-homebrew   Alias: include Homebrew cache even if excluded
  -h, --help           Show help

Examples:
  # Preview only (recommended first)
  ./1.clean-user-caches.sh --dry-run

  # Clean common user caches without prompts (default includes common caches + logs/diagnostics)
  ./1.clean-user-caches.sh --yes

  # Exclude heavier modules if you don't want them
  ./1.clean-user-caches.sh --yes --exclude-xcode --exclude-apple-ml

  # Add low-risk Apple UI caches
  ./1.clean-user-caches.sh --yes --quit-apps --include-apple-ui

  # Keep VS Code running (recommended when running inside VS Code terminal)
  ./1.clean-user-caches.sh --yes --exclude-vscode

  # If you WANT to clean VS Code cache, do it explicitly and restart it afterwards
  ./1.clean-user-caches.sh --yes --quit-vscode --restart-vscode

  # Big item: Apple Aerials videos are included by default; exclude if you want to keep them
  ./1.clean-user-caches.sh --yes --exclude-wallpaper-aerials
EOF
}

DRY_RUN=1
ASSUME_YES=0

# Default behavior:
# - Clean most user caches
# - Also clean VS Code + Apple UI + Siri + Homebrew caches by default
# - Also clean logs/xcode/apple-ml/telegram by default (use --exclude-* to opt out)
INCLUDE_XCODE=1
INCLUDE_APPLE_ML=1
INCLUDE_TELEGRAM=1
INCLUDE_LOGS=1
INCLUDE_WALLPAPER_AERIALS=1
QUIT_APPS=0
QUIT_APPS_SET=0
QUIT_VSCODE=0
QUIT_VSCODE_SET=0
RESTART_VSCODE=0
GRACEFUL_QUIT=0

EXCLUDE_VSCODE=0
EXCLUDE_APPLE_UI=0
EXCLUDE_SIRI=0
EXCLUDE_HOMEBREW=0
EXCLUDE_XCODE=0
EXCLUDE_APPLE_ML=0
EXCLUDE_TELEGRAM=0
EXCLUDE_LOGS=0
EXCLUDE_WALLPAPER_AERIALS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --yes) DRY_RUN=0; ASSUME_YES=1; shift ;;
    --exclude-xcode) EXCLUDE_XCODE=1; shift ;;
    --exclude-apple-ml) EXCLUDE_APPLE_ML=1; shift ;;
    --exclude-telegram) EXCLUDE_TELEGRAM=1; shift ;;
    --exclude-logs) EXCLUDE_LOGS=1; shift ;;
    --include-xcode) INCLUDE_XCODE=1; EXCLUDE_XCODE=0; shift ;;
    --include-apple-ml) INCLUDE_APPLE_ML=1; EXCLUDE_APPLE_ML=0; shift ;;
    --include-telegram) INCLUDE_TELEGRAM=1; EXCLUDE_TELEGRAM=0; shift ;;
    --include-logs) INCLUDE_LOGS=1; EXCLUDE_LOGS=0; shift ;;
    --include-apple-ui) EXCLUDE_APPLE_UI=0; shift ;;
    --include-siri) EXCLUDE_SIRI=0; shift ;;
    --include-homebrew) EXCLUDE_HOMEBREW=0; shift ;;
    --exclude-wallpaper-aerials) EXCLUDE_WALLPAPER_AERIALS=1; shift ;;
    --include-wallpaper-aerials) INCLUDE_WALLPAPER_AERIALS=1; EXCLUDE_WALLPAPER_AERIALS=0; shift ;;
    --quit-apps) QUIT_APPS=1; QUIT_APPS_SET=1; shift ;;
    --quit-app) QUIT_APPS=1; QUIT_APPS_SET=1; shift ;;
    --no-quit-apps) QUIT_APPS=0; QUIT_APPS_SET=1; shift ;;
    --graceful-quit) GRACEFUL_QUIT=1; shift ;;
    --exclude-vscode) EXCLUDE_VSCODE=1; shift ;;
    --exclude-apple-ui) EXCLUDE_APPLE_UI=1; shift ;;
    --exclude-siri) EXCLUDE_SIRI=1; shift ;;
    --exclude-homebrew) EXCLUDE_HOMEBREW=1; shift ;;
    --quit-vscode) QUIT_VSCODE=1; QUIT_VSCODE_SET=1; shift ;;
    --restart-vscode) RESTART_VSCODE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac
done

# Default behavior: only stop apps when we are actually deleting.
if [[ $DRY_RUN -eq 0 && $QUIT_APPS_SET -eq 0 ]]; then
  QUIT_APPS=1
fi

# If we are deleting VS Code cache and we are stopping apps, quit VS Code by default.
if [[ $DRY_RUN -eq 0 && $QUIT_APPS -eq 1 && $EXCLUDE_VSCODE -eq 0 && $QUIT_VSCODE_SET -eq 0 ]]; then
  QUIT_VSCODE=1
fi

say() { printf '%s\n' "$*"; }

quit_app() {
  local app_name="$1"
  # Best effort (may trigger macOS Automation prompts)
  osascript -e "quit app \"${app_name}\"" >/dev/null 2>&1 || true
}

pkill_name() {
  local proc_name="$1"
  pkill -x "$proc_name" >/dev/null 2>&1 || true
}

confirm() {
  local prompt="$1"
  if [[ $ASSUME_YES -eq 1 ]]; then
    return 0
  fi
  read -r -p "${prompt} [y/N] " ans
  [[ "${ans}" == "y" || "${ans}" == "Y" ]]
}

# Targets (safe-ish, user-level)
TARGETS=(
  "$HOME/Library/Caches"  # broad user caches
  "$HOME/.npm/_npx"  # npx cache
  "$HOME/Library/HTTPStorages"  # URLSession caches (usually safe to delete; will be rebuilt)
)

if [[ $EXCLUDE_VSCODE -eq 0 ]]; then
  TARGETS+=("$HOME/Library/Application Support/Code/Cache")
  # Extra VS Code caches
  TARGETS+=(
    "$HOME/Library/Application Support/Code/CachedData"
    "$HOME/Library/Application Support/Code/CachedExtensionVSIXs"
    "$HOME/Library/Application Support/Code/Service Worker/CacheStorage"
  )
fi

# Cursor (VS Code-like) caches
TARGETS+=(
  "$HOME/Library/Application Support/Cursor/Cache"
  "$HOME/Library/Application Support/Cursor/CachedData"
  "$HOME/Library/Application Support/Cursor/CachedExtensionVSIXs"
)

# Microsoft Edge caches
TARGETS+=(
  "$HOME/Library/Application Support/Microsoft Edge/Default/Service Worker/CacheStorage"
  "$HOME/Library/Application Support/Microsoft Edge/extensions_crx_cache"
)

# Steam caches
TARGETS+=(
  "$HOME/Library/Application Support/Steam/appcache"
  "$HOME/Library/Application Support/Steam/config/htmlcache"
)

# Postman caches (Partition IDs vary; best-effort)
POSTMAN_PARTITIONS="$HOME/Library/Application Support/Postman/Partitions"
if [[ -d "$POSTMAN_PARTITIONS" ]]; then
  while IFS= read -r -d '' p; do
    TARGETS+=("$p")
  done < <(
    find "$POSTMAN_PARTITIONS" -maxdepth 3 -type d \( -name Cache -o -name "Code Cache" \) -print0 2>/dev/null || true
  )
fi

# Google Updater caches
TARGETS+=(
  "$HOME/Library/Application Support/Google/GoogleUpdater/crx_cache"
)

if [[ $EXCLUDE_SIRI -eq 0 ]]; then
  TARGETS+=("$HOME/Library/Caches/SiriTTS")
fi

if [[ $EXCLUDE_HOMEBREW -eq 0 ]]; then
  TARGETS+=("$HOME/Library/Caches/Homebrew")
fi



# App-specific caches (only if present)
TARGETS+=(
  "$HOME/Library/Containers/com.microsoft.teams2/Data/Library/Caches"  # new Teams caches
  "$HOME/Library/Application Support/discord/Cache"  # Discord cache
)

# Outlook caches (can be "felt"; still typically safe)
TARGETS+=(
  "$HOME/Library/Containers/com.microsoft.Outlook/Data/Library/Caches"
)

if [[ $INCLUDE_LOGS -eq 1 && $EXCLUDE_LOGS -eq 0 ]]; then
  TARGETS+=("$HOME/Library/Logs")
  # Common app logs (can get very large; safe to delete)
  TARGETS+=(
    "$HOME/Library/Application Support/Code/logs"
    "$HOME/Library/Application Support/Cursor/logs"
    "$HOME/Library/Application Support/discord/logs"
  )
  # Microsoft Office container diagnostics logs (can grow large)
  # Auto-detect any com.microsoft.* containers that have a Diagnostics log directory.
  for ms_container in "$HOME/Library/Containers"/com.microsoft.*; do
    [[ -d "$ms_container" ]] || continue
    ms_logs="$ms_container/Data/Library/Logs"
    [[ -d "$ms_logs" ]] && TARGETS+=("$ms_logs")
    diag="$ms_container/Data/Library/Logs/Diagnostics"
    [[ -d "$diag" ]] && TARGETS+=("$diag")
  done
fi

if [[ $INCLUDE_XCODE -eq 1 && $EXCLUDE_XCODE -eq 0 ]]; then
  TARGETS+=(
    "$HOME/Library/Developer/CoreSimulator/Caches"
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    "$HOME/Library/Developer/Xcode/DerivedData"
  )
fi

if [[ $INCLUDE_APPLE_ML -eq 1 && $EXCLUDE_APPLE_ML -eq 0 ]]; then
  TARGETS+=(
    "$HOME/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches"
    "$HOME/Library/Containers/com.apple.photoanalysisd/Data/Library/Caches"
  )
fi

if [[ $EXCLUDE_APPLE_UI -eq 0 ]]; then
  TARGETS+=(
    "$HOME/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches/com.apple.wallpaper.caches"
    "$HOME/Library/Containers/com.apple.geod/Data/Library/Caches/com.apple.geod"
    "$HOME/Library/Containers/com.apple.news.widget/Data/Library/Caches"
    "$HOME/Library/Containers/com.apple.iBooksX/Data/Library/Caches"
  )
fi

if [[ $INCLUDE_TELEGRAM -eq 1 && $EXCLUDE_TELEGRAM -eq 0 ]]; then
  # Telegram path can vary; delete media directories if they exist under Telegram group container.
  # This is best-effort and intentionally narrow.
  TELEGRAM_ROOT="$HOME/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram"
  if [[ -d "$TELEGRAM_ROOT" ]]; then
    # Find a few common media directories without traversing the whole disk.
    while IFS= read -r -d '' p; do
      TARGETS+=("$p")
    done < <(find "$TELEGRAM_ROOT" -maxdepth 6 -type d -name media -print0 2>/dev/null || true)
  fi
fi

if [[ $INCLUDE_WALLPAPER_AERIALS -eq 1 && $EXCLUDE_WALLPAPER_AERIALS -eq 0 ]]; then
  TARGETS+=("$HOME/Library/Application Support/com.apple.wallpaper/aerials")
fi

if [[ $QUIT_APPS -eq 1 ]]; then
  if [[ $GRACEFUL_QUIT -eq 1 ]]; then
    say "Quitting apps gracefully (osascript; may trigger macOS prompts)..."
    quit_app "Microsoft Teams"; sleep 1
    quit_app "Microsoft Outlook"; sleep 1
    quit_app "Microsoft Excel"; sleep 1
    quit_app "Microsoft Word"; sleep 1
    quit_app "Microsoft PowerPoint"; sleep 1
    quit_app "Discord"; sleep 1

    if [[ $QUIT_VSCODE -eq 1 ]]; then
      quit_app "Visual Studio Code"; sleep 1
    fi
  fi

  say "Stopping apps (pkill; no Automation prompts)..."
  pkill_name "Microsoft Teams"
  pkill_name "Microsoft Outlook"
  pkill_name "Microsoft Excel"
  pkill_name "Microsoft Word"
  pkill_name "Microsoft PowerPoint"
  pkill_name "Discord"

  if [[ $QUIT_VSCODE -eq 1 ]]; then
    pkill_name "Code"
  fi
  say "Done."
fi

# De-dupe targets and keep only existing paths (bash 3.2 compatible; no mapfile)
EXISTING=()
while IFS= read -r p; do
  [[ -e "$p" ]] && EXISTING+=("$p") || true
done < <(
  printf '%s\n' "${TARGETS[@]}" | awk 'NF' | sort -u
)

if [[ ${#EXISTING[@]} -eq 0 ]]; then
  say "No cache paths found to process."
  exit 0
fi

say "Targets:"
TOTAL_KB_BEFORE=0
UNKNOWN_COUNT_BEFORE=0
BEFORE_KB_LIST=()
for p in "${EXISTING[@]}"; do
  # Use du if available; ignore permission errors
  size_h=$(du -sh "$p" 2>/dev/null | awk '{print $1}' || true)
  size_kb=$(du -sk "$p" 2>/dev/null | awk '{print $1}' || true)

  if [[ -n "$size_kb" ]]; then
    TOTAL_KB_BEFORE=$((TOTAL_KB_BEFORE + size_kb))
    BEFORE_KB_LIST+=("$size_kb")
  else
    UNKNOWN_COUNT_BEFORE=$((UNKNOWN_COUNT_BEFORE + 1))
    BEFORE_KB_LIST+=("")
  fi

  if [[ -n "$size_h" ]]; then
    say "  - $p ($size_h)"
  else
    say "  - $p"
  fi
done

total_h=$(echo "$TOTAL_KB_BEFORE" | awk '{ kb=$1; if (kb<=0) {print "0B"; exit}
  b=kb*1024;
  split("B KB MB GB TB PB",u," ");
  i=1;
  while (b>=1024 && i<6) { b/=1024; i++ }
  printf "%.1f%s", b, u[i]
}')

if [[ $UNKNOWN_COUNT_BEFORE -gt 0 ]]; then
  say ""
  say "Total (known): ${total_h}  | Unknown size entries: ${UNKNOWN_COUNT_BEFORE}"
else
  say ""
  say "Total: ${total_h}"
fi

if [[ $DRY_RUN -eq 1 ]]; then
  say ""
  say "DRY RUN: nothing was deleted. Re-run with --yes to delete."
  exit 0
fi

if ! confirm "Proceed to delete the targets above?"; then
  say "Canceled."
  exit 1
fi

say "Deleting..."

TOTAL_KB_AFTER=0
UNKNOWN_COUNT_AFTER=0

# Delete contents for broad directories, not the directory itself.
# For specific directories, remove directory contents as well.
for p in "${EXISTING[@]}"; do
  if [[ -d "$p" ]]; then
    # Remove contents only
    find "$p" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
  else
    rm -rf "$p" 2>/dev/null || true
  fi
  say "  deleted: $p"

  # Best-effort measure size after deletion to estimate freed space.
  after_kb=$(du -sk "$p" 2>/dev/null | awk '{print $1}' || true)
  if [[ -n "$after_kb" ]]; then
    TOTAL_KB_AFTER=$((TOTAL_KB_AFTER + after_kb))
  else
    # If it no longer exists (or can't be measured), treat as 0 and count unknown.
    [[ -e "$p" ]] && UNKNOWN_COUNT_AFTER=$((UNKNOWN_COUNT_AFTER + 1)) || true
  fi
done

FREED_KB=$((TOTAL_KB_BEFORE - TOTAL_KB_AFTER))
if [[ $FREED_KB -lt 0 ]]; then
  FREED_KB=0
fi

freed_h=$(echo "$FREED_KB" | awk '{ kb=$1; if (kb<=0) {print "0B"; exit}
  b=kb*1024;
  split("B KB MB GB TB PB",u," ");
  i=1;
  while (b>=1024 && i<6) { b/=1024; i++ }
  printf "%.1f%s", b, u[i]
}')

if [[ $UNKNOWN_COUNT_BEFORE -gt 0 || $UNKNOWN_COUNT_AFTER -gt 0 ]]; then
  say ""
  say "Estimated freed (known): ${freed_h}  | Unknown entries (before/after): ${UNKNOWN_COUNT_BEFORE}/${UNKNOWN_COUNT_AFTER}"
else
  say ""
  say "Estimated freed: ${freed_h}"
fi

if [[ $RESTART_VSCODE -eq 1 ]]; then
  # Best-effort re-open
  open -a "Visual Studio Code" >/dev/null 2>&1 || true
fi

say "Done. A reboot/log-out can help with UI/font cache refresh."
