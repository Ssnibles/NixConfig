//! A minimal, tmux-shaped zellij status bar.
//!
//! Renders a single line with:
//!   [ leader ][ 1 tab ][ 2 tab ]............[ session ][ /path/to/cwd ]
//!
//! - The leader pill only appears while the leader (`tmux`) mode is active.
//! - Unfocused tabs have no background; the focused tab is accent-on-bgSubtle.
//! - The focused pane's working directory is read through the plugin API, so it
//!   updates live and tracks pane focus (unlike shelling out from a command
//!   widget).
//!
//! Colors are passed in from the Nix module via plugin config so the bar
//! follows `config.theme.colors`.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use zellij_tile::prelude::*;

const MAX_PATH: usize = 35;
const PATH_TAIL: usize = 32;

type Rgb = (u8, u8, u8);

#[derive(Default)]
struct State {
    mode: InputMode,
    session_name: Option<String>,
    tabs: Vec<TabInfo>,
    // Stored tab names, keyed by stable tab id. The TabUpdate event carries the
    // *display* name (which becomes the pane title when frames draw titles),
    // whereas get_tab_info returns the name the user actually set.
    tab_names: BTreeMap<usize, String>,
    // Live pane manifest, used to find an existing yazi pane to focus.
    pane_manifest: PaneManifest,
    // Display form of the last known *terminal* cwd (see `refresh_cwd`).
    cwd: Option<String>,
    // Raw form of the same path, handed to keybind actions (new tab / yazi).
    cwd_path: Option<PathBuf>,
    config: BTreeMap<String, String>,
    zellij_bin: String,
    yazi_bin: String,
    // This bar instance's own plugin id, used to tell which tab it lives in.
    plugin_id: u32,
    // Host APIs (get_focused_pane_info/get_pane_cwd) need the
    // ReadApplicationState permission; calling them before zellij has
    // registered it panics, so wait for the result.
    permitted: bool,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.zellij_bin = configuration
            .get("zellij_bin")
            .cloned()
            .unwrap_or_else(|| "zellij".to_owned());
        self.yazi_bin = configuration
            .get("yazi_bin")
            .cloned()
            .unwrap_or_else(|| "yazi".to_owned());
        self.config = configuration;
        self.plugin_id = get_plugin_ids().plugin_id;
        // RunCommands lets the bar answer keybind `MessagePlugin` actions by
        // running `zellij action ...` (new tab with cwd / yazi popup toggle).
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::RunCommands,
        ]);
        subscribe(&[
            EventType::ModeUpdate,
            EventType::TabUpdate,
            EventType::PaneUpdate,
            EventType::CwdChanged,
            EventType::PermissionRequestResult,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                self.permitted = true;
                // Only now can the pane become non-selectable: while the
                // permission prompt is up it must remain focusable.
                set_selectable(false);
                self.refresh_tab_names();
                self.refresh_cwd()
            },
            Event::PermissionRequestResult(PermissionStatus::Denied) => {
                set_selectable(false);
                false
            },
            Event::ModeUpdate(mode_info) => {
                self.mode = mode_info.mode;
                self.session_name = mode_info.session_name;
                true
            },
            Event::TabUpdate(tabs) => {
                self.tabs = tabs;
                self.refresh_tab_names();
                true
            },
            Event::PaneUpdate(pane_manifest) => {
                self.pane_manifest = pane_manifest;
                if self.permitted {
                    self.refresh_cwd()
                } else {
                    false
                }
            },
            // Focus changes show up as pane updates; cwd changes arrive directly.
            Event::CwdChanged(..) => {
                if self.permitted {
                    self.refresh_cwd()
                } else {
                    false
                }
            },
            _ => false,
        }
    }

    /// Keybind `MessagePlugin "zjbar" { name "..."; payload "..."; }` actions
    /// and `zellij action pipe` messages arrive here.
    ///
    /// A pipe fans out to every bar instance (one per tab); `in_focused_tab`
    /// keeps that to the bar in the focused tab, so one keypress opens/moves
    /// exactly one thing. The `None` end-of-pipe marker that
    /// `zellij action pipe` appends after the real payload is ignored.
    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        let Some(payload) = pipe_message.payload.as_deref() else {
            return false;
        };
        if self.permitted && self.in_focused_tab() {
            match pipe_message.name.as_str() {
                "new-tab" => self.open_new_tab(Some(payload).filter(|name| !name.is_empty())),
                "toggle-yazi" => self.toggle_yazi(),
                _ => {},
            }
        }
        false
    }

    fn render(&mut self, _rows: usize, cols: usize) {
        let bg = self.color("bg");
        let fg_mid = self.color("fg_mid");
        let accent = self.color("accent");
        let bg_subtle = self.color("bg_subtle");
        let yellow = self.color("yellow");
        let teal = self.color("teal");

        let mut left = String::new();
        let mut left_w = 0usize;
        // A neutral gap between elements so coloured pills don't touch.
        let gap = seg(" ", bg, bg, false);
        let mut first = true;

        if self.mode == InputMode::Tmux {
            let label = " leader ";
            left.push_str(&seg(label, bg, yellow, true));
            left_w += label.chars().count();
            first = false;
        }

        if let Some(session) = &self.session_name {
            if !first {
                left.push_str(&gap);
                left_w += 1;
            }
            let label = format!(" {} ", session.to_lowercase());
            left.push_str(&seg(&label, bg, accent, true));
            left_w += label.chars().count();
            first = false;
        }

        for tab in &self.tabs {
            if !first {
                left.push_str(&gap);
                left_w += 1;
            }
            let index = tab.position + 1;
            // Use the stored name (see `tab_names`), not the display name from
            // the event: zellij swaps that for the pane title when frames draw
            // titles, which would leak directory names into the bar.
            let stored_name = self
                .tab_names
                .get(&tab.tab_id)
                .map(String::as_str)
                .unwrap_or("");
            let name = if stored_name.is_empty() || is_default_tab_name(stored_name) {
                String::new()
            } else {
                format!(" {}", stored_name.to_lowercase())
            };
            // The focused tab gets extra left/right margin around its number.
            let label = if tab.active {
                format!("  {index}{name}  ")
            } else {
                format!(" {index}{name} ")
            };
            let width = label.chars().count();
            if tab.active {
                left.push_str(&seg(&label, accent, bg_subtle, true));
            } else {
                left.push_str(&seg(&label, fg_mid, bg, false));
            }
            left_w += width;
            first = false;
        }

        let mut right = String::new();
        let mut right_w = 0usize;

        if let Some(cwd) = &self.cwd {
            let label = format!(" {cwd} ");
            right.push_str(&seg(&label, teal, bg, true));
            right_w += label.chars().count();
        }

        let pad = cols.saturating_sub(left_w + right_w);
        let mut out = String::new();
        out.push_str(reset_code());
        out.push_str(&bg_code(bg));
        out.push_str(&left);
        if pad > 0 {
            // Re-assert the bar background: the padding must not inherit the
            // last segment's colours (e.g. a focused rightmost tab).
            out.push_str(&bg_code(bg));
            out.push_str(&" ".repeat(pad));
        }
        out.push_str(&right);
        // Clear the remainder of the row with the bar background, then reset.
        out.push_str(&format!("{}\x1b[0K\x1b[0m", bg_code(bg)));
        print!("{out}");
    }
}

impl State {
    fn color(&self, key: &str) -> Rgb {
        self.config
            .get(key)
            .and_then(|value| parse_hex(value))
            .unwrap_or((0, 0, 0))
    }

    /// Cache the stored (user-set) tab names, which the `TabUpdate` event does
    /// not reliably carry (it sends the pane title instead once frames render
    /// titles).
    fn refresh_tab_names(&mut self) {
        if !self.permitted {
            return;
        }
        self.tab_names.clear();
        for tab in &self.tabs {
            if let Some(info) = get_tab_info(tab.tab_id) {
                self.tab_names.insert(tab.tab_id, info.name);
            }
        }
    }

    /// Re-read the focused pane's cwd. Returns whether it changed (so zellij
    /// knows to re-render).
    fn refresh_cwd(&mut self) -> bool {
        if !self.permitted {
            return false;
        }

        // Only terminal panes report a cwd. When a plugin (eg. the command
        // palette) takes focus there is nothing to read; keep the last known
        // terminal cwd so the bar and the keybind actions still have a target.
        let Some(path) = get_focused_pane_info()
            .ok()
            .and_then(|(_tab, pane_id)| get_pane_cwd(pane_id).ok())
        else {
            return false;
        };

        let display = display_path(&path);
        if self.cwd.as_deref() == Some(display.as_str())
            && self.cwd_path.as_deref() == Some(path.as_path())
        {
            return false;
        }
        self.cwd = Some(display);
        self.cwd_path = Some(path);
        true
    }

    /// Open a new tab, carrying over the focused pane's working directory.
    fn open_new_tab(&self, name: Option<&str>) {
        let cwd = self.cwd_path.as_ref().map(|path| path.display().to_string());
        let mut argv: Vec<&str> = vec![self.zellij_bin.as_str(), "action", "new-tab"];
        if let Some(name) = name.filter(|name| !name.is_empty()) {
            argv.push("--name");
            argv.push(name);
        }
        if let Some(cwd) = cwd.as_deref() {
            argv.push("--cwd");
            argv.push(cwd);
        }
        run_command(&argv, BTreeMap::new());
    }

    /// Focus (or open) a floating yazi popup, closing it when it already has
    /// focus. Mirrors the tmux `leader e` popup toggle.
    fn toggle_yazi(&self) {
        if let Ok((_tab, pane_id)) = get_focused_pane_info() {
            if is_yazi(pane_id) && pane_is_floating(pane_id) {
                let target = pane_ref(pane_id);
                self.run_action(&["close-pane", "--pane-id", target.as_str()]);
                return;
            }
        }
        if let Some(pane_id) = self.find_yazi_pane() {
            let target = pane_ref(pane_id);
            self.run_action(&["focus-pane-id", target.as_str()]);
            return;
        }

        let cwd = self.cwd_path.as_ref().map(|path| path.display().to_string());
        let coord = |key: &str, default: &str| {
            self.config
                .get(key)
                .cloned()
                .unwrap_or_else(|| default.to_owned())
        };
        let x = coord("yazi_x", "7%");
        let y = coord("yazi_y", "7%");
        let width = coord("yazi_width", "86%");
        let height = coord("yazi_height", "86%");
        let mut argv: Vec<&str> = vec![
            self.zellij_bin.as_str(),
            "action",
            "new-pane",
            "--floating",
            "--close-on-exit",
            "--x",
            x.as_str(),
            "--y",
            y.as_str(),
            "--width",
            width.as_str(),
            "--height",
            height.as_str(),
        ];
        if let Some(cwd) = cwd.as_deref() {
            argv.push("--cwd");
            argv.push(cwd);
        }
        argv.push("--");
        argv.push(self.yazi_bin.as_str());
        run_command(&argv, BTreeMap::new());
    }

    /// Run a `zellij action ...` command with the bar as the caller.
    fn run_action(&self, args: &[&str]) {
        let mut argv: Vec<&str> = vec![self.zellij_bin.as_str(), "action"];
        argv.extend_from_slice(args);
        run_command(&argv, BTreeMap::new());
    }

    /// Whether this bar instance lives in the currently focused tab. A pipe to
    /// the `zjbar` alias reaches every tab's bar, so this gate keeps exactly
    /// one instance acting on a control message.
    fn in_focused_tab(&self) -> bool {
        let Ok((focused_tab, _pane)) = get_focused_pane_info() else {
            return false;
        };
        self.pane_manifest.panes.iter().any(|(tab_position, panes)| {
            *tab_position == focused_tab
                && panes
                    .iter()
                    .any(|pane| pane.is_plugin && pane.id == self.plugin_id)
        })
    }

    /// Floating pane running yazi, if any (ie. the popup we opened).
    fn find_yazi_pane(&self) -> Option<PaneId> {
        self.pane_manifest.panes.values().flatten().find_map(|pane| {
            if pane.is_plugin || !pane.is_floating {
                return None;
            }
            let pane_id = PaneId::Terminal(pane.id);
            is_yazi(pane_id).then_some(pane_id)
        })
    }
}

/// Builds an ANSI-styled run. Every segment resets attributes first and then
/// sets both fg and bg, so neither colours nor bold can bleed into the next
/// segment (and `bold: false` truly means regular weight).
fn seg(text: &str, fg: Rgb, bg: Rgb, bold: bool) -> String {
    let bold = if bold { "\x1b[1m" } else { "" };
    format!(
        "{}{bold}\x1b[38;2;{};{};{}m\x1b[48;2;{};{};{}m{text}",
        reset_code(),
        fg.0, fg.1, fg.2, bg.0, bg.1, bg.2
    )
}

fn reset_code() -> &'static str {
    "\x1b[0m"
}

fn bg_code((r, g, b): Rgb) -> String {
    format!("\x1b[48;2;{r};{g};{b}m")
}

/// zellij's auto-generated tab names look like `Tab #3`.
fn is_default_tab_name(name: &str) -> bool {
    name.strip_prefix("Tab #")
        .is_some_and(|rest| !rest.is_empty() && rest.chars().all(|c| c.is_ascii_digit()))
}

/// The `terminal_<id>` / `plugin_<id>` string Zellij's CLI expects.
fn pane_ref(pane_id: PaneId) -> String {
    match pane_id {
        PaneId::Terminal(id) => format!("terminal_{id}"),
        PaneId::Plugin(id) => format!("plugin_{id}"),
    }
}

/// Whether the pane's foreground process is yazi.
fn is_yazi(pane_id: PaneId) -> bool {
    get_pane_running_command(pane_id)
        .ok()
        .and_then(|argv| argv.into_iter().next())
        .and_then(|command| {
            Path::new(&command)
                .file_name()
                .map(|name| name.to_string_lossy() == "yazi")
        })
        .unwrap_or(false)
}

/// Whether the pane is currently floating (tiled panes should never be
/// mistaken for the yazi popup).
fn pane_is_floating(pane_id: PaneId) -> bool {
    get_pane_info(pane_id)
        .map(|info| info.is_floating)
        .unwrap_or(false)
}

fn parse_hex(value: &str) -> Option<Rgb> {
    let value = value.trim().trim_start_matches('#');
    if value.len() != 6 {
        return None;
    }
    Some((
        u8::from_str_radix(&value[0..2], 16).ok()?,
        u8::from_str_radix(&value[2..4], 16).ok()?,
        u8::from_str_radix(&value[4..6], 16).ok()?,
    ))
}

/// Show `~` for the home directory and middle-truncate long paths, matching the
/// tmux status bar's formatter.
fn display_path(path: &Path) -> String {
    let full = path.display().to_string();
    let display = match std::env::var("HOME") {
        Ok(home) if !home.is_empty() && full.starts_with(&home) => {
            format!("~{}", &full[home.len()..])
        },
        _ => full,
    };

    let len = display.chars().count();
    if len > MAX_PATH {
        let tail: String = display.chars().skip(len - PATH_TAIL).collect();
        format!("...{tail}")
    } else {
        display
    }
}
