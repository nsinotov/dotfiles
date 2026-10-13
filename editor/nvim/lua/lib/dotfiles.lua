-- Dotfiles settings for Neovim, read from the file install.sh writes
-- (~/.local/state/dotfiles/settings.lua): enabled modules, local extension
-- dirs, optional LazyVim extras (NVIM_EXTRAS) and plugins (NVIM_PLUGINS).
local M = {}

local settings

local function load()
  local state = os.getenv("XDG_STATE_HOME") or (vim.env.HOME .. "/.local/state")
  local ok, result = pcall(dofile, state .. "/dotfiles/settings.lua")
  settings = ok and type(result) == "table" and result or {}
  for _, key in ipairs({ "modules", "local_dirs", "nvim_extras", "nvim_plugins" }) do
    settings[key] = settings[key] or {}
  end
end

local function get(key)
  if not settings then
    load()
  end
  return settings[key]
end

--- True when the module is listed in DOTFILES_MODULES (as of the last install.sh run)
---@param name string
function M.module(name)
  return vim.tbl_contains(get("modules"), name)
end

--- Lazy specs for NVIM_EXTRAS (LazyVim extras such as "lang.prisma") and
--- NVIM_PLUGINS (GitHub "owner/repo" names, installed with default settings)
function M.optional_specs()
  local specs = {}
  for _, extra in ipairs(get("nvim_extras")) do
    table.insert(specs, { import = "lazyvim.plugins.extras." .. extra })
  end
  for _, repo in ipairs(get("nvim_plugins")) do
    table.insert(specs, { repo })
  end
  return specs
end

--- Lazy specs from local extension dirs: every <dir>/nvim/plugins/*.lua file
--- returns a spec, like files in lua/plugins/
function M.local_specs()
  local specs = {}
  for _, dir in ipairs(get("local_dirs")) do
    for _, file in ipairs(vim.fn.glob(dir .. "/nvim/plugins/*.lua", false, true)) do
      local ok, spec = pcall(dofile, file)
      if ok then
        table.insert(specs, spec)
      else
        vim.notify("dotfiles: " .. file .. ": " .. spec, vim.log.levels.ERROR)
      end
    end
  end
  return specs
end

--- Run <dir>/nvim/init.lua from each local extension dir (called after startup)
function M.load_local_init()
  for _, dir in ipairs(get("local_dirs")) do
    local file = dir .. "/nvim/init.lua"
    if (vim.uv or vim.loop).fs_stat(file) then
      local ok, err = pcall(dofile, file)
      if not ok then
        vim.notify("dotfiles: " .. file .. ": " .. err, vim.log.levels.ERROR)
      end
    end
  end
end

return M
