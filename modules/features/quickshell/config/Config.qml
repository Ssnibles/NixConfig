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
  readonly property string sansFont: Colors.sansFont !== undefined ? Colors.sansFont : "Inter"
  readonly property string serifFont: Colors.sansFont !== undefined ? Colors.serifFont : "Instrument Serif"

  // --- Command Center State ----------------------------------------------
  property bool commandCenterVisible: false

  // --- Media --------------------------------------------------------------
  // Whether the command center's media card always stays visible, showing
  // "Nothing is playing" when no media is active.
  readonly property bool alwaysShowMediaCard: true

  // --- Clock --------------------------------------------------------------
  readonly property string timeFormat: "hh:mm"

  // --- Niri vertical bar (niri-bar.qml) ----------------------------------
  readonly property int barWidth: 38
  readonly property string barSide: "left" // "left" | "right"
  readonly property int barMarginTop: 8
  readonly property int barMarginBottom: 8
  readonly property int barMarginLeft: 4
  readonly property int barMarginRight: 4
  readonly property int barSpacing: 8

  // --- MangoWC top bar (mangowc-bar.qml) --------------------------------
  readonly property int barHeight: 32

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
  readonly property int notifWidth: 300
  readonly property int notifRadius: 12
  readonly property int notifCardMargins: 12
  readonly property int notifSpacing: 8

  // --- Lock Screen --------------------------------------------------------
  readonly property string lockAvatarPath: Quickshell.shellDir + "/assets/avatar.png"
  readonly property string lockFallbackIcon: "󰀉"
  readonly property string lockWallpaperPath: "file://" + (Quickshell.env("HOME") || "/home/josh") + "/Pictures/wallpaper"
  readonly property string lockClockFormat: "hh:mm"
  readonly property string lockDateFormat: "dddd, MMMM d"
  readonly property int lockCardRadius: 12
  readonly property int lockInputRadius: 10
  readonly property real lockBackgroundDimming: 0.8
  readonly property real lockBlurPercentage: 0.5
}
