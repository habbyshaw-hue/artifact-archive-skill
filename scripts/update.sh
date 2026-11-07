#!/usr/bin/env bash
# Pulls the latest skill from GitHub. Your member.json and token aren't in the repo, so they're left alone.
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
[ -e "$skill_dir/.git" ] || { echo "This copy wasn't installed with git. Ask for a new invite link." >&2; exit 1; }
git -C "$skill_dir" pull --ff-only origin main
chmod +x "$skill_dir"/scripts/*
echo "Up to date: version $(tr -d '[:space:]' < "$skill_dir/VERSION")."
