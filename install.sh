#!/usr/bin/env bash
# Installs the skill from the zip the join page gave you. Run: sh install.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
dest="$HOME/.claude/skills/artifact-archive-post"
token_file="$HOME/.config/artifact-archive/credentials"

die() { echo "$1" >&2; exit 1; }

[ -f "$here/credentials" ] || die "No credentials file here. Run this from the folder in your zip."
[ ! -e "$dest" ] || die "Already installed at $dest. Remove it first if you want to replace it."
[ ! -e "$token_file" ] || die "A token already exists at $token_file. Remove it first if you want to replace it."

mkdir -p "$(dirname "$dest")" "$(dirname "$token_file")"
mkdir "$dest"
cp "$here/SKILL.md" "$here/README.md" "$here/VERSION" "$here/member.json" "$dest/"
cp -R "$here/scripts" "$dest/scripts"
chmod +x "$dest"/scripts/*
( umask 077; cp "$here/credentials" "$token_file" )
rm "$here/credentials"

"$dest/scripts/post.sh" --check
echo "Installed. Delete the zip, then tell Claude: Archive this to Artifact Archive."
