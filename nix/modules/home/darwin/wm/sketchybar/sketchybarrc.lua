#!/usr/bin/env lua5.4

-- Require the sketchybar module (installed via Nix from pkgs.sbarlua)
-- Nix automatically adds the module to Lua's search path
sbar = require("sketchybar")

-- Bundle the entire initial configuration into a single message to sketchybar
-- This improves startup times drastically
sbar.begin_config()
require("helpers")
require("init")
sbar.hotload(true)
sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
