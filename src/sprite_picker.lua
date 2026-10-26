local Sprites = require("src/sprites")
local Picker = {}
function Picker.open(owner, store, coord)
    local library = Sprites.library
    if not library then log("RSprite is unavailable. Enable the rsprite dependency first.");return nil end
    local initial = store:getSprite(coord) or {size = 32, alpha = 1}
    local closed, ready, offset, results, total = false, false, 0, {}, 0
    local controller, buttons = {}, {}
    local width = math.min(620, owner.gameArea.width)
    local height = math.min(650, owner.gameArea.height)
    local window, sourceInput, sizeInput, opacityInput, searchInput, status, preview
    local function setStatus(text) if not closed and status then status.content = text end end
    local function cancelPreview() store:cancelCustomizationPreview(coord) end
    local function finish()
        if closed then return end
        closed = true;cancelPreview()
        if owner.spritePicker == controller then owner.spritePicker = nil end
    end
    window = owner.prettyui.Window.new(owner.gameArea, {
        title = "Tile sprite", width = width, height = height,
        x = math.max(0, math.floor((owner.gameArea.width - width) / 2)),
        y = math.max(0, math.floor((owner.gameArea.height - height) / 2)),
        minWidth = width, minHeight = height, maxWidth = width, maxHeight = height,
        scrollable = true, destroyOnClose = true, onClose = finish,
        layout = {startY = 10, paddingLeft = 12, paddingRight = 12, rowGap = 8},
    })
    controller.window = window
    local function values() return Sprites.parse(sourceInput:GetText(), sizeInput:GetText(), opacityInput:GetText()) end
    local function updatePreview()
        if closed then return end
        local icon, errorText = values()
        if errorText then setStatus(errorText);return end
        if preview then
            library.SetSource(preview, icon and icon.source or {}, {alpha = icon and icon.alpha or 1, placeholder = false})
        end
        store:previewSprite(coord, icon)
        setStatus(icon and "Previewing the selected sprite on the tile. Save to keep it." or "No sprite selected. Save removes the tile's sprite.")
    end
    window:AddText({text = "Sprite name or ID. Leave blank to remove. Icons face the camera at the tile centre.", height = 46, width = width - 24})
    sourceInput = window:AddTextField({text = initial.source and tostring(initial.source) or "", maxLength = 128,
        width = math.max(100, width - 100), placeholder = "e.g. SKILL_ATTACK", onChange = function() if opacityInput then updatePreview() end end})
    window:AddText({text = "Size (8-128 interface units) and opacity (0-100%)", height = 28})
    sizeInput = window:AddTextField({text = tostring(initial.size), maxLength = 3, width = 100,
        onChange = function() if opacityInput then updatePreview() end end})
    opacityInput = window:AddTextField({text = tostring(math.floor(initial.alpha * 100 + 0.5)), maxLength = 5, width = 100, inline = true,
        onChange = updatePreview})
    status = window:AddText({text = "Building the RSprite search index...", height = 44, width = width - 24})
    if window.content then
        -- RSprite creates a click-through sprite; its parent window owns native cleanup.
        preview = library.Draw(window.content, {}, {x = width - 68, y = 58, size = 44, placeholder = false})
    end
    local function search(reset)
        if closed then return end
        if not ready then setStatus("Sprite index is still building. Try Search shortly.");return end
        if reset then offset = 0 end
        local ok, matches, count = pcall(library.Find, searchInput:GetText(), {limit = 6, offset = offset})
        if not ok then setStatus("Sprite search is unavailable. Enter an exact name or ID instead.");return end
        results, total = matches or {}, count or 0
        for index, button in ipairs(buttons) do
            local entry = results[index]
            button:SetText(entry and entry.name:sub(1, 48) or "-")
            button:SetDisabled(entry == nil)
            button:SetTooltip(entry and (entry.name .. " (#" .. entry.id .. ")") or "No result")
        end
        setStatus(total .. " results; showing " .. (#results > 0 and offset + 1 or 0) .. "-" .. offset + #results .. ". Click a result to preview.")
    end
    searchInput = window:AddTextField({text = "", maxLength = 128, placeholder = "Search sprites: arrow, skull, skill attack...",
        onSubmit = function() search(true) end})
    window:AddFancyButton("Search", function() search(true) end, {width = 120})
    window:AddFancyButton("Previous", function() if offset >= 6 then offset = offset - 6;search(false) end end, {inline = true, width = 120})
    window:AddFancyButton("Next", function() if offset + 6 < total then offset = offset + 6;search(false) end end, {inline = true, width = 120})
    for index = 1, 6 do
        buttons[index] = window:AddFancyButton("-", function()
            if closed then return end
            local entry = results[index]
            if entry then sourceInput:SetText(entry.name, false);updatePreview() end
        end, {width = width - 24, disabled = true, tooltip = "No result"})
    end
    window:AddFancyButton("Save sprite", function()
        if closed then return end
        local icon, errorText = values()
        if errorText then setStatus(errorText);return end
        local ok, message = store:setSprite(coord, icon)
        if not ok then setStatus(message or "Could not save sprite.");return end
        window:Close()
    end, {width = 164, variant = "positive"})
    window:AddFancyButton("Remove sprite", function() if closed then return end;sourceInput:SetText("", false);updatePreview() end, {inline = true, width = 164})
    window:AddFancyButton("Cancel", function() if not closed then window:Close() end end, {inline = true, width = 164, variant = "negative"})
    function controller:destroy()
        if closed then return end
        finish();window:Destroy()
    end
    controller.sourceInput, controller.sizeInput, controller.opacityInput = sourceInput, sizeInput, opacityInput
    local ok = pcall(library.BuildIndex, function()
        if closed then return end
        ready = true;search(true)
    end)
    if not ok then setStatus("Search index unavailable; exact names and IDs still work.") end
    updatePreview()
    return controller
end
return Picker
