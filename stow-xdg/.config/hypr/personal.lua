-- Kaleb's Omarchy/Hyprland overrides, versioned in dotfiles (stow-xdg).
-- Loaded from ~/.config/hypr/hyprland.lua via require("hypr.personal"),
-- after Omarchy defaults and the stock per-topic override files.

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end

----------------------------------------------------------------------
-- Look'n'feel (portable)
----------------------------------------------------------------------
hl.config({
  decoration = {
    rounding = 4,
    -- Dim unfocused windows.
    dim_inactive = true,
    dim_strength = 0.15,
    -- Blur under windows (frosted glass effect).
    blur = {
      enabled = true,
      popups_ignorealpha = 0, -- blur all windows
      size = 20,              -- blur radius in pixels
    },
  },
  scrolling = {
    -- See only one column per screen instead of two.
    column_width = 0.60,
  },
})

-- OBS projector camera bubble.
hl.window_rule({
  name = "camera-bubble",
  match = { title = "Projector - Source: Video Capture Device.*" },
  float = true,
  pin = true,
  size = { "320", "180" },
  rounding = 20,
  border_size = 0,
  no_shadow = true,
})

----------------------------------------------------------------------
-- Bindings (portable)
----------------------------------------------------------------------
-- Paste plain text without formatting (Super+Shift+V).
-- 1. Rewrite the clipboard keeping only text/plain (drops rich text/HTML)
-- 2. Inject a compositor-level Ctrl+V into the focused window, using the same
--    down/up split as Omarchy's default universal clipboard bindings.
--    (wtype won't work: Chromium ignores virtual-keyboard input.)
o.bind("SUPER + SHIFT + V", "Paste (plain text)", function()
  os.execute("sh -c 'wl-paste --type text/plain | wl-copy' &")
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "V", state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "V", state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end, { timeout = 100, type = "oneshot" })
end)

-- Capture chord for compact keyboards without a PrtSc key.
-- Mirrors the PRINT bindings: Screenshot / Screenrecording / OCR.
o.bind("SUPER + ALT + C", "Screenshot", "omarchy-capture-screenshot")
o.bind("SUPER + ALT + V", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + ALT + X", "Extract text (OCR) from screenshot", "omarchy-capture-text")

----------------------------------------------------------------------
-- External peripherals (portable; harmless when the device is absent)
----------------------------------------------------------------------
-- External ProtoArc trackpad is classified as a mouse, so the touchpad block doesn't apply.
hl.device({
  name = "protoarc-xk01-tp-mouse",
  natural_scroll = true,
})

-- ProtoArc keyboard reports PC layout (Alt next to space); swap Alt/Super to get Mac-style Cmd position.
for _, name in ipairs({ "protoarc-xk01-tp-keyboard", "protoarc-xk01-tp-keyboard-1" }) do
  hl.device({
    name = name,
    kb_layout = "us",
    kb_options = "compose:caps,shift:both_capslock_cancel,altwin:swap_alt_win",
  })
end

----------------------------------------------------------------------
-- Machine-specific
----------------------------------------------------------------------
local function read_file(path)
  local f = io.open(path, "r")
  if not f then return "" end
  local content = f:read("*a")
  f:close()
  return content
end

local hostname = (read_file("/etc/hostname"):gsub("%s+", ""))

-- True if the kernel reports a built-in touchpad/trackpad.
local function has_touchpad()
  for line in read_file("/proc/bus/input/devices"):gmatch("[^\n]+") do
    if line:match("^N: Name=") and (line:lower():find("touchpad", 1, true) or line:lower():find("trackpad", 1, true)) then
      return true
    end
  end
  return false
end

-- salem: MacBook Pro laptop.
if hostname == "salem" then
  -- Built-in trackpad settings and toggles.
  if has_touchpad() then
    hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
    hl.config({
      input = {
        touchpad = {
          natural_scroll = true,
          clickfinger_behavior = true, -- two-finger click = right-click
          scroll_factor = 1,
          disable_while_typing = true,
          drag_3fg = 1,
        },
      },
    })

    o.bind("SUPER + F9", "Switch Trackpad Off", "omarchy toggle touchpad off")
    o.bind("SUPER + SHIFT + F9", "Switch Trackpad On", "omarchy toggle touchpad on")
  end
end
