# hashtags.nvim

Sistema de etiquetas libre en comentarios de código para Neovim.

Escribe `#tags` en tus comentarios y navega por ellos desde un panel lateral o un buscador fzf-lua.

```js
export function fetchUser(id) { // #api #critico
  return fetch(`/user/${id}`)
}

console.log("iniciando app") // #debug #mensaje
```

---

## Requisitos

- Neovim >= 0.9
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg` en PATH)
- (opcional) [bat](https://github.com/sharkdp/bat) para preview con colores

---

## Instalación

### lazy.nvim

```lua
{
  "tuusuario/hashtags.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("hashtags").setup()
  end,
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

---

## Configuración

```lua
require("hashtags").setup({
  -- Símbolo de tag (default: "#")
  tag_symbol = "#",

  -- Highlight de tags en el buffer actual
  highlight = true,
  highlight_group = "HashTag", -- puedes linkear a otro grupo

  -- Directorios a ignorar en el escaneo
  exclude = { ".git", "node_modules", ".venv", "dist", "build" },

  -- Patrones de comentarios por filetype
  -- (los defaults cubren la mayoría de lenguajes)
  comment_patterns = {
    lua        = { "--%s*(.*)" },
    python     = { "#%s*(.*)" },
    javascript = { "//%s*(.*)" },
    -- ...
  },
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
