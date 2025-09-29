-- Add this to your init.lua or create a separate file and require it

-- Function to toggle markdown checkboxes when pressing Enter
local function toggle_markdown_checkbox()
  local line = vim.fn.getline('.')
  local cursor_pos = vim.fn.getcurpos()
  
  -- Check if we're on a line with a markdown checkbox
  local checkbox_pattern = "%s*[-*+]%s*%[([%s%a])%]"
  local match_start, match_end, checkbox_state = string.find(line, checkbox_pattern)
  
  if match_start then
    -- Toggle the checkbox state
    local new_state = checkbox_state == " " and "x" or " "
    local new_line = string.gsub(line, checkbox_pattern, "%1 [" .. new_state .. "]", 1)
    
    -- Update the line
    vim.fn.setline('.', new_line)
    
    -- Create a new checkbox item below if needed
    local indent = string.match(line, "^%s+") or ""
    local bullet = string.match(line, "[-*+]")
    local new_checkbox_line = indent .. bullet .. " [ ] "
    
    -- Insert the new line and move cursor to it
    vim.fn.append('.', new_checkbox_line)
    vim.fn.cursor(cursor_pos[2] + 1, #new_checkbox_line + 1)
    
    return true
  end
  
  -- If not a checkbox line, return false to use the default Enter behavior
  return false
end

-- Create the module
local M = {}

-- Function to check if the cursor is on a checkbox line
function M.is_markdown_checkbox_line()
  if vim.bo.filetype ~= "markdown" then
    return false
  end
  
  local line = vim.fn.getline('.')
  local checkbox_pattern = "%s*[-*+]%s*%[([%s%a])%]"
  return string.find(line, checkbox_pattern) ~= nil
end

-- Function to setup the integration with nvim-cmp
function M.setup()
  local cmp = require('cmp')
  
  -- Store the original mapping for <CR>
  local original_cr_mapping = cmp.mapping.get_mapping('<CR>')
  
  -- Create a new mapping for <CR> that checks for checkboxes
  cmp.mapping.set('<CR>', function(fallback)
    if M.is_markdown_checkbox_line() then
      -- If completion menu is visible, confirm selection first
      if cmp.visible() then
        cmp.confirm({ select = true })
      end
      
      -- Then toggle the checkbox
      toggle_markdown_checkbox()
    else
      -- Otherwise use the original <CR> mapping or fallback
      if original_cr_mapping then
        original_cr_mapping(fallback)
      else
        fallback()
      end
    end
  end)
end

-- Add a stand-alone toggle function for use outside of cmp
function M.toggle()
  if vim.bo.filetype == "markdown" then
    return toggle_markdown_checkbox()
  end
  return false
end

-- Setup key mappings for when nvim-cmp is not handling the input
function M.setup_keymaps()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      -- Map Enter key in normal mode
      vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', 
        ':lua require("markdown_checkbox").toggle()<CR>', 
        { noremap = true, silent = true })
    end
  })
end

return M
