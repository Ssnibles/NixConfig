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
    // Resolve icon source from notification data:
    // 1. Inline image data if provided
    // 2. App icon path (local paths need file:// prefix for QML Image)
    // 3. Freedesktop icon name via icon:// scheme
    source: {
      if (!root.notification) return "";
      if (root.notification.image && root.notification.image.length > 0) return root.notification.image;
      if (!root.notification.appIcon || root.notification.appIcon.length === 0) return "";
      if (root.notification.appIcon.startsWith("/")) return "file://" + root.notification.appIcon;
      return "image://icon/" + root.notification.appIcon;
    }
    sourceSize.width: iconSize
    sourceSize.height: iconSize
    fillMode: Image.PreserveAspectFit
    visible: status === Image.Ready
  }

  Rectangle {
    anchors.fill: parent
    radius: 4
    color: fallbackBg
    border.width: 1
    border.color: Colors.border
    visible: !iconImg.visible

    Text {
      anchors.centerIn: parent
      text: (root.notification && root.notification.appName && root.notification.appName.length > 0)
        ? root.notification.appName[0].toUpperCase()
        : "N"
      color: Colors.teal
      font.family: uiFont
      font.pixelSize: 11
      font.bold: true
    }
  }
}
