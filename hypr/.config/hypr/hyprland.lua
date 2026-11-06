-- Converted from hyprland.conf to hyprland.lua.
-- Official docs used for this translation:
-- Start Here, Monitors, Autostart, Variables, Animations, Binds, Dispatchers,
-- Window Rules, Workspace Rules, Dwindle Layout, Master Layout, XWayland,
-- and Expanding Functionality.

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function shell_stdout(cmd)
    local handle = io.popen(cmd)
    if not handle then
        return nil
    end

    local out = handle:read("*a")
    handle:close()

    if not out then
        return nil
    end

    return trim(out)
end

local nproc = shell_stdout("nproc") or "1"

----------------
---- MONITORS ---
----------------
hl.monitor({
    output = "",
    mode = "2560x1440@144",
    position = "auto",
    scale = "auto",
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("NVD_BACKEND", "direct")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- Lua replacement for the shell substitution in the original config.
hl.env("MAKEFLAGS", "-j" .. nproc)

---------------------
---- MY PROGRAMS ----
---------------------
local terminal = "ghostty"
local fileManager = "dolphin"
local menu = "rofi -show drun"

-------------------
---- AUTOSTART ----
-------------------
-- `exec =` runs on config load, so keep it as a top-level async exec.
hl.exec_cmd("hyprshade on vibrance")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment")
    hl.exec_cmd("stow ~/dotfiles/*")

    hl.exec_cmd(terminal)
    hl.exec_cmd("quickshell")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swaybg -i ~/pictures/wallpapers/wallhaven-ogy6zm.jpg")
    hl.exec_cmd("pipewire-pulse")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
})

hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        enable_anr_dialog = false,
    },
})

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.config({
    input = {
        kb_layout = "3ls,us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,

        accel_profile = "flat",
        force_no_accel = true,
        sensitivity = 0,

        repeat_rate = 25,
        repeat_delay = 200,

        touchpad = {
            natural_scroll = false,
        },
    },
})

--------------------
---- DEVICES -------
--------------------
hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(
    mainMod .. " + SHIFT + Print",
    hl.dsp.exec_cmd([[grim -g "$(slurp)" - | tee "$HOME/pictures/screenshots/$(date '+%y%m%d_%H-%M-%S').png" - | wl-copy]])
)

-- Keyboard layout.
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"))

-- Move focus with mainMod + arrow keys.
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9].
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0.
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Resize mode.
hl.bind("ALT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
    hl.bind("h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
    hl.bind("k", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
    hl.bind("j", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Move window mode.
-- Old `swapwindow` maps to hl.dsp.window.swap({ direction = ... }),
-- and old `moveactive` maps to hl.dsp.window.move(..., relative = true).
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.move({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.move({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.move({ x = 0, y = 50, relative = true }), { repeating = true })

-- Scratchpad / special workspace.
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse dragging.
-- `bindm` becomes mouse = true on a regular bind.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())

-- mpd bindings.
-- `bindl` means locked-only.
hl.bind(mainMod .. " + F7", hl.dsp.exec_cmd("mpc prev"), { locked = true })
hl.bind(mainMod .. " + F8", hl.dsp.exec_cmd("mpc next"), { locked = true })
hl.bind(mainMod .. " + F9", hl.dsp.exec_cmd("mpc toggle"), { locked = true })
hl.bind(mainMod .. " + F10", hl.dsp.exec_cmd("mpc volume -5"), { locked = true })
hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd("mpc volume +5"), { locked = true })

-- Laptop multimedia keys.
-- `bindel` means locked + repeating.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

------------------------------
---- WINDOWS AND WORKSPACES ---
------------------------------
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})
