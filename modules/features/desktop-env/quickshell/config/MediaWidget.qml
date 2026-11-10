pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "Utils.js" as Utils

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Config.monoFont

  // Centralised MPRIS State from MediaService
  readonly property bool isPlaying: MediaService.isPlaying
  readonly property string mediaText: MediaService.mediaText
  readonly property bool hasMedia: MediaService.hasMedia

  visible: root.hasMedia
  hoverHighlight: true
  clickable: true
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  padding: root.horizontal ? Config.pillPaddingHorizontal : 4

  onClicked: function(mouse) {
    if (!MediaService.hasPlayer) return
    if (mouse.button === Qt.RightButton) {
      MediaService.focusSource()
    } else {
      MediaService.playPause()
    }
  }

  onWheel: function(wheel) {
    if (!MediaService.hasPlayer) return
    if (wheel.angleDelta.y > 0) {
      MediaService.next()
    } else if (wheel.angleDelta.y < 0) {
      MediaService.previous()
    }
    wheel.accepted = true
  }

  Tooltip {
    id: mediaTooltip
    target: root
    sharedWindow: root.sharedWindow
    contentWidth: Config.mediaPopupWidth
    contentComponent: mediaPopoverComponent
    onHoveredChanged: MediaService.setConsumer("barMedia-" + String(root), mediaTooltip.hovered)
  }
  Component.onDestruction: MediaService.setConsumer("barMedia-" + String(root), false)

  Component {
    id: mediaPopoverComponent

    MediaCard {
      id: popoverCard
      width: parent ? parent.width : Config.mediaPopupWidth
      cardColour: Colours.bg
      cardRadius: Config.popupRadius
    }
  }

  // Compact spinning disc shared by the sidebar and top-bar layouts.
  component SpinningIcon: Item {
    id: spinner
    property int iconSize: 16
    property int fontPx: 15
    property bool active: false

    width: spinner.iconSize
    height: spinner.iconSize

    Text {
      anchors.centerIn: parent
      text: root.isPlaying ? "󰎈" : "󰎆"
      color: root.isPlaying ? Colours.accent : Colours.fgDim
      font.pixelSize: spinner.fontPx
      font.bold: true
      font.family: root.uiFont
    }

    NumberAnimation on rotation {
      loops: Animation.Infinite
      from: 0
      to: 360
      duration: Config.mediaRotationDuration
      running: spinner.active && Config.animateMediaIcon && root.visible && root.isPlaying
    }
  }

  // UI Layout (Vertical for Sidebar)
  Column {
    id: mediaLayout
    visible: !root.horizontal
    spacing: 6
    anchors.centerIn: parent

    SpinningIcon {
      iconSize: 16
      fontPx: 15
      active: !root.horizontal
      anchors.horizontalCenter: parent.horizontalCenter
    }

    // Position indicator (elapsed / total stacked vertically)
    Column {
      id: positionCol
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 1

      Text {
        id: elapsedLabel
        anchors.horizontalCenter: parent.horizontalCenter
        text: !root.horizontal ? Utils.formatTime(Math.round(MediaService.estimatedPosition)) : ""
        color: Colours.fgMid
        font.family: root.uiFont
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        id: totalLabel
        visible: !root.horizontal && MediaService.hasPlayer && MediaService.lastLength > 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: !root.horizontal ? Utils.formatTime(Math.round(MediaService.lastLength)) : ""
        color: Colours.fgDim
        font.family: root.uiFont
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  // UI Layout (Horizontal for Topbar)
  Row {
    id: horizontalMediaRow
    visible: root.horizontal
    anchors.centerIn: parent
    spacing: 6

    SpinningIcon {
      iconSize: 14
      fontPx: 13
      active: root.horizontal
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.horizontal ? root.mediaText : ""
      color: Colours.fg
      font.family: Config.sansFont
      font.pixelSize: 12
      elide: Text.ElideRight
      maximumLineCount: 1
      width: Math.min(implicitWidth, 200)
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
