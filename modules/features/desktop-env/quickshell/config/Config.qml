pragma Singleton
import Quickshell
import QtQuick

// Global layout knobs for the quickshell config. Everything here is consumed
// by the bars, the popup layer and the notification overlay. Per-widget
// details (sizes that only affect one widget) stay hard-coded in each
// widget's own file.
Singleton {
  // --- Fonts ------------------------------------------------------------
  readonly property string monoFont: Colors.monoFont !== undefined ? Colors.monoFont : "JetBrainsMono Nerd Font"
  readonly property string sansFont: "SF Pro Text"
  readonly property string serifFont: Colors.serifFont !== undefined ? Colors.serifFont : "Instrument Serif"

  // --- Command Center State & Geometry ----------------------------------
  property bool commandCenterVisible: false
  property var targetScreen: null
  property var lastActiveScreen: null
  property string commandCenterSide: {
    var envSide = (Quickshell.env("QS_COMMAND_CENTER_SIDE") || "").toLowerCase()
    if (envSide === "left" || envSide === "right") return envSide
    return "left" // "left" | "right"
  }
  readonly property int commandCenterWidth: 500
  readonly property int commandCenterRadius: 16
  readonly property int commandCenterCardRadius: 12
  readonly property int commandCenterMargin: 12
  readonly property int commandCenterSlideOffset: 60
  readonly property int commandCenterAnimDuration: 250
  readonly property int commandCenterCloseDuration: 180
  readonly property string commandCenterClockFormat: "HH:mm"
  readonly property string commandCenterDateFormat: "dddd, MMMM d"

  // --- Status Bars --------------------------------------------------------
  property bool barVisible: true
  readonly property string barType: wm === "niri" ? "niri" : "bar"
  readonly property bool hasTopBar: barVisible && barType !== "niri"
  readonly property bool hasLeftBar: barVisible && barType === "niri" && barSide !== "right"
  readonly property bool hasRightBar: barVisible && barType === "niri" && barSide === "right"

  // --- Window Manager Detection ------------------------------------------
  readonly property string wm: {
    var envWm = (Quickshell.env("QS_BAR") || "").toLowerCase()
    if (envWm !== "") return envWm

    var xdg = (Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase()
    if (xdg.indexOf("hyprland") !== -1) return "hyprland"
    if (xdg.indexOf("river") !== -1) return "river"
    if (xdg.indexOf("niri") !== -1) return "niri"
    if (xdg.indexOf("mango") !== -1) return "mangowc"

    return "mangowc"
  }


  // --- Media --------------------------------------------------------------
  // Whether the command center's media card always stays visible, showing
  // "Nothing is playing" when no media is active.
  readonly property bool alwaysShowMediaCard: true
  readonly property bool animateMediaIcon: false
  readonly property int mediaRotationDuration: 4000
  readonly property int mediaSeekDebounceMs: 200

  // --- Clock --------------------------------------------------------------
  readonly property string timeFormat: "HH:mm"

  // --- Niri vertical bar (niri-bar.qml) ----------------------------------
  readonly property int barWidth: 42
  readonly property string barSide: "left" // "left" | "right"
  readonly property int barMarginTop: 8
  readonly property int barMarginBottom: 8
  readonly property int barMarginLeft: 4
  readonly property int barMarginRight: 4
  readonly property int barSpacing: 8
  readonly property int volBarHeight: 64
  readonly property int wifiMaxTextLength: 90

  // --- Workspaces (WorkspacesWidget.qml) --------------------------------
  readonly property int workspaceDotSize: 12
  readonly property int workspaceDotSizeFocused: 34
  readonly property int workspaceDotSpacing: 6

  // --- Top Bar (bar.qml) -------------------------------------------------
  readonly property int barHeight: 34
  readonly property int barHorizontalMargin: 12
  readonly property int barLeftSpacing: 12
  readonly property int barRightSpacing: 10
  readonly property int mangowcMinWorkspaces: 5
  readonly property string mangowcClockFormat: "HH:mm"

  // --- Audio (VolumeWidget.qml) ------------------------------------------
  readonly property real volStep: 0.05

  // --- Window Title (WindowTitleWidget.qml) ------------------------------
  readonly property int windowTitleMaxWidthHorizontal: 350
  readonly property int windowTitleMaxWidthVertical: 120

  // --- Popup / tooltip ---------------------------------------------------
  readonly property int popupGap: 46 // distance from the bar to a popup
  readonly property int popupMaxWidth: 280
  readonly property int popupRadius: 12
  readonly property int popupContentMargins: 12
  readonly property int popupContentSpacing: 6
  readonly property int popupShowDelay: 150 // ms before a tooltip appears
  readonly property int popupFadeMs: 120
  readonly property int popupGraceMs: 700 // generous window so cursor can cross the gap without flicker

  // --- Notifications ------------------------------------------------------
  readonly property string notifPosition: "top-left"
  readonly property int notifMarginX: 12
  readonly property int notifMarginY: 12
  readonly property int notifTimeoutMs: 5000
  readonly property int notifTimeoutLowMs: 3000
  readonly property int notifTimeoutNormalMs: 5000
  readonly property int notifTimeoutCriticalMs: 0 // 0 = persistent, do not auto-dismiss
  readonly property int notifMaxVisible: 5
  readonly property int notifMaxHistory: 30
  readonly property int notifWidth: 320
  readonly property int notifRadius: 12
  readonly property int notifCardMargins: 12
  readonly property int notifSpacing: 8
  readonly property int notifIconSize: 40
  readonly property int notifMediaIconSize: 48
  readonly property int notifIconRadius: 8
  readonly property int notifMaxLines: 5
  readonly property bool notifShowActions: true
  readonly property bool notifDismissOnAction: true
  readonly property bool notifShowMediaToasts: true
  readonly property bool notifAllScreens: false
  readonly property string notifLeftClickAction: "dismiss" // "dismiss" or "focus"
  readonly property string notifDefaultFallbackLogo: "preferences-desktop-notification"
  readonly property string notifDefaultFallbackGlyph: "󰂚"

  // App Name / Desktop Entry -> Preferred System Icon name, custom image path, or fallback logo
  // When an app sends a notification without a profile picture (or if avatar loading fails),
  // this map ensures the card accurately falls back to the app's real logo.
  readonly property var notifAppIcons: ({
    "discord": "vesktop",
    "vesktop": "vesktop",
    "webcord": "vesktop",
    "com.discordapp.discord": "vesktop",
    "spotify": "spotify-client",
    "spotify-client": "spotify-client",
    "firefox": "firefox-devedition",
    "firefox-developer-edition": "firefox-devedition",
    "firefox-devedition": "firefox-devedition",
    "firefoxdevedition": "firefox-devedition",
    "zen": "zen-browser",
    "zen-browser": "zen-browser",
    "helium": "helium",
    "helium-browser": "helium",
    "ghostty": "ghostty",
    "kitty": "kitty",
    "foot": "foot",
    "alacritty": "alacritty",
    "code": "code",
    "vscode": "code",
    "vscodium": "vscodium",
    "nvim": "nvim",
    "neovim": "nvim",
    "steam": "steam",
    "telegram": "telegram",
    "telegramdesktop": "telegram",
    "slack": "slack",
    "signal": "signal-desktop",
    "signal-desktop": "signal-desktop",
    "thunderbird": "thunderbird",
    "amberol": "io.bassi.Amberol",
    "boxbuddy": "io.github.dvlv.boxbuddyrs",
    "pavucontrol": "org.pulseaudio.pavucontrol",
    "blueman": "blueman",
    "nix": "nix-snowflake"
  })

  // Fallback Nerd Font glyphs when no icon or image is available
  readonly property var notifAppGlyphs: ({
    "discord": "󰙯",
    "vesktop": "󰙯",
    "webcord": "󰙯",
    "spotify": "󰓇",
    "music": "󰎈",
    "amberol": "󰎈",
    "firefox": "󰈹",
    "zen": "󰈹",
    "chrome": "󰊯",
    "chromium": "󰊯",
    "brave": "󰊯",
    "browser": "󰈹",
    "terminal": "󰅍",
    "kitty": "󰅍",
    "ghostty": "󰅍",
    "foot": "󰅍",
    "alacritty": "󰅍",
    "code": "󰨞",
    "vscode": "󰨞",
    "vscodium": "󰨞",
    "editor": "󰨞",
    "nvim": "󰨞",
    "neovim": "󰨞",
    "steam": "󰓓",
    "telegram": "󰔁",
    "slack": "󰒱",
    "signal": "󰍡",
    "mail": "󰇮",
    "thunderbird": "󰇮",
    "volume": "󰕾",
    "audio": "󰕾",
    "pipewire": "󰕾",
    "wireplumber": "󰕾",
    "network": "󰤨",
    "wifi": "󰤨",
    "bluetooth": "󰂯",
    "battery": "󰂄",
    "power": "󰂄",
    "upower": "󰂄",
    "brightness": "󰃠",
    "backlight": "󰃠",
    "screenshot": "󰄄",
    "grim": "󰄄",
    "slurp": "󰄄",
    "package": "󰏗",
    "nix": "󰏗",
    "system": "󰍹"
  })

  // Known browser / media player apps for media detection
  readonly property var notifMediaApps: [
    "spotify",
    "amberol",
    "zen",
    "helium",
    "qutebrowser",
    "firefox",
    "chrome",
    "chromium",
    "brave",
    "vivaldi",
    "librewolf",
    "vlc",
    "mpv"
  ]


  // --- Lock Screen --------------------------------------------------------
  readonly property string lockAvatarPath: Quickshell.shellDir + "/assets/avatar.png"
  readonly property string lockFallbackIcon: "󰀉"
  readonly property string lockWallpaperPath: "file://" + (Quickshell.env("HOME") || "/home/josh") + "/Pictures/wallpaper"
  readonly property string lockClockFormat: "HH:mm"
  readonly property string lockDateFormat: "dddd, MMMM d"
  readonly property int lockCardWidth: 440
  readonly property int lockAvatarSize: 64
  readonly property int lockCardRadius: 12
  readonly property int lockInputRadius: 10
  readonly property real lockBackgroundDimming: 0.8
  readonly property real lockBlurPercentage: 0.5

  // --- External App & System Commands ------------------------------------
  readonly property var cmdMixer: ["pavucontrol"]
  readonly property var cmdNetworkManager: ["foot", "-e", "nmtui"]
  readonly property var cmdBluetoothManager: ["blueman-manager"]
  readonly property var cmdLock: ["quickshell", "ipc", "call", "lockscreen", "lock"]
  readonly property var cmdSleep: ["systemctl", "suspend"]
  readonly property var cmdReboot: ["systemctl", "reboot"]
  readonly property var cmdPoweroff: ["systemctl", "poweroff"]
}
