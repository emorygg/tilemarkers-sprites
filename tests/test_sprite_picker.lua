package.path = "./?.lua;" .. package.path
local Sprites = require("src/sprites")
local buttons, fields, searchOffsets, pending, saved, previewed, cancelled, texts = {}, {}, {}, nil, nil, nil, 0, {}
Sprites.init({Resolve = function(source) if source == "ICON" or source == 100 then return 100 end end,
    BuildIndex = function(callback) pending = callback end,
    Find = function(query, options) searchOffsets[#searchOffsets + 1] = options.offset;return {{name = "ICON", id = 100}}, 7 end,
    Draw = function() return {} end, SetSource = function() end})
local store = {getSprite = function() return {source = "ICON", size = 32, alpha = 1} end,
    previewSprite = function(_, _, icon) previewed = icon end,
    cancelCustomizationPreview = function() cancelled = cancelled + 1 end,
    setSprite = function(_, _, icon) saved = icon;return true end}
local owner = {gameArea = {width = 1000, height = 800}, prettyui = {Window = {new = function(_, options)
    local window = {root = {}, content = {}}
    function window:AddText(props) texts[#texts + 1] = props;return setmetatable({}, {__newindex = function(_, _, value) window.status = value end}) end
    function window:AddTextField(props)
        local input = {value = props.text or "", options = props}
        function input:GetText() return self.value end
        function input:SetText(value) self.value = value end
        fields[#fields + 1] = input;return input
    end
    function window:AddFancyButton(text, callback)
        local button = {text = text, action = callback}
        function button:SetText(value) self.text = value end
        function button:SetDisabled(value) self.disabled = value end
        function button:SetTooltip(value) self.tooltip = value end
        buttons[#buttons + 1] = button;return button
    end
    function window:Close() options.onClose();self.root = nil end
    function window:Destroy() self.root = nil end
    return window
end}}}
local function click(name)
    for i = #buttons, 1, -1 do local button = buttons[i];if button.text == name then button.action();return end end
    error("Missing button " .. name)
end
local Picker = require("src/sprite_picker")
local coord = {}
owner.spritePicker = Picker.open(owner, store, coord)
assert(previewed.source == "ICON")
assert(#searchOffsets == 0, "no synchronous full-index search")
pending();assert(searchOffsets[1] == 0)
click("Next");assert(searchOffsets[2] == 6)
click("ICON");assert(previewed.source == "ICON")
owner.spritePicker.sizeInput.value = "0";click("Save sprite");assert(saved == nil and owner.spritePicker ~= nil)
owner.spritePicker.sizeInput.value = "64";click("Save sprite")
assert(saved.size == 64 and owner.spritePicker == nil and cancelled == 1)
owner.spritePicker = Picker.open(owner, store, coord)
local previousSaved = saved
owner.spritePicker:destroy();pending()
assert(owner.spritePicker == nil and cancelled == 2 and saved == previousSaved, "cancel/late index callback do not commit")
owner.spritePicker = Picker.open(owner, store, coord)
click("Remove sprite");assert(previewed == false)
click("Save sprite");assert(saved == false and owner.spritePicker == nil)
print("test_sprite_picker: ok")
