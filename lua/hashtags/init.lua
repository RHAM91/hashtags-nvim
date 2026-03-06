local M = {}

M.config = {
  -- Patrones de comentarios por filetype
  comment_patterns = {
    default    = { "--%s*(.*)", "//%s*(.*)", "#%s*(.*)" },
    lua        = { "--%s*(.*)" },
    python     = { "#%s*(.*)" },
    javascript = { "//%s*(.*)" },
    typescript = { "//%s*(.*)" },
    rust       = { "//%s*(.*)" },
    go         = { "//%s*(.*)" },
    c          = { "//%s*(.*)", "%*%s*(.*)" },
    cpp        = { "//%s*(.*)", "%*%s*(.*)" },
    sh         = { "#%s*(.*)" },
    bash       = { "#%s*(.*)" },
  },
  -- Directorios/archivos a ignorar
  exclude = { ".git", "node_modules", ".venv", "dist", "build" },
  -- Símbolo de tag (puedes cambiarlo a @ u otro)
  tag_symbol = "#",
  -- Highlight de tags en el buffer activo
  highlight = true,
  highlight_group = "HashTag",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Definir highlight por defecto si no existe
  vim.api.nvim_set_hl(0, "HashTag", {
    fg = "#f9e2af", bold = true, default = true
  })

  -- Cargar highlight automático al abrir buffers
  if M.config.highlight then
    local hl = require("hashtags.highlight")
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "InsertLeave" }, {
      callback = function() hl.apply() end,
    })
  end

  -- Registrar comandos
  vim.api.nvim_create_user_command("HashtagsFind", function()
    require("hashtags.picker").open()
  end, { desc = "Buscar por hashtag con fzf-lua" })

  vim.api.nvim_create_user_command("HashtagsTree", function()
    require("hashtags.tree").toggle()
  end, { desc = "Panel lateral de hashtags" })

  vim.api.nvim_create_user_command("HashtagsRefresh", function()
    require("hashtags.scanner").clear_cache()
    vim.notify("[hashtags] Caché limpiado", vim.log.levels.INFO)
  end, { desc = "Limpiar caché de hashtags" })
end

return M
