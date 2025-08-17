-- =========================
--  VORP Mining – Client
--  (River-Panning + Rocks)
-- =========================

local T = Translation and Translation.Langs and Translation.Langs[Lang] or {}

-- ====== Controls aus Config ======
local KEY_START   = Config.MinePromptKey     -- [SPACE] (0xD9D0E1C0)
local KEY_STOP    = Config.StopMiningKey     -- [F]
local KEY_SWING   = Config.MineRockKey       -- [LMB]

-- ====== Prompt Setup ======
local MinePrompt, MinePromptGroup = nil, GetRandomIntInRange(0, 0xffffff)
local function setupMinePrompt()
    if MinePrompt ~= nil then return end
    MinePrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(MinePrompt, KEY_START)
    UiPromptSetText(MinePrompt, CreateVarString(10, "LITERAL_STRING", T.Prompt and T.Prompt.StartMining or "Start Mining"))
    UiPromptSetEnabled(MinePrompt, false)
    UiPromptSetVisible(MinePrompt, true)
    UiPromptSetHoldMode(MinePrompt, true)
    UiPromptSetGroup(MinePrompt, MinePromptGroup, 0)
    UiPromptRegisterEnd(MinePrompt)
end
setupMinePrompt()

-- ====== Hilfen: Orte & Distanz ======
local function vec3(x,y,z) return vector3(x+0.0, y+0.0, z+0.0) end

local function dist(a, b)
    local dx = a.x - b.x; local dy = a.y - b.y; local dz = (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Town-Restriktionen schnell prüfbar machen
local restrictedTownHash = {}
local function convertConfigTownRestrictionsToHashRegister()
    if not Config.TownRestrictions then return end
    for _, t in ipairs(Config.TownRestrictions) do
        restrictedTownHash[t.name] = not t.mine_allowed
    end
end
convertConfigTownRestrictionsToHashRegister()

local function isInRestrictedTown(_, player_coords)
    -- Falls ihr eine echte Town-Detection habt, hier ersetzen.
    -- Wir nutzen diese Sperre nur rudimentär; River-Zonen ignorieren sie (damit Panning auch außerhalb von Towns klappt).
    return false
end

-- ====== Rock-Scan ======
local allowed_rock_model_hashes = {}
if Config.Rocks and #Config.Rocks > 0 then
    for _, name in ipairs(Config.Rocks) do
        allowed_rock_model_hashes[GetHashKey(name)] = true
    end
end

local function isAllowedRock(entity)
    if entity == 0 then return false end
    local mdl = GetEntityModel(entity)
    return allowed_rock_model_hashes[mdl] == true
end

local function getUnMinedNearbyRock(allowed_hashes, player, player_coords)
    -- Suche in kleinem Radius nach gültigen Rock-Entities
    local handle, entity = FindFirstObject()
    local success
    local closest, closest_dist = nil, 99999.0

    repeat
        if isAllowedRock(entity) then
            local ex, ey, ez = table.unpack(GetEntityCoords(entity))
            local d = dist(player_coords, vec3(ex,ey,ez))
            if d < 3.5 and d < closest_dist then
                closest = { vector_coords = vec3(ex,ey,ez), model_name = tostring(GetEntityModel(entity)), entity = entity }
                closest_dist = d
            end
        end
        success, entity = FindNextObject(handle)
    until not success
    EndFindObject(handle)

    return closest
end

-- ====== River-Panning Support (mehrere coords pro Zone) ======
local function pointInRadius(pt, center, radius)
    local dx = pt.x - center.x; local dy = pt.y - center.y; local dz = (pt.z or 0) - (center.z or 0)
    return (dx*dx + dy*dy + dz*dz) <= (radius * radius)
end

local function getRiverZoneByCoords(coords)
    if not Config.RiverPanningZones then return nil end
    for _,zone in ipairs(Config.RiverPanningZones) do
        if zone.coords then
            if zone.coords.x then
                if pointInRadius(coords, zone.coords, zone.radius or 60.0) then return zone end
            else
                for _,c in ipairs(zone.coords) do
                    if pointInRadius(coords, c, zone.radius or 60.0) then return zone end
                end
            end
        end
    end
    return nil
end

-- ====== Prompt Sichtbarkeit ======
local function manageStartMinePrompt(restricted_towns, player_coords)
    local allowed = not isInRestrictedTown(restricted_towns, player_coords)
    local rz = getRiverZoneByCoords(player_coords or GetEntityCoords(PlayerPedId()))
    UiPromptSetEnabled(MinePrompt, allowed or (rz ~= nil))
end

-- ====== Mining State ======
local nearby_rocks = nil
local isMining = false
local current_is_river = false

-- ====== Events vom Server ======
RegisterNetEvent("vorp_mining:nopickaxe")
AddEventHandler("vorp_mining:nopickaxe", function()
    isMining = false
end)

RegisterNetEvent("vorp_mining:pickaxechecked")
AddEventHandler("vorp_mining:pickaxechecked", function(rock_coords)
    if isMining then return end
    isMining = true

    local swings = math.random(Config.MinSwing or 1, Config.MaxSwing or 3)
    local done = 0

    -- Einfache „Schlag“-Logik: Linksklick zählt, F stoppt
    while isMining and done < swings do
        Wait(0)
        -- Stop?
        if IsControlJustPressed(0, KEY_STOP) then
            isMining = false
            break
        end
        -- Schlag?
        if IsControlJustPressed(0, KEY_SWING) then
            done = done + 1
            -- kleiner Delay pro Schlag
            Wait(400)
        end
    end

    -- Ergebnis an Server schicken
    if done > 0 then
        TriggerServerEvent("vorp_mining:addItem", done)
    end
    isMining = false
end)

-- ====== Haupt-Thread: Rock- und River-Erkennung + Prompt & Start ======
CreateThread(function()
    while true do
        Wait(0)
        local player = PlayerPedId()
        local player_coords = GetEntityCoords(player)

        -- 1) Rocks scannen
        nearby_rocks = getUnMinedNearbyRock(allowed_rock_model_hashes, player, player_coords)
        if not nearby_rocks then
            -- 2) Falls kein Rock: River-Zone erlauben (fake Rock an Spielerposition)
            local rz = getRiverZoneByCoords(player_coords)
            if rz then
                nearby_rocks = { vector_coords = player_coords, model_name = "river", entity = 0 }
                current_is_river = true
            else
                current_is_river = false
            end
        else
            current_is_river = false
        end

        -- Prompt steuern
        if nearby_rocks then
            manageStartMinePrompt(restrictedTownHash, player_coords)
        else
            UiPromptSetEnabled(MinePrompt, false)
        end

        -- Start gedrückt?
        if nearby_rocks and UiPromptHasStandardModeCompleted(MinePrompt) then
            -- an Server schicken: River nutzt Spielerpos, Rocks die Rock-Coords
            local coords = nearby_rocks.vector_coords
            TriggerServerEvent("vorp_mining:pickaxecheck", { x = coords.x, y = coords.y, z = coords.z })
            UiPromptSetEnabled(MinePrompt, false)
        end
    end
end)

-- ====== Optionaler Debug Overlay (falls in Config gesetzt) ======
if Config.Debug then
    local function drawTxt3D(x,y,z, text)
        local onScreen,_x,_y = GetScreenCoordFromWorldCoord(x,y,z)
        if onScreen then
            SetTextScale(0.35, 0.35)
            SetTextFontForCurrentCommand(1)
            SetTextColor(255,255,255,255)
            SetTextCentre(true)
            DisplayText(CreateVarString(10, "LITERAL_STRING", text), _x, _y)
        end
    end

    CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local rz = getRiverZoneByCoords(pos)
            if rz then
                drawTxt3D(pos.x, pos.y, pos.z+1.1, "~e~In River Zone: "..(rz.name or "?"))
            end
            if Config.Mines then
                for _,zn in ipairs(Config.Mines) do
                    local c = zn.coords
                    if c and c.x then
                        drawTxt3D(c.x, c.y, (c.z or 0)+1.0, ("Mine: %s (R=%.1f)"):format(zn.name or "?", zn.radius or 0.0))
                    end
                end
            end
            if Config.RiverPanningZones then
                for _,zn in ipairs(Config.RiverPanningZones) do
                    if zn.coords then
                        if zn.coords.x then
                            drawTxt3D(zn.coords.x, zn.coords.y, (zn.coords.z or 0)+1.0, ("River: %s"):format(zn.name or "?"))
                        else
                            for _,c in ipairs(zn.coords) do
                                drawTxt3D(c.x, c.y, (c.z or 0)+1.0, ("River: %s"):format(zn.name or "?"))
                            end
                        end
                    end
                end
            end
        end
    end)
end
