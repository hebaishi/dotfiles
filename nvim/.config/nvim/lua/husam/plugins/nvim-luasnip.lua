return {
  "saadparwaiz1/cmp_luasnip",
  config = function()
    require("luasnip.loaders.from_vscode").lazy_load({ paths = { "/home/hebaishi/snippets" } })
    local vscode_snippets = vim.fn.getcwd() .. "/.vscode/cpp.code-snippets"
    if vim.fn.filereadable(vscode_snippets) == 1 then
      require("luasnip.loaders.from_vscode").load_standalone({ path = vscode_snippets })
    end
  end
}
