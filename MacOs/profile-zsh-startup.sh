#!/usr/bin/env bash
set -euo pipefail

# Profiles zsh startup time without flooding the terminal.
# Writes reports under MacOs/zsh-backups/ (gitignored).

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

out_root="$repo_root/MacOs/zsh-backups"
mkdir -p "$out_root"

ts="$(date +%Y%m%d-%H%M%S)"
out_dir="$out_root/zsh-startup-profile-$ts"
mkdir -p "$out_dir"

echo "Writing zsh startup profile to: $out_dir"

bench_file="$out_dir/bench.txt"
: > "$bench_file"

echo "== time (5 runs) ==" >> "$bench_file"
for i in {1..5}; do
  echo "-- run $i: zsh -i -c exit" >> "$bench_file"
  /usr/bin/time -p zsh -i -c exit >> "$bench_file" 2>&1
  echo "-- run $i: zsh -l -i -c exit" >> "$bench_file"
  /usr/bin/time -p zsh -l -i -c exit >> "$bench_file" 2>&1
  echo "" >> "$bench_file"
done

# zprof for interactive shells
zprof_i="$out_dir/zprof-interactive.txt"
zprof_li="$out_dir/zprof-login-interactive.txt"

profile_with_zdotdir() {
  local mode="$1" outfile="$2"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  # Wrapper .zshrc that enables zprof before sourcing the real ~/.zshrc
  cat > "$tmp/.zshrc" <<EOF
zmodload zsh/zprof
source "$HOME/.zshrc"
zprof > "$outfile"
EOF

  if [[ "$mode" == "interactive" ]]; then
    ZDOTDIR="$tmp" zsh -i -c exit >/dev/null 2>&1 || true
  else
    # login + interactive reads .zprofile then .zshrc; provide a wrapper .zprofile too.
    cat > "$tmp/.zprofile" <<EOF
source "$HOME/.zprofile" 2>/dev/null || true
EOF
    ZDOTDIR="$tmp" zsh -l -i -c exit >/dev/null 2>&1 || true
  fi
}

profile_with_zdotdir "interactive" "$zprof_i"
profile_with_zdotdir "login-interactive" "$zprof_li"

# Small summary to avoid long output in VS Code terminal.
summary="$out_dir/summary.txt"
{
  echo "== bench (tail) =="
  tail -n 30 "$bench_file" || true
  echo ""
  echo "== zprof interactive (head 40) =="
  head -n 40 "$zprof_i" || true
  echo ""
  echo "== zprof login-interactive (head 40) =="
  head -n 40 "$zprof_li" || true
} > "$summary"

echo "Done. Quick summary: $summary"
