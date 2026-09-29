//! `leader :` command palette.
//!
//! A small floating list of zellij commands with fuzzy search and descriptions.
//! Commands are executed by running `zellij action <args>` so the palette stays
//! in sync with the CLI rather than the (limited) plugin action API.
//!
//! Keys: type to filter, ↑/↓ or Ctrl-p/Ctrl-n to move, Enter to run, Esc to
//! close. zellij draws the surrounding floating-pane frame/title, so the plugin
//! renders its list directly without its own border.

use std::collections::BTreeMap;
use zellij_tile::prelude::*;

type Rgb = (u8, u8, u8);

struct Command {
    name: &'static str,
    desc: &'static str,
    /// Args passed to `zellij action`.
    args: &'static [&'static str],
}

const COMMANDS: &[Command] = &[
    Command { name: "Split right", desc: "New pane to the right", args: &["new-pane", "--direction", "right"] },
    Command { name: "Split down", desc: "New pane below", args: &["new-pane", "--direction", "down"] },
    Command { name: "New floating pane", desc: "Open a floating pane", args: &["new-pane", "--floating"] },
    Command { name: "Close pane", desc: "Close the focused pane", args: &["close-pane"] },
    Command { name: "Toggle fullscreen", desc: "Zoom the focused pane", args: &["toggle-fullscreen"] },
    Command { name: "Toggle floating panes", desc: "Show/hide floating panes", args: &["toggle-floating-panes"] },
    Command { name: "Embed or float", desc: "Float/embed the focused pane", args: &["toggle-pane-embed-or-floating"] },
    Command { name: "New tab", desc: "Create a new tab", args: &["new-tab"] },
    Command { name: "Close tab", desc: "Close the current tab", args: &["close-tab"] },
    Command { name: "Next tab", desc: "Go to the next tab", args: &["go-to-next-tab"] },
    Command { name: "Previous tab", desc: "Go to the previous tab", args: &["go-to-previous-tab"] },
    Command { name: "Move tab left", desc: "Move the tab left", args: &["move-tab", "left"] },
    Command { name: "Move tab right", desc: "Move the tab right", args: &["move-tab", "right"] },
    Command { name: "Focus left", desc: "Focus the pane to the left", args: &["move-focus", "left"] },
    Command { name: "Focus down", desc: "Focus the pane below", args: &["move-focus", "down"] },
    Command { name: "Focus up", desc: "Focus the pane above", args: &["move-focus", "up"] },
    Command { name: "Focus right", desc: "Focus the pane to the right", args: &["move-focus", "right"] },
    Command { name: "Focus next pane", desc: "Cycle to the next pane", args: &["focus-next-pane"] },
    Command { name: "Focus last pane", desc: "Focus the previously focused pane", args: &["focus-last-pane"] },
    Command { name: "Resize left", desc: "Grow/shrink at the left border", args: &["resize", "increase", "left"] },
    Command { name: "Resize right", desc: "Grow/shrink at the right border", args: &["resize", "increase", "right"] },
    Command { name: "Resize up", desc: "Grow/shrink at the top border", args: &["resize", "increase", "up"] },
    Command { name: "Resize down", desc: "Grow/shrink at the bottom border", args: &["resize", "increase", "down"] },
    Command { name: "Toggle pane frames", desc: "Show/hide pane borders", args: &["toggle-pane-frames"] },
    Command { name: "Toggle sync panes", desc: "Sync input to all panes in the tab", args: &["toggle-active-sync-tab"] },
    Command { name: "Next swap layout", desc: "Cycle the pane layout", args: &["next-swap-layout"] },
    Command { name: "Clear pane", desc: "Clear the focused pane's buffers", args: &["clear"] },
    Command { name: "Edit scrollback", desc: "Open the scrollback in $EDITOR", args: &["edit-scrollback"] },
    Command { name: "Save session", desc: "Save the session state to disk", args: &["save-session"] },
    Command { name: "Toggle theme", desc: "Switch dark/light theme", args: &["toggle-theme"] },
    Command { name: "Session manager", desc: "Open the session manager", args: &["launch-or-focus-plugin", "zellij:session-manager", "--floating", "--move-to-focused-tab"] },
    Command { name: "Plugin manager", desc: "Open the plugin manager", args: &["launch-or-focus-plugin", "zellij:plugin-manager", "--floating", "--move-to-focused-tab"] },
    Command { name: "Configuration", desc: "Open the zellij configuration", args: &["launch-or-focus-plugin", "zellij:configuration", "--floating", "--move-to-focused-tab"] },
    Command { name: "Detach", desc: "Detach from the session", args: &["detach"] },
];

const HELP: &str = " type to filter   ↑/↓ or ctrl-j/k move   ⏎ run   esc close";

#[derive(Default)]
struct State {
    config: BTreeMap<String, String>,
    query: String,
    selected: usize,
    zellij_bin: String,
    plugin_id: u32,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.config = configuration;
        self.zellij_bin = self
            .config
            .get("zellij_bin")
            .cloned()
            .unwrap_or_else(|| "zellij".to_owned());
        self.plugin_id = get_plugin_ids().plugin_id;

        request_permission(&[
            PermissionType::ChangeApplicationState,
            PermissionType::RunCommands,
        ]);
        subscribe(&[EventType::Key, EventType::PermissionRequestResult]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(status) => {
                // Host calls need the grant to be registered first.
                if status == PermissionStatus::Granted {
                    rename_plugin_pane(self.plugin_id, "Commands");
                    self.resize_self();
                }
                true
            },
            Event::Key(key) => self.handle_key(key),
            _ => false,
        }
    }

    fn render(&mut self, rows: usize, cols: usize) {
        self.draw(rows, cols);
    }
}

impl State {
    /// Size the palette into a small window.
    fn resize_self(&self) {
        let coord = |key: &str, default: &str| {
            self.config
                .get(key)
                .cloned()
                .unwrap_or_else(|| default.to_owned())
        };
        if let Some(coords) = FloatingPaneCoordinates::new(
            Some(coord("x", "20%")),
            Some(coord("y", "20%")),
            Some(coord("width", "60%")),
            Some(coord("height", "60%")),
            Some(true),
            None,
        ) {
            change_floating_panes_coordinates(vec![(PaneId::Plugin(self.plugin_id), coords)]);
        }
    }

    fn handle_key(&mut self, key: KeyWithModifier) -> bool {
        let ctrl = key.has_modifiers(&[KeyModifier::Ctrl]);
        match key.bare_key {
            BareKey::Esc if key.has_no_modifiers() => {
                close_self();
                false
            },
            BareKey::Char('c') if ctrl => {
                close_self();
                false
            },
            BareKey::Enter if key.has_no_modifiers() => {
                self.run_selected();
                false
            },
            BareKey::Down if key.has_no_modifiers() => {
                self.move_selection(1);
                true
            },
            BareKey::Up if key.has_no_modifiers() => {
                self.move_selection(-1);
                true
            },
            BareKey::Tab if key.has_modifiers(&[KeyModifier::Shift]) => {
                self.move_selection(-1);
                true
            },
            BareKey::Tab if key.has_no_modifiers() => {
                self.move_selection(1);
                true
            },
            BareKey::Char('n' | 'j') if ctrl => {
                self.move_selection(1);
                true
            },
            BareKey::Char('p' | 'k') if ctrl => {
                self.move_selection(-1);
                true
            },
            BareKey::Backspace if key.has_no_modifiers() => {
                self.query.pop();
                self.selected = 0;
                true
            },
            BareKey::Char(c) if key.has_no_modifiers() && !c.is_control() => {
                self.query.push(c);
                self.selected = 0;
                true
            },
            _ => false,
        }
    }

    fn move_selection(&mut self, delta: isize) {
        let len = self.filtered().len();
        if len == 0 {
            self.selected = 0;
            return;
        }
        let current = self.selected.min(len - 1) as isize;
        self.selected = (current + delta).rem_euclid(len as isize) as usize;
    }

    fn filtered(&self) -> Vec<usize> {
        if self.query.trim().is_empty() {
            return (0..COMMANDS.len()).collect();
        }
        let mut scored: Vec<(i32, usize)> = COMMANDS
            .iter()
            .enumerate()
            .filter_map(|(index, command)| {
                let name = fuzzy_score(&self.query, command.name);
                let desc = fuzzy_score(&self.query, command.desc);
                match (name, desc) {
                    (Some(score), _) => Some((score + 100, index)),
                    (None, Some(score)) => Some((score, index)),
                    _ => None,
                }
            })
            .collect();
        scored.sort_by(|a, b| b.0.cmp(&a.0));
        scored.into_iter().map(|(_, index)| index).collect()
    }

    fn run_selected(&mut self) {
        let filtered = self.filtered();
        let Some(&index) = filtered.get(self.selected.min(filtered.len().saturating_sub(1))) else {
            close_self();
            return;
        };
        let command = &COMMANDS[index];

        // Close first: zellij processes shim messages in order, so the action
        // then applies to the pane behind the palette rather than the palette.
        close_self();
        let mut argv: Vec<&str> = vec![self.zellij_bin.as_str(), "action"];
        argv.extend_from_slice(command.args);
        run_command(&argv, BTreeMap::new());
    }

    fn color(&self, key: &str, fallback: Rgb) -> Rgb {
        self.config
            .get(key)
            .and_then(|value| parse_hex(value))
            .unwrap_or(fallback)
    }

    fn draw(&mut self, rows: usize, cols: usize) {
        if rows == 0 || cols == 0 {
            return;
        }

        let bg = self.color("bg", (0, 0, 0));
        let fg_mid = self.color("fg_mid", (128, 128, 128));
        let accent = self.color("accent", (255, 255, 255));
        let bg_subtle = self.color("bg_subtle", (40, 40, 40));

        let filtered = self.filtered();
        let list_rows = rows.saturating_sub(3); // query + spacer + help
        let start = if list_rows == 0 {
            0
        } else {
            self.selected.saturating_sub(list_rows - 1)
        };

        let mut lines: Vec<String> = Vec::with_capacity(rows);
        lines.push(row(&format!(" > {}", self.query), cols, accent, bg, true));
        lines.push(row("", cols, fg_mid, bg, false));
        for slot in 0..list_rows {
            let index = start + slot;
            if index >= filtered.len() {
                lines.push(row("", cols, fg_mid, bg, false));
                continue;
            }
            let command = &COMMANDS[filtered[index]];
            let text = format!(" {:<22} {}", truncate(command.name, 22), command.desc);
            if index == self.selected {
                lines.push(row(&text, cols, accent, bg_subtle, true));
            } else {
                lines.push(row(&text, cols, fg_mid, bg, false));
            }
        }
        lines.push(row(HELP, cols, fg_mid, bg, false));

        print!("\u{1b}[2J");
        for (index, line) in lines.iter().enumerate().take(rows) {
            print!("\u{1b}[{};1H{}", index + 1, line);
        }
    }
}

/// A full-width, padded row. zellij draws the pane frame, so each row spans the
/// whole width and carries its own background.
fn row(text: &str, cols: usize, fg: Rgb, bg: Rgb, bold: bool) -> String {
    let padded = pad_to(text, cols);
    let bold = if bold { "\u{1b}[1m" } else { "" };
    format!(
        "{bold}\u{1b}[38;2;{};{};{}m\u{1b}[48;2;{};{};{}m{padded}",
        fg.0, fg.1, fg.2, bg.0, bg.1, bg.2
    )
}

fn pad_to(text: &str, width: usize) -> String {
    let truncated = truncate(text, width);
    let len = truncated.chars().count();
    if len < width {
        format!("{truncated}{}", " ".repeat(width - len))
    } else {
        truncated
    }
}

fn truncate(text: &str, width: usize) -> String {
    text.chars().take(width).collect()
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

/// Case-insensitive subsequence match. Higher scores are better; consecutive
/// matches and matches near the start score higher.
fn fuzzy_score(needle: &str, haystack: &str) -> Option<i32> {
    let needle: Vec<char> = needle
        .to_lowercase()
        .chars()
        .filter(|c| !c.is_whitespace())
        .collect();
    if needle.is_empty() {
        return Some(0);
    }
    let haystack: Vec<char> = haystack.to_lowercase().chars().collect();
    let mut score = 0i32;
    let mut needle_index = 0usize;
    let mut previous_match: Option<usize> = None;
    for (index, character) in haystack.iter().enumerate() {
        if needle_index < needle.len() && *character == needle[needle_index] {
            score += 1;
            if previous_match == Some(index.wrapping_sub(1)) {
                score += 5;
            }
            if index == 0 {
                score += 3;
            }
            previous_match = Some(index);
            needle_index += 1;
        }
    }
    (needle_index == needle.len()).then_some(score)
}
