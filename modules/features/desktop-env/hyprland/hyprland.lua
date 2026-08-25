local G = require("generated")

local mod = "SUPER"
local screenshotDir = G.screenshot_dir
local specialWS = G.special_workspace

-- ── Input Configuration ────────────────────────────────────────────────
hl.config({
	input = {
		kb_layout = "us",
		repeat_delay = 200,
		repeat_rate = 35,
		follow_mouse = 1,
		natural_scroll = false,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
		},
	},
})

if G.isDesktop then
	hl.config({
		input = {
			sensitivity = 0,
		},
	})
end

-- ── Cursor Configuration ──────────────────────────────────────────────
hl.config({
	cursor = {
		hide_on_key_press = true,
	},
})

-- ── Autostart Services ─────────────────────────────────────────────────
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"bash -lc 'systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE PATH XDG_DATA_DIRS ELECTRON_OZONE_PLATFORM_HINT && dbus-update-activation-environment --systemd --all && systemctl --user start wayland-session.target graphical-session.target && systemctl --user restart vicinae-server.service xdg-desktop-portal-hyprland xdg-desktop-portal'"
	)
	hl.exec_cmd("QS_BAR=hyprland quickshell &")
	hl.exec_cmd("swaybg -i ~/Pictures/wallpaper -m fill &")
	hl.exec_cmd("nm-applet --indicator &")
end)

-- ── Environment Variables ──────────────────────────────────────────────
hl.env("QS_BAR", "hyprland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")

-- ── General Layout & Styling (Matched to Mango & Niri) ─────────────────
hl.config({
	general = {
		gaps_in = 12,
		gaps_out = 12,
		border_size = 2,
		resize_on_border = true,
		allow_tearing = G.isDesktop,
		layout = "dwindle",
		col = {
			active_border = "rgb(" .. G.accent .. ")",
			inactive_border = "rgb(" .. G.border .. ")",
		},
	},
})

-- ── Decoration Options ─────────────────────────────────────────────────
hl.config({
	decoration = {
		rounding = 12,
		dim_inactive = true,
		dim_strength = 0.15,
		blur = {
			enabled = false,
			xray = true,
			special = false,
			passes = 2,
			size = 6,
		},
		shadow = {
			enabled = false,
		},
	},
})

-- ── Animations ─────────────────────────────────────────────────────────
hl.curve("m3_expressive", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("m3_expressive_out", { type = "bezier", points = { { 0.3, 0 }, { 0, 1 } } })

hl.config({ animations = { enabled = true } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "m3_expressive" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.2, bezier = "m3_expressive", style = "popin 40%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.2, bezier = "m3_expressive", style = "popin 40%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.8, bezier = "m3_expressive_out", style = "popin 70%" })
hl.animation({ leaf = "border", enabled = true, speed = 1.5, bezier = "m3_expressive" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.8, bezier = "m3_expressive" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.8, bezier = "m3_expressive" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "m3_expressive" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "m3_expressive", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "m3_expressive", style = "slide" })

-- ── Layout Presets ─────────────────────────────────────────────────────
hl.config({ dwindle = { preserve_split = true } })

-- ── Gaming & Performance Optimizations ────────────────────────────────
hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = 2, -- Adaptive sync / VRR enabled in fullscreen games
		enable_swallow = true,
		swallow_regex = "^(foot|Alacritty|kitty)$",
		focus_on_activate = true,
	},
})

-- ── Monitors ───────────────────────────────────────────────────────────
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- ── Workspaces ─────────────────────────────────────────────────────────
for i = 1, 5 do
	hl.workspace_rule({ workspace = tostring(i), persistent = true, default = (i == 1) })
end

hl.config({ binds = { allow_workspace_cycles = true } })

-- ── Window Rules & Gaming Tearing Overrides ────────────────────────────
hl.window_rule({ name = "float-borders", match = { float = true }, border_size = 2 })
hl.window_rule({ name = "pavucontrol", match = { class = "org.pulseaudio.pavucontrol" }, float = true })
hl.window_rule({ name = "blueman", match = { class = ".blueman-manager-wrapped" }, float = true })
hl.window_rule({
	name = "pip",
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	pin = true,
	move = "72% 72%",
	size = "25% 25%",
})

-- Immediate low-latency rendering rules for games
hl.window_rule({ name = "steam_game", match = { class = "^(steam_app_.*)$" }, immediate = true })
hl.window_rule({ name = "warframe", match = { class = "^(warframe.exe)$" }, immediate = true })
hl.window_rule({ name = "minecraft", match = { class = "^(minecraft)$" }, immediate = true })
hl.window_rule({ name = "cs2", match = { class = "^(cs2)$" }, immediate = true })
hl.window_rule({ name = "qemu", match = { class = "^(qemu)$" }, immediate = true })

hl.window_rule({
	name = "save-as",
	match = { title = "^(Save As.*)$" },
	float = true,
	size = "60% 60%",
	move = "20% 20%",
})
hl.window_rule({
	name = "upload-file",
	match = { title = "^(Upload File.*)$" },
	float = true,
	size = "60% 60%",
	move = "20% 20%",
})
hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.layer_rule({
	name = "slurp-noanim",
	match = { namespace = "selection" },
	no_anim = true,
})

-- ── Screenshot & OCR Commands ─────────────────────────────────────────
local screenshotCmd =
	'pgrep -x slurp >/dev/null && exit 0; GEOM=$(slurp); [ -n "$GEOM" ] && grim -g "$GEOM" - | tee "$HOME/Pictures/Screenshot_$(date +\'%Y-%m-%d_%H-%M-%S\').png" | wl-copy -t image/png'
local screenshotOcrCmd =
	"pgrep -x slurp >/dev/null && exit 0; GEOM=$(slurp); [ -n \"$GEOM\" ] && grim -g \"$GEOM\" - | tesseract stdin stdout -l eng 2>/dev/null | wl-copy && notify-send 'OCR Complete' 'Text copied to clipboard.'"

-- ── Keybindings (Unified with Mango & Niri) ────────────────────────────
-- Application Launchers
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd("foot"))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("quickshell ipc call command-center toggle"))
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("quickshell ipc call lockscreen lock"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("foot -e yazi"))

-- Window Management
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("hyprctl dispatch togglefloating"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("hyprctl dispatch togglefloating"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd("hyprctl dispatch togglefloating"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Directional Focus (Vim + Arrow Keys)
hl.bind(mod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + Down", hl.dsp.focus({ direction = "down" }))

-- Moving Windows (Vim + Arrow Keys)
hl.bind(mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "down" }))

-- Resizing Windows (Vim + Arrow Keys)
hl.bind(mod .. " + CTRL + h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + j", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + Right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + Down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Monitor Focus
hl.bind(mod .. " + ALT + h", hl.dsp.focus({ monitor = "l" }))
hl.bind(mod .. " + ALT + l", hl.dsp.focus({ monitor = "r" }))
hl.bind(mod .. " + ALT + k", hl.dsp.focus({ monitor = "u" }))
hl.bind(mod .. " + ALT + j", hl.dsp.focus({ monitor = "d" }))
hl.bind(mod .. " + ALT + Left", hl.dsp.focus({ monitor = "l" }))
hl.bind(mod .. " + ALT + Right", hl.dsp.focus({ monitor = "r" }))
hl.bind(mod .. " + ALT + Up", hl.dsp.focus({ monitor = "u" }))
hl.bind(mod .. " + ALT + Down", hl.dsp.focus({ monitor = "d" }))

-- Move Window to Monitor
hl.bind(mod .. " + SHIFT + CTRL + h", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + CTRL + l", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mod .. " + SHIFT + CTRL + k", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mod .. " + SHIFT + CTRL + j", hl.dsp.window.move({ monitor = "d" }))
hl.bind(mod .. " + SHIFT + CTRL + Left", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + CTRL + Right", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mod .. " + SHIFT + CTRL + Up", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mod .. " + SHIFT + CTRL + Down", hl.dsp.window.move({ monitor = "d" }))

-- Workspaces 1-10 Focus & Move
for i = 1, 10 do
	local key = i % 10
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
	hl.bind(mod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, silent = true }))
	hl.bind(mod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, silent = true }))
end

hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + W", hl.dsp.workspace.toggle_special(specialWS))
hl.bind(mod .. " + SHIFT + W", hl.dsp.window.move({ workspace = "special:" .. specialWS }))

-- Screenshots & OCR
hl.bind(mod .. " + S", hl.dsp.exec_cmd("sh -c '" .. screenshotCmd .. "'"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("sh -c '" .. screenshotOcrCmd .. "'"))

-- Mouse Binds
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media & Hardware Keys
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
