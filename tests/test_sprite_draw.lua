package.path = "./?.lua;" .. package.path
local Sprites = require("src/sprites")
Sprites.init({Resolve = function(source) if source == "ICON" then return 321 end end})
local draws = {}
local canvas = {width = 800, height = 600, AddSprite = function(_, ...) draws[#draws + 1] = {...} end}
assert(Sprites.draw(canvas, {source = "ICON", size = 32, alpha = 0.5}, {x = 150, y = 100}, {x = 10, y = 20}))
assert(draws[1][1] == 124 and draws[1][2] == 64 and draws[1][3] == 32 and draws[1][5] == 321 and draws[1][6] == 0xFFFFFF80)
assert(not Sprites.draw(canvas, {source = "MISSING"}, {x = 150, y = 100}, {x = 0, y = 0}))
assert(not Sprites.draw(canvas, {source = "ICON", alpha = 0}, {x = 150, y = 100}, {x = 0, y = 0}))
assert(not Sprites.draw(canvas, {source = "ICON"}, {x = -200, y = 100}, {x = 0, y = 0}))

PersistentDB = {GetString = function() end, GetStructuredData = function() end, GetBool = function() end, GetInt = function() end}
GameKey = {CONTROL = 1, SHIFT = 2}
local function event() return {Subscribe = function() end, Unsubscribe = function() end} end
Event = {SettingsLayerReady = event(), ContentLayerReady = event(), Draw = event()}
ui = {TextDataConfig = {new = function() return {} end}, AlignMode = {CENTRE = 1}}
id = {Font = {MUSEO_SANS_19PT_REGULAR = 1}}
ScreenConvert = {CoordFineToScreen = function() return {x = 150, y = 100} end}
local UI = require("src/ui")
local renderer = {Sync = function() return true end}
UI:init({}, {}, renderer)
local cleared, textCalls = 0, 0
canvas.xyGlobal = {x = 10, y = 20}
canvas.Clear = function() cleared = cleared + 1 end
canvas.AddText = function() textCalls = textCalls + 1 end
UI.canvas = canvas
local coord = {level = 0, x = 1, z = 1, ToCoordFine = function() return {position = {x = 768, y = 0, z = 768}} end}
UI:syncMarkers({[coord] = {sprite = {source = "ICON", size = 48}}}, nil, 30 * 512)
UI:drawLabels({x = 768, z = 768}, 0)
assert(#draws == 2 and textCalls == 0, "sprite-only tiles draw without nil text")
UI:drawLabels({x = 768, z = 768}, 1)
assert(cleared == 1 and #draws == 2, "wrong-floor icons are cleared")
UI:drawLabels({x = 200000, z = 200000}, 0)
assert(#draws == 2, "far icons are culled")
UI:syncMarkers({[coord] = {text = "Label", sprite = {source = "ICON"}}}, nil, 30 * 512)
UI:drawLabels({x = 768, z = 768}, 0)
assert(#draws == 3 and textCalls == 1, "labels coexist with icons")
UI:syncMarkers({}, nil, 30 * 512)
UI:drawLabels({x = 768, z = 768}, 0)
assert(cleared == 2 and #draws == 3, "removed icons leave no stale canvas art")
print("test_sprite_draw: ok")
