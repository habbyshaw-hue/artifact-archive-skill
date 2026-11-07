#!/usr/bin/env bash
# Claims an invite and saves this member's ID and token. Usage: join.sh CODE "DISPLAY NAME"
# The token goes straight to a private file and is never printed.
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
endpoint="${ARCHIVE_ENDPOINT:-https://artifactarchive.ai}"
token_file="${ARTIFACT_ARCHIVE_CREDENTIALS:-$HOME/.config/artifact-archive/credentials}"

die() { echo "$1" >&2; exit 1; }

[ $# -eq 2 ] || die 'Usage: join.sh CODE "DISPLAY NAME"'

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
code="$(curl -sS --max-time 60 -o "$work/reply.json" -w '%{http_code}' --data-urlencode "code=$1" --data-urlencode "name=$2" "$endpoint/api/v1/join")" \
  || die "Could not reach $endpoint."
if [ "$code" != 201 ]; then
  message="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("error", "The archive refused."))' "$work/reply.json" 2>/dev/null || echo "The archive refused.")"
  die "$code: $message"
fi

mkdir -p "$(dirname "$token_file")"
python3 - "$work/reply.json" "$skill_dir/member.json" "$token_file" "$endpoint" <<'PY'
import json, os, sys
reply, member, token_file, endpoint = sys.argv[1:]
data = json.load(open(reply))
with open(member, "w") as out:
    json.dump({"handle": data["handle"], "endpoint": endpoint}, out, indent=2)
    out.write("\n")
descriptor = os.open(token_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(descriptor, "w") as out:
    out.write(data["token"])
os.chmod(token_file, 0o600)
print("Joined as", data["handle"])
PY
