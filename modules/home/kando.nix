# =============================================================================
# Kando Pie Menu – Stylix Theme & Configuration
# =============================================================================
# Deploys a custom "stylix" menu theme for Kando and generates config.json
# with theme colors sourced from the current Stylix base16 scheme.
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:
let
  s = config.lib.stylix.colors;
  c = import ../../lib/stylix/semantic-colors.nix { stylixColors = s; };
  themeDir = "kando/menu-themes/stylix";

  themeColors = {
    "background-color" = "#${c.bg}";
    "surface-color" = "#${c.bgRaised}";
    "text-color" = "#${c.fg}";
    "border-color" = "#${c.border}";
    "hover-color" = "#${c.accent}";
    "accent-color" = "#${c.accent}";
  };

  configJson = builtins.toJSON {
    version = "2.1.0";
    menuTheme = "stylix";
    menuThemeColors = {
      stylix = themeColors;
    };
  };
in
{
  xdg.configFile = {
    "${themeDir}/theme.json" = {
      force = true;
      text = ''
        {
          "name": "Stylix",
          "author": "Josh",
          "license": "CC0-1.0",
          "themeVersion": "1.0",
          "engineVersion": 1,
          "maxMenuRadius": 160,
          "centerTextWrapWidth": 95,
          "drawChildrenBelow": true,
          "drawCenterText": true,
          "drawSelectionWedges": false,
          "drawWedgeSeparators": false,
          "colors": {
            "background-color": "#141415",
            "surface-color": "#1c1c24",
            "text-color": "#cdcdcd",
            "border-color": "#252530",
            "hover-color": "#6e94b2",
            "accent-color": "#6e94b2"
          },
          "layers": [
            { "class": "icon-layer", "content": "icon" }
          ]
        }
      '';
    };

    "${themeDir}/theme.css" = {
      force = true;
      text = ''
        .menu-node {
          --child-distance: 105px;
          --grandchild-distance: 28px;

          --center-size: 100px;
          --child-size: 54px;
          --grandchild-size: 16px;
          --connector-width: 10px;

          --menu-transition: all 220ms cubic-bezier(0.775, 1.325, 0.535, 1);
          --opacity-transition: opacity 220ms ease;

          transition: var(--menu-transition);

          /* Positioning ---------------------------------------------------------------- */

          &.child {
            transform: translate(
              calc(max(var(--child-distance), 10px * var(--sibling-count)) * var(--dir-x)),
              calc(max(var(--child-distance), 10px * var(--sibling-count)) * var(--dir-y))
            );
          }

          &.grandchild {
            transform: translate(
              calc(var(--grandchild-distance) * var(--dir-x)),
              calc(var(--grandchild-distance) * var(--dir-y))
            );
          }

          &.active:has(.hovered) > .child {
            transform: scale(
              calc(1.12 - pow(var(--angle-diff) / 180, 0.25) * 0.12)
            ) translate(
              calc(max(var(--child-distance), 10px * var(--sibling-count)) * var(--dir-x)),
              calc(max(var(--child-distance), 10px * var(--sibling-count)) * var(--dir-y))
            );

            &.hovered {
              transform: scale(1.12) translate(
                calc(max(var(--child-distance), 10px * var(--sibling-count)) * var(--dir-x)),
                calc(max(var(--child-distance), 10px * var(--sibling-count)) * var(--dir-y))
              );
            }
          }

          /* Icon container ----------------------------------------------------------- */

          .icon-container {
            opacity: 0;
            color: var(--text-color);
            transition: var(--opacity-transition);
            margin: 12%;
            width: 76% !important;
            height: 76% !important;
            border-radius: 50%;
            overflow: hidden;
          }

          .icon-layer {
            position: absolute;
            border-radius: 50%;
            border: 1px solid var(--border-color);
            transition: var(--menu-transition);
          }

          /* Center ----------------------------------------------------------------- */

          &.active > .icon-layer {
            top: calc(-1 * var(--center-size) / 2);
            left: calc(-1 * var(--center-size) / 2);
            width: var(--center-size);
            height: var(--center-size);
            background-color: var(--surface-color);
            box-shadow: 2px 2px 12px rgba(0, 0, 0, 0.5);
          }

          &.active:has(>.hovered) > .icon-layer {
            transform: scale(1.08);

            & > .icon-container {
              opacity: 0;
            }
          }

          &.active.hovered > .icon-layer {
            background-color: var(--hover-color);
          }

          &.active.hovered > .icon-layer > .icon-container {
            color: #ffffff;
          }

          /* Parent & child --------------------------------------------------------- */

          &.parent.hovered.clicked > .icon-layer,
          &.child.hovered.clicked > .icon-layer {
            transform: scale(0.92);
          }

          &.active.hovered.clicked > .icon-layer {
            transform: scale(0.92);
          }

          &.parent > .icon-layer > .icon-container,
          &.child > .icon-layer > .icon-container,
          &.active > .icon-layer > .icon-container {
            opacity: 1;
          }

          &.parent > .icon-layer,
          &.child > .icon-layer {
            top: calc(-1 * var(--child-size) / 2);
            left: calc(-1 * var(--child-size) / 2);
            width: var(--child-size);
            height: var(--child-size);
            background-color: var(--surface-color);
            box-shadow: 2px 2px 8px rgba(0, 0, 0, 0.4);
          }

          &.parent.hovered > .icon-layer,
          &.child.hovered > .icon-layer {
            background-color: var(--hover-color);
            border-color: var(--accent-color);
          }

          &.parent.hovered > .icon-layer > .icon-container,
          &.child.hovered > .icon-layer > .icon-container {
            color: #ffffff;
          }

          /* Grandchild ------------------------------------------------------------- */

          &.grandchild > .icon-layer {
            top: calc(-1 * var(--grandchild-size) / 2);
            left: calc(-1 * var(--grandchild-size) / 2);
            width: var(--grandchild-size);
            height: var(--grandchild-size);
            background-color: var(--border-color);
          }

          &.dragged {
            transition: none;
          }

          /* Connectors ------------------------------------------------------------- */

          .connector {
            transition: var(--menu-transition);
            height: var(--connector-width);
            background-color: var(--border-color);
            top: calc(-1 * var(--connector-width) / 2);
          }

          &:has(.dragged) > .connector,
          &:has(.clicked) > .connector {
            transition: none;
          }

          &.hovered > .connector {
            background-color: color-mix(in srgb, var(--hover-color) 50%, var(--border-color));
          }

          &.active > .connector {
            background-color: var(--hover-color);
          }
        }

        /* Center Text ---------------------------------------------------------------- */

        .center-text {
          color: var(--text-color);
          transition: var(--opacity-transition);
          font-size: 15px;
          line-height: 21px;
        }
      '';
    };

    "${themeDir}/preview.jpg" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/NixConfig/wallpapers/kalen-emsley-Bkci_8qcdvQ-unsplash.jpg";
    };

    "kando/config.json" = {
      text = configJson;
      force = true;
    };
  };
}
