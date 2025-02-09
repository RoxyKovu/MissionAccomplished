--=============================================================================
-- EventsDictionary.lua
--
-- Event codes mapped to human-readable event names
-- This file holds all the events, their corresponding event codes, and
-- additional data for each event. All event-related properties (icons,
-- sounds, messages, etc.) are centralized here.
--
-- Usage:
--   local event = EventsDictionary.allEvents.RC
--   print(event.name)     -- "Ragefire Chasm"
--   print(event.message)  -- "%s ventures into Ragefire Chasm—the molten fury tests true resolve!"
--   print(event.icon)     -- "Interface\\Icons\\Spell_Fire_LavaSpawn"
--   print(event.sound)    -- "Sound\\Interface\\RaidWarning.wav"
--
-- For tips, note the field is named "text" (instead of "message").
--=============================================================================

-- A lookup to map event codes to a human-readable type (mostly for reference)
local eventTypeLookup = {
    EI    = "EnteredInstance",    -- Entered Instance
    LI    = "LeftInstance",       -- Left Instance (new)
    LH    = "LowHealth",          -- Low Health
    LU    = "LevelUp",            -- Level Up
    GD    = "GuildDeath",         -- Guild Death
    GLU   = "GuildLevelUp",       -- Guild Level Up (new)
    GAch  = "GuildAchievement",   -- Guild Achievement (new)
    GLH   = "GuildLowHealth",     -- Guild Low Health (new)
    GEI   = "GuildEnteredInstance", -- Guild Entered Instance (new)
    ML    = "MaxLevel",           -- Max Level
    PR    = "Progress",           -- Progress
    GA    = "GuildAmount",        -- Guild Amount
    GT    = "GavrialsTip",        -- Gavrial's Tip (fallback)
    BE    = "BuffEvent",          -- Buff (Aura) Event
    GR    = "GuildRosterUpdate",  -- Guild Roster Update
    BH    = "BigHit",             -- Big Hit (Combat Log) Event
}

-- Icon definitions for events
local eventIcons = {
    EI    = "Interface\\Icons\\ability_hunter_rapidkilling",   -- Entered Instance
    LI    = "Interface\\Icons\\INV_Misc_Map01",                -- Left Instance
    LH    = "Interface\\Icons\\Spell_Holy_AshesToAshes",         -- Low Health
    LU    = "Interface\\Icons\\achievement_bg_killflagcarriers_grabflag_capit",  -- Level Up
    GD    = "Interface\\Icons\\achievement_ladydeathwhisper",    -- Guild Death
    GLU   = "Interface\\Icons\\INV_Scroll_01",                 -- Guild Level Up
    GAch  = "Interface\\Icons\\INV_Misc_Coin_03",              -- Guild Achievement
    GLH   = "Interface\\Icons\\INV_Healthstone",               -- Guild Low Health
    GEI   = "Interface\\Icons\\INV_Misc_Map02",                -- Guild Entered Instance
    ML    = "Interface\\Icons\\achievement_level_60",          -- Max Level
    PR    = "Interface\\Icons\\ability_hunter_huntervswild",   -- Progress
    GA    = "Interface\\Icons\\INV_Misc_Coin_01",              -- Guild Amount
    GT    = "Interface\\Icons\\INV_Misc_QuestionMark",         -- Gavrial's Tip (fallback)
    BE    = "Interface\\Icons\\Spell_Holy_GuardianSpirit",     -- Buff Event (example icon)
    GR    = "Interface\\Icons\\INV_Misc_GroupLooking",         -- Guild Roster Update
    BH    = "Interface\\Icons\\INV_Sword_04",                  -- Big Hit
}

-- Sound file definitions for events
local eventSounds = {
    EI    = "Sound\\Interface\\RaidWarning.wav",      -- Entered Instance
    LI    = "Sound\\Interface\\RaidWarning.wav",      -- Left Instance (new)
    LH    = "Sound\\Spells\\PVPFlagTaken.wav",          -- Low Health
    LU    = "Sound\\Interface\\LevelUp.wav",            -- Level Up
    GD    = "Sound\\Spells\\PVPFlagTaken.wav",          -- Guild Death
    GLU   = "Sound\\Interface\\LevelUp.wav",            -- Guild Level Up (new)
    GAch  = "Sound\\Interface\\Achievement.wav",        -- Guild Achievement
    GLH   = "Sound\\Spells\\PVPFlagTaken.wav",          -- Guild Low Health (new)
    GEI   = "Sound\\Interface\\RaidWarning.wav",        -- Guild Entered Instance (new)
    ML    = "Sound\\Interface\\Achievement.wav",        -- Max Level
    PR    = "Sound\\Interface\\RaidWarning.wav",        -- Progress
    GA    = "Sound\\Interface\\Achievement.wav",        -- Guild Amount
    GT    = "Sound\\Interface\\LevelUp.wav",            -- Gavrial's Tip (fallback)
    BE    = "Sound\\Interface\\SpellActivationOvertime.wav",  -- Buff event
    GR    = "Sound\\Interface\\RaidWarning.wav",        -- Guild Roster Update
    BH    = "Sound\\Interface\\RaidWarning.wav",        -- Big Hit
}

-- Define additional event tables if not already defined

local auraEvent = {
    BE = {
        name = "Buff Event",
        icon = eventIcons.BE,
        sound = eventSounds.BE,
        messageGain = "%s has gained the buff: %s!",
        messageLost = "%s has lost the buff: %s!",
    },
}

local guildRosterEvent = {
    GR = {
        name = "Guild Roster Update",
        icon = eventIcons.GR,
        sound = eventSounds.GR,
        message = "%s the %s has come online and is ready to embark on new adventures!",
    },
}


local bigHitEvent = {
    BH = {
        name = "Big Hit",
        icon = eventIcons.BH,
        sound = eventSounds.BH,
        message = "%s was hit hard by %s for %s damage!",
    },
}

--=========================================================================== 
-- Dungeon and Raid Events 
--=========================================================================== 
local dungeonEvents = {
    RC = {
        name    = "Ragefire Chasm",
        icon    = "Interface\\Icons\\Spell_Fire_LavaSpawn",
        sound   = eventSounds.EI,
        message = "%s ventures into Ragefire Chasm—the molten fury tests true resolve!",
    },
    WC = {
        name    = "Wailing Caverns",
        icon    = "Interface\\Icons\\inv_misc_monsterhead_02",
        sound   = eventSounds.EI,
        message = "%s descends into Wailing Caverns—druidic nightmares and echoes beckon!",
    },
    TD = {
        name    = "The Deadmines",
        icon    = "Interface\\Icons\\achievement_boss_edwinvancleef",
        sound   = eventSounds.EI,
        message = "%s braves The Deadmines—shadowed treachery and hidden treasure await!",
    },
    SF = {
        name    = "Shadowfang Keep",
        icon    = "Interface\\Icons\\ability_mount_blackdirewolf",
        sound   = eventSounds.EI,
        message = "%s storms the gloom of Shadowfang Keep—curses prowl in every corridor!",
    },
    TS = {
        name    = "The Stockade",
        icon    = "Interface\\Icons\\inv_misc_key_11",
        sound   = eventSounds.EI,
        message = "%s assaults The Stockade—justice meets rebellion within these stony halls!",
    },
    GN = {
        name    = "Gnomeregan",
        icon    = "Interface\\Icons\\inv_misc_gear_02",
        sound   = eventSounds.EI,
        message = "%s fights to reclaim Gnomeregan—once a marvel of ingenuity, now a deadly maze!",
    },
    RK = {
        name    = "Razorfen Kraul",
        icon    = "Interface\\Icons\\spell_nature_thorns",
        sound   = eventSounds.EI,
        message = "%s invades Razorfen Kraul—thorn-riddled corridors brimming with primal threats!",
    },
    SG = {
        name    = "Scarlet Monastery",
        icon    = "Interface\\Icons\\INV_Misc_Bone_Skull_02",
        sound   = eventSounds.EI,
        message = "%s enters the Scarlet Monastery—fanatical crusaders and vengeful spirits stir at the intruder’s presence.",
    },
    SL = {
        name    = "Scarlet Monastery: Library",
        icon    = "Interface\\Icons\\INV_Misc_Book_06",
        sound   = eventSounds.EI,
        message = "%s boldly delves into the Library—forgotten tomes hold unimaginable powers!",
    },
    SA = {
        name    = "Scarlet Monastery: Armory",
        icon    = "Interface\\Icons\\INV_Sword_04",
        sound   = eventSounds.EI,
        message = "%s charges into the Armory—where blades clash with unyielding zeal!",
    },
    SC = {
        name    = "Scarlet Monastery: Cathedral",
        icon    = "Interface\\Icons\\INV_Hammer_06",
        sound   = eventSounds.EI,
        message = "%s confronts the Cathedral—the righteous and the wicked collide in judgment!",
    },
    RD = {
        name    = "Razorfen Downs",
        icon    = "Interface\\Icons\\INV_Misc_Pelt_Bear_03",
        sound   = eventSounds.EI,
        message = "%s treads carefully in Razorfen Downs—a necropolis of bone and bristle!",
    },
    UL = {
        name    = "Uldaman",
        icon    = "Interface\\Icons\\INV_Misc_Gear_02",
        sound   = eventSounds.EI,
        message = "%s unearths secrets in Uldaman—echoes of a lost Titan legacy resound!",
    },
    ZF = {
        name    = "Zul'Farrak",
        icon    = "Interface\\Icons\\INV_Jewelry_Talisman_06",
        sound   = eventSounds.EI,
        message = "%s ventures into Zul'Farrak—sandy storms swirl around trollish superstitions!",
    },
    MR = {
        name    = "Maraudon",
        icon    = "Interface\\Icons\\Spell_Nature_AbolishMagic",
        sound   = eventSounds.EI,
        message = "%s braves the wilds of Maraudon—where the raw power of the earth seethes!",
    },
    TA = {
        name    = "Temple of Atal'Hakkar",
        icon    = "Interface\\Icons\\Spell_Nature_EarthBindTotem",
        sound   = eventSounds.EI,
        message = "%s descends into the Temple of Atal'Hakkar—twisted dreams lurk in the swamp!",
    },
    BD2 = {
        name    = "Blackrock Depths",
        icon    = "Interface\\Icons\\achievement_dungeon_ulduarraid_irondwarf_01",
        sound   = eventSounds.EI,
        message = "%s dares the inferno of Blackrock Depths—a molten bastion of dwarven might!",
    },
    LBS = {
        name    = "Lower Blackrock Spire",
        icon    = "Interface\\Icons\\achievement_dungeon_coablackdragonflight",
        sound   = eventSounds.EI,
        message = "%s seizes upon Lower Blackrock Spire—where strife forges legends in flame!",
    },
    UBS = {
        name    = "Upper Blackrock Spire",
        icon    = "Interface\\Icons\\achievement_dungeon_coablackdragonflight_heroic",
        sound   = eventSounds.EI,
        message = "%s ascends to Upper Blackrock Spire—only the strongest survive its trials!",
    },
    DME = {
        name    = "Dire Maul: East",
        icon    = "Interface\\Icons\\spell_shadow_summonimp",
        sound   = eventSounds.EI,
        message = "%s challenges Dire Maul (East)—nature’s wrath stands vigilant!",
    },
    DMW = {
        name    = "Dire Maul: West",
        icon    = "Interface\\Icons\\inv_misc_eye_04",
        sound   = eventSounds.EI,
        message = "%s ventures into Dire Maul (West)—haunted corridors echo with past grandeur!",
    },
    DMN = {
        name    = "Dire Maul: North",
        icon    = "Interface\\Icons\\achievement_reputation_ogre",
        sound   = eventSounds.EI,
        message = "%s battles Dire Maul (North)—where ogres uphold a brutal legacy!",
    },
    SLL = {
        name    = "Stratholme: Living Side",
        icon    = "Interface\\Icons\\spell_holy_senseundead",
        sound   = eventSounds.EI,
        message = "%s enters Stratholme (Living)—where the desperate cling to a final hope!",
    },
    SLU = {
        name    = "Stratholme: Undead Side",
        icon    = "Interface\\Icons\\ability_warlock_demonicpower",
        sound   = eventSounds.EI,
        message = "%s invades Stratholme (Undead)—the dead march in eternal torment!",
    },
    SCOL = {
        name    = "Scholomance",
        icon    = "Interface\\Icons\\achievement_boss_lichking",
        sound   = eventSounds.EI,
        message = "%s breaches Scholomance—twisted souls guard forbidden knowledge!",
    },
}

local raidEvents = {
    MC = {
        name    = "Molten Core",
        icon    = "Interface\\Icons\\Spell_Fire_Fire",
        sound   = eventSounds.EI,
        message = "%s descends into Molten Core—fire and fury churn within the mountain!",
    },
    OL = {
        name    = "Onyxia's Lair",
        icon    = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
        sound   = eventSounds.EI,
        message = "%s stands before Onyxia's Lair—a broodmother's cunning looms!",
    },
    BWL = {
        name    = "Blackwing Lair",
        icon    = "Interface\\Icons\\INV_Misc_Head_Dragon_02",
        sound   = eventSounds.EI,
        message = "%s challenges Blackwing Lair—draconic legions test your final breath!",
    },
    ZG = {
        name    = "Zul'Gurub",
        icon    = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
        sound   = eventSounds.EI,
        message = "%s ventures into Zul'Gurub—a primal jungle stirs with trollish gods!",
    },
    AQ20 = {
        name    = "Ruins of Ahn'Qiraj",
        icon    = "Interface\\Icons\\INV_Misc_Idol_02",
        sound   = eventSounds.EI,
        message = "%s breaches the Ruins of Ahn'Qiraj—chitinous horrors awaken from slumber!",
    },
    AQ40 = {
        name    = "Temple of Ahn'Qiraj",
        icon    = "Interface\\Icons\\INV_Misc_Idol_03",
        sound   = eventSounds.EI,
        message = "%s ascends the Temple of Ahn'Qiraj—face the old god's chosen in ancient sands!",
    },
    NAX = {
        name    = "Naxxramas",
        icon    = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_02",
        sound   = eventSounds.EI,
        message = "%s faces Naxxramas—an unholy fortress of relentless dread!",
    },
}

--=========================================================================== 
-- Guild and Progress Events 
--=========================================================================== 
local guildEvents = {
    GA = {
        name    = "Guild Members Online",
        icon    = "Interface\\Icons\\INV_Misc_GroupLooking",
        sound   = eventSounds.GA,
        message = "%s guild members are currently online.",
    },
    -- (Additional guild-related events can be added here if needed.)
}

local progressEvents = {
    PR = {
        name    = "Progress",
        icon    = "Interface\\Icons\\ability_hunter_huntervswild",
        sound   = eventSounds.PR,
        message = "%s presses onward, now %s%% closer to conquering level 60!",
    },
}

--=========================================================================== 
-- Level and Health Events 
--=========================================================================== 
local maxLevelEvent = {
    ML = {
        name    = "Max Level",
        icon    = "Interface\\Icons\\achievement_level_60",
        sound   = eventSounds.ML,
        message = "%s stands at the pinnacle—level 60! A legend is forged this day!",
    },
}

local levelEvents = {
    EP = {
        name    = "Epic Level 60",
        icon    = "Interface\\Icons\\achievement_level_60",
        sound   = "Sound\\Interface\\Achievement.wav",
        message = "Behold, %s the %s from %s has ascended to level 60! Let their saga echo through eternity!",
    },
}

local lowHealthEvent = {
    LH = {
        name    = "Low Health",
        icon    = "Interface\\Icons\\Spell_Holy_AshesToAshes",
        sound   = eventSounds.LH,
        message = "A dire blow! The lifeblood of %s dwindles at %s%%—will they endure or fall?",
    },
}

local levelUpEvent = {
    LU = {
        name    = "Level Up",
        icon    = "Interface\\Icons\\achievement_bg_killflagcarriers_grabflag_capit",
        sound   = eventSounds.LU,
        message = "%s the %s has ascended to level %s—power surges in their veins!",
    },
}

local guildDeathEvent = {
    GD = {
        name    = "Guild Death",
        icon    = "Interface\\Icons\\achievement_ladydeathwhisper",
        sound   = eventSounds.GD,
        message = "Shadows tighten their grasp on %s—a brave spirit lost to the void!",
    },
}

--=========================================================================== 
-- Additional Events 
--=========================================================================== 
local welcomeEvent = {
    Welcome = {
        name    = "Welcome",
        icon    = "Interface\\Icons\\ability_hunter_huntervswild",
        sound   = "Sound\\Interface\\LevelUp.wav",
        message = "Welcome back, %s! You are currently %.1f%% done with %d EXP remaining. Keep grinding!",
    },
    Welcome60 = {
        name    = "Welcome Level 60",
        icon    = "Interface\\Icons\\Achievement_Level_60",
        sound   = "Sound\\Interface\\Achievement.wav",
        message = "Welcome back, %s! You've reached level 60! Embrace your legacy!",
    },
}

local playerDeathEvent = {
    PlayerDeath = {
        name    = "Player Death",
        icon    = "Interface\\Icons\\Spell_Shadow_SoulLeech",
        sound   = "Sound\\Creature\\CaveBear\\CaveBearDeath.wav",
        message = "%s has fallen in battle!",
    },
}

--=========================================================================== 
-- New Guild/Instance Events (Added for legacy mappings)
--=========================================================================== 
local leftInstanceEvent = {
    LI = {
        name    = "Left Instance",
        icon    = "Interface\\Icons\\INV_Misc_Map01",
        sound   = eventSounds.EI,
        message = "%s has left the instance.",
    },
}

local guildLevelUpEvent = {
    GLU = {
        name    = "Guild Level Up",
        icon    = "Interface\\Icons\\INV_Scroll_01",
        sound   = "Sound\\Interface\\LevelUp.wav",
        message = "Guild member %s has reached a new level!",
    },
}

local guildAchievementEvent = {
    GAch = {
        name    = "Guild Achievement",
        icon    = "Interface\\Icons\\INV_Misc_Coin_03",
        sound   = "Sound\\Interface\\Achievement.wav",
        message = "Guild member %s unlocked a guild achievement!",
    },
}

local guildLowHealthEvent = {
    GLH = {
        name    = "Guild Low Health",
        icon    = "Interface\\Icons\\INV_Healthstone",
        sound   = "Sound\\Spells\\PVPFlagTaken.wav",
        message = "Guild member %s is at low health (%s%%)!",
    },
}

local guildEnteredInstanceEvent = {
    GEI = {
        name    = "Guild Entered Instance",
        icon    = "Interface\\Icons\\INV_Misc_Map02",
        sound   = "Sound\\Interface\\RaidWarning.wav",
        message = "Guild member %s has entered an instance.",
    },
}

--=========================================================================== 
-- Gavrials Tips Events (using 'text' instead of 'message')
--=========================================================================== 
local gavrialsTips = {
    GT1 = {
        text  = "Close Call from The Warrior, Gavrial the 1st: Trust Your Gut – If you have a bad feeling about an enemy or quest, skip it.",
        icon  = "Interface\\Icons\\Ability_Rogue_FeignDeath",
        sound = eventSounds.GT,
    },
    GT2 = {
        text  = "Lesson from The Mage, Gavrial the 3rd: Be an Engineer – Engineering opens up powerful tools and gadgets that can save your life.",
        icon  = "Interface\\Icons\\Trade_Engineering",
        sound = eventSounds.GT,
    },
    GT3 = {
        text  = "Final Lesson of The Warrior, Gavrial the 1st: Stick With Friends – Team up whenever possible, trust your allies.",
        icon  = "Interface\\Icons\\INV_Misc_GroupLooking",
        sound = eventSounds.GT,
    },
    GT4 = {
        text  = "Lesson from The Mage, Gavrial the 3rd: Keep Your Skills Updated – Visit trainers regularly to keep your abilities up to date.",
        icon  = "Interface\\Icons\\spell_shadow_scourgebuild",
        sound = eventSounds.GT,
    },
    GT5 = {
        text  = "Close Call from The Rogue, Gavrial the 2nd: Plan Realistic Escapes – An escape route is essential, but make it practical—many have drowned fleeing through windows.",
        icon  = "Interface\\Icons\\Ability_Rogue_Sprint",
        sound = eventSounds.GT,
    },
    GT6 = {
        text  = "Final Lesson of The Mage, Gavrial the 3rd: Know Your Limits – Don’t overestimate your strength; play smart.",
        icon  = "Interface\\Icons\\Ability_Defend",
        sound = eventSounds.GT,
    },
    GT7 = {
        text  = "Lesson from The Druid, Gavrial the 4th: Run, Don’t Die – If things go south, don’t hesitate to run.",
        icon  = "Interface\\Icons\\ability_rogue_sprint",
        sound = eventSounds.GT,
    },
    GT8 = {
        text  = "Lesson from The Mage, Gavrial the 3rd: Train Your Skills – Regularly visit trainers to keep your abilities updated—outdated skills can cost you your life.",
        icon  = "Interface\\Icons\\spell_shadow_scourgebuild",
        sound = eventSounds.GT,
    },
    GT9 = {
        text  = "Lesson from The Mage, Gavrial the 3rd: Buy Big Bags – Trash in large amounts is worth its weight in gold.",
        icon  = "Interface\\Icons\\INV_Misc_Bag_10",
        sound = eventSounds.GT,
    },
    GT10 = {
        text  = "Final Lesson of The Shaman, Gavrial the 5th: Play It Safe – If you’re not feeling confident, go for green mobs.",
        icon  = "Interface\\Icons\\Ability_Hunter_SniperShot",
        sound = eventSounds.GT,
    },
    GT11 = {
        text  = "Final Lesson of The Warrior, Gavrial the 1st: Stick With Friends – When possible, run dungeons with people you know. If not, assume strangers won’t prioritize your safety.",
        icon  = "Interface\\Icons\\INV_Misc_GroupLooking",
        sound = eventSounds.GT,
    },
    GT12 = {
        text  = "Lesson from The Druid, Gavrial the 4th: Keep Big Pots – Always carry potions, just in case.",
        icon  = "Interface\\Icons\\INV_Potion_54",
        sound = eventSounds.GT,
    },
    GT13 = {
        text  = "Lesson from The Druid, Gavrial the 4th: Save Gold – Don’t waste money on unnecessary purchases.",
        icon  = "Interface\\Icons\\INV_Misc_Coin_02",
        sound = eventSounds.GT,
    },
    GT14 = {
        text  = "Lesson from The Rogue, Gavrial the 2nd: Scout Ahead – Use stealth or careful planning to avoid traps.",
        icon  = "Interface\\Icons\\Ability_Stealth",
        sound = eventSounds.GT,
    },
    GT15 = {
        text  = "Lesson from The Paladin, Gavrial the 6th: Know Your Role – Play to your class’s strengths in groups.",
        icon  = "Interface\\Icons\\Spell_Holy_AuraOfLight",
        sound = eventSounds.GT,
    },
    GT16 = {
        text  = "Lesson from The Paladin, Gavrial the 6th: Stay Informed – Read up on dungeons, quests, and zones before diving in.",
        icon  = "Interface\\Icons\\INV_Misc_Book_03",
        sound = eventSounds.GT,
    },
    GT17 = {
        text  = "Final Lesson of The Paladin, Gavrial the 6th: Beware Murlocs – They choose violence and have too many friends.",
        icon  = "Interface\\Icons\\INV_Misc_MonsterHead_02",
        sound = eventSounds.GT,
    },
    GT18 = {
        text  = "Final Lesson of The Priest, Gavrial the 7th: Happy Healer, Happy Party – Keep your healer safe and supplied!",
        icon  = "Interface\\Icons\\Spell_Holy_Renew",
        sound = eventSounds.GT,
    },
    GT19 = {
        text  = "Final Lesson of The Druid, Gavrial the 4th: Beware of Caves – In hardcore WoW, caves are death traps—escape routes are rare.",
        icon  = "Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility",
        sound = eventSounds.GT,
    },
    GT20 = {
        text  = "Lesson from The Hunter, Gavrial the 9th: Play Smart, Not Flashy – Dying at level 32 because of a risky move isn’t impressive—reaching level 60 is the real achievement.",
        icon  = "Interface\\Icons\\Achievement_Level_60",
        sound = eventSounds.GT,
    },
    GT21 = {
        text  = "Final Lesson of The Warlock, Gavrial the 8th: Log Out Safely – Only log out in safe areas—dungeons are not safe.",
        icon  = "Interface\\Icons\\inv_hearthstonebronze",
        sound = eventSounds.GT,
    },
    GT22 = {
        text  = "Final Lesson from The Rogue, Gavrial the 2nd: Escape Abilities Can Fail – Vanish, Feign Death, Frost Nova, Blind, and Gouge can be resisted—always have a backup plan.",
        icon  = "Interface\\Icons\\ability_vanish",
        sound = eventSounds.GT,
    },
    GT23 = {
        text  = "Close Call from The Paladin, Gavrial the 6th: Don’t Risk the Jump – If it looks like you can barely make it, you probably can’t—unless you have fall mitigation abilities.",
        icon  = "Interface\\Icons\\spell_magic_featherfall",
        sound = eventSounds.GT,
    },
    GT24 = {
        text  = "Close Call from The Hunter, Gavrial the 9th: Assume a High-Level Elite is Always Nearby – Even if you haven’t seen one, there’s probably a powerful roaming elite in your zone. Many players have met their end by assuming otherwise.",
        icon  = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
        sound = eventSounds.GT,
    },
    GT25 = {
        text  = "Close Call from The Warlock, Gavrial the 8th: Your Pet Doesn’t Know How to Jump – If you’re playing a Hunter or Warlock, remember: pets take the long way down. It will always choose the death march, pulling half the zone in the process.",
        icon  = "Interface\\Icons\\Ability_Hunter_BeastCall",
        sound = eventSounds.GT,
    },
    GT26 = {
        text  = "Lesson from The Hunter, Gavrial the 9th: Portals Before Risky Sections of Dungeons Can Be a Lifesaver – Mages dropping portals before dangerous fights can give your group an instant escape option when things go wrong.",
        icon  = "Interface\\Icons\\Spell_Arcane_PortalStormwind",
        sound = eventSounds.GT,
    },
    GT27 = {
        text  = "Lesson from The Hunter, Gavrial the 9th: Buffs Can Be the Difference Between Life and Death – A well-timed food buff, potion, or world buff might seem minor, but at higher levels, every buff can save you from disaster.",
        icon  = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings",
        sound = eventSounds.GT,
    },
}

--=========================================================================== 
-- Mapping of All Events 
--=========================================================================== 
local allEvents = {
    -- Dungeon and Raid Events
    RC    = dungeonEvents.RC,
    WC    = dungeonEvents.WC,
    TD    = dungeonEvents.TD,
    SF    = dungeonEvents.SF,
    TS    = dungeonEvents.TS,
    GN    = dungeonEvents.GN,
    RK    = dungeonEvents.RK,
    SG    = dungeonEvents.SG,
    SL    = dungeonEvents.SL,
    SA    = dungeonEvents.SA,
    SC    = dungeonEvents.SC,
    RD    = dungeonEvents.RD,
    UL    = dungeonEvents.UL,
    ZF    = dungeonEvents.ZF,
    MR    = dungeonEvents.MR,
    TA    = dungeonEvents.TA,
    BD2   = dungeonEvents.BD2,
    LBS   = dungeonEvents.LBS,
    UBS   = dungeonEvents.UBS,
    DME   = dungeonEvents.DME,
    DMW   = dungeonEvents.DMW,
    DMN   = dungeonEvents.DMN,
    SLL   = dungeonEvents.SLL,
    SLU   = dungeonEvents.SLU,
    SCOL  = dungeonEvents.SCOL,

    MC    = raidEvents.MC,
    OL    = raidEvents.OL,
    BWL   = raidEvents.BWL,
    ZG    = raidEvents.ZG,
    AQ20  = raidEvents.AQ20,
    AQ40  = raidEvents.AQ40,
    NAX   = raidEvents.NAX,

    GA    = guildEvents.GA,
    PR    = progressEvents.PR,

    ML    = maxLevelEvent.ML,
    LH    = lowHealthEvent.LH,
    LU    = levelUpEvent.LU,
    GD    = guildDeathEvent.GD,
    EP    = levelEvents.EP,

    Welcome     = welcomeEvent.Welcome,
    Welcome60   = welcomeEvent.Welcome60,
    PlayerDeath = playerDeathEvent.PlayerDeath,

    -- Gavrials Tips
    GT1  = gavrialsTips.GT1,
    GT2  = gavrialsTips.GT2,
    GT3  = gavrialsTips.GT3,
    GT4  = gavrialsTips.GT4,
    GT5  = gavrialsTips.GT5,
    GT6  = gavrialsTips.GT6,
    GT7  = gavrialsTips.GT7,
    GT8  = gavrialsTips.GT8,
    GT9  = gavrialsTips.GT9,
    GT10 = gavrialsTips.GT10,
    GT11 = gavrialsTips.GT11,
    GT12 = gavrialsTips.GT12,
    GT13 = gavrialsTips.GT13,
    GT14 = gavrialsTips.GT14,
    GT15 = gavrialsTips.GT15,
    GT16 = gavrialsTips.GT16,
    GT17 = gavrialsTips.GT17,
    GT18 = gavrialsTips.GT18,
    GT19 = gavrialsTips.GT19,
    GT20 = gavrialsTips.GT20,
    GT21 = gavrialsTips.GT21,
    GT22 = gavrialsTips.GT22,
    GT23 = gavrialsTips.GT23,
    GT24 = gavrialsTips.GT24,
    GT25 = gavrialsTips.GT25,
    GT26 = gavrialsTips.GT26,
    GT27 = gavrialsTips.GT27,

    -- New Additional Events
    BE = auraEvent.BE,      -- Aura/Buff Event
    GR = guildRosterEvent.GR, -- Guild Roster Update Event
    BH = bigHitEvent.BH,      -- Big Hit Event

    -- New Guild/Instance Events
    LI    = leftInstanceEvent.LI,
    GLU   = guildLevelUpEvent.GLU,
    GAch  = guildAchievementEvent.GAch,
    GLH   = guildLowHealthEvent.GLH,
    GEI   = guildEnteredInstanceEvent.GEI,
}

--=========================================================================== 
-- Expose the Complete Dictionary Globally 
--=========================================================================== 
local dict = {
    eventTypeLookup = eventTypeLookup,
    eventIcons      = eventIcons,
    eventSounds     = eventSounds,
    allEvents       = allEvents,
}

EventsDictionary = dict

return dict
