# Neovim Configuration

This is my baller neovim config. There is barely no plugin left under defaults.

## Features

- **Bleeding Edge:** Leverages Neovim 0.12+ features including `vim.pack` for
  plugin management and the new `vim.lsp.config` API.
- **Custom UI Components:**
  - **Dynamic Theme System:** A hand-rolled color scheme (vanilla++)
    (`lua/config/coloring.lua`) that generates semantic colors for both light
    and dark modes.
  - **Custom Tabline:** A minimal tabline (`lua/config/tabline.lua`) showing
    only relevant buffers and allowing quick tab switching via `A, S, D, F`
    keys.
  - **Custom Statuscolumn:** Combines line numbers, signs, and a visual border
    (`lua/config/statuscolumn.lua`).
- **Opinionated Workflow:** Preconfigured for web development (Typescript,
  React, Tailwind, Jinja) with specific formatting, linting, and navigation
  preferences.
- **AI Integration is WIP**

## Prerequisites

- **Neovim:** v0.12.0+ (Required for `vim.pack` and `vim.lsp.config`).
- **External Tools:**
  - `ripgrep` (for search)
  - `fd` (for file finding)
  - LSPs & Formatters

## Installation

1. Clone the repository into your Neovim config directory:
   ```bash
   git clone https://github.com/yourusername/nvim-config.git ~/.config/nvim
   ```
2. Start Neovim. The `init.lua` will automatically bootstrap plugins using
   `vim.pack`.

## Theming

The configuration defines a custom color palette in `lua/config/coloring.lua`.
It generates helper functions for manipulating hex codes (`darken_hex`,
`lighten_hex`).

Highlights are applied dynamically based on `vim.o.background`:

## File Structure

```
.
├── init.lua                  # Entry point, loads config and plugins
├── lua/
│   ├── ai/                   # AI integration logic (aichat wrapper)
│   ├── config/
│   │   ├── coloring.lua      # Color manipulation utils
│   │   ├── highlights.lua    # Theme definitions
│   │   ├── keymaps.lua       # Global keymaps
│   │   ├── settings.lua      # Vim options
│   │   ├── statuscolumn.lua  # Custom statuscolumn
│   │   └── tabline.lua       # Custom tabline
│   ├── lsp/                  # LSP configs (e.g., Tailwind)
│   └── plugins/              # Custom plugin specifications
├── queries/                  # Treesitter queries (Jinja overrides)
└── snippets/                 # Custom VSCode-style snippets
```
