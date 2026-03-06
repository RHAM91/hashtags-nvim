local M = {}

local NS = vim.api.nvim_create_namespace("hashtags_hl")

-- Detecta si una línea es comentario (simple heurística por filetype)
local function line_is_comment(line, ft, patterns)
  local pats = patterns[ft] or patterns["default"]
  for _, p in ipairs(pats) do
    if line:match("^%s*" .. p:gsub("%(%.%*%)", ".*")) then
      return true
    end
  end
  -- Fallback más simple: busca // o -- o # al inicio (tras espacios)
  return line:match("^%s*//") or line:match("^%s*%-%-") or line:match("^%s*#")
end

function M.apply()
  local buf = vim.api.nvim_get_current_buf()
  local cfg = require("hashtags").config
  if not cfg.highlight then return end

  -- Limpiar highlights anteriores
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)

  local ft      = vim.bo[buf].filetype
  local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local symbol  = vim.pesc(cfg.tag_symbol)
  local tag_pat = symbol .. "[a-zA-Z][a-zA-Z0-9_%-]*"

  for i, line in ipairs(lines) do
    if line_is_comment(line, ft, cfg.comment_patterns) then
      local start = 1
      while true do
        local s, e = line:find(tag_pat, start)
        if not s then break end
        -- extmark es 0-indexed
        vim.api.nvim_buf_set_extmark(buf, NS, i - 1, s - 1, {
          end_col   = e,
          hl_group  = cfg.highlight_group,
        })
        start = e + 1
      end
    end
  end
end

return M
