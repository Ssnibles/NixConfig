pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../Utils.js" as Utils
import ".."

Scope {
  id: ccScope

  property bool closing: false
  property bool active: UiState.commandCentreVisible || ccScope.closing

  // Distance from the screen edge to the near edge of the card: the side bar
  // (when there is one) plus the command centre margin.
  readonly property int cardMargin: {
    var barSpace = (Session.commandCentreSide === "right" ? Session.hasRightBar : Session.hasLeftBar) ? Config.barWidth : 0
    return barSpace + Config.commandCentreMargin
  }

  function openOnActiveScreen(): void {
    if (UiState.commandCentreVisible) return
    WmService.resolveTargetScreen(function() {
      UiState.commandCentreVisible = true
    })
  }

  IpcHandler {
    target: "command-centre"
    function toggle(): void {
      if (UiState.commandCentreVisible || WmService.queryingScreen) {
        WmService.cancelScreenQuery()
        UiState.commandCentreVisible = false
      } else {
        ccScope.openOnActiveScreen()
      }
    }

    function open(): void {
      if (!UiState.commandCentreVisible && !WmService.queryingScreen) {
        ccScope.openOnActiveScreen()
      }
    }

    function close(): void {
      WmService.cancelScreenQuery()
      UiState.commandCentreVisible = false
    }
  }

  Connections {
    target: UiState
    function onCommandCentreVisibleChanged() {
      if (UiState.commandCentreVisible) {
        ccScope.closing = false
        if (!UiState.targetScreen) {
          UiState.targetScreen = Utils.resolveActiveScreen(UiState.targetScreen, UiState.lastActiveScreen, Quickshell.screens)
        }
        BrightnessService.refreshBrightness(false)
      } else if (ccScope.active) {
        ccScope.closing = true
      }
    }
  }

  Variants {
    model: ccScope.active ? Quickshell.screens : []

    delegate: PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      // Full screen overlay for click-outside & escape dismiss
      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true

      color: "transparent"
      visible: true

      // Make sure it sits above windows and does not disrupt layout
      aboveWindows: true
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
      exclusionMode: ExclusionMode.Ignore

      // State for transition animation
      property bool isTargetScreen: {
        var target = Utils.resolveActiveScreen(UiState.targetScreen, UiState.lastActiveScreen, Quickshell.screens)
        if (!target) return false
        return panel.modelData === target || (panel.modelData && target && panel.modelData.name === target.name)
      }
      readonly property bool isLeft: Session.commandCentreSide === "left"
      readonly property real slideDistance: isLeft ? -Config.commandCentreSlideOffset : Config.commandCentreSlideOffset
      property real panelOpacity: 0
      property real panelSlide: slideDistance

      Component.onCompleted: {
        panelOpacity = 0
        panelSlide = slideDistance
        if (panel.isTargetScreen) {
          outsideDismiss.forceActiveFocus()
        }
        fadeInAnim.start()
      }

      Connections {
        target: ccScope
        function onClosingChanged() {
          if (ccScope.closing) {
            fadeInAnim.stop()
            fadeOutAnim.start()
          } else if (UiState.commandCentreVisible) {
            fadeOutAnim.stop()
            panel.panelSlide = panel.slideDistance
            fadeInAnim.start()
            if (panel.isTargetScreen) outsideDismiss.forceActiveFocus()
          }
        }
      }

      SequentialAnimation {
        id: fadeInAnim
        PauseAnimation { duration: 1 }
        ParallelAnimation {
          NumberAnimation { target: panel; property: "panelOpacity"; to: 1; duration: Config.commandCentreAnimDuration; easing.type: Easing.OutCubic }
          NumberAnimation { target: panel; property: "panelSlide"; to: 0; duration: Config.commandCentreAnimDuration; easing.type: Easing.OutCubic }
        }
      }

      SequentialAnimation {
        id: fadeOutAnim
        ParallelAnimation {
          NumberAnimation { target: panel; property: "panelOpacity"; to: 0; duration: Config.commandCentreCloseDuration; easing.type: Easing.OutCubic }
          NumberAnimation { target: panel; property: "panelSlide"; to: panel.slideDistance; duration: Config.commandCentreCloseDuration; easing.type: Easing.OutCubic }
        }
        onFinished: {
          if (ccScope.closing) {
            ccScope.closing = false
            UiState.targetScreen = null
            Qt.callLater(gc)
          }
        }
      }

      // Full-screen backdrop mouse area to catch clicks outside the card
      MouseArea {
        id: outsideDismiss
        anchors.fill: parent
        // Only the target screen needs hover tracking (to update the active
        // screen); every other overlay only needs to catch clicks.
        hoverEnabled: panel.isTargetScreen
        focus: panel.isTargetScreen
        onEntered: {
          UiState.lastActiveScreen = panel.modelData
        }
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            UiState.commandCentreVisible = false
            event.accepted = true
          }
        }
        onClicked: {
          UiState.commandCentreVisible = false
        }
      }

      // Main Card container (lazily loaded only on the target screen to avoid duplicating across displays)
      Loader {
        active: panel.isTargetScreen
        sourceComponent: mainCardComponent
        opacity: panel.panelOpacity
        transform: Translate { x: panel.panelSlide }
        width: Config.commandCentreWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: panel.isLeft ? parent.left : undefined
        anchors.right: panel.isLeft ? undefined : parent.right
        anchors.topMargin: Session.hasTopBar ? (Config.barHeight + Config.commandCentreMargin) : Config.commandCentreMargin
        anchors.bottomMargin: Config.commandCentreMargin
        anchors.leftMargin: panel.isLeft ? ccScope.cardMargin : 0
        anchors.rightMargin: panel.isLeft ? 0 : ccScope.cardMargin
      }

      Component {
        id: mainCardComponent

        CommandCentreCard { }
      }
    }
  }
}
