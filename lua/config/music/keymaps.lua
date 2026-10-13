local map = require("config.map").set

map("n", "<leader>tl", function()
  require("config.music.live").toggle()
end, "Toggle Live tab")
