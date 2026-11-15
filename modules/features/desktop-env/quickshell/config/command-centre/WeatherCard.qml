pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".."

// Weather card for the bento Command Centre. The service only fetches when
// the card opens or when the refresh button is pressed.
Card {
  id: root

  implicitHeight: content.implicitHeight + Config.spaceXl * 2
  cardColour: Colours.bg
  cardRadius: Config.commandCentreRadius
  readonly property bool showForecast: Config.weatherShowForecast
    && WeatherService.hasData
    && WeatherService.forecast.length > 0

  Component.onCompleted: WeatherService.refresh(false)

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: Config.spaceXl
    spacing: Config.space2xl

    ColumnLayout {
      Layout.fillWidth: true
      Layout.rightMargin: Config.space2xl
      spacing: Config.space2xs

      RowLayout {
        spacing: Config.spaceLg

        Text {
          text: WeatherService.weatherIcon
          color: Colours.yellow
          font.family: Session.monoFont
          font.pixelSize: Config.iconSizeXl * 3
          Layout.alignment: Qt.AlignVCenter
        }

        Text {
          text: WeatherService.temperatureText
          color: Colours.fg
          font.family: Session.serifFont
          font.pixelSize: Config.fontSize3xl
          font.italic: true
          Layout.alignment: Qt.AlignVCenter
        }
      }

      Text {
        Layout.fillWidth: true
        text: WeatherService.hasData
          ? WeatherService.description
          : (WeatherService.loading ? "Fetching weather..." : (WeatherService.error || "No weather data"))
        color: Colours.fgMid
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeLg
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: WeatherService.hasData
        text: WeatherService.locationText
        color: Colours.fgDim
        font.family: Session.sansFont
        font.pixelSize: Config.fontSizeMd
        elide: Text.ElideRight
      }
    }

    Divider {
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      visible: root.showForecast
      spacing: Config.spaceSm

      Repeater {
        model: WeatherService.forecast

        // A plain Column fills the row width here; a ColumnLayout delegate
        // inside the Repeater does not.
        delegate: Column {
          required property var modelData
          Layout.fillWidth: true
          spacing: Config.space2xs

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.label
            color: Colours.fgMid
            font.family: Session.sansFont
            font.pixelSize: Config.fontSizeSm
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.icon
            color: Colours.yellow
            font.family: Session.monoFont
            font.pixelSize: Config.iconSizeLg
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.high + "° / " + modelData.low + "°"
            color: Colours.fg
            font.family: Session.sansFont
            font.pixelSize: Config.fontSizeSm
          }
        }
      }
    }

    Text {
      Layout.fillWidth: true
      visible: WeatherService.hasData
      text: (root.showForecast ? "" : "H " + WeatherService.highText + " · L " + WeatherService.lowText + " · ")
        + "Feels " + WeatherService.feelsLikeText + " · " + WeatherService.humidity + "% · " + WeatherService.wind + " km/h"
      color: Colours.fgDim
      font.family: Session.sansFont
      font.pixelSize: Config.fontSizeSm
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }
  }

  IconButton {
    id: refreshButton
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Config.spaceXl
    anchors.rightMargin: Config.spaceXl
    buttonSize: Config.spaceXl + Config.space2xs
    iconSize: Config.iconSizeSm
    icon: "󰑐"
    enabled: !WeatherService.loading
    onClicked: WeatherService.refresh(true)

    NumberAnimation {
      target: refreshButton
      property: "rotation"
      from: 0
      to: 360
      duration: 1000
      loops: Animation.Infinite
      running: WeatherService.loading
      onRunningChanged: if (!running) refreshButton.rotation = 0
    }
  }
}
