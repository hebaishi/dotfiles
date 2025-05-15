return {
  "mfussenegger/nvim-dap-python",
  config = function()
    local bin_directory = 'Scripts'
    if vim.loop.os_uname().sysname == 'Linux' then
      bin_directory = 'bin'
    end
    require("dap-python").setup(vim.fn.expand("~") .. '/.virtualenvs/' .. bin_directory .. '/python')
  end
}
