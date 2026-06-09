local G = require("generated")

local mod = "SUPER"
local screenshotDir = G.screenshot_dir
local specialWS = G.special_workspace

-- ── Input ──────────────────────────────────────────────────────────────
hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    natural_scroll = false,
    touchpad = {
      natural_scroll = true,
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

-- ── Cursor ─────────────────────────────────────────────────────────────
hl.config({ cursor = { hide_on_key_press = true } })

-- ── Autostart ──────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
  hl.exec_cmd("bash -lc 'for i in {1..30}; do awww img " .. G.wallpaper .. " && exit 0; sleep 0.1; done; exit 1'")
  hl.exec_cmd("qs -n -c hyprland")
  hl.exec_cmd("nm-applet --indicator")
end)

-- ── Environment ────────────────────────────────────────────────────────
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ── General ────────────────────────────────────────────────────────────
hl.config({
  general = {
    gaps_in = 8,
    gaps_out = 16,
    border_size = 0,
    resize_on_border = false,
    allow_tearing = G.isDesktop,
    layout = "dwindle",
    col = {
      active_border = "rgb(" .. G.accent .. ")",
      inactive_border = "rgb(" .. G.border .. ")",
    },
  },
})

-- ── Decoration ─────────────────────────────────────────────────────────
hl.config({
  decoration = {
    rounding = 16,
    dim_inactive = true,
    dim_strength = 0.15,
    blur = {
      enabled = false,
      xray = true,
      special = false,
      passes = 2,
      size = 6,
      noise = 0.02,
      brightness = 0.9,
      contrast = 0.8,
      popups = true,
    },
    shadow = {
      enabled = false,
      range = 12,
      render_power = 3,
      color = "rgba(00000055)",
    },
  },
})

-- ── Animations ─────────────────────────────────────────────────────────
hl.curve("m3_expressive",     { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("m3_expressive_out", { type = "bezier", points = { { 0.3, 0 }, { 0, 1 } } })

hl.config({ animations = { enabled = true } })

hl.animation({ leaf = "global",           enabled = true, speed = 10,   bezier = "m3_expressive" })
hl.animation({ leaf = "windows",           enabled = true, speed = 2.2,  bezier = "m3_expressive",     style = "popin 40%" })
hl.animation({ leaf = "windowsIn",         enabled = true, speed = 2.2,  bezier = "m3_expressive",     style = "popin 40%" })
hl.animation({ leaf = "windowsOut",        enabled = true, speed = 1.8,  bezier = "m3_expressive_out", style = "popin 70%" })
hl.animation({ leaf = "border",            enabled = true, speed = 1.5,  bezier = "m3_expressive" })
hl.animation({ leaf = "fadeIn",            enabled = true, speed = 1.8,  bezier = "m3_expressive" })
hl.animation({ leaf = "fadeOut",           enabled = true, speed = 1.8,  bezier = "m3_expressive" })
hl.animation({ leaf = "fade",              enabled = true, speed = 1.8,  bezier = "m3_expressive" })
hl.animation({ leaf = "layers",            enabled = true, speed = 2,    bezier = "m3_expressive",     style = "slide" })
hl.animation({ leaf = "layersIn",          enabled = true, speed = 2,    bezier = "m3_expressive",     style = "slide" })
hl.animation({ leaf = "layersOut",         enabled = true, speed = 1.5,  bezier = "m3_expressive_out", style = "slide" })
hl.animation({ leaf = "fadeLayersIn",      enabled = true, speed = 1.5,  bezier = "m3_expressive" })
hl.animation({ leaf = "fadeLayersOut",     enabled = true, speed = 1.5,  bezier = "m3_expressive" })
hl.animation({ leaf = "workspaces",        enabled = true, speed = 2.5,  bezier = "m3_expressive",     style = "slide" })
hl.animation({ leaf = "specialWorkspace",  enabled = true, speed = 2.5,  bezier = "m3_expressive",     style = "slide" })

-- ── Layout ─────────────────────────────────────────────────────────────
hl.config({ dwindle = { preserve_split = true } })

-- ── Misc ───────────────────────────────────────────────────────────────
hl.config({
  misc = {
    vfr = true,
    disable_hyprland_logo = true,
    vrr = 1,
    enable_swallow = true,
    swallow_regex = "^(foot|Alacritty|kitty)$",
  },
})

-- ── Monitors ───────────────────────────────────────────────────────────
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- ── Workspaces ─────────────────────────────────────────────────────────
for i = 1, 5 do
  hl.workspace_rule({ workspace = tostring(i), persistent = true, default = (i == 1) })
end

-- ── Binds config ───────────────────────────────────────────────────────
hl.config({ binds = { allow_workspace_cycles = true } })

-- ── Window rules (v1) ──────────────────────────────────────────────────
hl.window_rule({ name = "float-borders",     match = { float = true },          border_size = 2 })
hl.window_rule({ name = "pavucontrol",       match = { class = "org.pulseaudio.pavucontrol" }, float = true })
hl.window_rule({ name = "blueman",           match = { class = ".blueman-manager-wrapped" },   float = true })
hl.window_rule({ name = "pip",               match = { title = "^(Picture-in-Picture)$" },     float = true, pin = true, keepaspectratio = true, move = "72% 72%", size = "25% 25%" })
hl.window_rule({ name = "steam",             match = { class = "^(steam_app_.*)$" },            immediate = true })
hl.window_rule({ name = "warframe",          match = { class = "^(warframe.exe)$" },            immediate = true })
hl.window_rule({ name = "minecraft",         match = { class = "^(minecraft)$" },               immediate = true })
hl.window_rule({ name = "qemu",              match = { class = "^(qemu)$" },                    immediate = true })

-- ── Window rules (v2) ──────────────────────────────────────────────────
hl.window_rule({ name = "save-as",                match = { title = "^(Save As.*)$" },                                 float = true, size = "60% 60%", move = "20% 20%" })
hl.window_rule({ name = "upload-file",            match = { title = "^(Upload File.*)$" },                             float = true, size = "60% 60%", move = "20% 20%" })
hl.window_rule({ name = "float-size",             match = { float = true },                                            size = "50% 50%" })
hl.window_rule({ name = "special-opacity",        match = { workspace = "special:" .. specialWS },                       opacity = "0.8 0.8" })
hl.window_rule({ name = "suppress-maximize",      match = { class = ".*" },                                            suppress_event = "maximize" })
hl.window_rule({ name = "no-focus-xwayland",      match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, no_focus = true })
hl.window_rule({ name = "spotify-special",        match = { class = "^(Spotify|spotify)$" },                           workspace = "special" })
hl.window_rule({ name = "pip-noblur",             match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, noblur = true })
hl.window_rule({ name = "pavucontrol-noblur",     match = { class = "^(org\\.pulseaudio\\.pavucontrol)$" },            noblur = true })
hl.window_rule({ name = "satty",                  match = { class = "^(satty|com\\.gabm\\.satty)$" },                 float = true, size = "60% 60%", center = true })

-- ── Layer rules ────────────────────────────────────────────────────────
hl.layer_rule({ name = "quickshell-bar", match = { namespace = "quickshell-bar" }, ignore_zero = true })

-- ── Screenshot commands ────────────────────────────────────────────────
local screenshotFull = "mkdir -p " .. screenshotDir .. "; "
  .. G.satty_focus .. " & grim -o \"$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')\" - | "
  .. G.satty_capture

local screenshotRegion = "mkdir -p " .. screenshotDir .. "; "
  .. "region=$(hyprctl -j clients | jq -r --argjson ws $(hyprctl -j activeworkspace | jq -r '.id') '.[] | select(.mapped and .workspace.id == $ws) | (.at[0]|tostring) + \",\" + (.at[1]|tostring) + \" \" + (.size[0]|tostring) + \"x\" + (.size[1]|tostring)' | slurp); "
  .. "[ -n \"$region\" ] && { " .. G.satty_focus .. " & grim -g \"$region\" - | " .. G.satty_capture .. "; }"

-- ── Keybinds ───────────────────────────────────────────────────────────
hl.bind(mod .. " + RETURN",             hl.dsp.exec_cmd("foot"))
hl.bind(mod .. " + Q",                  hl.dsp.window.close())
hl.bind(mod .. " + E",                  hl.dsp.exec_cmd("foot yazi"))
hl.bind(mod .. " + V",                  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + G",                  hl.dsp.exec_cmd("toggle-focus-mode-hyprland"))
hl.bind(mod .. " + SPACE",              hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mod .. " + P",                  hl.dsp.exec_cmd("qs -c hyprland ipc call controlpanel toggle"))
hl.bind(mod .. " + DELETE",             hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + R",          hl.dsp.exec_cmd("reload-all-hyprland"))
hl.bind(mod .. " + F",                  hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + h",                  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + l",                  hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + k",                  hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + j",                  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key,                hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key,        hl.dsp.window.move({ workspace = i }))
  hl.bind(mod .. " + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, silent = true }))
  hl.bind(mod .. " + ALT + " .. key,          hl.dsp.window.move({ workspace = i, silent = true }))
end

hl.bind(mod .. " + `",                   hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + TAB",                 hl.dsp.focus({ workspace = "previous" }))
hl.bind(mod .. " + W",                   hl.dsp.workspace.toggle_special(specialWS))
hl.bind(mod .. " + SHIFT + W",           hl.dsp.window.move({ workspace = "special:" .. specialWS }))
hl.bind(mod .. " + CTRL + SHIFT + W",    hl.dsp.window.move({ workspace = "special:" .. specialWS, silent = true }))
hl.bind(mod .. " + ALT + W",             hl.dsp.window.move({ workspace = "special:" .. specialWS, silent = true }))

hl.bind(mod .. " + SHIFT + h",           hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + l",           hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + k",           hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + j",           hl.dsp.window.move({ direction = "down" }))

hl.bind(mod .. " + S",                   hl.dsp.exec_cmd(screenshotFull))
hl.bind(mod .. " + SHIFT + S",           hl.dsp.exec_cmd(screenshotRegion))

hl.bind(mod .. " + mouse_down",          hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",            hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mod .. " + mouse:272",           hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273",           hl.dsp.window.resize(), { mouse = true })

hl.bind(mod .. " + CTRL + l",            hl.dsp.window.resize({ size = "10 0" }),  { repeating = true })
hl.bind(mod .. " + CTRL + h",            hl.dsp.window.resize({ size = "-10 0" }), { repeating = true })
hl.bind(mod .. " + CTRL + k",            hl.dsp.window.resize({ size = "0 -10" }), { repeating = true })
hl.bind(mod .. " + CTRL + j",            hl.dsp.window.resize({ size = "0 10" }),  { repeating = true })

if G.isDesktop then
  hl.bind("XF86MonBrightnessUp",         hl.dsp.exec_cmd("ddc-brightness up"),   { repeating = true })
  hl.bind("XF86MonBrightnessDown",       hl.dsp.exec_cmd("ddc-brightness down"), { repeating = true })
else
  hl.bind("XF86MonBrightnessUp",         hl.dsp.exec_cmd("brightnessctl set +5%"),  { repeating = true })
  hl.bind("XF86MonBrightnessDown",       hl.dsp.exec_cmd("brightnessctl set 5%-"),  { repeating = true })
end

hl.bind("XF86AudioRaiseVolume",          hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",          hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),         { locked = true, repeating = true })
hl.bind("XF86AudioMute",                 hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",              hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      { locked = true, repeating = true })
hl.bind("XF86AudioPlay",                 hl.dsp.exec_cmd("playerctl play-pause"),                              { locked = true })
hl.bind("XF86AudioNext",                 hl.dsp.exec_cmd("playerctl next"),                                    { locked = true })
hl.bind("XF86AudioPrev",                 hl.dsp.exec_cmd("playerctl previous"),                                { locked = true })
