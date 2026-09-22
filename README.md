# Neovim Configuration

<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/699605b6-ebf1-4ec5-996d-178d7c45ad9c" />
<img width="2525" height="1517" alt="image" src="https://github.com/user-attachments/assets/748abb06-f949-49fa-ad6f-789bddd98301" />

this is my neovim setup. with a conjoined zig project for sounds (ekhos).

> [!NOTE]
> run `just bootstrap` with zig installed to build ekhos.

## What is here

- I use vimpack, it's better, I found some ways to lazy load myself. it's simple.
- Formatting with conform.
- Lsp setup with blink completion, fidget progress notifications, diagnostic ui, and rust support through rustaceanvim.
- FFF for primary file search. Fzf-lua for buffers, help, diagnostics, lsp, and secondary search.
- Some treesitter changes, snippets, tag support, commentstring handling, and visual whitespace.
- Gitsigns, codediff, and a the quickfix list plugin.
- Tokyo night based semantic highlights, but drinks the actual hex colors from a different source. (external file set by chezmoi)
- Custom tabline and statuscolumn, folding, rounded ui borders, and no mouse.
- Tmux-aware split movement/resizing, yazi integration, and neovide-specific adjustments.

| Tool                            | Used for                                           | Required?                      |
| ------------------------------- | -------------------------------------------------- | ------------------------------ |
| `git`                           | Plugin downloads                                   | Yes                            |
| `ripgrep`                       | fzf-lua file search                                | Recommended                    |
| `fd`                            | General file finding                               | Recommended                    |
| Zig                             | Building Ekhos                                     | For sounds                     |
| just                            | Building local Zig projects                        | For `just bootstrap`           |
| Language servers and formatters | LSP and formatting features                        | Only for the languages you use |
| `tmux`                          | Cross-pane navigation and resizing                 | Optional                       |
| `yazi`                          | File manager integration                           | Optional                       |
