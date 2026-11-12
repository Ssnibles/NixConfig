pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import ".."

Pill {
  id: root

  property var screen: null
  property PanelWindow sharedWindow: null

  // Visible when window manager provides layouts (mangowc)
  readonly property bool active: Config.wm === "mangowc"
  visible: active

  readonly property string currentLayoutSymbol: {
    // Depend on the raw tag list so per-output layout changes re-evaluate.
    var _tags = WmService.allTags
    return WmService.getLayoutSymbol(root.screen ? root.screen.name : "")
  }

  readonly property var layoutInfo: WmService.getLayoutInfo(root.currentLayoutSymbol)

  pillColour: Colours.bgSubtle
  border.color: Colours.accent
  clickable: true
  onClicked: WmService.nextLayout()

  Row {
    anchors.centerIn: parent
    spacing: 6

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
    target: root
    sharedWindow: root.sharedWindow
    contentWidth: 210
    contentComponent: Component {
      LayoutPopup { currentSymbol: root.currentLayoutSymbol }
    }
  }
}
