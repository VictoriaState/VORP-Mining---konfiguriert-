Config = {}

-- Sprache der Labels (nur Anzeige)
Lang = "German"

-- ===== Grund-Settings =====
Config.Pickaxe = "pickaxe"                  -- Item-Name deiner Spitzhacke (Legacy-Fallback)

-- Tasten (RDR2 Control-Hashes)
Config.MinePromptKey = 0xD9D0E1C0          -- [SPACE] Start Mining
Config.StopMiningKey  = 0x3B24C470          -- [F]    Mining stoppen
Config.MineRockKey    = 0x07B8BEAF          -- [LMB]  Schlag

-- Interaktion / Schwierigkeitsgrad
Config.MinSwing = 2                         -- min. Schläge pro Fels
Config.MaxSwing = 4                         -- max. Schläge pro Fels
Config.PickaxeDurabilityThreshold = 20      -- ab so vielen Schlägen wird Bruch geprüft
Config.PickaxeBreakChanceMin = 1            -- min. Bruchchance pro Schlag (in %)
Config.PickaxeBreakChanceMax = 3            -- max. Bruchchance pro Schlag (in %)

-- Achtung: kleiner = schwerer
Config.minDifficulty = 4500
Config.maxDifficulty = 3200

-- Cooldowns / Drop-Chance-Rahmen
Config.CoolDown    = 45                     -- Minuten Sperrzeit pro Spot/Spieler (je nach Script-Logik)
Config.ChanceRange = 20

-- Welche World-Props gelten als "abbaubare Felsen" (für das Rock-Mining)?
-- Falls ihr eigene Mappings habt, hier eintragen. Sonst könnt ihr nur River-Panning nutzen.
Config.Rocks = {
  "p_rock_amb01x",
  "p_rock_amb02x",
  "p_rock_amb03x",
  "p_rock_amb04x"
}
                     -- Würfel 1..ChanceRange; item.chance <= Wurf ⇒ Drop

-- Städte-Restriktionen (Namen müssen zu deinem Script passen!)
Config.TownRestrictions = {
    { name = 'Annesburg',  mine_allowed = true  },
    { name = 'Armadillo',  mine_allowed = false },
    { name = 'Blackwater', mine_allowed = false },
    { name = 'Lagras',     mine_allowed = true  },
    { name = 'Rhodes',     mine_allowed = true  },
    { name = 'StDenis',    mine_allowed = false }, -- ggf. "SaintDenis"
    { name = 'Strawberry', mine_allowed = false },
    { name = 'Tumbleweed', mine_allowed = false },
    { name = 'Valentine',  mine_allowed = true  },
    { name = 'Vanhorn',    mine_allowed = false },
}

-- ===== Werkzeuge aktivieren (Pflichtwerkzeug pro Mineral) =====
Config.ToolsEnabled = true

-- Verfügbare Werkzeuge (Item-IDs = deine DB/Inventory IDs)
Config.Tools = {
  pickaxe_iron  = { item = "pickaxe",        type = "pickaxe", tier = 1, maxUses = 150 },
  pickaxe_steel = { item = "pickaxe_steel",  type = "pickaxe", tier = 2, maxUses = 150 },
  shovel        = { item = "shovel",         type = "shovel",  tier = 1, maxUses = 150 },
  goldpan       = { item = "goldpan",        type = "pan",     tier = 1, maxUses = 150 },
  chisel        = { item = "chisel",         type = "chisel",  tier = 1, maxUses = 150 },
}

-- Welches Mineral braucht welches Werkzeug?
Config.RequireJobToMine = false
Config.AllowedMiningJobs = { mining = { minGrade = 0 } }

Config.MineralTools = {
  coal        = { tool = "pickaxe", minTier = 1 },
  iron        = { tool = "pickaxe", minTier = 1 },
  copper      = { tool = "pickaxe", minTier = 1 },
  zinc        = { tool = "pickaxe", minTier = 1 },
  silverore   = { tool = "pickaxe", minTier = 2 },  -- härter → Stahl-Spitzhacke
  quartz      = { tool = "pickaxe", minTier = 1 },
  limestone   = { tool = "pickaxe", minTier = 1 },
  nitrite     = { tool = "pickaxe", minTier = 1 },
  salt        = { tool = "pickaxe", minTier = 1 },
  rock        = { tool = "pickaxe", minTier = 1 },

  clay        = { tool = "shovel",  minTier = 1 },
  sand        = { tool = "shovel",  minTier = 1 },

  goldnugget  = { tool = "pan",     minTier = 1 },  -- NUR mit Pfanne (und nur in Flüssen)
}

-- ===== Globale Fallback-Drops (falls Zone keine Override hat) =====
-- (Kein Gold hier!)
Config.Items = {
    { name = "clay",       label = "Ton",           chance = 16, amount = 4 },
    { name = "coal",       label = "Kohle",         chance = 14, amount = 4 },
    { name = "copper",     label = "Kupfer",        chance = 10, amount = 4 },
    { name = "iron",       label = "Eisen",         chance = 16, amount = 6 },
    { name = "nitrite",    label = "Salpeter",      chance = 6,  amount = 2 },
    { name = "rock",       label = "Stein",         chance = 12, amount = 4 },
    { name = "saltstone",       label = "Salzstein",          chance = 8,  amount = 3 },
}

-- ===== Zonen / Minen mit eigenen Loot-Tabellen =====
-- (Goldnuggets sind hier ENTFERNT!)
Config.Mines = {
    {
        name = "Annesburg Mine", -- große Kohle- und Eisenmine
        coords = {x = 2733.86, y = 1401.07, z = 68.8},
        radius = 120.0,
        items = {
            { name = "coal",       label = "Kohle",     chance = 18, amount = 5 },
            { name = "iron",       label = "Eisen",     chance = 15, amount = 6 },
            { name = "copper",     label = "Kupfer",    chance = 8,  amount = 4 },
            { name = "nitrite",    label = "Salpeter",  chance = 4,  amount = 2 },
			{ name = "mercury",    label = "Quecksilber",  chance = 4,  amount = 2 },
        }
    },
    {
        name = "Big Valley Goldader", -- jetzt OHNE Gold, dafür Silber/Quarz
        coords = {x = -1391.2, y = 1182.38, z = 222.11},
        radius = 90.0,
        items = {
            -- { name = "goldnugget", label = "Goldnugget", chance = 2,  amount = 1 }, -- entfernt
            { name = "silverore",  label = "Silbererz",   chance = 6,  amount = 2 },
            { name = "quartz",     label = "Quarz",       chance = 7,  amount = 3 },
            { name = "rock",       label = "Stein",       chance = 12, amount = 4 },
        }
    },
    {
        name = "Rhodes Steinbruch", -- Kalk- und Tonabbau
        coords = {x = 1412.59, y = -463.09, z = 76.76},
        radius = 110.0,
        items = {
            { name = "clay",       label = "Ton",        chance = 20, amount = 5 },
            { name = "limestone",  label = "Kalkstein",  chance = 15, amount = 4 },
            { name = "rock",       label = "Stein",      chance = 12, amount = 4 },
            { name = "saltstone",       label = "Salzstein",       chance = 4,  amount = 2 },
        }
    },
    {
        name = "Aurora Basin Silbermine", -- Silber + Buntmetalle
        coords = {x = -2578.14, y = -1498.74, z = 146.87},
        radius = 85.0,
        items = {
            { name = "silverore",  label = "Silbererz",  chance = 6, amount = 3 },
            { name = "copper",     label = "Kupfer",     chance = 8, amount = 4 },
            { name = "zinc",       label = "Zink",       chance = 5, amount = 3 },
            { name = "rock",       label = "Stein",      chance = 10, amount = 4 },
			{ name = "chlorinated_lime",       label = "Chlorkalk",       chance = 5, amount = 3 },
        }
    },
    {
        name = "Lagras Salzfelder", -- nur Salz & Ton
        coords = { x = 2140.0, y = -612.0, z = 43.0 },
        radius = 100.0,
        items = {
            { name = "salt",       label = "Salz",       chance = 22, amount = 5 },
            { name = "clay",       label = "Ton",        chance = 18, amount = 4 },
        }
    },
    {
        name = "Valentine Sandgrube", -- Sand/Quarz
        coords = {x = -764.94, y = 571.38, z = 56.65},
        radius = 75.0,
        items = {
            { name = "quartz",     label = "Quarz",      chance = 15, amount = 4 },
            { name = "sand",       label = "Sand",       chance = 20, amount = 6 },
            { name = "rock",       label = "Stein",      chance = 10, amount = 3 },
        }
    }
}

-- ===== Flüsse – hier gibt es Goldnuggets (NUR mit Goldpfanne) =====
-- Koordinaten sind Beispielpunkte nahe typischen Flussläufen – bitte nach Bedarf feinjustieren.
Config.RiverPanningZones = {
  {
    name = "Kamassa River – Flachwasser",
    coords = {
      { x = 2503.01, y = 99.19,  z = 43.25 },
      { x = 2523.58, y = 393.68, z = 63.86 },
      { x = 2481.24, y = 781.29, z = 67.31 },
      { x = 2224.99, y = 1388.95, z = 85.15 },
      { x = 2510.03, y = 1544.69, z = 85.26 },
      { x = 2849.75, y = 2245.22, z = 156.80 },
    },
    radius = 60.0,
    loot = {
      { name = "goldnugget", label = "Goldnugget", chance = 20, amount = 1 },
    }
  },

  {
    name = "Dakota River",
    coords = {
      { x = -520.84, y = -192.35, z = 41.66 },
      { x = -837.28, y = 28.42,   z = 41.61 },
      { x = -1209.84, y = 182.60, z = 41.48 },
      { x = -700.85,  y = 714.40, z = 60.08 },
      { x = -470.96,  y = 1040.80,z = 87.93 },
      { x = 28.27,    y = 1579.48,z = 112.70 },
      { x = 577.53,   y = 2025.88,z = 210.77 },
    },
    radius = 60.0,
    loot = {
      { name = "goldnugget", label = "Goldnugget", chance = 20, amount = 1 },
    }
  },

  {
    name = "Little Creek River",
    coords = {
      { x = -1583.71, y = 362.13, z = 102.81 },
      { x = -1954.06, y = 595.46, z = 115.24 },
      { x = -2451.18, y = 744.91, z = 129.46 },
    },
    radius = 60.0,
    loot = {
      { name = "goldnugget", label = "Goldnugget", chance = 20, amount = 1 },
    }
  },

  {
    name = "Upper Montana River",
    coords = {
      { x = -1073.26, y = -849.91, z = 43.40 },
      { x = -1591.26, y = -1077.48, z = 66.15 },
      { x = -1997.39, y = -1027.61, z = 74.98 },
      { x = -2262.90, y = -500.19,  z = 138.37 },
    },
    radius = 60.0,
    loot = {
      { name = "goldnugget", label = "Goldnugget", chance = 20, amount = 1 },
    }
  },

  {
    name = "Lower Montana River",
    coords = {
      { x = -2057.95, y = -2158.24, z = 42.67 },
      { x = -2353.82, y = -1788.90, z = 107.65 },
    },
    radius = 60.0,
    loot = {
      { name = "goldnugget", label = "Goldnugget", chance = 20, amount = 1 },
    }
  },
}

-- ===== Job-Boni für Mining =====
Config.JobYieldBonus = {
  enabled = true,
  jobName = "mining",             -- exakter Jobname im Core
  baseMultiplier = 1.50,          -- +50% Ertrag auf normale Drops
  gradeSteps = {                   -- zusätzlicher Bonus je Rang (multipliziert)
    [5]  = 1.10,                  -- ab Rang 5: x1.10 extra
    [10] = 1.25,                  -- ab Rang 10: x1.25 extra
  },
  zoneMultipliers = {              -- optional unterschiedliche Zonen-Boni
    ["Valentine Sandgrube"] = 1.10,
    ["Big Valley Goldader"] = 1.20,  -- bleibt als Silber-/Quarz-Zone leicht erhöht
  }
}

-- ===== Edelsteine (seltene Zusatzdrops) =====
Config.Gemstones = {
  enabled = true,
  baseChancePercent = 2,           -- % pro erfolgreichem Loot
  perZoneOverride = {
    ["Big Valley Goldader"]      = 3,
    ["Aurora Basin Silbermine"]  = 2,
  },
  table = {                        -- gewichtete Liste
    { name="agate",     label="Achat",      weight=35, amount=1 },
    { name="garnet",    label="Granat",     weight=25, amount=1 },
    { name="amethyst",  label="Amethyst",   weight=18, amount=1 },
    { name="turquoise", label="Türkis",     weight=12, amount=1 },
    { name="opal",      label="Opal",       weight=8,  amount=1 },
    { name="jade",      label="Jade",       weight=6,  amount=1 },
  },
  restrictToZones = false,
  allowedZones = { "Big Valley Goldader", "Aurora Basin Silbermine", "Valentine Sandgrube" }
}
