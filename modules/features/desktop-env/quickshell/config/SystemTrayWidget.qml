pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "Utils.js" as Utils

// System tray widget (StatusNotifierItem / SNI) supporting both horizontal
// top bars and vertical sidebars. Ingests centralised tray state from
// SystemService so multi-monitor bars share a single event-driven model.
Pill {
  id: root

  property PanelWindow sharedWindow: null

  visible: SystemService.trayHasContent
  padding: 5
  implicitWidth: root.horizontal ? (trayLayout.implicitWidth + root.padding * 2) : 34
  implicitHeight: root.horizontal ? Config.pillHeightHorizontal : (trayLayout.implicitHeight + 10)

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

  GridLayout {
    id: trayLayout
    anchors.centerIn: parent
    flow: root.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: Config.traySpacing
    columnSpacing: Config.traySpacing

    // Expand/collapse button for hidden tray icons (only shown when Config.trayShowExpandButton is true)
    Rectangle {
      visible: Config.trayShowExpandButton && SystemService.trayHiddenCount > 0
      Layout.preferredWidth: 18
      Layout.preferredHeight: Config.trayButtonSize
      width: 18
      height: Config.trayButtonSize
      radius: 4
      color: toggleMouse.containsMouse || Config.trayExpanded ? Colours.bgRaised : "transparent"
      Behavior on color { ColorAnimation { duration: Config.animFastMs } }

      Text {
        anchors.centerIn: parent
        text: root.horizontal
          ? (Config.trayExpanded ? "󰅂" : "󰅁")
          : (Config.trayExpanded ? "󰅃" : "󰅀")
        color: Config.trayExpanded ? Colours.accent : Colours.fgDim
        font.family: Config.monoFont
        font.pixelSize: 12
      }

      MouseArea {
        id: toggleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Config.trayExpanded = !Config.trayExpanded
      }
    }

    Repeater {
      model: SystemService.trayVisibleItems

      delegate: Rectangle {
        id: trayDelegate
        required property var modelData

        readonly property string itemId: SystemService.trayItemKey(trayDelegate.modelData)
        readonly property bool isHiddenItem: SystemService.isTrayItemHidden(trayDelegate.modelData)
        readonly property string appTitle: {
          if (!trayDelegate.modelData) return "Application"
          return trayDelegate.modelData.tooltipTitle
            || trayDelegate.modelData.title
            || Utils.prettifyAppName(trayDelegate.modelData.id)
            || "Application"
        }
        readonly property bool menuActive: root.sharedWindow !== null && root.sharedWindow.cachedActive === trayTip

        Layout.preferredWidth: Config.trayButtonSize
        Layout.preferredHeight: Config.trayButtonSize
        width: Config.trayButtonSize
        height: Config.trayButtonSize
        radius: 4
        opacity: trayDelegate.isHiddenItem ? 0.55 : 1.0
        color: (trayTip.hovered || trayDelegate.menuActive)
          ? Colours.bgRaised
          : "transparent"
        Behavior on color { ColorAnimation { duration: Config.animFastMs } }

        property var _focusTargets: []

        function focusApp() {
          if (!trayDelegate.modelData) return
          trayTip.closeNow()
          trayDelegate._focusTargets = Utils.goToSource(trayDelegate.modelData)
          if (trayDelegate._focusTargets && trayDelegate._focusTargets.length > 0) {
            WindowFocuser.focus(trayDelegate._focusTargets)
            focusFollowUpTimer.restart()
          }
        }

        Timer {
          id: focusFollowUpTimer
          interval: 180
          repeat: false
          onTriggered: {
            if (trayDelegate._focusTargets && trayDelegate._focusTargets.length > 0) {
              WindowFocuser.focus(trayDelegate._focusTargets)
            }
          }
        }

        Tooltip {
          id: trayTip
          target: trayDelegate
          sharedWindow: root.sharedWindow
          contentWidth: Config.trayMenuWidth
          contentComponent: trayMenuComponent
        }

        IconImage {
          anchors.centerIn: parent
          implicitSize: Config.trayIconSize
          source: trayDelegate.modelData ? trayDelegate.modelData.icon : ""
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

          onClicked: function(mouse) {
            if (!trayDelegate.modelData) return
            if (mouse.button === Qt.LeftButton) {
              if (Config.trayLeftClickAction === "menu") {
                trayTip.openNow()
              } else if (Config.trayLeftClickAction === "activate") {
                trayTip.closeNow()
                trayDelegate.modelData.activate()
              } else {
                trayDelegate.focusApp()
              }
            } else if (mouse.button === Qt.RightButton) {
              trayTip.openNow()
            } else if (mouse.button === Qt.MiddleButton) {
              trayDelegate.modelData.secondaryActivate()
            }
          }

          onWheel: function(wheel) {
            if (trayDelegate.modelData) {
              trayDelegate.modelData.scroll(wheel.angleDelta.y, false)
              wheel.accepted = true
            }
          }
        }
      }
    }
  }

  // Single shared context menu Component instantiated lazily inside SharedTooltipWindow
  Component {
    id: trayMenuComponent

    Card {
      id: menuCard
      width: parent ? parent.width : Config.trayMenuWidth
      height: menuCol.implicitHeight + Config.popupContentMargins * 2
      cardRadius: Config.popupRadius
      cardColour: Colours.bg

      readonly property var activeTip: root.sharedWindow ? root.sharedWindow.cachedActive : null
      readonly property var activeDelegate: menuCard.activeTip ? menuCard.activeTip.target : null
      readonly property var activeItem: menuCard.activeDelegate ? menuCard.activeDelegate.modelData : null
      readonly property string appTitle: menuCard.activeDelegate ? menuCard.activeDelegate.appTitle : "Application"
      readonly property string itemId: menuCard.activeDelegate ? menuCard.activeDelegate.itemId : ""
      readonly property bool isHiddenItem: menuCard.activeDelegate ? menuCard.activeDelegate.isHiddenItem : false

      // Lazily opened only while the context menu is actually visible
      QsMenuOpener {
        id: rootMenuOpener
        menu: (menuCard.activeItem && menuCard.activeItem.hasMenu) ? menuCard.activeItem.menu : null
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
            source: menuCard.activeItem ? menuCard.activeItem.icon : ""
            Layout.alignment: Qt.AlignVCenter
          }

          Column {
            Layout.fillWidth: true
            spacing: 1

            Text {
              width: parent.width
              text: menuCard.appTitle
              color: Colours.fg
              font.family: Config.sansFont
              font.pixelSize: Config.fontSizeMd
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              visible: !!(menuCard.activeItem && menuCard.activeItem.tooltipDescription)
              width: parent.width
              text: menuCard.activeItem ? menuCard.activeItem.tooltipDescription : ""
              color: Colours.fgMid
              font.family: Config.sansFont
              font.pixelSize: Config.fontSizeXs
              elide: Text.ElideRight
            }

            Text {
              visible: Config.trayShowAppIdInMenu && menuCard.itemId !== ""
              width: parent.width
              text: menuCard.itemId
              color: Colours.fgDim
              font.family: Config.monoFont
              font.pixelSize: 10
              elide: Text.ElideRight
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Colours.border
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
          onClicked: if (menuCard.activeDelegate) menuCard.activeDelegate.focusApp()
        }

        // App-provided DBusMenu Items
        Rectangle {
          visible: menuCard.menuEntries.length > 0
          width: parent.width
          height: 1
          color: Colours.border
        }

        Repeater {
          model: menuCard.menuEntries

          delegate: Column {
            id: entryCol
            required property var modelData
            width: menuCol.width
            spacing: 4

            property bool submenuOpen: false

            Rectangle {
              visible: entryCol.modelData ? entryCol.modelData.isSeparator : false
              width: parent.width
              height: 1
              color: Colours.border
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
                  if (menuCard.activeTip) menuCard.activeTip.closeNow()
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
                      if (menuCard.activeTip) menuCard.activeTip.closeNow()
                    }
                  }
                }
              }
            }
          }
        }

        Rectangle {
          visible: Config.trayAllowSessionHide
          width: parent.width
          height: 1
          color: Colours.border
        }

        // Hide / Unhide in Tray Action
        ActionPill {
          id: hideItemPill
          visible: Config.trayAllowSessionHide
          width: parent.width
          icon: menuCard.isHiddenItem ? "󰈈" : "󰈉"
          label: menuCard.isHiddenItem ? "Unhide in Tray" : "Hide from Tray"
          idleIconColour: Colours.fgDim
          textSize: Config.fontSizeXs
          onClicked: {
            if (menuCard.activeItem) SystemService.toggleTrayItemHidden(menuCard.activeItem)
            if (menuCard.activeTip) menuCard.activeTip.closeNow()
          }
        }

        // Toggle showing the expand arrow for hidden tray items
        ActionPill {
          id: toggleExpandBtnPill
          visible: Config.trayAllowSessionHide && (SystemService.trayHiddenCount > 0 || !Config.trayShowExpandButton)
          width: parent.width
          icon: Config.trayShowExpandButton ? "󰅁" : "󰅂"
          label: Config.trayShowExpandButton ? "Hide Expand Arrow" : "Show Expand Arrow"
          idleIconColour: Colours.fgDim
          textSize: Config.fontSizeXs
          onClicked: {
            Config.trayShowExpandButton = !Config.trayShowExpandButton
            if (menuCard.activeTip) menuCard.activeTip.closeNow()
          }
        }
      }
    }
  }
}
