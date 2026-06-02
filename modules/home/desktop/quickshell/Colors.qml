// Singleton color palette used across all quickshell UI components.
// Falls back to these values when a panel is loaded standalone without a root context.
pragma Singleton
import QtQml
import QtQuick
QtObject {
  readonly property color bg: "#141415"
  readonly property color bgRaised: "#1c1c24"
  readonly property color bgSubtle: "#252530"
  readonly property color border: "#252530"
  readonly property color fg: "#cdcdcd"
  readonly property color fgMid: "#878787"
  readonly property color fgDim: "#606079"
  readonly property color accent: "#6e94b2"
  readonly property color teal: "#b4d4cf"
  readonly property color purple: "#bb9dbd"
  readonly property color green: "#7fa563"
  readonly property color yellow: "#f3be7c"
  readonly property color red: "#d8647e"
  readonly property color orange: "#e8b589"
  readonly property color magenta: "#c48282"
  readonly property color selection: "#252530"
}
