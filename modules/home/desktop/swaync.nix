# =============================================================================
# SwayNC Configuration
# =============================================================================
# Notification daemon and control centre for Hyprland.
# Reworked to match Vicinae's raised-surface aesthetic and cleaner spacing.
# =============================================================================
{ colors, ... }:
let
  c = colors.vague.withHash;
  panelWidth = 392;
  panelHeight = 640;
  panelMargin = 24;
in
{
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";

      control-center-margin-top = panelMargin;
      control-center-margin-bottom = panelMargin;
      control-center-margin-right = panelMargin;
      control-center-margin-left = 0;
      control-center-width = panelWidth;
      control-center-height = panelHeight;

      notification-window-width = panelWidth;
      notification-icon-size = 38;
      notification-body-image-width = 220;
      notification-body-image-height = 120;

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
      /* Synced with Vicinae: raised surfaces and balanced spacing           */
      /* =================================================================== */

      @define-color bg          ${c.bg};
      @define-color bg-raised   ${c.raisedBackground}; /* Vicinae secondary_background */
      @define-color bg-subtle   ${c.bgSubtle};
      @define-color border      ${c.border};
      @define-color fg          ${c.fg};
      @define-color fg-mid      ${c.fgMid};
      @define-color fg-dim      ${c.fgDim};
      @define-color accent      ${c.accent};
      @define-color teal        ${c.teal};
      @define-color purple      ${c.purple};
      @define-color green       ${c.green};
      @define-color yellow      ${c.yellow};
      @define-color red         ${c.red};
      @define-color orange      ${c.orange};

      * {
        all: unset;
        font-family: "JetBrains Mono", monospace;
        font-size: 12px;
        color: @fg;
      }

      .blank-window,
      .notification-window {
        background: transparent;
      }

      .control-center {
        background: @bg-raised;
        border: 1px solid @border;
        border-radius: 8px;
        padding: 14px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.45);
      }

      .notification-window .notification-background {
        background: transparent;
        margin: 10px 10px 0 10px;
      }

      .notification-window .notification-background:last-child {
        margin-bottom: 10px;
      }

      .notification {
        background: @bg-raised;
        border: 1px solid @border;
        border-radius: 8px;
        padding: 12px;
        margin: 0;
        transition: all 200ms cubic-bezier(0.4, 0, 0.2, 1);
      }

      .notification:hover {
        background: @bg-subtle;
        border-color: @accent;
      }

      .notification.critical {
        border-color: @red;
      }

      .notification.critical .summary,
      .notification.critical .app-name {
        color: @red;
      }

      .notification.critical progressbar progress {
        background: @red;
      }

      .notification.low {
        opacity: 0.78;
      }

      .notification-content {
        padding: 0;
      }

      .app-name {
        color: @accent;
        font-size: 11px;
        margin-bottom: 4px;
      }

      .summary {
        color: @fg;
        font-size: 13px;
        font-weight: 600;
        margin-bottom: 4px;
      }

      .time {
        color: @fg-dim;
        font-size: 11px;
      }

      .body {
        color: @fg-mid;
        font-size: 12px;
        line-height: 1.35;
        margin-top: 6px;
      }

      .notification-default-icon,
      .notification-icon {
        border-radius: 6px;
        min-width: 38px;
        min-height: 38px;
        margin-right: 10px;
      }

      .notification progressbar {
        margin-top: 10px;
      }

      .notification progressbar trough {
        background: @bg-subtle;
        border-radius: 4px;
        min-height: 4px;
      }

      .notification progressbar progress {
        background: @accent;
        border-radius: 4px;
        min-height: 4px;
      }

      .notification-action {
        background: transparent;
        color: @fg-mid;
        border: 1px solid @border;
        border-radius: 6px;
        font-size: 11px;
        padding: 6px 10px;
        margin: 8px 8px 0 0;
        transition: all 200ms ease;
      }

      .notification-action:hover {
        background: @bg-subtle;
        color: @fg;
      }

      .notification-action:first-child {
        color: @accent;
        border-color: @accent;
      }

      .notification-action:first-child:hover {
        color: @teal;
        border-color: @teal;
      }

      .close-button {
        background: transparent;
        color: @fg-dim;
        border: none;
        border-radius: 4px;
        padding: 4px 6px;
        min-width: 0;
      }

      .close-button:hover {
        background: @bg-subtle;
        color: @red;
      }

      .notification-group {
        margin: 0 0 10px 0;
      }

      .notification-group:last-child {
        margin-bottom: 0;
      }

      .notification-group-headers,
      .notification-group-icon {
        color: @accent;
        font-size: 11px;
        font-weight: 600;
      }

      .notification-group-collapse-button,
      .notification-group-expand-button {
        background: transparent;
        color: @fg-dim;
        border: 1px solid @border;
        border-radius: 6px;
        font-size: 11px;
        padding: 4px 8px;
        margin-top: 8px;
      }

      .notification-group-collapse-button:hover,
      .notification-group-expand-button:hover {
        background: @bg-subtle;
        color: @fg;
      }

      .widget-title {
        padding: 0 0 12px 0;
        margin: 0 0 12px 0;
        border-bottom: 1px solid @border;
      }

      .widget-title > label {
        color: @fg;
        font-size: 14px;
        font-weight: 600;
      }

      .widget-title > button {
        background: transparent;
        color: @fg-dim;
        border: 1px solid @border;
        border-radius: 6px;
        font-size: 11px;
        padding: 4px 10px;
      }

      .widget-title > button:hover {
        background: @bg-subtle;
        color: @fg;
      }

      .widget-dnd {
        padding: 0 0 12px 0;
        margin: 0 0 12px 0;
        border-bottom: 1px solid @border;
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
      }

      .widget-mpris {
        background: @bg-raised;
        border: 1px solid @border;
        border-radius: 8px;
        padding: 12px;
        margin: 0 0 12px 0;
      }

      .widget-mpris:last-child {
        margin-bottom: 0;
      }

      .widget-mpris:hover {
        background: @bg-subtle;
      }

      .widget-mpris-title {
        color: @fg;
        font-size: 13px;
        font-weight: 600;
      }

      .widget-mpris-subtitle {
        color: @purple;
        font-size: 11px;
        margin-top: 2px;
      }

      .widget-mpris-player > box > button {
        background: transparent;
        color: @fg-dim;
        border: none;
        border-radius: 4px;
        padding: 6px 8px;
      }

      .widget-mpris-player > box > button:hover {
        background: @bg-subtle;
        color: @fg;
      }

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
