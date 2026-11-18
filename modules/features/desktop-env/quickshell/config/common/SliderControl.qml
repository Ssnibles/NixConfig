pragma ComponentBehavior: Bound
import QtQuick
import ".."

Item {
  id: root

  property real value: 0
  property color fillColour: Colours.accent
  // Colour of the quiet part of the track. The cover card tints it.
  property color trackColour: Colours.bgSubtle
  property real snapPercent: 0
  // Track style: "solid", "gradient", "segmented", "ticks", "hairline", "wavy"
  // or "shimmer".
  property string style: "solid"
  // Whether the track animates. Off lays the wavy style flat and stops the
  // shimmer, so a paused seek bar sits still.
  property bool animated: true

  signal moved(real value)

  implicitHeight: Config.spaceXl + Config.spaceMd
  implicitWidth: 120

  // Height of the band the track is drawn in. Compact gauges shrink it.
  property int trackAreaHeight: Config.spaceXl + Config.spaceSm

  // Track metrics. The bar styles use one or the other; the wavy style uses its
  // own stroke.
  readonly property int _pillHeight: Config.spaceLg
  readonly property int _hairlineHeight: Config.space2xs
  readonly property int _blockWidth: Config.spaceMd
  readonly property int _blockGap: Config.spaceXs
  readonly property int _blockHeight: Config.spaceSm
  readonly property int _tickWidth: Config.space2xs
  readonly property int _tickGap: Config.spaceSm
  readonly property int _tickHeight: Config.spaceMd
  readonly property int _sweepWidth: Config.space3xl
  readonly property int _waveThickness: Config.spaceXs
  readonly property int _waveAmplitude: Config.space2xs
  readonly property int _waveWavelength: Config.spaceLg

  // How far the painted squiggle is shifted, in pixels. The animation below
  // sweeps it over exactly one wavelength so the translate loops cleanly.
  property real wavePhase: 0

  // Internal drag state: _dragValue is live during drag, _pendingValue
  // holds the last dragged value until the bound 'value' property catches up.
  property real _dragValue: 0
  property real _pendingValue: -1
  readonly property real _visualValue: mouse.dragging ? _dragValue : (_pendingValue >= 0 ? _pendingValue : value)
  readonly property real _clampedValue: Math.max(0, Math.min(1, root._visualValue))
  // Smoothed value for the parts that slide. Seeded from the shown value rather
  // than starting at zero, so a freshly opened panel has them already in place;
  // only later changes animate.
  property real _shownValue: root._visualValue
  Behavior on _shownValue {
    enabled: !root.dragging
    NumberAnimation { duration: Config.animSmoothMs }
  }
  readonly property real _clampedShown: Math.max(0, Math.min(1, root._shownValue))
  // Exposed so surrounding UI (e.g. hover tooltips) can tell a drag from a hover.
  readonly property bool dragging: mouse.dragging

  // Clear the pending value once the external source reflects our drag.
  onValueChanged: {
    if (mouse && !mouse.dragging && _pendingValue >= 0 && Math.abs(value - _pendingValue) < 0.001) {
      _pendingValue = -1
      pendingClearTimer.stop()
    }
  }

  // Safety net: never latch on a pending value if the external source never
  // converges exactly (rounding, snapping, clamping, ...).
  Timer {
    id: pendingClearTimer
    interval: 1500
    repeat: false
    onTriggered: root._pendingValue = -1
  }

  // One sine of the wavy track, plus a second wavelength past the right edge so
  // the canvas can slide sideways without leaving a gap. Both the track and the
  // fill draw the same curve from the left edge, so the filled part lines up
  // with the track.
  function paintWave(canvas, colour) {
    var ctx = canvas.getContext("2d")
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.strokeStyle = colour
    ctx.lineWidth = root._waveThickness
    ctx.lineCap = "round"
    ctx.lineJoin = "round"
    ctx.beginPath()
    var mid = canvas.height / 2
    var amplitude = root.animated ? root._waveAmplitude : 0
    for (var x = 0; x <= canvas.width; x++) {
      var y = mid + Math.sin(x / root._waveWavelength * Math.PI * 2) * amplitude
      if (x === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.stroke()
  }

  // Travel is a translate of the painted canvas, not a redraw: the curve is
  // periodic, so shifting it by one wavelength lands on the same pixels and the
  // restart is seamless. A repaint per frame was the only continuous work the
  // panel did while playing.
  NumberAnimation {
    target: root
    property: "wavePhase"
    from: 0
    to: root._waveWavelength
    duration: Config.animSmoothMs * 8
    loops: Animation.Infinite
    running: root.style === "wavy" && root.visible && root.animated
  }

  Item {
    id: trackArea
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: root.trackAreaHeight

    readonly property real fillWidth: width * root._clampedValue

    Loader {
      anchors.fill: parent
      active: root.style === "solid" || root.style === "gradient" || root.style === "hairline"
      sourceComponent: pillTrack
    }

    Loader {
      anchors.fill: parent
      active: root.style === "segmented" || root.style === "ticks"
      sourceComponent: blockTrack
    }

    Loader {
      anchors.fill: parent
      active: root.style === "wavy"
      sourceComponent: wavyTrack
    }

    Loader {
      anchors.fill: parent
      active: root.style === "shimmer"
      sourceComponent: shimmerTrack
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      property bool dragging: false

      // Snap slider to increments (e.g. 5% steps) when snapPercent > 0.
      function _snap(v) {
        if (root.snapPercent <= 0) return v
        return Math.round(v / (root.snapPercent / 100)) * (root.snapPercent / 100)
      }

      function _computeValue(mx) {
        var raw = Math.max(0, Math.min(1, mx / width))
        return root.snapPercent > 0 ? _snap(raw) : raw
      }

      onPressed: function(mouse) {
        if (!root.enabled) return
        if (!dragging) {
          root._pendingValue = -1
          pendingClearTimer.stop()
          dragging = true
        }
        root._dragValue = _computeValue(mouse.x)
        root.moved(root._dragValue)
      }
      onReleased: {
        if (!dragging) return
        dragging = false
        root._pendingValue = root._dragValue
        pendingClearTimer.restart()
      }
      onPositionChanged: function(mouse) {
        if (dragging) {
          root._dragValue = _computeValue(mouse.x)
          root.moved(root._dragValue)
        }
      }
    }
  }

  // A rounded bar: the quiet track plus the filled part. Shared by the solid,
  // gradient, hairline and shimmer styles.
  component PillTrack: Item {
    id: pill

    property int barHeight: root._pillHeight
    property bool gradient: false
    property bool hoverBorder: true

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: pill.barHeight
      radius: height / 2
      color: root.trackColour
      border.width: pill.hoverBorder ? Config.borderWidth : 0
      border.color: pill.hoverBorder && mouse.containsMouse ? root.fillColour : "transparent"
      Behavior on border.color { ColorAnimation { duration: Config.animNormalMs } }
    }

    // Two fills so the default style stays a plain colour and the gradient keeps
    // its rounded ends.
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      visible: !pill.gradient
      width: trackArea.fillWidth
      height: pill.barHeight
      radius: height / 2
      color: root.fillColour
      Behavior on color { ColorAnimation { duration: Config.animSmoothMs } }
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      visible: pill.gradient
      width: trackArea.fillWidth
      height: pill.barHeight
      radius: height / 2
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Qt.lighter(root.fillColour, 1.5) }
        GradientStop { position: 1; color: root.fillColour }
      }
    }
  }

  // A row of rounded blocks, clipped at the filled width. Shared by the
  // segmented and ticks styles.
  component BlockTrack: Item {
    id: blocks

    property int blockWidth: root._blockWidth
    property int blockGap: root._blockGap
    property int blockHeight: root._blockHeight

    readonly property real pitch: blocks.blockWidth + blocks.blockGap
    readonly property int count: Math.max(1, Math.floor((blocks.width + blocks.blockGap) / blocks.pitch))
    readonly property real blockRadius: Math.min(blocks.blockWidth, blocks.blockHeight) / 2

    Repeater {
      model: blocks.count

      Rectangle {
        required property int index
        x: index * blocks.pitch
        anchors.verticalCenter: parent.verticalCenter
        width: blocks.blockWidth
        height: blocks.blockHeight
        radius: blocks.blockRadius
        color: root.trackColour
      }
    }

    Item {
      width: trackArea.fillWidth
      height: blocks.height
      clip: true

      Repeater {
        model: blocks.count

        Rectangle {
          required property int index
          x: index * blocks.pitch
          anchors.verticalCenter: parent.verticalCenter
          width: blocks.blockWidth
          height: blocks.blockHeight
          radius: blocks.blockRadius
          color: root.fillColour
        }
      }
    }
  }

  Component {
    id: pillTrack

    PillTrack {
      barHeight: root.style === "hairline" ? root._hairlineHeight : root._pillHeight
      gradient: root.style === "gradient"
      hoverBorder: root.style !== "hairline"
    }
  }

  Component {
    id: blockTrack

    BlockTrack {
      blockWidth: root.style === "ticks" ? root._tickWidth : root._blockWidth
      blockGap: root.style === "ticks" ? root._tickGap : root._blockGap
      blockHeight: root.style === "ticks" ? root._tickHeight : root._blockHeight
    }
  }

  Component {
    id: shimmerTrack

    Item {
      PillTrack { anchors.fill: parent; hoverBorder: false }

      // A light band sweeping over the filled part. It stays inside the pill so
      // it never paints over the background.
      Item {
        id: sweepClip
        width: trackArea.fillWidth
        height: parent.height
        clip: true

        Rectangle {
          id: sweepBand
          anchors.verticalCenter: parent.verticalCenter
          width: root._sweepWidth
          height: root._pillHeight
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.4) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
          }

          // The band starts and ends clear of the rounded caps.
          NumberAnimation on x {
            from: root._pillHeight / 2
            to: Math.max(root._pillHeight / 2, sweepClip.width - sweepBand.width - root._pillHeight / 2)
            duration: Config.animSmoothMs * 10
            loops: Animation.Infinite
            running: root.style === "shimmer" && root.visible && root.animated
          }
        }
      }
    }
  }

  Component {
    id: wavyTrack

    Item {
      id: waveArea
      // The canvases widen by a wavelength, so the track has to clip them.
      clip: true

      Canvas {
        id: waveBack
        // One wavelength wider than the track, shifted left by the phase.
        x: -root.wavePhase
        width: waveArea.width + root._waveWavelength
        height: waveArea.height
        onPaint: root.paintWave(waveBack, root.trackColour)
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
          target: root
          function onAnimatedChanged() { waveBack.requestPaint() }
          function onTrackColourChanged() { waveBack.requestPaint() }
        }
      }

      Item {
        width: waveArea.width * root._clampedShown
        height: waveArea.height
        clip: true

        Canvas {
          id: waveFill
          x: -root.wavePhase
          width: waveArea.width + root._waveWavelength
          height: waveArea.height
          onPaint: root.paintWave(waveFill, root.fillColour)
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()

          Connections {
            target: root
            function onFillColourChanged() { waveFill.requestPaint() }
            function onAnimatedChanged() { waveFill.requestPaint() }
          }
        }
      }

      // Handle at the end of the played part, taller than the wave so it reads
      // as the knob rather than another crest.
      Rectangle {
        visible: trackArea.fillWidth > 0
        x: Math.max(0, Math.min(waveArea.width - width, waveArea.width * root._clampedShown - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: Config.spaceXs
        height: Config.spaceLg
        radius: width / 2
        color: root.fillColour
      }
    }
  }
}
