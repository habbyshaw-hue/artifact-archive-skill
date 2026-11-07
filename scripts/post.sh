#!/usr/bin/env bash
# Usage: post.sh --check
#        post.sh --image FILE --note TEXT --approved --ai-confirmed
#        post.sh --show NUMBER
#        post.sh --remove NUMBER --approved
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
member_file="$skill_dir/member.json"
token_file="${ARTIFACT_ARCHIVE_CREDENTIALS:-$HOME/.config/artifact-archive/credentials}"
version_url="https://raw.githubusercontent.com/habbyshaw-hue/artifact-archive-skill/main/VERSION"

die() { echo "$1" >&2; exit 1; }

[ -f "$member_file" ] || die "Missing member.json. See README.md."
[ -f "$token_file" ] || die "Missing token file at $token_file. See README.md."
[ "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o077))' "$token_file")" = "0o0" ] \
  || die "The token file is readable by others. Run: chmod 600 \"$token_file\""

read_member() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$member_file" "$1"; }
handle="$(read_member handle)"
endpoint="$(read_member endpoint)"
endpoint="${endpoint%/}"
token="$(tr -d '[:space:]' < "$token_file")"

# Curl reads the token from stdin, so it never appears in the process list.
api() { printf 'header = "Authorization: Bearer %s"\n' "$token" | curl -sS --max-time 120 -K - "$@"; }

check() {
  local response code body
  response="$(api -w '\n%{http_code}' "$endpoint/api/v1/me")" || die "Could not reach $endpoint."
  code="${response##*$'\n'}"
  body="${response%$'\n'*}"
  [ "$code" = 200 ] || die "The archive refused the token ($code). $body"
  local server_handle
  server_handle="$(printf '%s' "$body" | python3 -c 'import json,sys; print(json.load(sys.stdin)["handle"])')"
  [ "$server_handle" = "$handle" ] || die "member.json says $handle, but the token belongs to $server_handle."
  server_gifs="$(printf '%s' "$body" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("animated_gifs") is True)')"
}

image=""; note=""; approved=0; ai_confirmed=0; only_check=0; show=""; remove=""
while [ $# -gt 0 ]; do
  case "$1" in
    --check) only_check=1; shift ;;
    --show) show="${2:-}"; shift 2 ;;
    --remove) remove="${2:-}"; shift 2 ;;
    --approved) approved=1; shift ;;
    --ai-confirmed) ai_confirmed=1; shift ;;
    --image) image="${2:-}"; shift 2 ;;
    --note) note="${2:-}"; shift 2 ;;
    *) die "Unknown option: $1" ;;
  esac
done

check
if [ "$only_check" = 1 ]; then
  echo "Ready to archive as $handle."
  # A failed check never blocks archiving.
  current="$(tr -d '[:space:]' < "$skill_dir/VERSION" 2>/dev/null || echo 0)"
  latest="$(curl -fsS --max-time 5 "$version_url" 2>/dev/null | tr -d '[:space:]' || true)"
  case "$latest" in
    ''|*[!0-9.]*) ;;
    "$current") ;;
    *)
      if [ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1)" = "$latest" ]; then
        echo "Update available: version $latest (you have $current). Run scripts/update.sh."
      fi
      ;;
  esac
  exit 0
fi

number_only() { case "$1" in ''|*[!0-9]*) die "Give the deposit's number, such as 12." ;; esac; printf '%d' "$((10#$1))"; }

if [ -n "$show" ]; then
  id="$(number_only "$show")"
  response="$(api -w '\n%{http_code}' "$endpoint/api/v1/posts/$id")" || die "Could not reach $endpoint."
  code="${response##*$'\n'}"
  body="${response%$'\n'*}"
  [ "$code" = 200 ] || die "Can't show that deposit ($code). $body"
  printf '%s' "$body" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["number"], "from", d["date"]); print(d["note"]); print(d["url"])'
  exit 0
fi

if [ -n "$remove" ]; then
  [ "$approved" = 1 ] || die "Not removed. The member has to confirm the number first."
  id="$(number_only "$remove")"
  response="$(api -w '\n%{http_code}' -X DELETE "$endpoint/api/v1/posts/$id")" || die "Could not reach $endpoint."
  code="${response##*$'\n'}"
  body="${response%$'\n'*}"
  [ "$code" = 200 ] || die "Not removed ($code). $body"
  echo "Removed deposit $id. This can't be undone."
  exit 0
fi

[ "$approved" = 1 ] || die "Not archived. The member has to approve it first."
[ "$ai_confirmed" = 1 ] || die "Not archived. The member has to confirm AI assistance was used."
[ -f "$image" ] || die "No image at: $image"
[ -n "$note" ] || die "The note is empty."
case "$image" in
  *.gif|*.GIF) [ "$server_gifs" = True ] || die "Not archived. This archive would keep only the first frame of a GIF." ;;
esac

response="$(api -w '\n%{http_code}' -F "image=@$image" --form-string "note=$note" \
  "$endpoint/api/v1/posts")" || die "The upload failed."
code="${response##*$'\n'}"
body="${response%$'\n'*}"
[ "$code" = 201 ] || die "Not archived ($code). $body"
printf '%s' "$body" | python3 -c 'import json,sys; print("Archived:", json.load(sys.stdin)["url"])'
