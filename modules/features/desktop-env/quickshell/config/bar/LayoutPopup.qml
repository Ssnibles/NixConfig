pragma ComponentBehavior: Bound
import QtQuick
import ".."

// Tiling layout selector shown in the bar layout widget popup.
Card {
  id: root

  property string currentSymbol: ""

  // Normalised through the compositor backend so "[1]", "[M]", and "monocle"
  // all resolve to the same entry.
  readonly property string currentName: WmService.getLayoutInfo(root.currentSymbol).symbol

  width: 210
  height: contentCol.implicitHeight + Config.popupContentMargins * 2
  cardRadius: Config.popupRadius
  cardColour: Colours.bg

  Column {
    id: contentCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Config.popupContentMargins
    spacing: 8

    Row {
      spacing: 8

      Text {
        text: "󰕰"
        color: Colours.accent
        font.family: Config.monoFont
        font.pixelSize: Config.fontSizeLg
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        Text {
          text: "Layout Selection"
          color: Colours.fg
          font.family: Config.sansFont
          font.pixelSize: Config.fontSizeMd
          font.weight: Font.Bold
        }
        Text {
          text: "MangoWC Window Tiling Mode"
          color: Colours.fgDim
          font.family: Config.sansFont
          font.pixelSize: 10
        }
      }
    }

    Divider {
      width: parent.width
    }

    Repeater {
      model: WmService.availableLayouts

      delegate: Rectangle {
        id: layoutOption
        required property var modelData
        readonly property bool isCurrent: layoutOption.modelData.symbol === root.currentName

        width: contentCol.width
        height: 28
        radius: Config.itemRadiusSm
        color: layoutOption.isCurrent
          ? Colours.accent
          : (rowMouse.containsMouse ? Colours.bgRaised : "transparent")

        Behavior on color { ColorAnimation { duration: Config.animFastMs } }

        Item {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
              text: layoutOption.modelData.icon
              color: layoutOption.isCurrent ? Colours.bg : Colours.accent
              font.family: Config.monoFont
              font.pixelSize: Config.iconSizeSm
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: layoutOption.modelData.name
              color: layoutOption.isCurrent ? Colours.bg : Colours.fg
              font.family: Config.sansFont
              font.pixelSize: Config.fontSizeSm
              font.weight: layoutOption.isCurrent ? Font.Bold : Font.Normal
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Text {
            text: layoutOption.modelData.key ? ("Super+" + layoutOption.modelData.key) : ""
            visible: layoutOption.modelData.key !== ""
            color: layoutOption.isCurrent ? Colours.bgSubtle : Colours.fgDim
            font.family: Config.monoFont
            font.pixelSize: 10
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: rowMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: WmService.setLayout(layoutOption.modelData.symbol)
        }
      }
    }
  }
}
