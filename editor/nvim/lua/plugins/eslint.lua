-- Auto-detect legacy .eslintrc.* projects and disable flat config for them
local legacy_patterns = { ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc.json" }
local flat_patterns = { "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts", "eslint.config.mts", "eslint.config.cts" }

local function has_any(dir, patterns)
  for _, p in ipairs(patterns) do
    if vim.uv.fs_stat(dir .. "/" .. p) then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "eslint" then
      return
    end
    local root = client.root_dir
    if root and has_any(root, legacy_patterns) and not has_any(root, flat_patterns) then
      client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
        useFlatConfig = false,
      })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    end
  end,
})

return {}
