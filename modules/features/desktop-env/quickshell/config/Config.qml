pragma Singleton
import Quickshell
import QtQuick

// Global layout knobs for the quickshell config. Everything here is consumed
// by the bars, the popup layer and the notification overlay. Per-widget
// details (sizes that only affect one widget) stay hard-coded in each
// widget's own file.
Singleton {
  // --- Fonts ------------------------------------------------------------
  readonly property string monoFont: Colors.monoFont !== undefined ? Colors.monoFont : "JetBrainsMono Nerd Font"
  readonly property string sansFont: "SF Pro Text"
  readonly property string serifFont: Colors.serifFont !== undefined ? Colors.serifFont : "Instrument Serif"

  // --- Command Center State & Geometry ----------------------------------
  property bool commandCenterVisible: false
  property var targetScreen: null
  property var lastActiveScreen: null
  readonly property int commandCenterWidth: 500
  readonly property int commandCenterRadius: 16
  readonly property int commandCenterCardRadius: 12
  readonly property string commandCenterClockFormat: "HH:mm"
  readonly property string commandCenterDateFormat: "dddd, MMMM d"

  // --- Window Manager Detection ------------------------------------------
  readonly property string wm: {
    var envWm = (Quickshell.env("QS_BAR") || "").toLowerCase()
    if (envWm !== "") return envWm

    var xdg = (Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase()
    if (xdg.indexOf("dwl") !== -1) return "dwl"
    if (xdg.indexOf("hyprland") !== -1) return "hyprland"
    if (xdg.indexOf("river") !== -1) return "river"
    if (xdg.indexOf("niri") !== -1) return "niri"
    if (xdg.indexOf("mango") !== -1) return "mangowc"

    return "mangowc"
  }

  // --- Screen Resolution Helpers ----------------------------------------
  function screenByName(name) {
    if (!name || !Quickshell.screens) return null
    for (var i = 0; i < Quickshell.screens.length; i++) {
      if (Quickshell.screens[i].name === name) {
        return Quickshell.screens[i]
      }
    }
    return null
  }

  function screenAt(x, y) {
    if (!Quickshell.screens) return null
    for (var i = 0; i < Quickshell.screens.length; i++) {
      var s = Quickshell.screens[i]
      if (x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) {
        return s
      }
    }
    return null
  }

  function resolveActiveScreen() {
    if (targetScreen) return targetScreen
    if (lastActiveScreen) return lastActiveScreen
    return (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null
  }

  // --- Media --------------------------------------------------------------
  // Whether the command center's media card always stays visible, showing
  // "Nothing is playing" when no media is active.
  readonly property bool alwaysShowMediaCard: true
  readonly property int mediaRotationDuration: 4000
  readonly property int mediaSeekDebounceMs: 200

  // --- Clock --------------------------------------------------------------
  readonly property string timeFormat: "HH:mm"

  // --- Niri vertical bar (niri-bar.qml) ----------------------------------
  readonly property int barWidth: 42
  readonly property string barSide: "left" // "left" | "right"
  readonly property int barMarginTop: 8
  readonly property int barMarginBottom: 8
  readonly property int barMarginLeft: 4
  readonly property int barMarginRight: 4
  readonly property int barSpacing: 8
  readonly property int volBarHeight: 64
  readonly property int wifiMaxTextLength: 90

  // --- Workspaces (WorkspacesWidget.qml) --------------------------------
  readonly property int workspaceDotSize: 12
  readonly property int workspaceDotSizeFocused: 34
  readonly property int workspaceDotSpacing: 6

  // --- MangoWC top bar (mangowc-bar.qml) --------------------------------
  readonly property int barHeight: 34
  readonly property int mangowcMinWorkspaces: 5
  readonly property string mangowcClockFormat: "HH:mm"

  // --- Popup / tooltip ---------------------------------------------------
  readonly property int popupGap: 46 // distance from the bar to a popup
  readonly property int popupMaxWidth: 280
  readonly property int popupRadius: 12
  readonly property int popupContentMargins: 12
  readonly property int popupContentSpacing: 6
  readonly property int popupShowDelay: 150 // ms before a tooltip appears
  readonly property int popupFadeMs: 120
  readonly property int popupGraceMs: 700 // generous window so cursor can cross the gap without flicker

  // --- Notifications ------------------------------------------------------
  readonly property string notifPosition: "top-left"
  readonly property int notifTimeoutMs: 5000
  readonly property int notifMaxVisible: 5
  readonly property int notifMaxHistory: 24
  readonly property int notifWidth: 300
  readonly property int notifRadius: 12
  readonly property int notifCardMargins: 12
  readonly property int notifSpacing: 8

  // --- Lock Screen --------------------------------------------------------
  readonly property string lockAvatarPath: Quickshell.shellDir + "/assets/avatar.png"
  readonly property string lockFallbackIcon: "󰀉"
  readonly property string lockWallpaperPath: "file://" + (Quickshell.env("HOME") || "/home/josh") + "/Pictures/wallpaper"
  readonly property string lockClockFormat: "HH:mm"
  readonly property string lockDateFormat: "dddd, MMMM d"
  readonly property int lockCardRadius: 12
  readonly property int lockInputRadius: 10
  readonly property real lockBackgroundDimming: 0.8
  readonly property real lockBlurPercentage: 0.5
}
