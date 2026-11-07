#!/usr/bin/env bash
# Usage: make_gif.sh --frames FOLDER --out FILE.gif [--fps 20] [--edge 480]
#        make_gif.sh --video FILE --out FILE.gif [--fps 20] [--edge 480]
set -euo pipefail

die() { echo "$1" >&2; exit 1; }

frames=""; video=""; out=""; fps=20; edge=480
while [ $# -gt 0 ]; do
  case "$1" in
    --frames) frames="${2:-}"; shift 2 ;;
    --video) video="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    --fps) fps="${2:-}"; shift 2 ;;
    --edge) edge="${2:-}"; shift 2 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[ -n "$out" ] || die "Say where the GIF goes with --out."
[ "$edge" -le 1200 ] || die "The archive's limit is 1200 pixels on the long edge."
command -v magick >/dev/null || die "ImageMagick is missing. Run: brew install imagemagick"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
if [ -n "$video" ]; then
  [ -f "$video" ] || die "No video at: $video"
  command -v ffmpeg >/dev/null || die "ffmpeg is missing. Run: brew install ffmpeg"
  ffmpeg -loglevel error -i "$video" -vf "fps=$fps" "$work/%04d.png" || die "ffmpeg could not read the video."
  frames="$work"
fi
[ -d "$frames" ] || die "No frames folder at: $frames"

list="$work/frames.txt"
find "$frames" -maxdepth 1 -name '*.png' | sort > "$list"
count="$(wc -l < "$list" | tr -d ' ')"
[ "$count" -ge 2 ] || die "A GIF needs at least two PNG frames."
[ "$count" -le 300 ] || die "$count frames is over the archive's limit of 300. Lower --fps or shorten the clip."

delay="$(python3 -c 'import sys; print(max(2, round(100 / float(sys.argv[1]))))' "$fps")"
magick -delay "$delay" -loop 0 "@$list" -resize "${edge}x${edge}>" -dither None -colors 128 \
  -layers OptimizeTransparency "$out"

bytes="$(wc -c < "$out" | tr -d ' ')"
[ "$bytes" -le 10485760 ] || die "$out is $((bytes / 1048576)) MB, over the archive's 10 MB limit. Lower --edge or --fps."
echo "$out: $count frames, $((bytes / 1024)) KB."
