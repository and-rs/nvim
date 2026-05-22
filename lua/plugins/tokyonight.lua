vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })
vim.cmd("colorscheme tokyonight-day")

if vim.o.background == "dark" then
  vim.g.terminal_color_0 = "#181a27"
  vim.g.terminal_color_8 = "#727AAC"
  vim.g.terminal_color_1 = "#ff757f"
  vim.g.terminal_color_9 = "#ff757f"
  vim.g.terminal_color_2 = "#c3e88d"
  vim.g.terminal_color_10 = "#c3e88d"
  vim.g.terminal_color_3 = "#ffc777"
  vim.g.terminal_color_11 = "#ffc777"
  vim.g.terminal_color_4 = "#82aaff"
  vim.g.terminal_color_12 = "#82aaff"
  vim.g.terminal_color_5 = "#c099ff"
  vim.g.terminal_color_13 = "#c099ff"
  vim.g.terminal_color_6 = "#86e1fc"
  vim.g.terminal_color_14 = "#86e1fc"
  vim.g.terminal_color_7 = "#c8d3f5"
  vim.g.terminal_color_15 = "#c8d3f5"
end

if vim.o.background == "light" then
  vim.g.terminal_color_0 = "#dfe2ec"
  vim.g.terminal_color_8 = "#777C92"
  vim.g.terminal_color_1 = "#C41C46"
  vim.g.terminal_color_9 = "#C41C46"
  vim.g.terminal_color_2 = "#587539"
  vim.g.terminal_color_10 = "#587539"
  vim.g.terminal_color_3 = "#A27629"
  vim.g.terminal_color_11 = "#A27629"
  vim.g.terminal_color_4 = "#2E7DE9"
  vim.g.terminal_color_12 = "#2E7DE9"
  vim.g.terminal_color_5 = "#9854F1"
  vim.g.terminal_color_13 = "#9854F1"
  vim.g.terminal_color_6 = "#007EA8"
  vim.g.terminal_color_14 = "#007EA8"
  vim.g.terminal_color_7 = "#D0D5E3"
  vim.g.terminal_color_15 = "#3760BF"
end
