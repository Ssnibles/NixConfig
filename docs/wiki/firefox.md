# Firefox & Sidebery Customisation Guide

This guide explains how Firefox Developer Edition UI customisation works in NixConfig, how CSS stylesheets are linked, and how to inspect elements for styling both Firefox (`userChrome.css`) and WebExtensions like Sidebery (`userContent.css`).

---

## Architecture Overview

| File | Scope | Target Elements |
| :--- | :--- | :--- |
| **`userChrome.css`** | **Firefox Native UI** | Toolbar, URL bar, sidebars, context menus, navbar buttons, window frame. |
| **`userContent.css`** | **Web Content & Extensions** | Extension sidebars (e.g. Sidebery), `about:config`, `about:blank`, `about:newtab`. |
| **`colors.css`** | **Theme System** | Dynamic CSS variables generated from your system colour palette (`--fx-bg`, `--fx-accent`, etc.). |
| **`startpage/`** | **Offline New Tab Extension** | Local embedded offline startpage WebExtension loaded into Firefox. |

> [!NOTE]
> Both `userChrome.css` and `userContent.css` are symlinked directly from your NixConfig workspace (`~/NixConfig/modules/features/apps/firefox/`) into your Firefox profile directory (`~/.mozilla/firefox/default/chrome/`). Any changes saved take effect immediately upon restarting Firefox.

---

## Inspecting UI Elements with Browser Toolbox

To discover CSS selectors for Firefox UI components:

1. **Enable Developer Tools for Chrome**:
   - Open `about:config` in Firefox.
   - Set `toolkit.legacyUserProfileCustomizations.stylesheets` = `true`
   - Set `devtools.chrome.enabled` = `true`
   - Set `devtools.debugger.remote-enabled` = `true`
2. **Launch the Browser Toolbox**:
   - Press **`Ctrl` + `Shift` + `Alt` + `I`**.
   - Click **OK** on the remote debugging prompt.
3. **Inspect Elements**:
   - Use the **Element Picker** icon (`Ctrl` + `Shift` + `C`) to click any part of Firefox's user interface to view its HTML structure and CSS rules.

---

## Styling Sidebery (`userContent.css`)

Sidebery runs inside an extension frame (`moz-extension://`). Scope rules inside `userContent.css`:

```css
@-moz-document url-prefix("moz-extension://") {
  /* Sidebery custom styles */
  .Tab {
    border-radius: 6px !important;
  }
}
```

---

## Helium Browser Alternative

In addition to Firefox Developer Edition, NixConfig packages the Chromium-based **Helium Browser** via `modules/features/apps/helium.nix`:
- Packaged from `inputs.helium`.
- Declarative Chrome Enterprise policies written to `/etc/chromium/policies/managed/helium-nixos.json`.
- Configured with Wayland ozone flags (`--ozone-platform-hint=auto`).
- Integrated into `modules/features/desktop-env/default-apps.nix` as a selectable default browser.
