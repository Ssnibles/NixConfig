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

# Locate wlrctl (check PATH, then nix store fallback)
WLRCTL=""
if command -v wlrctl >/dev/null 2>&1; then
  WLRCTL="wlrctl"
else
  for p in /nix/store/*-wlrctl-*/bin/wlrctl; do
    if [ -x "$p" ]; then
      WLRCTL="$p"
      break
    fi
  done
fi

# MangoWC borders: query defaults from config or fallback to standard values
BORDERPX=2
BORDER_RADIUS=8
mango_conf="$HOME/.config/mango/config.conf"
if [ -f "$mango_conf" ]; then
  b_px=$(sed -nE 's/^[[:space:]]*borderpx[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' "$mango_conf" | head -n1)
  b_rad=$(sed -nE 's/^[[:space:]]*border_radius[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' "$mango_conf" | head -n1)
  [ -n "$b_px" ] && BORDERPX="$b_px"
  [ -n "$b_rad" ] && BORDER_RADIUS="$b_rad"
fi

# MangoWC border restoration & cleanup trap
#
# setoption is the only way to change borderpx/border_radius at runtime, but
# every setoption call ends up re-applying the tagrules (reset_option ->
# reapply_tagrule), which forces the configured default layout on every tag.
# Snapshot the focused tag's layout first so it can be put back afterwards.
#
# NOTE: temporarily disabled to test the compositor-side fix (PR #1451); the
# snapshot/restore calls below are commented out. Re-enable if running an
# unpatched mango.
MANGO_LAYOUT=""
mango_snapshot_layout() {
  if [ "$IS_MANGO" != true ]; then
    return
  fi
  local mon sym
  mon=$(mmsg get all-monitors 2>/dev/null) || return
  sym=$(printf '%s\n' "$mon" | grep -o '"active":true[^}]*' \
    | grep -o '"layout_symbol":"[^"]*"' | head -n1 \
    | sed -E 's/.*"layout_symbol":"([^"]*)".*/\1/')
  [ -n "$sym" ] || return
  MANGO_LAYOUT=$(mmsg get layouts 2>/dev/null \
    | grep -o "{[^{}]*\"symbol\":\"$sym\"[^{}]*}" | head -n1 \
    | sed -E 's/.*"name":"([^"]*)".*/\1/')
}

MANGO_RESTORED=false
restore_mango() {
  if [ "$IS_MANGO" = true ] && [ "$MANGO_RESTORED" = false ]; then
    MANGO_RESTORED=true
    mmsg dispatch setoption,borderpx,"$BORDERPX" >/dev/null 2>&1
    mmsg dispatch setoption,border_radius,"$BORDER_RADIUS" >/dev/null 2>&1
    # [ -n "$MANGO_LAYOUT" ] && mmsg dispatch setlayout,"$MANGO_LAYOUT" >/dev/null 2>&1
  fi
}

ORIG_X=""
ORIG_Y=""
restore_cursor() {
  if [ -n "$ORIG_X" ] && [ -n "$ORIG_Y" ] && [ -n "$WLRCTL" ]; then
    "$WLRCTL" pointer move -10000 -10000 >/dev/null 2>&1
    "$WLRCTL" pointer move "$ORIG_X" "$ORIG_Y" >/dev/null 2>&1
    ORIG_X=""
    ORIG_Y=""
  fi
}

restore_all() {
  restore_cursor
  restore_mango
}

cleanup() {
  restore_all
  [ -n "${TMP_IMG:-}" ] && rm -f "$TMP_IMG"
}
trap cleanup EXIT INT TERM HUP

if [ "$IS_MANGO" = true ]; then
  # mango_snapshot_layout
  mmsg dispatch setoption,borderpx,0 >/dev/null 2>&1
  mmsg dispatch setoption,border_radius,0 >/dev/null 2>&1
  # Workaround for unpatched mango: setoption re-applies tagrules and resets
  # the layout. Disabled while testing the compositor-side fix (PR #1451).
  # [ -n "$MANGO_LAYOUT" ] && mmsg dispatch setlayout,"$MANGO_LAYOUT" >/dev/null 2>&1
fi

# Resolve accent color
ACCENT="6e94b2"
mango_colours="$HOME/.config/mango/colours.conf"
if [ -f "$mango_colours" ]; then
  col=$(sed -nE 's/^focuscolor.*0x([0-9a-fA-F]{6}).*/\1/p' "$mango_colours" | head -n1)
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

# Warp cursor away from selection to avoid capturing software cursor
if [ -n "$WLRCTL" ]; then
  if [ "$IS_MANGO" = true ]; then
    pos=$(mmsg get cursorpos 2>/dev/null)
    if [ -n "$pos" ]; then
      ORIG_X=$(sed -nE 's/.*"x":[[:space:]]*([0-9]+).*/\1/p' <<<"$pos")
      ORIG_Y=$(sed -nE 's/.*"y":[[:space:]]*([0-9]+).*/\1/p' <<<"$pos")
    fi
  fi
  "$WLRCTL" pointer move 10000 10000 >/dev/null 2>&1
  sleep 0.08
fi

# Action execution
if [ "${1:-}" = "ocr" ]; then
  TMP_IMG=$(mktemp --suffix=.png /tmp/screenshot_ocr.XXXXXX)
  grim -g "$GEOM" "$TMP_IMG"
  restore_all
  tesseract "$TMP_IMG" stdout -l eng 2>/dev/null | wl-copy && notify-send 'OCR Complete' 'Text copied to clipboard.'
else
  target_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}"
  mkdir -p "$target_dir"
  filename="$target_dir/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

  grim -g "$GEOM" - | tee "$filename" | wl-copy -t image/png
  restore_all
fi
