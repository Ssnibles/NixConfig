pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Pill {
  id: root

  property var screen: null
  property PanelWindow sharedWindow: null

  // Visible when window manager provides layouts (mangowc)
  readonly property bool active: WmService.wm === "mangowc"
  visible: active

  readonly property string currentLayoutSymbol: {
    // Depend on the raw tag list so per-output layout changes re-evaluate.
    var _tags = WmService.allTags
    var screenName = root.screen ? root.screen.name : ""
    return WmService.getLayoutSymbol(screenName)
  }

  readonly property var layoutInfo: WmService.getLayoutInfo(root.currentLayoutSymbol)

  pillColour: Colours.bgSubtle
  border.color: Colours.accent
  clickable: true
  onClicked: WmService.nextLayout()

  Row {
    id: layoutRow
    spacing: 6
    anchors.centerIn: parent

    Text {
      text: root.layoutInfo.icon
      color: Colours.accent
      font.family: Config.monoFont
      font.pixelSize: Config.iconSizeSm
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.layoutInfo.name
      color: Colours.fg
      font.family: Config.sansFont
      font.pixelSize: Config.fontSizeSm
      font.weight: Font.Medium
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Tooltip {
    id: tooltip
    target: root
    sharedWindow: root.sharedWindow
    contentWidth: 210

    contentComponent: Component {
      Card {
        id: card
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

          // Header
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

          Rectangle {
            width: parent.width
            height: 1
            color: Colours.border
          }

          // Options List
          Repeater {
            model: WmService.availableLayouts
            delegate: Rectangle {
              id: layoutOption
              required property var modelData
              readonly property bool isCurrent: {
                var cur = root.currentLayoutSymbol
                if (!cur) return false
                if (cur === modelData.symbol) return true
                if (modelData.layoutName && cur.toLowerCase() === modelData.layoutName.toLowerCase()) return true
                if (modelData.name && cur.toLowerCase() === modelData.name.toLowerCase()) return true
                if ((modelData.symbol === "M" || modelData.symbol === "[M]") &&
                    (cur === "M" || cur === "[M]" || /^\[\d+\]$/.test(cur) || cur.toLowerCase() === "monocle")) return true
                return false
              }

              width: contentCol.width
              height: 28
              radius: Config.itemRadiusSm
              color: isCurrent ? Colours.accent : (rowMouse.containsMouse ? Colours.bgRaised : "transparent")

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
    }
  }
}
