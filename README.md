# Neovim Configuration

<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/699605b6-ebf1-4ec5-996d-178d7c45ad9c" />

<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/748abb06-f949-49fa-ad6f-789bddd98301" />

My personal Neovim setup: opinionated, relatively minimal in the UI, and built around fast navigation rather than a distribution's defaults. It is useful as a starting point, but expect to adapt its keymaps, language tooling, and external commands to your own workflow.

The configuration uses Neovim's built-in `vim.pack` package manager rather than a third-party plugin manager.

## What is here

- **Zetesis as the primary file picker.** A local Zig application that exists because I was not fully happy with the available picker options for my main file-navigation workflow.
- **fzf-lua for everything else.** Buffers, help, diagnostics, LSP references, code actions, and secondary file-search workflows remain available through fzf-lua.
- **Built-in LSP configuration** with Blink completion, Fidget progress notifications, diagnostic UI, and Rust support through rustaceanvim.
- **Formatting on save** through Conform, with per-language formatter choices for web languages, Lua, Nix, Python-adjacent tooling, shell, SQL, OCaml, QML, Markdown, and more.
- **Treesitter-first editing** with custom filetype overrides, snippets, tag support, commentstring handling, and visual whitespace.
- **Git and review tools:** Gitsigns, CodeDiff, and a more useful quickfix list.
- **A custom interface:** TokyoNight-based semantic highlights, custom tabline and statuscolumn, folding, rounded UI borders, and no mouse.
- **Terminal workflow integration:** tmux-aware split movement/resizing, Yazi integration, and Neovide-specific adjustments.

## Zetesis

Zetesis (`zt`) is the core picker for project files, bound to `<leader>sf` (with `<leader>` set to `Space`). It is included in [`zetesis/`](zetesis/) and deliberately lives alongside the Neovim configuration rather than being another Lua plugin.

I built it because the current picker landscape did not quite fit the interaction I wanted for opening project files. It is a focused terminal picker rather than a general replacement for every fuzzy-finding use case.

When invoked, Neovim starts `zt files` in a small floating terminal. Zetesis gathers project files from Git when possible and falls back to filesystem walking otherwise. It fuzzy-ranks the query interactively, shows Git status in the results, and returns selections as JSON Lines. The Lua bridge decodes that protocol and performs the requested Neovim action: edit, vertical split, tab, or quickfix. The protocol also supports locations and text entries, leaving room for non-file picker sources later.

The binary is expected at `zetesis/zig-out/bin/zt`. Build the local Zig projects before using `<leader>sf`:

```sh
just bootstrap
```

If it is not built, Neovim reports the missing binary instead of silently falling back to another picker.

## Ekhos

Ekhos is a local Zig sound renderer for Neovim interaction cues. `just bootstrap` renders its WAV palette into `ekhos/zig-out/sounds/`; Neovim uses the platform audio player when a configured event occurs.

## Requirements

Use the current stable Neovim release. The rest is intentionally external and modular:

| Tool | Used for | Required? |
| --- | --- | --- |
| `git` | Plugin downloads, Git-aware Zetesis file discovery | Yes |
| `ripgrep` | fzf-lua file search | Recommended |
| `fd` | General file finding | Recommended |
| Zig | Building Zetesis and Ekhos | For local picker and sounds |
| just | Building local Zig projects | For `just bootstrap` |
| Language servers and formatters | LSP and formatting features | Only for the languages you use |
| `tmux` | Cross-pane navigation and resizing | Optional |
| `yazi` | File manager integration | Optional |

Language tooling is configured, not installed or managed here. Install only the servers and formatters relevant to your projects; inspect [`lua/plugins/lsp-config.lua`](lua/plugins/lsp-config.lua) and [`lua/plugins/conform.lua`](lua/plugins/conform.lua) for the current lists.

## Getting started

Place this repository at Neovim's configuration path (normally `~/.config/nvim` on Linux and macOS), run `just bootstrap`, then start Neovim to let `vim.pack` fetch the declared plugins.

This is a personal configuration, so newcomers should treat it as readable source rather than a turnkey distribution. In particular, review:

- [`lua/config/settings.lua`](lua/config/settings.lua) for editor defaults;
- [`lua/config/keymaps.lua`](lua/config/keymaps.lua) for global mappings;
- [`lua/plugins/lsp-config.lua`](lua/plugins/lsp-config.lua) for enabled language servers; and
- [`lua/plugins/conform.lua`](lua/plugins/conform.lua) for formatting on save.

## Key bindings

`<leader>` is `Space`. Which-key exposes the broader mapping surface; these are the useful entry points:

| Mapping | Action |
| --- | --- |
| `<leader>sf` | Open the Zetesis project-file picker |
| `<leader>sr` | Search files with fzf-lua |
| `<leader>sb` | Switch buffers |
| `<leader>sd` | Show diagnostics for the current buffer |
| `gd` | Go to LSP definition |
| `<leader>lr` | Find LSP references |
| `<leader>lc` | Show LSP code actions |
| `<leader>rn` | Rename symbol |
| `<leader>mp` | Format the current buffer |
| `<leader>gd` | Compare the current file with `HEAD` |
| `]h` / `[h` | Next / previous Git hunk |
| `]d` / `[d` | Next / previous diagnostic |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Move between Neovim and tmux panes |
| `<A-h>` / `<A-j>` / `<A-k>` / `<A-l>` | Resize tmux-aware splits |

## Layout

```text
.
├── init.lua                 # Load order and plugin entry points
├── lua/
│   ├── config/              # Options, keymaps, UI, colors, folding, Zetesis bridge
│   ├── lsp/                 # Per-server overrides
│   └── plugins/             # vim.pack declarations and plugin configuration
├── after/ftplugin/          # Filetype-specific settings
├── snippets/                # Custom VS Code-style snippets
├── zetesis/                 # Zig source for the primary project-file picker
├── nvim-pack-lock.json      # Plugin versions locked by vim.pack
└── .stylua.toml             # Lua formatting settings
```

## Customization notes

- The base colorscheme is TokyoNight; semantic palette and highlight overrides are in [`lua/config/palette.lua`](lua/config/palette.lua) and [`lua/config/highlights.lua`](lua/config/highlights.lua).
- Formatting runs on save. Remove or change entries in `formatters_by_ft` if that does not suit a project.
- The default indentation is two spaces, and persistent undo history is enabled.
- The config keeps project-specific ShaDa state, so jumps, marks, and command history do not spill between projects.
- The mouse is disabled by design.
