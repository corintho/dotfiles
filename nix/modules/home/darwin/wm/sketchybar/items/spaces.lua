local colors = require("colors")

-- Add event listener for aerospace workspace changes
sbar.add("event", "aerospace_workspace_change")

-- Store created spaces for later reference
local spaces = {}
local spaces_initialized = false
local pending_monitors = 0
local monitors_completed = 0

-- Forward declaration for finalize_spaces_initialization
local finalize_spaces_initialization

-- Initialize spaces asynchronously
local function initialize_spaces()
  if spaces_initialized then
    return
  end

  -- Fetch monitors asynchronously
  sbar.exec("aerospace list-monitors", function(result)
    local monitors = {}
    -- Parse monitors from output like "1 | DELL U2412M (1)\n2 | Built-in Retina Display"
    -- Extract only the leading digit from each line
    for line in result:gmatch("[^\n]+") do
      local monitor_id = line:match("^%s*(%d+)")
      if monitor_id then
        table.insert(monitors, monitor_id)
      end
    end

    pending_monitors = #monitors

    -- For each monitor, fetch workspaces
    for _, monitor in ipairs(monitors) do
      sbar.exec("aerospace list-workspaces --monitor " .. monitor, function(ws_result)
        local workspaces = {}
        for workspace in ws_result:gmatch("%S+") do
          table.insert(workspaces, workspace)
        end

        -- Create space items for this monitor
        for _, sid in ipairs(workspaces) do
          if not spaces[sid] then
            local space = sbar.add("item", sid, {
              display = monitor,
              icon = {
                string = sid,
                padding_left = 10,
                padding_right = 15,
                highlight_color = colors.red,
                font = {
                  family = "JetBrainsMono Nerd Font",
                  size = 16,
                },
              },
              padding_left = 2,
              padding_right = 2,
              label = {
                padding_right = 20,
                font = {
                  family = "JetBrainsMono Nerd Font",
                  size = 16,
                  style = "Regular",
                },
                background = {
                  height = 26,
                  drawing = true,
                  color = colors.bg2,
                  corner_radius = 8,
                },
                drawing = false,
              },
            })

            spaces[sid] = space.name

            -- Handle space click
            space:subscribe("mouse.clicked", function(res)
              sbar.exec("aerospace workspace " .. res.NAME)
            end)

            -- Handle workspace changes
            space:subscribe({ "aerospace_workspace_change" }, function(res)
              local focused = res.FOCUSED_WORKSPACE or ""
              local name = res.NAME or ""

              if focused == name then
                sbar.animate("tanh", 30, function()
                  space:set({
                    icon = {
                      highlight = true,
                    },
                    label = {
                      width = "dynamic",
                    },
                  })
                end)
              else
                sbar.animate("tanh", 30, function()
                  space:set({
                    icon = {
                      highlight = false,
                    },
                    label = {
                      width = 0,
                    },
                  })
                end)
              end
            end)
          end
        end

        -- Increment completed counter and check if all monitors are done
        monitors_completed = monitors_completed + 1
        if monitors_completed >= pending_monitors then
          finalize_spaces_initialization()
        end
      end)
    end
  end)
end

-- Finalize spaces initialization and create bracket after all spaces are created
finalize_spaces_initialization = function()
  spaces_initialized = true

  -- Collect all created space item names for the bracket
  local space_items = {}
  for sid, space_name in pairs(spaces) do
    table.insert(space_items, space_name)
  end

  -- Create the bracket with all spaces
  local spaces_bracket = sbar.add("bracket", "spaces_bracket", space_items, {
    background = {
      color = colors.bg1,
      border_color = colors.bg2,
      border_width = 2,
    },
  })

  -- Handle forced refresh
  spaces_bracket:subscribe({ "forced" }, function()
    -- Get current focused workspace and trigger update
    sbar.exec("aerospace list-workspaces --focused", function(result)
      local focused = result:match("^%s*(.-)%s*$")

      sbar.trigger("aerospace_workspace_change", {
        FOCUSED_WORKSPACE = focused,
      })
    end)
  end)
end


-- Initialize spaces on first run
initialize_spaces()

return {}
