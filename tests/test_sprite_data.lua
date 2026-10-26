package.path = "./?.lua;" .. package.path
local Sprites = require("src/sprites")
local resolves = 0
Sprites.init({Resolve = function(source)
    resolves = resolves + 1
    if source == "SKILL_ATTACK" or source == 100 then return 100 end
end})
assert(Sprites.source(" skill_attack ") == "SKILL_ATTACK")
assert(Sprites.source("100") == 100)
assert(Sprites.source("os.execute('x')") == nil)
assert(Sprites.source(0/0) == nil)
assert(Sprites.copy({source = "SKILL_ATTACK", size = 999, alpha = -1}).size == 128)
assert(Sprites.parse("SKILL_ATTACK", "32", "75").alpha == 0.75)
assert(Sprites.parse("SKILL_ATTACK", "0", "75") == nil)
assert(Sprites.parse("SKILL_ATTACK", "32", "101") == nil)
assert(Sprites.parse("MISSING", "32", "75") == nil)
assert(Sprites.parse("", "bad", "bad") == false)
Sprites.resolve("SKILL_ATTACK");Sprites.resolve("SKILL_ATTACK")
assert(resolves == 2, "successful and missing lookups are cached")

local records, saving = {}, true
PersistentDB = {GetStructuredData = function(_, key) return records[key] end,
    SetStructuredData = function(_, key, value) if saving then records[key] = value end;return saving end}
CoordGrid = {new = function(level, mx, mz, lx, lz)
    local x, z
    if mx == nil then
        local packed = level;level = (packed >> 28) & 3;x = (packed >> 14) & 0x3FFF;z = packed & 0x3FFF
    else x, z = mx * 64 + lx, mz * 64 + lz end
    return {level = level, x = x, z = z, mapSquareX = x // 64, mapSquareZ = z // 64,
        ToPacked = function() return (level << 28) | (x << 14) | z end}
end}
local coord = CoordGrid.new(0, 50, 50, 2, 3)
local Tiles = require("src/tiles")
Tiles:add(coord, {text = "Label", sprite = {source = "SKILL_ATTACK", size = 48, alpha = 0.75}})
assert(Tiles:getSprite(coord).size == 48)
Tiles:previewSprite(coord, {source = 100, size = 64})
assert(Tiles:getSprite(coord).size == 64)
Tiles:cancelCustomizationPreview(coord)
assert(Tiles:getSprite(coord).size == 48)
saving = false
assert(not Tiles:setSprite(coord, false))
assert(Tiles:getSprite(coord).size == 48, "failed saves restore original metadata")
saving = true
assert(Tiles:setCustomization(coord, "Changed", 0x123456FF, true, false))
assert(Tiles:getSprite(coord).size == 48, "ordinary customization preserves icon")
package.loaded["src/tiles"] = nil
Tiles = require("src/tiles")
assert(Tiles:getSprite(coord).source == "SKILL_ATTACK", "saved icons survive reload")

local Codec = require("src/preset_codec")
local exported = Tiles:exportCoords({coord})
local token = assert(Codec.encode("Icons", exported))
assert(token:sub(1, 3) == "TM3")
local decoded = assert(Codec.decode(token))
assert(decoded.tiles[1].sprite.source == "SKILL_ATTACK")
assert(Sprites.same(exported[1].sprite, decoded.tiles[1].sprite), "alpha comparison matches encoded render precision")
assert(Codec.decode(token:sub(1, -5)) == nil, "truncation is rejected")
local plain = assert(Codec.encode("Plain", {{x = 1, z = 2, level = 0}}))
assert(plain:sub(1, 3) == "TM2", "sprite-free exports remain upstream-compatible")
assert(Codec.decode("TM3" .. plain:sub(4)) == nil, "TM3 needs a sprite section")
assert(Codec.encode("Bad", {{x = 1, z = 2, sprite = {source = -1}}}) == nil)
local numeric = assert(Codec.decode(assert(Codec.encode("ID", {{x = 1, z = 1, sprite = {source = 100, size = 8, alpha = 0}}}))))
assert(numeric.tiles[1].sprite.source == 100 and numeric.tiles[1].sprite.alpha == 0)

local Presets = require("src/presets")
local ok, preset = Presets:create("Icons", exported, true);assert(ok)
local success, presetToken = Presets:export(preset.id);assert(success and presetToken:sub(1, 3) == "TM3")
local target = CoordGrid.new(0, 1, 1, 2, 3)
assert(Presets:query(coord, 2, {{source = coord, target = target}})[target].sprite.size == 48)
local direct = Presets:query(coord, 2)
for _, metadata in pairs(direct) do assert(metadata.sprite.size == 48) end
package.loaded["src/presets"] = nil
Presets = require("src/presets")
assert(Presets:get(preset.id).tiles[1].sprite.size == 48, "preset tokens retain icons after reload")
assert(Presets:import(presetToken))

local Editor = require("src/preset_editor")
assert(Editor:begin(Presets:get(preset.id), Tiles))
assert(Editor:getSprite(coord).size == 48)
Editor:previewSprite(coord, false);assert(Editor:getSprite(coord) == nil)
Editor:cancelCustomizationPreview(coord);assert(Editor:getSprite(coord).size == 48)
Editor:setSprite(coord, {source = 100, size = 64, alpha = 1})
assert(Editor:export()[1].sprite.source == 100)
assert(Editor:query(coord, 2, {{source = coord, target = target}})[target].sprite.size == 64)
Editor:cancel()
assert(Tiles:setSprite(coord, false) and Tiles:getSprite(coord) == nil)
print("test_sprite_data: ok")
