pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Pill {
  id: root

  property var wmService: null
  property var screen: null
  property PanelWindow sharedWindow: null
  property bool horizontal: true

  // Visible when window manager provides layouts (mangowc)
  readonly property bool active: wmService !== null && wmService.wm === "mangowc"
  visible: active

  readonly property string currentLayoutSymbol: {
    if (!wmService) return ""
    // Depend on the raw tag list so per-output layout changes re-evaluate.
    var _tags = wmService.allTags
    var screenName = root.screen ? root.screen.name : ""
    return wmService.getLayoutSymbol(screenName)
  }

  readonly property var layoutInfo: wmService ? wmService.getLayoutInfo(root.currentLayoutSymbol) : { symbol: "DW", name: "Dwindle", icon: "󱗼", key: "r" }

  pillHeight: root.horizontal ? 24 : 32
  padding: 8
  orientation: root.horizontal ? Qt.Horizontal : Qt.Vertical
  pillColour: Colours.bgSubtle
  border.color: Colours.accent

  Row {
    id: layoutRow
    spacing: 6
    anchors.centerIn: parent

    Text {
      text: root.layoutInfo.icon
      color: Colours.accent
      font.family: Config.monoFont
      font.pixelSize: 13
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.layoutInfo.name
      color: Colours.fg
      font.family: Config.sansFont
      font.pixelSize: 12
      font.weight: Font.Medium
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton && root.wmService) {
        root.wmService.nextLayout()
      }
    }
  }

  Tooltip {
    id: tooltip
    target: root
    sharedWindow: root.sharedWindow
    contentWidth: 200

    contentComponent: Component {
      Rectangle {
        id: card
        width: 210
        height: contentCol.implicitHeight + Config.popupContentMargins * 2
        radius: Config.popupRadius
        color: Colours.bg
        border.width: 1
        border.color: Colours.border
        antialiasing: true

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
              font.pixelSize: 15
              anchors.verticalCenter: parent.verticalCenter
            }
            Column {
              Text {
                text: "Layout Selection"
                color: Colours.fg
                font.family: Config.sansFont
                font.pixelSize: 13
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
            model: root.wmService ? root.wmService.availableLayouts : []
            delegate: Rectangle {
              id: layoutOption
              required property var modelData
              readonly property bool isCurrent: {
                if (!root.wmService) return false
                var cur = root.currentLayoutSymbol
                if (!cur) return false
                if (cur === modelData.symbol) return true
                if (modelData.layoutName && cur.toLowerCase() === modelData.layoutName.toLowerCase()) return true
                if (modelData.name && cur.toLowerCase() === modelData.name.toLowerCase()) return true
                if (modelData.symbol === "[M]" && (/^\[\d+\]$/.test(cur) || cur === "monocle")) return true
                return false
              }

              width: contentCol.width
              height: 28
              radius: 6
              color: isCurrent ? Colours.accent : (rowMouse.containsMouse ? Colours.bgRaised : "transparent")

              Behavior on color { ColorAnimation { duration: 100 } }

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
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: layoutOption.modelData.name
                    color: layoutOption.isCurrent ? Colours.bg : Colours.fg
                    font.family: Config.sansFont
                    font.pixelSize: 12
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
                onClicked: {
                  if (root.wmService) {
                    root.wmService.setLayout(layoutOption.modelData.symbol)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
