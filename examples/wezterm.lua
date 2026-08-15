local wezterm = require("wezterm")
local config = {}

config.default_prog = { "powershell.exe", "-NoLogo" }

-- Optional: use the WebGpu renderer instead of the default OpenGL backend.
-- Needed on some NVIDIA systems where OpenGL crashes (stack overflow in nvoglv64.dll).
config.front_end = "WebGpu"

-- The Shonos fork's plugin/init.lua still searches for the upstream "MLFlexer"
-- keyword, so tell dev.wezterm to substitute it with "Shonos" before requiring.
local dev = wezterm.plugin.require("https://github.com/chrisgve/dev.wezterm")
dev.set_substitutions({ MLFlexer = "Shonos" })

local resurrect = wezterm.plugin.require("https://github.com/Shonos/resurrect.wezterm")

resurrect.state_manager.periodic_save({
  interval_seconds = 900,
  save_workspaces = true,
  save_windows = true,
  save_tabs = true,
})

local function write_current_state()
  local ws = wezterm.mux.get_active_workspace()
  if ws then
    resurrect.state_manager.write_current_state(ws, "workspace")
  end
end

wezterm.on("resurrect.state_manager.periodic_save.finished", write_current_state)
wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)

config.keys = {
  { key = "w", mods = "ALT", action = wezterm.action_callback(function()
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      write_current_state()
    end) },
  { key = "s", mods = "ALT", action = wezterm.action_callback(function()
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      resurrect.window_state.save_window_action()
      write_current_state()
    end) },
  { key = "r", mods = "ALT", action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
        local state_type = string.match(id, "^([^/]+)")
        id = string.match(id, "([^/]+)$")
        id = string.match(id, "(.+)%..+$")
        local opts = {
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        if state_type == "workspace" then
          resurrect.workspace_state.restore_workspace(resurrect.state_manager.load_state(id, "workspace"), opts)
        elseif state_type == "window" then
          resurrect.window_state.restore_window(pane:window(), resurrect.state_manager.load_state(id, "window"), opts)
        elseif state_type == "tab" then
          resurrect.tab_state.restore_tab(pane:tab(), resurrect.state_manager.load_state(id, "tab"), opts)
        end
      end)
    end) },
  { key = "d", mods = "ALT", action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
        resurrect.state_manager.delete_state(id)
      end, { title = "Delete State", description = "Select state to delete" })
    end) },
}

return config
