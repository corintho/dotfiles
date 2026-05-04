local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local pomodoro = sbar.add("item", "widgets.pomodoro", {
  position = "right",
  icon = {
    string = icons.pomodoro.idle,
    color = colors.white,
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    }
  },
  label = {
    string = "Ready",
    color = colors.white,
    font = { 
      family = settings.font.numbers,
      size = 13.0,
    }
  },
  update_freq = 5,
})

local function render(icon_str, label_str, color)
  pomodoro:set({
    icon = { string = icon_str, color = color },
    label = { string = label_str, color = color }
  })
end

pomodoro:subscribe({"routine", "forced", "system_woke"}, function()
  sbar.exec("$CONFIG_DIR/scripts/tomito_status.sh", function(result)
    local output = (result or ""):gsub("%s+$", "")
    local type_str, time_str = output:match("([^|]+)|([^|]*)")
    
    if not type_str then
      return render(icons.pomodoro.timer, "Error", colors.red)
    end
    
    if type_str == "idle" then
      return render(icons.pomodoro.idle, "Ready", colors.white)
    end
    
    if type_str == "error" then
      return render(icons.pomodoro.timer, "Error", colors.red)
    end
    
    if type_str == "paused_session" or type_str == "paused_break" then
      return render(icons.pomodoro.pause, time_str, colors.yellow)
    end
    
    if type_str == "break" then
      return render(icons.pomodoro.break_icon, time_str, colors.green)
    end
    
    local mins, secs = time_str:match("(%d+):(%d+)")
    local total_secs = (tonumber(mins) or 0) * 60 + (tonumber(secs) or 0)
    local color = total_secs < 300 and colors.red or colors.white
    render(icons.pomodoro.timer, time_str, color)
  end)
end)

sbar.add("bracket", "widgets.pomodoro.bracket", { pomodoro.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.pomodoro.padding", {
  position = "right",
  width = settings.group_paddings
})
