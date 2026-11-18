pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import ".."

// One frozen frame with the selection, the window highlight and the hint bar.
// Capture decisions stay in ScreenshotOverlay; this surface only draws and
// forwards pointer and key input.
PanelWindow {
  id: surface

  required property var overlay

  screen: surface.overlay.targetScreen

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  color: "black"
  aboveWindows: true
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore

  readonly property var sel: surface.overlay.effectiveSelection
  readonly property bool hasSelection: surface.sel !== null
    && surface.sel.width >= 1
    && surface.sel.height >= 1
  readonly property real selX: surface.hasSelection ? surface.sel.x : 0
  readonly property real selY: surface.hasSelection ? surface.sel.y : 0
  readonly property real selW: surface.hasSelection ? surface.sel.width : 0
  readonly property real selH: surface.hasSelection ? surface.sel.height : 0

  readonly property var hovered: surface.overlay.hoveredWindow
  readonly property bool showHover: surface.hovered !== null
    && surface.overlay.tool !== "output"
    && !surface.hasSelection

  readonly property color dimColour: Qt.rgba(0, 0, 0, Config.screenshotDimOpacity)
  readonly property string frozenUrl: "file://" + surface.overlay.frozenPath

  // Decoded once and uploaded once: the dimming is four rects around the
  // selection rather than a masked second copy of the frame.
  Image {
    anchors.fill: parent
    source: surface.frozenUrl
    fillMode: Image.Stretch
    asynchronous: false
    cache: false
  }

  Rectangle {
    x: 0
    y: 0
    width: surface.width
    height: surface.selY
    visible: surface.hasSelection
    color: surface.dimColour
  }

  Rectangle {
    x: 0
    y: surface.selY + surface.selH
    width: surface.width
    height: Math.max(0, surface.height - surface.selY - surface.selH)
    visible: surface.hasSelection
    color: surface.dimColour
  }

  Rectangle {
    x: 0
    y: surface.selY
    width: surface.selX
    height: surface.selH
    visible: surface.hasSelection
    color: surface.dimColour
  }

  Rectangle {
    x: surface.selX + surface.selW
    y: surface.selY
    width: Math.max(0, surface.width - surface.selX - surface.selW)
    height: surface.selH
    visible: surface.hasSelection
    color: surface.dimColour
  }

  Rectangle {
    anchors.fill: parent
    visible: !surface.hasSelection
    color: surface.dimColour
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.CrossCursor
    onPressed: function (mouse) {
      surface.overlay.pointerPressed(mouse.x, mouse.y)
    }
    onPositionChanged: function (mouse) {
      surface.overlay.pointerMoved(mouse.x, mouse.y)
    }
    onReleased: function (mouse) {
      surface.overlay.pointerReleased(mouse.x, mouse.y)
    }
  }

  Rectangle {
    x: surface.selX
    y: surface.selY
    width: surface.selW
    height: surface.selH
    visible: surface.hasSelection
    color: "transparent"
    border.width: Config.borderWidthFocus
    border.color: Colours.accent
  }

  Rectangle {
    x: surface.hovered ? surface.hovered.x : 0
    y: surface.hovered ? surface.hovered.y : 0
    width: surface.hovered ? surface.hovered.width : 0
    height: surface.hovered ? surface.hovered.height : 0
    visible: surface.showHover
    radius: Config.itemRadiusXs
    color: Qt.rgba(Colours.accent.r, Colours.accent.g, Colours.accent.b, 0.12)
    border.width: Config.borderWidthFocus
    border.color: Colours.accent
  }

  // Live size readout next to the cursor while dragging. A settled selection
  // shows its size in the hint bar instead.
  Rectangle {
    id: sizePill

    readonly property int gap: Config.spaceSm

    visible: surface.hasSelection && surface.overlay.dragging
    x: Math.max(Config.spaceMd, Math.min(surface.selX, surface.width - width - Config.spaceMd))
    y: surface.selY > height + Config.spaceMd * 2
      ? surface.selY - height - sizePill.gap
      : surface.selY + sizePill.gap
    width: sizeText.implicitWidth + Config.spaceMd * 2
    height: sizeText.implicitHeight + Config.spaceXs * 2
    radius: Config.itemRadiusXs
    color: Colours.bg
    border.width: Config.borderWidth
    border.color: Colours.border

    Text {
      id: sizeText
      anchors.centerIn: parent
      text: Math.round(surface.selW) + " x " + Math.round(surface.selH)
      color: Colours.fg
      font.family: Session.monoFont
      font.pixelSize: Config.fontSizeSm
    }
  }

  Rectangle {
    id: hintBar

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Config.space2xl
    width: hintRow.implicitWidth + Config.spaceLg * 2
    height: Config.pillHeightHorizontal + Config.spaceMd * 2
    radius: height / 2
    color: Colours.bgRaised
    border.width: Config.borderWidth
    border.color: Colours.border

    Row {
      id: hintRow
      anchors.centerIn: parent
      spacing: Config.spaceMd

      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.space2xs

        Repeater {
          model: [
            { key: "region", label: "Region" },
            { key: "window", label: "Window" },
            { key: "output", label: "Output" }
          ]

          delegate: Rectangle {
            id: toolButton

            required property var modelData

            readonly property bool current: surface.overlay.tool === toolButton.modelData.key

            width: toolText.implicitWidth + Config.spaceMd * 2
            height: Config.pillHeightHorizontal
            radius: height / 2
            color: toolButton.current
              ? Colours.accent
              : (toolHover.hovered ? Colours.bgSubtle : "transparent")

            Text {
              id: toolText
              anchors.centerIn: parent
              text: toolButton.modelData.label
              color: toolButton.current ? Colours.bg : Colours.fgMid
              font.family: Session.sansFont
              font.pixelSize: Config.fontSizeSm
            }

            HoverHandler {
              id: toolHover
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: surface.overlay.setTool(toolButton.modelData.key)
            }
          }
        }
      }

      Rectangle {
        width: Config.borderWidth
        height: Config.pillHeightHorizontal - Config.spaceSm * 2
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.border
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        // Live dimensions once something is selected, otherwise what the tool
        // is waiting for.
        text: surface.hasSelection
          ? Math.round(surface.selW) + " x " + Math.round(surface.selH)
          : (surface.overlay.tool === "window"
            ? "Click a window"
            : (surface.overlay.tool === "output" ? "Whole output" : "Drag, or click a window"))
        color: Colours.fg
        font.family: surface.hasSelection ? Session.monoFont : Session.sansFont
        font.pixelSize: Config.fontSizeSm
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: surface.overlay.captureMode === "text" ? "Text to clipboard" : "Image to clipboard"
        color: Colours.fgDim
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeSm
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Esc cancels"
        color: Colours.fgDim
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeSm
      }
    }
  }

  Item {
    anchors.fill: parent
    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) {
        surface.overlay.cancel()
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
        surface.overlay.confirm()
        event.accepted = true
      } else if (event.key === Qt.Key_R) {
        surface.overlay.setTool("region")
        event.accepted = true
      } else if (event.key === Qt.Key_W) {
        surface.overlay.setTool("window")
        event.accepted = true
      } else if (event.key === Qt.Key_O) {
        surface.overlay.setTool("output")
        event.accepted = true
      }
    }
  }
}
