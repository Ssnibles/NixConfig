//! `leader :` command palette.
//!
//! A small floating list of zellij commands with fuzzy search and descriptions.
//! Most commands are executed by running `zellij action <args>` so the palette
//! stays in sync with the CLI; a few (session switching/renaming/killing) use
//! the plugin host API directly, which is the only way to create-or-switch a
//! session from inside a running one.
//!
//! Commands that need a name/argument open an inline prompt after Enter; the
//! session command opens a live picker of running + resurrectable sessions
//! (it can also be launched straight into the picker with the `picker
//! "sessions"` config, which the `leader S` keybind does).
//!
//! Keys (list): type to filter, ↑/↓ or Ctrl-p/Ctrl-n to move, Enter to run,
//!              Esc to close.
//! Keys (prompt): type the argument, Enter to run, Esc/Ctrl-c to cancel.
//! Keys (sessions): type to filter, ↑/↓ to move, Enter to switch, Ctrl-r to
//!                  refresh, Esc to go back/close.
//! zellij draws the surrounding floating-pane frame/title, so the plugin
//! renders its list directly without its own border.

use std::collections::BTreeMap;
use std::time::Duration;
use zellij_tile::prelude::*;

type Rgb = (u8, u8, u8);

/// How a command is executed once its (optional) argument is known.
enum Exec {
    /// `zellij action <prefix...> <argument>` (argument appended as one argv
    /// element; no shell is involved).
    Action(&'static [&'static str]),
    /// `zellij action new-pane -- <shell> -lc <argument>`: run the argument as
    /// a shell command line in a new pane.
    Shell(&'static [&'static str]),
    /// `switch_session(<argument>)` — switches to the session, creating it if
    /// it does not exist.
    SwitchSession,
    /// `rename_session(<argument>)`.
    RenameSession,
    /// `kill_sessions(&[<argument>])`.
    KillSession,
    /// `delete_dead_session(<argument>)`.
    DeleteDeadSession,
    /// Kill and delete the session the palette is running in.
    KillCurrentSession,
    /// Open the interactive session picker (running + resurrectable sessions).
    SessionPicker,
}

struct Command {
    name: &'static str,
    desc: &'static str,
    exec: Exec,
    /// When set, Enter opens a text prompt (with this label) instead of running
    /// the command immediately.
    prompt: Option<&'static str>,
}

const COMMANDS: &[Command] = &[
    Command { name: "Split right", desc: "New pane to the right", exec: Exec::Action(&["new-pane", "--direction", "right"]), prompt: None },
    Command { name: "Split down", desc: "New pane below", exec: Exec::Action(&["new-pane", "--direction", "down"]), prompt: None },
    Command { name: "New floating pane", desc: "Open a floating pane", exec: Exec::Action(&["new-pane", "--floating"]), prompt: None },
    Command { name: "Close pane", desc: "Close the focused pane", exec: Exec::Action(&["close-pane"]), prompt: None },
    Command { name: "Toggle fullscreen", desc: "Zoom the focused pane", exec: Exec::Action(&["toggle-fullscreen"]), prompt: None },
    Command { name: "Toggle floating panes", desc: "Show/hide floating panes", exec: Exec::Action(&["toggle-floating-panes"]), prompt: None },
    Command { name: "Embed or float", desc: "Float/embed the focused pane", exec: Exec::Action(&["toggle-pane-embed-or-floating"]), prompt: None },
    Command { name: "New tab", desc: "New tab in the focused pane's cwd", exec: Exec::Action(&["pipe", "--plugin", "zjbar", "--name", "new-tab", "--", ""]), prompt: None },
    Command { name: "Close tab", desc: "Close the current tab", exec: Exec::Action(&["close-tab"]), prompt: None },
    Command { name: "Next tab", desc: "Go to the next tab", exec: Exec::Action(&["go-to-next-tab"]), prompt: None },
    Command { name: "Previous tab", desc: "Go to the previous tab", exec: Exec::Action(&["go-to-previous-tab"]), prompt: None },
    Command { name: "Move tab left", desc: "Move the tab left", exec: Exec::Action(&["move-tab", "left"]), prompt: None },
    Command { name: "Move tab right", desc: "Move the tab right", exec: Exec::Action(&["move-tab", "right"]), prompt: None },
    Command { name: "Focus left", desc: "Focus the pane to the left", exec: Exec::Action(&["move-focus", "left"]), prompt: None },
    Command { name: "Focus down", desc: "Focus the pane below", exec: Exec::Action(&["move-focus", "down"]), prompt: None },
    Command { name: "Focus up", desc: "Focus the pane above", exec: Exec::Action(&["move-focus", "up"]), prompt: None },
    Command { name: "Focus right", desc: "Focus the pane to the right", exec: Exec::Action(&["move-focus", "right"]), prompt: None },
    Command { name: "Focus next pane", desc: "Cycle to the next pane", exec: Exec::Action(&["focus-next-pane"]), prompt: None },
    Command { name: "Focus last pane", desc: "Focus the previously focused pane", exec: Exec::Action(&["focus-last-pane"]), prompt: None },
    Command { name: "Resize left", desc: "Grow/shrink at the left border", exec: Exec::Action(&["resize", "increase", "left"]), prompt: None },
    Command { name: "Resize right", desc: "Grow/shrink at the right border", exec: Exec::Action(&["resize", "increase", "right"]), prompt: None },
    Command { name: "Resize up", desc: "Grow/shrink at the top border", exec: Exec::Action(&["resize", "increase", "up"]), prompt: None },
    Command { name: "Resize down", desc: "Grow/shrink at the bottom border", exec: Exec::Action(&["resize", "increase", "down"]), prompt: None },
    Command { name: "Toggle pane frames", desc: "Show/hide pane borders", exec: Exec::Action(&["toggle-pane-frames"]), prompt: None },
    Command { name: "Toggle sync panes", desc: "Sync input to all panes in the tab", exec: Exec::Action(&["toggle-active-sync-tab"]), prompt: None },
    Command { name: "Next swap layout", desc: "Cycle the pane layout", exec: Exec::Action(&["next-swap-layout"]), prompt: None },
    Command { name: "Clear pane", desc: "Clear the focused pane's buffers", exec: Exec::Action(&["clear"]), prompt: None },
    Command { name: "Save session", desc: "Save the session state to disk", exec: Exec::Action(&["save-session"]), prompt: None },
    Command { name: "Session manager", desc: "Open the session manager", exec: Exec::Action(&["launch-or-focus-plugin", "zellij:session-manager", "--floating", "--move-to-focused-tab"]), prompt: None },
    Command { name: "Plugin manager", desc: "Open the plugin manager", exec: Exec::Action(&["launch-or-focus-plugin", "zellij:plugin-manager", "--floating", "--move-to-focused-tab"]), prompt: None },
    Command { name: "Detach", desc: "Detach from the session", exec: Exec::Action(&["detach"]), prompt: None },
    // ── Sessions ─────────────────────────────────────────────────────────────
    // `switch_session` creates the session when it does not exist, so "New
    // session" and "Switch session" share an implementation. zellij keeps the
    // old session alive when you switch away (like tmux's switch-client).
    Command { name: "New session", desc: "Create a session and switch to it", exec: Exec::SwitchSession, prompt: Some("new session name ›") },
    Command { name: "Switch session", desc: "Pick a running session to switch to", exec: Exec::SessionPicker, prompt: None },
    Command { name: "Rename session", desc: "Rename the current session", exec: Exec::RenameSession, prompt: Some("new session name ›") },
    Command { name: "Kill session", desc: "Kill another session by name", exec: Exec::KillSession, prompt: Some("session name ›") },
    Command { name: "Kill+delete this session", desc: "Kill and delete the current session", exec: Exec::KillCurrentSession, prompt: Some("type 'yes' to confirm ›") },
    Command { name: "Delete dead session", desc: "Delete a resurrectable session", exec: Exec::DeleteDeadSession, prompt: Some("session name ›") },
    // ── Tabs & panes with names ──────────────────────────────────────────────
    Command { name: "New named tab", desc: "New named tab in the focused cwd", exec: Exec::Action(&["pipe", "--plugin", "zjbar", "--name", "new-tab", "--"]), prompt: Some("tab name ›") },
    Command { name: "New tab at cwd", desc: "Open a new tab in a directory", exec: Exec::Action(&["new-tab", "--cwd"]), prompt: Some("directory ›") },
    Command { name: "Rename tab", desc: "Rename the current tab", exec: Exec::Action(&["rename-tab"]), prompt: Some("new tab name ›") },
    Command { name: "Go to tab by name", desc: "Focus the tab with this name", exec: Exec::Action(&["go-to-tab-name"]), prompt: Some("tab name ›") },
    Command { name: "Rename pane", desc: "Rename the focused pane", exec: Exec::Action(&["rename-pane"]), prompt: Some("new pane name ›") },
    // ── Free-form input ──────────────────────────────────────────────────────
    Command { name: "Run command", desc: "Run a shell command in a new pane", exec: Exec::Shell(&["new-pane"]), prompt: Some("shell command ›") },
    Command { name: "Run command here", desc: "Run a shell command in place", exec: Exec::Shell(&["new-pane", "--in-place"]), prompt: Some("shell command ›") },
    Command { name: "Write text", desc: "Type text into the focused pane", exec: Exec::Action(&["write-chars"]), prompt: Some("text ›") },
];

const HELP: &str = " type to filter   ↑/↓ or ctrl-j/k move   ⏎ run (… prompts)   esc close";
const HELP_INPUT: &str = " type the value   ⏎ run   ctrl-u clear   esc back";
const HELP_SESSIONS: &str = " type to filter   ↑/↓ or ctrl-j/k move   ⏎ switch   ctrl-r refresh   esc back";

#[derive(Default)]
enum Mode {
    #[default]
    List,
    Input,
    Sessions,
}

/// One row in the session picker.
struct SessionEntry {
    name: String,
    detail: String,
    current: bool,
}

#[derive(Default)]
struct State {
    config: BTreeMap<String, String>,
    query: String,
    selected: usize,
    mode: Mode,
    /// Index into `COMMANDS` of the command awaiting an argument.
    pending: Option<usize>,
    /// The argument being typed while in `Mode::Input`.
    input: String,
    zellij_bin: String,
    shell_bin: String,
    /// `setsid` binary, used to detach the kill+delete of the current session.
    setsid_bin: String,
    plugin_id: u32,
    /// Name of the session the palette is running in, so "Kill session" can
    /// refuse to kill our own client.
    session_name: Option<String>,
    /// Live + resurrectable sessions shown in the picker.
    sessions: Vec<SessionEntry>,
    /// Error from the last `get_session_list` call, shown in the picker.
    session_error: Option<String>,
    /// True when the picker was opened directly (`leader S`): Esc closes it
    /// rather than returning to the command list.
    session_picker_root: bool,
    /// Set from the `picker "sessions"` config when launched by a keybind.
    initial_picker: bool,
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
        self.shell_bin = self
            .config
            .get("shell")
            .cloned()
            .unwrap_or_else(|| "sh".to_owned());
        self.setsid_bin = self
            .config
            .get("setsid_bin")
            .cloned()
            .unwrap_or_else(|| "setsid".to_owned());
        self.initial_picker = self
            .config
            .get("picker")
            .map(|value| value == "sessions")
            .unwrap_or(false);
        self.plugin_id = get_plugin_ids().plugin_id;

        request_permission(&[
            PermissionType::ChangeApplicationState,
            PermissionType::ReadApplicationState,
            PermissionType::RunCommands,
        ]);
        subscribe(&[
            EventType::Key,
            EventType::ModeUpdate,
            EventType::PermissionRequestResult,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(status) => {
                // Host calls need the grant to be registered first.
                if status == PermissionStatus::Granted {
                    self.resize_self();
                    if self.initial_picker {
                        self.initial_picker = false;
                        self.open_session_picker(true);
                    } else {
                        rename_plugin_pane(self.plugin_id, "Commands");
                    }
                }
                true
            },
            Event::ModeUpdate(mode_info) => {
                self.session_name = mode_info.session_name;
                false
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
        match self.mode {
            Mode::List => self.handle_list_key(key),
            Mode::Input => self.handle_input_key(key),
            Mode::Sessions => self.handle_sessions_key(key),
        }
    }

    fn handle_list_key(&mut self, key: KeyWithModifier) -> bool {
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
            BareKey::Enter if key.has_no_modifiers() => self.activate_selected(),
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

    fn handle_input_key(&mut self, key: KeyWithModifier) -> bool {
        let ctrl = key.has_modifiers(&[KeyModifier::Ctrl]);
        match key.bare_key {
            BareKey::Esc if key.has_no_modifiers() => {
                self.cancel_input();
                true
            },
            BareKey::Char('c') if ctrl => {
                self.cancel_input();
                true
            },
            BareKey::Enter if key.has_no_modifiers() => {
                if self.input.trim().is_empty() {
                    return false;
                }
                let Some(index) = self.pending else {
                    self.cancel_input();
                    return true;
                };
                let arg = std::mem::take(&mut self.input);
                self.mode = Mode::List;
                self.pending = None;
                self.execute(index, &arg);
                false
            },
            BareKey::Backspace if key.has_no_modifiers() => {
                self.input.pop();
                true
            },
            BareKey::Char('u') if ctrl => {
                self.input.clear();
                true
            },
            BareKey::Char(c) if key.has_no_modifiers() && !c.is_control() => {
                self.input.push(c);
                true
            },
            _ => false,
        }
    }

    fn handle_sessions_key(&mut self, key: KeyWithModifier) -> bool {
        let ctrl = key.has_modifiers(&[KeyModifier::Ctrl]);
        match key.bare_key {
            BareKey::Esc if key.has_no_modifiers() => {
                self.leave_session_picker();
                true
            },
            BareKey::Char('c') if ctrl => {
                self.leave_session_picker();
                true
            },
            BareKey::Enter if key.has_no_modifiers() => {
                self.switch_selected_session();
                false
            },
            BareKey::Down if key.has_no_modifiers() => {
                let len = self.filtered_sessions().len();
                self.move_selection_in(1, len);
                true
            },
            BareKey::Up if key.has_no_modifiers() => {
                let len = self.filtered_sessions().len();
                self.move_selection_in(-1, len);
                true
            },
            BareKey::Tab if key.has_modifiers(&[KeyModifier::Shift]) => {
                let len = self.filtered_sessions().len();
                self.move_selection_in(-1, len);
                true
            },
            BareKey::Tab if key.has_no_modifiers() => {
                let len = self.filtered_sessions().len();
                self.move_selection_in(1, len);
                true
            },
            BareKey::Char('n' | 'j') if ctrl => {
                let len = self.filtered_sessions().len();
                self.move_selection_in(1, len);
                true
            },
            BareKey::Char('p' | 'k') if ctrl => {
                let len = self.filtered_sessions().len();
                self.move_selection_in(-1, len);
                true
            },
            BareKey::Char('r') if ctrl => {
                self.refresh_sessions();
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

    /// Open the interactive session picker (from the command list, or directly
    /// via the `leader S` keybind).
    fn open_session_picker(&mut self, root: bool) {
        self.session_picker_root = root;
        self.mode = Mode::Sessions;
        self.query.clear();
        self.selected = 0;
        rename_plugin_pane(self.plugin_id, "Sessions");
        self.refresh_sessions();
    }

    fn leave_session_picker(&mut self) {
        if self.session_picker_root {
            close_self();
        } else {
            self.mode = Mode::List;
            self.query.clear();
            self.selected = 0;
            rename_plugin_pane(self.plugin_id, "Commands");
        }
    }

    fn refresh_sessions(&mut self) {
        match get_session_list() {
            Ok(snapshot) => {
                let mut sessions: Vec<SessionEntry> = snapshot
                    .live_sessions
                    .into_iter()
                    .map(|session| {
                        let tabs = session.tabs.len();
                        let clients = session.connected_clients;
                        SessionEntry {
                            name: session.name,
                            detail: format!(
                                "{} tab{}, {} client{}",
                                tabs,
                                plural(tabs),
                                clients,
                                plural(clients)
                            ),
                            current: session.is_current_session,
                        }
                    })
                    .collect();
                sessions.extend(snapshot.resurrectable_sessions.into_iter().map(
                    |(name, age)| SessionEntry {
                        name,
                        detail: format!("exited · {}", humanize_age(age)),
                        current: false,
                    },
                ));
                self.session_error = None;
                self.sessions = sessions;
            },
            Err(error) => {
                self.session_error = Some(error);
                self.sessions.clear();
            },
        }
        self.selected = 0;
    }

    fn switch_selected_session(&mut self) {
        let filtered = self.filtered_sessions();
        let Some(&index) = filtered.get(self.selected.min(filtered.len().saturating_sub(1))) else {
            return;
        };
        let (name, current) = {
            let entry = &self.sessions[index];
            (entry.name.clone(), entry.current)
        };
        close_self();
        // Attaching to the session we are already in errors in the server, so
        // selecting the current entry just closes the picker.
        if !current {
            switch_session(Some(&name));
        }
    }

    fn filtered_sessions(&self) -> Vec<usize> {
        if self.query.trim().is_empty() {
            return (0..self.sessions.len()).collect();
        }
        let mut scored: Vec<(i32, usize)> = self
            .sessions
            .iter()
            .enumerate()
            .filter_map(|(index, entry)| {
                fuzzy_score(&self.query, &entry.name).map(|score| (score, index))
            })
            .collect();
        scored.sort_by(|a, b| b.0.cmp(&a.0));
        scored.into_iter().map(|(_, index)| index).collect()
    }

    /// Enter in list mode: run immediately, or open a prompt/picker for an
    /// argument. Returns whether the palette must be re-rendered (true when we
    /// switched into a new mode; false when the command ran and closed us).
    fn activate_selected(&mut self) -> bool {
        let filtered = self.filtered();
        let Some(&index) = filtered.get(self.selected.min(filtered.len().saturating_sub(1))) else {
            close_self();
            return false;
        };
        if matches!(COMMANDS[index].exec, Exec::SessionPicker) {
            self.open_session_picker(false);
            true
        } else if COMMANDS[index].prompt.is_some() {
            self.pending = Some(index);
            self.input.clear();
            self.mode = Mode::Input;
            true
        } else {
            self.execute(index, "");
            false
        }
    }

    fn cancel_input(&mut self) {
        self.input.clear();
        self.pending = None;
        self.mode = Mode::List;
    }

    fn move_selection(&mut self, delta: isize) {
        let len = self.filtered().len();
        self.move_selection_in(delta, len);
    }

    fn move_selection_in(&mut self, delta: isize, len: usize) {
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

    fn execute(&self, index: usize, arg: &str) {
        let Some(command) = COMMANDS.get(index) else {
            close_self();
            return;
        };

        // Close first: zellij processes shim messages in order, so the action
        // (and any session switch) then applies without the palette lingering
        // in the session we are leaving.
        close_self();
        // Only prompt-taking commands append an argument; bare commands must
        // not receive the empty positional (clap would reject it).
        let has_arg = command.prompt.is_some();
        match command.exec {
            Exec::Action(prefix) => {
                let mut argv: Vec<&str> = vec![self.zellij_bin.as_str(), "action"];
                argv.extend_from_slice(prefix);
                if has_arg {
                    argv.push(arg);
                }
                run_command(&argv, BTreeMap::new());
            },
            Exec::Shell(prefix) => {
                let mut argv: Vec<&str> = vec![self.zellij_bin.as_str(), "action"];
                argv.extend_from_slice(prefix);
                argv.push("--");
                argv.push(self.shell_bin.as_str());
                argv.push("-lc");
                argv.push(arg);
                run_command(&argv, BTreeMap::new());
            },
            Exec::SwitchSession => switch_session(Some(arg)),
            // Session mutations go through the CLI rather than the plugin API.
            // The plugin-API variants (`rename_session`/`kill_sessions`/…) run
            // `route_action`/`apply_action` on the plugin's own wasm thread and
            // wait for the screen to finish, which can stall the UI (freezes on
            // rename). A separate `zellij` process talks to the server over IPC
            // instead, so it can never block the plugin thread.
            Exec::RenameSession => {
                // zellij's rename leaves the old name in the server's
                // `peer_sessions_cache`, so a later rename back to that name is
                // refused with "A session by this name already exists". Calling
                // the plugin API `get_session_list` pushes a rescan
                // (`ScreenInstruction::UpdateSessionInfos`) that rebuilds the
                // cache and clears the stale entry, so refresh before renaming.
                let _ = get_session_list();
                self.run_zellij(&["action", "rename-session", arg]);
            },
            Exec::KillSession => {
                // Never kill the session we are running in: that would take the
                // client (and this palette) down with it.
                if self.session_name.as_deref() != Some(arg) {
                    self.run_zellij(&["kill-session", arg]);
                }
            },
            Exec::KillCurrentSession => {
                if arg.trim() != "yes" {
                    return;
                }
                self.kill_and_delete_current_session();
            },
            Exec::DeleteDeadSession => {
                self.run_zellij(&["delete-session", arg]);
            },
            // The picker is opened by `activate_selected`, never executed.
            Exec::SessionPicker => {},
        }
    }

    /// Run `zellij <args>` as a separate process.
    fn run_zellij(&self, args: &[&str]) {
        let mut argv: Vec<&str> = vec![self.zellij_bin.as_str()];
        argv.extend_from_slice(args);
        run_command(&argv, BTreeMap::new());
    }

    /// Kill and delete the session we are running in. The `zellij` process is
    /// detached with `setsid` so that killing the session (which tears down the
    /// server that spawned it) does not also kill the follow-up delete.
    fn kill_and_delete_current_session(&self) {
        let Some(name) = self.session_name.clone() else {
            return;
        };
        // Pass the name through the environment rather than as a shell
        // positional: `$argv[1]` is fish-only and `$1` is POSIX-only, but
        // `$VAR` expands in both, so this no longer depends on which shell is
        // configured.
        let script = format!(
            "{} kill-session \"$ZL_TARGET\" >/dev/null 2>&1; sleep 1; {} delete-session \"$ZL_TARGET\" >/dev/null 2>&1",
            self.zellij_bin, self.zellij_bin
        );
        let argv: Vec<&str> = vec![
            self.setsid_bin.as_str(),
            "-f",
            self.shell_bin.as_str(),
            "-c",
            script.as_str(),
        ];
        let mut env = BTreeMap::new();
        env.insert("ZL_TARGET".to_owned(), name);
        run_command(&argv, env);
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

        let mut lines: Vec<String> = Vec::with_capacity(rows);
        match self.mode {
            Mode::List => self.draw_list(&mut lines, rows, cols, bg, fg_mid, accent, bg_subtle),
            Mode::Input => self.draw_input(&mut lines, rows, cols, bg, fg_mid, accent, bg_subtle),
            Mode::Sessions => {
                self.draw_sessions(&mut lines, rows, cols, bg, fg_mid, accent, bg_subtle)
            },
        }

        print!("\u{1b}[2J");
        for (index, line) in lines.iter().enumerate().take(rows) {
            print!("\u{1b}[{};1H{}", index + 1, line);
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn draw_list(
        &self,
        lines: &mut Vec<String>,
        rows: usize,
        cols: usize,
        bg: Rgb,
        fg_mid: Rgb,
        accent: Rgb,
        bg_subtle: Rgb,
    ) {
        let filtered = self.filtered();
        let list_rows = rows.saturating_sub(3); // query + spacer + help
        let start = if list_rows == 0 {
            0
        } else {
            self.selected.saturating_sub(list_rows - 1)
        };

        lines.push(input_row(&format!(" > {}", self.query), cols, accent, bg, true));
        lines.push(row("", cols, fg_mid, bg, false));
        for slot in 0..list_rows {
            let index = start + slot;
            if index >= filtered.len() {
                lines.push(row("", cols, fg_mid, bg, false));
                continue;
            }
            let command = &COMMANDS[filtered[index]];
            let marker = if command.prompt.is_some() { "…" } else { " " };
            let text = format!(
                " {marker} {:<22} {}",
                truncate(command.name, 22),
                command.desc
            );
            if index == self.selected {
                lines.push(row(&text, cols, accent, bg_subtle, true));
            } else {
                lines.push(row(&text, cols, fg_mid, bg, false));
            }
        }
        lines.push(row(HELP, cols, fg_mid, bg, false));
    }

    #[allow(clippy::too_many_arguments)]
    fn draw_input(
        &self,
        lines: &mut Vec<String>,
        rows: usize,
        cols: usize,
        bg: Rgb,
        fg_mid: Rgb,
        accent: Rgb,
        bg_subtle: Rgb,
    ) {
        let command = self.pending.and_then(|index| COMMANDS.get(index));
        let name = command.map(|command| command.name).unwrap_or("");
        let desc = command.map(|command| command.desc).unwrap_or("");
        let prompt = command
            .and_then(|command| command.prompt)
            .unwrap_or("value ›");

        lines.push(row(&format!(" {name}"), cols, accent, bg, true));
        lines.push(row(&format!(" {desc}"), cols, fg_mid, bg, false));
        lines.push(input_row(
            &format!(" {prompt} {}", self.input),
            cols,
            accent,
            bg_subtle,
            true,
        ));
        for _ in 4..rows.saturating_sub(1) {
            lines.push(row("", cols, fg_mid, bg, false));
        }
        if rows > 1 {
            lines.push(row(HELP_INPUT, cols, fg_mid, bg, false));
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn draw_sessions(
        &self,
        lines: &mut Vec<String>,
        rows: usize,
        cols: usize,
        bg: Rgb,
        fg_mid: Rgb,
        accent: Rgb,
        bg_subtle: Rgb,
    ) {
        let filtered = self.filtered_sessions();
        let list_rows = rows.saturating_sub(3); // header + spacer + help
        let start = if list_rows == 0 {
            0
        } else {
            self.selected.saturating_sub(list_rows - 1)
        };

        lines.push(input_row(
            &format!(" sessions > {}", self.query),
            cols,
            accent,
            bg,
            true,
        ));
        lines.push(row("", cols, fg_mid, bg, false));
        if let Some(error) = &self.session_error {
            lines.push(row(&format!(" ! {error}"), cols, fg_mid, bg, false));
            for _ in 3..rows.saturating_sub(1) {
                lines.push(row("", cols, fg_mid, bg, false));
            }
        } else {
            for slot in 0..list_rows {
                let index = start + slot;
                if index >= filtered.len() {
                    lines.push(row("", cols, fg_mid, bg, false));
                    continue;
                }
                let entry = &self.sessions[filtered[index]];
                let marker = if entry.current { "•" } else { " " };
                let text = format!(
                    " {marker} {:<24} {}",
                    truncate(&entry.name, 24),
                    entry.detail
                );
                if index == self.selected {
                    lines.push(row(&text, cols, accent, bg_subtle, true));
                } else {
                    lines.push(row(&text, cols, fg_mid, bg, false));
                }
            }
        }
        lines.push(row(HELP_SESSIONS, cols, fg_mid, bg, false));
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

/// A row with a block caret (an inverse-video space) appended. Used for the
/// lines the user types into: zellij does not draw a terminal cursor for plugin
/// panes, so the caret is rendered as text instead.
fn input_row(text: &str, cols: usize, fg: Rgb, bg: Rgb, bold: bool) -> String {
    let text = truncate(text, cols.saturating_sub(1));
    let len = text.chars().count();
    let pad = cols.saturating_sub(len + 1);
    let bold = if bold { "\u{1b}[1m" } else { "" };
    format!(
        "{bold}\u{1b}[38;2;{};{};{}m\u{1b}[48;2;{};{};{}m{text}\u{1b}[7m \u{1b}[27m{}",
        fg.0,
        fg.1,
        fg.2,
        bg.0,
        bg.1,
        bg.2,
        " ".repeat(pad)
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

fn plural(count: usize) -> &'static str {
    if count == 1 { "" } else { "s" }
}

fn humanize_age(age: Duration) -> String {
    let secs = age.as_secs();
    if secs < 60 {
        format!("{secs}s")
    } else if secs < 3600 {
        format!("{}m", secs / 60)
    } else if secs < 86400 {
        format!("{}h", secs / 3600)
    } else {
        format!("{}d", secs / 86400)
    }
}

fn parse_hex(value: &str) -> Option<Rgb> {
    let value = value.trim().trim_start_matches('#');
    let bytes = value.as_bytes();
    // Require exactly 6 ASCII hex digits so the byte-slicing below cannot hit a
    // UTF-8 char boundary (and so odd input is rejected up front).
    if bytes.len() != 6 || !bytes.iter().all(u8::is_ascii_hexdigit) {
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
