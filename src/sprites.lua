-- Sprite metadata is plain data. RSprite remains an external, unmodified library.
local Sprites = { library = nil }
local cache = {}
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
function Sprites.source(value)
    if type(value) == "string" then
        value = value:match("^%s*(.-)%s*$"):upper()
        if value:match("^%d+$") then value = tonumber(value)
        elseif #value > 0 and #value <= 128 and value:match("^[A-Z0-9_]+$") then return value
        else return nil end
    end
    if finite(value) and value % 1 == 0 and value >= 0 and value <= 2147483647 then return value end
end
function Sprites.copy(icon)
    if type(icon) ~= "table" then return nil end
    local source = Sprites.source(icon.source)
    if source == nil then return nil end
    local size, alpha = tonumber(icon.size), tonumber(icon.alpha)
    return {source = source,
        size = finite(size) and math.max(8, math.min(128, math.floor(size))) or 32,
        alpha = finite(alpha) and math.max(0, math.min(1, alpha)) or 1}
end
function Sprites.same(a, b)
    a, b = Sprites.copy(a), Sprites.copy(b)
    if a == nil or b == nil then return a == b end
    return a.source == b.source and a.size == b.size
        and math.floor(a.alpha * 255 + 0.5) == math.floor(b.alpha * 255 + 0.5)
end
function Sprites.init(library) Sprites.library = library;cache = {} end
function Sprites.resolve(source)
    source = Sprites.source(source)
    if source == nil or not Sprites.library then return nil end
    if cache[source] == nil then
        local ok, value = pcall(Sprites.library.Resolve, source)
        cache[source] = ok and type(value) == "number" and value or false
    end
    return cache[source] ~= false and cache[source] or nil
end
function Sprites.parse(source, size, opacity)
    source = tostring(source or ""):match("^%s*(.-)%s*$")
    if source == "" then return false end -- Explicit removal; nil means absent metadata.
    local value = Sprites.source(source)
    if value == nil then return nil, "Enter a sprite name or whole-number ID (no Lua expressions)." end
    size, opacity = tonumber(size), tonumber(opacity)
    if not finite(size) or size % 1 ~= 0 or size < 8 or size > 128 then return nil, "Size must be a whole number from 8 to 128." end
    if not finite(opacity) or opacity < 0 or opacity > 100 then return nil, "Opacity must be between 0 and 100 percent." end
    if Sprites.resolve(value) == nil then return nil, "Sprite unavailable or blocked by RSprite. Choose another result." end
    return {source = value, size = size, alpha = opacity / 100}
end
function Sprites.draw(canvas, icon, centre, origin)
    icon = Sprites.copy(icon)
    if not icon or icon.alpha == 0 then return false end
    local source = Sprites.resolve(icon.source)
    if source == nil then return false end
    local x, y = centre.x - origin.x - icon.size / 2, centre.y - origin.y - icon.size / 2
    if x + icon.size < 0 or y + icon.size < 0 or x > canvas.width or y > canvas.height then return false end
    canvas:AddSprite(math.floor(x + 0.5), math.floor(y + 0.5), icon.size, icon.size, source,
        0xFFFFFF00 | math.floor(icon.alpha * 255 + 0.5))
    return true
end
return Sprites
