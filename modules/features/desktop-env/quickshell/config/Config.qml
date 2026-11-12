pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

// Settings for the shell. Every value here is a literal you can edit.
//
// Layout that depends on the session (compositor, $HOME, environment
// overrides) lives in services/Session.qml, and transient state that resets on
// restart lives in services/UiState.qml. Sections follow the order: theme
// tokens, bar, command centre, launcher, media, notifications, lock screen,
// audio and OSD, tray, external commands.
Singleton {
    // Fonts and type scale. Nix generates the real values into Colours.qml;
    // these are the fallbacks Session uses when a generated value is missing.
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string sansFont: "SF Pro Text"
    readonly property string serifFont: "Instrument Serif"

    readonly property int fontSizeXs: 11
    readonly property int fontSizeSm: 12
    readonly property int fontSizeMd: 13
    readonly property int fontSizeLg: 15
    readonly property int iconSizeSm: 13
    readonly property int iconSizeMd: 16
    readonly property int iconSizeLg: 18

    // Spacing scale. From spaceXs up each step multiplies by 1.618 and rounds
    // to even pixels; space2xs is the half step for micro gaps. Use space2xs for
    // related text lines, spaceXs for micro insets, spaceSm for icon-label gaps
    // and compact chips, spaceMd for rows and list padding, spaceLg for card
    // padding and section gaps, and spaceXl upward for hero spacing and screen
    // edges.
    readonly property int space2xs: 2
    readonly property int spaceXs: 4
    readonly property int spaceSm: 6
    readonly property int spaceMd: 10
    readonly property int spaceLg: 16
    readonly property int spaceXl: 26
    readonly property int space2xl: 42
    readonly property int space3xl: 68

    // Border widths and corner radii. Radii reuse the spacing steps so nested
    // surfaces and controls keep the same proportions.
    readonly property int borderWidth: 1
    readonly property int borderWidthFocus: 2
    readonly property int itemRadiusXs: 4
    readonly property int itemRadiusSm: 6
    readonly property int itemRadiusMd: 10

    // Shared pill, surface and animation tokens
    readonly property int pillHeightHorizontal: 24
    readonly property int pillHeightVertical: 30
    readonly property int pillPaddingHorizontal: 10
    readonly property int animFastMs: 100
    readonly property int animNormalMs: 120
    readonly property int animSmoothMs: 150

    // Status bars
    readonly property int barHeight: 34
    readonly property int barWidth: 42
    // Default edge for the Niri side bar; $QS_BAR_SIDE overrides it.
    readonly property string barSide: "left"
    readonly property int barHorizontalMargin: 16
    readonly property int barLeftSpacing: 10
    readonly property int barRightSpacing: 10
    readonly property int barMarginTop: 10
    readonly property int barMarginBottom: 10
    readonly property int barMarginLeft: 4
    readonly property int barMarginRight: 4
    readonly property int barSpacing: 10
    readonly property int minWorkspaces: 5

    // Which widgets the bar shows. Order is fixed in bar/bar.qml; the shared
    // widgets keep working normally in the Command Centre and lock screen.
    readonly property bool barShowClock: true
    readonly property bool barShowCommandCentre: true
    readonly property bool barShowLayout: true
    readonly property bool barShowWindowTitle: true
    readonly property bool barShowWorkspaces: true
    readonly property bool barShowTray: true
    readonly property bool barShowMedia: true
    readonly property bool barShowVolume: true
    readonly property bool barShowNetwork: true
    readonly property bool barShowBattery: true

    // Bar widgets that carry their own geometry
    readonly property int volBarHeight: 64
    readonly property int wifiMaxTextLength: 90
    readonly property int windowTitleMaxWidthHorizontal: 350
    readonly property int windowTitleMaxWidthVertical: 120
    readonly property int workspaceDotSize: 12
    readonly property int workspaceDotSizeFocused: 34
    readonly property int workspaceDotSpacing: 6

    // Command centre
    readonly property int commandCentreWidth: 500
    readonly property int commandCentreRadius: 16
    readonly property int commandCentreCardRadius: 10
    readonly property int commandCentreMargin: 16
    readonly property int commandCentreSlideOffset: 60
    readonly property int commandCentreAnimDuration: 250
    readonly property int commandCentreCloseDuration: 180
    readonly property string commandCentreClockFormat: "HH:mm"
    readonly property string commandCentreDateFormat: "dddd, MMMM d"
    // Default edge; $QS_COMMAND_CENTRE_SIDE overrides it.
    readonly property string commandCentreSide: "left"
    readonly property bool ccShowSinkSwitcher: true
    // Place the output chips above the volume slider instead of below it.
    readonly property bool ccSinkSwitcherAboveVolume: false
    // Microphone slider visibility: "smart" (only while a capture stream is
    // active), "always", or "hidden".
    readonly property string ccMicSliderMode: "smart"
    readonly property bool ccShowBrightnessSlider: true
    // Mixer shortcut at the start of the output row. Empty label renders the
    // gear on its own.
    readonly property bool ccShowAudioMixer: true
    readonly property string ccAudioMixerLabel: ""

    // Launcher
    readonly property int launcherWidth: 760
    readonly property int launcherHeight: 500
    readonly property int launcherMaxResults: 50

    // Media
    // Whether the command centre's media card always stays visible, showing
    // "Nothing is playing" when no media is active.
    readonly property bool alwaysShowMediaCard: true
    readonly property bool mediaShowPlayerBadge: true
    readonly property bool mediaAllowPlayerSwitch: true
    readonly property int mediaPopupWidth: 320
    readonly property bool animateMediaIcon: false
    readonly property int mediaRotationDuration: 4000
    readonly property int mediaSeekDebounceMs: 200

    // Clock
    readonly property string timeFormat: "HH:mm"

    // Popup and tooltip layer
    readonly property int popupGap: 42
    readonly property int popupMaxWidth: 280
    readonly property int popupRadius: 10
    readonly property int popupContentMargins: 16
    readonly property int popupContentSpacing: 6
    readonly property int popupShowDelay: 150
    readonly property int popupFadeMs: 120
    // Generous window so the cursor can cross the gap without flicker.
    readonly property int popupGraceMs: 700

    // Notifications
    // Position on screen: "top-left", "top-centre" (or "top"), "top-right",
    // "centre-left", "centre", "centre-right", "bottom-left",
    // "bottom-centre" (or "bottom"), "bottom-right".
    readonly property string notifPosition: "top-right"
    readonly property int notifMarginX: 16
    readonly property int notifMarginY: 16
    readonly property int notifTimeoutMs: 5000
    readonly property int notifTimeoutLowMs: 3000
    // 0 = persistent, do not auto-dismiss.
    readonly property int notifTimeoutCriticalMs: 0
    readonly property int notifMaxVisible: 5
    readonly property int notifMaxHistory: 30
    readonly property int notifWidth: 320
    readonly property int notifRadius: 10
    readonly property int notifCardMargins: 16
    readonly property int notifSpacing: 10
    readonly property int notifIconSize: 40
    readonly property int notifMediaIconSize: 48
    readonly property int notifIconRadius: 10
    readonly property int notifMaxLines: 5
    readonly property bool notifShowActions: true
    readonly property bool notifDismissOnAction: true
    readonly property bool notifShowMediaToasts: true
    readonly property bool notifAllScreens: false
    // "dismiss" or "focus".
    readonly property string notifLeftClickAction: "dismiss"
    readonly property string notifDefaultFallbackLogo: "preferences-desktop-notification"
    readonly property string notifDefaultFallbackGlyph: "󰂚"

    // App name or desktop entry to preferred system icon override. Apps whose
    // icon name matches their appName or .desktop entry are resolved
    // automatically by NotificationIcons via Quickshell.iconPath / DesktopEntries.
    readonly property var notifAppIcons: ({
            "discord": "vesktop",
            "webcord": "vesktop",
            "spotify": "spotify-client",
            "firefox": "firefox-devedition",
            "helium": "helium",
            "vscode": "code",
            "neovim": "nvim",
            "telegram": "telegram",
            "signal": "signal-desktop",
            "amberol": "io.bassi.Amberol",
            "boxbuddy": "io.github.dvlv.boxbuddyrs",
            "pavucontrol": "org.pulseaudio.pavucontrol",
            "nix": "nix-snowflake"
        })

    // Fallback Nerd Font glyphs when no icon or image is available.
    readonly property var notifAppGlyphs: ({
            "discord": "󰙯",
            "vesktop": "󰙯",
            "webcord": "󰙯",
            "spotify": "󰓇",
            "music": "󰎈",
            "amberol": "󰎈",
            "firefox": "󰈹",
            "chrome": "󰊯",
            "chromium": "󰊯",
            "brave": "󰊯",
            "browser": "󰈹",
            "terminal": "󰅍",
            "kitty": "󰅍",
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

    // Known browser and media player apps for media detection.
    readonly property var notifMediaApps: ["spotify", "amberol", "zen", "helium", "qutebrowser", "firefox", "chrome", "chromium", "brave", "vivaldi", "librewolf", "vlc", "mpv"]

    // Lock screen
    // Empty means the bundled avatar; empty wallpaper means
    // $HOME/Pictures/wallpaper. Both are resolved in Session.qml.
    readonly property string lockAvatarPath: ""
    readonly property string lockWallpaperPath: ""
    readonly property string lockFallbackIcon: "󰀉"
    readonly property string lockClockFormat: "HH:mm"
    readonly property string lockDateFormat: "dddd, MMMM d"
    readonly property int lockCardWidth: 440
    readonly property int lockAvatarSize: 64
    readonly property int lockInputRadius: 10
    readonly property real lockBackgroundDimming: 0.8
    readonly property real lockBlurPercentage: 0.5
    // Status pill cluster: "top-right" (default), "top-left", "bottom-right",
    // "bottom-left", or "split" / "corners". $QS_LOCK_STATUS_POS overrides it.
    readonly property string lockStatusPosition: "top-right"
    readonly property int lockStatusMargin: 26
    readonly property int lockStatusSpacing: 10

    // Audio, microphone, brightness and OSD
    readonly property real volStep: 0.05
    readonly property real volMax: 1.5
    readonly property real micStep: 0.05
    readonly property real brightnessStep: 0.05
    readonly property bool osdEnabled: true
    // Position on screen: "bottom" (or "bottom-centre"), "top" (or
    // "top-centre"), "centre", "top-left", "top-right", "bottom-left",
    // "bottom-right".
    readonly property string osdPosition: "bottom-centre"
    readonly property bool osdAllScreens: false
    readonly property int osdTimeoutMs: 1800
    readonly property int osdWidth: 260
    readonly property int osdHeight: 46
    // -1 = full pill capsule (osdHeight / 2).
    readonly property int osdRadius: -1
    readonly property int osdMarginX: 26
    readonly property int osdMarginY: 68

    // System tray
    // Case-insensitive list of tray app IDs, titles, or substrings to hide by
    // default (e.g. ["nm-applet", "blueman", "steam"]).
    readonly property var trayHiddenApps: ["nm-applet", "vicinae"]
    // Left-click behaviour on tray icons:
    //   "focus"    = activate and focus the application window
    //   "activate" = native StatusNotifierItem activate() only
    //   "menu"     = open the context menu on left-click too
    readonly property string trayLeftClickAction: "focus"
    readonly property int trayIconSize: 15
    readonly property int trayButtonSize: 20
    readonly property int traySpacing: 4
    readonly property int trayMenuWidth: 240
    readonly property bool trayShowAppIdInMenu: true
    readonly property bool trayAllowSessionHide: true

    // External apps and system commands
    readonly property var cmdMixer: ["pavucontrol"]
    readonly property var cmdNetworkManager: ["kitty", "--single-instance", "-e", "nmtui"]
    readonly property var cmdBluetoothManager: ["blueman-manager"]
    readonly property var cmdLock: ["quickshell", "ipc", "call", "lockscreen", "lock"]
    readonly property var cmdSleep: ["systemctl", "suspend"]
    readonly property var cmdReboot: ["systemctl", "reboot"]
    readonly property var cmdPoweroff: ["systemctl", "poweroff"]
    // Prefixes used by the launcher, so the terminal can be swapped.
    readonly property var cmdTerminal: ["kitty", "-e"]
    readonly property var cmdClipboard: ["wl-copy"]
}
