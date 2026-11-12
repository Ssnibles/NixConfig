pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."

Scope {
  id: lockScope

  property bool active: false
  property bool authenticating: false
  property string errorMessage: ""
  property int shakeTrigger: 0
  property string pendingPassword: ""
  property string enteredPassword: ""
  // Guards against a tight start, fail, start loop if PAM keeps erroring without
  // user input. Reset on every user-initiated submit and on a successful unlock.
  property int _authRestarts: 0
  readonly property int _maxAuthRestarts: 5

  // Expose lock/unlock via IPC at Scope level so target exists when unlocked
  IpcHandler {
    target: "lockscreen"

    function lock(): void {
      if (!lockScope.active) {
        lockScope.active = true
      } else if (lockLoader.item && !lockLoader.item.locked) {
        // If active remained true while already unlocked, force a clean component reload
        lockScope.active = false
        Qt.callLater(function() {
          lockScope.active = true
        })
      }
    }

    function unlock(): void {
      lockScope.unlockSession()
    }

    function toggle(): void {
      if (lockScope.active && lockLoader.item && lockLoader.item.locked) {
        lockScope.unlockSession()
      } else {
        lockScope.active = false
        Qt.callLater(function() {
          lockScope.active = true
        })
      }
    }
  }

  function unlockSession(): void {
    if (lockLoader.item && lockLoader.item.locked) {
      lockLoader.item.locked = false
    }
    // Defer unloading the Loader by one event tick so WlSessionLock can cleanly
    // flush the unlock_and_destroy protocol request before its surfaces and QML item are destroyed.
    Qt.callLater(function() {
      lockScope.active = false
    })
  }

  // Single PAM Service Context for the lock session across all screens
  PamContext {
    id: pam
    config: "login"
    user: Session.user

    onResponseRequiredChanged: {
      if (responseRequired && lockScope.pendingPassword.length > 0) {
        respond(lockScope.pendingPassword)
        lockScope.pendingPassword = ""
      }
    }

    onCompleted: function(result) {
      lockScope.authenticating = false
      lockScope.pendingPassword = ""
      lockScope.enteredPassword = ""
      if (result === PamResult.Success) {
        lockScope._authRestarts = 0
        lockScope.errorMessage = ""
        lockScope.unlockSession()
      } else if (lockScope._authRestarts < lockScope._maxAuthRestarts) {
        lockScope._authRestarts++
        lockScope.errorMessage = "Authentication failed. Try again."
        lockScope.shakeTrigger++
        pam.start()
      } else {
        lockScope.errorMessage = "Authentication unavailable. Try again later."
        lockScope.shakeTrigger++
      }
    }

    onError: function(err) {
      lockScope.authenticating = false
      lockScope.pendingPassword = ""
      lockScope.enteredPassword = ""
      lockScope.shakeTrigger++
      if (lockScope._authRestarts < lockScope._maxAuthRestarts) {
        lockScope._authRestarts++
        lockScope.errorMessage = "PAM error. Retrying..."
        pam.start()
      } else {
        lockScope.errorMessage = "Authentication unavailable. Try again later."
      }
    }
  }

  function submitPassword(password) {
    if (!password || lockScope.authenticating) return
    lockScope._authRestarts = 0
    lockScope.authenticating = true
    lockScope.errorMessage = ""

    if (pam.responseRequired) {
      pam.respond(password)
    } else {
      lockScope.pendingPassword = password
      if (!pam.active) {
        pam.start()
      }
    }
  }

  Loader {
    id: lockLoader
    active: lockScope.active
    sourceComponent: lockComponent
    onActiveChanged: {
      MediaService.lockActive = lockLoader.active
      if (lockLoader.active) {
        lockScope._authRestarts = 0
        lockScope.errorMessage = ""
        lockScope.authenticating = false
        lockScope.pendingPassword = ""
        lockScope.enteredPassword = ""
        pam.start()
      } else {
        if (pam.active) {
          pam.abort()
        }
        Qt.callLater(gc)
      }
    }
  }

  Component {
    id: lockComponent

    WlSessionLock {
      locked: true
      onLockStateChanged: {
        if (!locked) {
          lockScope.active = false
        }
      }

      WlSessionLockSurface {
        id: surface
        color: Colours.bg

        property real shakeOffset: 0

        // Check if this screen is the main interactive screen (first screen in list)
        property bool isPrimaryScreen: surface.screen === undefined || surface.screen === Quickshell.screens[0]

        readonly property string currentTimeStr: ClockService.lockTimeStr
        readonly property string currentDateStr: ClockService.lockDateStr

        Component.onCompleted: {
          if (surface.isPrimaryScreen) {
            mainBg.forceActiveFocus()
          }
        }

        Connections {
          target: lockScope
          function onShakeTriggerChanged() {
            if (surface.isPrimaryScreen) {
              shakeAnimation.start()
              mainBg.forceActiveFocus()
            }
          }
        }

        // Shake animation for error feedback
        SequentialAnimation {
          id: shakeAnimation
          NumberAnimation { target: surface; property: "shakeOffset"; to: -12; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: 12; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: -8; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: 8; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: -4; duration: 50; easing.type: Easing.OutQuad }
          NumberAnimation { target: surface; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.OutQuad }
        }

        // Main background layer
        Rectangle {
          id: mainBg
          anchors.fill: parent
          color: Colours.bg
          focus: true

          Keys.onPressed: function(event) {
            authCard.updateCapsLock(event.modifiers)

            // Clear previous error message immediately on fresh typing
            if (lockScope.errorMessage !== "") {
              lockScope.errorMessage = ""
            }

            // Don't queue keystrokes in the disabled field while PAM is busy.
            if (lockScope.authenticating) return

            if (event.key === Qt.Key_Escape) {
              authCard.cancelInput()
              mainBg.forceActiveFocus()
              event.accepted = true
              return
            }

            // Ignore standalone modifier keys, tabs, and Delete
            if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control ||
                event.key === Qt.Key_Alt || event.key === Qt.Key_Meta ||
                event.key === Qt.Key_CapsLock || event.key === Qt.Key_Tab ||
                event.key === Qt.Key_Backtab || event.key === Qt.Key_Delete) {
              return
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              authCard.submitEnteredPassword()
              event.accepted = true
              return
            }

            if (event.key === Qt.Key_Backspace) {
              if (lockScope.enteredPassword.length > 0) {
                lockScope.enteredPassword = lockScope.enteredPassword.slice(0, -1)
              }
              event.accepted = true
              return
            }

            // Ignore modifier shortcuts (Ctrl, Alt combos)
            if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) {
              return
            }

            if (event.text && event.text.length > 0) {
              var code = event.text.charCodeAt(0)
              if (code >= 32 && code !== 127) {
                lockScope.enteredPassword += event.text
                event.accepted = true
              }
            }
          }

          // Wallpaper background layer (configurable via Session.lockWallpaperPath)
          Image {
            anchors.fill: parent
            source: Session.lockWallpaperPath
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(parent.width > 0 ? parent.width : 1920, parent.height > 0 ? parent.height : 1080)
            smooth: true

            layer.enabled: Config.lockBlurPercentage > 0
            layer.effect: MultiEffect {
              blurEnabled: Config.lockBlurPercentage > 0
              blur: Config.lockBlurPercentage
              blurMax: 64
            }

            // Translucent dark overlay to elevate UI contrast (configurable via Config.lockBackgroundDimming)
            Rectangle {
              anchors.fill: parent
              color: "black"
              opacity: Config.lockBackgroundDimming
            }
          }

          // Global click handler to clear text field focus when clicking outside
          MouseArea {
            anchors.fill: parent
            onClicked: mainBg.forceActiveFocus()
          }

          LockStatusCluster {
            anchors.fill: parent
          }

          // Primary Interactive Screen Content
          ColumnLayout {
            visible: surface.isPrimaryScreen

            anchors.centerIn: parent
            width: Math.min(parent.width - Config.space2xl, Config.lockCardWidth)
            spacing: Config.spaceXl

            // Clock and date
            Column {
              Layout.alignment: Qt.AlignHCenter
              spacing: Config.spaceXs

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: surface.currentTimeStr
                color: Colours.fg
                font.family: Session.serifFont
                font.pixelSize: 72
                font.italic: true
                font.letterSpacing: 2
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: surface.currentDateStr
                color: Colours.fgDim
                font.family: Session.sansFont
                font.pixelSize: 16
              }
            }

            LockAuthCard {
              id: authCard
              session: lockScope
              Layout.fillWidth: true
              shakeOffset: surface.shakeOffset
              onBackgroundFocusRequested: mainBg.forceActiveFocus()
            }

            // Power actions
            PowerButtons {
              Layout.fillWidth: true
              showLock: false
              buttonRadius: Config.lockInputRadius
            }
          }

          LockSecondaryScreen {
            session: lockScope
            visible: !surface.isPrimaryScreen
          }
        }
      }
    }
  }
}
