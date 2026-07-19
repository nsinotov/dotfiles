-- Langmapper: Cyrillic twins for all keymaps (complements langmap in options.lua)
--
-- Why two mechanisms?
--   langmap (options.lua) — translates raw keystrokes for Neovim built-in commands:
--     navigation (hjkl), operators (d/c/y), motions, text objects. Works for any
--     unmapped Normal-mode command.
--   langmapper (this file) — handles user-defined keymaps: <leader> sequences,
--     plugin bindings, which-key groups. langmap does not apply when Neovim is
--     resolving a key sequence against the keymap table, so without this plugin
--     <leader>+key sequences silently fail under a Cyrillic input method.
--
-- How it works:
--   hack_keymap = true wraps vim.keymap.set / nvim_set_keymap so every mapping
--   registered by any plugin automatically gets a Cyrillic twin. Combined with
--   priority = 1 (load before all other plugins), this covers lazy-loaded plugins
--   too. automapping() at VimEnter catches vim-script and pre-existing keymaps.
--
-- Insert mode is excluded throughout: Cyrillic typing in Insert must be unaffected.

return {
  "Wansmer/langmapper.nvim",
  lazy = false,
  priority = 1, -- must be first so hack_keymap wraps vim.keymap.set before any plugin uses it
  config = function()
    -- Layout strings are split to avoid Lua raw-string delimiter conflicts (]])
    -- and to make the positional mapping human-readable.
    --
    -- Uppercase row (33 chars): Shift+key positions, QWERTY order
    --   Q W E R T Y U I O P { } A S D F G H J K L : " Z X C V B N M < > ~
    local default_upper = 'QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>~'
    local ua_ru_upper   = 'ЙЦУКЕНГШЩЗХЇФІВАПРОЛДЖЄЯЧСМИТЬБЮҐ'
    --   Й Ц У К Е Н Г Ш Щ З Х Ї Ф І В А П Р О Л Д Ж Є Я Ч С М И Т Ь Б Ю Ґ

    -- Lowercase row (33 chars): unshifted positions, QWERTY order
    --   q w e r t y u i o p [ ] a s d f g h j k l ; ' z x c v b n m , . `
    local default_lower = "qwertyuiop[]asdfghjkl;'zxcvbnm,." .. "`"
    local ua_ru_lower   = "йцукенгшщзхїфівапролджєячсмитьбю" .. "ґ"
    --   й ц у к е н г ш щ з х ї ф і в а п р о л д ж є я ч с м и т ь б ю   ґ
    --
    -- Ukrainian characters take the positions that differ from Russian:
    --   s/S → і/І  (Russian: ы/Ы)    ' → є  (Russian: э)
    --   ]/} → ї/Ї  (Russian: ъ/Ъ)    ` → ґ  (Russian: ё)

    require("langmapper").setup({
      hack_keymap = true,

      -- Do not translate Insert-mode keymaps: Cyrillic typing must remain intact.
      disable_hack_modes = { "i" },

      -- Hide Cyrillic twins from which-key help panel
      custom_desc = function() return "which_key_ignore" end,

      -- Modes in which Cyrillic twins are created during automapping.
      automapping_modes = { "n", "v", "x", "o" },

      -- Full QWERTY layout (66 chars = 33 uppercase + 33 lowercase).
      default_layout = default_upper .. default_lower,

      -- Restrict to ua-ru only: langmapper ships a built-in 69-char 'ru' layout that would
      -- be merged in by tbl_deep_extend and then fail tr() against our 66-char default_layout.
      use_layouts = { "ua-ru" },

      layouts = {
        ["ua-ru"] = {
          -- TIS input source ID (informational; IM switching is handled by im-select.nvim)
          id = "org.sil.ukelele.keyboardlayout.ua_ru_layout.ua–ru–layout",
          -- Matching 66-char UA-RU layout string.
          layout = ua_ru_upper .. ua_ru_lower,
        },
      },
    })

    -- automapping() runs after all plugins have registered their keymaps and catches
    -- any vim-script or pre-existing mappings that hack_keymap did not see.
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        require("langmapper").automapping({ global = true, buffer = true })
      end,
    })
  end,
}
