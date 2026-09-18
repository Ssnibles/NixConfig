#!/usr/bin/env bash
# =============================================================================
# Wayland Screenshot & OCR Helper
# =============================================================================
# Supports window snapping/highlighting across MangoWC, Hyprland, and Sway,
# with fallback to freeform region selection.
# =============================================================================

# Prevent concurrent slurp sessions
pgrep -x slurp >/dev/null && exit 0

# Determine accent color from theme configuration
ACCENT="6e94b2"
if [ -f "$HOME/.config/mango/colours.conf" ]; then
  col=$(grep -m1 '^focuscolor' "$HOME/.config/mango/colours.conf" 2>/dev/null | sed -E 's/.*0x([0-9a-fA-F]{6}).*/\1/')
  [ -n "$col" ] && ACCENT="$col"
elif [ -f "$HOME/.config/hypr/generated.lua" ]; then
  col=$(grep -m1 'M.accent' "$HOME/.config/hypr/generated.lua" 2>/dev/null | sed -E 's/.*"([0-9a-fA-F]{6})".*/\1/')
  [ -n "$col" ] && ACCENT="$col"
fi

# Query window bounding boxes (<x>,<y> <width>x<height>) from the active compositor
get_windows() {
  # MangoWC
  if [ -n "$MANGO_INSTANCE_SIGNATURE" ] || [ "$XDG_CURRENT_DESKTOP" = "mango" ] || command -v mmsg >/dev/null 2>&1; then
    if command -v jq >/dev/null 2>&1; then
      mmsg get all-clients 2>/dev/null | jq -r '.clients[] | select(.is_visible and (.is_swallowedby | not) and (.is_minimized | not) and .width > 0 and .height > 0) | "\(.x),\(.y) \(.width)x\(.height)"'
    elif command -v perl >/dev/null 2>&1; then
      mmsg get all-clients 2>/dev/null | perl -MJSON::PP -e '
                $d = eval { decode_json(join("", <STDIN>)) };
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

  # Hyprland
  if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || command -v hyprctl >/dev/null 2>&1; then
    if command -v jq >/dev/null 2>&1; then
      workspaces=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | .activeWorkspace.id] + [.[] | select(.specialWorkspace.id != 0) | .specialWorkspace.id]')
      hyprctl clients -j 2>/dev/null | jq -r --argjson ws "$workspaces" '.[] | select((.workspace.id as $id | $ws | index($id)) and .mapped and (.hidden | not) and .size[0] > 0 and .size[1] > 0) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
    elif command -v perl >/dev/null 2>&1; then
      perl -MJSON::PP -e '
                my $mons = eval { decode_json(`hyprctl monitors -j 2>/dev/null`) } || [];
                my %active_ws = map { $_->{activeWorkspace}{id} => 1 } @$mons;
                for my $m (@$mons) {
                    $active_ws{$m->{specialWorkspace}{id}} = 1 if $m->{specialWorkspace}{id};
                }
                my $clients = eval { decode_json(`hyprctl clients -j 2>/dev/null`) } || [];
                for my $c (@$clients) {
                    if ($active_ws{$c->{workspace}{id}} && $c->{mapped} && !$c->{hidden} && $c->{size}[0] > 0 && $c->{size}[1] > 0) {
                        print "$c->{at}[0],$c->{at}[1] $c->{size}[0]x$c->{size}[1]\n";
                    }
                }
            ' 2>/dev/null
    fi
    return
  fi

  # Sway / wlroots
  if [ -n "$SWAYSOCK" ] && command -v swaymsg >/dev/null 2>&1; then
    if command -v jq >/dev/null 2>&1; then
      swaymsg -t get_tree 2>/dev/null | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
    fi
    return
  fi
}

WINDOWS=$(get_windows 2>/dev/null)

# Slurp overlay styling matching current desktop theme
SLURP_FLAGS=(-c "#${ACCENT}ff" -s "#${ACCENT}25" -b "#00000080" -B "#00000000" -d)

# If window candidates exist, feed them to slurp for auto-snapping on hover/click
if [ -n "$WINDOWS" ]; then
  GEOM=$(echo "$WINDOWS" | slurp "${SLURP_FLAGS[@]}")
else
  GEOM=$(slurp "${SLURP_FLAGS[@]}")
fi

# Exit if selection was canceled (e.g. Esc pressed)
[ -z "$GEOM" ] && exit 0

# Execute action: OCR text extraction or image save & copy
if [ "$1" = "ocr" ]; then
  grim -g "$GEOM" - | tesseract stdin stdout -l eng 2>/dev/null | wl-copy && notify-send 'OCR Complete' 'Text copied to clipboard.'
else
  mkdir -p "$HOME/Pictures"
  FILENAME="$HOME/Pictures/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
  grim -g "$GEOM" - | tee "$FILENAME" | wl-copy -t image/png
fi
