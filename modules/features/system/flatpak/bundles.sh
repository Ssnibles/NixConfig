# Install and update GitHub release Flatpak bundles.
# Arguments are groups of five: app id, owner, repo, asset template and
# checksums asset. An empty checksums asset skips verification.

STATE_DIR="${STATE_DIRECTORY:-/var/lib/flatpak-bundles}"
STATE_DIR="${STATE_DIR%%:*}"
NETWORK_WAIT_SECONDS="${FLATPAK_BUNDLES_NETWORK_WAIT:-120}"
FLATPAK_ROOT="/var/lib/flatpak"

log() {
  printf 'flatpak-bundles: %s\n' "$*"
}

error() {
  printf 'flatpak-bundles: %s\n' "$*" >&2
}

# NetworkManager-wait-online is disabled on these hosts, so wait for a real
# connection here instead of trusting network-online.target.
wait_for_network() {
  local deadline=$((SECONDS + NETWORK_WAIT_SECONDS))
  while ! curl --fail --silent --location --max-time 10 --output /dev/null https://github.com/; do
    if ((SECONDS >= deadline)); then
      return 1
    fi
    sleep 5
  done
}

# GitHub redirects releases/latest to the tag URL. The last path component is
# the tag, so no API token or JSON parsing is needed.
latest_tag() {
  local owner="$1"
  local repo="$2"
  local url
  url="$(curl --fail --silent --show-error --location \
    --retry 3 --retry-all-errors --connect-timeout 15 \
    --output /dev/null --write-out '%{url_effective}' \
    "https://github.com/$owner/$repo/releases/latest")" || return 1
  case "$url" in
    */releases/tag/*) printf '%s\n' "${url##*/}" ;;
    *) return 1 ;;
  esac
}

download() {
  local url="$1"
  local dest="$2"
  curl --fail --silent --show-error --location \
    --retry 3 --retry-all-errors --connect-timeout 15 \
    --output "$dest" "$url"
}

checksum_for() {
  local sums_file="$1"
  local asset="$2"
  awk -v name="$asset" '
    { file = $2; sub(/^\*/, "", file); if (file == name) { print $1; exit } }
  ' "$sums_file"
}

# Some bundles only ship a scalable SVG icon. Qt launchers such as Vicinae need
# a raster icon, so link the AppStream PNG fallback into the exported hicolor
# theme.
install_app_icons() {
  local app_id="$1"
  local app_dir="$FLATPAK_ROOT/app/$app_id/current/active/files/share/app-info/icons/flatpak"
  local theme_dir="$FLATPAK_ROOT/exports/share/icons/hicolor"
  local src size changed=0

  [ -d "$app_dir" ] || return 0
  for src in "$app_dir"/*/"$app_id.png"; do
    [ -f "$src" ] || continue
    size="$(basename "$(dirname "$src")")"
    [ -e "$theme_dir/$size/apps/$app_id.png" ] && continue
    mkdir -p "$theme_dir/$size/apps"
    ln -s "$src" "$theme_dir/$size/apps/$app_id.png"
    changed=1
  done

  if [ "$changed" = 1 ] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache --force --ignore-theme-index "$theme_dir" >/dev/null 2>&1 || true
  fi
}

install_bundle() (
  local app_id="$1"
  local owner="$2"
  local repo="$3"
  local asset_template="$4"
  local checksums_asset="$5"
  local state_file="$STATE_DIR/$app_id.tag"
  local tag asset version url sums_url tmp expected actual

  tag="$(latest_tag "$owner" "$repo")" || {
    error "cannot resolve the latest release of $owner/$repo"
    return 1
  }

  # Check the install as well as the tag: a manual uninstall leaves the tag
  # behind and would otherwise skip the bundle forever.
  if [ -f "$state_file" ] && [ "$(cat "$state_file")" = "$tag" ] &&
    flatpak info --system "$app_id" >/dev/null 2>&1; then
    install_app_icons "$app_id"
    log "$app_id $tag is already installed"
    return 0
  fi

  version="${tag#v}"
  asset="${asset_template//\{tag\}/$tag}"
  asset="${asset//\{version\}/$version}"
  checksums_asset="${checksums_asset//\{tag\}/$tag}"
  checksums_asset="${checksums_asset//\{version\}/$version}"
  url="https://github.com/$owner/$repo/releases/download/$tag/$asset"

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  if ! download "$url" "$tmp/$asset"; then
    error "failed to download $url"
    return 1
  fi

  if [ -n "$checksums_asset" ]; then
    sums_url="https://github.com/$owner/$repo/releases/download/$tag/$checksums_asset"
    if ! download "$sums_url" "$tmp/$checksums_asset"; then
      error "failed to download $sums_url"
      return 1
    fi

    expected="$(checksum_for "$tmp/$checksums_asset" "$asset")"
    if [ -z "$expected" ]; then
      error "$checksums_asset has no entry for $asset"
      return 1
    fi

    actual="$(sha256sum "$tmp/$asset" | awk '{ print $1 }')"
    if [ "$expected" != "$actual" ]; then
      error "checksum mismatch for $asset"
      error "  expected: $expected"
      error "  actual:   $actual"
      return 1
    fi
  fi

  if ! flatpak install --system --noninteractive --or-update -y --bundle "$tmp/$asset"; then
    error "failed to install $app_id $tag"
    return 1
  fi

  install_app_icons "$app_id"
  printf '%s\n' "$tag" > "$state_file"
  log "installed $app_id $tag"
)

main() {
  if (( $# == 0 )); then
    log "no bundles configured"
    return 0
  fi

  if (( $# % 5 != 0 )); then
    error "internal error: bundle arguments are not in groups of five"
    return 2
  fi

  # A boot without a network is not a failure. Leave the bundles for the daily
  # timer instead of marking the unit failed.
  if ! wait_for_network; then
    log "GitHub is unreachable after ${NETWORK_WAIT_SECONDS}s; the timer will retry"
    return 0
  fi

  mkdir -p "$STATE_DIR"

  local failed=0
  while (( $# > 0 )); do
    install_bundle "$1" "$2" "$3" "$4" "$5" || failed=1
    shift 5
  done
  return "$failed"
}
