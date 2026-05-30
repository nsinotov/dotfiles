return {
  "sindrets/diffview.nvim",
  config = function()
    -- Temporary fix until https://github.com/sindrets/diffview.nvim/issues/618 is resolved.
    -- PathLib:expand() strips $ from filenames that aren't env vars (e.g. Remix routes).
    local PathLib = require("diffview.path").PathLib
    local uv = vim.uv or vim.loop
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
          segments[i] = uv.os_getenv(env_var) or segments[i]
        end
      end
      return self:join(unpack(segments))
    end
  end,
}
