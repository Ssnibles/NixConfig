pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../Utils.js" as Utils
import ".."

Pill {
  id: root

  property PanelWindow sharedWindow: null
  property string uiFont: Session.monoFont

  readonly property int maxTextWidth: Config.mediaBarTextMaxWidth

  visible: MediaService.hasMedia && root.shown
  hoverHighlight: true
  clickable: true
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  padding: root.horizontal ? Config.pillPaddingHorizontal : Config.spaceXs

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
    target: root
    sharedWindow: root.sharedWindow
    contentWidth: Config.mediaPopupWidth
    contentComponent: mediaPopoverComponent
    onHoveredChanged: MediaService.setConsumer("barMedia-" + String(root), hovered)
  }
  Component.onDestruction: MediaService.setConsumer("barMedia-" + String(root), false)

  Component {
    id: mediaPopoverComponent

    MediaCard {
      width: parent ? parent.width : Config.mediaPopupWidth
      cardColour: Colours.bg
      cardRadius: Config.popupRadius
    }
  }

  // Compact spinning disc shared by the sidebar and top-bar layouts.
  component SpinningIcon: Item {
    id: spinner
    property int iconSize: Config.iconSizeMd
    property int fontPx: Config.fontSizeLg
    property bool active: false

    width: spinner.iconSize
    height: spinner.iconSize

    Text {
      anchors.centerIn: parent
      text: MediaService.isPlaying ? "󰎈" : "󰎆"
      color: MediaService.isPlaying ? Colours.accent : Colours.fgDim
      font.pixelSize: spinner.fontPx
      font.bold: true
      font.family: root.uiFont
    }

    NumberAnimation on rotation {
      loops: Animation.Infinite
      from: 0
      to: 360
      duration: Config.mediaRotationDuration
      running: spinner.active && Config.animateMediaIcon && root.visible && MediaService.isPlaying
    }
  }

  // Side bar: spinner above the stacked elapsed / total time.
  Column {
    visible: !root.horizontal
    spacing: Config.spaceSm
    anchors.centerIn: parent

    SpinningIcon {
      iconSize: Config.iconSizeMd
      fontPx: Config.fontSizeLg
      active: !root.horizontal
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.space2xs

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Utils.formatTime(Math.round(MediaService.estimatedPosition))
        color: Colours.fgMid
        font.family: root.uiFont
        font.pixelSize: Config.fontSizeXs
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        visible: MediaService.hasPlayer && MediaService.lastLength > 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: Utils.formatTime(Math.round(MediaService.lastLength))
        color: Colours.fgDim
        font.family: root.uiFont
        font.pixelSize: Config.fontSizeXs
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  // Top bar: spinner beside the track label.
  Row {
    visible: root.horizontal
    anchors.centerIn: parent
    spacing: Config.spaceSm

    SpinningIcon {
      iconSize: Config.iconSizeSm
      fontPx: Config.fontSizeMd
      active: root.horizontal
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: MediaService.mediaText
      color: Colours.fg
      font.family: Session.sansFont
      font.pixelSize: Config.fontSizeSm
      elide: Text.ElideRight
      maximumLineCount: 1
      width: Math.min(implicitWidth, root.maxTextWidth)
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
