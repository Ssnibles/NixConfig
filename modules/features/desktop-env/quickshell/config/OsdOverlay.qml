pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "Utils.js" as Utils

// Floating On-Screen Display (OSD) pill for volume, microphone mute, and
// screen brightness changes, driven by SystemService and configurable via Config.
Scope {
  id: root

  property bool closing: false
  readonly property bool active: Config.osdEnabled && (SystemService.osdVisible || root.closing)
  property var _screen: null

  Connections {
    target: SystemService
    function onOsdVisibleChanged() {
      if (SystemService.osdVisible) {
        closeTimer.stop()
        root.closing = false
        if (!root._screen) {
          root._screen = Utils.resolveActiveScreen(Config.targetScreen, Config.lastActiveScreen, Quickshell.screens)
        }
      } else if (root.active) {
        root.closing = true
        closeTimer.restart()
      }
    }
  }

  Timer {
    id: closeTimer
    interval: Config.animNormalMs
    repeat: false
    onTriggered: {
      root.closing = false
      root._screen = null
    }
  }

  readonly property var targetScreens: Utils.resolveOverlayScreens(
    Config.osdAllScreens,
    root.active,
    root._screen,
    Config.lastActiveScreen,
    Quickshell.screens
  )

  Variants {
    model: root.targetScreens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore
      aboveWindows: true
      focusable: false

      readonly property var pos: Utils.parseOverlayPosition(Config.osdPosition, "bottom")

      anchors {
        top: panel.pos.onTop
        bottom: panel.pos.onBottom
        left: panel.pos.onLeft
        right: panel.pos.onRight
      }

      margins {
        top: panel.pos.onTop ? (Config.hasTopBar ? (Config.barHeight + Config.osdMarginY) : Config.osdMarginY) : 0
        bottom: panel.pos.onBottom ? Config.osdMarginY : 0
        left: panel.pos.onLeft ? (Config.hasLeftBar ? (Config.barWidth + Config.osdMarginX) : Config.osdMarginX) : 0
        right: panel.pos.onRight ? (Config.hasRightBar ? (Config.barWidth + Config.osdMarginX) : Config.osdMarginX) : 0
      }

      implicitWidth: Config.osdWidth + 16
      implicitHeight: Config.osdHeight + 16
      color: "transparent"
      visible: root.active

      mask: Region { item: osdCard }

      property bool shown: false
      Component.onCompleted: shown = true

      readonly property real targetOpacity: (panel.shown && !root.closing) ? 1.0 : 0.0
      readonly property real slideDir: panel.pos.onTop ? -10 : 10
      readonly property real targetSlide: (panel.shown && !root.closing) ? 0 : panel.slideDir

      readonly property color activeAccent: {
        if (SystemService.osdMuted) return Colours.red
        if (SystemService.osdKind === "brightness") return Colours.yellow
        return Colours.accent
      }

      Card {
        id: osdCard
        width: Config.osdWidth
        height: Config.osdHeight
        anchors.centerIn: parent
        cardRadius: Config.osdRadius >= 0 ? Config.osdRadius : (Config.osdHeight / 2)
        cardColour: Colours.bg
        borderColour: SystemService.osdMuted ? Colours.red : Colours.border
        opacity: panel.targetOpacity
        Behavior on opacity { NumberAnimation { duration: Config.animNormalMs; easing.type: Easing.OutCubic } }

        transform: Translate {
          y: panel.targetSlide
          Behavior on y { NumberAnimation { duration: Config.animSmoothMs; easing.type: Easing.OutCubic } }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          spacing: 12

          Text {
            text: SystemService.osdIcon
            color: panel.activeAccent
            font.family: Config.monoFont
            font.pixelSize: Config.iconSizeLg
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: Config.animFastMs } }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            Layout.alignment: Qt.AlignVCenter
            radius: 4
            color: Colours.bgSubtle
            border.width: 1
            border.color: Colours.border

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Math.round(parent.width * Math.max(0, Math.min(1.0, SystemService.osdValue)))
              radius: 4
              color: panel.activeAccent
              Behavior on width { NumberAnimation { duration: Config.animNormalMs; easing.type: Easing.OutCubic } }
              Behavior on color { ColorAnimation { duration: Config.animFastMs } }
            }
          }

          Text {
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
            text: SystemService.osdLabel
            color: SystemService.osdMuted ? Colours.red : Colours.fg
            font.family: Config.monoFont
            font.pixelSize: Config.fontSizeMd
            font.bold: true
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
          }
        }
      }
    }
  }
}
