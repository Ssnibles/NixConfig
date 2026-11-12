pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../Utils.js" as Utils
import ".."

// Tray context menu rendered inside the shared tooltip window. It reads the
// active tooltip from the window so the same component serves every tile.

Card {
  id: menuRoot

  property var sharedWindow: null

  width: parent ? parent.width : Config.trayMenuWidth
  height: menuCol.implicitHeight + Config.popupContentMargins * 2
  cardRadius: Config.popupRadius
  cardColour: Colours.bg

  // Shared action pill for tray menu top actions (focus, hide, toggle expand)
  component ActionPill: Pill {
    id: actRoot
    property string icon: ""
    property string label: ""
    property color activeIconColour: Colours.accent
    property color idleIconColour: Colours.fgMid
    property bool isBold: false
    property int textSize: Config.fontSizeSm
    pillHeight: 26
    radius: Config.itemRadiusSm
    baseColour: "transparent"
    hoverColour: Colours.bgSubtle
    hoverHighlight: true
    border.color: "transparent"
    clickable: true

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      spacing: 8

      Text {
        visible: actRoot.icon !== ""
        text: actRoot.icon
        color: actRoot.hovered ? actRoot.activeIconColour : actRoot.idleIconColour
        font.family: Config.monoFont
        font.pixelSize: Config.iconSizeSm
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        Layout.fillWidth: true
        text: actRoot.label
        color: actRoot.hovered ? Colours.fg : actRoot.idleIconColour
        font.family: Config.sansFont
        font.pixelSize: actRoot.textSize
        font.bold: actRoot.isBold
        elide: Text.ElideRight
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }

  // Shared menu entry pill used for both top-level and submenu DBusMenu items
  component MenuEntryPill: Pill {
    id: entryRoot
    property var entry: null
    property bool submenuExpanded: false

    readonly property bool isEnabled: !!(entryRoot.entry && entryRoot.entry.enabled)
    readonly property string label: entryRoot.entry ? Utils.cleanMenuText(entryRoot.entry.text) : ""
    readonly property bool hasSubmenu: !!(entryRoot.entry && entryRoot.entry.hasChildren)

    visible: entryRoot.entry !== null && !entryRoot.entry.isSeparator && entryRoot.label !== ""
    pillHeight: 26
    radius: Config.itemRadiusSm
    baseColour: "transparent"
    hoverColour: Colours.bgSubtle
    hoverHighlight: entryRoot.isEnabled
    border.color: (entryRoot.hovered && entryRoot.isEnabled) ? Colours.border : "transparent"
    clickable: entryRoot.isEnabled
    opacity: entryRoot.isEnabled ? 1.0 : 0.45

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      spacing: 8

      Text {
        visible: entryRoot.entry ? (entryRoot.entry.buttonType !== QsMenuButtonType.None) : false
        text: {
          if (!entryRoot.entry) return ""
          var checked = entryRoot.entry.checkState === Qt.Checked
          if (entryRoot.entry.buttonType === QsMenuButtonType.RadioButton) {
            return checked ? "󰪥" : "󰝦"
          }
          return checked ? "󰄲" : "󰄱"
        }
        color: entryRoot.entry && entryRoot.entry.checkState === Qt.Checked ? Colours.accent : Colours.fgDim
        font.family: Config.monoFont
        font.pixelSize: Config.iconSizeSm
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        Layout.fillWidth: true
        text: entryRoot.label
        color: entryRoot.hovered ? Colours.fg : Colours.fgMid
        font.family: Config.sansFont
        font.pixelSize: Config.fontSizeSm
        elide: Text.ElideRight
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        visible: entryRoot.hasSubmenu
        text: entryRoot.submenuExpanded ? "󰅃" : "󰅂"
        color: Colours.fgDim
        font.family: Config.monoFont
        font.pixelSize: 12
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }

  readonly property var activeTip: menuRoot.sharedWindow ? menuRoot.sharedWindow.shownTip : null
  readonly property var activeDelegate: menuRoot.activeTip ? menuRoot.activeTip.target : null
  readonly property var activeItem: menuRoot.activeDelegate ? menuRoot.activeDelegate.modelData : null
  readonly property string appTitle: menuRoot.activeDelegate ? menuRoot.activeDelegate.appTitle : "Application"
  readonly property string itemId: menuRoot.activeDelegate ? menuRoot.activeDelegate.itemId : ""
  readonly property bool isHiddenItem: menuRoot.activeDelegate ? menuRoot.activeDelegate.isHiddenItem : false

  // Lazily opened only while the context menu is actually visible
  QsMenuOpener {
    id: rootMenuOpener
    menu: (menuRoot.activeItem && menuRoot.activeItem.hasMenu) ? menuRoot.activeItem.menu : null
  }

  readonly property var menuEntries: (rootMenuOpener.children && rootMenuOpener.children.values)
    ? rootMenuOpener.children.values
    : []

  Column {
    id: menuCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Config.popupContentMargins
    spacing: 6

    // Header: Icon + App Name + optional description & SNI ID
    RowLayout {
      width: parent.width
      spacing: 8

      IconImage {
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        implicitSize: 18
        source: menuRoot.activeItem ? menuRoot.activeItem.icon : ""
        Layout.alignment: Qt.AlignVCenter
      }

      Column {
        Layout.fillWidth: true
        spacing: 1

        Text {
          width: parent.width
          text: menuRoot.appTitle
          color: Colours.fg
          font.family: Config.sansFont
          font.pixelSize: Config.fontSizeMd
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          visible: !!(menuRoot.activeItem && menuRoot.activeItem.tooltipDescription)
          width: parent.width
          text: menuRoot.activeItem ? menuRoot.activeItem.tooltipDescription : ""
          color: Colours.fgMid
          font.family: Config.sansFont
          font.pixelSize: Config.fontSizeXs
          elide: Text.ElideRight
        }

        Text {
          visible: Config.trayShowAppIdInMenu && menuRoot.itemId !== ""
          width: parent.width
          text: menuRoot.itemId
          color: Colours.fgDim
          font.family: Config.monoFont
          font.pixelSize: 10
          elide: Text.ElideRight
        }
      }
    }

    Divider {
      width: parent.width
    }

    // Primary Action: Focus / Bring Up Application
    ActionPill {
      id: focusAppPill
      width: parent.width
      pillHeight: 28
      baseColour: Colours.bgSubtle
      hoverColour: Colours.bgRaised
      border.color: focusAppPill.hovered ? Colours.accent : Colours.border
      icon: "󰀻"
      label: "Focus Application"
      isBold: true
      onClicked: if (menuRoot.activeDelegate) menuRoot.activeDelegate.focusApp()
    }

    // App-provided DBusMenu Items
    Divider {
      visible: menuRoot.menuEntries.length > 0
      width: parent.width
    }

    Repeater {
      model: menuRoot.menuEntries

      delegate: Column {
        id: entryCol
        required property var modelData
        width: menuCol.width
        spacing: 4

        property bool submenuOpen: false

        Divider {
          visible: entryCol.modelData ? entryCol.modelData.isSeparator : false
          width: parent.width
        }

        MenuEntryPill {
          width: parent.width
          entry: entryCol.modelData
          submenuExpanded: entryCol.submenuOpen
          onClicked: {
            if (!entryCol.modelData || !entryCol.modelData.enabled) return
            if (entryCol.modelData.hasChildren) {
              entryCol.submenuOpen = !entryCol.submenuOpen
            } else {
              entryCol.modelData.triggered()
              if (menuRoot.activeTip) menuRoot.activeTip.closeNow()
            }
          }
        }

        QsMenuOpener {
          id: subMenuOpener
          menu: (entryCol.submenuOpen && entryCol.modelData && entryCol.modelData.hasChildren) ? entryCol.modelData : null
        }

        Column {
          visible: entryCol.submenuOpen && subMenuOpener.children && subMenuOpener.children.values.length > 0
          width: parent.width
          leftPadding: 12
          spacing: 3

          Repeater {
            model: (subMenuOpener.children && subMenuOpener.children.values) ? subMenuOpener.children.values : []

            delegate: MenuEntryPill {
              id: subEntryPill
              required property var modelData
              width: entryCol.width - 12
              pillHeight: 24
              entry: subEntryPill.modelData
              onClicked: {
                if (subEntryPill.modelData && subEntryPill.modelData.enabled) {
                  subEntryPill.modelData.triggered()
                  if (menuRoot.activeTip) menuRoot.activeTip.closeNow()
                }
              }
            }
          }
        }
      }
    }

    Divider {
      visible: Config.trayAllowSessionHide
      width: parent.width
    }

    // Hide / Unhide in Tray Action
    ActionPill {
      visible: Config.trayAllowSessionHide
      width: parent.width
      icon: menuRoot.isHiddenItem ? "󰈈" : "󰈉"
      label: menuRoot.isHiddenItem ? "Unhide in Tray" : "Hide from Tray"
      idleIconColour: Colours.fgDim
      textSize: Config.fontSizeXs
      onClicked: {
        if (menuRoot.activeItem) TrayService.toggleTrayItemHidden(menuRoot.activeItem)
        if (menuRoot.activeTip) menuRoot.activeTip.closeNow()
      }
    }

    // Toggle showing the expand arrow for hidden tray items
    ActionPill {
      visible: Config.trayAllowSessionHide && (TrayService.trayHiddenCount > 0 || !Config.trayShowExpandButton)
      width: parent.width
      icon: Config.trayShowExpandButton ? "󰅁" : "󰅂"
      label: Config.trayShowExpandButton ? "Hide Expand Arrow" : "Show Expand Arrow"
      idleIconColour: Colours.fgDim
      textSize: Config.fontSizeXs
      onClicked: {
        Config.trayShowExpandButton = !Config.trayShowExpandButton
        if (menuRoot.activeTip) menuRoot.activeTip.closeNow()
      }
    }
  }
}
