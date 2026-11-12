pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "../Utils.js" as Utils
import ".."

// Live session facts: the compositor we are running under, the logged-in user,
// and the resolved value of every option that an environment variable or the
// compositor can override. Nothing here is meant to be edited; set defaults in
// Config.qml and transient state in UiState.qml.
Singleton {
  id: root

  // $QS_BAR wins, then the session's desktop name, then MangoWC.
  readonly property string wm: {
    var envWm = Utils.envChoice(Quickshell.env("QS_BAR"), ["mangowc", "hyprland", "niri"], "")
    if (envWm !== "") return envWm

    var xdg = (Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase()
    if (xdg.indexOf("hyprland") !== -1) return "hyprland"
    if (xdg.indexOf("niri") !== -1) return "niri"
    if (xdg.indexOf("mango") !== -1) return "mangowc"
    return "mangowc"
  }

  // Theme fonts, falling back to the literals in Config.
  readonly property string monoFont: Colours.monoFont || Config.monoFont
  readonly property string sansFont: Colours.sansFont || Config.sansFont
  readonly property string serifFont: Colours.serifFont || Config.serifFont

  readonly property string user: Quickshell.env("USER") || "user"
  readonly property string home: Quickshell.env("HOME") || ("/home/" + root.user)
  readonly property string hostname: Quickshell.env("HOSTNAME") || Quickshell.env("HOST") || "NixOS"

  // Bar geometry, derived from the compositor and the bar options so Config
  // stays a flat list of values.
  readonly property string barType: root.wm === "niri" ? "niri" : "bar"
  readonly property bool hasTopBar: UiState.barVisible && root.barType !== "niri"
  readonly property bool hasLeftBar: UiState.barVisible && root.barType === "niri" && root.barSide !== "right"
  readonly property bool hasRightBar: UiState.barVisible && root.barType === "niri" && root.barSide === "right"

  // The shape Utils.overlayMargins expects, so overlays do not each rebuild it.
  readonly property var barGeometry: ({
      hasTopBar: root.hasTopBar,
      hasLeftBar: root.hasLeftBar,
      hasRightBar: root.hasRightBar,
      barHeight: Config.barHeight,
      barWidth: Config.barWidth
    })

  // Options whose default lives in Config but which a session variable may
  // replace (handy for per-compositor or per-machine experiments).
  readonly property string barSide: Utils.envChoice(Quickshell.env("QS_BAR_SIDE"),
    ["left", "right"], Config.barSide)
  readonly property string commandCentreSide: Utils.envChoice(Quickshell.env("QS_COMMAND_CENTRE_SIDE"),
    ["left", "right"], Config.commandCentreSide)
  readonly property string lockStatusPosition: Utils.envChoice(Quickshell.env("QS_LOCK_STATUS_POS"),
    ["top-left", "top-right", "bottom-left", "bottom-right", "split", "corners"], Config.lockStatusPosition)

  // Paths that depend on where the shell or the user lives. An empty Config
  // value means "use this default".
  readonly property string lockAvatarPath: Config.lockAvatarPath !== ""
    ? Config.lockAvatarPath
    : (Quickshell.shellDir + "/assets/avatar.png")
  readonly property string lockWallpaperPath: Config.lockWallpaperPath !== ""
    ? Config.lockWallpaperPath
    : ("file://" + root.home + "/Pictures/wallpaper")
}
