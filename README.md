# Neovim Configuration

<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/699605b6-ebf1-4ec5-996d-178d7c45ad9c" />
<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/748abb06-f949-49fa-ad6f-789bddd98301" />

this is my neovim setup. with some conjoined zig projects. for sounds (ekhos) and for a custom WIP fuzzy finder (zetesis)

> [!NOTE]
> run `just bootstrap` with zig installed to build ekhos and zetesis.

## What is here

- I use vimpack, it's better, I found some ways to lazy load myself. it's simple.
- Formatting with conform.
- Lsp setup with blink completion, fidget progress notifications, diagnostic ui, and rust support through rustaceanvim.
- Fzf-lua for: buffers, help, diagnostics, lsp references, code actions, and secondary file-search workflows remain available through fzf-lua.
- Some treesitter changes, snippets, tag support, commentstring handling, and visual whitespace.
- Gitsigns, codediff, and a the quickfix list plugin.
- Tokyo night based semantic highlights, but drinks the actual hex colors from a different source. (external file set by chezmoi)
- Custom tabline and statuscolumn, folding, rounded ui borders, and no mouse.
- Tmux-aware split movement/resizing, yazi integration, and neovide-specific adjustments.

| Tool                            | Used for                                           | Required?                      |
| ------------------------------- | -------------------------------------------------- | ------------------------------ |
| `git`                           | Plugin downloads, Git-aware Zetesis file discovery | Yes                            |
| `ripgrep`                       | fzf-lua file search                                | Recommended                    |
| `fd`                            | General file finding                               | Recommended                    |
| Zig                             | Building Zetesis and Ekhos                         | For local picker and sounds    |
| just                            | Building local Zig projects                        | For `just bootstrap`           |
| Language servers and formatters | LSP and formatting features                        | Only for the languages you use |
| `tmux`                          | Cross-pane navigation and resizing                 | Optional                       |
| `yazi`                          | File manager integration                           | Optional                       |
