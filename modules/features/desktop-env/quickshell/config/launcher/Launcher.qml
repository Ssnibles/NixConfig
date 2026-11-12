pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "Calc.js" as Calc

// Minimal application launcher and calculator.
// Apps are read from the desktop entry files by launcher/desktop-entries.sh.
Scope {
  id: root

  property var allApps: []
  property var results: []
  property int selected: 0
  property string query: ""
  property bool actionMenuVisible: false
  property var actions: []
  property int actionSelected: 0
  property var actionItem: null

  function open(): void {
    WmService.resolveTargetScreen(function(screen) {
      Config.targetScreen = screen || Quickshell.screens[0]
      root.closeActions()
      root.query = ""
      root.selected = 0
      root.refresh()
      Config.launcherVisible = true
    })
  }

  function close(): void {
    root.closeActions()
    Config.launcherVisible = false
  }

  function toggle(): void {
    if (Config.launcherVisible) root.close()
    else root.open()
  }

  function move(delta: int): void {
    if (root.results.length === 0) return
    root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + delta))
  }

  function moveAction(delta: int): void {
    if (root.actions.length === 0) return
    root.actionSelected = Math.max(0, Math.min(root.actions.length - 1, root.actionSelected + delta))
  }

  function moveSelection(delta: int): void {
    if (root.actionMenuVisible) root.moveAction(delta)
    else root.move(delta)
  }

  function openActions(index: int): void {
    var item = root.results[index]
    if (!item) return

    var list = []
    if (item.kind === "calc") {
      list.push({ name: "Copy result", detail: item.name, copy: item.name })
      list.push({ name: "Copy expression", detail: root.query, copy: root.query })
    } else {
      var appActions = item.actions || []
      for (var i = 0; i < appActions.length; i++) {
        list.push({
          name: appActions[i].name,
          detail: appActions[i].exec || "",
          exec: appActions[i].exec || "",
          terminal: item.terminal === true
        })
      }
      if (item.exec) {
        list.push({ name: "Launch", detail: item.exec, exec: item.exec, terminal: item.terminal === true })
        list.push({ name: "Run in terminal", detail: item.exec, exec: item.exec, terminal: true })
        list.push({ name: "Copy command", detail: item.exec, copy: item.exec })
      }
      if (item.file) list.push({ name: "Copy desktop file path", detail: item.file, copy: item.file })
      if (item.id) list.push({ name: "Copy desktop ID", detail: item.id, copy: item.id })
    }

    if (list.length === 0) return
    root.actionItem = item
    root.actions = list
    root.actionSelected = 0
    root.actionMenuVisible = true
  }

  function closeActions(): void {
    root.actionMenuVisible = false
    root.actions = []
    root.actionSelected = 0
    root.actionItem = null
  }

  function executeAction(index: int): void {
    var action = root.actions[index]
    if (!action) return

    if (action.copy) Quickshell.execDetached(["wl-copy", action.copy])
    else if (action.exec) {
      if (action.terminal) Quickshell.execDetached(["kitty", "-e", "sh", "-c", action.exec])
      else Quickshell.execDetached(["sh", "-c", action.exec])
    }
    root.close()
  }

  function activate(withActions: bool): void {
    if (root.actionMenuVisible) {
      root.executeAction(root.actionSelected)
    } else if (withActions) {
      root.openActions(root.selected)
    } else {
      root.launch(root.selected)
    }
  }

  function refresh(): void {
    if (!appProc.running) appProc.running = true
  }

  function updateResults(): void {
    var q = root.query.trim().toLowerCase()
    var out = []

    // A valid expression becomes the first result, so Enter copies it.
    if (q !== "") {
      var value = Calc.evaluate(root.query)
      if (value !== null) {
        out.push({
          kind: "calc",
          name: Calc.format(value),
          comment: "Copy result",
          icon: ""
        })
      }
    }

    for (var i = 0; i < root.allApps.length; i++) {
      var app = root.allApps[i]
      var name = app.name.toLowerCase()
      var haystack = name + " " + (app.comment || "").toLowerCase()
      var score = -1
      if (q === "") score = 0
      else if (name.indexOf(q) === 0) score = 100 - name.length
      else if (name.indexOf(q) !== -1) score = 50 - name.length
      else if (haystack.indexOf(q) !== -1) score = 10
      if (score < 0) continue
      out.push({
        kind: "app",
        name: app.name,
        comment: app.comment || "",
        icon: app.icon || "",
        exec: app.exec || "",
        terminal: app.terminal === true,
        actions: app.actions || [],
        file: app.file || "",
        id: app.id || "",
        score: score
      })
    }

    var calcRows = []
    var appRows = []
    for (var j = 0; j < out.length; j++) {
      if (out[j].kind === "calc") calcRows.push(out[j])
      else appRows.push(out[j])
    }
    appRows.sort(function(a, b) {
      if (a.score !== b.score) return b.score - a.score
      return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
    })

    root.results = calcRows.concat(appRows).slice(0, Config.launcherMaxResults)
    root.selected = 0
  }

  function launch(index: int): void {
    var item = root.results[index]
    if (!item) return

    if (item.kind === "calc") {
      Quickshell.execDetached(["wl-copy", item.name])
    } else if (item.exec) {
      if (item.terminal) Quickshell.execDetached(["kitty", "-e", "sh", "-c", item.exec])
      else Quickshell.execDetached(["sh", "-c", item.exec])
    }
    root.close()
  }

  onQueryChanged: {
    if (root.actionMenuVisible) root.closeActions()
    root.updateResults()
  }

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      root.toggle()
    }

    function open(): void {
      root.open()
    }

    function close(): void {
      root.close()
    }
  }

  Process {
    id: appProc
    command: [ "bash", Quickshell.shellDir + "/launcher/desktop-entries.sh" ]
    stdout: StdioCollector {
      onStreamFinished: {
        var apps = []
        var text = this.text ? this.text.trim() : ""
        var lines = text === "" ? [] : text.split("\n")
        for (var i = 0; i < lines.length; i++) {
          if (lines[i] === "") continue
          try {
            apps.push(JSON.parse(lines[i]))
          } catch (e) {
            console.warn("launcher: bad desktop entry line:", lines[i])
          }
        }
        apps.sort(function(a, b) {
          return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
        })
        root.allApps = apps
        root.updateResults()
      }
    }
  }

  Component.onCompleted: root.refresh()

  Variants {
    model: Config.launcherVisible && Config.targetScreen ? [ Config.targetScreen ] : []

    delegate: PanelWindow {
      required property var modelData
      screen: modelData

      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true
      color: "transparent"
      aboveWindows: true
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      exclusionMode: ExclusionMode.Ignore
      visible: true

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }

      Card {
        width: Config.launcherWidth
        height: Config.launcherHeight
        anchors.centerIn: parent
        cardRadius: Config.commandCentreCardRadius

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onClicked: {}
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 8

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 10
            color: Colours.bgSubtle
            border.width: 1
            border.color: Colours.border

            TextInput {
              id: input
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              verticalAlignment: TextInput.AlignVCenter
              color: Colours.fg
              selectionColor: Colours.accent
              selectedTextColor: Colours.bg
              font.family: Session.sansFont
              font.pixelSize: 16
              focus: true
              readOnly: root.actionMenuVisible
              onTextChanged: root.query = text
              Keys.onPressed: function(event) {
                if (event.modifiers & Qt.ControlModifier) {
                  if (event.key === Qt.Key_J) {
                    root.moveSelection(1)
                    event.accepted = true
                    return
                  }
                  if (event.key === Qt.Key_K) {
                    root.moveSelection(-1)
                    event.accepted = true
                    return
                  }
                  if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate(true)
                    event.accepted = true
                    return
                  }
                }

                if (event.key === Qt.Key_Down) {
                  root.moveSelection(1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                  root.moveSelection(-1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.activate(false)
                  event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                  if (root.actionMenuVisible) root.closeActions()
                  else root.close()
                  event.accepted = true
                }
              }
              Component.onCompleted: forceActiveFocus()
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 12
              visible: input.text === ""
              text: "Search apps or calculate"
              color: Colours.fgDim
              font.family: Session.sansFont
              font.pixelSize: 16
            }
          }

          Text {
            Layout.fillWidth: true
            visible: root.actionMenuVisible
            text: root.actionItem ? (root.actionItem.kind === "calc" ? "Calculator actions" : "Actions for " + root.actionItem.name) : "Actions"
            color: Colours.fgMid
            font.family: Session.sansFont
            font.pixelSize: 12
            leftPadding: 4
          }

          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
              id: list
              visible: !root.actionMenuVisible
              anchors.fill: parent
              clip: true
              model: root.results
              currentIndex: root.selected
              interactive: true
              boundsBehavior: Flickable.StopAtBounds
              onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

              ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 6

                contentItem: Rectangle {
                  implicitWidth: 6
                  radius: 3
                  color: Colours.fgDim
                }
              }

              delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                width: (row.modelData.kind === "calc" && root.results.length === 1) ? list.width : list.width - 24
                height: row.modelData.kind === "calc" ? (root.results.length === 1 ? list.height : 92) : 44
                radius: 8
                color: (index === root.selected && !(row.modelData.kind === "calc" && root.results.length === 1)) ? Colours.bgSubtle : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 10
                  visible: row.modelData.kind !== "calc"

                  Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    source: {
                      if (!row.modelData.icon) return ""
                      if (row.modelData.icon.charAt(0) === "/") return "file://" + row.modelData.icon
                      return Quickshell.iconPath(row.modelData.icon, true)
                    }
                    visible: row.modelData.icon !== ""
                    smooth: true
                  }

                  Text {
                    visible: !row.modelData.icon
                    Layout.preferredWidth: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.kind === "calc" ? "=" : "•"
                    color: Colours.accent
                    font.family: Session.monoFont
                    font.pixelSize: 16
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                      Layout.fillWidth: true
                      text: row.modelData.name
                      color: Colours.fg
                      font.family: Session.sansFont
                      font.pixelSize: 14
                      elide: Text.ElideRight
                    }

                    Text {
                      Layout.fillWidth: true
                      visible: text !== ""
                      text: row.modelData.comment
                      color: Colours.fgDim
                      font.family: Session.sansFont
                      font.pixelSize: 11
                      elide: Text.ElideRight
                    }
                  }
                }

                Column {
                  visible: row.modelData.kind === "calc"
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: row.modelData.name
                    color: Colours.fg
                    font.family: Session.sansFont
                    font.pixelSize: root.results.length === 1 ? 44 : 32
                    font.weight: Font.DemiBold
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: row.modelData.comment
                    color: Colours.fgDim
                    font.family: Session.sansFont
                    font.pixelSize: 11
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: root.selected = row.index
                  onClicked: root.launch(row.index)
                }
              }
            }

            ListView {
              id: actionList
              visible: root.actionMenuVisible
              anchors.fill: parent
              clip: true
              model: root.actions
              currentIndex: root.actionSelected
              interactive: true
              boundsBehavior: Flickable.StopAtBounds
              onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

              ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 6

                contentItem: Rectangle {
                  implicitWidth: 6
                  radius: 3
                  color: Colours.fgDim
                }
              }

              delegate: Rectangle {
                id: actionRow
                required property var modelData
                required property int index

                width: actionList.width - 24
                height: 44
                radius: 8
                color: index === root.actionSelected ? Colours.bgSubtle : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10

                  Text {
                    Layout.preferredWidth: 16
                    horizontalAlignment: Text.AlignHCenter
                    text: "•"
                    color: Colours.accent
                    font.family: Session.monoFont
                    font.pixelSize: 14
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                      Layout.fillWidth: true
                      text: actionRow.modelData.name
                      color: Colours.fg
                      font.family: Session.sansFont
                      font.pixelSize: 14
                      elide: Text.ElideRight
                    }

                    Text {
                      Layout.fillWidth: true
                      visible: text !== ""
                      text: actionRow.modelData.detail || ""
                      color: Colours.fgDim
                      font.family: Session.sansFont
                      font.pixelSize: 11
                      elide: Text.ElideRight
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: root.actionSelected = actionRow.index
                  onClicked: root.executeAction(actionRow.index)
                }
              }
            }

            Text {
              anchors.centerIn: parent
              visible: !root.actionMenuVisible && root.results.length === 0
              text: "No matches"
              color: Colours.fgDim
              font.family: Session.sansFont
              font.pixelSize: 12
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
      }
    }
  }
}
