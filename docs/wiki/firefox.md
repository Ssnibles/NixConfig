# Firefox & Sidebery Customisation Guide

This guide explains how Firefox Developer Edition UI customisation works in NixConfig, how CSS stylesheets are linked, and how to inspect elements for styling both Firefox (`userChrome.css`) and WebExtensions like Sidebery (`userContent.css`).

---

## Architecture Overview

| File | Scope | Target Elements |
| :--- | :--- | :--- |
| **`userChrome.css`** | **Firefox Native UI** | Toolbar, URL bar, sidebars, context menus, navbar buttons, window frame. |
| **`userContent.css`** | **Web Content & Extensions** | Extension sidebars (e.g. Sidebery), `about:config`, `about:blank`, `about:newtab`. |
| **`colours.css`** | **Theme System** | Dynamic CSS variables generated from your system colour palette (`--fx-bg`, `--fx-accent`, etc.). |
| **`startpage/`** | **Offline New Tab Extension** | Local embedded offline startpage WebExtension loaded into Firefox. |

> [!NOTE]
> `userChrome.css`, `userContent.css`, `tridactylrc`, and `startpage/` are linked into your Firefox profile directory (`~/.mozilla/firefox/dev-edition-default/`) via `nixos.liveLinks`. The startpage uses `contents = true` to symlink individual files into place while letting Hjem declaratively manage generated `colours.css` files, ensuring that live editing is supported without mutating tracked files in your Git workspace. Changes take effect immediately upon restarting Firefox or refreshing the startpage.

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

In addition to Firefox Developer Edition, NixConfig packages the Chromium-based **Helium Browser** via `modules/features/apps/helium/default.nix`. It deliberately mirrors the Firefox module's behaviour and theming wherever Chromium allows:

- Packaged from `inputs.helium`.
- Declarative Chrome Enterprise policies written to `/etc/chromium/policies/managed/helium-nixos.json`.
- Wayland ozone acceleration injected by the upstream wrapper (`NIXOS_OZONE_WL`), plus GPU/VA-API feature flags and overlay scrollbars.
- **Search**: default engine forced to SearXNG (`search.ssnibles.xyz`), search suggestions disabled.
- **Privacy/security**: telemetry, studies, Safe Browsing remote checks, Privacy Sandbox, third-party cookies and background networking disabled; HTTPS-only forced; password manager/autofill off (Bitwarden).
- **Startup**: restore last session, no default-browser prompt, permissions default-deny.
- **Extensions**: `uBlock Origin`, `Bitwarden`, `Dark Reader` and `SponsorBlock` force-installed from the Chrome Web Store via the `ExtensionSettings` policy.
- **Theming**: a Chromium theme extension is generated from the active palette and loaded with `--load-extension`, so chrome colours (`frame`, `toolbar`, `omnibox`, tab text) are applied literally and bypass Material You. `OverlayScrollbar` gives thin overlay scrollbars.
- **Custom startpage**: a themed local startpage (shared with Firefox's palette via `--fx-*` variables) is materialised at `~/.config/helium/startpage` and used for the new-tab page (via the ungoogled `--custom-ntp` switch) and home button. The hand-written page files live in `modules/features/apps/helium/startpage/` and are symlinked into place for live editing; `colours.css` is generated from `config.theme.colours` by Hjem.
- Integrated into `modules/features/desktop-env/default-apps.nix` as a selectable default browser.

> [!NOTE]
> Chromium has no `userChrome.css`/`userContent.css` equivalent, so arbitrary CSS on the browser *chrome* is impossible. The palette is applied through a generated theme extension loaded with `--load-extension` (theme-extension colours are applied literally, unlike the `BrowserThemeColor` policy which runs the seed through Material You) and through the custom startpage. Helium reads local (including `file://`) new-tab URLs only through the ungoogled `--custom-ntp` switch — the `NewTabPageLocation` policy silently ignores them.
