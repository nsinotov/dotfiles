return {
  {
    "GCBallesteros/jupytext.nvim",
    config = function()
      local utils = require("jupytext.utils")
      local orig = utils.get_ipynb_metadata
      utils.get_ipynb_metadata = function(filename)
        local ok, result = pcall(orig, filename)
        if ok then
          return result
        end
        return { language = "python", extension = "py" }
      end

      require("jupytext").setup({
        style = "markdown",
        output_extension = "md",
        force_ft = "markdown",
      })
    end,
  },
}
