local M = {}

local function open_entries(tag)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[hashtags] fzf-lua no encontrado", vim.log.levels.ERROR)
    return
  end

  local scanner = require("hashtags.scanner")
  local entries = scanner.entries_for(tag)

  if #entries == 0 then
    vim.notify("[hashtags] No hay entradas para " .. tag, vim.log.levels.WARN)
    return
  end

  -- Formato: "archivo.js:10  // comentario con #tag"
  local items = {}
  for _, e in ipairs(entries) do
    table.insert(items, string.format(
      "%-40s  \27[90m%s\27[0m",
      e.file .. ":" .. e.lnum,
      vim.trim(e.text)
    ))
  end

  fzf.fzf_exec(items, {
    prompt = "  " .. tag .. " > ",
    preview = function(selected)
      local line = selected[1] or ""
      local file_lnum = line:match("^(%S+)")
      if not file_lnum then return {} end
      local file, lnum = file_lnum:match("^(.+):(%d+)$")
      if file and lnum then
        -- bat preview si está disponible, si no cat
        if vim.fn.executable("bat") == 1 then
          return string.format(
            "bat --style=numbers --color=always --highlight-line %s '%s'",
            lnum, file
          )
        else
          return string.format("sed -n '%s,%sp' '%s'", lnum, tonumber(lnum) + 10, file)
        end
      end
    end,
    preview_type = "cmd",
    actions = {
      ["default"] = function(selected)
        local line = selected[1] or ""
        local file_lnum = line:match("^(%S+)")
        if not file_lnum then return end
        local file, lnum = file_lnum:match("^(.+):(%d+)$")
        if file and lnum then
          vim.cmd("edit " .. vim.fn.fnameescape(file))
          vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
          vim.cmd("normal! zz")
        end
      end,
    },
  })
end

-- Paso 1: elegir el tag
function M.open()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[hashtags] fzf-lua no encontrado", vim.log.levels.ERROR)
    return
  end

  local scanner = require("hashtags.scanner")
  local index = scanner.scan()
  local tags = vim.tbl_keys(index)

  if #tags == 0 then
    vim.notify("[hashtags] No se encontraron tags en el proyecto", vim.log.levels.WARN)
    return
  end

  table.sort(tags)

  -- Enriquece con conteo de ocurrencias
  local items = {}
  for _, tag in ipairs(tags) do
    local count = #(index[tag])
    table.insert(items, string.format(
      "%-30s  \27[36m%d ocurrencia%s\27[0m",
      tag,
      count,
      count == 1 and "" or "s"
    ))
  end

  fzf.fzf_exec(items, {
    prompt = "  Hashtags > ",
    winopts = {
      height = 0.5,
      width  = 0.5,
    },
    actions = {
      ["default"] = function(selected)
        local line = selected[1] or ""
        -- Extrae solo el tag (primera palabra)
        local tag = line:match("^(%S+)")
        if tag then open_entries(tag) end
      end,
    },
  })
end

return M
