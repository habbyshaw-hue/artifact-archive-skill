#!/usr/bin/env bash
# Updates this skill from GitHub. Your member.json and token are left alone.
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_url="https://codeload.github.com/habbyshaw-hue/artifact-archive-skill/tar.gz/refs/heads/main"

die() { echo "$1" >&2; exit 1; }

[ ! -e "$skill_dir/.git" ] || die "This is the working copy of the skill. Use git here."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
curl -fsSL --max-time 60 "$source_url" -o "$work/skill.tar.gz" || die "Could not download the update."
tar -xzf "$work/skill.tar.gz" -C "$work" --strip-components=1
[ -f "$work/SKILL.md" ] && [ -f "$work/VERSION" ] && [ -f "$work/scripts/post.sh" ] || die "The download looks incomplete. Nothing was changed."

cp "$work/SKILL.md" "$work/README.md" "$work/VERSION" "$work/install.sh" "$skill_dir/"
rm -rf "$skill_dir/scripts.new"
cp -R "$work/scripts" "$skill_dir/scripts.new"
chmod +x "$skill_dir"/scripts.new/*
rm -rf "$skill_dir/scripts"
mv "$skill_dir/scripts.new" "$skill_dir/scripts"
echo "Updated to version $(tr -d '[:space:]' < "$skill_dir/VERSION")."
