local NC_CONFIG_FILE = "nc/nc_config.txt"

local NC_CONFIG = {
    MENU_X = 34,
    MENU_Y = 54,

    RADAR_ENABLED = 1,
    RADAR_X = 300,
    RADAR_Y = 300,
    RADAR_SIZE = 200,
    RADAR_ENEMY_ONLY = 1,
    RADAR_ICON_STYLE = 2,
    RADAR_SHAPE = 1,
    RADAR_ICON_SIZE = 12,
    RADAR_ZOOM = 0.1,
    RADAR_SCALE = 200,
    RADAR_HEALTHBAR = 1,
    RADAR_HEALTHKITS = 1,
    RADAR_AMMOBOXES = 1,
    RADAR_DROPPEDWEAPONS = 1,
    RADAR_BACKGROUND_ALPHA = 51,
    RADAR_CENTER_PADDING = 2,
    RADAR_CENTER_BG_ALPHA = 230,

    INFO_ENABLED = 1,
    INFO_X = 100,
    INFO_Y = 200,
    INFO_SCALE = 1.0,
    INFO_WIDTH = 200,

    CRIT_ICON_ENABLED = 1,
    CRIT_X = 100,
    CRIT_Y = 300,
    CRIT_SCALE = 1.0,
}

local NC_CONFIG_ORDER = {
    "MENU_X", "MENU_Y",

    "RADAR_ENABLED",
    "RADAR_X", "RADAR_Y", "RADAR_SIZE",
    "RADAR_ENEMY_ONLY",
    "RADAR_ICON_STYLE",
    "RADAR_SHAPE",
    "RADAR_ICON_SIZE",
    "RADAR_ZOOM",
    "RADAR_SCALE",
    "RADAR_HEALTHBAR",
    "RADAR_HEALTHKITS",
    "RADAR_AMMOBOXES",
    "RADAR_DROPPEDWEAPONS",
    "RADAR_BACKGROUND_ALPHA",
    "RADAR_CENTER_PADDING",
    "RADAR_CENTER_BG_ALPHA",

    "INFO_ENABLED",
    "INFO_X", "INFO_Y", "INFO_SCALE", "INFO_WIDTH",

    "CRIT_ICON_ENABLED",
    "CRIT_X", "CRIT_Y", "CRIT_SCALE",
}

local function NC_SaveConfig()
    local file = io.open(NC_CONFIG_FILE, "w")
    if not file then
        return false
    end

    for i = 1, #NC_CONFIG_ORDER do
        local key = NC_CONFIG_ORDER[i]
        local value = NC_CONFIG[key]

        if type(value) == "number" then
            file:write(key, "=", string.format("%.6g", value), "\n")
        else
            file:write(key, "=", tostring(value), "\n")
        end
    end

    file:close()
    return true
end

local function NC_LoadConfig()
    local file = io.open(NC_CONFIG_FILE, "r")
    if not file then
        NC_SaveConfig()
        return
    end

    local content = file:read("*all")
    file:close()

    for key, raw in string.gmatch(content, "([%w_]+)=([^\r\n]+)") do
        if NC_CONFIG[key] ~= nil then
            local numberValue = tonumber(raw)
            if numberValue ~= nil then
                NC_CONFIG[key] = numberValue
            end
        end
    end
end

NC_LoadConfig()

_G.NC_COMBINED_STATE = _G.NC_COMBINED_STATE or {}
_G.NC_COMBINED_STATE.radarEnabled = NC_CONFIG.RADAR_ENABLED ~= 0
_G.NC_COMBINED_STATE.infoPanelEnabled = NC_CONFIG.INFO_ENABLED ~= 0
_G.NC_COMBINED_STATE.critIconEnabled = NC_CONFIG.CRIT_ICON_ENABLED ~= 0
_G.NC_COMBINED_STATE.critScale = NC_CONFIG.CRIT_SCALE
_G.NC_COMBINED_STATE.luaMenuOpen = false

_G.NC_COMBINED_STATE.radarEnemyOnly = NC_CONFIG.RADAR_ENEMY_ONLY ~= 0
_G.NC_COMBINED_STATE.radarIconStyle = NC_CONFIG.RADAR_ICON_STYLE
_G.NC_COMBINED_STATE.radarShape = NC_CONFIG.RADAR_SHAPE
_G.NC_COMBINED_STATE.radarIconSize = NC_CONFIG.RADAR_ICON_SIZE
_G.NC_COMBINED_STATE.radarZoom = NC_CONFIG.RADAR_ZOOM
_G.NC_COMBINED_STATE.radarScale = NC_CONFIG.RADAR_SCALE
_G.NC_COMBINED_STATE.radarHealthbar = NC_CONFIG.RADAR_HEALTHBAR ~= 0
_G.NC_COMBINED_STATE.radarHealthkits = NC_CONFIG.RADAR_HEALTHKITS ~= 0
_G.NC_COMBINED_STATE.radarAmmoBoxes = NC_CONFIG.RADAR_AMMOBOXES ~= 0
_G.NC_COMBINED_STATE.radarDroppedWeapons = NC_CONFIG.RADAR_DROPPEDWEAPONS ~= 0

local NC_SHARED_CONFIG_KEYS = {
    radarEnabled = "RADAR_ENABLED",
    infoPanelEnabled = "INFO_ENABLED",
    critIconEnabled = "CRIT_ICON_ENABLED",
    critScale = "CRIT_SCALE",
    radarEnemyOnly = "RADAR_ENEMY_ONLY",
    radarIconStyle = "RADAR_ICON_STYLE",
    radarShape = "RADAR_SHAPE",
    radarIconSize = "RADAR_ICON_SIZE",
    radarZoom = "RADAR_ZOOM",
    radarScale = "RADAR_SCALE",
    radarHealthbar = "RADAR_HEALTHBAR",
    radarHealthkits = "RADAR_HEALTHKITS",
    radarAmmoBoxes = "RADAR_AMMOBOXES",
    radarDroppedWeapons = "RADAR_DROPPEDWEAPONS",
}

local function NC_SetSharedState(stateKey, value)
    _G.NC_COMBINED_STATE[stateKey] = value

    local configKey = NC_SHARED_CONFIG_KEYS[stateKey]
    if configKey then
        if type(value) == "boolean" then
            NC_CONFIG[configKey] = value and 1 or 0
        else
            NC_CONFIG[configKey] = value
        end

        NC_SaveConfig()
    end
end

local NC_CALLBACKS = {}

local cleanScreenshotState = {
    nextUpdate = 0,
    enabled = false,
}

local function NC_IsTakingCleanScreenshot()
    local now = globals.RealTime()

    if now >= cleanScreenshotState.nextUpdate then
        cleanScreenshotState.nextUpdate = now + 0.25

        local ok, value =
            pcall(gui.GetValue, "Clean Screenshots")

        cleanScreenshotState.enabled =
            ok and value == 1
    end

    if not cleanScreenshotState.enabled then
        return false
    end

    local down = input.IsButtonDown

    return ((KEY_F12 and down(KEY_F12)) or false)
        or ((KEY_F7 and down(KEY_F7)) or false)
        or down(44)
        or ((KEY_PRINT and down(KEY_PRINT)) or false)
end

do

local FONT = draw.CreateFont("Tahoma", 10, 400)
local FONT_BOLD = draw.CreateFont("Tahoma", 10, 700)
local GAMEUI_FONT = draw.CreateFont("Tahoma", 13, 400)

local realTime = globals.RealTime
local isButtonDown = input.IsButtonDown
local guiGetValue = gui.GetValue
local guiSetValue = gui.SetValue
local mathFloor = math.floor
local tostring_ = tostring
local type_ = type
local pcall_ = pcall

local VALUE_REFRESH_INTERVAL = 0.25

local VK = {
    INSERT = KEY_INSERT or 45,
    RETURN = KEY_ENTER or 13,
    ESCAPE = KEY_ESCAPE or 27,
    BACK = KEY_BACKSPACE or 8,
    UP = KEY_UP or 38,
    DOWN = KEY_DOWN or 40,
    LEFT = KEY_LEFT or 37,
    RIGHT = KEY_RIGHT or 39,
}

local STYLE = {
    x = NC_CONFIG.MENU_X,
    y = NC_CONFIG.MENU_Y,
    leftW = 193,
    rightW = 218,
    preferencesW = 193,
    nestedW = 180,
    headerH = 20,
    rowH = 18,

    bg = {20, 20, 24, 165},
    border = {22, 132, 132, 255},
    line = {22, 132, 132, 255},
    text = {220, 220, 220, 255},
    title = {235, 235, 235, 255},
    muted = {175, 175, 175, 255},
    selectedFill = {62, 130, 115, 70},
}

local menuDrag = {
    active = false,
    wasDown = false,
    offsetX = 0,
    offsetY = 0,
}

local function DrawOutlinedText(font, x, y, r, g, b, a, text)
    draw.SetFont(font)
    draw.Color(0, 0, 0, 220)
    draw.Text(x - 1, y, text)
    draw.Text(x + 1, y, text)
    draw.Text(x, y - 1, text)
    draw.Text(x, y + 1, text)
    draw.Color(r, g, b, a)
    draw.Text(x, y, text)
end

local function DrawGameUIText(x, y, text)
    draw.SetFont(GAMEUI_FONT)

    draw.Color(0, 0, 0, 255)
    draw.Text(x - 1, y, text)
    draw.Text(x + 1, y, text)
    draw.Text(x, y - 1, text)
    draw.Text(x, y + 1, text)
    draw.Text(x - 1, y - 1, text)
    draw.Text(x + 1, y - 1, text)
    draw.Text(x - 1, y + 1, text)
    draw.Text(x + 1, y + 1, text)

    draw.Color(22, 132, 132, 255)
    draw.Text(x, y, text)
end

local function getBool(value)
    if value == nil or value == false or value == 0 or value == "0" then
        return false
    end

    if type_(value) == "string" then
        local lower = string.lower(value)
        if lower == "off" or lower == "false" or lower == "none" then
            return false
        end
    end

    return true
end

local function normalizeGuiNames(names)
    if type_(names) == "table" then
        return names
    end
    return {names}
end

local function safeGuiGet(item, now)
    if item.cachedValid and now < item.nextRefresh then
        return item.cachedValue
    end

    local names = item.guiNames
    local value = nil
    local resolved = nil

    for i = 1, #names do
        local ok, result = pcall_(guiGetValue, names[i])
        if ok and result ~= nil then
            value = result
            resolved = names[i]
            break
        end
    end

    item.resolvedGuiName = resolved or item.resolvedGuiName or names[1]
    item.cachedValue = value
    item.cachedValid = true
    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
    return value
end

local function safeGuiSet(item, value)
    local names = item.guiNames
    local preferred = item.resolvedGuiName or names[1]

    local ok = pcall_(guiSetValue, preferred, value)
    if not ok then
        for i = 1, #names do
            if names[i] ~= preferred then
                local aliasOk = pcall_(guiSetValue, names[i], value)
                if aliasOk then
                    item.resolvedGuiName = names[i]
                    ok = true
                    break
                end
            end
        end
    end

    item.cachedValue = value
    item.cachedValid = true
    item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
    return ok
end

local function makeGuiItem(kind, label, guiNames, options)
    local item = options or {}
    item.kind = kind
    item.label = label
    item.guiNames = normalizeGuiNames(guiNames)
    item.cachedValue = nil
    item.cachedValid = false
    item.nextRefresh = 0
    item.resolvedGuiName = nil

    item.get = function(now)
        return safeGuiGet(item, now or realTime())
    end

    item.set = function(value)
        return safeGuiSet(item, value)
    end

    return item
end

local function makeEspMasterEnableItem()
    local item = {
        kind = "toggle",
        label = "Enable",
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
    }

    local names = {
        "Players",
        "Buildings",
    }

    item.get = function(now)
        now = now or realTime()

        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        local playersOn = false
        local buildingsOn = false

        local okPlayers, players = pcall_(guiGetValue, "Players")
        if okPlayers and players ~= nil then
            playersOn = getBool(players)
        end

        local okBuildings, buildings = pcall_(guiGetValue, "Buildings")
        if okBuildings and buildings ~= nil then
            buildingsOn = getBool(buildings)
        end

        item.cachedValue = (playersOn and buildingsOn) and 1 or 0
        item.cachedValid = okPlayers or okBuildings
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL

        return item.cachedValue
    end

    item.set = function(value)
        local enabled = getBool(value)
        local raw = enabled and 1 or 0

        for i = 1, #names do
            pcall_(guiSetValue, names[i], raw)
        end

        item.cachedValue = raw
        item.cachedValid = true
        item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
        return true
    end

    return item
end

local function makeGuiBoolItem(label, guiNames)
    local item = makeGuiItem("toggle", label, guiNames)

    if #item.guiNames > 1 then
        item.get = function(now)
            now = now or realTime()
            if item.cachedValid and now < item.nextRefresh then
                return item.cachedValue
            end

            local foundAny = false
            local enabled = false
            local enabledName = nil

            for i = 1, #item.guiNames do
                local name = item.guiNames[i]
                local ok, result = pcall_(guiGetValue, name)
                if ok and result ~= nil then
                    foundAny = true
                    if getBool(result) then
                        enabled = true
                        enabledName = name
                        break
                    end
                end
            end

            if enabledName then
                item.resolvedGuiName = enabledName
            end

            item.cachedValue = enabled and 1 or 0
            item.cachedValid = foundAny
            item.nextRefresh = now + VALUE_REFRESH_INTERVAL
            return item.cachedValue
        end

        item.set = function(value)
            local numeric = value and 1 or 0
            local anyOk = false

            for i = 1, #item.guiNames do
                local ok = pcall_(guiSetValue, item.guiNames[i], numeric)
                if ok then anyOk = true end
            end

            item.cachedValue = numeric
            item.cachedValid = true
            item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
            return anyOk
        end
    else
        item.set = function(value)
            return safeGuiSet(item, value and 1 or 0)
        end
    end

    return item
end

local function makeGuiKeyItem(label, guiNames)
    local item = makeGuiItem("key", label, guiNames)

    if #item.guiNames > 1 then
        item.get = function(now)
            now = now or realTime()
            if item.cachedValid and now < item.nextRefresh then
                return item.cachedValue
            end

            local foundAny = false
            local fallbackValue = 0
            local fallbackName = nil

            for i = 1, #item.guiNames do
                local name = item.guiNames[i]
                local ok, result = pcall_(guiGetValue, name)
                if ok and result ~= nil then
                    foundAny = true
                    local numeric = tonumber(result)
                    local isBound = false

                    if numeric ~= nil then
                        isBound = numeric ~= 0
                    elseif type_(result) == "string" then
                        local lower = string.lower(result)
                        isBound = lower ~= "" and lower ~= "none" and lower ~= "off"
                    end

                    if isBound then
                        item.resolvedGuiName = name
                        item.cachedValue = result
                        item.cachedValid = true
                        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                        return result
                    end

                    if fallbackName == nil then
                        fallbackName = name
                        fallbackValue = result
                    end
                end
            end

            item.resolvedGuiName = fallbackName or item.resolvedGuiName or item.guiNames[1]
            item.cachedValue = fallbackValue
            item.cachedValid = foundAny
            item.nextRefresh = now + VALUE_REFRESH_INTERVAL
            return fallbackValue
        end

        item.set = function(value)
            local anyOk = false
            for i = 1, #item.guiNames do
                local ok = pcall_(guiSetValue, item.guiNames[i], value)
                if ok then anyOk = true end
            end

            item.cachedValue = value
            item.cachedValid = true
            item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
            return anyOk
        end
    end

    return item
end

local function makeGuiEnumItem(label, guiNames, values)
    local item = makeGuiItem("enum", label, guiNames, {values = values})

    if #item.guiNames > 1 then
        item.get = function(now)
            now = now or realTime()
            if item.cachedValid and now < item.nextRefresh then
                return item.cachedValue
            end

            local function isKnownEnumValue(value)
                local valueLower = type_(value) == "string" and string.lower(value) or nil
                for j = 1, #item.values do
                    local raw = item.values[j][1]
                    if raw == value then return true end
                    if valueLower and type_(raw) == "string" and string.lower(raw) == valueLower then
                        return true
                    end
                end
                return false
            end

            local value = nil
            local resolved = nil
            for i = 1, #item.guiNames do
                local ok, result = pcall_(guiGetValue, item.guiNames[i])
                if ok and result ~= nil and isKnownEnumValue(result) then
                    value = result
                    resolved = item.guiNames[i]
                    break
                end
            end

            item.resolvedGuiName = resolved or item.resolvedGuiName or item.guiNames[1]
            item.cachedValue = value
            item.cachedValid = value ~= nil
            item.nextRefresh = now + VALUE_REFRESH_INTERVAL
            return value
        end

        item.set = function(value)
            local anyOk = false
            for i = 1, #item.guiNames do
                local ok = pcall_(guiSetValue, item.guiNames[i], value)
                if ok then anyOk = true end
            end
            item.cachedValue = value
            item.cachedValid = true
            item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
            return anyOk
        end
    end

    return item
end

local function makeCritModeItem(label, guiNames)
    local item = makeGuiEnumItem(label, guiNames, {
        {"none", "None"},
        {"force key", "Force Key"},
        {"force always", "Force Always"},
    })

    local baseGet = item.get

    item.get = function(now)
        local value = baseGet(now)
        if type_(value) == "string" then
            local lower = string.lower(value)
            if lower == "off" or lower == "none" then return "none" end
            if lower == "force key" then return "force key" end
            if lower == "force always" then return "force always" end
        elseif type_(value) == "number" then
            if value == 0 then return "none" end
            if value == 1 then return "force key" end
            if value == 2 then return "force always" end
        end
        return value
    end

    item.set = function(value)
        local names = item.guiNames
        local candidates
        if value == "none" then
            candidates = {"off", "none", 0}
        elseif value == "force key" then
            candidates = {"force key", 1}
        else
            candidates = {"force always", 2}
        end

        for n = 1, #names do
            local name = names[n]
            for c = 1, #candidates do
                pcall_(guiSetValue, name, candidates[c])
                local ok, result = pcall_(guiGetValue, name)
                if ok then
                    local normalized = result
                    if type_(result) == "string" then
                        local lower = string.lower(result)
                        if lower == "off" or lower == "none" then normalized = "none"
                        elseif lower == "force key" then normalized = "force key"
                        elseif lower == "force always" then normalized = "force always" end
                    elseif type_(result) == "number" then
                        if result == 0 then normalized = "none"
                        elseif result == 1 then normalized = "force key"
                        elseif result == 2 then normalized = "force always" end
                    end

                    if normalized == value then
                        item.resolvedGuiName = name
                        item.cachedValue = result
                        item.cachedValid = true
                        item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
                        return true
                    end
                end
            end
        end

        item.cachedValid = false
        item.nextRefresh = 0
        return false
    end

    return item
end

local function makeDoubleTapModeItem(label)
    local item = {
        kind = "enum",
        label = label,
        guiNames = {"Double Tap"},
        values = {
            {"off", "None"},
            {"force always", "Force Always"},
            {"force key", "Force Key"},
        },
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
        resolvedGuiName = nil,
    }

    local function normalize(value)
        if value == nil then return nil end

        if type_(value) == "number" then
            if value == 0 then return "off" end
            if value == 1 then return "force always" end
            if value == 2 then return "force key" end
            return nil
        end

        local lower = string.lower(tostring_(value))
        if lower == "none" or lower == "off" then return "off" end
        if lower == "force always" then return "force always" end
        if lower == "force key" then return "force key" end
        return nil
    end

    item.get = function(now)
        now = now or realTime()
        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        if item.resolvedGuiName then
            local ok, result = pcall_(guiGetValue, item.resolvedGuiName)
            if ok then
                local normalized = normalize(result)
                if normalized then
                    item.cachedValue = normalized
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return normalized
                end
            end
            item.resolvedGuiName = nil
        end

        for i = 1, #item.guiNames do
            local name = item.guiNames[i]
            local ok, result = pcall_(guiGetValue, name)
            if ok then
                local normalized = normalize(result)
                if normalized then
                    item.resolvedGuiName = name
                    item.cachedValue = normalized
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return normalized
                end
            end
        end

        item.cachedValid = false
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
        return nil
    end

    item.set = function(value)
        local normalized = normalize(value)
        if not normalized then return false end

        local numericValue
        local stringValue
        if normalized == "off" then
            numericValue = 0
            stringValue = "off"
        elseif normalized == "force always" then
            numericValue = 1
            stringValue = "force always"
        else
            numericValue = 2
            stringValue = "force key"
        end

        local name = "Double Tap"
        local candidates = {numericValue, stringValue}

        for i = 1, #candidates do
            local ok = pcall_(guiSetValue, name, candidates[i])
            if ok then
                local readOk, result = pcall_(guiGetValue, name)
                local actual = readOk and normalize(result) or nil
                if actual == normalized then
                    item.resolvedGuiName = name
                    item.cachedValue = actual
                    item.cachedValid = true
                    item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
                    item._displayRaw = nil
                    item._displayText = nil
                    item._displayWidth = nil
                    return true
                end
            end
        end

        item.cachedValid = false
        item.nextRefresh = 0
        return false
    end

    return item
end

local function makeCompatCycleEnumItem(label, guiNames, entries)
    local values = {}
    for i = 1, #entries do
        values[i] = {entries[i].id, entries[i].display}
    end

    local item = {
        kind = "enum",
        label = label,
        guiNames = normalizeGuiNames(guiNames),
        values = values,
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
        resolvedGuiName = nil,
    }

    local function normalizeValue(value)
        if value == nil then return nil end

        if type_(value) == "number" then
            for i = 1, #entries do
                local entry = entries[i]
                for j = 1, #(entry.match or {}) do
                    if entry.match[j] == value then
                        return entry.id
                    end
                end
            end
            return nil
        end

        local lower = string.lower(tostring_(value))
        for i = 1, #entries do
            local entry = entries[i]
            for j = 1, #(entry.match or {}) do
                local candidate = entry.match[j]
                if type_(candidate) == "string" and string.lower(candidate) == lower then
                    return entry.id
                end
            end
        end

        return nil
    end

    item.get = function(now)
        now = now or realTime()
        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        if item.resolvedGuiName then
            local ok, result = pcall_(guiGetValue, item.resolvedGuiName)
            if ok then
                local normalized = normalizeValue(result)
                if normalized ~= nil then
                    item.cachedValue = normalized
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return normalized
                end
            end
            item.resolvedGuiName = nil
        end

        for i = 1, #item.guiNames do
            local name = item.guiNames[i]
            local ok, result = pcall_(guiGetValue, name)
            if ok then
                local normalized = normalizeValue(result)
                if normalized ~= nil then
                    item.resolvedGuiName = name
                    item.cachedValue = normalized
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return normalized
                end
            end
        end

        item.cachedValid = false
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
        return nil
    end

    item.set = function(value)
        local target = normalizeValue(value)
        if target == nil then target = value end

        local targetEntry = nil
        for i = 1, #entries do
            if entries[i].id == target then
                targetEntry = entries[i]
                break
            end
        end
        if not targetEntry then return false end

        local names = item.guiNames
        local setValues = targetEntry.set or {targetEntry.id}

        for n = 1, #names do
            local name = names[n]
            for s = 1, #setValues do
                pcall_(guiSetValue, name, setValues[s])
                local ok, result = pcall_(guiGetValue, name)
                if ok and normalizeValue(result) == targetEntry.id then
                    item.resolvedGuiName = name
                    item.cachedValue = targetEntry.id
                    item.cachedValid = true
                    item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
                    item._displayRaw = nil
                    item._displayText = nil
                    item._displayWidth = nil
                    return true
                end
            end
        end

        item.cachedValid = false
        item.nextRefresh = 0
        return false
    end

    return item
end

local function makeIgnoreProjectilesItem()
    local item = {
        kind = "enum",
        label = "Ignore projectiles",
        guiNames = normalizeGuiNames({
            "- Ignore projectiles",
            "- Ignore Projectiles",
            "Ignore projectiles",
            "Ignore Projectiles"
        }),
        values = {
            {"none", "None"},
            {"ignore small", "Ignore Small"},
            {"ignore big", "Ignore Big"},
        },
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
        resolvedGuiName = nil,
    }

    local function normalize(value)
        if value == nil then return nil end

        if type_(value) == "number" then
            if value == 0 then return "none" end
            if value == 1 then return "ignore small" end
            if value == 2 then return "ignore big" end
            return nil
        end

        local lower = string.lower(tostring_(value))
        if lower == "0" or lower == "none" or lower == "off" then
            return "none"
        end
        if lower == "1" or lower == "ignore small" or lower == "small" then
            return "ignore small"
        end
        if lower == "2" or lower == "ignore big" or lower == "big" then
            return "ignore big"
        end
        return nil
    end

    item.get = function(now)
        now = now or realTime()

        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        if item.resolvedGuiName then
            local ok, raw = pcall_(guiGetValue, item.resolvedGuiName)
            if ok then
                local value = normalize(raw)
                if value ~= nil then
                    item.cachedValue = value
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return value
                end
            end
            item.resolvedGuiName = nil
        end

        local noneName = nil
        local foundNone = false

        for i = 1, #item.guiNames do
            local name = item.guiNames[i]
            local ok, raw = pcall_(guiGetValue, name)
            if ok then
                local value = normalize(raw)

                if value == "ignore small" or value == "ignore big" then
                    item.resolvedGuiName = name
                    item.cachedValue = value
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return value
                elseif value == "none" and not foundNone then
                    foundNone = true
                    noneName = name
                end
            end
        end

        if foundNone then
            item.resolvedGuiName = noneName
            item.cachedValue = "none"
            item.cachedValid = true
            item.nextRefresh = now + VALUE_REFRESH_INTERVAL
            return "none"
        end

        item.cachedValid = false
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
        return nil
    end

    item.set = function(value)
        local target = normalize(value)
        if target == nil then target = value end

        local candidates
        if target == "none" then
            candidates = {0, "none", "off"}
        elseif target == "ignore small" then
            candidates = {1, "ignore small"}
        elseif target == "ignore big" then
            candidates = {2, "ignore big"}
        else
            return false
        end

        for n = 1, #item.guiNames do
            local name = item.guiNames[n]
            for c = 1, #candidates do
                pcall_(guiSetValue, name, candidates[c])
            end
        end

        item.cachedValid = false
        item.nextRefresh = 0
        item.resolvedGuiName = nil

        local now = realTime()
        local actual = item.get(now)

        if actual == target then
            item._displayRaw = nil
            item._displayText = nil
            item._displayWidth = nil
            return true
        end

        return false
    end

    return item
end

local function makeThreeModeLegitRageItem(label, guiNames)
    return makeCompatCycleEnumItem(label, guiNames, {
        {id = "none", display = "None", match = {0, "0", "none", "off"}, set = {0, "none", "off"}},
        {id = "legit", display = "Legit", match = {1, "1", "legit"}, set = {1, "legit"}},
        {id = "rage", display = "Rage", match = {2, "2", "rage"}, set = {2, "rage"}},
    })
end

local function makeAutoUberchargeModeItem(label, guiNames)
    return makeCompatCycleEnumItem(label, guiNames, {
        {id = "none", display = "None", match = {0, "0", "none", "off"}, set = {0, "none", "off"}},
        {id = "all players", display = "All Players", match = {1, "1", "all players", "all"}, set = {1, "all players"}},
        {id = "friends only", display = "Friends Only", match = {2, "2", "friends only", "friends"}, set = {2, "friends only"}},
    })
end

local function makeFakeLagValueItem()
    local item = {
        kind = "number",
        label = "Fake Lag Value (ms)",
        guiNames = normalizeGuiNames({
            "Fake Lag Value (ms)",
            "Fake Lag Value (MS)",
            "fake lag value (ms)"
        }),
        min = 30,
        max = 330,
        step = 15,
        offAtZero = false,
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
        resolvedGuiName = nil,
    }

    local function rawToDisplayed(raw)
        raw = tonumber(raw)
        if raw == nil then return nil end

        local displayed = raw + 15

        if displayed < 30 then displayed = 30 end
        if displayed > 330 then displayed = 330 end
        return displayed
    end

    local function displayedToRaw(displayed)
        displayed = tonumber(displayed) or 30
        if displayed < 30 then displayed = 30 end
        if displayed > 330 then displayed = 330 end
        return displayed - 15
    end

    item.get = function(now)
        now = now or realTime()
        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        if item.resolvedGuiName then
            local ok, raw = pcall_(guiGetValue, item.resolvedGuiName)
            if ok and tonumber(raw) ~= nil then
                local displayed = rawToDisplayed(raw)
                if displayed then
                    item.cachedValue = displayed
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return displayed
                end
            end
            item.resolvedGuiName = nil
        end

        local fallbackName, fallbackRaw = nil, nil
        for i = 1, #item.guiNames do
            local name = item.guiNames[i]
            local ok, raw = pcall_(guiGetValue, name)
            raw = ok and tonumber(raw) or nil
            if raw ~= nil then
                if raw >= 15 and raw <= 315 then
                    item.resolvedGuiName = name
                    local displayed = rawToDisplayed(raw)
                    item.cachedValue = displayed
                    item.cachedValid = true
                    item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                    return displayed
                elseif fallbackName == nil then
                    fallbackName, fallbackRaw = name, raw
                end
            end
        end

        if fallbackName then
            item.resolvedGuiName = fallbackName
            item.cachedValue = rawToDisplayed(fallbackRaw)
            item.cachedValid = true
            item.nextRefresh = now + VALUE_REFRESH_INTERVAL
            return item.cachedValue
        end

        item.cachedValid = false
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
        return 30
    end

    item.set = function(displayed)
        displayed = tonumber(displayed) or 30
        if displayed > 330 then displayed = 30 end
        if displayed < 30 then displayed = 330 end

        local raw = displayedToRaw(displayed)
        local preferred = item.resolvedGuiName

        local function trySet(name)
            if not name then return false end
            local ok = pcall_(guiSetValue, name, raw)
            if not ok then return false end

            local readOk, readRaw = pcall_(guiGetValue, name)
            readRaw = readOk and tonumber(readRaw) or nil
            if readRaw ~= nil then
                local actual = rawToDisplayed(readRaw)
                if actual == displayed then
                    item.resolvedGuiName = name
                    item.cachedValue = actual
                    item.cachedValid = true
                    item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
                    item._displayRaw = nil
                    item._displayText = nil
                    item._displayWidth = nil
                    return true
                end
            end
            return false
        end

        if trySet(preferred) then return true end

        for i = 1, #item.guiNames do
            if item.guiNames[i] ~= preferred and trySet(item.guiNames[i]) then
                return true
            end
        end

        item.cachedValid = false
        item.nextRefresh = 0
        return false
    end

    return item
end

local function makeGuiNumberItem(label, guiNames, minVal, maxVal, step, offAtZero, displaySuffix)
    return makeGuiItem("number", label, guiNames, {
        min = minVal,
        max = maxVal,
        step = step,
        offAtZero = offAtZero,
        displaySuffix = displaySuffix,
    })
end

local function makeOff100Item(label, guiName)
    local item = makeGuiNumberItem(
        label,
        guiName,
        0, 100, 1,
        true
    )

    item.wrap = true
    return item
end

local localState = {
    infoPanelEnabled = _G.NC_COMBINED_STATE.infoPanelEnabled ~= false,
    radarEnabled = _G.NC_COMBINED_STATE.radarEnabled ~= false,
    radarEnemyOnly = _G.NC_COMBINED_STATE.radarEnemyOnly ~= false,
    critIconEnabled = _G.NC_COMBINED_STATE.critIconEnabled ~= false,
    luaEnabled = true,
}

local function makeStateToggleItem(label, key)
    return {
        kind = "toggle",
        label = label,

        get = function()
            if NC_SHARED_CONFIG_KEYS[key] then
                localState[key] = _G.NC_COMBINED_STATE[key] ~= false
            end

            return localState[key]
        end,

        set = function(value)
            localState[key] = value and true or false

            if NC_SHARED_CONFIG_KEYS[key] then
                NC_SetSharedState(key, localState[key])
            end
        end,
    }
end

local function makeSharedCycleItem(label, stateKey, values)
    return {
        kind = "shared_enum",
        label = label,

        get = function()
            local current = _G.NC_COMBINED_STATE[stateKey]

            for i = 1, #values do
                if values[i].value == current then
                    return values[i].display
                end
            end

            NC_SetSharedState(stateKey, values[1].value)
            return values[1].display
        end,

        cycle = function(dir)
            local current = _G.NC_COMBINED_STATE[stateKey]
            local index = 1

            for i = 1, #values do
                if values[i].value == current then
                    index = i
                    break
                end
            end

            index = index + dir
            if index < 1 then index = #values end
            if index > #values then index = 1 end

            NC_SetSharedState(stateKey, values[index].value)
            return true
        end,
    }
end

local function makeSharedNumberItem(
    label,
    stateKey,
    minValue,
    maxValue,
    step,
    wrap,
    displayDecimals
)
    return {
        kind = "number",
        label = label,
        min = minValue,
        max = maxValue,
        step = step,
        wrap = wrap and true or false,
        displayDecimals = displayDecimals,

        get = function()
            return tonumber(_G.NC_COMBINED_STATE[stateKey]) or minValue
        end,

        set = function(value)
            value = tonumber(value) or minValue

            if displayDecimals then
                local factor = 10 ^ displayDecimals
                value = math.floor((value * factor) + 0.5) / factor
            else
                value = math.floor(value + 0.5)
            end

            NC_SetSharedState(stateKey, value)
            return true
        end,
    }
end

local function makeCritIconScaleItem()
    local item = makeSharedNumberItem(
        "Crit Icon Scale",
        "critScale",
        0, 9, 1,
        true,
        nil
    )

    item.offAtZero = true
    return item
end

local function makeAimFovRangeTransparencyItem()
    local item = {
        kind = "number",
        label = "Aim FOV Range Transparency",
        min = 0,
        max = 100,
        step = 1,
        offAtZero = true,
        aimFovRangeTransparency = true,
        cachedValue = 0,
        cachedValid = false,
        nextRefresh = 0,
    }

    item.get = function(now)
        now = now or realTime()

        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        local enabled = false
        local transparency = 100

        local okEnabled, enabledValue =
            pcall_(guiGetValue, "Aim FOV Range")

        if okEnabled and enabledValue ~= nil then
            enabled = getBool(enabledValue)
        end

        local okTransparency, transparencyValue =
            pcall_(guiGetValue, "Aim FOV Range Transparency")

        if okTransparency and transparencyValue ~= nil then
            local numeric = tonumber(transparencyValue)
            if numeric ~= nil then
                transparency = numeric
            end
        end

        if transparency < 1 then transparency = 1 end
        if transparency > 100 then transparency = 100 end

        item.cachedValue = enabled and transparency or 0
        item.cachedValid = okEnabled or okTransparency
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL

        return item.cachedValue
    end

    item.set = function(value)
        value = tonumber(value) or 0

        if value <= 0 then
            pcall_(guiSetValue, "Aim FOV Range", 0)

            item.cachedValue = 0
            item.cachedValid = true
            item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
            return true
        end

        value = math.floor(value + 0.5)
        if value < 1 then value = 1 end
        if value > 100 then value = 100 end

        pcall_(
            guiSetValue,
            "Aim FOV Range Transparency",
            value
        )
        pcall_(guiSetValue, "Aim FOV Range", 1)

        item.cachedValue = value
        item.cachedValid = true
        item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
        return true
    end

    return item
end

local function makeWrappedAngleItem(label, guiNames, maxAbs)
    local item = makeGuiItem("number", label, guiNames, {
        min = -maxAbs,
        max = maxAbs,
        step = 1,
    })

    item.angleWrapMax = maxAbs
    item.offAtZero = true
    return item
end

local customFovState = {
    value = 0.0,
    active = false,

    savedCheatEnabled = nil,
    savedCheatValue = nil,
    savedGameFov = nil,
}

local customVmFovState = {
    value = 0.0,
    active = false,

    savedViewmodelFov = nil,

}

local function readViewmodelFovConVar()
    if not client or not client.GetConVar then
        return nil
    end

    local ok, value = pcall_(client.GetConVar, "viewmodel_fov")
    if not ok or value == nil then
        return nil
    end

    return tonumber(value)
end

local function writeViewmodelFov(value)
    value = tonumber(value)
    if value == nil or not client or not client.SetConVar then
        return false
    end

    local ok = pcall_(
        client.SetConVar,
        "viewmodel_fov",
        value
    )

    return ok
end

local function saveCustomFovBaseline()
    if customFovState.active then
        return
    end

    local okEnabled, enabled =
        pcall_(guiGetValue, "Enable Custom FOV")
    if okEnabled then
        customFovState.savedCheatEnabled = enabled
    end

    local okValue, value =
        pcall_(guiGetValue, "Custom FOV Value")
    if okValue then
        customFovState.savedCheatValue = value
    end

    if client and client.GetConVar then
        local okGame, gameFov =
            pcall_(client.GetConVar, "fov_desired")

        if okGame then
            customFovState.savedGameFov = gameFov
        end
    end

    customFovState.active = true
end

local function restoreCustomFovBaseline()
    if not customFovState.active then
        return
    end

    if customFovState.savedCheatValue ~= nil then
        pcall_(
            guiSetValue,
            "Custom FOV Value",
            customFovState.savedCheatValue
        )
    end

    if customFovState.savedCheatEnabled ~= nil then
        pcall_(
            guiSetValue,
            "Enable Custom FOV",
            customFovState.savedCheatEnabled
        )
    end

    if customFovState.savedGameFov ~= nil
        and client
        and client.SetConVar then

        pcall_(
            client.SetConVar,
            "fov_desired",
            customFovState.savedGameFov
        )
    end

    customFovState.active = false
    customFovState.savedCheatEnabled = nil
    customFovState.savedCheatValue = nil
    customFovState.savedGameFov = nil
end

local function setCustomFovValue(value)
    value = tonumber(value) or 0.0

    if value <= 0 then
        customFovState.value = 0.0
        restoreCustomFovBaseline()
        return true
    end

    if value > 180 then
        value = 180
    end

    saveCustomFovBaseline()

    customFovState.value = value

    pcall_(guiSetValue, "Enable Custom FOV", 1)
    pcall_(guiSetValue, "Custom FOV Value", value)

    return true
end

local function setCustomVmFovValue(value)
    value = tonumber(value) or 0.0

    if value <= 0 then
        customVmFovState.value = 0.0

        if customVmFovState.active
            and customVmFovState.savedViewmodelFov ~= nil then
            writeViewmodelFov(
                customVmFovState.savedViewmodelFov
            )
        end

        customVmFovState.active = false
        customVmFovState.savedViewmodelFov = nil
        return true
    end

    if value > 180 then
        value = 180
    end

    if not customVmFovState.active then
        customVmFovState.savedViewmodelFov =
            readViewmodelFovConVar()

        customVmFovState.active = true
    end

    customVmFovState.value = value

    writeViewmodelFov(value)
    return true
end

local function makeCustomFovItem()
    return {
        kind = "number",
        label = "Custom FOV",
        min = 0.0,
        max = 180.0,
        step = 1.0,
        wrap = true,
        displayDecimals = 1,

        get = function()
            return customFovState.value
        end,

        set = setCustomFovValue,
    }
end

local function makeCustomVmFovItem()
    return {
        kind = "number",
        label = "Custom VM FOV",
        min = 0.0,
        max = 180.0,
        step = 1.0,
        wrap = true,
        displayDecimals = 1,

        get = function()
            return customVmFovState.value
        end,

        set = setCustomVmFovValue,
    }
end

local function restoreRuntimeFovSettings()
    restoreCustomFovBaseline()

    if customVmFovState.active
        and customVmFovState.savedViewmodelFov ~= nil then
        writeViewmodelFov(
            customVmFovState.savedViewmodelFov
        )
    end

    customVmFovState.value = 0.0
    customVmFovState.active = false
    customVmFovState.savedViewmodelFov = nil
end

local function makePingReducerItem()
    local item = {
        kind = "number",
        label = "Ping Reducer",
        min = 5,
        max = 200,
        step = 5,
        pingReducerCombined = true,
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
    }

    item.get = function(now)
        now = now or realTime()

        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        local enabled = false
        local target = 5

        local okEnabled, enabledValue =
            pcall_(guiGetValue, "Ping Reducer")
        if okEnabled then
            enabled = getBool(enabledValue)
        end

        local okTarget, targetValue =
            pcall_(guiGetValue, "Ping Reducer Target (ms)")
        if okTarget and tonumber(targetValue) then
            target = tonumber(targetValue)
        end

        if target < 5 then target = 5 end
        if target > 200 then target = 200 end

        item.cachedValue = enabled and target or 0
        item.cachedValid = okEnabled or okTarget
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL

        return item.cachedValue
    end

    item.set = function(value)
        value = tonumber(value) or 0

        if value <= 0 then
            pcall_(guiSetValue, "Ping Reducer", 0)

            item.cachedValue = 0
            item.cachedValid = true
            item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
            return true
        end

        if value < 5 then value = 5 end
        if value > 200 then value = 200 end

        pcall_(guiSetValue, "Ping Reducer Target (ms)", value)
        pcall_(guiSetValue, "Ping Reducer", 1)

        item.cachedValue = value
        item.cachedValid = true
        item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
        return true
    end

    return item
end

local actionConfirm = {
    pending = nil,
    text = nil,
}

local function resetActionConfirm()
    actionConfirm.pending = nil
    actionConfirm.text = nil
end

local function beginActionConfirm(key, text)
    if actionConfirm.pending == key then
        resetActionConfirm()
        return true
    end

    actionConfirm.pending = key
    actionConfirm.text = text
    return false
end

local function makeLuaEnableItem()
    local item = {
        kind = "toggle",
        label = "Lua",
        confirmKey = "lua_toggle",
    }

    item.get = function()
        return localState.luaEnabled
    end

    item.set = function(value)
        local wanted = value and true or false
        local stateText = wanted and "ON" or "OFF"

        local confirmed = beginActionConfirm(
            item.confirmKey,
            "Are you sure you want to turn Lua "
                .. stateText
                .. "? Press again to continue."
        )

        if not confirmed then
            return false
        end

        if wanted == false and localState.luaEnabled ~= false then
            localState.luaEnabled = false

            if client and client.Command then
                pcall_(client.Command, "quit", true)
            end

            return true
        end

        localState.luaEnabled = wanted
        return true
    end

    return item
end

local function makeNestedItem(label, submenu, targetLevel)
    return {
        kind = "submenu",
        label = label,
        submenu = submenu,
        targetLevel = targetLevel or 3,
    }
end

local openedLinkInfo = {
    url = nil,
    untilTime = 0,
}

local function openExternalUrl(url)
    url = tostring_(url or "")
    url = string.gsub(url, "[\r\n]", "")

    if not string.match(url, "^https?://") then
        return false
    end

    print("Open this URL manually:")
    print(url)

    openedLinkInfo.url = url
    openedLinkInfo.untilTime = realTime() + 6.0

    return false
end

local function makeLinkActionItem(label, url)
    local item = {
        kind = "action",
        label = label,
        confirmKey = "link:" .. label,
    }

    item.activate = function()
        local confirmed = beginActionConfirm(
            item.confirmKey,
            "Are you sure you want to open this link? Press again to open it."
        )

        if confirmed then
            openExternalUrl(url)
        end
    end

    return item
end

local IGNORE_FILTER_MENU = {
    makeGuiBoolItem("Steam Friends", {"Ignore Steam Friends", "Steam Friends"}),
    makeGuiBoolItem("DeadRinger", {"Ignore Deadringer", "Ignore DeadRinger", "Deadringer", "DeadRinger"}),
    makeGuiBoolItem("Cloaked", {
        "Ignore Cloaked",
        "Cloaked",
    }),

    makeGuiBoolItem("Hide Cloaked", {
        "Hide Cloaked",
    }),
    makeGuiBoolItem("Disguised", {"Ignore Disguised", "Disguised"}),
    makeGuiBoolItem("Taunting", {"Ignore Taunting", "Taunting"}),
    makeGuiBoolItem("Bonked", {"Ignore Bonked", "Bonked"}),
    makeGuiBoolItem("Vacc Ubercharge", {"Ignore Vacc Ubercharge", "Vacc Ubercharge", "Vacc UberCharge"}),
}

local PREFERENCES_MENU = {
    makeGuiEnumItem("Heal/Buff Weapons", "Heal/Buff Weapons", {
        {"teammates", "Teammates"},
        {"enemies", "Enemies"},
        {"both teams", "Both Teams"},
    }),

    makeGuiBoolItem("Prefer Medics", "Prefer Medics"),
    makeGuiBoolItem("Minigun Spinup", "Minigun Spinup"),
    makeGuiBoolItem("Minigun Tapfire", {"Minigun tapfire", "Minigun Tapfire"}),
    makeGuiBoolItem("Sniper: Zoomed only", {"Sniper: Zoomed Only", "Sniper: Zoomed only"}),
    makeGuiBoolItem("Sniper: Auto Zoom", "Sniper: Auto Zoom"),
    makeGuiBoolItem("Wait for charge", {"Wait for charge", "Wait For Charge"}),

    makeGuiNumberItem("Minimal priority", {"Minimal Priority", "Minimal priority"}, 0, 10, 1, true),
    makeGuiNumberItem("Spread: Max Distance", "Spread: Max Distance", 0, 200, 1, true),

    makeGuiBoolItem("BackTrack", {"Backtrack", "BackTrack"}),
    makeGuiNumberItem("BackTrack Size (Ticks)", {"BackTrack Size (Ticks)", "Backtrack Size (Ticks)"}, 0, 14, 1, false),

    makeGuiBoolItem("Fake Latency", "Fake Latency"),
    makeGuiNumberItem("Fake Latency Value (ms)", {"Fake Latency Value (MS)", "Fake Latency Value (ms)"}, 0, 1000, 10, false),

    makeDoubleTapModeItem("Double Tap"),
    makeGuiKeyItem("Double Tap Key", "Double Tap Key"),
    makeGuiKeyItem("Force recharge Key", {"Force Recharge Key", "Force recharge Key"}),

    makeNestedItem("Ignore Filter", IGNORE_FILTER_MENU, 4),
}

local configSelector = {
    kind = "config_selector",
    label = "Config",
    pending = "Default",
}

local function cycleConfigSelector()
    configSelector.pending = "Default"
    configSelector._displayRaw = nil
    configSelector._displayText = nil
    configSelector._displayWidth = nil
end

local function applySelectedConfig()
    return true
end

local CONFIG_MENU = {
    configSelector,
}

local INFO_LINKS_MENU = {
    makeLinkActionItem(
        "Join Discord",
        "https://discord.gg/CwG7VkhSSm"
    ),
    makeLinkActionItem(
        "Join Telegram",
        "https://www.t.me/+keeCq5DyUP4wODBk"
    ),
    makeLinkActionItem(
        "Suggest a new feature",
        "https://lbox.sleekplan.app/?type=feature"
    ),
    makeLinkActionItem(
        "Report a bug",
        "https://lbox.sleekplan.app/?type=t671a4ded1a1d7"
    ),
}

local CHEAT_SETTINGS_MENU = {
    makeLuaEnableItem(),
    makeNestedItem("Config", CONFIG_MENU, 3),
    makeNestedItem("Info", INFO_LINKS_MENU, 3),
}

local function makeSharedEspBoolItem(label, playerNames, buildingNames)
    local allNames = {}

    local function appendNames(names)
        names = normalizeGuiNames(names)
        for i = 1, #names do
            allNames[#allNames + 1] = names[i]
        end
    end

    appendNames(playerNames)
    appendNames(buildingNames)

    local item = {
        kind = "toggle",
        label = label,
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
    }

    item.get = function(now)
        now = now or realTime()

        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        local enabled = false
        local foundAny = false

        for i = 1, #allNames do
            local ok, value = pcall_(guiGetValue, allNames[i])
            if ok and value ~= nil then
                foundAny = true
                if getBool(value) then
                    enabled = true
                end
            end
        end

        item.cachedValue = enabled and 1 or 0
        item.cachedValid = foundAny
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
        return item.cachedValue
    end

    item.set = function(value)
        local raw = getBool(value) and 1 or 0

        for i = 1, #allNames do
            pcall_(guiSetValue, allNames[i], raw)
        end

        item.cachedValue = raw
        item.cachedValid = true
        item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
        return true
    end

    return item
end

local function makeSharedEspEnumItem(label, playerNames, buildingNames, entries)
    local allNames = {}

    local function appendNames(names)
        names = normalizeGuiNames(names)
        for i = 1, #names do
            allNames[#allNames + 1] = names[i]
        end
    end

    appendNames(playerNames)
    appendNames(buildingNames)

    local values = {}
    for i = 1, #entries do
        values[i] = {entries[i].id, entries[i].display}
    end

    local item = {
        kind = "enum",
        label = label,
        values = values,
        cachedValue = nil,
        cachedValid = false,
        nextRefresh = 0,
    }

    local function normalize(value)
        if value == nil then return nil end

        if type_(value) == "number" then
            for i = 1, #entries do
                local entry = entries[i]
                for j = 1, #(entry.match or {}) do
                    if entry.match[j] == value then
                        return entry.id
                    end
                end
            end
            return nil
        end

        local lower = string.lower(tostring_(value))
        for i = 1, #entries do
            local entry = entries[i]
            for j = 1, #(entry.match or {}) do
                local candidate = entry.match[j]
                if type_(candidate) == "string"
                    and string.lower(candidate) == lower then
                    return entry.id
                end
            end
        end

        return nil
    end

    item.get = function(now)
        now = now or realTime()

        if item.cachedValid and now < item.nextRefresh then
            return item.cachedValue
        end

        local zeroCandidate = nil

        for i = 1, #allNames do
            local ok, raw = pcall_(guiGetValue, allNames[i])

            if ok and raw ~= nil then
                local normalized = normalize(raw)
                if normalized ~= nil then
                    local isZero =
                        raw == 0
                        or raw == "0"
                        or (type_(raw) == "string"
                            and (string.lower(raw) == "none"
                                or string.lower(raw) == "off"))

                    if not isZero then
                        item.cachedValue = normalized
                        item.cachedValid = true
                        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
                        return normalized
                    elseif zeroCandidate == nil then
                        zeroCandidate = normalized
                    end
                end
            end
        end

        item.cachedValue = zeroCandidate
        item.cachedValid = zeroCandidate ~= nil
        item.nextRefresh = now + VALUE_REFRESH_INTERVAL
        return zeroCandidate
    end

    item.set = function(id)
        local entry = nil

        for i = 1, #entries do
            if entries[i].id == id then
                entry = entries[i]
                break
            end
        end

        if not entry then return false end

        local setValues = entry.set or {}

        for i = 1, #allNames do
            for j = 1, #setValues do
                pcall_(guiSetValue, allNames[i], setValues[j])
            end
        end

        item.cachedValue = id
        item.cachedValid = true
        item.nextRefresh = realTime() + VALUE_REFRESH_INTERVAL
        return true
    end

    return item
end

local ESP_GLOW_MENU = {
    makeSharedEspEnumItem(
        "Glow",
        {"Glow"},
        {"Buildings Glow", "Building Glow", "Glow"},
        {
            {id = "none",   display = "None",   match = {0, "0", "none"},   set = {0, "none"}},
            {id = "health", display = "Health", match = {1, "1", "health"}, set = {1, "health"}},
            {id = "team",   display = "Team",   match = {2, "2", "team"},   set = {2, "team"}},
        }
    ),

    makeCompatCycleEnumItem("Glow Style", {"Glow Style"}, {
        {id = "legacy",    display = "Legacy",    match = {0, "0", "legacy"},    set = {0, "legacy"}},
        {id = "blur glow", display = "Blur Glow", match = {1, "1", "blur glow"}, set = {1, "blur glow"}},
    }),

    makeCompatCycleEnumItem("Glow Mode", {"Glow Mode"}, {
        {id = "outline",       display = "Outline",       match = {0, "0", "outline"},       set = {0, "outline"}},
        {id = "solid",         display = "Solid",         match = {1, "1", "solid"},         set = {1, "solid"}},
        {id = "outline-solid", display = "Outline-Solid", match = {2, "2", "outline-solid"}, set = {2, "outline-solid"}},
    }),

    makeGuiNumberItem("Glow Size", {"Glow Size"}, 1, 30, 1, false),
    makeGuiBoolItem("Glow Weapon", {"Glow Weapon"}),
}

local ESP_CHAMS_MENU = {
    makeGuiBoolItem("Colored Players", {
        "Colored Players",
        "COLORED PLAYERS",
        "Chams",
        "Player Chams",
    }),

    makeCompatCycleEnumItem("Draw Mode", {
        "Draw Mode",
    }, {
        {
            id = "always",
            display = "Always",
            match = {1, "1", "always"},
            set = {"always", 1},
        },
        {
            id = "when visible",
            display = "When visible",
            match = {2, "2", "when visible", "visible"},
            set = {"when visible", 2},
        },
        {
            id = "when invisible",
            display = "When invisible",
            match = {3, "3", "when invisible", "invisible"},
            set = {"when invisible", 3},
        },
    }),

    makeCompatCycleEnumItem("Draw Style", {
        "Draw Style",
    }, {
        {
            id = "flat",
            display = "Flat",
            match = {1, "1", "flat"},
            set = {"flat", 1},
        },
        {
            id = "textured",
            display = "Textured",
            match = {2, "2", "textured"},
            set = {"textured", 2},
        },
    }),

    makeGuiBoolItem("Classic Wallhack", {
        "Classic Wallhack",
        "CLASSIC WALLHACK",
        "Chams Classic Wallhack",
    }),
}

local SKYBOX_FACES = {
    "bk", "dn", "ft", "lf", "rt", "up",
}

local SKYBOX_BUILTINS = {
    "sky_night_01",
    "sky_nightfall_01",
    "sky_harvest_night_01",
    "sky_hydro_01",
    "sky_well_01",
    "sky_rainbow_01",
    "sky_alpinestorm_01",
}

local skyboxState = {
    selected = "off",
    original = nil,
    map = nil,
    nextApply = 0,
    custom = {},
    mapDefaults = {},
}

local KNOWN_MAP_SKYBOXES = {
    ctf_2fort = "sky_urb01",
}

local function ScanCustomSkyboxes()
    local groups = {}

    if not filesystem or not filesystem.EnumerateDirectory then
        return groups
    end

    pcall_(
        filesystem.EnumerateDirectory,
        [[tf/materials/skybox/*]],
        function(filename, attributes)
            if not filename then return end

            local lower = string.lower(tostring_(filename))
            if not string.match(lower, "%.vtf$") then
                return
            end

            local stem = string.sub(filename, 1, #filename - 4)
            local stemLower = string.lower(stem)

            for i = 1, #SKYBOX_FACES do
                local face = SKYBOX_FACES[i]

                if string.sub(stemLower, -2) == face then
                    local base = string.sub(stem, 1, #stem - 2)
                    local baseLower = string.lower(base)

                    if base ~= "" then
                        local group = groups[baseLower]

                        if not group then
                            group = {
                                name = base,
                                faces = {},
                            }
                            groups[baseLower] = group
                        end

                        group.faces[face] = stem
                    end

                    break
                end
            end
        end
    )

    local complete = {}

    for key, group in pairs(groups) do
        local valid = true

        for i = 1, #SKYBOX_FACES do
            if not group.faces[SKYBOX_FACES[i]] then
                valid = false
                break
            end
        end

        if valid then
            complete[key] = group
        end
    end

    return complete
end

local function EnsureCustomSkyboxVMTs(name)
    local group = skyboxState.custom[string.lower(name or "")]
    if not group then
        return true
    end

    for i = 1, #SKYBOX_FACES do
        local face = SKYBOX_FACES[i]
        local stem = group.faces[face]

        if not stem then
            return false
        end

        local vmtPath =
            "tf/materials/skybox/"
            .. stem
            .. ".vmt"

        local exists = false

        if filesystem and filesystem.GetFileAttributes then
            local ok, attributes =
                pcall_(filesystem.GetFileAttributes, vmtPath)

            if ok and attributes
                and attributes ~= INVALID_FILE_ATTRIBUTES then
                exists = true
            end
        end

        if not exists then
            local file = io.open(vmtPath, "w")

            if not file then
                print(
                    "Failed to create skybox material: "
                    .. vmtPath
                )
                return false
            end

            file:write(
                [["sky"
{
    "$basetexture" "skybox/]]
                .. stem
                .. [["
    "$nofog" "1"
    "$nomip" "1"
    "$ignorez" "1"
}
]]
            )

            file:close()
        end
    end

    return true
end

local function ReadUInt32LE(data, pos)
    local b1, b2, b3, b4 =
        string.byte(data, pos, pos + 3)

    if not b4 then
        return nil
    end

    return b1
        + b2 * 256
        + b3 * 65536
        + b4 * 16777216
end

local function NormalizeMapName(name)
    name = tostring_(name or "")
    name = string.gsub(name, "\\", "/")
    name = string.match(name, "([^/]+)$") or name
    name = string.gsub(name, "%.bsp$", "")
    return name
end

local function GetMapDefaultSkybox(mapName)
    mapName = NormalizeMapName(mapName)
    if mapName == "" then
        return nil
    end

    local cached = skyboxState.mapDefaults[mapName]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end

    local paths = {
        "tf/maps/" .. mapName .. ".bsp",
        "maps/" .. mapName .. ".bsp",
    }

    for i = 1, #paths do
        local file = io.open(paths[i], "rb")

        if file then
            local header = file:read(24)

            if header and #header >= 16
                and string.sub(header, 1, 4) == "VBSP" then

                local entityOffset =
                    ReadUInt32LE(header, 9)
                local entityLength =
                    ReadUInt32LE(header, 13)

                if entityOffset
                    and entityLength
                    and entityLength > 0 then

                    file:seek("set", entityOffset)
                    local entitiesText =
                        file:read(entityLength)

                    file:close()

                    if entitiesText then
                        local sky =
                            string.match(
                                entitiesText,
                                [["skyname"%s*"([^"]+)"]]
                            )

                        if sky and sky ~= "" then
                            skyboxState.mapDefaults[mapName] = sky
                            return sky
                        end
                    end
                else
                    file:close()
                end
            else
                file:close()
            end
        end
    end

    local known =
        KNOWN_MAP_SKYBOXES[string.lower(mapName)]

    if known then
        skyboxState.mapDefaults[mapName] = known
        return known
    end

    skyboxState.mapDefaults[mapName] = false
    return nil
end

local function GetCurrentSkyboxName()
    if not client or not client.GetConVar then
        return nil
    end

    local ok, value =
        pcall_(client.GetConVar, "sv_skyname")

    if not ok or value == nil then
        return nil
    end

    value = tostring_(value)

    local lower = string.lower(value)

    if value == ""
        or lower == "0"
        or lower == "off"
        or lower == "none" then
        return nil
    end

    return value
end

local function SetSkyboxName(name)
    if not name then
        return false
    end

    name = tostring_(name)

    local lower = string.lower(name)

    if name == ""
        or lower == "0"
        or lower == "off"
        or lower == "none" then
        return false
    end

    if client and client.RemoveConVarProtection then
        pcall_(
            client.RemoveConVarProtection,
            "sv_skyname"
        )
    end

    if client and client.SetConVar then
        local ok =
            pcall_(
                client.SetConVar,
                "sv_skyname",
                name
            )

        if ok then
            return true
        end
    end

    if client and client.Command then
        return pcall_(
            client.Command,
            'sv_skyname "' .. name .. '"',
            true
        )
    end

    return false
end

local function RestoreSkybox()
    local restoreName =
        GetMapDefaultSkybox(skyboxState.map)
        or skyboxState.original

    if restoreName and restoreName ~= "" then
        SetSkyboxName(restoreName)
        skyboxState.original = restoreName
    end

    skyboxState.selected = "off"
    skyboxState.nextApply = 0
end

local function UpdateSkyboxOverride(now)
    local mapName = ""

    if engine and engine.GetMapName then
        local ok, value = pcall_(engine.GetMapName)

        if ok and value then
            mapName = tostring_(value)
        end
    end

    if mapName ~= skyboxState.map then
        skyboxState.map = mapName

        local mapDefault =
            GetMapDefaultSkybox(mapName)

        if mapDefault and mapDefault ~= "" then
            skyboxState.original = mapDefault
        elseif skyboxState.selected == "off" then
            skyboxState.original =
                GetCurrentSkyboxName()
        end

        skyboxState.nextApply = 0
    end

    if skyboxState.selected == "off" then
        return
    end

    if now >= skyboxState.nextApply then
        skyboxState.nextApply = now + 1.0
        SetSkyboxName(skyboxState.selected)
    end
end

local function BuildSkyboxItem()
    skyboxState.custom = ScanCustomSkyboxes()

    local values = {
        {"off", "OFF"},
    }

    local known = {
        off = true,
    }

    for i = 1, #SKYBOX_BUILTINS do
        local name = SKYBOX_BUILTINS[i]
        local key = string.lower(name)

        known[key] = true
        values[#values + 1] = {
            name,
            name,
        }
    end

    local customNames = {}

    for key, group in pairs(skyboxState.custom) do
        if not known[key] then
            customNames[#customNames + 1] = group.name
        end
    end

    table.sort(
        customNames,
        function(a, b)
            return string.lower(a) < string.lower(b)
        end
    )

    for i = 1, #customNames do
        local name = customNames[i]

        values[#values + 1] = {
            name,
            name,
        }
    end

    return {
        kind = "enum",
        label = "Sky Box",
        values = values,

        get = function()
            return skyboxState.selected
        end,

        set = function(value)
            if value == nil
                or value == 0
                or value == "0" then
                RestoreSkybox()
                return true
            end

            value = tostring_(value or "off")

            local lower = string.lower(value)

            if lower == "off"
                or lower == "none" then
                RestoreSkybox()
                return true
            end

            if not EnsureCustomSkyboxVMTs(value) then
                return false
            end

            if skyboxState.selected == "off" then
                skyboxState.original =
                    GetMapDefaultSkybox(skyboxState.map)
                    or GetCurrentSkyboxName()
            end

            if SetSkyboxName(value) then
                skyboxState.selected = value
                skyboxState.nextApply =
                    realTime() + 1.0
                return true
            end

            return false
        end,
    }
end

local ESP_MISC_MENU = {
    BuildSkyboxItem(),
    makeGuiBoolItem("Big Heads", {
        "Big Heads",
    }),

    makeGuiBoolItem("Rain effect", {
        "Rain effect",
        "Rain Effect",
    }),

    makeGuiBoolItem("Scoreboard: Show enemy classes", {
        "Scoreboard: Show enemy classes",
        "Scoreboard: Show Enemy Classes",
    }),
}

local MAIN_MENU = {
    {
        label = "Aim Bot",
        submenu = {
            makeGuiBoolItem("Enabled", "Aim Bot"),
            makeGuiKeyItem("Key", "Aim Key"),
            makeGuiEnumItem("Mode", "Aim Key Mode", {
                {"hold-to-use", "Hold-To-Use"},
                {"press-to-toggle", "Press-To-Toggle"},
            }),
            makeGuiEnumItem("Method", "Aim Method", {
                {"plain", "Plain"},
                {"smooth", "Smooth"},
                {"assistance", "Assistance"},
                {"silent", "Silent"},
                {"silent +", "Silent +"},
            }),
            makeGuiNumberItem("FOV", "Aim Fov", 0, 180, 1, false),
            makeGuiNumberItem("Projectile FOV", "Projectile Aim Fov", 0, 180, 1, false),
            makeGuiEnumItem("Projectile Aimbot", "Projectile Aimbot", {
                {"off", "Off"},
                {"draw", "Draw"},
                {"aim+draw", "Aim+Draw"},
                {"aim", "Aim"},
            }),
            makeGuiEnumItem("Priority", "Priority", {
                {"closest to crosshair", "FOV"},
                {"smallest distance", "Distance"},
                {"lowest health", "Lowest Health"},
                {"highest health", "Highest Health"},
            }),
            makeGuiEnumItem("Position", "Aim Position", {
                {"hit scan", "Hit Scan"},
                {"head", "Head Only"},
                {"body", "Body Only"},
            }),
            makeGuiBoolItem("Auto Shoot", "Auto Shoot"),

            makeGuiBoolItem("Aim At Sentries", {"Sentry", "Aim Sentry"}),
            makeGuiBoolItem("Other Buildings", {"Other Buildings", "Aim Other buildings", "Aim Other Buildings"}),
            makeGuiBoolItem("Aim At Stickies", {"Stickies", "Aim Stickies"}),
            makeGuiBoolItem("Aim At Sentry Buster", {"Sentry Buster", "Aim Sentry Buster"}),
            makeGuiBoolItem("Aim At NPCs", {"NPC", "Aim NPC"}),
            makeNestedItem("Preferences", PREFERENCES_MENU, 3),
        },
    },
    {
        label = "Trigger Bot",
        submenu = {
            makeGuiKeyItem("Key", {"Trigger Key", "trigger key", "Trigger Shoot Key", "Trigger Shoot key", "trigger shoot key"}),

            makeThreeModeLegitRageItem("Auto Backstab", "Auto Backstab"),
            makeGuiNumberItem("Auto Backstab FOV", "Auto Backstab FOV", 20, 100, 1, false),
            makeCompatCycleEnumItem("Disguise after attack", {"Disguise After Attack", "Disguise after attack"}, {
                {id = "none", display = "None", match = {0, "0", "none", "off"}, set = {0, "none", "off"}},
                {id = "last disguise", display = "Last Disguise", match = {1, "1", "last disguise"}, set = {1, "last disguise"}},
                {id = "last target", display = "Last Target", match = {2, "2", "last target"}, set = {2, "last target"}},
                {id = "random", display = "Random", match = {3, "3", "random"}, set = {3, "random"}},
            }),
            makeGuiBoolItem("Ignore Razorback", "Ignore Razorback"),
            makeThreeModeLegitRageItem("Auto Sapper", "Auto Sapper"),
            makeThreeModeLegitRageItem("Auto Detonate Sticky", "Auto Detonate Sticky"),
            makeGuiBoolItem("Auto Detonator", "Auto Detonator"),
            makeThreeModeLegitRageItem("Auto Airblast", "Auto Airblast"),
            makeIgnoreProjectilesItem(),

            makeGuiBoolItem("Auto Vaccinator", "Auto Vaccinator"),
            makeAutoUberchargeModeItem("Auto Ubercharge", "Auto Ubercharge"),
            makeGuiNumberItem("Health Percentage", "Health Percentage", 0, 100, 1, false),
            makeGuiBoolItem("'Activate Uber' Trigger", {"'Activate Uber' Trigger", "'Activate Uber' Voice Trigger"}),

            makeGuiBoolItem("Trigger Shoot", {"Trigger Shoot", "trigger shoot"}),
            makeGuiBoolItem("Trigger Melee", "Trigger Melee"),
            makeGuiEnumItem("Trigger Position", "Trigger Position", {
                {"hit scan", "Hit Scan"},
                {"head", "Head"},
                {"body", "Body"},
            }),
            makeGuiNumberItem("Trigger Shoot Delay (ms)", {"Trigger Shoot Delay (MS)", "Trigger Shoot Delay (ms)"}, 0, 500, 1, false),
            makeGuiBoolItem("SNIPER: Shoot thru teammates", {"Sniper: Shoot Thru Teammates", "SNIPER: Shoot thru teammates"}),
        },
    },
    {
        label = "Accuracy",
        submenu = {
            makeGuiBoolItem("No Spread", {"NoSpread", "No Spread"}),
            makeGuiBoolItem("No Recoil", {"NoRecoil", "No Recoil"}),
            makeGuiBoolItem("Resolver", {"Aim Resolver", "aim resolver"}),

            makeGuiBoolItem("No Push", {"No Push", "no push"}),

            makeGuiBoolItem("Anti-Taunting", {
                "Anti-Taunting",
                "Anti Taunting",
                "anti-taunting",
                "anti taunting"
            }),
            makeGuiBoolItem("Anti-Disguise", {
                "Anti-Disguise",
                "Anti Disguise",
                "Anti-Disquise",
                "Anti Disquise",
                "anti-disguise",
                "anti disguise"
            }),

            makeGuiBoolItem("No Zoom", {"No Zoom", "no zoom"}),
            makeGuiBoolItem("No Scope", {"No Scope", "no scope"}),
            makeGuiBoolItem("No Hands", {"No Hands", "no hands"}),

            makeAimFovRangeTransparencyItem(),

            makeCustomFovItem(),
            makeCustomVmFovItem(),
        },
    },
    {
        label = "Crit Hack",
        submenu = {
            makeCritModeItem("Crit Hack", {"Crit Hack"}),
            makeCritModeItem("Melee Crit Hack", {"Melee Crit Hack", "Melee Crits"}),
            makeGuiKeyItem("Key", {"Crit Hack Key", "Crit Key"}),
            makeStateToggleItem("Enable Icon", "critIconEnabled"),
            makeCritIconScaleItem(),
        },
    },
    {
        label = "Fake Lag",
        submenu = {
            makeGuiBoolItem("Enabled", {"Fake Lag", "fake lag"}),
            makeFakeLagValueItem(),
            makeGuiBoolItem("Dynamic Fake Lag", {"Dynamic Fake Lag", "dynamic fake lag"}),
            makeGuiKeyItem("Key", {"Fake Lag Key", "fake lag key"}),
        },
    },
    {
        label = "ESP",
        submenu = {
            makeEspMasterEnableItem(),

            makeNestedItem("Glow", ESP_GLOW_MENU, 3),
            makeNestedItem("Chams", ESP_CHAMS_MENU, 3),

            makeGuiBoolItem("AAA Indicator", {
                "Anti Aim Indicator",
                "Anti-Aim Indicator",
            }),

            makeSharedEspBoolItem(
                "Enemy Only",
                {"Enemy Only"},
                {"Buildings Enemy Only", "Building Enemy Only", "Enemy Only"}
            ),
            makeGuiBoolItem("Visible Only", {"Visible Only"}),
            makeGuiBoolItem("Friends", {"Friends"}),
            makeGuiBoolItem("Lobby Members", {"Lobby Members"}),
            makeGuiBoolItem("Name", {"Name"}),
            makeGuiBoolItem("Steam", {"Steam"}),

            makeSharedEspEnumItem(
                "Health",
                {"Health"},
                {"Buildings Health", "Building Health", "Health"},
                {
                    {id = "none",  display = "None",  match = {0, "0", "none"},  set = {0, "none"}},
                    {id = "value", display = "Value", match = {1, "1", "value"}, set = {1, "value"}},
                    {id = "bar",   display = "Bar",   match = {2, "2", "bar"},   set = {2, "bar"}},
                    {id = "both",  display = "Both",  match = {3, "3", "both"},  set = {3, "both"}},
                }
            ),

            makeCompatCycleEnumItem("Weapon", {"Weapon"}, {
                {id = "none", display = "None", match = {0, "0", "none"}, set = {0}},
                {id = "text", display = "Text", match = {1, "1", "text"}, set = {1}},
                {id = "icon", display = "Icon", match = {2, "2", "icon"}, set = {2}},
            }),

            makeGuiBoolItem("UberCharge", {"Ubercharge", "UberCharge"}),
            makeGuiBoolItem("Distance", {"Distance"}),

            makeCompatCycleEnumItem("Class", {"Class"}, {
                {id = "none", display = "None", match = {0, "0", "none"}, set = {0}},
                {id = "text", display = "Text", match = {1, "1", "text"}, set = {1}},
                {id = "icon", display = "Icon", match = {2, "2", "icon"}, set = {2}},
            }),

            makeGuiBoolItem("Conditions", {"Conditions"}),

            makeSharedEspEnumItem(
                "Box",
                {"Box"},
                {"Buildings Box", "Building Box", "Box"},
                {
                    {id = "none",        display = "None",        match = {0, "0", "none"}, set = {0, "none"}},
                    {id = "solid",       display = "Solid",       match = {1, "1", "solid"}, set = {1, "solid"}},
                    {id = "outlined",    display = "Outlined",    match = {2, "2", "outlined"}, set = {2, "outlined"}},
                    {id = "3d",          display = "3D",          match = {3, "3", "3d"}, set = {3, "3d"}},
                    {id = "corner",      display = "Corner",      match = {4, "4", "corner"}, set = {4, "corner"}},
                    {id = "bold",        display = "Bold",        match = {5, "5", "bold"}, set = {5, "bold"}},
                    {id = "corner bold", display = "Corner Bold", match = {6, "6", "corner bold"}, set = {6, "corner bold"}},
                }
            ),

            makeCompatCycleEnumItem("View Angles", {"View Angles"}, {
                {id = "none",    display = "None",    match = {0, "0", "none"}, set = {0}},
                {id = "snipers", display = "Snipers", match = {1, "1", "snipers"}, set = {1}},
                {id = "all",     display = "All",     match = {2, "2", "all"}, set = {2}},
            }),

            makeCompatCycleEnumItem("Skeleton", {"Skeleton"}, {
                {id = "none",   display = "None",   match = {0, "0", "none"},   set = {0, "none"}},
                {id = "white",  display = "White",  match = {1, "1", "white"},  set = {1, "white"}},
                {id = "health", display = "Health", match = {2, "2", "health"}, set = {2, "health"}},
                {id = "team",   display = "Team",   match = {3, "3", "team"},   set = {3, "team"}},
            }),

            makeGuiBoolItem("Local Player", {"Local Player"}),

            makeCompatCycleEnumItem("Offscreen Arrows", {"OffScreen Arrows", "Offscreen Arrows"}, {
                {id = "none",  display = "None",  match = {0, "0", "none"},  set = {0, "none"}},
                {id = "white", display = "White", match = {1, "1", "white"}, set = {1, "white"}},
                {id = "team",  display = "Team",  match = {2, "2", "team"},  set = {2, "team"}},
            }),

            makeNestedItem("Misc", ESP_MISC_MENU, 3),
        },
    },
    {
        label = "Radar",
        submenu = {
            makeStateToggleItem("Enabled", "radarEnabled"),
            makeStateToggleItem("Enemy Only", "radarEnemyOnly"),
            makeSharedCycleItem("Icon Style", "radarIconStyle", {
                {value = 1, display = "1"},
                {value = 2, display = "2"},
            }),
            makeSharedCycleItem("Shape", "radarShape", {
                {value = 0, display = "Square"},
                {value = 1, display = "Circular"},
            }),
            makeSharedNumberItem(
                "Icon Size",
                "radarIconSize",
                6, 24, 1,
                true,
                nil
            ),
            makeSharedNumberItem(
                "Zoom",
                "radarZoom",
                0.1, 10.0, 0.1,
                true,
                1
            ),

            makeSharedNumberItem(
                "Scale",
                "radarScale",
                100, 1000, 50,
                true,
                nil
            ),
            makeStateToggleItem("Healthbar", "radarHealthbar"),
            makeStateToggleItem("Health Kits", "radarHealthkits"),
            makeStateToggleItem("Ammo Boxes", "radarAmmoBoxes"),
            makeStateToggleItem("Dropped Weapons", "radarDroppedWeapons"),
        },
    },
    {
        label = "Bunny Hop",
        submenu = {
            makeGuiBoolItem("Enabled", {"Bunny Hop", "Bunny hop"}),
            makeGuiNumberItem("Bunny Hop Limit", {"Bunny Hop Limit", "Bunny hop limit"}, 0, 10, 1, true),
            makeCompatCycleEnumItem("Auto Strafe", {"Auto Strafe", "Auto strafe"}, {
                {id = "none", display = "None", match = {0, "0", "none", "off"}, set = {0, "none", "off"}},
                {id = "legit", display = "Legit", match = {1, "1", "legit"}, set = {1, "legit"}},
                {id = "directional", display = "Directional", match = {2, "2", "directional"}, set = {2, "directional"}},
            }),
            makeGuiBoolItem("Rocket Jump", {"Rocket Jump", "Rocket jump"}),
            makeGuiBoolItem("Duck Jump", {"Duck Jump", "Duck jump"}),
            makeGuiBoolItem("Edge Jump", {"Edge Jump", "Edge jump"}),
        },
    },
    {
        label = "Anti-/Anti-Aim",
        submenu = {
            makeGuiBoolItem("Enabled", {"Anti Aim", "anti aim"}),
            makeGuiKeyItem("Key", {"Anti Aim Key", "anti aim key"}),
            makeGuiEnumItem("Mode", {"Anti Aim Key Mode", "anti aim key mode"}, {
                {"hold-to-use", "Hold-To-Use"},
                {"press-to-toggle", "Press-To-Toggle"},
            }),

            makeCompatCycleEnumItem("Pitch", {
                "Anti Aim - Pitch",
                "Anti Aim Pitch",
            }, {
                {id = "none",        display = "None",        match = {0, "0", "none"},        set = {0, "none"}},
                {id = "up",          display = "Up",          match = {1, "1", "up"},          set = {1, "up"}},
                {id = "fake up",     display = "Fake Up",     match = {2, "2", "fake up"},     set = {2, "fake up"}},
                {id = "down",        display = "Down",        match = {3, "3", "down"},        set = {3, "down"}},
                {id = "fake down",   display = "Fake Down",   match = {4, "4", "fake down"},   set = {4, "fake down"}},
                {id = "fake center", display = "Fake Center", match = {5, "5", "fake center"}, set = {5, "fake center"}},
                {id = "random",      display = "Random",      match = {6, "6", "random"},      set = {6, "random"}},
                {id = "custom",      display = "Custom",      match = {7, "7", "custom"},      set = {7, "custom"}},
            }),

            makeWrappedAngleItem(
                "Custom Pitch (Real)",
                {"Anti Aim - Custom Pitch (Real)", "Anti Aim Custom Pitch (Real)"},
                360
            ),

            makeCompatCycleEnumItem("Yaw (Real)", {
                "Anti Aim - Yaw (Real)",
                "Anti Aim Yaw (Real)",
            }, {
                {id = "none",       display = "None",       match = {0, "0", "none"},       set = {0, "none"}},
                {id = "left",       display = "Left",       match = {1, "1", "left"},       set = {1, "left"}},
                {id = "right",      display = "Right",      match = {2, "2", "right"},      set = {2, "right"}},
                {id = "back",       display = "Back",       match = {3, "3", "back"},       set = {3, "back"}},
                {id = "spin left",  display = "Spin Left",  match = {4, "4", "spin left"},  set = {4, "spin left"}},
                {id = "spin right", display = "Spin Right", match = {5, "5", "spin right"}, set = {5, "spin right"}},
                {id = "jitter",     display = "Jitter",     match = {6, "6", "jitter"},     set = {6, "jitter"}},
                {id = "forward",    display = "Forward",    match = {7, "7", "forward"},    set = {7, "forward"}},
                {id = "custom",     display = "Custom",     match = {8, "8", "custom"},     set = {8, "custom"}},
            }),

            makeWrappedAngleItem(
                "Custom Yaw (Real)",
                {"Anti Aim - Custom Yaw (Real)", "Anti Aim Custom Yaw (Real)"},
                180
            ),

            makeCompatCycleEnumItem("Yaw (Fake)", {
                "Anti Aim - Yaw (Fake)",
                "Anti Aim Yaw (Fake)",
            }, {
                {id = "none",       display = "None",       match = {0, "0", "none"},       set = {0, "none"}},
                {id = "left",       display = "Left",       match = {1, "1", "left"},       set = {1, "left"}},
                {id = "right",      display = "Right",      match = {2, "2", "right"},      set = {2, "right"}},
                {id = "back",       display = "Back",       match = {3, "3", "back"},       set = {3, "back"}},
                {id = "spin left",  display = "Spin Left",  match = {4, "4", "spin left"},  set = {4, "spin left"}},
                {id = "spin right", display = "Spin Right", match = {5, "5", "spin right"}, set = {5, "spin right"}},
                {id = "jitter",     display = "Jitter",     match = {6, "6", "jitter"},     set = {6, "jitter"}},
                {id = "forward",    display = "Forward",    match = {7, "7", "forward"},    set = {7, "forward"}},
                {id = "custom",     display = "Custom",     match = {8, "8", "custom"},     set = {8, "custom"}},
            }),

            makeWrappedAngleItem(
                "Custom Yaw (Fake)",
                {"Anti Aim - Custom Yaw (Fake)", "Anti Aim Custom Yaw (Fake)"},
                180
            ),

            makeGuiBoolItem("Edge Detection", {
                "Edge Detection",
                "Anti Aim - Edge Detection",
            }),

            makeGuiNumberItem(
                "Spin Speed",
                {"Spin Speed", "Anti Aim - Spin Speed"},
                1, 10, 1, true
            ),
        },
    },
    {
        label = "Misc",
        submenu = {
            makeOff100Item("Night Mode", "Night Mode"),

            makeGuiBoolItem("Anti Backstab", {
                "Anti Backstab",
                "Anti-Backstab",
            }),

            makeGuiBoolItem("Duck Speed", {
                "Duck Speed",
            }),

            makeGuiBoolItem("Far ESP", {
                "Far ESP",
                "FarESP",
            }),

            makeGuiBoolItem("Bypass sv_pure", {
                "Bypass sv_pure",
                "BYPASS SV_PURE",
                "Bypass SV_PURE",
            }),

            makeGuiBoolItem("Bypass SMAC", {
                "Bypass SMAC",
                "BYPASS SMAC",
            }),

            makeGuiBoolItem("Anti-OBS", {
                "Anti-OBS",
                "ANTI-OBS",
                "Anti OBS",
            }),

            makeGuiBoolItem("Clean Screenshots", {
                "Clean Screenshots",
                "CLEAN SCREENSHOTS",
            }),

            makeGuiBoolItem("Anonymous Mode", {
                "Anonymous Mode",
                "ANONYMOUS MODE",
            }),

            makeCompatCycleEnumItem("Region Selector", {
                "Region Selector",
                "REGION SELECTOR",
            }, {
                {id = "none",          display = "None",          match = {0, "0", "none"},          set = {0, "none"}},
                {id = "europe",        display = "Europe",        match = {1, "1", "europe"},        set = {1, "europe"}},
                {id = "north america", display = "North America", match = {2, "2", "north america"}, set = {2, "north america"}},
                {id = "south america", display = "South America", match = {3, "3", "south america"}, set = {3, "south america"}},
                {id = "asia",          display = "Asia",          match = {4, "4", "asia"},          set = {4, "asia"}},
                {id = "oceania",       display = "Oceania",       match = {5, "5", "oceania"},       set = {5, "oceania"}},
                {id = "africa",        display = "Africa",        match = {6, "6", "africa"},        set = {6, "africa"}},
                {id = "world",         display = "World",         match = {7, "7", "world"},         set = {7, "world"}},
            }),

            makeGuiBoolItem("Display Spectator List", {
                "Display Spectator List",
                "DISPLAY SPECTATOR LIST",
            }),

            makeGuiBoolItem("Noisemaker Spam", {
                "Noisemaker Spam",
                "NOISEMAKER SPAM",
            }),

            makeCompatCycleEnumItem("Voicemenu Spam", {
                "Voicemenu Spam",
                "VOICEMENU SPAM",
            }, {
                {id = "none",   display = "None",   match = {0, "0", "none"},   set = {0, "none"}},
                {id = "medic",  display = "Medic",  match = {1, "1", "medic"},  set = {1, "medic"}},
                {id = "random", display = "Random", match = {2, "2", "random"}, set = {2, "random"}},
                {id = "cheers", display = "Cheers", match = {3, "3", "cheers"}, set = {3, "cheers"}},
            }),

            makePingReducerItem(),

            makeGuiBoolItem("Anti-Autobalance", {
                "Anti-Autobalance",
                "ANTI-AUTOBALANCE",
                "Anti Autobalance",
            }),

            makeGuiBoolItem("Auto-Accept Item Drops", {
                "Auto-Accept Item Drops",
                "AUTO-ACCEPT ITEM DROPS",
                "Auto Accept Item Drops",
            }),

            makeGuiBoolItem("Comp. Settings Unlock", {
                "Comp. Settings Unlock",
                "COMP. SETTINGS UNLOCK",
                "Comp Settings Unlock",
            }),

            makeGuiBoolItem("Conga Sliding", {
                "Conga Sliding",
                "CONGA SLIDING",
            }),

            makeGuiBoolItem("Hide MOTD", {
                "Hide MOTD",
                "HIDE MOTD",
            }),
        },
    },
    {
        label = "Info Panel",
        kind = "main_toggle",
        get = function()
            localState.infoPanelEnabled = _G.NC_COMBINED_STATE.infoPanelEnabled ~= false
            return localState.infoPanelEnabled
        end,
        set = function(value)
            localState.infoPanelEnabled = value and true or false
            _G.NC_COMBINED_STATE.infoPanelEnabled = localState.infoPanelEnabled
        end,
    },
    {
        label = "Cheat Settings",
        submenu = CHEAT_SETTINGS_MENU,
    },
}

local menu = {
    open = false,
    level = 1,
    mainIndex = 1,
    subIndex = 1,
    nestedIndex = 1,
    deepIndex = 1,
    captureItem = nil,
    captureWaitRelease = false,
    captureWaitMouseRelease = false,
}

local keyState = {}

local function pressed(key, firstDelay, repeatDelay)
    local now = realTime()
    local state = keyState[key]
    local down = isButtonDown(key)

    if not state then
        state = {down = false, next = 0}
        keyState[key] = state
    end

    if down then
        if not state.down then
            state.down = true
            state.next = now + (firstDelay or 0.20)
            return true
        end

        if now >= state.next then
            state.next = now + (repeatDelay or 0.10)
            return true
        end
    else
        state.down = false
        state.next = 0
    end

    return false
end

local function getCurrentMain()
    return MAIN_MENU[menu.mainIndex]
end

local function getCurrentSubmenu()
    local main = getCurrentMain()
    return main and main.submenu or nil
end

local function getCurrentNestedMenu()
    local submenu = getCurrentSubmenu()
    local item = submenu and submenu[menu.subIndex] or nil
    return item and item.kind == "submenu" and item.submenu or nil
end

local function getCurrentDeepMenu()
    local nested = getCurrentNestedMenu()
    local item = nested and nested[menu.nestedIndex] or nil
    return item and item.kind == "submenu" and item.submenu or nil
end

local function getCurrentDeepTitle()
    local nested = getCurrentNestedMenu()
    local item = nested and nested[menu.nestedIndex] or nil
    return (item and item.label) or "Menu"
end

local BUTTON_CODE_NAMES = {
    [0] = "NONE",
    [37] = "NUM0", [38] = "NUM1", [39] = "NUM2", [40] = "NUM3", [41] = "NUM4",
    [42] = "NUM5", [43] = "NUM6", [44] = "NUM7", [45] = "NUM8", [46] = "NUM9",
    [47] = "NUM/", [48] = "NUM*", [49] = "NUM-", [50] = "NUM+", [51] = "NUMENTER", [52] = "NUM.",
    [53] = "[", [54] = "]", [55] = ";", [56] = "'", [57] = "`", [58] = ",", [59] = ".",
    [60] = "/", [61] = "\\", [62] = "-", [63] = "=",
    [64] = "ENTER", [65] = "SPACE", [66] = "BACKSPACE", [67] = "TAB",
    [68] = "CAPSLOCK", [69] = "NUMLOCK", [70] = "ESC", [71] = "SCROLLLOCK",
    [72] = "INSERT", [73] = "DELETE", [74] = "HOME", [75] = "END",
    [76] = "PGUP", [77] = "PGDN", [78] = "PAUSE",
    [79] = "SHIFT", [80] = "RSHIFT", [81] = "ALT", [82] = "RALT",
    [83] = "CTRL", [84] = "RCTRL", [85] = "WIN", [86] = "RWIN", [87] = "APP",
    [88] = "UP", [89] = "LEFT", [90] = "DOWN", [91] = "RIGHT",
    [92] = "F1", [93] = "F2", [94] = "F3", [95] = "F4", [96] = "F5", [97] = "F6",
    [98] = "F7", [99] = "F8", [100] = "F9", [101] = "F10", [102] = "F11", [103] = "F12",
    [104] = "CAPSLOCK TOGGLE", [105] = "NUMLOCK TOGGLE", [106] = "SCROLLLOCK TOGGLE",
    [107] = "MOUSE1", [108] = "MOUSE2", [109] = "MOUSE3", [110] = "MOUSE4", [111] = "MOUSE5",
    [112] = "MWHEELUP", [113] = "MWHEELDOWN",
}

local function keyCodeToString(key)
    if type_(key) == "string" then
        local numeric = tonumber(key)
        if numeric == nil then
            if key == "" then return "NONE" end
            return string.upper(key)
        end
        key = numeric
    else
        key = tonumber(key) or 0
    end

    if key == 0 then return "NONE" end

    if key >= 1 and key <= 10 then
        return tostring_(key - 1)
    end

    if key >= 11 and key <= 36 then
        return string.char(string.byte("A") + (key - 11))
    end

    return BUTTON_CODE_NAMES[key] or ("KEY " .. tostring_(key))
end

local function enumText(item, value)
    local values = item.values or {}
    local valueLower = type_(value) == "string" and string.lower(value) or nil

    for i = 1, #values do
        local raw = values[i][1]
        if raw == value then
            return values[i][2]
        end
        if valueLower and type_(raw) == "string" and string.lower(raw) == valueLower then
            return values[i][2]
        end
    end

    if value == nil then return "?" end
    return tostring_(value)
end

local function getItemValue(item, now)
    if menu.captureItem == item then
        if item._displayText ~= "[press key]" then
            item._displayRaw = nil
            item._displayText = "[press key]"
            item._displayWidth = nil
        end
        return "[press key]"
    end

    if item.kind == "submenu" then
        return ""
    end

    if item.kind == "config_selector" then
        local value = item.pending or "Default"
        if item._displayRaw == value and item._displayText ~= nil then
            return item._displayText
        end
        item._displayRaw = value
        item._displayText = value
        item._displayWidth = nil
        return value
    end

    local value = item.get and item.get(now) or nil

    if item._displayRaw == value and item._displayText ~= nil then
        return item._displayText
    end

    local display = ""
    if item.kind == "toggle" then
        display = getBool(value) and "ON" or "OFF"
    elseif item.kind == "enum" then
        display = enumText(item, value)
    elseif item.kind == "shared_enum" then
        display = tostring_(value or "")
    elseif item.kind == "number" then
        local numberValue = tonumber(value) or 0
        local isAimFov = item.label == "FOV" or item.label == "Projectile FOV"
        if isAimFov and numberValue >= 180 then
            display = "Unlimited"
        elseif item.pingReducerCombined and numberValue <= 0 then
            display = "OFF"
        elseif item.offAtZero and numberValue == 0 then
            display = "OFF"
        else
            local suffix = item.displaySuffix or ""
            if item.displayDecimals ~= nil then
                display = string.format(
                    "%." .. tostring_(item.displayDecimals) .. "f",
                    numberValue
                ) .. suffix
            elseif numberValue == mathFloor(numberValue) then
                display = tostring_(mathFloor(numberValue)) .. suffix
            else
                display = string.format("%.3f", numberValue) .. suffix
            end
        end
    elseif item.kind == "key" then
        display = keyCodeToString(value)
    elseif item.kind == "action" then
        display = ">"
    end

    item._displayRaw = value
    item._displayText = display
    item._displayWidth = nil
    return display
end

local function cycleEnum(item, dir, now)
    local values = item.values or {}
    if #values == 0 then return end

    local current = item.get and item.get(now) or nil
    local currentLower = type_(current) == "string" and string.lower(current) or nil
    local index = 1

    for i = 1, #values do
        local raw = values[i][1]
        if raw == current or (currentLower and type_(raw) == "string" and string.lower(raw) == currentLower) then
            index = i
            break
        end
    end

    index = index + dir
    if index < 1 then index = #values end
    if index > #values then index = 1 end

    if item.set then item.set(values[index][1]) end
end

local function adjustNumber(item, dir, now)
    local value = tonumber(item.get and item.get(now) or 0) or 0
    local step = item.step or 1

    local isFakeLatency = item.label == "Fake Latency Value (ms)"
    local isBacktrackTicks = item.label == "BackTrack Size (Ticks)"
    local isAutoBackstabFov = item.label == "Auto Backstab FOV"
    local isMinimalPriority = item.label == "Minimal priority"
    local isSpreadMaxDistance = item.label == "Spread: Max Distance"
    local isBunnyHopLimit = item.label == "Bunny Hop Limit"
    local isAimFov = item.label == "FOV" or item.label == "Projectile FOV"
    local isFakeLagValue = item.label == "Fake Lag Value (ms)"
    if isFakeLatency and value > 0 and value <= 2 then
        step = 0.010
        item.min = 0
        item.max = 1.000
    elseif isFakeLatency then
        item.min = 0
        item.max = 1000
        step = 10
    end

    local shiftDown = false
    if KEY_LSHIFT and isButtonDown(KEY_LSHIFT) then
        shiftDown = true
    elseif KEY_RSHIFT and isButtonDown(KEY_RSHIFT) then
        shiftDown = true
    elseif KEY_SHIFT and isButtonDown(KEY_SHIFT) then
        shiftDown = true
    elseif isButtonDown(79) or isButtonDown(80) then
        shiftDown = true
    end

    if shiftDown then
        step = step * 5
    end

    if item.aimFovRangeTransparency then
        local steps = math.max(
            1,
            math.floor(math.abs(step) + 0.5)
        )

        for _ = 1, steps do
            if dir > 0 then
                if value <= 0 then
                    value = 100
                elseif value <= 1 then
                    value = 0
                else
                    value = value - 1
                end
            else
                if value <= 0 then
                    value = 1
                elseif value >= 100 then
                    value = 0
                else
                    value = value + 1
                end
            end
        end

        if item.set then
            item.set(value)
        end
        return
    end

    if item.pingReducerCombined then
        local steps = math.max(1, math.floor(math.abs(step / 5) + 0.5))

        for _ = 1, steps do
            if dir > 0 then
                if value <= 0 then
                    value = 5
                elseif value >= 200 then
                    value = 0
                else
                    value = value + 5
                    if value > 200 then value = 0 end
                end
            else
                if value <= 0 then
                    value = 200
                elseif value <= 5 then
                    value = 0
                else
                    value = value - 5
                    if value < 5 then value = 0 end
                end
            end
        end

        if item.set then item.set(value) end
        return
    end

    if item.angleWrapMax then
        local maxAbs = item.angleWrapMax
        local steps = math.max(1, math.floor(math.abs(step) + 0.5))

        for _ = 1, steps do
            if dir > 0 then
                if value == 0 then
                    value = 1
                elseif value >= 1 and value < maxAbs then
                    value = value + 1
                elseif value == maxAbs then
                    value = -maxAbs
                elseif value < -1 then
                    value = value + 1
                else
                    value = 0
                end
            else
                if value == 0 then
                    value = -1
                elseif value <= -1 and value > -maxAbs then
                    value = value - 1
                elseif value == -maxAbs then
                    value = maxAbs
                elseif value > 1 then
                    value = value - 1
                else
                    value = 0
                end
            end
        end

        if item.set then item.set(value) end
        return
    end

    value = value + (step * dir)

    if isAimFov then
        item.min = 1
        item.max = 180
        if value > item.max then
            value = item.min
        elseif value < item.min then
            value = item.max
        end
    elseif isFakeLagValue then
        item.min = 30
        item.max = 330
        if value > item.max then
            value = item.min
        elseif value < item.min then
            value = item.max
        end
    elseif isFakeLatency or isBacktrackTicks or isAutoBackstabFov or isMinimalPriority or isSpreadMaxDistance or isBunnyHopLimit then
        if value > item.max then
            value = item.min
        elseif value < item.min then
            value = item.max
        end
    elseif item.wrap then
        if value > item.max then
            value = item.min
        elseif value < item.min then
            value = item.max
        end
    else
        if item.min and value < item.min then value = item.min end
        if item.max and value > item.max then value = item.max end
    end

    if item.set then item.set(value) end
end

local function activateItem(item, now)
    if not item then return end

    if item.kind == "toggle" then
        local value = item.get and item.get(now) or false
        if item.set then item.set(not getBool(value)) end
    elseif item.kind == "enum" then
        cycleEnum(item, 1, now)
    elseif item.kind == "shared_enum" then
        if item.cycle then item.cycle(1) end
    elseif item.kind == "number" then
        adjustNumber(item, 1, now)
    elseif item.kind == "key" then
        menu.captureItem = item
        menu.captureWaitRelease = true
    elseif item.kind == "action" then
        if item.activate then item.activate() end
    elseif item.kind == "submenu" then
        local targetLevel = item.targetLevel or 3

        menu.level = targetLevel
        if targetLevel == 3 then
            menu.nestedIndex = 1
        elseif targetLevel == 4 then
            menu.deepIndex = 1
        end
    end
end

local function capturePressedKey()
    if not menu.captureItem then return false end

    if menu.captureWaitMouseRelease then
        local mouseCode =
            (E_ButtonCode and E_ButtonCode.MOUSE_LEFT) or MOUSE_LEFT

        if mouseCode and isButtonDown(mouseCode) then
            return true
        end

        menu.captureWaitMouseRelease = false
    end

    if pressed(VK.ESCAPE, 0.20, 0.10) then
        if menu.captureItem.set then
            menu.captureItem.set(0)
        end
        menu.captureItem = nil
        menu.captureWaitRelease = false
        return true
    end

    if menu.captureWaitRelease then
        if isButtonDown(VK.RETURN) or isButtonDown(VK.RIGHT) or isButtonDown(VK.LEFT) then
            return true
        end
        menu.captureWaitRelease = false
    end

    for key = 1, 255 do
        if key ~= VK.ESCAPE and isButtonDown(key) then
            if menu.captureItem.set then
                menu.captureItem.set(key)
            end
            menu.captureItem = nil
            menu.captureWaitRelease = false
            menu.captureWaitMouseRelease = false
            return true
        end
    end

    return true
end

local function wrapIndex(index, count)
    if count <= 0 then return 1 end
    if index < 1 then return count end
    if index > count then return 1 end
    return index
end

local function closeOneLevel()
    resetActionConfirm()

    if menu.level == 4 then
        menu.level = 3
    elseif menu.level == 3 then
        menu.level = 2
    elseif menu.level == 2 then
        menu.level = 1
    else
        menu.open = false
        resetActionConfirm()
    end
end

local function handleInput()
    if pressed(VK.INSERT, 0.25, 0.25) then
        menu.open = not menu.open
        if not menu.open then
            menu.level = 1
            menu.captureItem = nil
            menu.captureWaitRelease = false
            resetActionConfirm()
        end
        return
    end

    if not menu.open then return end
    if capturePressedKey() then return end

    if pressed(VK.ESCAPE, 0.20, 0.10) or pressed(VK.BACK, 0.20, 0.10) then
        closeOneLevel()
        return
    end

    if menu.level == 1 then
        if pressed(VK.UP) then
            resetActionConfirm()
            menu.mainIndex = wrapIndex(menu.mainIndex - 1, #MAIN_MENU)
            menu.subIndex = 1
            return
        end

        if pressed(VK.DOWN) then
            resetActionConfirm()
            menu.mainIndex = wrapIndex(menu.mainIndex + 1, #MAIN_MENU)
            menu.subIndex = 1
            return
        end

        if pressed(VK.RETURN) or pressed(VK.RIGHT) then
            local item = MAIN_MENU[menu.mainIndex]

            if item and item.kind == "main_toggle" then
                local current = item.get and item.get() or false
                if item.set then
                    item.set(not current)
                end
                return
            end

            resetActionConfirm()
            menu.level = 2
            menu.subIndex = 1
            return
        end

        return
    end

    if menu.level == 2 then
        local submenu = getCurrentSubmenu() or {}

        if pressed(VK.LEFT) then
            resetActionConfirm()
            menu.level = 1
            return
        end

        if pressed(VK.UP) then
            resetActionConfirm()
            menu.subIndex = wrapIndex(menu.subIndex - 1, #submenu)
            return
        end

        if pressed(VK.DOWN) then
            resetActionConfirm()
            menu.subIndex = wrapIndex(menu.subIndex + 1, #submenu)
            return
        end

        local item = submenu[menu.subIndex]
        if pressed(VK.RETURN) or pressed(VK.RIGHT) then
            activateItem(item, realTime())
            return
        end

        return
    end

    if menu.level == 3 then
        local nested = getCurrentNestedMenu() or {}
        local item = nested[menu.nestedIndex]

        if pressed(VK.LEFT) then
            resetActionConfirm()
            menu.level = 2
            return
        end

        if item and item.kind == "config_selector" then
            if pressed(VK.UP) then
                cycleConfigSelector(-1)
                return
            end

            if pressed(VK.DOWN) or pressed(VK.RIGHT) then
                cycleConfigSelector(1)
                return
            end

            if pressed(VK.RETURN) then
                applySelectedConfig()
                return
            end

            return
        end

        if pressed(VK.UP) then
            resetActionConfirm()
            menu.nestedIndex = wrapIndex(menu.nestedIndex - 1, #nested)
            return
        end

        if pressed(VK.DOWN) then
            resetActionConfirm()
            menu.nestedIndex = wrapIndex(menu.nestedIndex + 1, #nested)
            return
        end

        if pressed(VK.RETURN) or pressed(VK.RIGHT) then
            activateItem(item, realTime())
            return
        end

        return
    end

    if menu.level == 4 then
        local deep = getCurrentDeepMenu() or {}

        if pressed(VK.LEFT) then
            resetActionConfirm()
            menu.level = 3
            return
        end

        if pressed(VK.UP) then
            resetActionConfirm()
            menu.deepIndex = wrapIndex(menu.deepIndex - 1, #deep)
            return
        end

        if pressed(VK.DOWN) then
            resetActionConfirm()
            menu.deepIndex = wrapIndex(menu.deepIndex + 1, #deep)
            return
        end

        local item = deep[menu.deepIndex]
        if pressed(VK.RETURN) or pressed(VK.RIGHT) then
            activateItem(item, realTime())
            return
        end
    end
end

local function getMenuLayout()
    local sw, sh = draw.GetScreenSize()

    local layout = {
        side = 1,
        mainX = STYLE.x,
        middleX = nil,
        preferencesX = nil,
        deepX = nil,
        minX = STYLE.x,
        maxX = STYLE.x + STYLE.leftW,
        minY = STYLE.y,
        maxY = STYLE.y + STYLE.headerH + (#MAIN_MENU * STYLE.rowH),
    }

    local submenu = nil
    local nested = nil
    local deep = nil

    if menu.level >= 2 and getCurrentSubmenu() then
        submenu = getCurrentSubmenu() or {}
    end
    if menu.level >= 3 and submenu then
        nested = getCurrentNestedMenu() or {}
    end
    if menu.level >= 4 and nested then
        deep = getCurrentDeepMenu() or {}
    end

    local attachedW = 0
    if submenu then attachedW = attachedW + STYLE.rightW end
    if nested then attachedW = attachedW + STYLE.preferencesW end
    if deep then attachedW = attachedW + STYLE.nestedW end

    if attachedW > 0 and (STYLE.x + STYLE.leftW + attachedW > sw) then
        layout.side = -1
    end

    if layout.side == 1 then
        local cursor = STYLE.x + STYLE.leftW

        if submenu then
            layout.middleX = cursor
            cursor = cursor + STYLE.rightW
        end
        if nested then
            layout.preferencesX = cursor
            cursor = cursor + STYLE.preferencesW
        end
        if deep then
            layout.deepX = cursor
            cursor = cursor + STYLE.nestedW
        end

        layout.minX = STYLE.x
        layout.maxX = cursor
    else
        local cursor = STYLE.x

        if submenu then
            cursor = cursor - STYLE.rightW
            layout.middleX = cursor
        end
        if nested then
            cursor = cursor - STYLE.preferencesW
            layout.preferencesX = cursor
        end
        if deep then
            cursor = cursor - STYLE.nestedW
            layout.deepX = cursor
        end

        layout.minX = cursor
        layout.maxX = STYLE.x + STYLE.leftW
    end

    local maxRows = #MAIN_MENU
    if submenu and #submenu > maxRows then maxRows = #submenu end
    if nested and #nested > maxRows then maxRows = #nested end
    if deep and #deep > maxRows then maxRows = #deep end

    layout.minY = STYLE.y
    layout.maxY = STYLE.y + STYLE.headerH + (maxRows * STYLE.rowH)

    return layout
end

local function getVisibleMenuBounds()
    local layout = getMenuLayout()
    return layout.maxX - layout.minX, layout.maxY - layout.minY, layout
end

local function updateMenuDragging()
    if not menu.open then
        if menuDrag.active then
            NC_CONFIG.MENU_X = STYLE.x
            NC_CONFIG.MENU_Y = STYLE.y
            NC_SaveConfig()
        end

        menuDrag.active = false
        menuDrag.wasDown = false
        return
    end

    local mouse = input.GetMousePos()
    if not mouse then return end

    local mx, my = mouse[1], mouse[2]
    local mouseCode = (E_ButtonCode and E_ButtonCode.MOUSE_LEFT) or MOUSE_LEFT
    local down = mouseCode and input.IsButtonDown(mouseCode) or false

    local totalW, totalH, layout = getVisibleMenuBounds()

    local inTitleBar =
        mx >= layout.minX and mx <= layout.maxX
        and my >= STYLE.y and my <= STYLE.y + STYLE.headerH

    if down and not menuDrag.wasDown and inTitleBar then
        menuDrag.active = true
        menuDrag.offsetX = mx - STYLE.x
        menuDrag.offsetY = my - STYLE.y
    end

    if menuDrag.active and down then
        local sw, sh = draw.GetScreenSize()

        local newX = mx - menuDrag.offsetX
        local newY = my - menuDrag.offsetY

        local leftExtra = STYLE.x - layout.minX
        local rightExtra = layout.maxX - (STYLE.x + STYLE.leftW)

        local minMainX = leftExtra
        local maxMainX = sw - STYLE.leftW - rightExtra
        local maxY = sh - totalH

        if maxMainX < minMainX then maxMainX = minMainX end
        if maxY < 0 then maxY = 0 end

        if newX < minMainX then newX = minMainX end
        if newX > maxMainX then newX = maxMainX end
        if newY < 0 then newY = 0 end
        if newY > maxY then newY = maxY end

        STYLE.x = mathFloor(newX)
        STYLE.y = mathFloor(newY)
    end

    if not down then
        if menuDrag.active then
            NC_CONFIG.MENU_X = STYLE.x
            NC_CONFIG.MENU_Y = STYLE.y
            NC_SaveConfig()
        end

        menuDrag.active = false
    end

    menuDrag.wasDown = down
end

local menuMouse = {
    leftWasDown = false,
    rightWasDown = false,
}

local function pointInPanelRow(mx, my, x, y, w, rowCount)
    if not x then return nil end
    if mx < x or mx > x + w then return nil end

    local firstY = y + STYLE.headerH
    local lastY = firstY + rowCount * STYLE.rowH

    if my < firstY or my >= lastY then
        return nil
    end

    local index =
        mathFloor((my - firstY) / STYLE.rowH) + 1

    if index < 1 or index > rowCount then
        return nil
    end

    return index
end

local function resetConfirmForItem(item)
    if not actionConfirm.pending then
        return
    end

    local key = item and item.confirmKey or nil
    if key ~= actionConfirm.pending then
        resetActionConfirm()
    end
end

local function activateItemByMouse(item, direction, now)
    if not item then return end

    direction = direction or 1

    if item.kind == "toggle" then
        local value = item.get and item.get(now) or false
        if item.set then
            item.set(not getBool(value))
        end

    elseif item.kind == "enum" then
        cycleEnum(item, direction, now)

    elseif item.kind == "shared_enum" then
        if item.cycle then
            item.cycle(direction)
        end

    elseif item.kind == "number" then
        adjustNumber(item, direction, now)

    elseif item.kind == "key" then
        menu.captureItem = item
        menu.captureWaitRelease = false
        menu.captureWaitMouseRelease = true

    elseif item.kind == "action" then
        if item.activate then
            item.activate()
        end

    elseif item.kind == "submenu" then
        local targetLevel = item.targetLevel or 3

        menu.level = targetLevel

        if targetLevel == 3 then
            menu.nestedIndex = 1
        elseif targetLevel == 4 then
            menu.deepIndex = 1
        end

    elseif item.kind == "config_selector" then
        cycleConfigSelector(direction)
    end
end

local function handleMenuMouse()
    if not menu.open or menuDrag.active then
        menuMouse.leftWasDown = false
        menuMouse.rightWasDown = false
        return
    end

    if menu.captureItem then
        return
    end

    local mouse = input.GetMousePos()
    if not mouse then return end

    local mx, my = mouse[1], mouse[2]

    local leftCode =
        (E_ButtonCode and E_ButtonCode.MOUSE_LEFT) or MOUSE_LEFT
    local rightCode =
        (E_ButtonCode and E_ButtonCode.MOUSE_RIGHT) or MOUSE_RIGHT

    local leftDown =
        leftCode and input.IsButtonDown(leftCode) or false
    local rightDown =
        rightCode and input.IsButtonDown(rightCode) or false

    local leftPressed =
        leftDown and not menuMouse.leftWasDown
    local rightPressed =
        rightDown and not menuMouse.rightWasDown

    menuMouse.leftWasDown = leftDown
    menuMouse.rightWasDown = rightDown

    if not leftPressed and not rightPressed then
        return
    end

    local direction = rightPressed and -1 or 1
    local now = realTime()
    local layout = getMenuLayout()

    local mainIndex = pointInPanelRow(
        mx, my,
        STYLE.x, STYLE.y,
        STYLE.leftW,
        #MAIN_MENU
    )

    if mainIndex then
        menu.mainIndex = mainIndex
        menu.subIndex = 1
        menu.nestedIndex = 1
        menu.deepIndex = 1

        local item = MAIN_MENU[mainIndex]
        resetConfirmForItem(item)

        if leftPressed then
            if item and item.kind == "main_toggle" then
                local current =
                    item.get and item.get(now) or false

                if item.set then
                    item.set(not current)
                end
            elseif item and item.submenu then
                menu.level = 2
            end
        else
            menu.level = 1
        end

        return
    end

    if menu.level >= 2 then
        local submenu = getCurrentSubmenu() or {}
        local index = pointInPanelRow(
            mx, my,
            layout.middleX, STYLE.y,
            STYLE.rightW,
            #submenu
        )

        if index then
            local clickedItem = submenu[index]
            resetConfirmForItem(clickedItem)

            menu.subIndex = index
            menu.nestedIndex = 1
            menu.deepIndex = 1

            activateItemByMouse(
                clickedItem,
                direction,
                now
            )
            return
        end
    end

    if menu.level >= 3 then
        local nested = getCurrentNestedMenu() or {}
        local index = pointInPanelRow(
            mx, my,
            layout.preferencesX, STYLE.y,
            STYLE.preferencesW,
            #nested
        )

        if index then
            local clickedItem = nested[index]
            resetConfirmForItem(clickedItem)

            menu.nestedIndex = index
            menu.deepIndex = 1

            activateItemByMouse(
                clickedItem,
                direction,
                now
            )
            return
        end
    end

    if menu.level >= 4 then
        local deep = getCurrentDeepMenu() or {}
        local index = pointInPanelRow(
            mx, my,
            layout.deepX, STYLE.y,
            STYLE.nestedW,
            #deep
        )

        if index then
            local clickedItem = deep[index]
            resetConfirmForItem(clickedItem)

            menu.deepIndex = index

            activateItemByMouse(
                clickedItem,
                direction,
                now
            )
            return
        end
    end
end

local function drawPanelFrame(x, y, w, rowCount, title, sharedSide, neighborRowCount)
    local totalH = STYLE.headerH + (rowCount * STYLE.rowH)

    draw.Color(STYLE.bg[1], STYLE.bg[2], STYLE.bg[3], STYLE.bg[4])
    draw.FilledRect(x, y, x + w, y + totalH)

    draw.Color(STYLE.border[1], STYLE.border[2], STYLE.border[3], STYLE.border[4])

    if sharedSide == "left" then
        local seamX = x - 1

        draw.Line(seamX, y, x + w, y)
        draw.Line(x + w, y, x + w, y + totalH)
        draw.Line(seamX, y + totalH, x + w, y + totalH)

        local neighbourH = STYLE.headerH + ((neighborRowCount or 0) * STYLE.rowH)
        if totalH > neighbourH then
            draw.Line(seamX, y + neighbourH, seamX, y + totalH)
        end

        draw.Line(seamX, y + STYLE.headerH, x + w, y + STYLE.headerH)

    elseif sharedSide == "right" then
        local seamX = x + w

        draw.Line(x, y, seamX, y)
        draw.Line(x, y, x, y + totalH)
        draw.Line(x, y + totalH, seamX, y + totalH)

        local neighbourH = STYLE.headerH + ((neighborRowCount or 0) * STYLE.rowH)
        if totalH > neighbourH then
            draw.Line(seamX, y + neighbourH, seamX, y + totalH)
        end

        draw.Line(x, y + STYLE.headerH, seamX, y + STYLE.headerH)

    else
        draw.OutlinedRect(x, y, x + w, y + totalH)
        draw.Line(x, y + STYLE.headerH, x + w, y + STYLE.headerH)
    end

    draw.SetFont(FONT_BOLD)
    local titleW, titleH = draw.GetTextSize(title)
    DrawOutlinedText(
        FONT_BOLD,
        x + mathFloor((w - titleW) / 2),
        y + mathFloor((STYLE.headerH - titleH) / 2),
        STYLE.title[1], STYLE.title[2], STYLE.title[3], STYLE.title[4],
        title
    )
end

local function drawPanelBorderOnly(x, y, w, rowCount, sharedSide, neighborRowCount)
    local totalH = STYLE.headerH + (rowCount * STYLE.rowH)

    draw.Color(STYLE.border[1], STYLE.border[2], STYLE.border[3], STYLE.border[4])

    if sharedSide == "left" then
        local seamX = x - 1

        draw.Line(seamX, y, x + w, y)
        draw.Line(x + w, y, x + w, y + totalH)
        draw.Line(seamX, y + totalH, x + w, y + totalH)

        local neighbourH = STYLE.headerH + ((neighborRowCount or 0) * STYLE.rowH)
        if totalH > neighbourH then
            draw.Line(seamX, y + neighbourH, seamX, y + totalH)
        end

        draw.Line(seamX, y + STYLE.headerH, x + w, y + STYLE.headerH)

    elseif sharedSide == "right" then
        local seamX = x + w

        draw.Line(x, y, seamX, y)
        draw.Line(x, y, x, y + totalH)
        draw.Line(x, y + totalH, seamX, y + totalH)

        local neighbourH = STYLE.headerH + ((neighborRowCount or 0) * STYLE.rowH)
        if totalH > neighbourH then
            draw.Line(seamX, y + neighbourH, seamX, y + totalH)
        end

        draw.Line(x, y + STYLE.headerH, seamX, y + STYLE.headerH)

    else
        draw.OutlinedRect(x, y, x + w, y + totalH)
        draw.Line(x, y + STYLE.headerH, x + w, y + STYLE.headerH)
    end
end

local function drawSelection(x, rowY, w, sharedSide)
    draw.Color(STYLE.selectedFill[1], STYLE.selectedFill[2], STYLE.selectedFill[3], STYLE.selectedFill[4])

    local leftInset = 1
    local rightInset = 1

    if sharedSide == "left" then
        leftInset = 0
    elseif sharedSide == "right" then
        rightInset = 0
    end

    draw.FilledRect(
        x + leftInset,
        rowY + 1,
        x + w - rightInset,
        rowY + STYLE.rowH - 1
    )
end

local function drawRowLine(x, rowY, w, sharedSide)
    draw.Color(STYLE.line[1], STYLE.line[2], STYLE.line[3], STYLE.line[4])

    if sharedSide == "left" then
        draw.Line(x - 1, rowY, x + w, rowY)
    else
        draw.Line(x, rowY, x + w, rowY)
    end
end

local function drawMainPanel(title)
    local x, y, w = STYLE.x, STYLE.y, STYLE.leftW
    drawPanelFrame(x, y, w, #MAIN_MENU, title, nil)

    local rowY = y + STYLE.headerH
    for i = 1, #MAIN_MENU do
        if i == menu.mainIndex then
            drawSelection(x, rowY, w, nil)
        end

        drawRowLine(x, rowY, w, nil)

        local mainItem = MAIN_MENU[i]

        if mainItem.kind == "main_toggle" then
            local enabled = mainItem.get and mainItem.get() or false
            local label = mainItem.label .. ": " .. (enabled and "ON" or "OFF")

            DrawOutlinedText(
                FONT, x + 4, rowY + 3,
                STYLE.text[1], STYLE.text[2], STYLE.text[3], STYLE.text[4],
                label
            )
        else
            local marker = (i == menu.mainIndex and menu.level >= 2) and "[-] " or "[+] "

            DrawOutlinedText(
                FONT, x + 4, rowY + 3,
                STYLE.text[1], STYLE.text[2], STYLE.text[3], STYLE.text[4],
                marker .. mainItem.label
            )
        end

        rowY = rowY + STYLE.rowH
    end

    drawPanelBorderOnly(x, y, w, #MAIN_MENU, nil)
end

local function drawItemsPanel(x, y, w, title, items, selectedIndex, now, neighborRowCount, sharedSide)
    drawPanelFrame(x, y, w, #items, title, sharedSide, neighborRowCount)

    local rowY = y + STYLE.headerH
    for i = 1, #items do
        local item = items[i]
        if i == selectedIndex then
            drawSelection(x, rowY, w, sharedSide)
        end

        drawRowLine(x, rowY, w, sharedSide)

        local label = item.label
        if item.kind == "submenu" then
            local targetLevel = item.targetLevel or 3
            local isOpen = false

            if targetLevel == 3 then
                local currentSubmenu = getCurrentSubmenu()
                local selectedParent =
                    currentSubmenu and currentSubmenu[menu.subIndex] or nil

                isOpen =
                    menu.level >= 3
                    and selectedParent == item

            elseif targetLevel == 4 then
                local currentNested = getCurrentNestedMenu()
                local selectedParent =
                    currentNested and currentNested[menu.nestedIndex] or nil

                isOpen =
                    menu.level >= 4
                    and selectedParent == item
            else
                isOpen = menu.level >= targetLevel
            end

            label = (isOpen and "[-] " or "[+] ") .. label
        end

        if string.sub(label, -1) ~= ":" then
            label = label .. ":"
        end

        DrawOutlinedText(
            FONT, x + 4, rowY + 3,
            STYLE.text[1], STYLE.text[2], STYLE.text[3], STYLE.text[4],
            label
        )

        local value = getItemValue(item, now)
        if value ~= "" then
            draw.SetFont(FONT)

            local valueW = item._displayWidth
            if valueW == nil then
                valueW = draw.GetTextSize(value)
                item._displayWidth = valueW
            end

            local labelW = draw.GetTextSize(label)
            local valueX = x + 4 + labelW + 5
            local maxValueX = x + w - valueW - 6

            if valueX > maxValueX then
                valueX = maxValueX
            end

            DrawOutlinedText(
                FONT, valueX, rowY + 3,
                STYLE.text[1], STYLE.text[2], STYLE.text[3], STYLE.text[4],
                value
            )
        end

        rowY = rowY + STYLE.rowH
    end

    drawPanelBorderOnly(x, y, w, #items, sharedSide, neighborRowCount)
end

local customName = "Not Set"

local function trimText(value)
    value = tostring_(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function stripOuterQuotes(value)
    value = trimText(value)
    if #value >= 2 and string.sub(value, 1, 1) == '"' and string.sub(value, -1) == '"' then
        value = string.sub(value, 2, -2)
    end
    return trimText(value)
end

local function onCustomNameCommand(cmd)
    if not cmd or not cmd.Get then return end

    local ok, raw = pcall_(cmd.Get, cmd)
    if not ok or not raw then return end

    local entered = string.match(raw, "^%s*[Nn][Aa][Mm][Ee]%s+(.+)%s*$")
    if not entered then return end

    entered = stripOuterQuotes(entered)
    if entered == "" then
        customName = "Not Set"
    else
        customName = entered
    end

    if cmd.Set then
        pcall_(cmd.Set, cmd, "echo ")
    end
end

local function drawGameUIInfo()
    if localState.luaEnabled == false then return end

    local gameUIVisible = engine.IsGameUIVisible()
    local consoleVisible = engine.Con_IsVisible and engine.Con_IsVisible()

    if not gameUIVisible and not consoleVisible then return end

    draw.SetFont(GAMEUI_FONT)

    local x = 8
    local y = 8
    local lineH = 14

    DrawGameUIText(x, y, "Premium build, registered to: Lmaobox")
    DrawGameUIText(x, y + lineH, "Version: 13.09,2026")
    DrawGameUIText(x, y + lineH * 2, "Press 'insert' or 'F11' key to open/close cheat menu.")
    DrawGameUIText(x, y + lineH * 3, "Use keyboard arrows or mouse to navigate in menu")

    local customY = y + lineH * 5
    DrawGameUIText(x, customY, "Custom Name:")

    draw.SetFont(GAMEUI_FONT)
    local labelW = draw.GetTextSize("Custom Name:")
    local shownName = customName
    if shownName == "Not Set" then
        shownName = "*Not Set*"
    end

    DrawGameUIText(x + labelW + 6, customY, shownName)
end

local function drawActionConfirmation()
    draw.SetFont(FONT_BOLD)

    local sw, sh = draw.GetScreenSize()

    if menu.open
        and actionConfirm.pending
        and actionConfirm.text then

        local textW, textH =
            draw.GetTextSize(actionConfirm.text)

        local x = mathFloor((sw - textW) / 2)
        local y = mathFloor((sh - textH) / 2)

        DrawOutlinedText(
            FONT_BOLD,
            x,
            y,
            STYLE.title[1],
            STYLE.title[2],
            STYLE.title[3],
            STYLE.title[4],
            actionConfirm.text
        )
    end

    if openedLinkInfo.url
        and realTime() < openedLinkInfo.untilTime then

        local message =
            "Lmaobox Lua cannot open browser URLs. Open manually: "
            .. openedLinkInfo.url

        local textW, textH = draw.GetTextSize(message)
        local x = mathFloor((sw - textW) / 2)
        local y = mathFloor((sh - textH) / 2) + 20

        DrawOutlinedText(
            FONT_BOLD,
            x,
            y,
            STYLE.title[1],
            STYLE.title[2],
            STYLE.title[3],
            STYLE.title[4],
            message
        )
    end
end

local function onDraw()
    handleInput()
    UpdateSkyboxOverride(realTime())

    _G.NC_COMBINED_STATE.luaMenuOpen = menu.open and true or false

    if NC_IsTakingCleanScreenshot() then
        return
    end

    drawGameUIInfo()

    if not menu.open then
        updateMenuDragging()
        return
    end

    updateMenuDragging()
    handleMenuMouse()

    local now = realTime()
    draw.SetFont(FONT)

    if collectgarbage then
        collectgarbage("step", 8)
    end

    local mainTitle = (menu.level == 1) and ">>> Lmaobox <<<" or "Lmaobox"
    drawMainPanel(mainTitle)

    if menu.level >= 2 and getCurrentSubmenu() then
        local layout = getMenuLayout()
        local main = getCurrentMain()
        local submenu = getCurrentSubmenu() or {}
        local middleX = layout.middleX
        local sharedSide = (layout.side == 1) and "left" or "right"
        local middleBaseTitle = (main and main.label or "Menu") .. " Menu"
        local middleTitle = (menu.level == 2) and (">> " .. middleBaseTitle .. " <<") or middleBaseTitle
        drawItemsPanel(middleX, STYLE.y, STYLE.rightW, middleTitle, submenu, menu.subIndex, now, #MAIN_MENU, sharedSide)

        if menu.level >= 3 then
            local nested = getCurrentNestedMenu() or {}
            local preferencesX = layout.preferencesX
            local selectedParent = submenu[menu.subIndex]
            local preferencesBaseTitle =
                (selectedParent and selectedParent.label) or "Preferences"
            local preferencesTitle =
                (menu.level == 3)
                and (">> " .. preferencesBaseTitle .. " <<")
                or preferencesBaseTitle

            drawItemsPanel(
                preferencesX,
                STYLE.y,
                STYLE.preferencesW,
                preferencesTitle,
                nested,
                menu.nestedIndex,
                now,
                #submenu,
                sharedSide
            )

            if menu.level >= 4 then
                local deep = getCurrentDeepMenu() or {}
                local deepX = layout.deepX
                local deepBaseTitle = getCurrentDeepTitle()
                local deepTitle = (menu.level == 4) and (">> " .. deepBaseTitle .. " <<") or deepBaseTitle
                drawItemsPanel(deepX, STYLE.y, STYLE.nestedW, deepTitle, deep, menu.deepIndex, now, #nested, sharedSide)
            end
        end
    end

    drawActionConfirmation()
end

NC_CALLBACKS.menuDraw = onDraw
NC_CALLBACKS.sendStringCmd = onCustomNameCommand
NC_CALLBACKS.restoreFovOnUnload = function()
    restoreRuntimeFovSettings()

    if skyboxState.selected ~= "off" then
        RestoreSkybox()
    end
end

end

do

local config = {
    size = NC_CONFIG.RADAR_SCALE or NC_CONFIG.RADAR_SIZE,
    icon_size = NC_CONFIG.RADAR_ICON_SIZE,
    zoom = NC_CONFIG.RADAR_ZOOM,
    x = NC_CONFIG.RADAR_X,
    y = NC_CONFIG.RADAR_Y,
    enemy_only = NC_CONFIG.RADAR_ENEMY_ONLY ~= 0,
    healthbar = NC_CONFIG.RADAR_HEALTHBAR ~= 0,
    healthkits = NC_CONFIG.RADAR_HEALTHKITS ~= 0,
    ammo_boxes = NC_CONFIG.RADAR_AMMOBOXES ~= 0,
    dropped_weapons = NC_CONFIG.RADAR_DROPPEDWEAPONS ~= 0,
    icon_style = NC_CONFIG.RADAR_ICON_STYLE,
    radar_shape = NC_CONFIG.RADAR_SHAPE,

    background_alpha = NC_CONFIG.RADAR_BACKGROUND_ALPHA,
    center_box_padding = NC_CONFIG.RADAR_CENTER_PADDING,
    center_bg_alpha = NC_CONFIG.RADAR_CENTER_BG_ALPHA,

    stale_time = 0.12,

    material_retry = 2.00,
}

local colors = {
    bg = {16, 16, 20},
    border = {62, 130, 115, 255},
    cross_normal = {62, 130, 115, 180},
    cross_active = {255, 105, 180, 220},

    red_team = {255, 64, 64, 255},
    blue_team = {202, 255, 255, 255},
    aimbot_target = {255, 105, 180, 255},
}

local radarGuiColors = {
    nextUpdate = 0,
    red = colors.red_team,
    blue = colors.blue_team,
    target = colors.aimbot_target,
}

local function unpackGuiColor(value, fallback)
    value = tonumber(value)
    if not value then
        return fallback
    end

    if value < 0 then
        value = value + 4294967296
    end

    value = math.floor(value) % 4294967296

    local r = math.floor(value / 16777216) % 256
    local g = math.floor(value / 65536) % 256
    local b = math.floor(value / 256) % 256
    local a = value % 256

    return {r, g, b, a}
end

local function updateRadarGuiColors(now)
    if now < radarGuiColors.nextUpdate then
        return
    end

    radarGuiColors.nextUpdate = now + 0.20

    local okRed, redValue = pcall(function()
        return gui.GetValue("Red Team Color")
    end)
    if okRed and redValue ~= nil then
        radarGuiColors.red =
            unpackGuiColor(redValue, colors.red_team)
    end

    local okBlue, blueValue = pcall(function()
        return gui.GetValue("Blue Team Color")
    end)
    if okBlue and blueValue ~= nil then
        radarGuiColors.blue =
            unpackGuiColor(blueValue, colors.blue_team)
    end

    local okTarget, targetValue = pcall(function()
        return gui.GetValue("Aimbot Target Color")
    end)
    if okTarget and targetValue ~= nil then
        radarGuiColors.target =
            unpackGuiColor(targetValue, colors.aimbot_target)
    end
end

local function getRadarTeamColor(team)
    if team == 2 then
        return radarGuiColors.red
    end

    if team == 3 then
        return radarGuiColors.blue
    end

    return colors.border
end

local targetState = {nextUpdate = 0, index = nil}

local function getAimbotTargetIndex(now)
    if now < targetState.nextUpdate then
        return targetState.index
    end

    targetState.nextUpdate = now + 0.05
    targetState.index = nil

    if not aimbot then return nil end

    local ok, target = pcall(function()
        if aimbot.GetAimbotTarget then
            return aimbot.GetAimbotTarget()
        end
        if aimbot.GetTarget then
            return aimbot.GetTarget()
        end
    end)

    if not ok or target == nil then return nil end

    if type(target) == "number" then
        targetState.index = target
        return target
    end

    local okIndex, index = pcall(target.GetIndex, target)
    if okIndex then targetState.index = index end
    return targetState.index
end

local classNames = {
    [1] = "scout",
    [2] = "sniper",
    [3] = "soldier",
    [4] = "demoman",
    [5] = "medic",
    [6] = "heavy",
    [7] = "pyro",
    [8] = "spy",
    [9] = "engineer",
}

local classAliases = {
    scout = {"scout"},
    sniper = {"sniper"},
    soldier = {"soldier"},
    demoman = {"demoman", "demo"},
    medic = {"medic"},
    heavy = {"heavy"},
    pyro = {"pyro"},
    spy = {"spy"},
    engineer = {"engineer"},
}

local leaderboardNames = {
    scout = "scout",
    sniper = "sniper",
    soldier = "soldier",
    demoman = "demo",
    medic = "medic",
    heavy = "heavy",
    pyro = "pyro",
    spy = "spy",
    engineer = "engineer",
}

local iconCache1 = {}
local iconCache2 = {}
local iconRetry1 = {}
local iconRetry2 = {}

local playerCache = {}
local buildingCache = {}
local nextPlayerCacheUpdate = 0
local PLAYER_CACHE_INTERVAL = 0.05
local nextIconPreload = 0
local ICON_PRELOAD_INTERVAL = 2.0

local buildingClasses = {
    {class = "CObjectSentrygun", kind = "sentry"},
    {class = "CObjectDispenser", kind = "dispenser"},
    {class = "CObjectTeleporter", kind = "teleporter"},
}

local buildingTextureCandidates = {
    sentry = {
        "hud/hud_obj_status_sentry_1",
        "hud/hud_obj_status_sentry_2",
        "hud/hud_obj_status_sentry_3",
    },
    dispenser = {
        "hud/hud_obj_status_dispenser",
    },
    teleporter_entrance = {
        "hud/hud_obj_status_tele_entrance",
    },
    teleporter_exit = {
        "hud/hud_obj_status_tele_exit",
    },
}

local buildingIconCache = {}
local buildingIconRetry = {}

local healthKitCache = {}
local ammoBoxCache = {}
local droppedWeaponCache = {}
local pickupModelCache = {}
local nextPickupScan = 0
local PICKUP_SCAN_INTERVAL = 0.35
local healthKitTexture = nil
local ammoBoxTexture = nil
local droppedWeaponTexture = nil

local oldmx, oldmy, lastclicktick = 0, 0, 0
local dragging = false
local cos, sin = math.cos, math.sin

local function clamp(v, minValue, maxValue)
    if v < minValue then return minValue end
    if v > maxValue then return maxValue end
    return v
end

local function syncRadarConfig()
    if not _G.NC_COMBINED_STATE then return end

    local style = tonumber(_G.NC_COMBINED_STATE.radarIconStyle)
    if style == 1 or style == 2 then
        config.icon_style = style
    end

    local shape = tonumber(_G.NC_COMBINED_STATE.radarShape)
    if shape == 0 or shape == 1 then
        config.radar_shape = shape
    end

    config.enemy_only =
        _G.NC_COMBINED_STATE.radarEnemyOnly ~= false
    config.healthbar =
        _G.NC_COMBINED_STATE.radarHealthbar ~= false
    config.healthkits =
        _G.NC_COMBINED_STATE.radarHealthkits ~= false
    config.ammo_boxes =
        _G.NC_COMBINED_STATE.radarAmmoBoxes ~= false
    config.dropped_weapons =
        _G.NC_COMBINED_STATE.radarDroppedWeapons ~= false

    local iconSize = tonumber(_G.NC_COMBINED_STATE.radarIconSize)
    if iconSize then
        config.icon_size = math.max(6, math.min(24, iconSize))
    end

    local zoom = tonumber(_G.NC_COMBINED_STATE.radarZoom)
    if zoom then
        config.zoom = math.max(0.1, math.min(10.0, zoom))
    end

    local scale = tonumber(_G.NC_COMBINED_STATE.radarScale)
    if scale then
        config.size = math.max(100, math.min(1000, scale))
    end
end

local triggerState = {nextUpdate = 0, active = false}

local function IsTriggerActive(now)
    now = now or globals.RealTime()
    if now < triggerState.nextUpdate then
        return triggerState.active
    end

    triggerState.nextUpdate = now + 0.10

    local ok, val = pcall(gui.GetValue, "Triggerbot Active")
    if not ok or val == nil then
        ok, val = pcall(gui.GetValue, "Trigger Active")
    end

    triggerState.active = ok and (val == 1 or val == true)
    return triggerState.active
end

local function tryFindMaterial(path)
    local ok, mat = pcall(function()
        return materials.Find(path)
    end)

    if ok and mat then
        return mat
    end

    return nil
end

local function makeLeaderboardMaterial(className)
    local leaderboardName = leaderboardNames[className]
    if not leaderboardName then
        return nil
    end

    local texturePath =
        "hud/leaderboard_class_" .. leaderboardName

    local materialName =
        "nc_radar_leaderboard_" .. leaderboardName

    local vmt =
        [["UnlitGeneric"
        {
            "$basetexture" "]] .. texturePath .. [["
            "$translucent" "1"
            "$ignorez" "1"
            "$nofog" "1"
            "$vertexcolor" "0"
            "$vertexalpha" "0"
        }]]

    local ok, mat = pcall(function()
        return materials.Create(materialName, vmt)
    end)

    if ok and mat then
        return {
            mat = mat,
            texSize = 32,
            cacheKey = className,
            style = 1,
            path = texturePath,
        }
    end

    local fallback = tryFindMaterial(texturePath)
    if fallback then
        return {
            mat = fallback,
            texSize = 32,
            cacheKey = className,
            style = 1,
            path = texturePath,
        }
    end

    return nil
end

local function loadStyle1Icon(className, now)
    local cached = iconCache1[className]
    if cached then
        return cached
    end

    if (iconRetry1[className] or 0) > now then
        return nil
    end

    iconRetry1[className] =
        now + config.material_retry

    cached = makeLeaderboardMaterial(className)

    if cached then
        iconCache1[className] = cached
        return cached
    end

    return nil
end

local function preloadStyle1Icons(now)
    for className, _ in pairs(leaderboardNames) do
        loadStyle1Icon(className, now)
    end
end

local function makePortraitMaterial(className, team)
    local aliases = classAliases[className]
    if not aliases then
        return nil
    end

    local suffix = (team == 3) and "_blue" or ""
    local teamName = (team == 3) and "blue" or "red"

    for i = 1, #aliases do
        local texturePath =
            "vgui/class_portraits/" .. aliases[i] .. suffix

        local materialName =
            "nc_radar_portrait_" .. aliases[i] .. "_" .. teamName

        local vmt =
            [["UnlitGeneric"
            {
                "$basetexture" "]] .. texturePath .. [["
                "$translucent" "1"
                "$ignorez" "1"
                "$nofog" "1"
                "$vertexcolor" "0"
                "$vertexalpha" "0"
            }]]

        local ok, mat = pcall(function()
            return materials.Create(materialName, vmt)
        end)

        if ok and mat then
            return {
                mat = mat,
                texSize = 256,
                cacheKey = className .. ":" .. teamName,
                style = 2,
                path = texturePath,
            }
        end

        local fallback = tryFindMaterial(texturePath)
        if fallback then
            return {
                mat = fallback,
                texSize = 256,
                cacheKey = className .. ":" .. teamName,
                style = 2,
                path = texturePath,
            }
        end
    end

    return nil
end

local function loadStyle2Icon(className, team, now)
    local teamKey = (team == 3) and "blue" or "red"
    local cacheKey = className .. ":" .. teamKey

    local cached = iconCache2[cacheKey]
    if cached then
        return cached
    end

    if (iconRetry2[cacheKey] or 0) > now then
        return nil
    end

    iconRetry2[cacheKey] = now + config.material_retry

    cached = makePortraitMaterial(className, team)
    if cached then
        iconCache2[cacheKey] = cached
        return cached
    end

    return nil
end

local function preloadStyle2Icons(now)
    for className, _ in pairs(classAliases) do
        loadStyle2Icon(className, 2, now)
        loadStyle2Icon(className, 3, now)
    end
end

local function GetIcon(className, team, now)
    if config.icon_style == 2 then
        return loadStyle2Icon(className, team, now)
    end

    return loadStyle1Icon(className, now)
end

local function makeBuildingMaterial(kind, level, team, iconColor)
    local candidates = buildingTextureCandidates[kind]
    if not candidates then return nil end

    local firstIndex = 1
    local lastIndex = #candidates

    if kind == "sentry" then
        level = tonumber(level) or 1
        if level < 1 then level = 1 end
        if level > 3 then level = 3 end
        firstIndex = level
        lastIndex = level
    end

    local cr = math.max(0, math.min(255, iconColor[1] or 255))
    local cg = math.max(0, math.min(255, iconColor[2] or 255))
    local cb = math.max(0, math.min(255, iconColor[3] or 255))

    local rf = cr / 255
    local gf = cg / 255
    local bf = cb / 255

    for i = firstIndex, lastIndex do
        local texturePath = candidates[i]
        local materialName =
            "nc_radar_building_"
            .. kind
            .. "_"
            .. tostring(i)
            .. "_"
            .. tostring(team)
            .. "_"
            .. tostring(cr)
            .. "_"
            .. tostring(cg)
            .. "_"
            .. tostring(cb)

        local vmt = string.format(
            [["UnlitGeneric"
            {
                "$basetexture" "%s"
                "$translucent" "1"
                "$ignorez" "1"
                "$nofog" "1"
                "$vertexcolor" "0"
                "$vertexalpha" "0"
                "$color2" "[%.4f %.4f %.4f]"
            }]],
            texturePath,
            rf,
            gf,
            bf
        )

        local ok, mat = pcall(function()
            return materials.Create(materialName, vmt)
        end)

        if ok and mat then
            return {
                mat = mat,
                texSize = 64,
                path = texturePath,
            }
        end
    end

    return nil
end

local function getBuildingIcon(kind, level, team, iconColor, now)
    local cr = math.max(0, math.min(255, iconColor[1] or 255))
    local cg = math.max(0, math.min(255, iconColor[2] or 255))
    local cb = math.max(0, math.min(255, iconColor[3] or 255))

    local cacheKey =
        kind
        .. ":"
        .. tostring(level or 1)
        .. ":"
        .. tostring(team)
        .. ":"
        .. tostring(cr)
        .. ":"
        .. tostring(cg)
        .. ":"
        .. tostring(cb)

    local cached = buildingIconCache[cacheKey]
    if cached then
        return cached, cacheKey
    end

    if (buildingIconRetry[cacheKey] or 0) > now then
        return nil, cacheKey
    end

    buildingIconRetry[cacheKey] = now + config.material_retry
    cached = makeBuildingMaterial(
        kind,
        level,
        team,
        iconColor
    )

    if cached then
        buildingIconCache[cacheKey] = cached
    end

    return cached, cacheKey
end

local function DrawMaterialIcon(iconData, px, py)
    if not iconData or not iconData.mat then return false end

    local size = config.icon_size
    local texSize = iconData.texSize or 256

    return pcall(
        render.DrawScreenSpaceRectangle,
        iconData.mat,
        math.floor(px - size),
        math.floor(py - size),
        size * 2,
        size * 2,
        0, 0,
        texSize, texSize,
        texSize, texSize
    )
end

local function DrawBuildingIcon(kind, level, team, iconColor, now, px, py)
    local iconData, cacheKey =
        getBuildingIcon(kind, level, team, iconColor, now)

    local ok = DrawMaterialIcon(iconData, px, py)
    if not ok then
        buildingIconCache[cacheKey] = nil
        buildingIconRetry[cacheKey] = 0
    end
    return ok
end

local function DrawSquareRadar(x, y, size, borderColor)
    local ix = math.floor(x)
    local iy = math.floor(y)
    local isize = math.floor(size)

    draw.Color(
        colors.bg[1], colors.bg[2], colors.bg[3],
        config.background_alpha
    )
    draw.FilledRect(ix, iy, ix + isize, iy + isize)

    draw.Color(
        borderColor[1], borderColor[2],
        borderColor[3], borderColor[4]
    )
    draw.OutlinedRect(
        ix - 1, iy - 1,
        ix + isize + 1, iy + isize + 1
    )
end

local circleFillCache = {
    radius = -1,
    step = -1,
    slices = {},
}

local function getCircleFillSlices(r)
    local step = math.max(2, math.floor(r / 100))

    if circleFillCache.radius == r
        and circleFillCache.step == step then
        return circleFillCache.slices
    end

    local slices = {}
    local n = 0
    local oy = -r

    while oy <= r do
        local sampleY = oy + math.floor((step - 1) / 2)
        if sampleY > r then sampleY = r end

        local inside = r * r - sampleY * sampleY
        if inside >= 0 then
            n = n + 1
            slices[n] = {
                oy,
                math.floor(math.sqrt(inside)),
                math.min(step, r - oy + 1),
            }
        end

        oy = oy + step
    end

    circleFillCache.radius = r
    circleFillCache.step = step
    circleFillCache.slices = slices
    return slices
end

local function DrawCircleRadar(cx, cy, radius, borderColor)
    local r = math.floor(radius)
    local icx = math.floor(cx)
    local icy = math.floor(cy)
    local slices = getCircleFillSlices(r)

    draw.Color(
        colors.bg[1], colors.bg[2], colors.bg[3],
        config.background_alpha
    )

    for i = 1, #slices do
        local slice = slices[i]
        local yy = icy + slice[1]
        local half = slice[2]
        local h = slice[3]

        draw.FilledRect(
            icx - half,
            yy,
            icx + half + 1,
            yy + h
        )
    end

    draw.Color(
        borderColor[1], borderColor[2],
        borderColor[3], borderColor[4]
    )
    draw.OutlinedCircle(icx, icy, r, 64)
end

local function DrawBackground()
    local size = config.size
    local x, y = config.x, config.y
    local cx, cy = x + size / 2, y + size / 2
    local radius = size / 2
    local sw, sh = draw.GetScreenSize()

    local luaMenuOpen = _G.NC_COMBINED_STATE
        and _G.NC_COMBINED_STATE.luaMenuOpen == true

    if luaMenuOpen then
        local mouse = input.GetMousePos()
        local mx, my = mouse[1], mouse[2]
        local dx, dy = mx - oldmx, my - oldmy

        local pressed, tick =
            input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)

        if pressed and tick > lastclicktick then
            local inside

            if config.radar_shape == 1 then
                local mdx, mdy = mx - cx, my - cy
                inside =
                    (mdx * mdx + mdy * mdy)
                    <= radius * radius
            else
                inside =
                    mx >= x and mx <= x + size
                    and my >= y and my <= y + size
            end

            if inside then
                dragging = true
                lastclicktick = tick
            end
        end

        if input.IsButtonReleased(E_ButtonCode.MOUSE_LEFT) then
            if dragging then
                NC_CONFIG.RADAR_X = config.x
                NC_CONFIG.RADAR_Y = config.y
                NC_SaveConfig()
            end

            dragging = false
        end

        if dragging then
            config.x = math.floor(
                clamp(x + dx, 0, math.max(0, sw - size))
            )
            config.y = math.floor(
                clamp(y + dy, 0, math.max(0, sh - size))
            )
        end

        oldmx, oldmy = mx, my
    else
        if dragging then
            NC_CONFIG.RADAR_X = config.x
            NC_CONFIG.RADAR_Y = config.y
            NC_SaveConfig()
        end

        dragging = false
    end

    x, y = config.x, config.y
    cx, cy = x + size / 2, y + size / 2
    radius = size / 2

    local borderColor = colors.border

    if config.radar_shape == 1 then
        DrawCircleRadar(cx, cy, radius, borderColor)
    else
        DrawSquareRadar(x, y, size, borderColor)
    end

    local crossColor =
        IsTriggerActive(globals.RealTime()) and colors.cross_active or colors.cross_normal

    draw.Color(
        crossColor[1], crossColor[2],
        crossColor[3], crossColor[4]
    )

    if config.radar_shape == 1 then
        draw.Line(
            math.floor(cx), math.floor(cy - radius),
            math.floor(cx), math.floor(cy + radius)
        )
        draw.Line(
            math.floor(cx - radius), math.floor(cy),
            math.floor(cx + radius), math.floor(cy)
        )
    else
        draw.Line(
            math.floor(cx), math.floor(y),
            math.floor(cx), math.floor(y + size)
        )
        draw.Line(
            math.floor(x), math.floor(cy),
            math.floor(x + size), math.floor(cy)
        )
    end
end

local function ClampRadarPosition(px, py, x, y, size)
    local cx, cy = x + size / 2, y + size / 2
    local margin = config.icon_size + 2

    if config.radar_shape == 0 then
        return
            math.floor(clamp(px, x + margin, x + size - margin)),
            math.floor(clamp(py, y + margin, y + size - margin))
    end

    local dx, dy = px - cx, py - cy
    local d2 = dx * dx + dy * dy
    local maxDist = size / 2 - margin

    if d2 > maxDist * maxDist and d2 > 0 then
        local distance = math.sqrt(d2)
        local scale = maxDist / distance
        dx, dy = dx * scale, dy * scale
    end

    return
        math.floor(cx + dx),
        math.floor(cy + dy)
end

local function DrawPlayerIcon(className, team, now, px, py)
    local iconData = GetIcon(className, team, now)
    local ok = DrawMaterialIcon(iconData, px, py)

    if not ok and iconData and iconData.cacheKey then
        if iconData.style == 2 then
            iconCache2[iconData.cacheKey] = nil
            iconRetry2[iconData.cacheKey] = 0
        elseif iconData.style == 1 then
            iconCache1[iconData.cacheKey] = nil
            iconRetry1[iconData.cacheKey] = 0
        end
    end

    return ok
end

local function ClassifyPickupModel(model)
    if not model or not models or not models.GetModelName then
        return false
    end

    local cached = pickupModelCache[model]
    if cached ~= nil then
        return cached
    end

    local okName, rawName = pcall(models.GetModelName, model)
    if not okName or not rawName then
        pickupModelCache[model] = false
        return false
    end

    local name = string.lower(tostring(rawName))
    local result = false

    if string.find(name, "medkit", 1, true)
        or string.find(name, "healthkit", 1, true)
        or string.find(name, "health_pack", 1, true)
        or string.find(name, "/health", 1, true)
        or string.find(name, "pill", 1, true) then

        local size = "full"
        if string.find(name, "small", 1, true)
            or string.find(name, "pill", 1, true) then
            size = "small"
        elseif string.find(name, "medium", 1, true) then
            size = "medium"
        end

        result = {kind = "health", size = size}

    elseif string.find(name, "ammopack", 1, true)
        or string.find(name, "ammo_pack", 1, true)
        or string.find(name, "ammobox", 1, true)
        or string.find(name, "/ammo", 1, true) then

        local size = "full"
        if string.find(name, "small", 1, true) then
            size = "small"
        elseif string.find(name, "medium", 1, true) then
            size = "medium"
        end

        result = {kind = "ammo", size = size}

    else
        local weapon =
            string.find(name, "/w_", 1, true)
            or string.find(name, "/c_", 1, true)
            or string.find(name, "/weapons/", 1, true)
            or string.find(name, "dropped", 1, true)

        local excluded =
            string.find(name, "toolbox", 1, true)
            or string.find(name, "gib", 1, true)

        if weapon and not excluded then
            result = {kind = "weapon", size = "full"}
        end
    end

    pickupModelCache[model] = result
    return result
end

local function GetCachedHealth(entity)
    if not entity then return 0, 1 end

    local health, maxHealth

    if entity.GetHealth then
        local ok, value = pcall(entity.GetHealth, entity)
        if ok then health = tonumber(value) end
    end

    if health == nil and entity.GetPropInt then
        local ok, value = pcall(entity.GetPropInt, entity, "m_iHealth")
        if ok then health = tonumber(value) end
    end

    if entity.GetMaxHealth then
        local ok, value = pcall(entity.GetMaxHealth, entity)
        if ok then maxHealth = tonumber(value) end
    end

    if (maxHealth == nil or maxHealth <= 0) and entity.GetPropInt then
        local ok, value = pcall(entity.GetPropInt, entity, "m_iMaxHealth")
        if ok then maxHealth = tonumber(value) end
    end

    health = health or 0
    maxHealth = maxHealth or math.max(health, 1)

    if maxHealth <= 0 then maxHealth = math.max(health, 1) end
    if health < 0 then health = 0 end

    return health, maxHealth
end

local function DrawRadarHealthbar(px, py, health, maxHealth, framed)
    if not config.healthbar then return end

    health = tonumber(health) or 0
    maxHealth = tonumber(maxHealth) or 1
    if maxHealth <= 0 then return end

    local fraction = health / maxHealth
    if fraction < 0 then fraction = 0 end
    if fraction > 1 then fraction = 1 end

    local extra = framed and config.center_box_padding or 0
    local half = config.icon_size + extra

    local left = math.floor(px - half)
    local right = math.floor(px + half)
    local iconBottom = math.floor(py + half)

    local top = iconBottom

    local barH = config.icon_size <= 8 and 3 or 4
    local bottom = top + barH

    if right <= left + 2 then return end

    draw.Color(6, 34, 34, 235)
    draw.FilledRect(left, top, right, bottom)

    local innerLeft = left + 1
    local innerRight = right - 1
    local innerTop = top + 1
    local innerBottom = bottom - 1
    local fillW = math.floor((innerRight - innerLeft) * fraction + 0.5)

    if fillW > 0 and innerBottom > innerTop then
        local r = math.floor(220 * (1 - fraction))
        local g = math.floor(70 + 170 * fraction)

        draw.Color(r, g, 55, 255)
        draw.FilledRect(
            innerLeft,
            innerTop,
            math.min(innerLeft + fillW, innerRight),
            innerBottom
        )
    end
end

local function updatePlayerCache(now)
    if now < nextPlayerCacheUpdate then
        return
    end

    nextPlayerCacheUpdate = now + PLAYER_CACHE_INTERVAL

    local found = entities.FindByClass("CTFPlayer")

    if found then
        for _, player in pairs(found) do
            if player then
                local index = player:GetIndex()

                if index and not player:IsAlive() then
                    playerCache[index] = nil

                elseif index and player:IsAlive() then
                    local origin = player:GetAbsOrigin()

                    if origin then
                        local entry = playerCache[index]
                        if not entry then
                            entry = {
                                index = index,
                                x = origin.x,
                                y = origin.y,
                                className = "scout",
                                team = 2,
                                health = 0,
                                maxHealth = 1,
                                lastSeen = now,
                            }
                            playerCache[index] = entry
                        end

                        entry.x = origin.x
                        entry.y = origin.y

                        local classId = player:GetPropInt("m_iClass")
                        local className = classNames[classId]

                        if className then
                            entry.className = className
                        end

                        local team = player:GetTeamNumber()
                        if team == 2 or team == 3 then
                            entry.team = team
                        end

                        entry.health, entry.maxHealth =
                            GetCachedHealth(player)

                        entry.lastSeen = now
                    end
                end
            end
        end
    end

    for index, entry in pairs(playerCache) do
        if now - entry.lastSeen > config.stale_time then
            playerCache[index] = nil
        end
    end

    for i = 1, #buildingClasses do
        local classInfo = buildingClasses[i]
        local foundBuildings = entities.FindByClass(classInfo.class)

        if foundBuildings then
            for _, building in pairs(foundBuildings) do
                if building then
                    local index = building:GetIndex()
                    local origin = building:GetAbsOrigin()
                    local team = building:GetTeamNumber()

                    if index and origin and (team == 2 or team == 3) then
                        local key = classInfo.kind .. ":" .. tostring(index)
                        local entry = buildingCache[key]

                        if not entry then
                            entry = {
                                index = index,
                                kind = classInfo.kind,
                                x = origin.x,
                                y = origin.y,
                                team = team,
                                level = 1,
                                objectMode = 0,
                                ownerIndex = nil,
                                health = 0,
                                maxHealth = 1,
                                lastSeen = now,
                            }
                            buildingCache[key] = entry
                        end

                        entry.x = origin.x
                        entry.y = origin.y
                        entry.team = team
                        entry.health, entry.maxHealth =
                            GetCachedHealth(building)

                        local okBuilder, builder = pcall(function()
                            return building:GetPropEntity("m_hBuilder")
                        end)

                        if okBuilder and builder then
                            local okBuilderIndex, builderIndex = pcall(function()
                                return builder:GetIndex()
                            end)

                            if okBuilderIndex then
                                entry.ownerIndex = builderIndex
                            end
                        end

                        if classInfo.kind == "sentry" then
                            local okLevel, level = pcall(function()
                                return building:GetPropInt("m_iUpgradeLevel")
                            end)

                            if okLevel and level then
                                if level < 1 then level = 1 end
                                if level > 3 then level = 3 end
                                entry.level = level
                            end
                        elseif classInfo.kind == "teleporter" then
                            local okMode, objectMode = pcall(function()
                                return building:GetPropInt("m_iObjectMode")
                            end)

                            if okMode and objectMode ~= nil then
                                entry.objectMode = objectMode
                            end
                        end

                        entry.lastSeen = now
                    end
                end
            end
        end
    end

    for key, entry in pairs(buildingCache) do
        if now - entry.lastSeen > config.stale_time then
            buildingCache[key] = nil
        end
    end

    if (config.healthkits or config.ammo_boxes or config.dropped_weapons)
        and now >= nextPickupScan then

        nextPickupScan = now + PICKUP_SCAN_INTERVAL

        local found = entities.FindByClass("CBaseAnimating")

        if found then
            for _, entity in pairs(found) do
                if entity then
                    local index = entity:GetIndex()
                    local model = nil

                    if index and entity.GetModel then
                        local okModel, value =
                            pcall(entity.GetModel, entity)
                        if okModel then
                            model = value
                        end
                    end

                    if index and model then
                        local info = ClassifyPickupModel(model)

                        if info then
                            local enabled =
                                (info.kind == "health" and config.healthkits)
                                or (info.kind == "ammo" and config.ammo_boxes)
                                or (info.kind == "weapon" and config.dropped_weapons)

                            if enabled then
                                local origin = entity:GetAbsOrigin()

                                if origin then
                                    local cache

                                    if info.kind == "health" then
                                        cache = healthKitCache
                                    elseif info.kind == "ammo" then
                                        cache = ammoBoxCache
                                    else
                                        cache = droppedWeaponCache
                                    end

                                    local key = tostring(index)
                                    local entry = cache[key]

                                    if not entry then
                                        entry = {
                                            index = index,
                                            size = info.size,
                                            x = origin.x,
                                            y = origin.y,
                                            lastSeen = now,
                                        }
                                        cache[key] = entry
                                    end

                                    entry.x = origin.x
                                    entry.y = origin.y
                                    entry.size = info.size
                                    entry.lastSeen = now
                                end
                            end
                        end
                    end
                end
            end
        end

        if config.ammo_boxes then
            local dropped = entities.FindByClass("CTFAmmoPack")

            if dropped then
                for _, entity in pairs(dropped) do
                    if entity then
                        local index = entity:GetIndex()
                        local origin = entity:GetAbsOrigin()

                        if index and origin then
                            local key = "drop:" .. tostring(index)
                            local entry = ammoBoxCache[key]

                            if not entry then
                                entry = {
                                    index = index,
                                    size = "medium",
                                    x = origin.x,
                                    y = origin.y,
                                    lastSeen = now,
                                }
                                ammoBoxCache[key] = entry
                            end

                            entry.x = origin.x
                            entry.y = origin.y
                            entry.lastSeen = now
                        end
                    end
                end
            end
        end

        if config.dropped_weapons then
            local dropped = entities.FindByClass("CTFDroppedWeapon")

            if dropped then
                for _, entity in pairs(dropped) do
                    if entity then
                        local index = entity:GetIndex()
                        local origin = entity:GetAbsOrigin()

                        if index and origin then
                            local key = "drop:" .. tostring(index)
                            local entry = droppedWeaponCache[key]

                            if not entry then
                                entry = {
                                    index = index,
                                    size = "full",
                                    x = origin.x,
                                    y = origin.y,
                                    lastSeen = now,
                                }
                                droppedWeaponCache[key] = entry
                            end

                            entry.x = origin.x
                            entry.y = origin.y
                            entry.lastSeen = now
                        end
                    end
                end
            end
        end

        local stale = PICKUP_SCAN_INTERVAL * 2.5

        for key, entry in pairs(healthKitCache) do
            if now - entry.lastSeen > stale then
                healthKitCache[key] = nil
            end
        end

        for key, entry in pairs(ammoBoxCache) do
            if now - entry.lastSeen > stale then
                ammoBoxCache[key] = nil
            end
        end

        for key, entry in pairs(droppedWeaponCache) do
            if now - entry.lastSeen > stale then
                droppedWeaponCache[key] = nil
            end
        end
    end

    if not config.healthkits and next(healthKitCache) ~= nil then
        healthKitCache = {}
    end

    if not config.ammo_boxes and next(ammoBoxCache) ~= nil then
        ammoBoxCache = {}
    end

    if not config.dropped_weapons
        and next(droppedWeaponCache) ~= nil then
        droppedWeaponCache = {}
    end
end

local function DrawRadarIconBlockBackground(px, py, borderColor)
    local half =
        config.icon_size + config.center_box_padding

    local left = math.floor(px - half)
    local top = math.floor(py - half)
    local right = math.floor(px + half)
    local bottom = math.floor(py + half)

    draw.Color(
        colors.bg[1],
        colors.bg[2],
        colors.bg[3],
        config.center_bg_alpha
    )
    draw.FilledRect(left, top, right, bottom)

    draw.Color(
        borderColor[1],
        borderColor[2],
        borderColor[3],
        borderColor[4] or 255
    )
    draw.OutlinedRect(left, top, right, bottom)

    return left, top, right, bottom
end

local function GetHealthKitTexture()
    if healthKitTexture then
        return healthKitTexture
    end

    local pixels =
        "\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\214\016\016\255\214\016\016\255\214\016\016\255\214\016\016\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\092\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\052\221\025\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255"

    healthKitTexture =
        draw.CreateTextureRGBA(
            pixels,
            32,
            32
        )

    return healthKitTexture
end
local function DrawHealthKitIcon(px, py, pickupSize)
    local texture = GetHealthKitTexture()
    if not texture then return end

    local scale = 1.0

    if pickupSize == "small" then
        scale = 0.72
    elseif pickupSize == "medium" then
        scale = 0.86
    end

    local half = math.max(
        5,
        math.floor(config.icon_size * scale + 0.5)
    )

    draw.TexturedRect(
        texture,
        math.floor(px - half),
        math.floor(py - half),
        math.floor(px + half),
        math.floor(py + half)
    )
end

local function GetAmmoBoxTexture()
    if ammoBoxTexture then
        return ammoBoxTexture
    end

    local pixels =
        "\000\004\006\255\000\004\006\255\001\004\006\255\001\004\006\255\006\007\010\255\006\007\010\255\006\007\010\255\006\007\010\255\009\011\013\255\009\011\013\255\009\011\013\255\009\011\013\255\008\010\012\255\008\010\012\255\006\008\011\255\006\008\011\255\006\008\011\255\006\008\011\255\007\008\011\255\007\008\011\255\000\001\004\255\000\001\004\255\000\001\004\255\000\001\004\255\000\001\004\255\000\001\004\255\006\007\009\255\006\007\009\255\003\002\004\255\003\002\004\255\007\007\009\255\007\007\009\255\000\004\006\255\000\004\006\255\001\004\006\255\001\004\006\255\006\007\010\255\006\007\010\255\006\007\010\255\006\007\010\255\009\011\013\255\009\011\013\255\009\011\013\255\009\011\013\255\008\010\012\255\008\010\012\255\006\008\011\255\006\008\011\255\006\008\011\255\006\008\011\255\007\008\011\255\007\008\011\255\000\001\004\255\000\001\004\255\000\001\004\255\000\001\004\255\000\001\004\255\000\001\004\255\006\007\009\255\006\007\009\255\003\002\004\255\003\002\004\255\007\007\009\255\007\007\009\255\000\003\005\255\000\003\005\255\152\154\157\255\152\154\157\255\161\162\166\255\161\162\166\255\160\160\165\255\160\160\165\255\160\160\164\255\160\160\164\255\157\158\162\255\157\158\162\255\153\155\159\255\153\155\159\255\151\154\158\255\151\154\158\255\152\154\157\255\152\154\157\255\155\156\160\255\155\156\160\255\158\158\162\255\158\158\162\255\158\158\162\255\158\158\162\255\160\160\164\255\160\160\164\255\167\167\170\255\167\167\170\255\149\149\151\255\149\149\151\255\000\000\000\255\000\000\000\255\000\003\005\255\000\003\005\255\152\154\157\255\152\154\157\255\161\162\166\255\161\162\166\255\160\160\165\255\160\160\165\255\160\160\164\255\160\160\164\255\157\158\162\255\157\158\162\255\153\155\159\255\153\155\159\255\151\154\158\255\151\154\158\255\152\154\157\255\152\154\157\255\155\156\160\255\155\156\160\255\158\158\162\255\158\158\162\255\158\158\162\255\158\158\162\255\160\160\164\255\160\160\164\255\167\167\170\255\167\167\170\255\149\149\151\255\149\149\151\255\000\000\000\255\000\000\000\255\000\003\004\255\000\003\004\255\156\157\159\255\156\157\159\255\162\161\164\255\162\161\164\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\158\158\159\255\158\158\159\255\162\163\164\255\162\163\164\255\000\000\001\255\000\000\001\255\000\000\000\255\000\000\000\255\158\158\160\255\158\158\160\255\161\160\162\255\161\160\162\255\000\000\001\255\000\000\001\255\000\000\000\255\000\000\000\255\165\165\167\255\165\165\167\255\163\163\165\255\163\163\165\255\000\000\000\255\000\000\000\255\000\003\004\255\000\003\004\255\156\157\159\255\156\157\159\255\162\161\164\255\162\161\164\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\158\158\159\255\158\158\159\255\162\163\164\255\162\163\164\255\000\000\001\255\000\000\001\255\000\000\000\255\000\000\000\255\158\158\160\255\158\158\160\255\161\160\162\255\161\160\162\255\000\000\001\255\000\000\001\255\000\000\000\255\000\000\000\255\165\165\167\255\165\165\167\255\163\163\165\255\163\163\165\255\000\000\000\255\000\000\000\255\000\002\002\255\000\002\002\255\163\163\161\255\163\163\161\255\162\159\155\255\162\159\155\255\006\005\000\255\006\005\000\255\008\007\002\255\008\007\002\255\162\162\156\255\162\162\156\255\158\158\150\255\158\158\150\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\162\161\156\255\162\161\156\255\162\161\157\255\162\161\157\255\003\001\000\255\003\001\000\255\003\002\000\255\003\002\000\255\155\155\155\255\155\155\155\255\160\159\162\255\160\159\162\255\000\000\000\255\000\000\000\255\000\002\002\255\000\002\002\255\163\163\161\255\163\163\161\255\162\159\155\255\162\159\155\255\006\005\000\255\006\005\000\255\008\007\002\255\008\007\002\255\162\162\156\255\162\162\156\255\158\158\150\255\158\158\150\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\162\161\156\255\162\161\156\255\162\161\157\255\162\161\157\255\003\001\000\255\003\001\000\255\003\002\000\255\003\002\000\255\155\155\155\255\155\155\155\255\160\159\162\255\160\159\162\255\000\000\000\255\000\000\000\255\000\002\001\255\000\002\001\255\160\159\149\255\160\159\149\255\007\003\000\255\007\003\000\255\006\002\000\255\006\002\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\002\000\000\255\002\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\003\001\000\255\003\001\000\255\005\003\000\255\005\003\000\255\008\007\001\255\008\007\001\255\160\159\162\255\160\159\162\255\004\004\008\255\004\004\008\255\000\002\001\255\000\002\001\255\160\159\149\255\160\159\149\255\007\003\000\255\007\003\000\255\006\002\000\255\006\002\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\003\001\000\255\002\000\000\255\002\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\003\001\000\255\003\001\000\255\005\003\000\255\005\003\000\255\008\007\001\255\008\007\001\255\160\159\162\255\160\159\162\255\004\004\008\255\004\004\008\255\000\000\000\255\000\000\000\255\159\157\139\255\159\157\139\255\007\000\000\255\007\000\000\255\104\098\065\255\104\098\065\255\107\102\074\255\107\102\074\255\009\005\000\255\009\005\000\255\011\006\000\255\011\006\000\255\107\101\072\255\107\101\072\255\107\102\076\255\107\102\076\255\009\006\000\255\009\006\000\255\005\004\000\255\005\004\000\255\102\099\071\255\102\099\071\255\104\100\071\255\104\100\071\255\005\003\000\255\005\003\000\255\157\157\159\255\157\157\159\255\010\010\014\255\010\010\014\255\000\000\000\255\000\000\000\255\159\157\139\255\159\157\139\255\007\000\000\255\007\000\000\255\104\098\065\255\104\098\065\255\107\102\074\255\107\102\074\255\009\005\000\255\009\005\000\255\011\006\000\255\011\006\000\255\107\101\072\255\107\101\072\255\107\102\076\255\107\102\076\255\009\006\000\255\009\006\000\255\005\004\000\255\005\004\000\255\102\099\071\255\102\099\071\255\104\100\071\255\104\100\071\255\005\003\000\255\005\003\000\255\157\157\159\255\157\157\159\255\010\010\014\255\010\010\014\255\000\000\000\255\000\000\000\255\162\158\133\255\162\158\133\255\010\002\000\255\010\002\000\255\108\099\055\255\108\099\055\255\111\104\066\255\111\104\066\255\012\005\000\255\012\005\000\255\013\006\000\255\013\006\000\255\109\101\064\255\109\101\064\255\110\102\067\255\110\102\067\255\011\006\000\255\011\006\000\255\007\004\000\255\007\004\000\255\103\100\061\255\103\100\061\255\108\105\063\255\108\105\063\255\005\003\000\255\005\003\000\255\156\156\158\255\156\156\158\255\009\009\014\255\009\009\014\255\000\000\000\255\000\000\000\255\162\158\133\255\162\158\133\255\010\002\000\255\010\002\000\255\108\099\055\255\108\099\055\255\111\104\066\255\111\104\066\255\012\005\000\255\012\005\000\255\013\006\000\255\013\006\000\255\109\101\064\255\109\101\064\255\110\102\067\255\110\102\067\255\011\006\000\255\011\006\000\255\007\004\000\255\007\004\000\255\103\100\061\255\103\100\061\255\108\105\063\255\108\105\063\255\005\003\000\255\005\003\000\255\156\156\158\255\156\156\158\255\009\009\014\255\009\009\014\255\000\000\000\255\000\000\000\255\164\161\132\255\164\161\132\255\013\004\000\255\013\004\000\255\111\102\053\255\111\102\053\255\114\106\066\255\114\106\066\255\012\005\000\255\012\005\000\255\014\006\000\255\014\006\000\255\109\101\060\255\109\101\060\255\110\102\064\255\110\102\064\255\012\006\000\255\012\006\000\255\009\004\000\255\009\004\000\255\104\100\057\255\104\100\057\255\108\105\057\255\108\105\057\255\005\004\000\255\005\004\000\255\156\156\158\255\156\156\158\255\008\008\013\255\008\008\013\255\000\000\000\255\000\000\000\255\164\161\132\255\164\161\132\255\013\004\000\255\013\004\000\255\111\102\053\255\111\102\053\255\114\106\066\255\114\106\066\255\012\005\000\255\012\005\000\255\014\006\000\255\014\006\000\255\109\101\060\255\109\101\060\255\110\102\064\255\110\102\064\255\012\006\000\255\012\006\000\255\009\004\000\255\009\004\000\255\104\100\057\255\104\100\057\255\108\105\057\255\108\105\057\255\005\004\000\255\005\004\000\255\156\156\158\255\156\156\158\255\008\008\013\255\008\008\013\255\000\001\000\255\000\001\000\255\164\161\131\255\164\161\131\255\014\004\000\255\014\004\000\255\114\104\053\255\114\104\053\255\113\105\064\255\113\105\064\255\013\005\000\255\013\005\000\255\014\006\000\255\014\006\000\255\110\101\059\255\110\101\059\255\111\103\061\255\111\103\061\255\014\006\000\255\014\006\000\255\011\003\000\255\011\003\000\255\105\100\053\255\105\100\053\255\108\106\053\255\108\106\053\255\004\003\000\255\004\003\000\255\155\155\157\255\155\155\157\255\007\007\012\255\007\007\012\255\000\001\000\255\000\001\000\255\164\161\131\255\164\161\131\255\014\004\000\255\014\004\000\255\114\104\053\255\114\104\053\255\113\105\064\255\113\105\064\255\013\005\000\255\013\005\000\255\014\006\000\255\014\006\000\255\110\101\059\255\110\101\059\255\111\103\061\255\111\103\061\255\014\006\000\255\014\006\000\255\011\003\000\255\011\003\000\255\105\100\053\255\105\100\053\255\108\106\053\255\108\106\053\255\004\003\000\255\004\003\000\255\155\155\157\255\155\155\157\255\007\007\012\255\007\007\012\255\000\002\001\255\000\002\001\255\164\161\132\255\164\161\132\255\014\004\000\255\014\004\000\255\114\104\054\255\114\104\054\255\113\105\065\255\113\105\065\255\013\005\000\255\013\005\000\255\014\006\000\255\014\006\000\255\110\101\059\255\110\101\059\255\111\103\061\255\111\103\061\255\014\006\000\255\014\006\000\255\012\003\000\255\012\003\000\255\106\100\052\255\106\100\052\255\110\107\053\255\110\107\053\255\004\003\000\255\004\003\000\255\155\155\157\255\155\155\157\255\006\005\011\255\006\005\011\255\000\002\001\255\000\002\001\255\164\161\132\255\164\161\132\255\014\004\000\255\014\004\000\255\114\104\054\255\114\104\054\255\113\105\065\255\113\105\065\255\013\005\000\255\013\005\000\255\014\006\000\255\014\006\000\255\110\101\059\255\110\101\059\255\111\103\061\255\111\103\061\255\014\006\000\255\014\006\000\255\012\003\000\255\012\003\000\255\106\100\052\255\106\100\052\255\110\107\053\255\110\107\053\255\004\003\000\255\004\003\000\255\155\155\157\255\155\155\157\255\006\005\011\255\006\005\011\255\000\002\002\255\000\002\002\255\163\159\134\255\163\159\134\255\012\003\000\255\012\003\000\255\113\104\059\255\113\104\059\255\111\103\069\255\111\103\069\255\012\004\000\255\012\004\000\255\014\006\000\255\014\006\000\255\109\101\063\255\109\101\063\255\110\102\064\255\110\102\064\255\014\005\000\255\014\005\000\255\011\003\000\255\011\003\000\255\105\100\054\255\105\100\054\255\110\108\056\255\110\108\056\255\004\003\000\255\004\003\000\255\156\156\158\255\156\156\158\255\006\005\011\255\006\005\011\255\000\002\002\255\000\002\002\255\163\159\134\255\163\159\134\255\012\003\000\255\012\003\000\255\113\104\059\255\113\104\059\255\111\103\069\255\111\103\069\255\012\004\000\255\012\004\000\255\014\006\000\255\014\006\000\255\109\101\063\255\109\101\063\255\110\102\064\255\110\102\064\255\014\005\000\255\014\005\000\255\011\003\000\255\011\003\000\255\105\100\054\255\105\100\054\255\110\108\056\255\110\108\056\255\004\003\000\255\004\003\000\255\156\156\158\255\156\156\158\255\006\005\011\255\006\005\011\255\000\002\003\255\000\002\003\255\163\159\139\255\163\159\139\255\011\002\000\255\011\002\000\255\113\104\068\255\113\104\068\255\109\102\075\255\109\102\075\255\012\004\000\255\012\004\000\255\013\005\000\255\013\005\000\255\109\101\069\255\109\101\069\255\110\102\071\255\110\102\071\255\013\005\000\255\013\005\000\255\010\003\000\255\010\003\000\255\103\100\059\255\103\100\059\255\112\112\064\255\112\112\064\255\004\004\000\255\004\004\000\255\158\157\159\255\158\157\159\255\003\002\008\255\003\002\008\255\000\002\003\255\000\002\003\255\163\159\139\255\163\159\139\255\011\002\000\255\011\002\000\255\113\104\068\255\113\104\068\255\109\102\075\255\109\102\075\255\012\004\000\255\012\004\000\255\013\005\000\255\013\005\000\255\109\101\069\255\109\101\069\255\110\102\071\255\110\102\071\255\013\005\000\255\013\005\000\255\010\003\000\255\010\003\000\255\103\100\059\255\103\100\059\255\112\112\064\255\112\112\064\255\004\004\000\255\004\004\000\255\158\157\159\255\158\157\159\255\003\002\008\255\003\002\008\255\002\004\005\255\002\004\005\255\160\158\143\255\160\158\143\255\009\002\000\255\009\002\000\255\111\104\080\255\111\104\080\255\107\101\085\255\107\101\085\255\009\004\000\255\009\004\000\255\011\005\000\255\011\005\000\255\106\100\079\255\106\100\079\255\107\102\081\255\107\102\081\255\010\005\000\255\010\005\000\255\006\003\000\255\006\003\000\255\100\100\071\255\100\100\071\255\095\097\064\255\095\097\064\255\008\010\000\255\008\010\000\255\158\158\161\255\158\158\161\255\000\000\002\255\000\000\002\255\002\004\005\255\002\004\005\255\160\158\143\255\160\158\143\255\009\002\000\255\009\002\000\255\111\104\080\255\111\104\080\255\107\101\085\255\107\101\085\255\009\004\000\255\009\004\000\255\011\005\000\255\011\005\000\255\106\100\079\255\106\100\079\255\107\102\081\255\107\102\081\255\010\005\000\255\010\005\000\255\006\003\000\255\006\003\000\255\100\100\071\255\100\100\071\255\095\097\064\255\095\097\064\255\008\010\000\255\008\010\000\255\158\158\161\255\158\158\161\255\000\000\002\255\000\000\002\255\008\010\010\255\008\010\010\255\158\156\148\255\158\156\148\255\009\004\000\255\009\004\000\255\009\003\000\255\009\003\000\255\008\003\000\255\008\003\000\255\007\003\000\255\007\003\000\255\005\003\000\255\005\003\000\255\006\002\000\255\006\002\000\255\006\002\000\255\006\002\000\255\004\003\000\255\004\003\000\255\001\002\000\255\001\002\000\255\000\003\000\255\000\003\000\255\000\002\000\255\000\002\000\255\000\000\000\255\000\000\000\255\159\162\166\255\159\162\166\255\008\011\016\255\008\011\016\255\008\010\010\255\008\010\010\255\158\156\148\255\158\156\148\255\009\004\000\255\009\004\000\255\009\003\000\255\009\003\000\255\008\003\000\255\008\003\000\255\007\003\000\255\007\003\000\255\005\003\000\255\005\003\000\255\006\002\000\255\006\002\000\255\006\002\000\255\006\002\000\255\004\003\000\255\004\003\000\255\001\002\000\255\001\002\000\255\000\003\000\255\000\003\000\255\000\002\000\255\000\002\000\255\000\000\000\255\000\000\000\255\159\162\166\255\159\162\166\255\008\011\016\255\008\011\016\255\013\016\015\255\013\016\015\255\153\153\149\255\153\153\149\255\152\150\144\255\152\150\144\255\154\151\148\255\154\151\148\255\157\153\153\255\157\153\153\255\166\164\163\255\166\164\163\255\152\151\149\255\152\151\149\255\153\153\150\255\153\153\150\255\154\154\152\255\154\154\152\255\154\157\154\255\154\157\154\255\155\160\156\255\155\160\156\255\156\162\159\255\156\162\159\255\157\163\161\255\157\163\161\255\151\157\158\255\151\157\158\255\143\149\152\255\143\149\152\255\000\006\009\255\000\006\009\255\013\016\015\255\013\016\015\255\153\153\149\255\153\153\149\255\152\150\144\255\152\150\144\255\154\151\148\255\154\151\148\255\157\153\153\255\157\153\153\255\166\164\163\255\166\164\163\255\152\151\149\255\152\151\149\255\153\153\150\255\153\153\150\255\154\154\152\255\154\154\152\255\154\157\154\255\154\157\154\255\155\160\156\255\155\160\156\255\156\162\159\255\156\162\159\255\157\163\161\255\157\163\161\255\151\157\158\255\151\157\158\255\143\149\152\255\143\149\152\255\000\006\009\255\000\006\009\255\019\022\021\255\019\022\021\255\008\010\008\255\008\010\008\255\003\002\001\255\003\002\001\255\011\008\008\255\011\008\008\255\007\002\005\255\007\002\005\255\003\000\003\255\003\000\003\255\001\001\003\255\001\001\003\255\001\001\003\255\001\001\003\255\000\000\002\255\000\000\002\255\000\000\001\255\000\000\001\255\000\001\002\255\000\001\002\255\000\004\004\255\000\004\004\255\000\004\004\255\000\004\004\255\000\004\004\255\000\004\004\255\000\005\007\255\000\005\007\255\000\005\007\255\000\005\007\255\019\022\021\255\019\022\021\255\008\010\008\255\008\010\008\255\003\002\001\255\003\002\001\255\011\008\008\255\011\008\008\255\007\002\005\255\007\002\005\255\003\000\003\255\003\000\003\255\001\001\003\255\001\001\003\255\001\001\003\255\001\001\003\255\000\000\002\255\000\000\002\255\000\000\001\255\000\000\001\255\000\001\002\255\000\001\002\255\000\004\004\255\000\004\004\255\000\004\004\255\000\004\004\255\000\004\004\255\000\004\004\255\000\005\007\255\000\005\007\255\000\005\007\255\000\005\007\255"

    ammoBoxTexture =
        draw.CreateTextureRGBA(
            pixels,
            32,
            32
        )

    return ammoBoxTexture
end
local function DrawAmmoBoxIcon(px, py, pickupSize)
    local texture = GetAmmoBoxTexture()
    if not texture then return end

    local scale = 1.0
    if pickupSize == "small" then
        scale = 0.72
    elseif pickupSize == "medium" then
        scale = 0.86
    end

    local half = math.max(
        5,
        math.floor(config.icon_size * scale + 0.5)
    )

    draw.TexturedRect(
        texture,
        math.floor(px - half),
        math.floor(py - half),
        math.floor(px + half),
        math.floor(py + half)
    )
end

local function GetDroppedWeaponTexture()
    if droppedWeaponTexture then
        return droppedWeaponTexture
    end

    local pixels =
        "\000\005\000\255\000\005\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\010\000\255\000\010\000\255\000\011\000\255\000\011\000\255\000\011\000\255\000\011\000\255\000\012\000\255\000\012\000\255\000\011\000\255\000\011\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\009\000\255\000\009\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\005\000\255\000\005\000\255\000\005\000\255\000\005\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\010\000\255\000\010\000\255\000\011\000\255\000\011\000\255\000\011\000\255\000\011\000\255\000\012\000\255\000\012\000\255\000\011\000\255\000\011\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\008\000\255\000\009\000\255\000\009\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\005\000\255\000\005\000\255\000\010\000\255\000\010\000\255\201\241\195\255\201\241\195\255\197\251\190\255\197\251\190\255\192\255\184\255\192\255\184\255\196\255\186\255\196\255\186\255\201\255\188\255\201\255\188\255\200\255\187\255\200\255\187\255\199\254\186\255\199\254\186\255\196\252\187\255\196\252\187\255\195\252\191\255\195\252\191\255\193\252\192\255\193\252\192\255\195\253\195\255\195\253\195\255\202\250\199\255\202\250\199\255\212\247\205\255\212\247\205\255\212\234\202\255\212\234\202\255\000\010\000\255\000\010\000\255\000\010\000\255\000\010\000\255\201\241\195\255\201\241\195\255\197\251\190\255\197\251\190\255\192\255\184\255\192\255\184\255\196\255\186\255\196\255\186\255\201\255\188\255\201\255\188\255\200\255\187\255\200\255\187\255\199\254\186\255\199\254\186\255\196\252\187\255\196\252\187\255\195\252\191\255\195\252\191\255\193\252\192\255\193\252\192\255\195\253\195\255\195\253\195\255\202\250\199\255\202\250\199\255\212\247\205\255\212\247\205\255\212\234\202\255\212\234\202\255\000\010\000\255\000\010\000\255\000\001\000\255\000\001\000\255\196\238\192\255\196\238\192\255\198\252\193\255\198\252\193\255\194\255\187\255\194\255\187\255\198\255\188\255\198\255\188\255\202\255\189\255\202\255\189\255\202\255\189\255\202\255\189\255\199\254\187\255\199\254\187\255\195\252\188\255\195\252\188\255\193\252\193\255\193\252\193\255\191\252\197\255\191\252\197\255\193\253\203\255\193\253\203\255\199\251\205\255\199\251\205\255\207\248\207\255\207\248\207\255\211\239\206\255\211\239\206\255\000\012\000\255\000\012\000\255\000\001\000\255\000\001\000\255\196\238\192\255\196\238\192\255\198\252\193\255\198\252\193\255\194\255\187\255\194\255\187\255\198\255\188\255\198\255\188\255\202\255\189\255\202\255\189\255\202\255\189\255\202\255\189\255\199\254\187\255\199\254\187\255\195\252\188\255\195\252\188\255\193\252\193\255\193\252\193\255\191\252\197\255\191\252\197\255\193\253\203\255\193\253\203\255\199\251\205\255\199\251\205\255\207\248\207\255\207\248\207\255\211\239\206\255\211\239\206\255\000\012\000\255\000\012\000\255\000\006\000\255\000\006\000\255\217\238\215\255\217\238\215\255\221\243\219\255\221\243\219\255\000\007\000\255\000\007\000\255\146\164\141\255\146\164\141\255\000\008\000\255\000\008\000\255\147\162\140\255\147\162\140\255\000\005\000\255\000\005\000\255\147\165\144\255\147\165\144\255\000\009\000\255\000\009\000\255\000\010\001\255\000\010\001\255\000\010\007\255\000\010\007\255\000\012\005\255\000\012\005\255\000\013\000\255\000\013\000\255\215\237\216\255\215\237\216\255\000\012\000\255\000\012\000\255\000\006\000\255\000\006\000\255\217\238\215\255\217\238\215\255\221\243\219\255\221\243\219\255\000\007\000\255\000\007\000\255\146\164\141\255\146\164\141\255\000\008\000\255\000\008\000\255\147\162\140\255\147\162\140\255\000\005\000\255\000\005\000\255\147\165\144\255\147\165\144\255\000\009\000\255\000\009\000\255\000\010\001\255\000\010\001\255\000\010\007\255\000\010\007\255\000\012\005\255\000\012\005\255\000\013\000\255\000\013\000\255\215\237\216\255\215\237\216\255\000\012\000\255\000\012\000\255\000\005\000\255\000\005\000\255\226\234\224\255\226\234\224\255\002\006\002\255\002\006\002\255\003\001\002\255\003\001\002\255\003\000\001\255\003\000\001\255\005\000\000\255\005\000\000\255\004\000\000\255\004\000\000\255\002\000\000\255\002\000\000\255\010\003\006\255\010\003\006\255\001\000\000\255\001\000\000\255\164\162\169\255\164\162\169\255\158\161\169\255\158\161\169\255\150\161\161\255\150\161\161\255\000\005\000\255\000\005\000\255\218\236\218\255\218\236\218\255\000\012\000\255\000\012\000\255\000\005\000\255\000\005\000\255\226\234\224\255\226\234\224\255\002\006\002\255\002\006\002\255\003\001\002\255\003\001\002\255\003\000\001\255\003\000\001\255\005\000\000\255\005\000\000\255\004\000\000\255\004\000\000\255\002\000\000\255\002\000\000\255\010\003\006\255\010\003\006\255\001\000\000\255\001\000\000\255\164\162\169\255\164\162\169\255\158\161\169\255\158\161\169\255\150\161\161\255\150\161\161\255\000\005\000\255\000\005\000\255\218\236\218\255\218\236\218\255\000\012\000\255\000\012\000\255\000\005\000\255\000\005\000\255\223\236\220\255\223\236\220\255\000\006\000\255\000\006\000\255\000\004\000\255\000\004\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\017\000\255\000\017\000\255\204\232\200\255\204\232\200\255\217\238\212\255\217\238\212\255\000\010\000\255\000\010\000\255\000\005\000\255\000\005\000\255\223\236\220\255\223\236\220\255\000\006\000\255\000\006\000\255\000\004\000\255\000\004\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\000\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\009\000\255\000\017\000\255\000\017\000\255\204\232\200\255\204\232\200\255\217\238\212\255\217\238\212\255\000\010\000\255\000\010\000\255\000\007\000\255\000\007\000\255\216\239\210\255\216\239\210\255\218\239\211\255\218\239\211\255\226\243\219\255\226\243\219\255\000\005\000\255\000\005\000\255\158\162\151\255\158\162\151\255\006\007\000\255\006\007\000\255\153\155\146\255\153\155\146\255\221\230\216\255\221\230\216\255\000\009\000\255\000\009\000\255\207\240\201\255\207\240\201\255\202\246\193\255\202\246\193\255\206\249\196\255\206\249\196\255\213\250\203\255\213\250\203\255\214\239\207\255\214\239\207\255\000\009\000\255\000\009\000\255\000\007\000\255\000\007\000\255\216\239\210\255\216\239\210\255\218\239\211\255\218\239\211\255\226\243\219\255\226\243\219\255\000\005\000\255\000\005\000\255\158\162\151\255\158\162\151\255\006\007\000\255\006\007\000\255\153\155\146\255\153\155\146\255\221\230\216\255\221\230\216\255\000\009\000\255\000\009\000\255\207\240\201\255\207\240\201\255\202\246\193\255\202\246\193\255\206\249\196\255\206\249\196\255\213\250\203\255\213\250\203\255\214\239\207\255\214\239\207\255\000\009\000\255\000\009\000\255\000\009\000\255\000\009\000\255\211\241\202\255\211\241\202\255\215\243\206\255\215\243\206\255\000\006\000\255\000\006\000\255\000\002\000\255\000\002\000\255\156\155\148\255\156\155\148\255\005\003\003\255\005\003\003\255\228\231\232\255\228\231\232\255\149\163\151\255\149\163\151\255\000\010\000\255\000\010\000\255\208\251\202\255\208\251\202\255\202\254\192\255\202\254\192\255\203\252\194\255\203\252\194\255\209\249\202\255\209\249\202\255\214\241\208\255\214\241\208\255\000\009\000\255\000\009\000\255\000\009\000\255\000\009\000\255\211\241\202\255\211\241\202\255\215\243\206\255\215\243\206\255\000\006\000\255\000\006\000\255\000\002\000\255\000\002\000\255\156\155\148\255\156\155\148\255\005\003\003\255\005\003\003\255\228\231\232\255\228\231\232\255\149\163\151\255\149\163\151\255\000\010\000\255\000\010\000\255\208\251\202\255\208\251\202\255\202\254\192\255\202\254\192\255\203\252\194\255\203\252\194\255\209\249\202\255\209\249\202\255\214\241\208\255\214\241\208\255\000\009\000\255\000\009\000\255\000\008\000\255\000\008\000\255\214\239\209\255\214\239\209\255\223\244\218\255\223\244\218\255\000\014\000\255\000\014\000\255\155\162\147\255\155\162\147\255\000\000\000\255\000\000\000\255\000\004\000\255\000\004\000\255\000\004\000\255\000\004\000\255\000\009\000\255\000\009\000\255\196\238\196\255\196\238\196\255\202\254\197\255\202\254\197\255\199\255\190\255\199\255\190\255\201\253\194\255\201\253\194\255\208\250\203\255\208\250\203\255\213\241\209\255\213\241\209\255\000\008\000\255\000\008\000\255\000\008\000\255\000\008\000\255\214\239\209\255\214\239\209\255\223\244\218\255\223\244\218\255\000\014\000\255\000\014\000\255\155\162\147\255\155\162\147\255\000\000\000\255\000\000\000\255\000\004\000\255\000\004\000\255\000\004\000\255\000\004\000\255\000\009\000\255\000\009\000\255\196\238\196\255\196\238\196\255\202\254\197\255\202\254\197\255\199\255\190\255\199\255\190\255\201\253\194\255\201\253\194\255\208\250\203\255\208\250\203\255\213\241\209\255\213\241\209\255\000\008\000\255\000\008\000\255\000\006\000\255\000\006\000\255\223\235\226\255\223\235\226\255\000\004\000\255\000\004\000\255\001\001\000\255\001\001\000\255\153\158\146\255\153\158\146\255\000\007\000\255\000\007\000\255\226\254\217\255\226\254\217\255\211\253\206\255\211\253\206\255\204\253\201\255\204\253\201\255\202\254\200\255\202\254\200\255\200\255\194\255\200\255\194\255\200\255\191\255\200\255\191\255\202\252\195\255\202\252\195\255\208\250\204\255\208\250\204\255\214\242\211\255\214\242\211\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\223\235\226\255\223\235\226\255\000\004\000\255\000\004\000\255\001\001\000\255\001\001\000\255\153\158\146\255\153\158\146\255\000\007\000\255\000\007\000\255\226\254\217\255\226\254\217\255\211\253\206\255\211\253\206\255\204\253\201\255\204\253\201\255\202\254\200\255\202\254\200\255\200\255\194\255\200\255\194\255\200\255\191\255\200\255\191\255\202\252\195\255\202\252\195\255\208\250\204\255\208\250\204\255\214\242\211\255\214\242\211\255\000\007\000\255\000\007\000\255\000\004\000\255\000\004\000\255\230\232\238\255\230\232\238\255\005\000\011\255\005\000\011\255\165\157\167\255\165\157\167\255\000\005\000\255\000\005\000\255\000\015\000\255\000\015\000\255\212\255\198\255\212\255\198\255\194\253\180\255\194\253\180\255\195\255\187\255\195\255\187\255\196\255\193\255\196\255\193\255\198\255\192\255\198\255\192\255\201\255\192\255\201\255\192\255\204\252\196\255\204\252\196\255\209\249\204\255\209\249\204\255\214\242\211\255\214\242\211\255\000\007\000\255\000\007\000\255\000\004\000\255\000\004\000\255\230\232\238\255\230\232\238\255\005\000\011\255\005\000\011\255\165\157\167\255\165\157\167\255\000\005\000\255\000\005\000\255\000\015\000\255\000\015\000\255\212\255\198\255\212\255\198\255\194\253\180\255\194\253\180\255\195\255\187\255\195\255\187\255\196\255\193\255\196\255\193\255\198\255\192\255\198\255\192\255\201\255\192\255\201\255\192\255\204\252\196\255\204\252\196\255\209\249\204\255\209\249\204\255\214\242\211\255\214\242\211\255\000\007\000\255\000\007\000\255\000\004\000\255\000\004\000\255\230\232\236\255\230\232\236\255\006\003\012\255\006\003\012\255\162\160\165\255\162\160\165\255\000\010\000\255\000\010\000\255\213\245\204\255\213\245\204\255\204\252\190\255\204\252\190\255\195\255\179\255\195\255\179\255\194\255\184\255\194\255\184\255\195\255\191\255\195\255\191\255\197\255\192\255\197\255\192\255\201\255\192\255\201\255\192\255\204\252\196\255\204\252\196\255\209\249\203\255\209\249\203\255\214\242\211\255\214\242\211\255\000\007\000\255\000\007\000\255\000\004\000\255\000\004\000\255\230\232\236\255\230\232\236\255\006\003\012\255\006\003\012\255\162\160\165\255\162\160\165\255\000\010\000\255\000\010\000\255\213\245\204\255\213\245\204\255\204\252\190\255\204\252\190\255\195\255\179\255\195\255\179\255\194\255\184\255\194\255\184\255\195\255\191\255\195\255\191\255\197\255\192\255\197\255\192\255\201\255\192\255\201\255\192\255\204\252\196\255\204\252\196\255\209\249\203\255\209\249\203\255\214\242\211\255\214\242\211\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\217\238\216\255\217\238\216\255\000\007\000\255\000\007\000\255\000\013\000\255\000\013\000\255\000\013\000\255\000\013\000\255\197\243\189\255\197\243\189\255\198\254\188\255\198\254\188\255\193\255\181\255\193\255\181\255\193\255\185\255\193\255\185\255\193\255\189\255\193\255\189\255\195\255\189\255\195\255\189\255\198\255\189\255\198\255\189\255\201\253\194\255\201\253\194\255\207\250\203\255\207\250\203\255\213\243\211\255\213\243\211\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\217\238\216\255\217\238\216\255\000\007\000\255\000\007\000\255\000\013\000\255\000\013\000\255\000\013\000\255\000\013\000\255\197\243\189\255\197\243\189\255\198\254\188\255\198\254\188\255\193\255\181\255\193\255\181\255\193\255\185\255\193\255\185\255\193\255\189\255\193\255\189\255\195\255\189\255\195\255\189\255\198\255\189\255\198\255\189\255\201\253\194\255\201\253\194\255\207\250\203\255\207\250\203\255\213\243\211\255\213\243\211\255\000\007\000\255\000\007\000\255\000\010\000\255\000\010\000\255\201\245\189\255\201\245\189\255\197\253\185\255\197\253\185\255\192\255\182\255\192\255\182\255\194\255\186\255\194\255\186\255\196\255\190\255\196\255\190\255\195\255\189\255\195\255\189\255\193\255\187\255\193\255\187\255\194\255\188\255\194\255\188\255\195\255\189\255\195\255\189\255\195\255\187\255\195\255\187\255\196\255\187\255\196\255\187\255\199\254\193\255\199\254\193\255\205\251\203\255\205\251\203\255\212\243\212\255\212\243\212\255\000\007\000\255\000\007\000\255\000\010\000\255\000\010\000\255\201\245\189\255\201\245\189\255\197\253\185\255\197\253\185\255\192\255\182\255\192\255\182\255\194\255\186\255\194\255\186\255\196\255\190\255\196\255\190\255\195\255\189\255\195\255\189\255\193\255\187\255\193\255\187\255\194\255\188\255\194\255\188\255\195\255\189\255\195\255\189\255\195\255\187\255\195\255\187\255\196\255\187\255\196\255\187\255\199\254\193\255\199\254\193\255\205\251\203\255\205\251\203\255\212\243\212\255\212\243\212\255\000\007\000\255\000\007\000\255\000\010\000\255\000\010\000\255\201\245\186\255\201\245\186\255\194\250\178\255\194\250\178\255\198\255\184\255\198\255\184\255\197\253\186\255\197\253\186\255\206\254\198\255\206\254\198\255\207\252\201\255\207\252\201\255\207\252\202\255\207\252\202\255\208\251\202\255\208\251\202\255\209\251\201\255\209\251\201\255\208\252\200\255\208\252\200\255\208\252\199\255\208\252\199\255\210\249\203\255\210\249\203\255\214\247\210\255\214\247\210\255\218\241\216\255\218\241\216\255\000\006\000\255\000\006\000\255\000\010\000\255\000\010\000\255\201\245\186\255\201\245\186\255\194\250\178\255\194\250\178\255\198\255\184\255\198\255\184\255\197\253\186\255\197\253\186\255\206\254\198\255\206\254\198\255\207\252\201\255\207\252\201\255\207\252\202\255\207\252\202\255\208\251\202\255\208\251\202\255\209\251\201\255\209\251\201\255\208\252\200\255\208\252\200\255\208\252\199\255\208\252\199\255\210\249\203\255\210\249\203\255\214\247\210\255\214\247\210\255\218\241\216\255\218\241\216\255\000\006\000\255\000\006\000\255\000\008\000\255\000\008\000\255\000\009\000\255\000\009\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\006\000\255\009\015\002\255\009\015\002\255\000\008\000\255\000\008\000\255\000\009\000\255\000\009\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\007\000\255\000\006\000\255\000\006\000\255\000\006\000\255\000\006\000\255\009\015\002\255\009\015\002\255"

    droppedWeaponTexture =
        draw.CreateTextureRGBA(
            pixels,
            32,
            32
        )

    return droppedWeaponTexture
end
local function DrawDroppedWeaponIcon(px, py)
    local texture = GetDroppedWeaponTexture()
    if not texture then return end

    local half = math.max(5, math.floor(config.icon_size + 0.5))

    draw.TexturedRect(
        texture,
        math.floor(px - half),
        math.floor(py - half),
        math.floor(px + half),
        math.floor(py + half)
    )
end

local function IsPickupInsideRadar(px, py, x, y, size)
    if config.radar_shape == 1 then
        local cx = x + size / 2
        local cy = y + size / 2
        local radius =
            math.max(0, size / 2 - config.icon_size)

        local dx = px - cx
        local dy = py - cy
        return dx * dx + dy * dy <= radius * radius
    end

    local pad = config.icon_size
    return px >= x + pad
        and px <= x + size - pad
        and py >= y + pad
        and py <= y + size - pad
end

local function DrawDroppedWeapons(plocal)
    if not config.dropped_weapons then return end

    local size, x, y = config.size, config.x, config.y
    local cx, cy = x + size / 2, y + size / 2

    local localPos = plocal:GetAbsOrigin()
    if not localPos then return end

    local viewAngles = engine.GetViewAngles()
    local yaw = math.rad(viewAngles.y - 90)
    local cosYaw, sinYaw = cos(-yaw), sin(-yaw)

    for _, weapon in pairs(droppedWeaponCache) do
        local dx = weapon.x - localPos.x
        local dy = weapon.y - localPos.y
        local rx = dx * cosYaw - dy * sinYaw
        local ry = dx * sinYaw + dy * cosYaw

        local px =
            cx + rx * config.zoom
        local py =
            cy - ry * config.zoom

        if IsPickupInsideRadar(px, py, x, y, size) then
            DrawDroppedWeaponIcon(px, py)
        end
    end
end

local function DrawAmmoBoxes(plocal)
    if not config.ammo_boxes then return end

    local size, x, y = config.size, config.x, config.y
    local cx, cy = x + size / 2, y + size / 2

    local localPos = plocal:GetAbsOrigin()
    if not localPos then return end

    local viewAngles = engine.GetViewAngles()
    local yaw = math.rad(viewAngles.y - 90)
    local cosYaw, sinYaw = cos(-yaw), sin(-yaw)

    for _, box in pairs(ammoBoxCache) do
        local dx = box.x - localPos.x
        local dy = box.y - localPos.y
        local rx = dx * cosYaw - dy * sinYaw
        local ry = dx * sinYaw + dy * cosYaw

        local px =
            cx + rx * config.zoom
        local py =
            cy - ry * config.zoom

        if IsPickupInsideRadar(px, py, x, y, size) then
            DrawAmmoBoxIcon(px, py, box.size)
        end
    end
end

local function DrawHealthKits(plocal, now)
    if not config.healthkits then return end

    local size, x, y = config.size, config.x, config.y
    local cx, cy = x + size / 2, y + size / 2

    local localPos = plocal:GetAbsOrigin()
    if not localPos then return end

    local viewAngles = engine.GetViewAngles()
    local yaw = math.rad(viewAngles.y - 90)
    local cosYaw, sinYaw = cos(-yaw), sin(-yaw)

    for _, kit in pairs(healthKitCache) do
        local dx = kit.x - localPos.x
        local dy = kit.y - localPos.y
        local rx = dx * cosYaw - dy * sinYaw
        local ry = dx * sinYaw + dy * cosYaw

        local px =
            cx + rx * config.zoom
        local py =
            cy - ry * config.zoom

        if IsPickupInsideRadar(px, py, x, y, size) then
            DrawHealthKitIcon(px, py, kit.size)
        end
    end
end

local function DrawRadarEntities(plocal, now)
    local size, x, y = config.size, config.x, config.y
    local cx, cy = x + size / 2, y + size / 2
    local localPos = plocal:GetAbsOrigin()
    if not localPos then return end

    local viewAngles = engine.GetViewAngles()
    local yaw = math.rad(viewAngles.y - 90)
    local cosYaw, sinYaw = cos(-yaw), sin(-yaw)
    local localIndex = plocal:GetIndex()
    local localTeam = plocal:GetTeamNumber()

    updateRadarGuiColors(now)
    local targetIndex = getAimbotTargetIndex(now)

    local oldBlend = 1.0
    local oldR, oldG, oldB = 1.0, 1.0, 1.0

    if render.GetBlend then
        local ok, value = pcall(render.GetBlend)
        if ok and type(value) == "number" then oldBlend = value end
    end

    if render.GetColorModulation then
        local ok, r, g, b = pcall(render.GetColorModulation)
        if ok then
            oldR, oldG, oldB = r or 1.0, g or 1.0, b or 1.0
        end
    end

    if render.SetBlend then pcall(render.SetBlend, 1.0) end
    if render.SetColorModulation then
        pcall(render.SetColorModulation, 1.0, 1.0, 1.0)
    end

    for _, building in pairs(buildingCache) do
        if not (config.enemy_only and building.team == localTeam) then
            local dx, dy =
                building.x - localPos.x,
                building.y - localPos.y
            local rx = dx * cosYaw - dy * sinYaw
            local ry = dx * sinYaw + dy * cosYaw
            local px, py = ClampRadarPosition(
                cx + rx * config.zoom,
                cy - ry * config.zoom,
                x, y, size
            )

            local iconColor =
                building.ownerIndex == localIndex
                and colors.border
                or getRadarTeamColor(building.team)

            local iconKind = building.kind
            if iconKind == "teleporter" then
                iconKind =
                    building.objectMode == 1
                    and "teleporter_exit"
                    or "teleporter_entrance"
            end

            DrawBuildingIcon(
                iconKind,
                building.level,
                building.team,
                iconColor,
                now,
                px,
                py
            )
            DrawRadarHealthbar(
                px,
                py,
                building.health,
                building.maxHealth,
                false
            )
        end
    end

    for index, player in pairs(playerCache) do
        if index ~= localIndex
            and not (config.enemy_only and player.team == localTeam) then

            local dx, dy =
                player.x - localPos.x,
                player.y - localPos.y
            local rx = dx * cosYaw - dy * sinYaw
            local ry = dx * sinYaw + dy * cosYaw
            local px, py = ClampRadarPosition(
                cx + rx * config.zoom,
                cy - ry * config.zoom,
                x, y, size
            )

            local frameColor =
                targetIndex ~= nil and index == targetIndex
                and radarGuiColors.target
                or getRadarTeamColor(player.team)

            DrawRadarIconBlockBackground(px, py, frameColor)
            DrawPlayerIcon(
                player.className,
                player.team,
                now,
                px,
                py
            )
            DrawRadarHealthbar(
                px,
                py,
                player.health,
                player.maxHealth,
                true
            )
        end
    end

    DrawRadarIconBlockBackground(cx, cy, colors.border)

    local localClass =
        classNames[plocal:GetPropInt("m_iClass")]
        or "scout"

    DrawPlayerIcon(
        localClass,
        localTeam,
        now,
        cx,
        cy
    )

    local localHealth, localMaxHealth =
        GetCachedHealth(plocal)

    DrawRadarHealthbar(
        cx,
        cy,
        localHealth,
        localMaxHealth,
        true
    )

    if render.SetColorModulation then
        pcall(render.SetColorModulation, oldR, oldG, oldB)
    end
    if render.SetBlend then pcall(render.SetBlend, oldBlend) end
end

local function Draw()
    syncRadarConfig()

    if _G.NC_COMBINED_STATE
        and _G.NC_COMBINED_STATE.radarEnabled == false then
        return
    end

    if NC_IsTakingCleanScreenshot() then
        return
    end

    if engine.Con_IsVisible() then return end

    local luaMenuOpen = _G.NC_COMBINED_STATE
        and _G.NC_COMBINED_STATE.luaMenuOpen == true

    if engine.IsGameUIVisible() and not luaMenuOpen then
        return
    end

    local plocal = entities.GetLocalPlayer()
    if not plocal or not plocal:IsAlive() then
        return
    end

    local now = globals.RealTime()

    updatePlayerCache(now)

    if now >= nextIconPreload then
        nextIconPreload = now + ICON_PRELOAD_INTERVAL

        if config.icon_style == 2 then
            preloadStyle2Icons(now)
        else
            preloadStyle1Icons(now)
        end
    end

    DrawBackground()

    if config.dropped_weapons
        or config.ammo_boxes
        or config.healthkits then
        draw.Color(255, 255, 255, 255)
        DrawDroppedWeapons(plocal)
        DrawAmmoBoxes(plocal)
        DrawHealthKits(plocal, now)
    end

    DrawRadarEntities(plocal, now)
end

NC_CALLBACKS.radarDraw = Draw
NC_CALLBACKS.radarUnload = function()
    if healthKitTexture then
        pcall(draw.DeleteTexture, healthKitTexture)
        healthKitTexture = nil
    end
    if ammoBoxTexture then
        pcall(draw.DeleteTexture, ammoBoxTexture)
        ammoBoxTexture = nil
    end
    if droppedWeaponTexture then
        pcall(draw.DeleteTexture, droppedWeaponTexture)
        droppedWeaponTexture = nil
    end
end
end

do

pcall(function()
    gui.SetValue("Crit Hack Indicator Size", 0)
end)

local FONT = draw.CreateFont("Tahoma", 10, 400)

local PANEL_CONFIG = {
    x = NC_CONFIG.INFO_X,
    y = NC_CONFIG.INFO_Y,
    scale = NC_CONFIG.INFO_SCALE,
    width = NC_CONFIG.INFO_WIDTH,
}

local CRIT_CONFIG = {
    x = NC_CONFIG.CRIT_X,
    y = NC_CONFIG.CRIT_Y,
    scale = NC_CONFIG.CRIT_SCALE,
}
local CRIT_BUCKET_CAP = 1000
local MIN_SECONDARY_PROGRESS = 16 / 60

local INFO_UPDATE_INTERVAL = 0.10
local CRIT_SETTINGS_UPDATE_INTERVAL = 0.25

local guiGetValue = gui.GetValue
local isButtonDown = input.IsButtonDown
local getMousePos = input.GetMousePos
local realTime = globals.RealTime
local mathFloor = math.floor
local mathAbs = math.abs
local mathMax = math.max
local mathSqrt = math.sqrt
local stringLower = string.lower
local stringFind = string.find
local stringSub = string.sub
local stringFormat = string.format

local critIconDir = "nc"

if filesystem and filesystem.CreateDirectory then
    local ok, first, second =
        pcall(filesystem.CreateDirectory, "nc")

    if ok then
        local fullPath =
            type(second) == "string" and second
            or type(first) == "string" and first
            or nil

        if fullPath and fullPath ~= "" then
            critIconDir = fullPath
        end
    end
end

local function critIconPath(fileName)
    local tail = string.sub(critIconDir, -1)

    if tail == "\\" or tail == "/" then
        return critIconDir .. fileName
    end

    return critIconDir .. "\\" .. fileName
end

local critIconPaths = {
    crits = critIconPath("crits.png"),
    noCrits = critIconPath("no_crits.png"),
}

local critIconState = {
    crits = false,
    noCrits = false,
    nextCheck = 0,
    warned = false,
}

local function fileExists(path)
    local file = io.open(path, "rb")

    if not file then
        return false
    end

    file:close()
    return true
end

local function checkCritIcons(force)
    local now = realTime()

    if not force and now < critIconState.nextCheck then
        return
    end

    critIconState.nextCheck = now + 5
    critIconState.crits = fileExists(critIconPaths.crits)
    critIconState.noCrits = fileExists(critIconPaths.noCrits)

    if not critIconState.crits
        or not critIconState.noCrits then

        if not critIconState.warned then
            print(
                "You need to install the icons: https://github.com/botsetes/icons_ithink"
            )
            print(
                "Place crits.png and no_crits.png in Team Fortress 2\\nc"
            )
            critIconState.warned = true
        end
    end
end

checkCritIcons(true)

local function SaveConfig()
    NC_CONFIG.INFO_X = PANEL_CONFIG.x
    NC_CONFIG.INFO_Y = PANEL_CONFIG.y
    NC_CONFIG.INFO_SCALE = PANEL_CONFIG.scale
    NC_CONFIG.INFO_WIDTH = PANEL_CONFIG.width

    NC_CONFIG.CRIT_X = CRIT_CONFIG.x
    NC_CONFIG.CRIT_Y = CRIT_CONFIG.y
    NC_CONFIG.CRIT_SCALE = CRIT_CONFIG.scale

    NC_SaveConfig()
end

local dragData = {
    activePanel = nil,
    isMouseDown = false,
    downX = 0,
    downY = 0,
    startBoxX = 0,
    startBoxY = 0,
    isDragging = false,
    threshold = 4,
}

local critTexture = nil
local noCritsTexture = nil

local function createTexture(path)
    local ok, texture =
        pcall(draw.CreateTexture, path)

    if ok then
        return texture
    end

    return nil
end

local function getCritTexture(canRandomCrit)
    checkCritIcons(false)

    if canRandomCrit then
        if not critTexture and critIconState.crits then
            critTexture =
                createTexture(critIconPaths.crits)
        end

        return critTexture
    end

    if not noCritsTexture and critIconState.noCrits then
        noCritsTexture =
            createTexture(critIconPaths.noCrits)
    end

    return noCritsTexture
end

local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function ClampToScreen(x, y, w, h)
    local sw, sh = draw.GetScreenSize()
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    if x + w > sw then x = sw - w end
    if y + h > sh then y = sh - h end
    return x, y
end

local function DrawInfoOutlinedText(x, y, r, g, b, a, text)
    draw.Color(0, 0, 0, 200)
    draw.Text(x + 1, y + 1, text)
    draw.Color(r, g, b, a)
    draw.Text(x, y, text)
end

local maxSpeedRecorded = 0.0
local lastMap = ""

local function getPlayerSpeeds(player)
    local currentMap = (engine.GetMapName and engine.GetMapName()) or ""
    if currentMap ~= lastMap then
        lastMap = currentMap
        maxSpeedRecorded = 0.0
    end

    if not player then
        return "0.0", stringFormat("%.1f", maxSpeedRecorded)
    end

    local vel = player:EstimateAbsVelocity()
    if not vel then
        return "0.0", stringFormat("%.1f", maxSpeedRecorded)
    end

    local currentSpeed = mathSqrt(vel.x * vel.x + vel.y * vel.y)
    if currentSpeed > maxSpeedRecorded then
        maxSpeedRecorded = currentSpeed
    end

    return stringFormat("%.1f", currentSpeed), stringFormat("%.1f", maxSpeedRecorded)
end

local function hasAssignedKey(keyVal)
    return keyVal ~= nil
        and keyVal ~= 0
        and keyVal ~= "NONE"
        and keyVal ~= "None"
        and keyVal ~= ""
end

local function getFeatureState(enabledName, keyName, modeName, isFakeLag)
    local enabled = guiGetValue(enabledName)
    local keyVal = keyName and guiGetValue(keyName) or 0
    local hasKey = hasAssignedKey(keyVal)

    local isHold = false
    if modeName then
        local modeVal = guiGetValue(modeName)
        isHold = modeVal == 0 or modeVal == "0"
        if not isHold and type(modeVal) == "string" then
            isHold = stringFind(stringLower(modeVal), "hold", 1, true) ~= nil
        end
    end

    if not enabled or enabled == 0 then
        if hasKey and (isFakeLag or (modeName and not isHold)) then
            return "Inactive"
        end
        return "Disabled"
    end

    if not hasKey then return "Active" end
    if modeName and not isHold then return "Active" end
    if isFakeLag then return "Active" end

    return isButtonDown(keyVal) and "Active" or "Inactive"
end

local function getPingReducerState(enabledName, targetName)
    local enabled = guiGetValue(enabledName)
    if not enabled or enabled == 0 then return "Disabled" end

    local targetVal = guiGetValue(targetName)
    if not targetVal then return "Active" end
    return tostring(mathFloor(targetVal))
end

local INFO_ITEMS = {
    {"Speed:", "0.0"},
    {"Max Speed:", "0.0"},
    {"Aim Bot:", "Disabled"},
    {"Trigger Bot:", "Disabled"},
    {"Fake Lag:", "Disabled"},
    {"Anti Aim:", "Disabled"},
    {"Resolver:", "Disabled"},
    {"Clean Screenshots:", "Disabled"},
    {"Ping Reducer:", "Disabled"},
}

local nextInfoUpdate = 0

local function updateInfoItems(player, now)
    if now < nextInfoUpdate then return end
    nextInfoUpdate = now + INFO_UPDATE_INTERVAL

    local currentSpeed, maxSpeed = getPlayerSpeeds(player)
    INFO_ITEMS[1][2] = currentSpeed
    INFO_ITEMS[2][2] = maxSpeed
    INFO_ITEMS[3][2] = getFeatureState("aim bot", "aim key", "aim key mode")
    INFO_ITEMS[4][2] = getFeatureState("trigger shoot", "trigger key", "trigger key mode")
    INFO_ITEMS[5][2] = getFeatureState("Fake Lag", "Fake Lag Key", nil, true)
    INFO_ITEMS[6][2] = getFeatureState("anti aim", "anti aim key", "anti aim key mode")
    INFO_ITEMS[7][2] = getFeatureState("aim resolver", nil)
    INFO_ITEMS[8][2] = guiGetValue("Clean Screenshots") == 1 and "Active" or "Disabled"
    INFO_ITEMS[9][2] = getPingReducerState("ping reducer", "ping reducer target (ms)")
end

local critSettings = {
    nextUpdate = 0,
    forceAlways = false,
    key = 0,
}

local function updateCritSettings(now)
    if now < critSettings.nextUpdate then return end
    critSettings.nextUpdate = now + CRIT_SETTINGS_UPDATE_INTERVAL

    local critMode = guiGetValue("Crit Hack") or guiGetValue("Crithack") or 0
    local critKey = guiGetValue("Crit Hack Key") or guiGetValue("Crit Key") or 0

    critSettings.forceAlways = critMode == 1 or critMode == "Force Always"
    critSettings.key = type(critKey) == "number" and critKey or 0
end

local function getCritHackKeyActive(now)
    updateCritSettings(now)

    if critSettings.forceAlways then
        return true
    end

    if critSettings.key > 0 then
        return isButtonDown(critSettings.key)
    end

    return true
end

local function isKnownNoRandomCritClass(classStr, melee)
    if melee and classStr == "CTFKnife" then return true end
    if classStr == "CTFCompoundBow" then return true end

    return stringSub(classStr, 1, 14) == "CTFSniperRifle"
end

local function hasNoRandomCrits(wpn, classStr, melee)
    if isKnownNoRandomCritClass(classStr, melee) then
        return true
    end

    if wpn.AttributeHookFloat then
        local critMult = wpn:AttributeHookFloat("mult_crit_chance", 1.0)
        if critMult ~= nil and critMult <= 0 then
            return true
        end
    end

    if wpn.CanRandomCrit then
        local canRandomCrit = wpn:CanRandomCrit()
        if canRandomCrit == false then
            return true
        end
    end

    return false
end

local weaponMeta = {
    index = -1,
    classStr = "",
    melee = false,
    noRandomCrits = false,
}

local function updateWeaponMeta(wpn, weaponIndex)
    if weaponIndex == weaponMeta.index then return end

    weaponMeta.index = weaponIndex
    weaponMeta.classStr = (wpn.GetClass and wpn:GetClass()) or ""
    weaponMeta.melee = (wpn.IsMeleeWeapon and wpn:IsMeleeWeapon()) or false
    weaponMeta.noRandomCrits = hasNoRandomCrits(wpn, weaponMeta.classStr, weaponMeta.melee)
end

local critCache = {
    weaponIndex = -1,
    bucket = -1,
    req = -1,
    chk = -1,
    canCrit = false,
    blueProgress = 0,
    secondaryProgress = 0,
    visible = true,
    canRandomCrit = false,
}

local function cacheCritResult(canCrit, blueProgress, secondaryProgress, visible, canRandomCrit)
    critCache.canCrit = canCrit
    critCache.blueProgress = blueProgress
    critCache.secondaryProgress = secondaryProgress
    critCache.visible = visible
    critCache.canRandomCrit = canRandomCrit
end

local function getCritData(player, wpn, now)
    if not wpn or not wpn:IsWeapon() then
        return false, 0, 0, false, true, false
    end

    local isKeyActive = getCritHackKeyActive(now)
    local weaponIndex = wpn:GetIndex() or -1
    local bucket = wpn:GetCritTokenBucket() or 0
    local req = wpn:GetCritSeedRequestCount() or 0
    local chk = wpn:GetCritCheckCount() or 0

    updateWeaponMeta(wpn, weaponIndex)

    if weaponIndex == critCache.weaponIndex
        and bucket == critCache.bucket
        and req == critCache.req
        and chk == critCache.chk then
        return critCache.canCrit,
            critCache.blueProgress,
            critCache.secondaryProgress,
            critCache.visible,
            isKeyActive,
            critCache.canRandomCrit
    end

    critCache.weaponIndex = weaponIndex
    critCache.bucket = bucket
    critCache.req = req
    critCache.chk = chk

    local globalCrit = convarInt and convarInt("tf_weapon_criticals", 1)
        or tonumber(client.GetConVar("tf_weapon_criticals") or 1)

    if globalCrit == 0 then
        cacheCritResult(false, 0, 0, false, false)
        return false, 0, 0, false, false, false
    end

    if weaponMeta.noRandomCrits then
        cacheCritResult(false, 0, 0, false, false)
        return false, 0, 0, false, isKeyActive, false
    end

    if weaponMeta.melee then
        local nextCrit = player:GetPropInt("m_Shared", "m_iNextMeleeCrit")
        if nextCrit == 2 then
            cacheCritResult(true, 1.0, 1.0, true, true)
            return true, 1.0, 1.0, true, isKeyActive, true
        end
    end

    local base = wpn:GetWeaponBaseDamage()
    if not base or base <= 0 then
        local chance = wpn:GetCritChance() or 0
        local canCrit = chance >= 0.15
        cacheCritResult(canCrit, chance, chance, false, true)
        return canCrit, chance, chance, false, isKeyActive, true
    end

    local cost = wpn:GetCritCost(bucket, req, chk)
    if not cost or cost <= 0 then
        local chance = wpn:GetCritChance() or 0
        local canCrit = chance >= 0.15
        cacheCritResult(canCrit, chance, chance, false, true)
        return canCrit, chance, chance, false, isKeyActive, true
    end

    local chance = wpn:GetCritChance() or 0

    local canAffordCrit = bucket >= cost
    local canCrit = canAffordCrit
    local blueProgress = clamp01(bucket / CRIT_BUCKET_CAP)

    local secondaryProgress
    if canCrit then
        secondaryProgress = mathMax(MIN_SECONDARY_PROGRESS, clamp01(1.0 - blueProgress))
        if bucket >= CRIT_BUCKET_CAP then
            secondaryProgress = MIN_SECONDARY_PROGRESS
        end
    elseif cost > 0 then
        secondaryProgress = mathMax(MIN_SECONDARY_PROGRESS, clamp01(bucket / cost))
    else
        secondaryProgress = 1.0
    end

    cacheCritResult(canCrit, blueProgress, secondaryProgress, true, true)
    return canCrit, blueProgress, secondaryProgress, true, isKeyActive, true
end

local function updateDragging(mx, my, mouseDownNow, menuOpen, x, y, w, h, panelName)
    if menuOpen then
        local inBox = mx >= x and mx <= (x + w) and my >= y and my <= (y + h)

        if mouseDownNow and not dragData.isMouseDown and inBox and not dragData.activePanel then
            dragData.isMouseDown = true
            dragData.activePanel = panelName
            dragData.downX, dragData.downY = mx, my
            dragData.startBoxX, dragData.startBoxY = x, y
            dragData.isDragging = false
        end

        if mouseDownNow and dragData.isMouseDown and dragData.activePanel == panelName then
            local dx = mx - dragData.downX
            local dy = my - dragData.downY

            if not dragData.isDragging and (mathAbs(dx) > dragData.threshold or mathAbs(dy) > dragData.threshold) then
                dragData.isDragging = true
            end

            if dragData.isDragging then
                return ClampToScreen(dragData.startBoxX + dx, dragData.startBoxY + dy, w, h)
            end
        end
    end

    if not mouseDownNow and dragData.isMouseDown and dragData.activePanel == panelName then
        dragData.isMouseDown = false
        dragData.activePanel = nil
        dragData.isDragging = false
        SaveConfig()
    end

    return x, y
end

local infoMetricsReady = false
local titleWidth = 0
local titleHeight = 0
local INFO_LABEL_WIDTHS = {}

local function ensureInfoMetrics()
    if infoMetricsReady then return end

    titleWidth, titleHeight = draw.GetTextSize("Info Panel")
    for i = 1, #INFO_ITEMS do
        INFO_LABEL_WIDTHS[i] = draw.GetTextSize(INFO_ITEMS[i][1])
    end

    infoMetricsReady = true
end

local function drawInfoPanel(mx, my, mouseDown, lmaoboxMenuOpen, player, now)
    updateInfoItems(player, now)
    ensureInfoMetrics()

    local rowH = 16
    local totalW = mathFloor(PANEL_CONFIG.width * PANEL_CONFIG.scale)
    local totalH = rowH + (#INFO_ITEMS * rowH)

    PANEL_CONFIG.x, PANEL_CONFIG.y = updateDragging(
        mx, my, mouseDown, lmaoboxMenuOpen,
        PANEL_CONFIG.x, PANEL_CONFIG.y,
        totalW, totalH,
        "info"
    )

    local x, y = PANEL_CONFIG.x, PANEL_CONFIG.y

    draw.Color(16, 16, 20, 51)
    draw.FilledRect(x, y, x + totalW, y + totalH)

    draw.Color(62, 130, 115, 255)
    draw.OutlinedRect(x, y, x + totalW, y + totalH)

    DrawInfoOutlinedText(
        x + mathFloor((totalW - titleWidth) / 2),
        y + mathFloor((rowH - titleHeight) / 2),
        255, 255, 255, 255,
        "Info Panel"
    )

    draw.Color(62, 130, 115, 255)
    draw.Line(x, y + rowH, x + totalW, y + rowH)

    local currY = y + rowH
    for i = 1, #INFO_ITEMS do
        local item = INFO_ITEMS[i]
        local startTextX = x + 4
        local textY = currY + 3

        DrawInfoOutlinedText(startTextX, textY, 210, 210, 210, 255, item[1])
        DrawInfoOutlinedText(startTextX + INFO_LABEL_WIDTHS[i] + 6, textY, 210, 210, 210, 255, item[2])

        currY = currY + rowH
        draw.Color(62, 130, 115, 255)
        draw.Line(x, currY, x + totalW, currY)
    end
end

local function drawCritPanel(mx, my, mouseDown, lmaoboxMenuOpen, player, weapon, now)
    local canCrit, blueProgress, greenProgress, _, isKeyActive, canRandomCrit = getCritData(player, weapon, now)

    local boxSize = mathFloor(50 * CRIT_CONFIG.scale)
    local barH = mathFloor(6 * CRIT_CONFIG.scale)
    local totalH = boxSize + barH

    CRIT_CONFIG.x, CRIT_CONFIG.y = updateDragging(
        mx, my, mouseDown, lmaoboxMenuOpen,
        CRIT_CONFIG.x, CRIT_CONFIG.y,
        boxSize, totalH,
        "crit"
    )

    local x, y = CRIT_CONFIG.x, CRIT_CONFIG.y
    local boxR, boxG, boxB

    if canRandomCrit and isKeyActive then
        boxR, boxG, boxB = 122, 66, 102
    else
        boxR, boxG, boxB = 62, 130, 115
    end

    draw.Color(boxR, boxG, boxB, 255)
    draw.OutlinedRect(x, y, x + boxSize, y + boxSize)

    draw.Color(20, 20, 25, 230)
    draw.FilledRect(x + 1, y + 1, x + boxSize - 1, y + boxSize - 1)

    local tex = getCritTexture(canRandomCrit)
    if tex then
        if not canRandomCrit or not canCrit then
            draw.Color(90, 95, 105, 255)
        else
            draw.Color(255, 150, 50, 255)
        end

        draw.TexturedRect(tex, x, y, x + boxSize, y + boxSize)
    end

    local barY = y + boxSize
    draw.Color(boxR, boxG, boxB, 255)
    draw.OutlinedRect(x, barY, x + boxSize, barY + barH)

    draw.Color(30, 30, 35, 230)
    draw.FilledRect(x + 1, barY + 1, x + boxSize - 1, barY + barH - 1)

    local innerX = x + 1
    local innerY = barY + 1
    local innerW = boxSize - 2
    local innerH = barH - 2

    if not canRandomCrit then
        draw.Color(75, 80, 90, 255)
        draw.FilledRect(innerX, innerY, innerX + innerW, innerY + innerH)
        return
    end

    local blueFillW = mathFloor(innerW * (blueProgress or 0))
    if blueFillW > 0 then
        draw.Color(40, 140, 250, 255)
        draw.FilledRect(innerX, innerY, innerX + blueFillW, innerY + innerH)
    end

    local remainingW = innerW - blueFillW
    local greenFillW = mathFloor(remainingW * (greenProgress or 0))

    if canCrit and greenFillW < 2 then
        greenFillW = math.min(2, innerW)
    end

    if greenFillW <= 0 then return end

    if canCrit then
        draw.Color(118, 226, 138, 255)
    else
        draw.Color(230, 40, 40, 255)
    end

    local greenX
    if canCrit and remainingW < greenFillW then
        greenX = innerX + innerW - greenFillW
    else
        greenX = innerX + blueFillW
    end

    draw.FilledRect(
        greenX,
        innerY,
        math.min(innerX + innerW, greenX + greenFillW),
        innerY + innerH
    )
end

local function onDraw()
    if engine.Con_IsVisible() then return end

    local luaMenuOpen = _G.NC_COMBINED_STATE
        and _G.NC_COMBINED_STATE.luaMenuOpen == true

    if engine.IsGameUIVisible() and not luaMenuOpen then return end
    if NC_IsTakingCleanScreenshot() then return end

    draw.SetFont(FONT)

    local now = realTime()
    local mx, my = 0, 0
    local mouseDown = false

    if luaMenuOpen then
        local mousePos = getMousePos()
        mx, my = mousePos[1], mousePos[2]
        mouseDown = isButtonDown(MOUSE_LEFT)
    end

    local player = entities.GetLocalPlayer()

    local sharedCritScale = tonumber(
        _G.NC_COMBINED_STATE
        and _G.NC_COMBINED_STATE.critScale
        or NC_CONFIG.CRIT_SCALE
    ) or 0

    if sharedCritScale < 0 then sharedCritScale = 0 end
    if sharedCritScale > 9 then sharedCritScale = 9 end

    CRIT_CONFIG.scale = sharedCritScale

    if not _G.NC_COMBINED_STATE
        or _G.NC_COMBINED_STATE.infoPanelEnabled ~= false then
        drawInfoPanel(mx, my, mouseDown, luaMenuOpen, player, now)
    end

    if not player or not player:IsAlive() then return end

    local weapon = player:GetPropEntity("m_hActiveWeapon")
    if not weapon or not weapon:IsWeapon() then return end

    if (
        not _G.NC_COMBINED_STATE
        or _G.NC_COMBINED_STATE.critIconEnabled ~= false
    ) and CRIT_CONFIG.scale > 0 then
        drawCritPanel(mx, my, mouseDown, luaMenuOpen, player, weapon, now)
    end
end

NC_CALLBACKS.infoCritDraw = onDraw

end

pcall(
    callbacks.Unregister,
    "Draw",
    "nc_master_draw"
)
pcall(
    callbacks.Unregister,
    "SendStringCmd",
    "lmaobox_custom_name_command"
)
pcall(
    callbacks.Unregister,
    "Unload",
    "nc_restore_fov"
)

local function NC_MasterDraw()
    NC_CALLBACKS.menuDraw()
    NC_CALLBACKS.radarDraw()
    NC_CALLBACKS.infoCritDraw()
end

callbacks.Register(
    "Draw",
    "nc_master_draw",
    NC_MasterDraw
)

callbacks.Register(
    "SendStringCmd",
    "lmaobox_custom_name_command",
    NC_CALLBACKS.sendStringCmd
)

callbacks.Register(
    "Unload",
    "nc_restore_fov",
    function()
        NC_CALLBACKS.restoreFovOnUnload()
        NC_CALLBACKS.radarUnload()
    end
)
