--Code from: https://github.com/linkarzu/dotfiles-latest/blob/main/neovim/neobean/lua/config/keymaps.lua
---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    mappings = {
      -- first key is the mode
      n = {
        ["<Leader>Tc"] = {
          function()
            require("snacks").picker.grep_word {
              regex = true,
              search = "^- \\[x\\] `done:", -- Matches lines starting with "- [x] `done:"
              focus = "list",
              live = false,
              title = "Completed Tasks",
            }
          end,
          desc = "Search completed tasks",
        },
        ["<Leader>Tt"] = {
          function()
            require("snacks").picker.grep_word {
              regex = true,
              search = "^- \\[ \\] ", -- Ensure "- [ ]" is at the beginning of the line
              focus = "list",
              live = false,
              title = "Incomplete Tasks",
            }
          end,
          desc = "Search incomplete tasks",
        },
        ["<Leader>Td"] = {
          function()
            -- Customizable variables
            -- NOTE: Customize the completion label
            local label_done = "done:"
            -- NOTE: Customize the timestamp format
            local timestamp = os.date "%y%m%d"
            -- local timestamp = os.date("%y%m%d")
            -- NOTE: Customize the heading and its level
            local tasks_heading = "## Completed tasks"
            -- Save the view to preserve folds
            vim.cmd "mkview"
            local api = vim.api
            -- Retrieve buffer & lines
            local buf = api.nvim_get_current_buf()
            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            local start_line = cursor_pos[1] - 1
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local total_lines = #lines
            -- If cursor is beyond last line, do nothing
            if start_line >= total_lines then return end
            ------------------------------------------------------------------------------
            -- (A) Move upwards to find the bullet line (if user is somewhere in the chunk)
            ------------------------------------------------------------------------------
            while start_line > 0 do
              local line_text = lines[start_line + 1]
              -- Stop if we find a blank line or a bullet line
              if line_text == "" or line_text:match "^%s*%-" then break end
              start_line = start_line - 1
            end
            -- Now we might be on a blank line or a bullet line
            if lines[start_line + 1] == "" and start_line < (total_lines - 1) then start_line = start_line + 1 end
            ------------------------------------------------------------------------------
            -- (B) Validate that it's actually a task bullet, i.e. '- [ ]' or '- [x]'
            ------------------------------------------------------------------------------
            local bullet_line = lines[start_line + 1]
            if not bullet_line:match "^%s*%- %[[x ]%]" then
              -- Not a task bullet => show a message and return
              print "Not a task bullet: no action taken."
              return
            end
            ------------------------------------------------------------------------------
            -- 1. Identify the chunk boundaries
            ------------------------------------------------------------------------------
            local chunk_start = start_line
            local chunk_end = start_line
            while chunk_end + 1 < total_lines do
              local next_line = lines[chunk_end + 2]
              if next_line == "" or next_line:match "^%s*%-" then break end
              chunk_end = chunk_end + 1
            end
            -- Collect the chunk lines
            local chunk = {}
            for i = chunk_start, chunk_end do
              table.insert(chunk, lines[i + 1])
            end
            ------------------------------------------------------------------------------
            -- 2. Check if chunk has [done: ...] or [untoggled], then transform them
            ------------------------------------------------------------------------------
            local has_done_index = nil
            local has_untoggled_index = nil
            for i, line in ipairs(chunk) do
              -- Replace `[done: ...]` -> `` `done: ...` ``
              chunk[i] = line:gsub("%[done:([^%]]+)%]", "`" .. label_done .. "%1`")
              -- Replace `[untoggled]` -> `` `untoggled` ``
              chunk[i] = chunk[i]:gsub("%[untoggled%]", "`untoggled`")
              if chunk[i]:match("`" .. label_done .. ".-`") then
                has_done_index = i
                break
              end
            end
            if not has_done_index then
              for i, line in ipairs(chunk) do
                if line:match "`untoggled`" then
                  has_untoggled_index = i
                  break
                end
              end
            end
            ------------------------------------------------------------------------------
            -- 3. Helpers to toggle bullet
            ------------------------------------------------------------------------------
            -- Convert '- [ ]' to '- [x]'
            local function bulletToX(line) return line:gsub("^(%s*%- )%[%s*%]", "%1[x]") end
            -- Convert '- [x]' to '- [ ]'
            local function bulletToBlank(line) return line:gsub("^(%s*%- )%[x%]", "%1[ ]") end
            ------------------------------------------------------------------------------
            -- 4. Insert or remove label *after* the bracket
            ------------------------------------------------------------------------------
            local function insertLabelAfterBracket(line, label)
              local prefix = line:match "^(%s*%- %[[x ]%])"
              if not prefix then return line end
              local rest = line:sub(#prefix + 1)
              return prefix .. " " .. label .. rest
            end
            local function removeLabel(line)
              -- If there's a label (like `` `done: ...` `` or `` `untoggled` ``) right after
              -- '- [x]' or '- [ ]', remove it
              return line:gsub("^(%s*%- %[[x ]%])%s+`.-`", "%1")
            end
            ------------------------------------------------------------------------------
            -- 5. Update the buffer with new chunk lines (in place)
            ------------------------------------------------------------------------------
            local function updateBufferWithChunk(new_chunk)
              for idx = chunk_start, chunk_end do
                lines[idx + 1] = new_chunk[idx - chunk_start + 1]
              end
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            end
            ------------------------------------------------------------------------------
            -- 6. Main toggle logic
            ------------------------------------------------------------------------------
            if has_done_index then
              chunk[has_done_index] = removeLabel(chunk[has_done_index]):gsub("`" .. label_done .. ".-`", "`untoggled`")
              chunk[1] = bulletToBlank(chunk[1])
              chunk[1] = removeLabel(chunk[1])
              chunk[1] = insertLabelAfterBracket(chunk[1], "`untoggled`")
              updateBufferWithChunk(chunk)
            elseif has_untoggled_index then
              chunk[has_untoggled_index] = removeLabel(chunk[has_untoggled_index]):gsub(
                "`untoggled`",
                "`" .. label_done .. " " .. timestamp .. "`"
              )
              chunk[1] = bulletToX(chunk[1])
              chunk[1] = removeLabel(chunk[1])
              chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")
              updateBufferWithChunk(chunk)
            else
              chunk[1] = bulletToX(chunk[1])
              chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")
              -- Remove chunk from the original lines
              for i = chunk_end, chunk_start, -1 do
                table.remove(lines, i + 1)
              end
              -- Replace with new content
              for i, cLine in ipairs(chunk) do
                table.insert(lines, chunk_start + i, cLine)
              end
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            end
            -- Restore the view to preserve folds
            vim.cmd "loadview"
          end,
          desc = "Toggle Task",
        },
        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        ["<Leader>T"] = { desc = " Tasks" },
      },
    },
  },
}
