return {
  "nvim-neorg/neorg",
  lazy = false,
  version = "v9.1.1",
  config = function()
    require('neorg').setup {
      load = {
        ["core.concealer"] = {
          config = {
            icon_preset = "basic"
          }
        },
        ["core.defaults"] = {},
        ["core.dirman"] = {
          config = {
            workspaces = {
              default = "~/personal/git/notes",
            },
            index = "index.norg",
            default_workspace = "default",
          }
        }
      }
    }
  end
}
