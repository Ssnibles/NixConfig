pragma ComponentBehavior: Bound
import QtQuick

// Single notification card rendered by NotificationOverlay (live toasts) and
// CommandCentre (notification history). Consumes normalized items produced by
// NotificationService directly via `model`.
Card {
  id: root

  required property var model
  required property int index
  property bool isHistory: false

  readonly property int uid: model.uid !== undefined ? model.uid : -1
  readonly property bool isMedia: Boolean(model.isMedia)
  readonly property int urgency: model.urgency !== undefined ? model.urgency : 1
  readonly property string primaryIcon: model.primaryIcon || ""
  readonly property string fallbackIcon: model.fallbackIcon || ""
  readonly property string glyph: model.glyph || Config.notifDefaultFallbackGlyph || "󰂚"
  readonly property var actions: (Config.notifShowActions && model.hasActions)
    ? NotificationService.actionsFor(root.uid)
    : []

  property bool primaryFailed: false
  property bool fallbackFailed: false
  onPrimaryIconChanged: primaryFailed = false
  onFallbackIconChanged: fallbackFailed = false

  readonly property string iconSource: (!primaryFailed && primaryIcon !== "")
    ? primaryIcon
    : ((!fallbackFailed && fallbackIcon !== "") ? fallbackIcon : "")

  readonly property bool isHovered: hoverArea.containsMouse
  onIsHoveredChanged: {
    if (!root.isHistory) NotificationService.setHovered(root.uid, root.isHovered)
  }
  Component.onDestruction: {
    if (!root.isHistory && root.uid >= 0) NotificationService.setHovered(root.uid, false)
  }

  readonly property int targetIconSize: isMedia ? (Config.notifMediaIconSize || 48) : (Config.notifIconSize || 40)
  readonly property int targetIconRadius: Config.notifIconRadius || Config.itemRadiusMd

  width: parent ? parent.width : Config.notifWidth
  height: Math.max(contentCol.implicitHeight, targetIconSize) + Config.notifCardMargins * 2
  cardRadius: Config.notifRadius
  cardColour: hoverArea.containsMouse ? Colours.bgRaised : Colours.bg
  borderColour: hoverArea.containsMouse
    ? (isMedia ? Colours.teal : (urgency === 2 ? Colours.red : Colours.accent))
    : (urgency === 2 ? Colours.red : Colours.border)

  scale: hoverArea.containsMouse ? (hoverArea.pressed ? 0.98 : 1.01) : 1.0

  Behavior on scale { NumberAnimation { duration: Config.animFastMs } }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton || Config.notifLeftClickAction === "focus") {
        NotificationService.activate(root.uid, root.isHistory)
      } else {
        NotificationService.dismiss(root.uid, root.isHistory)
      }
    }
  }

  // Left-side Icon / Avatar Container
  Item {
    id: iconContainer
    anchors.left: parent.left
    anchors.leftMargin: Config.notifCardMargins
    anchors.top: parent.top
    anchors.topMargin: Config.notifCardMargins
    width: root.targetIconSize
    height: root.targetIconSize

    Rectangle {
      anchors.fill: parent
      radius: root.targetIconRadius
      color: Colours.bgSubtle
      border.color: Colours.border
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.isMedia ? Colours.fgDim : (root.urgency === 2 ? Colours.red : Colours.accent)
        font.pixelSize: (root.glyph.length === 1) ? 18 : 20
        font.bold: root.glyph.length === 1
        font.family: (root.glyph.length === 1) ? Config.sansFont : Config.monoFont
        visible: !iconImage.ready
      }

      RoundedImage {
        id: iconImage
        anchors.fill: parent
        sourceSize: Qt.size(root.targetIconSize * 2, root.targetIconSize * 2)
        radius: root.targetIconRadius
        source: root.iconSource
        onSourceError: {
          if (!root.primaryFailed && root.primaryIcon !== "") {
            root.primaryFailed = true
          } else {
            root.fallbackFailed = true
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.activate(root.uid, root.isHistory)
      }
    }
  }

  // Text & Actions Column
  Column {
    id: contentCol
    anchors.left: iconContainer.right
    anchors.leftMargin: 10
    anchors.right: parent.right
    anchors.rightMargin: Config.notifCardMargins
    anchors.top: parent.top
    anchors.topMargin: Config.notifCardMargins
    spacing: 3

    // Header Row: Title + Timestamp
    Row {
      width: parent.width
      spacing: 6

      Text {
        width: timeLabel.visible ? (parent.width - timeLabel.implicitWidth - 6) : parent.width
        text: root.model.title || ""
        color: root.isMedia ? Colours.teal : (root.urgency === 2 ? Colours.red : Colours.accent)
        font.bold: true
        font.pixelSize: root.isMedia ? 12 : 13
        font.family: Config.sansFont
        elide: Text.ElideRight
      }

      Text {
        id: timeLabel
        text: root.model.timeStr || ""
        color: Colours.fgDim
        font.pixelSize: 11
        font.family: Config.sansFont
        visible: text !== ""
      }
    }

    // Body / Track Title
    Text {
      width: parent.width
      text: root.model.body || ""
      color: Colours.fg
      font.pixelSize: 13
      font.family: Config.sansFont
      maximumLineCount: root.isMedia ? 1 : (Config.notifMaxLines || 5)
      elide: Text.ElideRight
      wrapMode: root.isMedia ? Text.NoWrap : Text.Wrap
      visible: text !== ""
    }

    // Subtext / Media Artist
    Text {
      width: parent.width
      text: root.model.subtext || ""
      color: Colours.fgMid
      font.pixelSize: 12
      font.family: Config.sansFont
      elide: Text.ElideRight
      visible: text !== ""
    }

    // Action Buttons Row
    Row {
      spacing: 6
      visible: root.actions.length > 0

      Repeater {
        model: root.actions
        delegate: Pill {
          id: actionBtn
          required property var modelData
          pillHeight: Config.pillHeightHorizontal
          radius: Config.itemRadiusSm
          padding: 8
          baseColour: Colours.bgSubtle
          hoverColour: Colours.bgRaised
          hoverHighlight: true
          border.color: actionBtn.hovered ? Colours.accent : Colours.border
          clickable: true
          onClicked: NotificationService.invokeAction(root.uid, actionBtn.modelData, root.isHistory)

          Text {
            id: actionText
            anchors.centerIn: parent
            text: actionBtn.modelData.text || actionBtn.modelData.identifier
            font.pixelSize: Config.fontSizeXs
            font.bold: true
            font.family: Config.sansFont
            color: actionBtn.hovered ? Colours.accent : Colours.fgMid
          }
        }
      }
    }
  }
}
