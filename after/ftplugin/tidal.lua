local map = require("config.map").set
local tidal = require("config.tidal")

map("n", "<leader>ts", tidal.start, "Start or show Tidal", { buffer = true })
map("n", "<leader>tr", tidal.send_buffer, "Send buffer to Tidal", { buffer = true })
map("n", "<leader>th", tidal.hush, "Hush Tidal", { buffer = true })
