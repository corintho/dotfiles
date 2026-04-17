local colors = require("colors")

-- Add event listener for aerospace workspace changes
sbar.add("event", "aerospace_workspace_change")

local space_items = {}

-- Map workspace names to NerdFont icons
local function workspace_icon(workspace)
  local icons = {
    ["1"] = "",        -- house
    ["Browsers"] = "", -- firefox
    ["Dev"] = "",      -- code
    ["Misc"] = "",     -- apps
    ["Retail"] = "",   -- shopping cart
    ["cOmms"] = "",    -- comments
  }
  return icons[workspace] or workspace -- Fallback to workspace name if no icon defined
end

-- Asynchronous query to aerospace for workspace list
sbar.exec("aerospace list-workspaces --all", function(result)
  -- Parse workspace names
  local workspaces = {}
  for workspace in result:gmatch("%S+") do
    table.insert(workspaces, workspace)
  end

  -- Fallback: if no workspaces found, exit gracefully (no workspace section shown)
  if #workspaces == 0 then
    return
  end

  -- Create items for each workspace
  for _, workspace in ipairs(workspaces) do
    local item = sbar.add("item", "space_" .. workspace, {
      position = "center",
      icon = { drawing = false },  -- No icon, label only
      label = {
        string = workspace_icon(workspace),
        font = {
          family = "JetBrainsMono Nerd Font",
          size = 14,
          style = "Regular",
        },
        color = colors.white,
        padding_left = 3,
        padding_right = 3,
      },
      padding_left = 0,
      padding_right = 0,
      background = { drawing = false },
    })

    -- Handle click to switch workspace
    item:subscribe("mouse.clicked", function()
      sbar.exec("aerospace workspace " .. workspace)
    end)

    -- Handle workspace change highlight
    item:subscribe("aerospace_workspace_change", function(env)
      local focused = env.FOCUSED_WORKSPACE or ""

      if focused == workspace then
        -- Focused: bold + red
        item:set({
          label = {
            string = workspace_icon(workspace),
            font = { style = "Bold" },
            color = colors.red,
          }
        })
      else
        -- Not focused: regular + white
        item:set({
          label = {
            string = workspace_icon(workspace),
            font = { style = "Regular" },
            color = colors.white,
          }
        })
      end
    end)

    table.insert(space_items, item.name)
  end

  -- Create bracket grouping all spaces
  local spaces_bracket = sbar.add("bracket", "spaces_bracket", space_items, {
    position = "center",
    background = {
      color = colors.bg1,
      border_color = colors.bg2,
      border_width = 2,
    },
  })

  -- Handle forced refresh
  spaces_bracket:subscribe({ "forced" }, function()
    sbar.exec("aerospace list-workspaces --focused", function(result)
      local focused = result:match("^%s*(.-)%s*$")
      sbar.trigger("aerospace_workspace_change", {
        FOCUSED_WORKSPACE = focused,
      })
    end)
  end)

  -- Initial focused workspace detection
  sbar.exec("aerospace list-workspaces --focused", function(result)
    local focused = result:match("^%s*(.-)%s*$")
    sbar.trigger("aerospace_workspace_change", {
      FOCUSED_WORKSPACE = focused,
    })
  end)
end)

return {}
