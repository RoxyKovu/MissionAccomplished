--=============================================================================
-- GavrialCorner.lua
--=============================================================================
-- Creates a custom frame for the "Gavrial's Corner" tab with:
--   1) Journey Data (overall)
--   2) Combat Data
--   3) Historical Data
-- Enhanced styling: more color, spacing, simpler lines. 
-- Removes "Combat XP/hour" from the display. 
-- Clamps any single-strike damage above 5000 as "N/A" to avoid impossible hits.
--
-- NOTE:
--   If you want to truly exclude giant hits from your DB, fix it in Core.lua 
--   (where highestDamage is set). This file just displays or clamps the result.
--=============================================================================

--------------------------------------------------
-- (A) Local Helper Functions
--------------------------------------------------

local function ProperCase(str)
    if not str or str == "" then
        return "Unknown"
    end
    return str:sub(1,1):upper() .. str:sub(2):lower()
end

-- Class icon coordinates (Classic: UI-CharacterCreate-Classes.blp)
local classIconCoords = {
    Warrior = { left = 0.00, right = 0.25, top = 0.00, bottom = 0.25 },
    Mage    = { left = 0.25, right = 0.50, top = 0.00, bottom = 0.25 },
    Rogue   = { left = 0.50, right = 0.75, top = 0.00, bottom = 0.25 },
    Druid   = { left = 0.75, right = 1.00, top = 0.00, bottom = 0.25 },

    Hunter  = { left = 0.00, right = 0.25, top = 0.25, bottom = 0.50 },
    Shaman  = { left = 0.25, right = 0.50, top = 0.25, bottom = 0.50 },
    Priest  = { left = 0.50, right = 0.75, top = 0.25, bottom = 0.50 },
    Warlock = { left = 0.75, right = 1.00, top = 0.25, bottom = 0.50 },

    Paladin = { left = 0.00, right = 0.25, top = 0.50, bottom = 0.75 },
}

local function GetClassIcon(className)
    local proper = ProperCase(className)
    local coords = classIconCoords[proper]
    if coords then
        local tex   = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes.blp"
        local left   = coords.left   * 256
        local right  = coords.right  * 256
        local top    = coords.top    * 256
        local bottom = coords.bottom * 256

        return string.format("|T%s:16:16:0:0:256:256:%.0f:%.0f:%.0f:%.0f|t",
                             tex, left, right, top, bottom)
    end
    return "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:0:0|t"
end

-- Race icon table (Classic: UI-CharacterCreate-Races.blp)
local raceIcons = {
    Male = {
        ["Human"]     = { left = 0.00, right = 0.25, top = 0.00, bottom = 0.25 },
        ["Dwarf"]     = { left = 0.25, right = 0.50, top = 0.00, bottom = 0.25 },
        ["Gnome"]     = { left = 0.50, right = 0.75, top = 0.00, bottom = 0.25 },
        ["Night Elf"] = { left = 0.75, right = 1.00, top = 0.00, bottom = 0.25 },

        ["Tauren"]    = { left = 0.00, right = 0.25, top = 0.25, bottom = 0.50 },
        ["Undead"]    = { left = 0.25, right = 0.50, top = 0.25, bottom = 0.50 },
        ["Troll"]     = { left = 0.50, right = 0.75, top = 0.25, bottom = 0.50 },
        ["Orc"]       = { left = 0.75, right = 1.00, top = 0.25, bottom = 0.50 },
    },
    Female = {
        ["Human"]     = { left = 0.00, right = 0.25, top = 0.50, bottom = 0.75 },
        ["Dwarf"]     = { left = 0.25, right = 0.50, top = 0.50, bottom = 0.75 },
        ["Gnome"]     = { left = 0.50, right = 0.75, top = 0.50, bottom = 0.75 },
        ["Night Elf"] = { left = 0.75, right = 1.00, top = 0.50, bottom = 0.75 },

        ["Tauren"]    = { left = 0.00, right = 0.25, top = 0.75, bottom = 1.00 },
        ["Undead"]    = { left = 0.25, right = 0.50, top = 0.75, bottom = 1.00 },
        ["Troll"]     = { left = 0.50, right = 0.75, top = 0.75, bottom = 1.00 },
        ["Orc"]       = { left = 0.75, right = 1.00, top = 0.75, bottom = 1.00 },
    },
}

local function GetRaceIcon(raceName)
    local sex = UnitSex("player")  -- 2=Male, 3=Female
    local sexKey = (sex == 2) and "Male" or "Female"
    local data = (raceIcons[sexKey] or {})[raceName]
    if data then
        local tex   = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races.blp"
        local left   = data.left   * 256
        local right  = data.right  * 256
        local top    = data.top    * 256
        local bottom = data.bottom * 256

        return string.format("|T%s:16:16:0:0:256:256:%.0f:%.0f:%.0f:%.0f|t",
                             tex, left, right, top, bottom)
    end
    return "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:0:0|t"
end

--------------------------------------------------
-- (B) Main "GavrialCornerContent" Function
--------------------------------------------------
function GavrialCornerContent()

    -- If we've already created this frame, just show & return it.
    if _G.SettingsFrameContent.journeyFrame then
        _G.SettingsFrameContent.journeyFrame:Show()
        return _G.SettingsFrameContent.journeyFrame
    end

    --------------------------------------------------
    -- 1) Create the frame (fills the tab content area)
    --------------------------------------------------
    local parentFrame = _G.SettingsFrameContent.contentFrame
    local journeyFrame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    journeyFrame:SetAllPoints(parentFrame)

    -- A subtle border/backdrop
    journeyFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    journeyFrame:SetBackdropColor(0, 0, 0, 0.6)

    --------------------------------------------------
    -- 2) Background Image
    --------------------------------------------------
    local bgTexture = journeyFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bgTexture:SetAllPoints()
    bgTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\Journey.blp")
    bgTexture:SetAlpha(0.15)
    bgTexture:SetDrawLayer("BACKGROUND", -8)

    --------------------------------------------------
    -- 3) Main FontString for content
    --------------------------------------------------
    local contentText = journeyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contentText:SetPoint("TOPLEFT", 20, -20)
    contentText:SetPoint("BOTTOMRIGHT", -20, 20)
    contentText:SetJustifyH("LEFT")
    contentText:SetJustifyV("TOP")
    contentText:SetSpacing(4)    -- line spacing
    contentText:SetWordWrap(true)

    --------------------------------------------------
    -- 4) Gather Data from Core.lua
    --------------------------------------------------
    local playerName = UnitName("player") or "Unknown"
    local level      = UnitLevel("player") or 1

    local className  = (select(1, UnitClass("player"))) or "Unknown"
    className        = ProperCase(className)
    local raceName   = UnitRace("player") or "Unknown"
    local classIcon  = GetClassIcon(className)
    local raceIcon   = GetRaceIcon(raceName)

    local totalXP    = MissionAccomplished.GetTotalXPSoFar()
    local xpMax      = MissionAccomplished.GetXPMaxTo60()
    local percent    = (xpMax > 0) and (totalXP / xpMax * 100) or 0
    local remain     = xpMax - totalXP

    local timePlayedStr   = MissionAccomplished.GetTotalTimePlayed() or "N/A"
    local xpPerHour       = MissionAccomplished.GetOverallXPPerHour() or 0
    local secsTo60        = MissionAccomplished.GetTimeToLevel60() or 0
    local timeTo60Str     = MissionAccomplished.FormatSeconds(secsTo60)

    -- Combat data
    local enemiesHour     = MissionAccomplished.GetEnemiesPerHour() or 0
    local lowestHP        = MissionAccomplishedDB.lowestHP or "N/A"
    local highestDamage   = MissionAccomplishedDB.highestDamage or 0
    local totalDamage     = MissionAccomplishedDB.totalDamage or 0
    local totalCbtTime    = MissionAccomplishedDB.totalCombatTime or 0
    local avgDPS          = (totalCbtTime > 0) and (totalDamage / totalCbtTime) or 0

    -- If highestDamage is suspiciously large (e.g. 14k?), display "N/A" instead.
    local singleStrikeDisplay = highestDamage
    if singleStrikeDisplay > 5000 then
        singleStrikeDisplay = "N/A"
    end

    --------------------------------------------------
    -- 5) Build Journey Data (Overall)
    --------------------------------------------------
    local journeySection = "|cff00ccff=== Journey Data ===|r\n" ..
        string.format("|cff99ccffName:|r |cff00ff00%s|r\n", playerName) ..
        string.format("|cff99ccffRace/Class:|r %s %s  %s %s\n", 
                      raceIcon, raceName, classIcon, className) ..
        string.format("|cff99ccffLevel:|r |cff00ff00%d|r\n", level) ..
        string.format("|cff99ccffTotal XP:|r |cff00ff00%d|r / |cffffd700%d|r\n", totalXP, xpMax) ..
        string.format("|cff99ccffProgress:|r |cffffd700%.1f%%|r\n", percent) ..
        string.format("|cff99ccffRemaining XP:|r |cffffd700%d|r\n", remain) ..
        string.format("|cff99ccffTime Played:|r |cff00ffff%s|r\n", timePlayedStr) ..
        string.format("|cff99ccffXP/hour:|r |cff00ff00%.0f|r\n", xpPerHour) ..
        string.format("|cff99ccffEst. Time to 60:|r |cffffd700%s|r\n", timeTo60Str) ..
        "\n"

    --------------------------------------------------
    -- 6) Build Combat Data (no more Combat XP/hour)
    --------------------------------------------------
    local combatSection = "|cff00ccff=== Combat Data ===|r\n" ..
        string.format("|cff99ccffLowest HP Seen:|r |cff00ff00%s|r\n", lowestHP) ..
        string.format("|cff99ccffMost Damage in a Strike:|r |cff00ff00%s|r\n", tostring(singleStrikeDisplay)) ..
        string.format("|cff99ccffAverage DPS:|r |cff00ff00%.1f|r\n", avgDPS) ..
        string.format("|cff99ccffEnemies Killed per Hour:|r |cff00ff00%.0f|r\n", enemiesHour) ..
        "\n"

    --------------------------------------------------
    -- 7) Build Historical Data
    --------------------------------------------------
    local best = MissionAccomplishedDB.best or {}
    -- Possibly update best record
    if level > (best.level or 0) then
        best.level   = level
        best.totalXP = totalXP
        best.xpMax   = xpMax
        best.percent = percent
        best.name    = playerName
        best.class   = className
        best.race    = raceName
        if level >= 60 then
            best.date = date("%Y-%m-%d")
        end
        MissionAccomplishedDB.best = best
    elseif level == (best.level or 0) then
        best.totalXP = totalXP
        best.xpMax   = xpMax
        best.percent = percent
        if not best.race or best.race == "Unknown" then
            best.race = raceName
        end
        MissionAccomplishedDB.best = best
    end

    local bestClassIcon = GetClassIcon(best.class or "Unknown")
    local bestRaceIcon  = GetRaceIcon(best.race or "Unknown")

    local historyHeader  = "|cff00ccff=== Historical Data ===|r\n"
    local historySection = ""

    if best.level and best.level >= 60 then
        historySection = historyHeader ..
            "|cff99ccff-- Hall of Legends --|r\n" ..
            string.format("|cff99ccffName:|r |cff00ff00%s|r\n", best.name or "N/A") ..
            string.format("|cff99ccffRace/Class:|r %s %s  %s %s\n", 
                          bestRaceIcon, best.race or "N/A",
                          bestClassIcon, best.class or "N/A") ..
            string.format("|cff99ccffDate Reached 60:|r |cff00ff00%s|r\n", best.date or "N/A")
    else
        historySection = historyHeader ..
            "|cff99ccff-- Best Record So Far --|r\n" ..
            string.format("|cff99ccffName:|r |cff00ff00%s|r\n", best.name or "N/A") ..
            string.format("|cff99ccffRace/Class:|r %s %s  %s %s\n",
                          bestRaceIcon, best.race or "N/A",
                          bestClassIcon, best.class or "N/A") ..
            string.format("|cff99ccffTotal XP:|r |cff00ff00%d|r / |cffffd700%d|r\n",
                          best.totalXP or 0, best.xpMax or 0) ..
            string.format("|cff99ccffProgress:|r |cffffd700%.1f%%|r\n", best.percent or 0)
    end

    --------------------------------------------------
    -- 8) Combine Everything & Set Text
    --------------------------------------------------
    local finalContent = journeySection .. combatSection .. historySection
    contentText:SetText(finalContent)

    --------------------------------------------------
    -- 9) Cache & Return the Frame
    --------------------------------------------------
    _G.SettingsFrameContent.journeyFrame = journeyFrame
    return journeyFrame
end

-- Expose globally
_G.GavrialCornerContent = GavrialCornerContent