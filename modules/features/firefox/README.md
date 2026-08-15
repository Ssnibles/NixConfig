# Firefox & Sidebery Customization Guide

This guide explains how Firefox UI customization works in this repository, how to inspect elements, and where to find CSS selectors and community resources for styling both Firefox itself (`userChrome.css`) and WebExtensions like Sidebery (`userContent.css`).

---

## 📁 Architecture Overview

| File | Scope | What it Styles |
| :--- | :--- | :--- |
| **`userChrome.css`** | **Firefox Native UI** | Main toolbar, URL bar, sidebars, context menus, navbar buttons, window frame. |
| **`userContent.css`** | **Web Content & Extensions** | Extension sidebars (e.g. Sidebery), `about:config`, `about:blank`, `about:newtab`. |
| **`colors.css`** | **Theme System** | Dynamic CSS variables generated from your system color palette (`--fx-bg`, `--fx-accent`, etc.). |

> [!NOTE]
> Both `userChrome.css` and `userContent.css` are symlinked directly from your `NixConfig` workspace (`~/NixConfig/modules/features/firefox/`) into your Firefox profile directory (`~/.mozilla/firefox/default/chrome/`). Any changes saved here take effect immediately upon restarting Firefox or reloading the sidebar/page!

---

## 🛠️ How to Discover CSS Selectors

### 1. Styling Firefox Native UI (`userChrome.css`)
To inspect any element in Firefox's UI (URL bar, tabs, sidebars, buttons, menus):

1. **Enable Developer Tools for Chrome**:
   - Open `about:config` in Firefox.
   - Set `toolkit.legacyUserProfileCustomizations.stylesheets` = `true`
   - Set `devtools.chrome.enabled` = `true`
   - Set `devtools.debugger.remote-enabled` = `true`
2. **Launch the Browser Toolbox**:
   - Press **`Ctrl` + `Shift` + `Alt` + `I`** (or go to `Menu` → `More Tools` → `Browser Tools` → `Browser Toolbox`).
   - Click **OK** on the remote debugging prompt.
3. **Inspect Elements**:
   - Click the **Element Picker** icon (`Ctrl` + `Shift` + `C`) in the Browser Toolbox.
   - Click on any part of Firefox's user interface to view its exact HTML structure, ID, class names, and active CSS rules.

### 2. Styling WebExtensions & Sidebery (`userContent.css`)
WebExtensions like Sidebery run inside extension frames (`moz-extension://`).

#### Method A: Firefox Extension Debugger (Live Inspection)
1. Open `about:debugging` in Firefox.
2. Click **This Firefox** on the left panel.
3. Find **Sidebery** under *Extensions* and click **Inspect**.
4. A dedicated DevTools window will open for Sidebery.
5. Use `Ctrl` + `Shift` + `C` to click on any element in Sidebery (e.g. `.PinnedTabsBar`, `.Tab`, `.NavigationBar`) to inspect its live styles.

#### Method B: Extracting Extension Stylesheet
You can inspect Sidebery's built-in CSS stylesheet directly from its package bundle:
```bash
# Search Sidebery classes in terminal
unzip -p ~/.mozilla/firefox/*/extensions/\{3c078156-979c-498b-8990-85f7987dd929\}.xpi styles/sidebar.css | grep -o -E '\.[a-zA-Z0-9_-]+' | sort -u
```

---

## 📚 Essential Resources & Community Libraries

### 🦊 Firefox Customization & `userChrome.css`
- **[r/FirefoxCSS Subreddit](https://www.reddit.com/r/FirefoxCSS/)**: The official community for Firefox CSS tweaks, snippets, and troubleshooting.
- **[MrOtherGuy/firefox-csshacks](https://github.com/MrOtherGuy/firefox-csshacks)**: A comprehensive repository of modular `userChrome.css` and `userContent.css` tweaks.
- **[Firefox CSS Store](https://firefoxcss-store.github.io/)**: Showcase of custom themes for Firefox.
- **[Firefox Source Docs (Gecko UI)](https://firefox-source-docs.mozilla.org/)**: Mozilla's internal documentation for browser structure.

### 📑 Sidebery & WebExtensions
- **[Sidebery GitHub Repository](https://github.com/mbnuoshi/sidebery)**: Official source code, issue tracker, and release notes.
- **[Sidebery Wiki & Custom CSS Guide](https://github.com/mbnuoshi/sidebery/wiki)**: Documentation on Sidebery's CSS structure and native variables (`--tabs-*`, `--nav-*`).

---

## 💡 Quick Tips for Writing Custom CSS

1. **Use `@-moz-document` for Scope**:
   - Scope WebExtension styles inside `userContent.css` using:
     ```css
     @-moz-document url-prefix("moz-extension://") {
       /* WebExtension styles here */
     }
     ```
2. **Use `!important` Overrides**:
   - Firefox internal stylesheets have high specificity; add `!important` to your rules to ensure they override browser defaults.
3. **Use Dynamic Color Variables**:
   - Leverage `var(--fx-bg)`, `var(--fx-bg-raised)`, `var(--fx-accent)`, etc. defined in `colors.css` so your Firefox UI seamlessly matches your system's color scheme.
