#!/usr/bin/env bash
# =============================================================================
# Wayland Screenshot & OCR Helper (MangoWC & Sway)
# =============================================================================

# Prevent concurrent slurp sessions
pgrep -x slurp >/dev/null && exit 0

# Check for MangoWC
IS_MANGO=false
if command -v mmsg >/dev/null 2>&1 && { [ -n "$MANGO_INSTANCE_SIGNATURE" ] || [ "$XDG_CURRENT_DESKTOP" = "mango" ] || mmsg get version >/dev/null 2>&1; }; then
  IS_MANGO=true
fi

# MangoWC border restoration & cleanup trap
MANGO_RESTORED=false
restore_mango() {
  if [ "$IS_MANGO" = true ] && [ "$MANGO_RESTORED" = false ]; then
    MANGO_RESTORED=true
    mmsg dispatch setoption,borderpx,3 >/dev/null 2>&1
    mmsg dispatch setoption,border_radius,8 >/dev/null 2>&1
  fi
}

cleanup() {
  restore_mango
  [ -n "${TMP_IMG:-}" ] && rm -f "$TMP_IMG"
}
trap cleanup EXIT INT TERM HUP

if [ "$IS_MANGO" = true ]; then
  mmsg dispatch setoption,borderpx,0 >/dev/null 2>&1
  mmsg dispatch setoption,border_radius,0 >/dev/null 2>&1
fi

# Resolve accent color
ACCENT="6e94b2"
mango_conf="$HOME/.config/mango/colours.conf"
if [ -f "$mango_conf" ]; then
  col=$(sed -nE 's/^focuscolor.*0x([0-9a-fA-F]{6}).*/\1/p' "$mango_conf" | head -n1)
  [ -n "$col" ] && ACCENT="$col"
fi

# Query window bounding boxes (<x>,<y> <width>x<height>)
get_windows() {
  if [ "$IS_MANGO" = true ]; then
    if command -v jq >/dev/null 2>&1; then
      mmsg get all-clients 2>/dev/null | jq -r '
        .clients[]
        | select(.is_visible and (.is_swallowedby | not) and (.is_minimized | not) and .width > 0 and .height > 0)
        | "\(.x),\(.y) \(.width)x\(.height)"
      '
    elif command -v perl >/dev/null 2>&1; then
      mmsg get all-clients 2>/dev/null | perl -MJSON::PP -e '
        my $d = eval { decode_json(join("", <>)) };
        if ($d && $d->{clients}) {
          for my $c (@{$d->{clients}}) {
            if ($c->{is_visible} && !$c->{is_swallowedby} && !$c->{is_minimized} && $c->{width} > 0 && $c->{height} > 0) {
              print "$c->{x},$c->{y} $c->{width}x$c->{height}\n";
            }
          }
        }
      '
    fi
    return
  fi

  if [ -n "${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    swaymsg -t get_tree 2>/dev/null | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
  fi
}

windows=$(get_windows 2>/dev/null)

# Slurp styling
slurp_flags=(-c "#${ACCENT}ff" -s "#${ACCENT}25" -b "#00000080" -d)

# Selection
if [ -n "$windows" ]; then
  GEOM=$(printf '%s\n' "$windows" | slurp "${slurp_flags[@]}")
else
  GEOM=$(slurp "${slurp_flags[@]}")
fi

[ -z "$GEOM" ] && exit 0

# Warp pointer out of selection zone
if [ "$IS_MANGO" = true ]; then
  mmsg dispatch cursor:set_pos 0 0 >/dev/null 2>&1
elif command -v wlrctl >/dev/null 2>&1; then
  wlrctl pointer move -10000 -10000 >/dev/null 2>&1
fi

sleep 0.15

# Action execution
if [ "${1:-}" = "ocr" ]; then
  TMP_IMG=$(mktemp --suffix=.png /tmp/screenshot_ocr.XXXXXX)
  grim -g "$GEOM" "$TMP_IMG"
  restore_mango
  tesseract "$TMP_IMG" stdout -l eng 2>/dev/null | wl-copy && notify-send 'OCR Complete' 'Text copied to clipboard.'
else
  target_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}"
  mkdir -p "$target_dir"
  filename="$target_dir/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

  grim -g "$GEOM" - | tee "$filename" | wl-copy -t image/png
  restore_mango
fi
