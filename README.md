<div align="center">

# 🗂️ super-kanban.nvim

**A keyboard-centric, minimal, and customizable Kanban board plugin for Neovim.**

It supports Obsidian-style Markdown and Orgmode formats, with Treesitter-powered parsing and a focus on speed and clarity - right inside your editor.

</div>

---

## Screenshots

![gif](https://github.com/user-attachments/assets/00708972-7dfe-4503-a90a-2bbbf87e2ded)

---

## ✨ Features

- Keyboard-centric Kanban workflow built for Neovim
- Treesitter-based parsing for `Markdown` and `Orgmode` (`neorg` coming soon)
- Compatible with Obsidian Kanban-style markdown
- Supports tags, checkmarks, due dates, sorting or archiving cards
- Built-in date picker for assigning due dates (press `@` in insert mode)
- Create dedicated notes for each card to store additional context
- Time tracking support to log and review time spent on each task (`coming soon`)

---

## ⚙️ Requirements

#### Required

- [snacks.nvim](https://github.com/folke/snacks.nvim) - search & component layout engine
- Treesitter parser for `markdown` or `org`

#### Optional

- [orgmode.nvim](https://github.com/nvim-orgmode/orgmode) - for Org file support
- [flash.nvim](https://github.com/folke/flash.nvim) - for enhanced jump navigation  *(see [Flash integration](#flashnvim-integration))*

---

## 📦 Installation

### Using `lazy.nvim`

```lua
{
  "hasansujon786/super-kanban.nvim",
  dependencies = {
    "folke/snacks.nvim",           -- [required]
    "nvim-orgmode/orgmode",        -- [optional] Org format support
  },
  opts = {}, -- optional: pass your config table here
}
```

### Using `mini.deps`

```lua
require("mini.deps").add({
  source = "hasansujon786/super-kanban.nvim",
  depends = {
    { source = "folke/snacks.nvim" },       -- [required]
    { source = "nvim-orgmode/orgmode" },    -- [optional]
  },
})
```

---

## 🔧 Configuration

Call `setup()` in your config file to customize behavior:

```lua
require("super-kanban").setup({
  markdown = {
    notes_dir = "./tasks/",
    list_heading = "h2",
    default_template = {
      "## Backlog\n",
      "## Todo\n",
      "## Work in progress\n",
      "## Completed\n",
    },
  },
  mappings = {
    ["<cr>"] = "open_note",
    ["gD"] = "delete_card",
    ["<C-t>"] = "toggle_complete",
  },
})
```

## Configuration Options

```lua
{
  markdown = {...},     -- Settings for working with Markdown kanban files
  org = {...},          -- Settings for working with Org kanban files
  card = {...},         -- Window style and behavior for cards
  list = {...},         -- Layout and options for lists
  board = {...},        -- Main board window layout and styling
  date_picker = {...},  -- Appearance and options for the date picker
  note_popup = {...},   -- Settings for the card note popup
  icons = {...},        -- Customize UI icons (borders, arrows, etc.)
  mappings = {...},     -- Custom keymaps for user actions
}
```

See [`:h super-kanban-config-defaults`](https://github.com/hasansujon786/super-kanban.nvim/blob/main/doc/super-kanban.txt#L160) in the help file for all available options.

---

## ⌨️Configuration Keymaps

Define custom mappings using the `mappings` option. Each mapping can be:

- a string (built-in action name)
- a table: with a `callback` function and optional mapping options
- `false` (to disable the default)

Example:

```lua
mappings = {
  ['s'] = {
    callback = function()
      pick_window()
    end,
    desc = "Flash",
  },

  ['/'] = {
    callback = function(card, list, ctx)
      require("super-kanban.actions").search_card(card, list, ctx)
    end,
    nowait = true,
  },

  ['<cr>'] = false,
}
```

You can use all standard mapping options (`desc`, `nowait`, etc.)  
See `:h vim.keymap.set()` and `vim.keymap.set.Opts` for details.

## 🧩 Default Keymaps

| Key      | Action                   | Description                    |
| -------- | ------------------------ | ------------------------------ |
| `q`      | `close`                  | Close board window             |
| `gN`     | `create_card_before`     | Create card before current     |
| `gn`     | `create_card_after`      | Create card after current      |
| `gK`     | `create_card_top`        | Create card at top of list     |
| `gJ`     | `create_card_bottom`     | Create card at bottom of list  |
| `gD`     | `delete_card`            | Delete current card            |
| `g<C-t>` | `archive_card`           | Archive current card           |
| `<C-t>`  | `toggle_complete`        | Toggle card checkbox           |
| `g.`     | `sort_by_due_descending` | Sort cards by due (descending) |
| `g,`     | `sort_by_due_ascending`  | Sort cards by due (ascending)  |
| `/`      | `search_card`            | Search cards                   |
| `zi`     | `pick_date`              | Open date picker               |
| `<CR>`   | `open_note`              | Open card note                 |
| `zN`     | `create_list_at_begin`   | Create list at beginning       |
| `zn`     | `create_list_at_end`     | Create list at end             |
| `zD`     | `delete_list`            | Delete current list            |
| `zr`     | `rename_list`            | Rename current list            |
| `<C-k>`  | `jump_up`                | Jump to card above             |
| `<C-j>`  | `jump_down`              | Jump to card below             |
| `<C-h>`  | `jump_left`              | Jump to list on the left       |
| `<C-l>`  | `jump_right`             | Jump to list on the right      |
| `gg`     | `jump_top`               | Jump to top of current list    |
| `G`      | `jump_bottom`            | Jump to bottom of current list |
| `z0`     | `jump_list_begin`        | Jump to first list             |
| `z$`     | `jump_list_end`          | Jump to last list              |
| `<A-k>`  | `move_up`                | Move card up                   |
| `<A-j>`  | `move_down`              | Move card down                 |
| `<A-h>`  | `move_left`              | Move card to previous list     |
| `<A-l>`  | `move_right`             | Move card to next list         |
| `zh`     | `move_list_left`         | Move list left                 |
| `zl`     | `move_list_right`        | Move list right                |

## flash.nvim Integration

You can integrate flash.nvim to jump between Kanban windows using label hints.

Example:
```lua
local function pick_window(callback)
  require('flash').jump({
    highlight = {
      backdrop = true,
      groups = {
        current = 'FlashLabel',
        label = 'FlashLabel',
      },
    },
    label = { after = { 0, 0 } },
    search = {
      mode = 'search',
      max_length = 0,
      multi_window = true,
      exclude = {
        function(win)
          local kanban_ft = { superkanban_list = true, superkanban_card = true }
          return not kanban_ft[vim.bo[vim.api.nvim_win_get_buf(win)].filetype]
        end,
      },
    },
    action = callback,
    matcher = function(win)
      return { { pos = { 1, 0 }, end_pos = { 1, 0 } } }
    end,
  })
end

-- Inside your plugin setup
{
  mappings = {
    ['s'] = {
      callback = function()
        pick_window()
      end,
      desc = 'Flash',
    },
  }
}
```
---

## 📜 Commands

| Command               | Description                                      |
| --------------------- | ------------------------------------------------ |
| `:SuperKanban`        | Open the main board window                       |
| `:SuperKanban create` | Create a new Kanban file                         |
| `:SuperKanban close`  | Close the main board window                      |
| `:SuperKanban list`   | List-related actions (create, move, delete, etc) |
| `:SuperKanban card`   | Card-related actions (move, jump, date, etc)     |

See `:h :SuperKanban` for subcommand details.

---

## 📦 API

You can call functions directly via Lua:

```lua
require("super-kanban").open("todo.md")
require("super-kanban").create("my-board.md")
require("super-kanban").setup({ ... })
```

---

## 🎨 Highlight Groups

- `SuperKanbanNormal`
- `SuperKanbanListBorder`
- `SuperKanbanCardNormal`
- `SuperKanbanDatePickerCursor`
- and more...

See [`:h super-kanban-highlight-groups`](https://github.com/hasansujon786/super-kanban.nvim/blob/main/doc/super-kanban.txt#L909) for the full list.

---

## 🧪 Contributing

Feel free to open issues or PRs if you have ideas or find bugs.
This plugin is still in early development, so feedback is welcome!

## 🙏 Acknowledgement

- Huge thanks to [arakkkkk/kanban.nvim](https://github.com/arakkkkk/kanban.nvim)
  it was one of the first Neovim Kanban plugins I tried, and it inspired me to
  build my own take on the idea.
