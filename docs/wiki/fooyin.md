# Fooyin Player & Theming Guide

This guide documents the fooyin music player module, its palette-driven theme, the `Minimal` layout, and the runtime state that fooyin keeps outside the Nix store.

---

## Module

The player is configured in [`modules/features/apps/fooyin.nix`](../../modules/features/apps/fooyin.nix) and is enabled by default through `features.fooyin.enable`.

The module:

- installs `pkgs.fooyin`;
- generates `~/.config/fooyin/fooyin.conf`;
- installs the `Minimal` layout at `~/.config/fooyin/layouts/Minimal.fyl`;
- maps the active desktop palette onto fooyin's Qt palette;
- enables library auto-refresh and directory monitoring.

The generated config directory is a read-only symlink into the Nix store. Change settings in the module and rebuild instead of editing files under `~/.config/fooyin`.

---

## Theme model

fooyin themes are a `FyTheme`, defined in upstream `include/gui/theme/fytheme.h`.

A theme contains:

- a map of `PaletteKey` to `QColor`;
- a map of font class names to `QFont`.

A `PaletteKey` is a pair:

- `QPalette::ColorRole`, such as `Window`, `WindowText`, `Base`, or `Highlight`;
- `QPalette::ColorGroup`, such as `All`, `Active`, `Disabled`, or `Inactive`.

The GUI edit page is **Settings > Interface > Theme**. From there you can create, edit, import, and export themes.

### Import and export format

The `.fyt` import/export format is JSON. A minimal file looks like this:

```json
{
  "format": "fooyin-theme",
  "version": 1,
  "name": "Example",
  "colours": {
    "all.Window": "#ff141415",
    "all.WindowText": "#ffcdcdcd",
    "all.Highlight": "#ff6e94b2"
  },
  "fonts": {}
}
```

Colour keys use `<group>.<role>`:

```text
all.Window
all.WindowText
all.Base
all.Text
all.Button
all.ButtonText
all.Highlight
all.HighlightedText
disabled.WindowText
disabled.Highlight
```

Colours use `#AARRGGBB`, so `#ff141415` is fully opaque `#141415`. The eight-digit format is enforced by upstream `fythemefile.cpp`.

Groups are:

- `all`
- `active`
- `disabled`
- `inactive`

Roles are Qt's `QPalette::ColorRole` values. Common roles include `Window`, `WindowText`, `Base`, `Text`, `Button`, `ButtonText`, `Highlight`, `HighlightedText`, `Link`, `LinkVisited`, `AlternateBase`, `ToolTipBase`, `ToolTipText`, and `PlaceholderText`.

### Active theme storage

The GUI does not store the active theme as a readable name. It stores it in `Theme/CustomTheme` as a serialised Qt `QVariant`, and saved themes in `Theme/SavedThemes` as a compressed byte array.

Those values live in:

```text
~/.config/fooyin/fooyin.conf
```

They look like this:

```ini
[Theme]
CustomTheme=@Variant(...)
SavedThemes="@ByteArray(...)"
```

That is why the repository does not hand-write the theme. A small helper constructs a real `FyTheme` and lets `QSettings` serialise it with the same Qt version that fooyin uses.

### Theme writer

The helper is [`modules/features/apps/fooyin/theme-writer.cpp`](../../modules/features/apps/fooyin/theme-writer.cpp).

It:

1. reads a generated JSON colour list;
2. builds a `Fooyin::FyTheme`;
3. registers the Qt metatype;
4. writes `Theme/CustomTheme` and `Theme/SavedThemes` through `QSettings`.

The helper mirrors upstream's serialisation layout. If fooyin changes `FyTheme`, the helper must change with it.

The current theme is named `NixConfig`, uses ID `100`, and contains only colours. No custom font is applied.

---

## Colour mapping

The source palette is defined in [`modules/themes/palette.nix`](../../modules/themes/palette.nix). The active scheme is exposed as `config.theme.colours`, for example `c.bg`, `c.fg`, `c.accent`, and `c.border`.

The fooyin module maps those desktop colours onto Qt roles:

| Desktop colour | Qt group | Qt role |
| :--- | :--- | :--- |
| `c.fg` | `all` | `WindowText` |
| `c.fgDim` | `disabled` | `WindowText` |
| `c.fg` | `all` | `Text` |
| `c.fgDim` | `disabled` | `Text` |
| `c.fg` | `all` | `ButtonText` |
| `c.fgDim` | `disabled` | `ButtonText` |
| `c.red` | `all` | `BrightText` |
| `c.bgRaised` | `all` | `Button` |
| `c.bgSubtle` | `all` | `Light` |
| `c.border` | `all` | `Midlight` |
| `c.bg` | `all` | `Dark` |
| `c.bgRaised` | `all` | `Mid` |
| `c.bgRaised` | `all` | `Base` |
| `c.bg` | `all` | `Window` |
| `c.bg` | `all` | `Shadow` |
| `c.accent` | `all` | `Highlight` |
| `c.bgSubtle` | `disabled` | `Highlight` |
| `c.bg` | `all` | `HighlightedText` |
| `c.fgDim` | `disabled` | `HighlightedText` |
| `c.teal` | `all` | `Link` |
| `c.purple` | `all` | `LinkVisited` |
| `c.bgSubtle` | `all` | `AlternateBase` |
| `c.bgRaised` | `all` | `ToolTipBase` |
| `c.fg` | `all` | `ToolTipText` |
| `c.fgDim` | `all` | `PlaceholderText` |

To add a role, add another entry to the `colours` list in `fooyin.nix`:

```nix
{
  group = "all";
  role = "Mid";
  colour = c.border;
}
```

Rebuild and restart fooyin to apply it.

### Icon theme

Fooyin also chooses between light and dark icon sets. The module calculates the background luminance from `c.bg` and sets:

- `IconTheme=2` for light backgrounds;
- `IconTheme=3` for dark backgrounds.

The enum values come from upstream `IconThemeOption`:

```text
0 = Auto-detect
1 = System icons
2 = Light
3 = Dark
```

---

## The `Minimal` layout

The layout is defined in [`modules/features/apps/fooyin/minimal.fyl`](../../modules/features/apps/fooyin/minimal.fyl).

It uses fooyin's built-in widgets:

- `Playlist` as the track list;
- `LibraryFilter` in icon mode as the album cover grid;
- `ArtworkPanel` and `SelectionInfo` as the now-playing panel;
- `SeekBar` across the bottom;
- `PlayerControls`, `ScriptDisplay`, and `VolumeControls` in the bottom row.

The layout intentionally does not apply custom widget styling. Only the palette and the layout arrangement are customised.

### Splitter state

Each `State` value is base64 data from Qt's `QSplitter::saveState()`. It is not meant to be edited by hand.

If you need different pane sizes, the practical route is:

1. Enable **Layout > Editing mode** in fooyin.
2. Resize the panes.
3. Export the layout from **Layout > Export layout**.
4. Copy the resulting `.fyl` back into the module.

### Album grid source

The `LibraryFilter` uses album and album artist columns in icon mode. It shows album covers with captions underneath.

Fooyin filters only include tracks that belong to a library. Tracks that exist only in a playlist are skipped by the filter pipeline. Add a folder from **Settings > Library** before expecting the grid to populate.

The module enables `Library/AutoRefresh`, `Library/MonitorLibraries`, and `Library/MonitorTrackFiles`, so new libraries are scanned and watched automatically.

### Layout selection

The active layout is stored in:

```text
~/.local/state/fooyin/fooyin.state
```

It is not controlled by `fooyin.conf`. After rebuilding, choose **Layout > Minimal** from the menu bar. The choice persists until another layout is selected.

If fooyin is closed, the same switch can be made from a shell:

```bash
sed -i 's/^ActiveLayout=.*/ActiveLayout=Minimal/' ~/.local/state/fooyin/fooyin.state
```

---

## Customising the theme

### In the GUI

1. Open **Settings > Interface > Theme**.
2. Create or edit a theme.
3. Adjust the basic and advanced palette roles.
4. Export the theme as a `.fyt` file.
5. Open the `.fyt` file in a text editor to inspect the exact role names and colours.

### In the repository

1. Change the active scheme in [`modules/themes/default.nix`](../../modules/themes/default.nix), or edit a scheme in `palette.nix`.
2. Add or change role mappings in `fooyin.nix`.
3. Rebuild with `./build.sh`.
4. Restart fooyin.

### Adding a font

The theme writer supports fonts, but the current theme deliberately leaves them at the application default.

To apply one, add a `font` object to the generated theme JSON in `fooyin.nix`:

```nix
font = {
  family = config.theme.fonts.sans;
  size = 10.5;
};
```

The helper inserts it as the default theme font.

---

## Troubleshooting

### The layout is still the old one

The active layout is runtime state. Rebuild, restart fooyin, then choose **Layout > Minimal**. Alternatively, edit `ActiveLayout` in `~/.local/state/fooyin/fooyin.state` while fooyin is closed.

### The album grid is empty

The library is empty, or the tracks are not library tracks. Add the music folder from **Settings > Library** and let the scan finish. Check the library state with:

```bash
sqlite3 ~/.local/share/fooyin/fooyin.db \
  'select count(*), sum(case when LibraryID >= 0 then 1 else 0 end) from Tracks;'
```

A result such as `47|47` means all tracks belong to a library.

### The theme is not applied

- Restart fooyin after rebuilding.
- Check that `~/.config/fooyin` points at the current store path.
- Open **Settings > Interface > Theme** and confirm `NixConfig` is selected.
- Remember that `~/.config/fooyin` is a read-only symlink. Editing it will not persist.

### Theme changes do not survive a rebuild

The theme is generated by Nix. Change `fooyin.nix` or the palette, then rebuild. Runtime edits made in the GUI are overwritten when the symlink updates.

---

## Upstream references

- Fooyin documentation: https://docs.fooyin.org/en/latest/
- Theme struct: https://github.com/fooyin/fooyin/blob/master/include/gui/theme/fytheme.h
- Theme file format: https://github.com/fooyin/fooyin/blob/master/src/gui/theme/fythemefile.cpp
- Built-in themes and role examples: https://github.com/fooyin/fooyin/blob/master/src/gui/theme/themeregistry.cpp
- Theme settings page: https://github.com/fooyin/fooyin/blob/master/src/gui/settings/guithemespage.cpp
- Theme application: https://github.com/fooyin/fooyin/blob/master/src/gui/guiapplication.cpp
- Qt palette roles: https://doc.qt.io/qt-6/qpalette.html
- Qt colour roles: https://doc.qt.io/qt-6/qpalette.html#ColorRole-enum
- Qt colour groups: https://doc.qt.io/qt-6/qpalette.html#ColorGroup-enum

---

## File map

| Path | Purpose |
| :--- | :--- |
| `modules/features/apps/fooyin.nix` | Module, palette mapping, generated config |
| `modules/features/apps/fooyin/theme-writer.cpp` | Writes the `FyTheme` QVariant into `fooyin.conf` |
| `modules/features/apps/fooyin/minimal.fyl` | `Minimal` layout |
| `modules/themes/palette.nix` | Desktop colour schemes |
| `~/.config/fooyin/fooyin.conf` | Generated theme and library settings |
| `~/.local/state/fooyin/fooyin.state` | Active layout, window geometry, playlist state |
| `~/.local/share/fooyin/fooyin.db` | Library database and playlists |
