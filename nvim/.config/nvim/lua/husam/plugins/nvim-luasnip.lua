return {
  "saadparwaiz1/cmp_luasnip",
  config = function()
    require("luasnip.loaders.from_vscode").lazy_load({ paths = { "/home/hebaishi/snippets" } })
  end
}
