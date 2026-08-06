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

  // --- Command Center State ----------------------------------------------
  property bool commandCenterVisible: false

  // --- Clock --------------------------------------------------------------
  readonly property string timeFormat: "hh:mm"

  // --- Niri vertical bar (niri-bar.qml) ----------------------------------
  readonly property int barWidth: 38
  readonly property string barSide: "left" // "left" | "right"
  readonly property int barMarginTop: 8
  readonly property int barMarginBottom: 8
  readonly property int barMarginLeft: 4
  readonly property int barMarginRight: 4
  readonly property int barSpacing: 12

  // --- MangoWC top bar (mangowc-bar.qml) --------------------------------
  readonly property int barHeight: 32

  // --- Popup / tooltip ---------------------------------------------------
  readonly property int popupGap: 46 // distance from the bar to a popup
  readonly property int popupMaxWidth: 280
  readonly property int popupRadius: 8
  readonly property int popupContentMargins: 12
  readonly property int popupContentSpacing: 6
  readonly property int popupShowDelay: 150 // ms before a tooltip appears
  readonly property int popupFadeMs: 120
  readonly property int popupGraceMs: 500 // instant swap window between tooltips

  // --- Notifications ------------------------------------------------------
  readonly property string notifPosition: "top-right"
  readonly property int notifTimeoutMs: 5000
  readonly property int notifMaxVisible: 3
  readonly property int notifWidth: 300
  readonly property int notifRadius: 12
  readonly property int notifCardMargins: 12
  readonly property int notifSpacing: 8
}