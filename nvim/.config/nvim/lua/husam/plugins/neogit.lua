return {
  "TimUntersberger/neogit",
  event = 'VeryLazy',
  config = function()
    require('neogit').setup {
      integrations = {
        diffview = true
      }
    }
  end
}
