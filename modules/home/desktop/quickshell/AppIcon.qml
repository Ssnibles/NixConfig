import Quickshell
import QtQuick
import QtQml

Item {
  id: root

  property var notification: null
  property color fallbackBg: Colors.bgSubtle
  property int iconSize: 24
  property string uiFont: "JetBrainsMono Nerd Font"

  width: iconSize
  height: iconSize

  Image {
    id: iconImg
    anchors.fill: parent
    source: {
      if (!root.notification) return ""
      if (root.notification.image && root.notification.image.length > 0) return root.notification.image
      var appIcon = root.notification.appIcon || ""
      if (appIcon.length === 0) return ""
      if (appIcon.startsWith("/")) return "file://" + appIcon
      var iconUrl = Quickshell.iconPath(appIcon, true)
      return iconUrl && iconUrl.length > 0 ? iconUrl : ""
    }
    sourceSize.width: iconSize
    sourceSize.height: iconSize
    fillMode: Image.PreserveAspectFit
    visible: status === Image.Ready
  }

  Rectangle {
    anchors.fill: parent
    radius: 6
    color: fallbackBg
    visible: !iconImg.visible

    Text {
      anchors.centerIn: parent
      text: (root.notification && root.notification.appName && root.notification.appName.length > 0)
        ? root.notification.appName[0].toUpperCase()
        : "?"
      color: Colors.fgMid
      font.family: root.uiFont
      font.pixelSize: 12
      font.bold: true
    }
  }
}
