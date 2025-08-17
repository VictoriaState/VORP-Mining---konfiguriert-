-- ============================
--   VORP Mining – server.lua
-- ============================
local Core = exports.vorp_core:GetCore()
local T = Translation and Translation.Langs and Translation.Langs[Lang] or {}

-- ----------------------------
--  Konfig / Defaults zusammenführen
-- ----------------------------
local TOOL_DEFAULTS = {
  ToolsEnabled = true,
  Tools = {
    -- maxUses = feste Nutzungen pro Item (persistente Haltbarkeit)
    { item = "pickaxe",       type = "pickaxe", tier = 1, maxUses = 150 },
    { item = "pickaxe_steel", type = "pickaxe", tier = 2, maxUses = 150 },
    { item = "shovel",        type = "shovel",  tier = 1, maxUses = 150 },
    { item = "goldpan",       type = "pan",     tier = 1, maxUses = 150 },
    { item = "chisel",        type = "chisel",  tier = 1, maxUses = 150 },
  },
  MineralTools = {
    coal        = { tool = "pickaxe", minTier = 1 },
    iron        = { tool = "pickaxe", minTier = 1 },
    copper      = { tool = "pickaxe", minTier = 1 },
    zinc        = { tool = "pickaxe", minTier = 1 },
    silverore   = { tool = "pickaxe", minTier = 2 },
    goldnugget  = { tool = "pan",     minTier = 1 },
    clay        = { tool = "shovel",  minTier = 1 },
    sand        = { tool = "shovel",  minTier = 1 },
    limestone   = { tool = "pickaxe", minTier = 1 },
    salt        = { tool = "pickaxe", minTier = 1 },
    nitrite     = { tool = "pickaxe", minTier = 1 },
    quartz      = { tool = "pickaxe", minTier = 1 },
    rock        = { tool = "pickaxe", minTier = 1 },
    mercury     = { tool = "pickaxe", minTier = 1 },
    saltstone   = { tool = "pickaxe", minTier = 1 },
    chlorinated_lime = { tool = "pickaxe", minTier = 1 },
    sulfur      = { tool = "pickaxe", minTier = 1 },
  }
}

local function CFG()
  local c = Config or {}
  c.ToolsEnabled = (c.ToolsEnabled ~= false)
  c.Tools = c.Tools or TOOL_DEFAULTS.Tools
  for _,def in ipairs(c.Tools) do
    if not def.maxUses then def.maxUses = 150 end
  end
  c.MineralTools = c.MineralTools or TOOL_DEFAULTS.MineralTools
  return c
end

-- ----------------------------
--  State
-- ----------------------------
local mining_rocks = {}          -- per player: { coords=vec, count=int, river=bool }
local mining_rocks_cooldown = {} -- key-> { time=os.time() }

-- ----------------------------
--  Helpers
-- ----------------------------
local function getKey(coords)
  local x = math.floor(coords.x * 100) / 100
  local y = math.floor(coords.y * 100) / 100
  local z = math.floor(coords.z * 100) / 100
  return string.format("%.2f,%.2f,%.2f", x, y, z)
end

local function vecDist(a, b)
  local dx = a.x - b.x; local dy = a.y - b.y; local dz = (a.z or 0.0) - (b.z or 0.0)
  return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- VORP Character
local function GetChar(src)
  if not Core or not Core.getUser then return nil end
  local User = Core.getUser(src)
  if not User then return nil end
  local C = User.getUsedCharacter
  return {
    id    = C.charIdentifier or C.identifier,
    job   = C.job,
    grade = tonumber(C.jobgrade or C.jobGrade or 0) or 0,
    name  = ((C.firstname or "") .. " " .. (C.lastname or "")):gsub("^%s+",""):gsub("%s+$","")
  }
end

-- Job-Gate (global + zonenspezifisch)
local function HasMiningAccess(char, zone)
  if not char then return false end
  if zone and zone.allowedJobs and type(zone.allowedJobs)=="table" then
    local rule = zone.allowedJobs[char.job]
    if not rule then return false end
    local minG = tonumber(rule.minGrade or 0) or 0
    return (tonumber(char.grade or 0) or 0) >= minG
  end
  if Config.RequireJobToMine then
    local rule = Config.AllowedMiningJobs and Config.AllowedMiningJobs[char.job]
    if not rule then return false end
    local minG = tonumber(rule.minGrade or 0) or 0
    return (tonumber(char.grade or 0) or 0) >= minG
  end
  return true
end

-- Zonen / Minen
local function inZone(coords, zone)
  if not zone or not zone.coords or not zone.radius then return false end
  local dx = coords.x - zone.coords.x
  local dy = coords.y - zone.coords.y
  local dz = (coords.z or 0) - (zone.coords.z or 0)
  return (dx*dx + dy*dy + dz*dz) <= (zone.radius * zone.radius)
end

local function getZoneByCoords(coords)
  if not Config or not Config.Mines then return nil end
  for _,zone in ipairs(Config.Mines) do
    if inZone(coords, zone) then return zone end
  end
  return nil
end

local function getLootTableForCoords(coords)
  local zone = getZoneByCoords(coords)
  if zone and zone.items and #zone.items > 0 then
    return (zone.ChanceRange or Config.ChanceRange or 20), zone.items, zone
  end
  return (Config.ChanceRange or 20), (Config.Items or {}), nil
end

-- River Panning (mehrere Koordinaten pro Zone)
local function pointInRadius(pt, center, radius)
  local dx = pt.x - center.x; local dy = pt.y - center.y; local dz = (pt.z or 0) - (center.z or 0)
  return (dx*dx + dy*dy + dz*dz) <= (radius * radius)
end

local function getRiverZoneByCoords(coords)
  if not Config or not Config.RiverPanningZones then return nil end
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

-- Job-Ertragsmultiplikator
local function getJobYieldMultiplier(zoneName, char)
  if not Config or not Config.JobYieldBonus or not Config.JobYieldBonus.enabled then return 1.0 end
  if not char or (char.job ~= Config.JobYieldBonus.jobName) then return 1.0 end

  local mult = Config.JobYieldBonus.baseMultiplier or 1.0
  local steps = Config.JobYieldBonus.gradeSteps or {}
  for grade, stepMult in pairs(steps) do
    if char.grade >= grade then mult = mult * (stepMult or 1.0) end
  end
  local zm = Config.JobYieldBonus.zoneMultipliers or {}
  if zoneName and zm[zoneName] then mult = mult * zm[zoneName] end
  return mult
end

-- Edelsteine
local function pickGem()
  if not Config or not Config.Gemstones or not Config.Gemstones.table then return nil end
  local list = Config.Gemstones.table
  if #list == 0 then return nil end
  local total = 0
  for _,g in ipairs(list) do total = total + (g.weight or 1) end
  local roll = math.random(1, total)
  local acc = 0
  for _,g in ipairs(list) do
    acc = acc + (g.weight or 1)
    if roll <= acc then return g end
  end
  return list[#list]
end

local function getGemChanceForZone(zoneName)
  if not Config or not Config.Gemstones or not Config.Gemstones.enabled then return 0 end
  if Config.Gemstones.restrictToZones then
    local allowed = Config.Gemstones.allowedZones or {}
    local ok = false
    for _,zn in ipairs(allowed) do if zn == zoneName then ok = true break end end
    if not ok then return 0 end
  end
  local base = Config.Gemstones.baseChancePercent or 0
  local per  = Config.Gemstones.perZoneOverride or {}
  if zoneName and per[zoneName] ~= nil then return per[zoneName] end
  return base
end

-- Inventory helpers
local function canCarry(src, item, amount)
  return exports.vorp_inventory:canCarryItem(src, item, amount)
end

local function giveItem(src, item, amount)
  exports.vorp_inventory:addItem(src, item, amount)
end

-- ----------------------------
--  Events
-- ----------------------------
RegisterNetEvent("vorp_mining:resetTable", function(coords)
  local _source = source
  local st = mining_rocks[_source]
  if st and st.coords and st.coords == coords then
    mining_rocks[_source] = nil
  end
end)

-- Werkzeug prüfen (Client schickt Koords: Rock ODER Spielerpos in Fluss)
RegisterServerEvent("vorp_mining:pickaxecheck", function(rock)
  local _source = source
  local miningrock = rock                  -- {x=..,y=..,z=..} vom Client
  local player_coords = miningrock
  local riverZone = getRiverZoneByCoords(player_coords)

  -- Jobzugriff
  local char = GetChar(_source)
  if not HasMiningAccess(char, riverZone) then
    Core.NotifyObjective(_source, "Dir fehlt die Berechtigung zum Schürfen.", 4000)
    TriggerClientEvent("vorp_mining:nopickaxe", _source)
    return
  end

  -- Spieler bereits an einem Rock?
  if mining_rocks[_source] then return end

  -- Cooldown
  local key = riverZone and getKey(player_coords) or getKey(miningrock)
  if mining_rocks_cooldown[key] then
    Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.Rockoncooldown) or "Hier ist nichts mehr zu holen.", 5000)
    TriggerClientEvent("vorp_mining:nopickaxe", _source)
    return
  end

  -- Werkzeug suchen
  local c = CFG()
  local foundDef, foundItem
  if riverZone then
    for _,def in ipairs(c.Tools) do
      if def.type == "pan" then
        local itm = exports.vorp_inventory:getItem(_source, def.item)
        if itm then foundDef, foundItem = def, itm break end
      end
    end
    if not foundItem then
      TriggerClientEvent("vorp_mining:nopickaxe", _source)
      Core.NotifyObjective(_source, "Du brauchst eine Goldpfanne!", 4000)
      return
    end
  else
    for _,def in ipairs(c.Tools) do
      local itm = exports.vorp_inventory:getItem(_source, def.item)
      if itm then foundDef, foundItem = def, itm break end
    end
    if not foundItem then
      TriggerClientEvent("vorp_mining:nopickaxe", _source)
      Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.notHavePickaxe) or "Du hast kein passendes Werkzeug.", 5000)
      return
    end
  end

  -- Haltbarkeit verringern (persistente usesLeft)
  local meta = foundItem.metadata or {}
  local usesLeft = tonumber(meta.usesLeft or meta.durability or foundDef.maxUses or 150)
  usesLeft = usesLeft - 1

  if usesLeft <= 0 then
    Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.brokePickaxe) or "Dein Werkzeug ist zerbrochen.", 5000)
    exports.vorp_inventory:subItem(_source, foundItem.name or foundDef.item, 1, meta)
    TriggerClientEvent("vorp_mining:nopickaxe", _source)
    return
  else
    local description = ("Haltbarkeit: %d Nutzungen übrig"):format(usesLeft)
    local newmeta = { description = description, usesLeft = usesLeft }
    exports.vorp_inventory:setItemMetadata(_source, foundItem.id, newmeta, 1)
    TriggerClientEvent("vorp_mining:pickaxechecked", _source, riverZone and player_coords or miningrock)
  end

  mining_rocks[_source] = { coords = riverZone and player_coords or miningrock, count = 0, river = riverZone and true or false }
end)

-- Cooldown-Thread
CreateThread(function()
  while true do
    Wait(1000)
    for k, v in pairs(mining_rocks_cooldown) do
      if os.time() - v.time > ((Config.CoolDown or 60) * 60) then
        mining_rocks_cooldown[k] = nil
      end
    end
  end
end)

-- Hauptdrop
RegisterServerEvent('vorp_mining:addItem', function(max_swings)
  math.randomseed(os.time())
  local _source = source

  local state = mining_rocks[_source]
  if not state or not state.coords then return end
  local pos = state.coords
  local riverZone = getRiverZoneByCoords(pos)

  if riverZone then
    -- Jobzugriff
    local char = GetChar(_source)
    if not HasMiningAccess(char, riverZone) then
      Core.NotifyObjective(_source, "Dir fehlt die Berechtigung zum Schürfen.", 4000)
      return
    end
    -- Pfanne prüfen
    local hasPan = false
    for _,def in ipairs(CFG().Tools) do
      if def.type == "pan" then
        local itm = exports.vorp_inventory:getItem(_source, def.item)
        if itm then hasPan = true break end
      end
    end
    if not hasPan then
      Core.NotifyObjective(_source, "Du brauchst eine Goldpfanne, um hier zu schürfen!", 4000)
      return
    end

    local key = getKey(pos)
    if mining_rocks_cooldown[key] then
      Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.Rockoncooldown) or "Hier ist kürzlich schon geschürft worden.", 4000)
      return
    end

    -- River-Loot: einfacher 1..100-Wurf gegen item.chance
    local roll = math.random(1, 100)
    local gave = false
    for _,it in ipairs(riverZone.loot or {}) do
      if roll <= (it.chance or 0) then
        local qty = it.amount or 1
        if canCarry(_source, it.name, qty) then
          giveItem(_source, it.name, qty)
          Core.NotifyObjective(_source, "💰 Du hast einen ".. (it.label or it.name) .." gefunden!", 4000)
          gave = true
        end
      end
    end
    if not gave then
      Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.gotNothing) or "Nichts gefunden.", 2500)
    end

    mining_rocks_cooldown[key] = { time = os.time() }
    return
  end

  -- Fels-Mining
  local miningrock = mining_rocks[_source]
  if not miningrock then return end

  local key = getKey(miningrock.coords)
  if mining_rocks_cooldown[key] then
    Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.Rockoncooldown) or "Hier gibt es nichts mehr zu holen.", 5000)
    return
  end

  if max_swings > (Config.MaxSwing or 3) then return end

  miningrock.count = miningrock.count + 1
  if miningrock.count >= max_swings then
    mining_rocks[_source] = nil
    if not mining_rocks_cooldown[key] then
      mining_rocks_cooldown[key] = { time = os.time() }
    end
  end

  local chanceRange, items, zone = getLootTableForCoords(miningrock.coords)
  if not items or #items == 0 then
    Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.gotNothing) or "Du hast nichts gefunden.", 3000)
    return
  end

  -- Jobzugriff
  local char = GetChar(_source)
  if not HasMiningAccess(char, zone) then
    Core.NotifyObjective(_source, "Dir fehlt die Berechtigung zum Minen.", 4000)
    return
  end

  -- Werkzeugpflicht prüfen
  local c = CFG()
  local function hasToolFor(itemName)
    local rule = c.MineralTools[itemName]
    if not rule then return true end
    for _,def in ipairs(c.Tools) do
      local itm = exports.vorp_inventory:getItem(_source, def.item)
      if itm and def.type == rule.tool and (def.tier or 1) >= (rule.minTier or 1) then
        return true
      end
    end
    return false
  end

  -- Loot-Roll
  local roll1 = math.random(1, chanceRange)
  local reward = {}
  for _,it in ipairs(items) do
    if (it.chance or 0) >= roll1 then reward[#reward+1] = it end
  end
  if #reward == 0 then
    Core.NotifyObjective(_source, (T.NotifyLabels and T.NotifyLabels.gotNothing) or "Du hast nichts gefunden.", 3000)
    return
  end

  local pick = reward[math.random(1, #reward)]
  if c.ToolsEnabled and not hasToolFor(pick.name) then
    local rule = c.MineralTools[pick.name]
    local toolName = rule and rule.tool or "Werkzeug"
    Core.NotifyObjective(_source, "Du brauchst das richtige Werkzeug (".. toolName ..") für dieses Material.", 4000)
    return
  end

  local baseAmount = math.random(1, pick.amount or 1)
  local mult = getJobYieldMultiplier(zone and zone.name or nil, char)
  local finalAmount = math.max(1, math.floor(baseAmount * mult + 0.0001))

  if not canCarry(_source, pick.name, finalAmount) then
    return Core.NotifyObjective(_source, ((T.NotifyLabels and T.NotifyLabels.fullBag) or "Inventar voll: ") .. (pick.label or pick.name), 5000)
  end

  giveItem(_source, pick.name, finalAmount)
  Core.NotifyObjective(_source, ((T.NotifyLabels and T.NotifyLabels.yourGot) or "Erhalten: ") .. (pick.label or pick.name) .. (finalAmount>1 and (" x"..finalAmount) or ""), 3000)

  -- Edelsteinchance
  if Config and Config.Gemstones and Config.Gemstones.enabled then
    local zoneName = zone and zone.name or nil
    local gemChance = getGemChanceForZone(zoneName)
    if gemChance and gemChance > 0 then
      local r = math.random(1, 100)
      if r <= gemChance then
        local g = pickGem()
        if g and canCarry(_source, g.name, g.amount or 1) then
          giveItem(_source, g.name, g.amount or 1)
          Core.NotifyObjective(_source, "💎 Du hast einen Edelstein gefunden: " .. (g.label or g.name), 4000)
        end
      end
    end
  end
end)

-- Cleanup
AddEventHandler('playerDropped', function()
  local _source = source
  mining_rocks[_source] = nil
end)
