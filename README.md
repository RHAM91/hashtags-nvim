# hashtags.nvim

Sistema de etiquetas libre en comentarios de código para Neovim.

Escribe `#tags` en tus comentarios y navega por ellos desde un panel lateral o un buscador fzf-lua con preview integrado.

```js
export function fetchUser(id) { // #api #critico
  return fetch(`/user/${id}`)
}

console.log("iniciando app") // #debug #mensaje
```

---

## ✨ Características

- 🔍 Búsqueda rápida de hashtags con **fzf-lua**
- 📁 Panel lateral tipo árbol para explorar tags
- 🎨 Preview con syntax highlighting (usando **bat**)
- 🚀 Caché inteligente para mejor rendimiento
- 🌐 Soporte multi-lenguaje automático
- ⚙️ Altamente configurable

---

## 📋 Requisitos

- Neovim >= 0.9
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg` en PATH)
- [bat](https://github.com/sharkdp/bat) (opcional, para preview con colores)

---

## 📦 Instalación

### lazy.nvim (recomendado)

```lua
{
  "tuusuario/hashtags.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("hashtags").setup()
  end,
  keys = {
    { "<leader>ht", "<cmd>HashtagsFind<CR>", desc = "Buscar hashtag" },
    { "<leader>hT", "<cmd>HashtagsTree<CR>", desc = "Panel hashtags" },
    { "<leader>hr", "<cmd>HashtagsRefresh<CR>", desc = "Refresh hashtags" },
  },
}
```

### packer.nvim

```lua
use {
  "tuusuario/hashtags.nvim",
  requires = { "ibhagwan/fzf-lua" },
  config = function()
    require("hashtags").setup()
  end,
}
```

Después de agregar el plugin, ejecuta:
```vim
:Lazy sync  " para lazy.nvim
:PackerSync " para packer.nvim
```

---

## ⚙️ Configuración

### Configuración básica

```lua
require("hashtags").setup()
```

### Configuración completa (con valores por defecto)

```lua
require("hashtags").setup({
  -- Símbolo de tag (default: "#")
  -- Puedes cambiarlo a "@", "!", etc.
  tag_symbol = "#",

  -- Highlight de tags en el buffer actual
  highlight = true,
  highlight_group = "HashTag", -- puedes linkear a otro grupo de color

  -- Directorios a ignorar en el escaneo
  exclude = { ".git", "node_modules", ".venv", "dist", "build" },

  -- Patrones de comentarios por filetype
  -- (los defaults cubren la mayoría de lenguajes)
  comment_patterns = {
    lua        = { "--%s*(.*)" },
    python     = { "#%s*(.*)" },
    javascript = { "//%s*(.*)" },
    typescript = { "//%s*(.*)" },
    rust       = { "//%s*(.*)" },
    go         = { "//%s*(.*)" },
    -- Agrega más según necesites
  },
})
```

### Ejemplos de personalización

#### Cambiar el símbolo de tag

```lua
require("hashtags").setup({
  tag_symbol = "@",  -- Ahora usa @tag en lugar de #tag
})
```

#### Personalizar colores del highlight

```lua
require("hashtags").setup({
  highlight_group = "Comment",  -- Usa el color de comentarios
})

-- O crea tu propio grupo de color
vim.api.nvim_set_hl(0, "HashTag", { fg = "#ff79c6", bold = true })
```

#### Agregar más directorios a ignorar

```lua
require("hashtags").setup({
  exclude = { ".git", "node_modules", ".venv", "dist", "build", "target", "vendor" },
})
```

---

## Uso

### Comandos

| Comando              | Descripción                                    |
|----------------------|------------------------------------------------|
| `:HashtagsFind`      | Abre fzf-lua → elige tag → elige ocurrencia    |
| `:HashtagsTree`      | Toggle del panel lateral con árbol de tags     |
| `:HashtagsRefresh`   | Limpia la caché y fuerza re-escaneo            |

### Keymaps recomendados

```lua
vim.keymap.set("n", "<leader>ht", "<cmd>HashtagsFind<CR>",    { desc = "Buscar hashtag" })
vim.keymap.set("n", "<leader>hT", "<cmd>HashtagsTree<CR>",   { desc = "Panel hashtags" })
vim.keymap.set("n", "<leader>hr", "<cmd>HashtagsRefresh<CR>", { desc = "Refresh hashtags" })
```

### Panel lateral (`HashtagsTree`)

| Tecla   | Acción                          |
|---------|---------------------------------|
| `<CR>`  | Expandir tag / abrir línea      |
| `l`     | Expandir tag                    |
| `h`     | Colapsar tag                    |
| `r`     | Refrescar árbol                 |
| `q`     | Cerrar panel                    |

---

## Cómo funciona

1. Al invocar `:HashtagsFind` o `:HashtagsTree`, se ejecuta `ripgrep` en el directorio actual buscando el patrón `#palabra`.
2. Solo se consideran las líneas que son **comentarios** (detectado por filetype).
3. Los resultados se indexan en memoria por tag.
4. fzf-lua muestra primero los tags disponibles, luego las ocurrencias del tag elegido.
5. Al seleccionar una ocurrencia, el cursor salta al archivo y línea correspondiente.

El resultado se **cachea** hasta que corras `:HashtagsRefresh` o reinicies Neovim.

---

## Tags en cualquier lenguaje

```python
# utils.py
def send_email(to): # #notificacion #critico
    pass
```

```lua
-- init.lua
vim.keymap.set("n", "gd", ...) -- #keymaps #navegacion
```

```rust
// main.rs
fn parse_config() -> Config { // #config #importante
```

---

## Licencia

MIT
