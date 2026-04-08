# =============================================================================
# SwayNC Configuration
# =============================================================================
# Notification daemon and control centre for Hyprland.
# =============================================================================
{ ... }:
{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      control-center-margin-top = 28;
      control-center-margin-bottom = 28;
      control-center-margin-right = 28;
      control-center-margin-left = 0;
      control-center-width = 380;
      control-center-height = 600;
      notification-window-width = 380;
      notification-icon-size = 40;
      notification-body-image-width = 200;
      notification-body-image-height = 100;
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0;
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      cssPriority = "application";
      keyboard-shortcuts = true;
      widgets = [
        "title"
        "dnd"
        "mpris"
        "notifications"
      ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear";
        };
        dnd.text = "Do Not Disturb";
        mpris = {
          image-size = 56;
          image-radius = 8;
        };
        notifications = {
          vexpand = true;
          max-notifications = 0;
        };
      };
    };

    style = ''
      /* =================================================================== */
      /* SwayNC Vague Theme                                                  */
      /* Notification daemon and control center                              */
      /* Matches waybar and neovim color palette                            */
      /* =================================================================== */

      @define-color bg          #141415;
      @define-color bg-raised   #1c1c24;
      @define-color bg-subtle   #252530;
      @define-color border      #252530;
      @define-color fg          #cdcdcd;
      @define-color fg-dim      #606079;
      @define-color fg-mid      #878787;
      @define-color accent      #6e94b2;
      @define-color teal        #b4d4cf;
      @define-color purple      #bb9dbd;
      @define-color green       #7fa563;
      @define-color yellow      #f3be7c;
      @define-color red         #d8647e;
      @define-color orange      #e8b589;

      /* ── Base ──────────────────────────────────────────────────────── */
      * {
        all: unset;
        font-family: "JetBrains Mono", monospace;
        font-size: 13px;
        font-weight: 400;
      }

      /* ── Windows ───────────────────────────────────────────────────── */
      .blank-window,
      .notification-window {
        background: transparent;
      }

      /* ── Control Center ────────────────────────────────────────────── */
      .control-center {
        background: @bg;
        border: 1px solid @border;
        border-radius: 8px;
        padding: 12px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.4);
      }

      /* ── Notification Containers ───────────────────────────────────── */
      .notification-background {
        background: transparent;
        border-radius: 8px;
        margin: 6px 0;
        padding: 0;
      }

      .notification-window .notification-background {
        margin: 8px;
      }

      /* ── Individual Notifications ──────────────────────────────────── */
      .notification {
        background: @bg-raised;
        border: 1px solid @border;
        border-radius: 8px;
        padding: 14px;
        margin: 0;
        transition: all 200ms cubic-bezier(0.4, 0, 0.2, 1);
      }

      .notification:hover {
        background: #21212e;
        border-color: @bg-subtle;
      }

      .notification-window .notification {
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
      }

      /* Notification priority styling */
      .notification.low {
        opacity: 0.75;
      }

      .notification.low .summary {
        color: @fg-mid;
      }

      .notification.low .body {
        color: @fg-dim;
      }

      .notification.critical {
        border-color: @red;
        background: @bg-raised;
      }

      .notification.critical .summary {
        color: @red;
        font-weight: 600;
      }

      .notification.critical .app-name {
        color: @red;
        opacity: 0.8;
      }

      .notification.critical progressbar progress {
        background: @red;
      }

      .notification.critical .notification-action:first-child {
        color: @red;
        border-color: @red;
      }

      /* ── Notification Content ──────────────────────────────────────── */
      .notification-content {
        padding: 0;
      }

      .app-name {
        font-size: 11px;
        color: @accent;
        margin-bottom: 4px;
        opacity: 0.9;
      }

      .summary {
        font-weight: 600;
        color: @fg;
        font-size: 13px;
        margin-bottom: 2px;
      }

      .time {
        font-size: 11px;
        color: @fg-dim;
      }

      .body {
        font-size: 12px;
        color: @fg-mid;
        margin-top: 4px;
        line-height: 1.4;
      }

      /* ── Icons ─────────────────────────────────────────────────────── */
      .notification-default-icon,
      .notification-icon {
        border-radius: 6px;
        min-width: 40px;
        min-height: 40px;
        margin-right: 12px;
      }

      /* ── Progress Bars ─────────────────────────────────────────────── */
      .notification progressbar {
        margin-top: 8px;
      }

      .notification progressbar trough {
        background: @bg-subtle;
        border-radius: 4px;
        min-height: 4px;
        border: none;
      }

      .notification progressbar progress {
        background: @accent;
        border-radius: 4px;
        min-height: 4px;
        border: none;
      }

      /* ── Action Buttons ────────────────────────────────────────────── */
      .notification-action {
        background: transparent;
        border: 1px solid @border;
        border-radius: 6px;
        color: @fg-mid;
        padding: 6px 12px;
        margin: 6px 6px 0 0;
        font-size: 11px;
        transition: all 200ms ease;
      }

      .notification-action:hover {
        background: @bg-subtle;
        color: @fg;
        border-color: @bg-subtle;
      }

      .notification-action:first-child {
        color: @accent;
        border-color: @accent;
      }

      .notification-action:first-child:hover {
        background: @bg-subtle;
        color: @teal;
        border-color: @teal;
      }

      /* ── Close Button ──────────────────────────────────────────────── */
      .close-button {
        background: transparent;
        border: none;
        border-radius: 4px;
        color: @fg-dim;
        padding: 4px 8px;
        font-size: 14px;
        min-width: 0;
        transition: all 200ms ease;
      }

      .close-button:hover {
        background: @bg-subtle;
        color: @red;
      }

      /* ── Notification Groups ───────────────────────────────────────── */
      .notification-group {
        margin: 6px 0;
        padding: 0;
      }

      .notification-group-headers {
        color: @accent;
        font-size: 11px;
        font-weight: 600;
      }

      .notification-group-icon {
        color: @accent;
      }

      .notification-group-collapse-button,
      .notification-group-expand-button {
        background: transparent;
        border: 1px solid @border;
        border-radius: 6px;
        color: @fg-dim;
        padding: 4px 10px;
        font-size: 11px;
        margin: 6px 0 4px 0;
        transition: all 200ms ease;
      }

      .notification-group-collapse-button:hover,
      .notification-group-expand-button:hover {
        background: @bg-subtle;
        color: @fg;
      }

      /* ── Widget: Title ─────────────────────────────────────────────── */
      .widget-title {
        padding: 8px 8px 12px 8px;
        border-bottom: 1px solid @border;
        margin-bottom: 12px;
      }

      .widget-title > label {
        font-weight: 600;
        font-size: 14px;
        color: @fg;
        letter-spacing: 0.5px;
      }

      .widget-title > button {
        background: transparent;
        border: 1px solid @border;
        border-radius: 6px;
        color: @fg-dim;
        padding: 4px 12px;
        font-size: 11px;
        transition: all 200ms ease;
      }

      .widget-title > button:hover {
        background: @bg-subtle;
        color: @fg;
        border-color: @bg-subtle;
      }

      /* ── Widget: Do Not Disturb ────────────────────────────────────── */
      .widget-dnd {
        padding: 8px 8px;
        border-bottom: 1px solid @border;
        margin-bottom: 12px;
      }

      .widget-dnd > label {
        color: @fg-mid;
        font-size: 12px;
      }

      .widget-dnd > switch {
        background: @bg-subtle;
        border: 1px solid @border;
        border-radius: 12px;
        min-width: 40px;
        min-height: 20px;
        transition: all 200ms ease;
      }

      .widget-dnd > switch:checked {
        background: @accent;
        border-color: @accent;
      }

      .widget-dnd > switch slider {
        background: @fg;
        border-radius: 10px;
        min-width: 16px;
        min-height: 16px;
        margin: 2px;
        transition: all 200ms cubic-bezier(0.4, 0, 0.2, 1);
      }

      /* ── Widget: MPRIS ─────────────────────────────────────────────── */
      .widget-mpris {
        background: @bg-raised;
        border: 1px solid @border;
        border-radius: 8px;
        padding: 12px;
        margin-bottom: 12px;
        transition: all 200ms ease;
      }

      .widget-mpris:hover {
        background: #21212e;
      }

      .widget-mpris-player {
        padding: 0;
      }

      .widget-mpris-title {
        font-weight: 600;
        font-size: 13px;
        color: @fg;
        margin-bottom: 2px;
      }

      .widget-mpris-subtitle {
        font-size: 11px;
        color: @purple;
        font-style: italic;
      }

      .widget-mpris-player > box > button {
        background: transparent;
        border: none;
        border-radius: 4px;
        color: @fg-dim;
        padding: 6px 10px;
        transition: all 200ms ease;
      }

      .widget-mpris-player > box > button:hover {
        background: @bg-subtle;
        color: @fg;
      }

      /* ── Scrollbar ─────────────────────────────────────────────────── */
      scrollbar {
        background: transparent;
        width: 8px;
      }

      scrollbar slider {
        background: @bg-subtle;
        border-radius: 4px;
        min-height: 40px;
      }

      scrollbar slider:hover {
        background: @border;
      }
    '';
  };
}
