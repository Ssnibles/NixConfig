pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

// Transient UI state: what is open, which screen owns it, and the per-session
// tray tweaks. Everything here resets when the shell restarts, so it is not
// configuration. Persistent defaults live in Config.qml and services/Session.qml.
Singleton {
  // Panels and overlays
  property bool barVisible: true
  property bool commandCentreVisible: false
  property bool launcherVisible: false
  property var targetScreen: null
  property var lastActiveScreen: null

  // System tray, toggled at runtime through IPC and the tray menu
  property bool trayEnabled: true
  property bool trayShowExpandButton: true
  property bool trayExpanded: false
  // Session-only hide/unhide overrides, shared by every monitor's bar.
  property var runtimeHiddenTrayApps: []
  property var runtimeUnhiddenTrayApps: []
}
