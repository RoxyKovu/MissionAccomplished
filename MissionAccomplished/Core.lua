MissionAccomplished = MissionAccomplished or {}

-- Ensure the database table exists
MissionAccomplishedDB = MissionAccomplishedDB or {}

---------------------------------------------------------------
-- Force the toggle function for the UI XP Bar (ExperienceBar)
---------------------------------------------------------------
MissionAccomplished_ExperienceBar_SetShown = function(enable)
    MissionAccomplishedDB.enableUIXPBar = enable
    -- Stub: Actual functionality will be replaced when ExperienceBar.lua loads.
end
_G.MissionAccomplished_ExperienceBar_SetShown = MissionAccomplished_ExperienceBar_SetShown

---------------------------------------------------------------
-- Force the toggle function for the Moveable XP Bar (Bar.lua)
---------------------------------------------------------------
MissionAccomplished_Bar_SetShown = function(enable)
    MissionAccomplishedDB.enableMoveableXPBar = enable
    -- Stub: Actual functionality will be replaced when Bar.lua loads.
end
_G.MissionAccomplished_Bar_SetShown = MissionAccomplished_Bar_SetShown


---------------------------------------------------------------
-- XP Requirements Table (Classic style up to level 60)
-- NOTE: The 60th value represents the XP needed to go from level 60 to 61.
-- For progress toward level 60, we sum only the first 59 levels.
---------------------------------------------------------------
local XP_REQUIREMENTS = {
    400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,
    8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
    25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,
    50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,
    95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,
    153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800, 217400,
}

---------------------------------------------------------------
-- XP Calculation Functions
---------------------------------------------------------------

-- Returns the total XP earned from level 1 up to (but not including) level 60.
-- For players at level 60 or higher, we sum XP for levels 1 to 59 and then add the current XP on level 60.
function MissionAccomplished.GetTotalXPSoFar()
    local level = UnitLevel("player") or 1
    local xpSoFar = 0

    if level >= 60 then
        for i = 1, 59 do
            xpSoFar = xpSoFar + (XP_REQUIREMENTS[i] or 0)
        end
        xpSoFar = xpSoFar + (UnitXP("player") or 0)
    else
        for i = 1, (level - 1) do
            xpSoFar = xpSoFar + (XP_REQUIREMENTS[i] or 0)
        end
        xpSoFar = xpSoFar + (UnitXP("player") or 0)
    end

    return xpSoFar
end

-- Returns the total XP required to reach level 60 (summing levels 1 to 59).
function MissionAccomplished.GetXPMaxTo60()
    local xpMax = 0
    for i = 1, 59 do
        xpMax = xpMax + (XP_REQUIREMENTS[i] or 0)
    end
    return xpMax
end

-- Returns the progress percentage toward level 60.
-- If the player is level 60 or higher, returns 100.
function MissionAccomplished.GetProgressPercentage()
    local level = UnitLevel("player") or 1
    if level >= 60 then
        return 100
    end

    local totalXP = MissionAccomplished.GetTotalXPSoFar()
    local xpMax   = MissionAccomplished.GetXPMaxTo60()
    if xpMax > 0 then
        return (totalXP / xpMax) * 100
    else
        return 0
    end
end

-- Returns any overflow XP beyond what is needed to reach level 60.
-- (For players below level 60, this returns 0.)
function MissionAccomplished.GetOverflowXP()
    local level = UnitLevel("player") or 1
    if level < 60 then
        return 0
    end
    local totalXP = MissionAccomplished.GetTotalXPSoFar()
    local xpMax   = MissionAccomplished.GetXPMaxTo60()
    local overflow = totalXP - xpMax
    return (overflow > 0) and overflow or 0
end

---------------------------------------------------------------
-- Time Formatting & Rate Functions
---------------------------------------------------------------

function MissionAccomplished.FormatSeconds(seconds)
    local weeks   = math.floor(seconds / 604800) -- 7*24*3600
    seconds       = seconds % 604800
    local days    = math.floor(seconds / 86400)
    seconds       = seconds % 86400
    local hours   = math.floor(seconds / 3600)
    seconds       = seconds % 3600
    local minutes = math.floor(seconds / 60)
    return string.format("%d weeks, %d days, %d hours, %d minutes", weeks, days, hours, minutes)
end

function MissionAccomplished.GetOverallXPPerHour()
    local totalXP = MissionAccomplished.GetTotalXPSoFar()
    local xpMax   = MissionAccomplished.GetXPMaxTo60()
    local totalTimePlayed = MissionAccomplishedDB and MissionAccomplishedDB.totalTimePlayed or 0

    if totalTimePlayed < 60 or totalXP <= 0 or totalXP >= xpMax then
        return 0
    end

    local hoursPlayed = totalTimePlayed / 3600
    return totalXP / hoursPlayed
end

function MissionAccomplished.GetTimeToLevel60()
    local xpPerHour = MissionAccomplished.GetOverallXPPerHour()
    if xpPerHour <= 0 then
        return 0
    end

    local totalXP = MissionAccomplished.GetTotalXPSoFar()
    local xpMax   = MissionAccomplished.GetXPMaxTo60()
    local remainingXP = xpMax - totalXP
    if remainingXP <= 0 then
        return 0
    end

    local hoursTo60 = remainingXP / xpPerHour
    return hoursTo60 * 3600 -- seconds
end

function MissionAccomplished.GetCombatXPPerHour()
    if not MissionAccomplishedDB then return 0 end

    local combatTime = MissionAccomplishedDB.totalCombatTime or 0
    local totalXP    = MissionAccomplished.GetTotalXPSoFar()

    if combatTime <= 0 or totalXP <= 0 then
        return 0
    end

    local hoursInCombat = combatTime / 3600
    return totalXP / hoursInCombat
end

function MissionAccomplished.GetEnemiesPerHour()
    if not MissionAccomplishedDB then return 0 end

    local combatTime   = MissionAccomplishedDB.totalCombatTime or 0
    local totalEnemies = MissionAccomplishedDB.totalEnemies or 0

    if combatTime <= 0 or totalEnemies <= 0 then
        return 0
    end

    return (totalEnemies / combatTime) * 3600
end

---------------------------------------------------------------
-- Time Played Tracking & Welcome Message
---------------------------------------------------------------
local totalTimePlayed = 0
local welcomeMessageShown = false

function MissionAccomplished.GetTotalTimePlayed()
    totalTimePlayed = totalTimePlayed or 0

    local weeks   = math.floor(totalTimePlayed / (7 * 24 * 3600))
    local days    = math.floor((totalTimePlayed % (7 * 24 * 3600)) / (24 * 3600))
    local hours   = math.floor((totalTimePlayed % (24 * 3600)) / 3600)
    local mins    = math.floor((totalTimePlayed % 3600) / 60)

    return string.format("%d weeks, %d days, %d hours, %d minutes", weeks, days, hours, mins)
end

local function MissionAccomplished_DisplayWelcomeMessage()
    local playerName = UnitName("player") or "Player"
    local totalXP    = MissionAccomplished.GetTotalXPSoFar()
    local xpMax      = MissionAccomplished.GetXPMaxTo60()
    local remainingXP= xpMax - totalXP
    local percentComplete = (xpMax > 0) and (totalXP / xpMax * 100) or 0

    totalTimePlayed = totalTimePlayed or 0

    local xpPerHour     = 0
    local estimatedTime = 0
    local timePlayedStr = "insufficient data"

    if totalTimePlayed >= 60 and totalXP > 0 then
        local hoursPlayed = totalTimePlayed / 3600
        xpPerHour = totalXP / hoursPlayed
        timePlayedStr = MissionAccomplished.GetTotalTimePlayed()

        if xpPerHour > 0 and totalXP < xpMax then
            local hoursTo60 = remainingXP / xpPerHour
            estimatedTime = hoursTo60 * 3600
        end
    end

    local weeks   = math.floor(estimatedTime / 604800)
    local days    = math.floor((estimatedTime % 604800) / 86400)
    local hours   = math.floor((estimatedTime % 86400) / 3600)
    local minutes = math.floor((estimatedTime % 3600) / 60)

    local welcomeMessage = string.format(
        "|cff00ff00MissionAccomplished started.|r\n" ..
        "|cffffd700Gavrial:|r \"Welcome back, %s. You have gained |cff00ff00%d XP|r over |cff00ff00%s|r, " ..
        "which averages to |cff00ff00%.1f XP/hour|r. " ..
        "Estimated time to level 60: |cff00ff00%d weeks, %d days, %d hours, %d minutes|r.\"",
        playerName,
        totalXP,
        timePlayedStr,
        xpPerHour,
        weeks, days, hours, minutes
    )

    welcomeMessageShown = true
    -- The welcome message is displayed via the event system (not printed to chat)
end

---------------------------------------------------------------
-- Initialization Frame
---------------------------------------------------------------
local coreFrame = CreateFrame("Frame", "MissionAccomplishedCoreEventFrame")
coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:RegisterEvent("TIME_PLAYED_MSG")

coreFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MissionAccomplished" then
            MissionAccomplished_InitializeDB()
            if type(MissionAccomplished_Icon_Setup) == "function" then
                MissionAccomplished_Icon_Setup()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        RequestTimePlayed()
        C_Timer.After(5, function()
            if not welcomeMessageShown and totalTimePlayed > 0 then
                MissionAccomplished_DisplayWelcomeMessage()
            else
                C_Timer.After(1, function()
                    if not welcomeMessageShown then
                        MissionAccomplished_DisplayWelcomeMessage()
                    end
                end)
            end
        end)
    elseif event == "TIME_PLAYED_MSG" then
        local playedTotal = ...
        totalTimePlayed = playedTotal or 0
        MissionAccomplishedDB.totalTimePlayed = totalTimePlayed
        if not welcomeMessageShown then
            MissionAccomplished_DisplayWelcomeMessage()
        end
    end
end)

---------------------------------------------------------------
-- Database Initialization
---------------------------------------------------------------
function MissionAccomplished_InitializeDB()
    if not MissionAccomplishedDB then
        MissionAccomplishedDB = {}
    end

    MissionAccomplishedDB.totalTimePlayed   = MissionAccomplishedDB.totalTimePlayed or 0
    totalTimePlayed = MissionAccomplishedDB.totalTimePlayed

    MissionAccomplishedDB.totalDamage       = MissionAccomplishedDB.totalDamage or 0
    MissionAccomplishedDB.highestDamage     = MissionAccomplishedDB.highestDamage or 0
    MissionAccomplishedDB.totalEnemies      = MissionAccomplishedDB.totalEnemies or 0
    MissionAccomplishedDB.totalCombatTime   = MissionAccomplishedDB.totalCombatTime or 0
    MissionAccomplishedDB.lowestHP          = MissionAccomplishedDB.lowestHP or nil
end

---------------------------------------------------------------
-- Combat Data Tracking
---------------------------------------------------------------
local combatFrame = CreateFrame("Frame", "MissionAccomplishedCombatEventFrame")
combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function FindUnitIDByGUID(guid)
    if guid == UnitGUID("target") then
        return "target"
    elseif guid == UnitGUID("focus") then
        return "focus"
    else
        for i = 1, 5 do
            local nameplate = "nameplate" .. i
            if guid == UnitGUID(nameplate) then
                return nameplate
            end
        end
    end
    return nil
end

local function IsDamageEligible(damage, destGUID)
    if damage > 5000 then
        return false
    end

    local unitID = FindUnitIDByGUID(destGUID)
    if not unitID then
        return false
    end

    local mobLevel = UnitLevel(unitID)
    local playerLevel = UnitLevel("player") or 1
    if not mobLevel or mobLevel < 1 then
        return false
    end

    if mobLevel < (playerLevel - 5) then
        return false
    end

    return true
end

combatFrame:SetScript("OnEvent", function(self, event)
    local timestamp, subevent, hideCaster,
          sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")

    if (sourceGUID == playerGUID) or (petGUID and sourceGUID == petGUID) then
        if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
            local damage = select(12, CombatLogGetCurrentEventInfo())
            if type(damage) == "number" and damage > 0 then
                if IsDamageEligible(damage, destGUID) then
                    MissionAccomplishedDB.totalDamage = (MissionAccomplishedDB.totalDamage or 0) + damage
                    if damage > (MissionAccomplishedDB.highestDamage or 0) then
                        MissionAccomplishedDB.highestDamage = damage
                    end
                end
            end
        end
    end

    if subevent == "UNIT_DIED" then
        if destFlags and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
            MissionAccomplishedDB.totalEnemies = (MissionAccomplishedDB.totalEnemies or 0) + 1
        end
    end
end)

---------------------------------------------------------------
-- Track Lowest HP
---------------------------------------------------------------
local hpFrame = CreateFrame("Frame", "MissionAccomplishedHPFrame")
hpFrame:RegisterEvent("UNIT_HEALTH")
hpFrame:SetScript("OnEvent", function(_, event, unit)
    if unit == "player" then
        local currentHP = UnitHealth("player")
        if not MissionAccomplishedDB.lowestHP or currentHP < MissionAccomplishedDB.lowestHP then
            MissionAccomplishedDB.lowestHP = currentHP
        end
    end
end)

---------------------------------------------------------------
-- Continuous Combat Time Tracking
---------------------------------------------------------------
local combatTimeFrame = CreateFrame("Frame", "MissionAccomplishedCombatTimeFrame")
combatTimeFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatTimeFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local inCombat = false
local lastUpdate = 0

combatTimeFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        lastUpdate = GetTime()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if inCombat then
            local now = GetTime()
            local duration = now - lastUpdate
            if duration > 0 then
                MissionAccomplishedDB.totalCombatTime = (MissionAccomplishedDB.totalCombatTime or 0) + duration
            end
            inCombat = false
        end
    end
end)

combatTimeFrame:SetScript("OnUpdate", function(self, elapsed)
    if inCombat then
        local now = GetTime()
        local delta = now - lastUpdate
        if delta >= 1.0 then
            MissionAccomplishedDB.totalCombatTime = (MissionAccomplishedDB.totalCombatTime or 0) + delta
            lastUpdate = now
        end
    end
end)
