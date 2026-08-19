import QtQuick

Item {
  id: root

  property var workspaces: []
  signal focusRequested(int workspaceId)
  property bool horizontal: false

  property int dotSize: Config.workspaceDotSize
  property int dotSizeFocused: Config.workspaceDotSizeFocused
  property int dotSpacing: Config.workspaceDotSpacing

  property color dotColorFocused: Colors.accent
  property color dotColorActive: Colors.fgMid
  property color dotColorUrgent: Colors.red
  property color dotColorEmpty: Colors.fgDim

  readonly property int focusedIndex: {
    if (!workspaces || workspaces.length === 0) return 0
    for (var i = 0; i < workspaces.length; i++) {
      var w = workspaces[i]
      if (w && (w.is_focused || w.isFocused)) return i
    }
    return 0
  }

  property real pillStart: 0
  property real pillEnd: 0
  property bool initialAnimDone: false

  // Sequential 2-Phase Liquid Morph Animation (Stretch -> Contract & Bounce)
  SequentialAnimation {
    id: morphAnim

    property real startFrom: 0
    property real startTo: 0
    property real endFrom: 0
    property real endTo: 0
    property bool isForward: true

    // Phase 1: Stretch leading edge across workspaces into a liquid capsule
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: morphAnim.isForward ? "pillEnd" : "pillStart"
        from: morphAnim.isForward ? morphAnim.endFrom : morphAnim.startFrom
        to: morphAnim.isForward ? morphAnim.endTo : morphAnim.startTo
        duration: 150
        easing.type: Easing.OutQuad
      }
      NumberAnimation {
        target: root
        property: morphAnim.isForward ? "pillStart" : "pillEnd"
        from: morphAnim.isForward ? morphAnim.startFrom : morphAnim.endFrom
        to: morphAnim.isForward
          ? (morphAnim.startFrom + (morphAnim.startTo - morphAnim.startFrom) * 0.2)
          : (morphAnim.endFrom + (morphAnim.endTo - morphAnim.endFrom) * 0.2)
        duration: 150
        easing.type: Easing.OutQuad
      }
    }

    // Phase 2: Snap trailing edge forward with elastic bounce into target
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: morphAnim.isForward ? "pillStart" : "pillEnd"
        to: morphAnim.isForward ? morphAnim.startTo : morphAnim.endTo
        duration: 200
        easing.type: Easing.OutBack
        easing.overshoot: 1.25
      }
      NumberAnimation {
        target: root
        property: morphAnim.isForward ? "pillEnd" : "pillStart"
        to: morphAnim.isForward ? morphAnim.endTo : morphAnim.startTo
        duration: 200
        easing.type: Easing.OutCubic
      }
    }
  }

  function updatePillTarget() {
    var count = (workspaces && workspaces.length) ? workspaces.length : 0
    if (count === 0) return

    var k = root.focusedIndex
    var step = root.dotSize + root.dotSpacing
    var targetS = k * step
    var targetE = targetS + root.dotSizeFocused

    if (!initialAnimDone) {
      pillStart = targetS
      pillEnd = targetE
      initialAnimDone = true
      return
    }

    // Stop current morph if in-flight
    morphAnim.stop()

    morphAnim.startFrom = pillStart
    morphAnim.endFrom = pillEnd
    morphAnim.startTo = targetS
    morphAnim.endTo = targetE
    morphAnim.isForward = targetS >= pillStart

    morphAnim.restart()
  }

  onFocusedIndexChanged: updatePillTarget()
  onWorkspacesChanged: updatePillTarget()
  onHorizontalChanged: updatePillTarget()
  Component.onCompleted: updatePillTarget()

  implicitWidth: root.horizontal
    ? (root.workspaces && root.workspaces.length > 0 ? (root.dotSizeFocused + (root.workspaces.length - 1) * (root.dotSize + root.dotSpacing)) : root.dotSize)
    : root.dotSize

  implicitHeight: root.horizontal
    ? root.dotSize
    : (root.workspaces && root.workspaces.length > 0 ? (root.dotSizeFocused + (root.workspaces.length - 1) * (root.dotSize + root.dotSpacing)) : root.dotSize)

  width: implicitWidth
  height: implicitHeight

  anchors.centerIn: parent ? parent : undefined

  Item {
    id: container
    anchors.fill: parent

    // Sliding Morphing Focused Pill
    Rectangle {
      id: activePill
      color: root.dotColorFocused
      radius: Math.min(width, height) / 2
      antialiasing: true
      z: 2

      x: root.horizontal ? Math.min(root.pillStart, root.pillEnd) : 0
      y: root.horizontal ? 0 : Math.min(root.pillStart, root.pillEnd)
      width: root.horizontal ? Math.max(Math.abs(root.pillEnd - root.pillStart), root.dotSize) : root.dotSize
      height: root.horizontal ? root.dotSize : Math.max(Math.abs(root.pillEnd - root.pillStart), root.dotSize)
    }

    // Workspace Slots (Background Dots)
    Repeater {
      id: gridRepeater
      model: root.workspaces

      delegate: Item {
        id: dotItem
        required property var modelData
        required property int index

        readonly property bool isFocused: index === root.focusedIndex
        readonly property bool isActive: modelData ? (modelData.is_active || modelData.isActive || false) : false
        readonly property bool isUrgent: modelData ? (modelData.is_urgent || modelData.isUrgent || false) : false
        readonly property bool isOccupied: modelData ? (modelData.is_occupied || modelData.isOccupied || (modelData.client_count !== undefined && modelData.client_count > 0) || false) : false

        readonly property real targetPos: {
          var step = root.dotSize + root.dotSpacing
          var extra = root.dotSizeFocused - root.dotSize
          if (index < root.focusedIndex) {
            return index * step
          } else if (index === root.focusedIndex) {
            return index * step
          } else {
            return index * step + extra
          }
        }

        readonly property real targetSize: isFocused ? root.dotSizeFocused : root.dotSize

        x: root.horizontal ? targetPos : 0
        y: root.horizontal ? 0 : targetPos
        width: root.horizontal ? targetSize : root.dotSize
        height: root.horizontal ? root.dotSize : targetSize

        Behavior on x {
          enabled: root.horizontal
          NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on y {
          enabled: !root.horizontal
          NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on width {
          enabled: root.horizontal
          NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on height {
          enabled: !root.horizontal
          NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Unfocused status indicator (circle) inside slot
        Rectangle {
          anchors.centerIn: parent
          width: root.dotSize
          height: root.dotSize
          radius: root.dotSize / 2
          color: dotItem.isUrgent ? root.dotColorUrgent : ((dotItem.isActive || dotItem.isOccupied) ? root.dotColorActive : root.dotColorEmpty)
          opacity: dotItem.isFocused ? 0.0 : 1.0

          Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
          }
          Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.InOutQuad }
          }
        }
      }
    }
  }
}
