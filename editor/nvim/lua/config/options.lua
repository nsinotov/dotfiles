-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- ---- Cyrillic → Latin langmap (RU + UA) ----
-- Translates Cyrillic keystrokes to their QWERTY positional equivalents in
-- Normal, Visual, Select, and Operator-pending modes. Insert mode is untouched.
-- Pairs with im-select.nvim: im-select handles OS IM switching on mode
-- transitions; langmap covers the gap and any manual IM changes in Normal mode.
--
-- langremap is off by default in Neovim, which is correct: langmap applies to
-- raw keystrokes only, not to keys produced by mappings. <leader> sequences
-- therefore work normally — the Cyrillic key after <Space> is a raw keystroke
-- and gets translated before which-key sees it.
--
-- Escaping inside langmap strings (format: fromstring;tostring):
--   ';' in to-string → '\;' in langmap → '\\;' in Lua double-quoted string
--   ',' in to-string → '\,' in langmap → '\\,' in Lua double-quoted string
--   '"' in to-string → not a langmap special char, but needs '\"' in Lua string

vim.opt.langmap = table.concat({
  -- Russian lowercase (33 chars each): й→q  ц→w  у→e  к→r  е→t  н→y  г→u
  --   ш→i  щ→o  з→p  х→[  ъ→]  ф→a  ы→s  в→d  а→f  п→g  р→h  о→j  л→k
  --   д→l  ж→;  э→'  я→z  ч→x  с→c  м→v  и→b  т→n  ь→m  б→,  ю→.  ё→`
  "йцукенгшщзхъфывапролджэячсмитьбюё;qwertyuiop[]asdfghjkl\\;'zxcvbnm\\,.`",

  -- Russian uppercase (33 chars each): Й→Q … Ё→~
  --   Х→{  Ъ→}  Ж→:  Э→"  Б→<  Ю→>
  "ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ;QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>~",

  -- Ukrainian-only lowercase (4 chars): і→s  ї→]  є→'  ґ→`
  "іїєґ;s]'`",

  -- Ukrainian-only uppercase (4 chars): І→S  Ї→}  Є→"  Ґ→~
  "ІЇЄҐ;S}\"~",
}, ",")

-- Limitations:
--   ё / ґ (backtick position): included, but the actual key depends on the
--     specific UA-RU variant. If backtick produces neither, the entries are
--     harmless no-ops. Verify with ':verbose set langmap?' and test the key.
--
--   / key (search mode entry): on most Mac ЙЦУКЕН variants '/' stays as '/'.
--     If the active layout remaps it to a Cyrillic char, add that char→'/' pair here.
--     Inside the search prompt, langmap does not apply (not Normal mode), so
--     the IM must be English (or im-select.nvim must have already restored it).
--
--   Command-line input (:w, :q, etc.): langmap translates Ж→':' to enter
--     command mode, but keys typed inside the command line are raw — see the
--     CmdlineEnter autocmd in autocmds.lua for the safety-net IM switch.
