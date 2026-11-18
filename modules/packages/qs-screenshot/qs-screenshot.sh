#!/usr/bin/env bash
# Finish a screenshot: crop the frozen frame, then save and copy it, or OCR it
# into the clipboard. The overlay passes a crop; a whole-screen capture omits it.
set -euo pipefail

frozen=""
crop=""
mode="image"

while [ $# -gt 0 ]; do
  case "$1" in
    --frozen) frozen="${2:-}"; shift 2 ;;
    --crop)   crop="${2:-}";   shift 2 ;;
    --mode)   mode="${2:-}";   shift 2 ;;
    *)
      echo "qs-screenshot: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ -z "$frozen" ] || [ ! -f "$frozen" ]; then
  echo "usage: qs-screenshot --frozen FILE [--crop WxH+X+Y] [--mode image|text]" >&2
  exit 2
fi

# The crop geometry arrives in device pixels, so it maps straight onto the
# frozen frame, which grim wrote at the output's native resolution. A whole
# screen capture has no crop and is used as written, with no re-encode.
work="$frozen"
if [ -n "$crop" ]; then
  work=$(mktemp --suffix=.png "${TMPDIR:-/tmp}/qs-screenshot.XXXXXX")
fi
trap 'rm -f "$work" "$frozen"' EXIT
# A capture that dies here would otherwise leave no trace on screen.
trap 'notify-send -a Screenshot "Screenshot" "Could not finish the capture"' ERR

if [ -n "$crop" ]; then
  magick "$frozen" -crop "$crop" +repage "PNG24:$work"
fi

if [ "$mode" = "text" ]; then
  tesseract "$work" stdout -l eng 2>/dev/null | wl-copy
  notify-send -a Screenshot "Screenshot" "Text copied to clipboard"
else
  target_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
  mkdir -p "$target_dir"
  stamp=$(date +'%Y-%m-%d_%H-%M-%S')
  filename="$target_dir/screenshot_$stamp.png"
  # Two captures in the same second would otherwise overwrite each other.
  n=1
  while [ -e "$filename" ]; do
    n=$((n + 1))
    filename="$target_dir/screenshot_$stamp-$n.png"
  done
  cp "$work" "$filename"
  wl-copy -t image/png < "$filename"
  notify-send -a Screenshot "Screenshot" "Saved $(basename "$filename")"
fi
