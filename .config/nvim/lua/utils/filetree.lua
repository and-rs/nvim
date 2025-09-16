local M = {}

local default_config = {
  split_command = "40vs",
  buf_name = "Filetree",
  mode = "keep",
}

local config = {}

-- Global state
local treeviewer_buf = nil
local treeviewer_win = nil
local original_win = nil
local current_path = nil
local current_items = nil
local navigation_history = {}
local expanded_folders = {}
local clipboard = nil
local clipboard_mode = nil

-- Setup highlights
local function setup_highlights()
  vim.cmd("highlight default link TreeViewerFolder Directory")
  vim.cmd("highlight default TreeViewerSlash guifg=#f1c1bd ctermfg=75")
end

-- Function to get directory contents
local function get_directory_contents(path)
  local items = {}
  local handle = io.popen('ls -la "' .. path .. '" 2>/dev/null')
  if not handle then
    return items
  end
  for line in handle:lines() do
    if not line:match("^total") and not line:match("%s%.%s") and not line:match("%s%.%.%s") then
      local permissions, links, owner, group, size, month, day, time, name =
        line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.+)$")
      if name and name ~= "." and name ~= ".." then
        local is_dir = permissions:sub(1, 1) == "d"
        table.insert(items, {
          name = name,
          is_directory = is_dir,
          full_path = path .. "/" .. name,
          depth = 0,
        })
      end
    end
  end
  handle:close()
  table.sort(items, function(a, b)
    if a.is_directory and not b.is_directory then
      return true
    elseif not a.is_directory and b.is_directory then
      return false
    else
      return a.name:lower() < b.name:lower()
    end
  end)
  return items
end

-- Function to get expanded tree structure for "keep" mode
local function get_expanded_tree(base_path, depth)
  depth = depth or 0
  local items = {}
  local handle = io.popen('ls -la "' .. base_path .. '" 2>/dev/null')
  if not handle then
    return items
  end
  local current_level_items = {}
  for line in handle:lines() do
    if not line:match("^total") and not line:match("%s%.%s") and not line:match("%s%.%.%s") then
      local permissions, links, owner, group, size, month, day, time, name =
        line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.+)$")
      if name and name ~= "." and name ~= ".." then
        local is_dir = permissions:sub(1, 1) == "d"
        local full_path = base_path .. "/" .. name
        table.insert(current_level_items, {
          name = name,
          is_directory = is_dir,
          full_path = full_path,
          depth = depth,
        })
      end
    end
  end
  handle:close()
  table.sort(current_level_items, function(a, b)
    if a.is_directory and not b.is_directory then
      return true
    elseif not a.is_directory and b.is_directory then
      return false
    else
      return a.name:lower() < b.name:lower()
    end
  end)
  for _, item in ipairs(current_level_items) do
    table.insert(items, item)
    if item.is_directory then
      if expanded_folders[item.full_path] then
        local sub_items = get_expanded_tree(item.full_path, depth + 1)
        if #sub_items == 0 then
          -- Add virtual placeholder for empty folder
          table.insert(items, {
            name = "",
            is_directory = false,
            full_path = item.full_path .. "/.",
            depth = depth + 1,
          })
        else
          for _, sub_item in ipairs(sub_items) do
            table.insert(items, sub_item)
          end
        end
      end
    end
  end
  return items
end

-- Function to populate buffer with directory contents
local function populate_buffer(buf, path)
  local items
  if config.mode == "keep" then
    items = get_expanded_tree(path)
  else
    items = get_directory_contents(path)
  end
  current_items = items
  current_path = path
  local lines = {}
  -- Add root folder as the first line
  local root_name = vim.fn.fnamemodify(path, ":t")
  root_name = root_name == "" and path or root_name
  table.insert(lines, root_name .. "/")
  -- Check if directory is empty and add placeholder in both modes
  if #items == 0 then
    -- Add virtual placeholder for empty directory
    table.insert(items, {
      name = "",
      is_directory = false,
      full_path = path .. "/.",
      depth = 0,
    })
  end
  -- Shift existing items by depth +1
  for i, item in ipairs(items) do
    local indent = string.rep("| ", item.depth + 1)
    local display_name = item.is_directory and (item.name .. "/") or item.name
    table.insert(lines, indent .. display_name)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ns_id = vim.api.nvim_create_namespace("treeviewer_highlights")
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  -- Highlight root folder
  vim.api.nvim_buf_add_highlight(buf, ns_id, "TreeViewerFolder", 0, 0, #root_name)
  vim.api.nvim_buf_add_highlight(buf, ns_id, "TreeViewerSlash", 0, #root_name, #root_name + 1)
  -- Highlight all other items
  for i, item in ipairs(items) do
    local start_col = (item.depth + 1) * 2
    if item.is_directory then
      local end_col = start_col + #item.name
      vim.api.nvim_buf_add_highlight(buf, ns_id, "TreeViewerFolder", i, start_col, end_col)
      vim.api.nvim_buf_add_highlight(buf, ns_id, "TreeViewerSlash", i, end_col, end_col + 1)
    end
  end
end

-- Function to position cursor on item
local function position_cursor_on_item(target_name)
  if not current_items then
    return false
  end
  for i, item in ipairs(current_items) do
    if item.name == target_name then
      vim.api.nvim_win_set_cursor(treeviewer_win, { i + 1, 0 })
      local ns_id = vim.api.nvim_create_namespace("treeviewer_current_file")
      vim.api.nvim_buf_clear_namespace(treeviewer_buf, ns_id, 0, -1)
      vim.api.nvim_buf_add_highlight(treeviewer_buf, ns_id, "CursorLine", i, 0, -1)
      return true
    end
  end
  return false
end

-- Function to expand path to current file
local function expand_path_to_current_file()
  if not original_win or not vim.api.nvim_win_is_valid(original_win) then
    return
  end
  local current_file_path = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(original_win))
  if current_file_path == "" then
    return
  end
  local file_dir = vim.fn.fnamemodify(current_file_path, ":h")
  local path_parts = {}
  local temp_path = file_dir
  while temp_path ~= current_path and temp_path ~= vim.fn.fnamemodify(temp_path, ":h") do
    if temp_path:sub(1, #current_path) == current_path then
      table.insert(path_parts, 1, temp_path)
    end
    temp_path = vim.fn.fnamemodify(temp_path, ":h")
  end
  for _, path in ipairs(path_parts) do
    expanded_folders[path] = true
  end
end

-- Function to highlight current file
local function highlight_current_file()
  if not original_win or not vim.api.nvim_win_is_valid(original_win) then
    return
  end
  local current_file_path = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(original_win))
  if current_file_path == "" then
    return
  end
  local current_file_name = vim.fn.fnamemodify(current_file_path, ":t")
  if config.mode == "keep" then
    expand_path_to_current_file()
    vim.bo[treeviewer_buf].modifiable = true
    populate_buffer(treeviewer_buf, current_path)
    vim.bo[treeviewer_buf].modifiable = false
  end
  position_cursor_on_item(current_file_name)
end

-- Function to get unique filename
local function get_unique_filename(target_dir, original_name)
  local full_path = target_dir .. "/" .. original_name
  if vim.fn.filereadable(full_path) == 0 and vim.fn.isdirectory(full_path) == 0 then
    return original_name
  end
  local name_without_ext = vim.fn.fnamemodify(original_name, ":r")
  local extension = vim.fn.fnamemodify(original_name, ":e")
  local counter = 2
  local new_name
  repeat
    if extension ~= "" then
      new_name = name_without_ext .. counter .. "." .. extension
    else
      new_name = name_without_ext .. counter
    end
    full_path = target_dir .. "/" .. new_name
    counter = counter + 1
  until vim.fn.filereadable(full_path) == 0 and vim.fn.isdirectory(full_path) == 0
  return new_name
end

-- Function to copy item
local function copy_item(source, target)
  if vim.fn.isdirectory(source) == 1 then
    local cmd = string.format('cp -r "%s" "%s"', source, target)
    local result = os.execute(cmd)
    return result == 0
  else
    local cmd = string.format('cp "%s" "%s"', source, target)
    local result = os.execute(cmd)
    return result == 0
  end
end

-- Function to move item
local function move_item(source, target)
  local cmd = string.format('mv "%s" "%s"', source, target)
  local result = os.execute(cmd)
  return result == 0
end

-- Function to get visual selection
local function get_visual_selection()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local total_lines = vim.api.nvim_buf_line_count(treeviewer_buf)
  if start_line == 0 or end_line == 0 or start_line > total_lines or end_line > total_lines then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    if start_pos[2] == 0 or end_pos[2] == 0 then
      return {}
    end
    start_line = start_pos[2]
    end_line = end_pos[2]
  end
  local selected_items = {}
  for i = math.max(1, start_line - 1), end_line - 1 do
    if current_items and current_items[i] then
      table.insert(selected_items, current_items[i])
    end
  end
  return selected_items
end

-- Function to highlight selected items
local function highlight_selected_items(items, highlight_group)
  local ns_id = vim.api.nvim_create_namespace("treeviewer_selection")
  vim.api.nvim_buf_clear_namespace(treeviewer_buf, ns_id, 0, -1)
  for _, item in ipairs(items) do
    for i, current_item in ipairs(current_items) do
      if current_item.full_path == item.full_path then
        vim.api.nvim_buf_add_highlight(treeviewer_buf, ns_id, highlight_group, i, 0, -1)
        break
      end
    end
  end
end

-- Function to clear all selection highlighting
local function clear_selection_highlighting()
  local ns_id = vim.api.nvim_create_namespace("treeviewer_selection")
  vim.api.nvim_buf_clear_namespace(treeviewer_buf, ns_id, 0, -1)
end

-- Split filename into basename + extension
local function split_filename(name)
  local idx = name:match("^.*()%.")
  if idx then
    return name:sub(1, idx - 1), name:sub(idx)
  else
    return name, ""
  end
end

-- Handle rename
local function handle_rename(include_extension)
  local cursor_line = vim.api.nvim_win_get_cursor(treeviewer_win)[1]
  if cursor_line <= 1 or not current_items or cursor_line - 1 > #current_items then
    return
  end
  local selected_item = current_items[cursor_line - 1]
  local target_dir = vim.fn.fnamemodify(selected_item.full_path, ":h")
  local basename, extension = split_filename(selected_item.name)
  local default_input = include_extension and (basename .. extension) or basename
  vim.ui.input({
    prompt = "Rename: ",
    default = default_input,
  }, function(input)
    if not input or vim.trim(input) == "" then
      print("Rename cancelled")
      return
    end
    input = vim.trim(input)
    if not include_extension then
      input = input .. extension
    end
    if input == selected_item.name then
      print("Name unchanged")
      return
    end
    if input:match('[/\\<>:"|?*]') then
      print("Invalid characters in name")
      return
    end
    local new_path = target_dir .. "/" .. input
    if vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1 then
      print("A file or folder with that name already exists")
      return
    end
    local cmd = string.format('mv "%s" "%s"', selected_item.full_path, new_path)
    local result = os.execute(cmd)
    if result == 0 then
      print("Renamed to: " .. input)
      vim.bo[treeviewer_buf].modifiable = true
      populate_buffer(treeviewer_buf, current_path)
      vim.bo[treeviewer_buf].modifiable = false
      position_cursor_on_item(input)
    else
      print("Failed to rename " .. selected_item.name)
    end
    if treeviewer_win and vim.api.nvim_win_is_valid(treeviewer_win) then
      vim.api.nvim_set_current_win(treeviewer_win)
    end
  end)
end

-- Handle copy (y)
local function handle_copy()
  local selected_items = {}
  local cursor_pos = vim.api.nvim_win_get_cursor(treeviewer_win)
  local mode = vim.api.nvim_get_mode().mode
  if mode == "V" then
    local start_line = vim.fn.line("v")
    local end_line = cursor_pos[1]
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    for i = math.max(1, start_line - 1), end_line - 1 do
      if current_items and current_items[i] then
        table.insert(selected_items, current_items[i])
      end
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  else
    local cursor_line = cursor_pos[1]
    if cursor_line > 1 and current_items and cursor_line - 1 <= #current_items then
      table.insert(selected_items, current_items[cursor_line - 1])
    end
  end
  vim.api.nvim_win_set_cursor(treeviewer_win, cursor_pos)
  if #selected_items == 0 then
    print("No items selected")
    return
  end
  clipboard = selected_items
  clipboard_mode = "copy"
  clear_selection_highlighting()
  if #selected_items == 1 then
    local item_type = selected_items[1].is_directory and "folder" or "file"
    print("Copied " .. item_type .. ": " .. selected_items[1].name)
  else
    print("Copied " .. #selected_items .. " items")
  end
end

-- Handle cut (x)
local function handle_cut()
  local selected_items = {}
  local cursor_pos = vim.api.nvim_win_get_cursor(treeviewer_win)
  local mode = vim.api.nvim_get_mode().mode
  if mode == "V" then
    local start_line = vim.fn.line("v")
    local end_line = cursor_pos[1]
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    for i = math.max(1, start_line - 1), end_line - 1 do
      if current_items and current_items[i] then
        table.insert(selected_items, current_items[i])
      end
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  else
    local cursor_line = cursor_pos[1]
    if cursor_line > 1 and current_items and cursor_line - 1 <= #current_items then
      table.insert(selected_items, current_items[cursor_line - 1])
    end
  end
  vim.api.nvim_win_set_cursor(treeviewer_win, cursor_pos)
  if #selected_items == 0 then
    print("No items selected")
    return
  end
  clipboard = selected_items
  clipboard_mode = "cut"
  highlight_selected_items(selected_items, "Comment")
  if #selected_items == 1 then
    local item_type = selected_items[1].is_directory and "folder" or "file"
    print("Cut " .. item_type .. ": " .. selected_items[1].name)
  else
    print("Cut " .. #selected_items .. " items")
  end
end

-- Handle paste (p)
local function handle_paste()
  if not clipboard or not clipboard_mode or #clipboard == 0 then
    print("Nothing to paste")
    return
  end
  local cursor_line = vim.api.nvim_win_get_cursor(treeviewer_win)[1]
  if cursor_line <= 1 or not current_items or cursor_line - 1 > #current_items then
    return
  end
  local selected_item = current_items[cursor_line - 1]
  local target_dir
  if selected_item.is_directory then
    target_dir = selected_item.full_path
  else
    target_dir = vim.fn.fnamemodify(selected_item.full_path, ":h")
  end
  local successful_operations = 0
  local failed_operations = 0
  for _, clipboard_item in ipairs(clipboard) do
    if clipboard_mode == "cut" then
      local current_dir = vim.fn.fnamemodify(clipboard_item.full_path, ":h")
      if current_dir == target_dir then
        print("Cannot move " .. clipboard_item.name .. " to same location")
        failed_operations = failed_operations + 1
        goto continue
      end
      if
        clipboard_item.is_directory
        and target_dir:sub(1, #clipboard_item.full_path) == clipboard_item.full_path
      then
        print("Cannot move directory " .. clipboard_item.name .. " into itself")
        failed_operations = failed_operations + 1
        goto continue
      end
    end
    local new_name = get_unique_filename(target_dir, clipboard_item.name)
    local target_path = target_dir .. "/" .. new_name
    local success = false
    if clipboard_mode == "copy" then
      success = copy_item(clipboard_item.full_path, target_path)
    else
      success = move_item(clipboard_item.full_path, target_path)
    end
    if success then
      successful_operations = successful_operations + 1
    else
      failed_operations = failed_operations + 1
    end
    ::continue::
  end
  if successful_operations > 0 then
    local action = clipboard_mode == "copy" and "Pasted" or "Moved"
    print(action .. " " .. successful_operations .. " items")
  end
  if failed_operations > 0 then
    print("Failed: " .. failed_operations .. " items")
  end
  clipboard = nil
  clipboard_mode = nil
  clear_selection_highlighting()
  vim.bo[treeviewer_buf].modifiable = true
  if config.mode == "keep" then
    if selected_item.is_directory then
      expanded_folders[selected_item.full_path] = true
    end
    populate_buffer(treeviewer_buf, current_path)
  else
    populate_buffer(treeviewer_buf, current_path)
  end
  vim.bo[treeviewer_buf].modifiable = false
end

-- Handle add
local function handle_add()
  local cursor_line = vim.api.nvim_win_get_cursor(treeviewer_win)[1]
  local target_dir
  if cursor_line <= 1 or not current_items or cursor_line - 1 > #current_items then
    target_dir = current_path
  else
    local selected_item = current_items[cursor_line - 1]
    if selected_item.is_directory then
      target_dir = selected_item.full_path
    else
      target_dir = vim.fn.fnamemodify(selected_item.full_path, ":h")
    end
  end
  local prompt = "Enter name (end with / for directory): "
  vim.ui.input({
    prompt = prompt,
  }, function(input)
    if not input or input:gsub("%s+", "") == "" then
      print("Creation cancelled")
      return
    end
    input = vim.trim(input)
    local is_directory = input:sub(-1) == "/"
    local item_name = is_directory and input:sub(1, -2) or input
    if item_name == "" then
      print("Invalid name")
      return
    end
    if item_name:match('[/\\<>:"|?*]') then
      print("Invalid characters in name")
      return
    end
    local target_path = target_dir .. "/" .. item_name
    local success = false
    local item_type = is_directory and "directory" or "file"
    if vim.fn.filereadable(target_path) == 1 or vim.fn.isdirectory(target_path) == 1 then
      print(item_type:gsub("^%l", string.upper) .. " already exists: " .. item_name)
      return
    end
    if is_directory then
      local cmd = string.format('mkdir -p "%s"', target_path)
      local result = os.execute(cmd)
      success = (result == 0)
    else
      local cmd = string.format('touch "%s"', target_path)
      local result = os.execute(cmd)
      success = (result == 0)
    end
    if success then
      print("Created " .. item_type .. ": " .. item_name)
      vim.bo[treeviewer_buf].modifiable = true
      if config.mode == "keep" then
        if cursor_line > 1 and current_items and cursor_line - 1 <= #current_items then
          local selected_item = current_items[cursor_line - 1]
          if selected_item.is_directory then
            expanded_folders[selected_item.full_path] = true
          end
        end
        if is_directory then
          expanded_folders[target_path] = nil
        end
        populate_buffer(treeviewer_buf, current_path)
      else
        populate_buffer(treeviewer_buf, current_path)
      end
      vim.bo[treeviewer_buf].modifiable = false
      position_cursor_on_item(item_name)
    else
      print("Failed to create " .. item_type .. ": " .. item_name)
    end
    if treeviewer_win and vim.api.nvim_win_is_valid(treeviewer_win) then
      vim.api.nvim_set_current_win(treeviewer_win)
    end
  end)
end

local function collapse_if_empty(folder_path)
  if not expanded_folders[folder_path] then
    return
  end
  local handle = io.popen('ls -la "' .. folder_path .. '" 2>/dev/null')
  if not handle then
    return
  end
  local has_items = false
  for line in handle:lines() do
    if not line:match("^total") and not line:match("%s%.%s") and not line:match("%s%.%.%s") then
      local permissions, links, owner, group, size, month, day, time, name =
        line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.+)$")
      if name and name ~= "." and name ~= ".." then
        has_items = true
        break
      end
    end
  end
  handle:close()
  if not has_items then
    expanded_folders[folder_path] = nil
  end
end

-- Perform deletion function
local function perform_deletion(selected_items, cursor_pos)
  if #selected_items == 0 then
    print("No items selected")
    return
  end
  vim.cmd("normal! \\<Esc>")
  clear_selection_highlighting()
  local prompt
  if #selected_items == 1 then
    local item_type = selected_items[1].is_directory and "folder" or "file"
    prompt = string.format("Remove %s '%s'? [y/N]: ", item_type, selected_items[1].name)
  else
    prompt = string.format("Remove %d selected items? [y/N]: ", #selected_items)
  end
  vim.ui.input({ prompt = prompt }, function(input)
    if not input then
      print("Deletion cancelled")
      if treeviewer_win and vim.api.nvim_win_is_valid(treeviewer_win) then
        vim.api.nvim_set_current_win(treeviewer_win)
      end
      return
    end
    input = input:lower():gsub("%s+", "")
    if input == "y" or input == "yes" then
      local successful_deletions = 0
      local failed_deletions = 0
      local parent_folders_to_check = {}
      for _, item in ipairs(selected_items) do
        local cmd = item.is_directory and string.format('rm -rf "%s"', item.full_path)
          or string.format('rm "%s"', item.full_path)
        local result = os.execute(cmd)
        if result == 0 then
          successful_deletions = successful_deletions + 1
          local parent_dir = vim.fn.fnamemodify(item.full_path, ":h")
          parent_folders_to_check[parent_dir] = true
        else
          failed_deletions = failed_deletions + 1
          print("Failed to remove: " .. item.name)
        end
      end
      for parent_dir, _ in pairs(parent_folders_to_check) do
        collapse_if_empty(parent_dir)
      end
      if successful_deletions > 0 then
        if #selected_items == 1 then
          local item_type = selected_items[1].is_directory and "folder" or "file"
          print("Removed " .. item_type .. ": " .. selected_items[1].name)
        else
          print("Removed " .. successful_deletions .. " items")
        end
      end
      if failed_deletions > 0 then
        print("Failed to remove " .. failed_deletions .. " items")
      end
      if treeviewer_buf and vim.api.nvim_buf_is_valid(treeviewer_buf) then
        vim.bo[treeviewer_buf].modifiable = true
        populate_buffer(treeviewer_buf, current_path)
        vim.bo[treeviewer_buf].modifiable = false
        if cursor_pos and current_items then
          local new_cursor_line = math.min(cursor_pos[1], #current_items + 1)
          if
            new_cursor_line > 1
            and treeviewer_win
            and vim.api.nvim_win_is_valid(treeviewer_win)
          then
            vim.api.nvim_win_set_cursor(treeviewer_win, { new_cursor_line, 0 })
          end
        end
      end
    else
      print("Deletion cancelled")
    end
    if treeviewer_win and vim.api.nvim_win_is_valid(treeviewer_win) then
      vim.api.nvim_set_current_win(treeviewer_win)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    end
  end)
end

local function handle_delete()
  local selected_items = {}
  local cursor_pos = vim.api.nvim_win_get_cursor(treeviewer_win)
  local mode = vim.api.nvim_get_mode().mode
  if mode == "V" then
    local start_line = vim.fn.line("v")
    local end_line = cursor_pos[1]
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    for i = math.max(1, start_line - 1), end_line - 1 do
      if current_items and current_items[i] then
        table.insert(selected_items, current_items[i])
      end
    end
    perform_deletion(selected_items, cursor_pos)
  else
    local cursor_line = cursor_pos[1]
    if cursor_line > 1 and current_items and cursor_line - 1 <= #current_items then
      table.insert(selected_items, current_items[cursor_line - 1])
    end
    perform_deletion(selected_items, cursor_pos)
  end
end

local function handle_enter()
  local cursor_line = vim.api.nvim_win_get_cursor(treeviewer_win)[1]
  if cursor_line <= 1 then
    return
  end
  if not current_items or cursor_line - 1 > #current_items then
    return
  end
  local selected_item = current_items[cursor_line - 1]
  -- Handle empty folder dummy item
  if selected_item.name == "" and selected_item.full_path:match("/%.$") then
    if config.mode == "dive" then
      if not current_path then
        return
      end
      local parent_path = vim.fn.fnamemodify(current_path, ":h")
      if parent_path == current_path then
        return
      end
      vim.bo[treeviewer_buf].modifiable = true
      populate_buffer(treeviewer_buf, parent_path)
      vim.bo[treeviewer_buf].modifiable = false
      if #navigation_history > 0 then
        local last_location = table.remove(navigation_history)
        if last_location.path == parent_path then
          position_cursor_on_item(last_location.focus_item)
        else
          highlight_current_file()
        end
      else
        highlight_current_file()
      end
    else
      local parent_path = selected_item.full_path:gsub("/%.$", "")
      expanded_folders[parent_path] = nil
      vim.bo[treeviewer_buf].modifiable = true
      populate_buffer(treeviewer_buf, current_path)
      vim.bo[treeviewer_buf].modifiable = false
      local parent_name = vim.fn.fnamemodify(parent_path, ":t")
      position_cursor_on_item(parent_name)
    end
    return
  end
  if selected_item.is_directory then
    if config.mode == "dive" then
      table.insert(navigation_history, {
        path = current_path,
        focus_item = selected_item.name,
      })
      vim.bo[treeviewer_buf].modifiable = true
      populate_buffer(treeviewer_buf, selected_item.full_path)
      vim.bo[treeviewer_buf].modifiable = false
    else
      if expanded_folders[selected_item.full_path] then
        expanded_folders[selected_item.full_path] = nil
      else
        expanded_folders[selected_item.full_path] = true
      end
      vim.bo[treeviewer_buf].modifiable = true
      populate_buffer(treeviewer_buf, current_path)
      vim.bo[treeviewer_buf].modifiable = false
      position_cursor_on_item(selected_item.name)
    end
  else
    if original_win and vim.api.nvim_win_is_valid(original_win) then
      vim.api.nvim_set_current_win(original_win)
      vim.cmd("edit " .. vim.fn.fnameescape(selected_item.full_path))
    end
    if treeviewer_win and vim.api.nvim_win_is_valid(treeviewer_win) then
      vim.api.nvim_win_close(treeviewer_win, true)
      treeviewer_win = nil
      treeviewer_buf = nil
      original_win = nil
      navigation_history = {}
      expanded_folders = {}
    end
  end
end

local function handle_l()
  handle_enter()
end

local function handle_h()
  if config.mode == "dive" then
    if not current_path then
      return
    end
    local parent_path = vim.fn.fnamemodify(current_path, ":h")
    if parent_path == current_path then
      return
    end
    vim.bo[treeviewer_buf].modifiable = true
    populate_buffer(treeviewer_buf, parent_path)
    vim.bo[treeviewer_buf].modifiable = false
    if #navigation_history > 0 then
      local last_location = table.remove(navigation_history)
      if last_location.path == parent_path then
        position_cursor_on_item(last_location.focus_item)
      else
        highlight_current_file()
      end
    else
      highlight_current_file()
    end
  else
    local cursor_line = vim.api.nvim_win_get_cursor(treeviewer_win)[1]
    if cursor_line <= 1 or not current_items or cursor_line - 1 > #current_items then
      return
    end
    local selected_item = current_items[cursor_line - 1]
    if selected_item.is_directory and expanded_folders[selected_item.full_path] then
      expanded_folders[selected_item.full_path] = nil
      vim.bo[treeviewer_buf].modifiable = true
      populate_buffer(treeviewer_buf, current_path)
      vim.bo[treeviewer_buf].modifiable = false
      position_cursor_on_item(selected_item.name)
    end
  end
end

function M.toggle_mode()
  config.mode = config.mode == "dive" and "keep" or "dive"
  navigation_history = {}
  expanded_folders = {}
  if treeviewer_buf and vim.api.nvim_buf_is_valid(treeviewer_buf) then
    vim.bo[treeviewer_buf].modifiable = true
    populate_buffer(treeviewer_buf, current_path)
    vim.bo[treeviewer_buf].modifiable = false
    highlight_current_file()
  end
  print("TreeViewer mode: " .. config.mode)
end

local function setup_keymaps(buf)
  vim.keymap.set("n", "<CR>", handle_enter, { buffer = buf, silent = true })
  vim.keymap.set("n", "l", handle_l, { buffer = buf, silent = true })
  vim.keymap.set("n", "h", handle_h, { buffer = buf, silent = true })
  vim.keymap.set("n", "m", function()
    M.toggle_mode()
  end, { buffer = buf, silent = true })
  vim.keymap.set({ "n", "v" }, "y", handle_copy, { buffer = buf, silent = true })
  vim.keymap.set({ "n", "v" }, "x", handle_cut, { buffer = buf, silent = true })
  vim.keymap.set("n", "p", handle_paste, { buffer = buf, silent = true })
  vim.keymap.set({ "n", "v" }, "d", handle_delete, { buffer = buf, silent = true })
  vim.keymap.set("n", "a", handle_add, { buffer = buf, silent = true })
  vim.keymap.set("n", "r", function()
    handle_rename(false)
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "R", function()
    handle_rename(true)
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "q", function()
    M.toggle()
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", function()
    clipboard = nil
    clipboard_mode = nil
    clear_selection_highlighting()
    print("Selection cleared")
  end, { buffer = buf, silent = true })
end

local function create_treeviewer()
  original_win = vim.api.nvim_get_current_win()
  navigation_history = {}
  local cwd = vim.fn.getcwd()
  treeviewer_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[treeviewer_buf].modifiable = false
  vim.bo[treeviewer_buf].buftype = "nofile"
  vim.bo[treeviewer_buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(treeviewer_buf, config.buf_name)
  vim.cmd(config.split_command)
  treeviewer_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(treeviewer_win, treeviewer_buf)
  vim.bo[treeviewer_buf].modifiable = true
  populate_buffer(treeviewer_buf, cwd)
  expanded_folders[cwd] = true
  vim.bo[treeviewer_buf].modifiable = false
  vim.wo[treeviewer_win].cursorline = true
  vim.wo[treeviewer_win].number = false
  vim.wo[treeviewer_win].relativenumber = false
  vim.cmd("highlight default Bold gui=bold cterm=bold")
  setup_keymaps(treeviewer_buf)
  highlight_current_file()
end

function M.toggle()
  if treeviewer_win and vim.api.nvim_win_is_valid(treeviewer_win) then
    vim.api.nvim_win_close(treeviewer_win, true)
    treeviewer_win = nil
    treeviewer_buf = nil
    original_win = nil
    navigation_history = {}
    expanded_folders = {}
  else
    create_treeviewer()
  end
end

function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config or {})
  setup_highlights()
end

return M
