local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.color_scheme_dirs = { wezterm.config_dir }
config.color_scheme = "dank"

config.font = wezterm.font("NotoSansM Nerd Font Mono")
config.font_size = 12
config.enable_tab_bar = true
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }
config.window_decorations = "TITLE|RESIZE"

config.keys = {
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
}

return config
