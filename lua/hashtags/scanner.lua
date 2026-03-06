local M = {}

-- Caché: { "#tag" = { {file, lnum, text, col}, ... } }
local _cache = nil

-- Construye el patrón regex para ripgrep según el símbolo configurado
local function rg_pattern(symbol)
  -- Busca el símbolo dentro de comentarios (línea completa para que rg sea rápido)
  -- Luego el parser filtra los que están dentro de comentarios reales
  return symbol .. "[a-zA-Z][a-zA-Z0-9_-]*"
end

-- Excluye directorios al llamar ripgrep
local function build_rg_cmd(symbol, exclude)
  local globs = ""
  for _, dir in ipairs(exclude) do
    globs = globs .. string.format(" --glob '!%s'", dir)
  end
  local pat = rg_pattern(symbol)
  -- -n: número de línea, --column: columna, -H: nombre archivo, -I: no imprimir 2x nombre
  return string.format(
    "rg --no-heading -n --column -H %s -e '%s' .",
    globs, pat
  )
end

-- Parsea una línea de salida de ripgrep:
-- "archivo.js:10:5:  // llamada a la API #api #critico"
local function parse_rg_line(line)
  local file, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
  if not file then return nil end
  return {
    file = file,
    lnum = tonumber(lnum),
    col  = tonumber(col),
    text = text,
  }
end

-- Extrae todos los #tags de un texto
local function extract_tags(text, symbol)
  local tags = {}
  local pat = symbol .. "([a-zA-Z][a-zA-Z0-9_-]*)"
  for tag in text:gmatch(pat) do
    table.insert(tags, symbol .. tag)
  end
  return tags
end

-- Verifica si el match de rg está dentro de un comentario
-- usando los patrones del config para el filetype del archivo
local function is_in_comment(text, ft, comment_patterns)
  local patterns = comment_patterns[ft] or comment_patterns["default"]
  for _, pat in ipairs(patterns) do
    -- Busca el patrón de comentario en la línea
    if text:match(pat) then return true end
  end
  return false
end

-- Detecta filetype por extensión (simple, sin abrir buffer)
local ext_to_ft = {
  lua="lua", py="python", js="javascript", ts="typescript",
  jsx="javascript", tsx="typescript", rs="rust", go="go",
  c="c", cpp="cpp", h="c", sh="sh", bash="bash",
}

local function ft_from_file(file)
  local ext = file:match("%.([^%.]+)$")
  return ext and ext_to_ft[ext] or "default"
end

-- Escanea el proyecto y retorna el índice de tags
-- { "#tag" = { {file, lnum, col, text}, ... } }
function M.scan(force)
  if _cache and not force then return _cache end

  local cfg = require("hashtags").config
  local cwd = vim.fn.getcwd()
  local cmd = build_rg_cmd(cfg.tag_symbol, cfg.exclude)

  local result = vim.fn.systemlist(cmd, nil, false)
  if vim.v.shell_error ~= 0 and #result == 0 then
    _cache = {}
    return _cache
  end

  local index = {}

  for _, line in ipairs(result) do
    local entry = parse_rg_line(line)
    if entry then
      local ft = ft_from_file(entry.file)
      if is_in_comment(entry.text, ft, cfg.comment_patterns) then
        local tags = extract_tags(entry.text, cfg.tag_symbol)
        -- Ruta relativa más limpia
        entry.file = entry.file:gsub("^%./", "")
        for _, tag in ipairs(tags) do
          if not index[tag] then index[tag] = {} end
          table.insert(index[tag], {
            file = entry.file,
            lnum = entry.lnum,
            col  = entry.col,
            text = vim.trim(entry.text),
          })
        end
      end
    end
  end

  _cache = index
  return _cache
end

-- Lista de todos los tags encontrados (ordenados)
function M.tags(force)
  local index = M.scan(force)
  local tags = vim.tbl_keys(index)
  table.sort(tags)
  return tags
end

-- Entradas de un tag específico
function M.entries_for(tag)
  local index = M.scan()
  return index[tag] or {}
end

function M.clear_cache()
  _cache = nil
end

return M
