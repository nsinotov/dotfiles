return {
  "dlyongemallo/diffview-plus.nvim",
  config = function()
    -- Fix vim.env[] crashing in async context (fast event). Use uv.os_getenv() instead.
    local PathLib = require("diffview.path").PathLib
    local uv = vim.uv or vim.loop
    local original_expand = PathLib.expand
    function PathLib:expand(path)
      local segments = self:explode(path)
      local idx = 1
      if segments[1] == "~" then
        segments[1] = uv.os_homedir()
        idx = 2
      end
      for i = idx, #segments do
        local env_var = segments[i]:match("^%$(%S+)$")
        if env_var then
          local value = uv.os_getenv(env_var)
          if value ~= nil then
            segments[i] = value
          end
        end
      end
      return self:join(unpack(segments))
    end
  end,
}
