return {
  "nomnivore/ollama.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- All the user commands added by the plugin
  cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },
  keys = {
    {
      "<leader>oo",
      ":<c-u>lua require('ollama').prompt()<cr>",
      desc = "ollama prompt",
      mode = { "n", "v" },
    },
    {
      "<leader>oG",
      ":<c-u>lua require('ollama').prompt('CodeGen2')<cr>",
      desc = "ollama Generate Code",
      mode = { "n", "v" },
    },
  },
  opts = {
    model = "deepseek-coder-v2",
    url = "http://127.0.0.1:11434",
    serve = {
      on_start = false,
      command = "ollama",
      args = { "serve" },
      stop_command = "pkill",
      stop_args = { "-SIGTERM", "ollama" },
    },
    prompts = {
      CodeGen2 = {
        prompt = "$input",
        input_label = "> ",
        model = "llama3.1",
        action = "insert",
        extract = "```%w*\n(.-)```"
      }
    }
  }
}
