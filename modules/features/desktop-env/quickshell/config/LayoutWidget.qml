import QtQuick
import Quickshell

Pill {
  id: root

  property var wmService: null
  property var screen: null
  property PanelWindow sharedWindow: null
  property bool horizontal: true

  // Visible when window manager provides layouts (mangowc, dwl)
  readonly property bool active: wmService !== null && (wmService.wm === "mangowc" || wmService.wm === "dwl")
  visible: active

  readonly property string currentLayoutSymbol: {
    if (!wmService) return ""
    var _ = wmService.currentLayoutSymbol
    var screenName = root.screen ? root.screen.name : ""
    return wmService.getLayoutSymbol(screenName)
  }

  readonly property var layoutInfo: wmService ? wmService.getLayoutInfo(root.currentLayoutSymbol) : { symbol: "DW", name: "Dwindle", icon: "󱗼", key: "r" }

  pillHeight: root.horizontal ? 24 : 32
  padding: 8
  orientation: root.horizontal ? Qt.Horizontal : Qt.Vertical
  pillColor: Colors.bgSubtle
  border.color: Colors.accent

  Row {
    id: layoutRow
    spacing: 6
    anchors.centerIn: parent

    Text {
      text: root.layoutInfo.icon
      color: Colors.accent
      font.family: Config.monoFont
      font.pixelSize: 13
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.layoutInfo.name
      color: Colors.fg
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
        color: Colors.bg
        border.width: 1
        border.color: Colors.border
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
              color: Colors.accent
              font.family: Config.monoFont
              font.pixelSize: 15
              anchors.verticalCenter: parent.verticalCenter
            }
            Column {
              Text {
                text: "Layout Selection"
                color: Colors.fg
                font.family: Config.sansFont
                font.pixelSize: 13
                font.weight: Font.Bold
              }
              Text {
                text: (root.wmService && root.wmService.wm === "dwl") ? "DWL Window Tiling Mode" : "MangoWC Window Tiling Mode"
                color: Colors.fgDim
                font.family: Config.sansFont
                font.pixelSize: 10
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 1
            color: Colors.border
          }

          // Options List
          Repeater {
            model: root.wmService ? root.wmService.availableLayouts : []
            delegate: Rectangle {
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
              color: isCurrent ? Colors.accent : (rowMouse.containsMouse ? Colors.bgRaised : "transparent")

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
                    text: modelData.icon
                    color: isCurrent ? Colors.bg : Colors.accent
                    font.family: Config.monoFont
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: modelData.name
                    color: isCurrent ? Colors.bg : Colors.fg
                    font.family: Config.sansFont
                    font.pixelSize: 12
                    font.weight: isCurrent ? Font.Bold : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Text {
                  text: modelData.key ? ("Super+" + modelData.key) : ""
                  visible: modelData.key !== ""
                  color: isCurrent ? Colors.bgSubtle : Colors.fgDim
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
                    root.wmService.setLayout(modelData.symbol)
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
