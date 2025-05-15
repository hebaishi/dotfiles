return {
  "windwp/nvim-ts-autotag",
  config = function()
    require('nvim-ts-autotag').setup({
      filetypes = {
        'html', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'xml',
      },
      skip_tags = {
        'area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'input',
        'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr', 'menuitem'
      }
    })
  end
}
