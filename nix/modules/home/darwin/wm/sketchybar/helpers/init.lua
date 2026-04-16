-- Compile helper binaries (menus, event providers, etc.)
-- Use absolute path to ensure reliability
os.execute("(cd " .. os.getenv("HOME") .. "/.config/sketchybar/helpers && make)")
