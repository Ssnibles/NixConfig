pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

// On-demand weather data from wttr.in. The service does not poll: the widget
// asks for a refresh when it opens or when the refresh button is pressed, and
// the result is cached for Config.weatherCacheMinutes.
Singleton {
  id: root

  property bool loading: false
  property string error: ""
  property string location: ""
  property real temperature: 0
  property real feelsLike: 0
  property real high: 0
  property real low: 0
  property int humidity: 0
  property int wind: 0
  property int code: -1
  property string description: ""
  property var forecast: []
  property double lastUpdated: 0

  readonly property bool hasData: root.lastUpdated > 0
  readonly property string weatherIcon: root.iconFor(root.code)
  readonly property string temperatureText: root.hasData ? Math.round(root.temperature) + "°" : "--°"
  readonly property string highText: root.hasData ? Math.round(root.high) + "°" : "--°"
  readonly property string lowText: root.hasData ? Math.round(root.low) + "°" : "--°"
  readonly property string feelsLikeText: root.hasData ? Math.round(root.feelsLike) + "°" : "--°"
  readonly property string locationText: root.location !== ""
    ? root.location
    : (Config.weatherLocation.trim() !== "" ? Config.weatherLocation : "Location unavailable")

  function refresh(force) {
    if (root.loading) return
    if (!force && root.hasData && (Date.now() - root.lastUpdated) < Config.weatherCacheMinutes * 60000) {
      return
    }
    root.loading = true
    root.error = ""
    // wttr.in resolves a place name or coordinates in the path. With no path it
    // falls back to the address the request came from.
    var place = Config.weatherLocation.trim()
    var path = place === "" ? "" : encodeURIComponent(place)
    weatherProc.exec(["curl", "-fsS", "--max-time", "20", "https://wttr.in/" + path + "?format=j1"])
  }

  // wttr.in uses the same WMO-style codes as Open-Meteo.
  function iconFor(weatherCode) {
    if (weatherCode === 113) return "󰖙"
    if (weatherCode === 116) return "󰖕"
    if (weatherCode === 119 || weatherCode === 122) return "󰖐"
    if (weatherCode === 143 || weatherCode === 248 || weatherCode === 260) return "󰖑"
    if (weatherCode === 200 || weatherCode >= 386) return "󰖓"
    if ((weatherCode >= 179 && weatherCode <= 230) || (weatherCode >= 323 && weatherCode <= 377)) {
      return "󰖘"
    }
    if ((weatherCode >= 263 && weatherCode <= 302) || (weatherCode >= 305 && weatherCode <= 320) || (weatherCode >= 353 && weatherCode <= 365)) {
      return "󰖗"
    }
    return "󰖐"
  }

  Process {
    id: weatherProc

    stdout: StdioCollector {
      onStreamFinished: {
        var text = this.text ? this.text.trim() : ""
        if (!text) {
          root.loading = false
          root.error = "Weather unavailable"
          return
        }

        try {
          var data = JSON.parse(text)
          var current = data.current_condition && data.current_condition[0]
          var today = data.weather && data.weather[0]
          var area = data.nearest_area && data.nearest_area[0]
          if (!current) throw new Error("No current conditions")

          root.temperature = parseFloat(current.temp_C)
          root.feelsLike = parseFloat(current.FeelsLikeC)
          root.humidity = parseInt(current.humidity)
          root.wind = parseInt(current.windspeedKmph)
          root.code = parseInt(current.weatherCode)
          root.description = current.weatherDesc && current.weatherDesc[0]
            ? current.weatherDesc[0].value
            : "Unknown"

          if (today) {
            root.high = parseFloat(today.maxtempC)
            root.low = parseFloat(today.mintempC)
          }

          var days = []
          if (data.weather) {
            for (var d = 0; d < data.weather.length; d++) {
              var day = data.weather[d]
              var hourly = day.hourly || []
              // Noon is the most representative hour for a daily icon.
              var noon = hourly.length > 4 ? hourly[4] : (hourly[0] || null)
              var dayDate = new Date(day.date + "T12:00:00")
              days.push({
                label: d === 0 ? "Today" : Qt.formatDate(dayDate, "ddd"),
                icon: root.iconFor(noon ? parseInt(noon.weatherCode) : -1),
                high: Math.round(parseFloat(day.maxtempC)),
                low: Math.round(parseFloat(day.mintempC))
              })
            }
          }
          root.forecast = days

          if (area) {
            var city = area.areaName && area.areaName[0] ? area.areaName[0].value : ""
            var country = area.country && area.country[0] ? area.country[0].value : ""
            root.location = city + (country !== "" ? ", " + country : "")
          }

          root.lastUpdated = Date.now()
        } catch (e) {
          root.error = "Weather unavailable"
        }

        root.loading = false
      }
    }

    onExited: function() {
      if (root.loading) {
        root.loading = false
        root.error = "Weather unavailable"
      }
    }
  }
}
