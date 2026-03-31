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
      * {
        font-family: "JetBrains Mono", monospace;
        font-size: 13px; font-weight: 400;
        border: none; border-radius: 0;
        padding: 0; margin: 0;
        box-shadow: none; text-shadow: none;
        -gtk-icon-shadow: none; outline: none;
      }
      .blank-window, .notification-window { background: transparent; }
      .control-center {
        background: #141415; border: 1px solid #252530;
        border-radius: 8px; padding: 8px;
      }
      .notification-background {
        background: transparent; border-radius: 8px; margin: 4px 0; padding: 0;
      }
      .notification-window .notification-background { margin: 4px; }
      .notification {
        background: #1c1c24; border: 1px solid #252530;
        border-radius: 8px; padding: 12px; margin: 0;
      }
      .notification:hover { background: #21212e; }
      .notification-window .notification { box-shadow: 0 2px 8px rgba(0,0,0,0.5); }
      .notification.low          { opacity: 0.75; }
      .notification.low .summary { color: #878787; }
      .notification.low .body    { color: #606079; }
      .notification.critical              { border-color: #d8647e; }
      .notification.critical .summary     { color: #d8647e; }
      .notification.critical .app-name    { color: #d8647e; opacity: 0.8; }
      .notification.critical progressbar progress { background: #d8647e; }
      .notification.critical .notification-action:first-child {
        color: #d8647e; border-color: #d8647e;
      }
      .notification-content { padding: 0; }
      .app-name { font-size: 11px; color: #6e94b2; margin-bottom: 2px; }
      .summary  { font-weight: 600; color: #cdcdcd; font-size: 13px; }
      .time     { font-size: 11px; color: #606079; }
      .body     { font-size: 12px; color: #878787; margin-top: 3px; }
      .notification-default-icon, .notification-icon {
        border-radius: 6px; min-width: 40px; min-height: 40px;
      }
      .notification progressbar        { margin-top: 6px; }
      .notification progressbar trough {
        background: #252530; border-radius: 4px; min-height: 4px; border: none;
      }
      .notification progressbar progress {
        background: #6e94b2; border-radius: 4px; min-height: 4px; border: none;
      }
      .notification-action {
        background: transparent; border: 1px solid #252530; border-radius: 6px;
        color: #878787; padding: 4px 10px; margin: 4px 4px 0 0; font-size: 11px;
      }
      .notification-action:hover { background: #21212e; color: #cdcdcd; }
      .notification-action:first-child { color: #6e94b2; border-color: #6e94b2; }
      .notification-action:first-child:hover { background: #21212e; color: #b4d4cf; }
      .close-button {
        background: transparent; border: none; border-radius: 4px;
        color: #606079; padding: 2px 6px; font-size: 12px; min-width: 0;
      }
      .close-button:hover { background: #1c1c24; color: #d8647e; }
      .notification-group { margin: 4px 0; padding: 0; }
      .notification-group-headers { color: #6e94b2; font-size: 11px; }
      .notification-group-icon    { color: #6e94b2; }
      .notification-group-collapse-button,
      .notification-group-expand-button {
        background: transparent; border: 1px solid #252530; border-radius: 6px;
        color: #606079; padding: 2px 8px; font-size: 11px; margin: 4px 0 2px 0;
      }
      .notification-group-collapse-button:hover,
      .notification-group-expand-button:hover { background: #1c1c24; color: #cdcdcd; }
      .widget-title {
        padding: 4px 4px 8px 4px; border-bottom: 1px solid #252530; margin-bottom: 8px;
      }
      .widget-title > label  { font-weight: 600; font-size: 13px; color: #cdcdcd; }
      .widget-title > button {
        background: transparent; border: 1px solid #252530; border-radius: 6px;
        color: #606079; padding: 2px 10px; font-size: 11px;
      }
      .widget-title > button:hover { background: #1c1c24; color: #cdcdcd; }
      .widget-dnd {
        padding: 6px 4px; border-bottom: 1px solid #252530; margin-bottom: 8px;
      }
      .widget-dnd > label  { color: #878787; font-size: 12px; }
      .widget-dnd > switch {
        background: #1c1c24; border: 1px solid #252530; border-radius: 12px;
        min-width: 40px; min-height: 20px;
      }
      .widget-dnd > switch:checked { background: #6e94b2; border-color: #6e94b2; }
      .widget-dnd > switch slider {
        background: #cdcdcd; border-radius: 10px;
        min-width: 16px; min-height: 16px; margin: 2px;
      }
      .widget-mpris {
        background: #1c1c24; border: 1px solid #252530; border-radius: 8px;
        padding: 10px; margin-bottom: 8px;
      }
      .widget-mpris-player   { padding: 0; }
      .widget-mpris-title    { font-weight: 600; font-size: 13px; color: #cdcdcd; }
      .widget-mpris-subtitle { font-size: 11px; color: #bb9dbd; font-style: italic; }
      .widget-mpris-player > box > button {
        background: transparent; border: none; border-radius: 4px;
        color: #606079; padding: 4px 8px;
      }
      .widget-mpris-player > box > button:hover { background: #252530; color: #cdcdcd; }
    '';
  };
}
