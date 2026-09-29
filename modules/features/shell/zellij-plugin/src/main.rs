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
use std::path::Path;
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
    cwd: Option<String>,
    config: BTreeMap<String, String>,
    // Host APIs (get_focused_pane_info/get_pane_cwd) need the
    // ReadApplicationState permission; calling them before zellij has
    // registered it panics, so wait for the result.
    permitted: bool,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.config = configuration;
        request_permission(&[PermissionType::ReadApplicationState]);
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
            // Focus changes show up as pane updates; cwd changes arrive directly.
            Event::PaneUpdate(_) | Event::CwdChanged(..) => {
                if self.permitted {
                    self.refresh_cwd()
                } else {
                    false
                }
            },
            _ => false,
        }
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

        let new_cwd = get_focused_pane_info()
            .ok()
            .and_then(|(_tab, pane_id)| get_pane_cwd(pane_id).ok())
            .map(|path| display_path(&path));

        if new_cwd != self.cwd {
            self.cwd = new_cwd;
            true
        } else {
            false
        }
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
