-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ---- Learning tracker ----
require("lib.learning-tracker")

-- ---- Cyrillic command-line safety net ----
-- Switch to English layout when entering Ex command-line (:).
-- Scoped to ':' only — search (/?) is excluded so Cyrillic searches still work.
-- This is a belt-and-suspenders fix: im-select.nvim's InsertLeave handler should
-- have already restored ABC before Normal mode was entered, but this covers the
-- edge case of a manual IM switch while already in Normal mode.
--
-- Limitations:
--   Timing: macism is an async shell call. If it takes more than one frame, the
--     very first character typed after ':' may still arrive as Cyrillic. This is
--     uncommon in practice; macism is fast and the user typically pauses briefly.
--
--   Search prompt (/ and ?): excluded deliberately so Cyrillic text searches
--     continue to work. Inside the search prompt, langmap does NOT apply (it is
--     command-line mode, not Normal mode), so the IM at the time of typing
--     determines whether you get Latin or Cyrillic characters. With
--     im-select.nvim restoring ABC on InsertLeave, the IM is usually already
--     English when you reach Normal mode and then type '/'.
vim.api.nvim_create_autocmd("CmdlineEnter", {
  callback = function()
    if vim.fn.getcmdtype() == ":" then
      vim.fn.system("macism com.apple.keylayout.ABC")
    end
  end,
})
