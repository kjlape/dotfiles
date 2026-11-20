-- Kaleb's Omarchy/Hyprland overrides, versioned in dotfiles (stow-xdg).
-- Loaded from ~/.config/hypr/hyprland.lua via require("hypr.personal"),
-- after Omarchy defaults and the stock per-topic override files.

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
