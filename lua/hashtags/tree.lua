local M = {}

local BUF_NAME = "HashtagsTree"
local _win = nil
local _buf = nil

local ICONS = {
  tag     = "󰓹 ",
  file    = "󰈙 ",
  line    = "  ",
  open    = "▾ ",
  closed  = "▸ ",
}

-- Estado de qué tags están expandidos
local _expanded = {}

-- Genera las líneas del árbol y un mapa línea→acción
local function build_tree(index)
  local lines = {}
  local line_map = {} -- { [lnum] = { type="tag"|"entry", tag=, entry= } }

  local tags = vim.tbl_keys(index)
  table.sort(tags)

  for _, tag in ipairs(tags) do
    local entries = index[tag]
    local count   = #entries
    local is_open = _expanded[tag]
    local icon    = is_open and ICONS.open or ICONS.closed

    table.insert(lines, string.format(
      "%s%s  \27[36m(%d)\27[0m", icon, tag, count
    ))
    line_map[#lines] = { type = "tag", tag = tag }

    if is_open then
      -- Agrupa por archivo
      local by_file = {}
      local file_order = {}
      for _, e in ipairs(entries) do
        if not by_file[e.file] then
          by_file[e.file] = {}
          table.insert(file_order, e.file)
        end
        table.insert(by_file[e.file], e)
      end

      for _, file in ipairs(file_order) do
        local short = file:match("[^/]+$") or file
        table.insert(lines, string.format("  %s%s", ICONS.file, short))
        line_map[#lines] = { type = "file", file = file }

        for _, e in ipairs(by_file[file]) do
          local text_short = e.text:sub(1, 50):gsub("\27%[[%d;]+m", "")
          table.insert(lines, string.format(
            "    %s:%d  %s", ICONS.line, e.lnum, vim.trim(text_short)
          ))
          line_map[#lines] = { type = "entry", entry = e }
        end
      end
    end
  end

  return lines, line_map
end

local function render(buf, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  -- Quitar escapes ANSI para nvim (usamos extmarks en su lugar)
  local clean = vim.tbl_map(function(l)
    return l:gsub("\27%[[%d;]+m", "")
  end, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, clean)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

local function open_entry(entry)
  -- Busca una ventana que no sea el árbol
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= _win then
      vim.api.nvim_set_current_win(win)
      vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
      vim.api.nvim_win_set_cursor(0, { entry.lnum, 0 })
      vim.cmd("normal! zz")
      return
    end
  end
  -- Si no hay otra ventana, abre en split
  vim.cmd("vsplit " .. vim.fn.fnameescape(entry.file))
  vim.api.nvim_win_set_cursor(0, { entry.lnum, 0 })
end

function M.refresh()
  if not _buf or not vim.api.nvim_buf_is_valid(_buf) then return end
  local scanner = require("hashtags.scanner")
  local index = scanner.scan()
  local lines, line_map = build_tree(index)
  render(_buf, lines)

  -- Keymaps interactivos
  local opts = { buffer = _buf, nowait = true, silent = true }

  -- Enter / l → expandir tag o ir a entry
  vim.keymap.set("n", "<CR>", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local info  = line_map[lnum]
    if not info then return end
    if info.type == "tag" then
      _expanded[info.tag] = not _expanded[info.tag]
      M.refresh()
    elseif info.type == "entry" then
      open_entry(info.entry)
    end
  end, opts)

  vim.keymap.set("n", "l", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local info  = line_map[lnum]
    if info and info.type == "tag" then
      _expanded[info.tag] = true
      M.refresh()
    end
  end, opts)

  vim.keymap.set("n", "h", function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local info  = line_map[lnum]
    if info and info.type == "tag" then
      _expanded[info.tag] = false
      M.refresh()
    end
  end, opts)

  vim.keymap.set("n", "r", function()
    require("hashtags.scanner").clear_cache()
    M.refresh()
    vim.notify("[hashtags] Árbol actualizado", vim.log.levels.INFO)
  end, opts)

  vim.keymap.set("n", "q", function() M.close() end, opts)
end

function M.open()
  -- Crear buffer
  _buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(_buf, BUF_NAME)
  vim.api.nvim_buf_set_option(_buf, "buftype",    "nofile")
  vim.api.nvim_buf_set_option(_buf, "bufhidden",  "wipe")
  vim.api.nvim_buf_set_option(_buf, "swapfile",   false)
  vim.api.nvim_buf_set_option(_buf, "filetype",   "HashtagsTree")

  -- Abrir ventana lateral izquierda
  vim.cmd("topleft vsplit")
  _win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(_win, _buf)
  vim.api.nvim_win_set_width(_win, 40)

  vim.api.nvim_win_set_option(_win, "number",         false)
  vim.api.nvim_win_set_option(_win, "relativenumber", false)
  vim.api.nvim_win_set_option(_win, "signcolumn",     "no")
  vim.api.nvim_win_set_option(_win, "wrap",           false)
  vim.api.nvim_win_set_option(_win, "winfixwidth",    true)

  M.refresh()
end

function M.close()
  if _win and vim.api.nvim_win_is_valid(_win) then
    vim.api.nvim_win_close(_win, true)
  end
  _win = nil
  _buf = nil
end

function M.is_open()
  return _win ~= nil and vim.api.nvim_win_is_valid(_win)
end

function M.toggle()
  if _win and vim.api.nvim_win_is_valid(_win) then
    M.close()
  else
    M.open()
  end
end

return M
