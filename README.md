# Neovim Configuration

My setup. Sounds: `just bootstrap` (requires Zig).

## Dependencies

Plugins are managed by `vim.pack`; external tools are installed separately.

- **Core:** recent Neovim with `vim.pack` and `vim._core.ui2`, Git, Bash, `~/.config/colors/current.lua` (from my dotfiles).
- **Search / files:** `fzf`, `ripgrep`, `fd`, `yazi`, `file`; external openers configured in `yazi.toml`.
- **Parser installation:** C compiler, `curl`, `tar`, `tree-sitter` CLI.
- **Language servers (as needed):** `qmlls`, `vtsls` + TypeScript, `vscode-html-language-server`, `biome`, `vscode-css-language-server`, `vscode-json-language-server`, `vscode-eslint-language-server`, `tailwindcss-language-server`, `ty`, `ruff`, `fish-lsp`, `nu`, `bash-language-server`, `zls`, `clangd`, `gopls`, `buf`, `yaml-language-server`, `nil`, `lua-language-server`, `ocamllsp`, `ast-grep`, `glsl_analyzer`, `rust-analyzer`. Node.js for JS-based servers.
- **Formatters (as needed):** `biome`, `rustywind`, `deno`, `xmlstarlet`, `topiary` (with Nushell grammar/config), `beautysh`, `fish_indent`, `djlint`, `sqlfluff`, `gotmplfmt`, `ocamlformat`, `clang-format`, `qmlformat`, `yamlfmt`, `kdlfmt`, `stylua`, `nixfmt`.
- **Optional:** `tmux`, Neovide, clipboard provider for your platform; Zig + `just` for sounds, `pw-play` (Linux) / `afplay` (macOS) / PowerShell (Windows) for playback; `sclang` + `tidal` for live coding; Rust/Cargo if FFF needs building instead of a prebuilt binary.

<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/699605b6-ebf1-4ec5-996d-178d7c45ad9c" />
<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/748abb06-f949-49fa-ad6f-789bddd98301" />
