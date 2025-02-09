--=============================================================================
-- GavrialCorner.lua
--=============================================================================
-- Creates a custom frame for the "Gavrial's Corner" tab with:
--   1) Journey Data (overall for the current character)
--   2) Combat Data (for the current character)
--   3) Adventurers on their Journey (records for characters that are below level 60)
--   4) Hall of Legends (records for characters that have reached level 60)
--
-- Enhanced styling: more color, spacing, and simpler lines.
-- Removes "Combat XP/hour" from the display.
-- Clamps any single-strike damage above 5000 as "N/A" to avoid impossible hits.
--
-- NOTE:
--   This file now pulls all XP, time, and rate calculations from the Core module
--   (MissionAccomplished.GetTotalXPSoFar, GetXPMaxTo60, GetProgressPercentage, etc.)
--   to ensure consistency. Any duplicate calculations have been removed.
--
--   A new field "bankalt" has been added to each character's record (default: false).
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
        local tex    = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes.blp"
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
        local tex    = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races.blp"
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
-- (B) Main "GavrialCornerContent" Function (with Multiple Sections and Scrolling)
--------------------------------------------------
function GavrialCornerContent()

    -- If the frame already exists, show and return it.
    if _G.SettingsFrameContent.journeyFrame then
        _G.SettingsFrameContent.journeyFrame:GetParent():Show()  -- ensure scroll frame is shown
        return _G.SettingsFrameContent.journeyFrame:GetParent()
    end

    --------------------------------------------------
    -- 1) Create the main scroll frame which fills the tab content area
    --------------------------------------------------
    local parentFrame = _G.SettingsFrameContent.contentFrame
-- Create a named scroll frame
local scrollFrame = CreateFrame("ScrollFrame", "MyScrollFrame", parentFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetAllPoints(parentFrame)

-- Adjust the scroll bar position (move it to the left side)
local scrollBar = _G["MyScrollFrameScrollBar"]
if scrollBar then
    scrollBar:ClearAllPoints()
    -- Anchor the scroll bar on the left side of the scroll frame
scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -5, -20)
scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMLEFT", -5, 20)

end


    -- Create the content frame (journeyFrame) that will be the scroll child.
    local journeyFrame = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    -- Set a size larger than the parent to enable scrolling; adjust height as needed.
    journeyFrame:SetSize(parentFrame:GetWidth(), 600)
    journeyFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    journeyFrame:SetBackdropColor(0, 0, 0, 0.6)
    scrollFrame:SetScrollChild(journeyFrame)

    --------------------------------------------------
    -- 2) Background Image & Main Title
    --------------------------------------------------
    local bgTexture = journeyFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bgTexture:SetAllPoints()
    bgTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\Journey.blp")
    bgTexture:SetAlpha(0.15)
    bgTexture:SetDrawLayer("BACKGROUND", -8)

    local title = journeyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", journeyFrame, "TOP", 10, -10)
    title:SetFont("Fonts\\MORPHEUS.TTF", 32, "OUTLINE")
    title:SetText("|cffffff00Gavrial's Corner|r")

    local icon = journeyFrame:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp")
    icon:SetSize(32, 32)
    icon:SetPoint("RIGHT", title, "LEFT", -5, 0)

    --------------------------------------------------
    -- 3) Gather Data from Core (for the current character)
    --------------------------------------------------
    local playerName    = UnitName("player") or "Unknown"
    local level         = UnitLevel("player") or 1

    local className     = (select(1, UnitClass("player"))) or "Unknown"
    className           = ProperCase(className)
    local raceName      = UnitRace("player") or "Unknown"
    local classIcon     = GetClassIcon(className)
    local raceIcon      = GetRaceIcon(raceName)

    local totalXP       = MissionAccomplished.GetTotalXPSoFar()
    local xpMax         = MissionAccomplished.GetXPMaxTo60()
    local percent       = MissionAccomplished.GetProgressPercentage()
    local remain        = xpMax - totalXP

    local timePlayedStr = MissionAccomplished.GetTotalTimePlayed() or "N/A"
    local xpPerHour     = MissionAccomplished.GetOverallXPPerHour() or 0
    local secsTo60      = MissionAccomplished.GetTimeToLevel60() or 0
    local timeTo60Str   = MissionAccomplished.FormatSeconds(secsTo60)

    --------------------------------------------------
    -- 4) Build Section Content Strings for Current Character
    --------------------------------------------------
    local journeyContent =
          string.format("|cff99ccffName:|r |cff00ff00%s|r\n", playerName) ..
          string.format("|cff99ccffRace/Class:|r %s %s  %s %s\n", raceIcon, raceName, classIcon, className) ..
          string.format("|cff99ccffLevel:|r |cff00ff00%d|r\n", level) ..
          string.format("|cff99ccffTotal XP:|r |cff00ff00%d|r / |cffffd700%d|r\n", totalXP, xpMax) ..
          string.format("|cff99ccffProgress:|r |cffffd700%.1f%%|r\n", percent) ..
          string.format("|cff99ccffRemaining XP:|r |cffffd700%d|r\n", remain) ..
          string.format("|cff99ccffTime Played:|r |cff00ffff%s|r\n", timePlayedStr) ..
          string.format("|cff99ccffXP/hour:|r |cff00ff00%.0f|r\n", xpPerHour) ..
          string.format("|cff99ccffEst. Time to 60:|r |cffffd700%s|r", timeTo60Str)

    local enemiesHour   = MissionAccomplished.GetEnemiesPerHour() or 0
    local lowestHP      = MissionAccomplishedDB.lowestHP or "N/A"
    local highestDamage = MissionAccomplishedDB.highestDamage or 0
    local totalDamage   = MissionAccomplishedDB.totalDamage or 0
    local totalCbtTime  = MissionAccomplishedDB.totalCombatTime or 0
    local avgDPS        = (totalCbtTime > 0) and (totalDamage / totalCbtTime) or 0

    local singleStrikeDisplay = highestDamage
    if singleStrikeDisplay > 5000 then
        singleStrikeDisplay = "N/A"
    end

    local combatContent =
          string.format("|cff99ccffLowest HP Seen:|r |cff00ff00%s|r\n", lowestHP) ..
          string.format("|cff99ccffMost Damage in a Strike:|r |cff00ff00%s|r\n", tostring(singleStrikeDisplay)) ..
          string.format("|cff99ccffAverage DPS:|r |cff00ff00%.1f|r\n", avgDPS) ..
          string.format("|cff99ccffEnemies Killed per Hour:|r |cff00ff00%.0f|r", enemiesHour)

    --------------------------------------------------
    -- 5) Save/Update Records for Multiple Characters
    --------------------------------------------------
    if not MissionAccomplishedDB.adventurers then
        MissionAccomplishedDB.adventurers = {}
    end
    if not MissionAccomplishedDB.hallOfLegends then
        MissionAccomplishedDB.hallOfLegends = {}
    end

    local function UpdateRecord(tbl, record)
        local found = false
        for i, rec in ipairs(tbl) do
            if rec.name == record.name then
                tbl[i] = record
                found = true
                break
            end
        end
        if not found then
            table.insert(tbl, record)
        end
    end

    local currentRecord = {
        name       = playerName,
        race       = raceName,
        class      = className,
        level      = level,
        totalXP    = totalXP,
        xpMax      = xpMax,
        percent    = percent,  -- progress percentage
        timePlayed = timePlayedStr,
        xpPerHour  = xpPerHour,
        lastPlayed = date("%B %d, %Y"),  -- current date in "May 24, 2025" format
        date       = nil,  -- will be set if level >= 60
        bankalt    = false,  -- new flag; default is false
    }

    if level < 60 then
        UpdateRecord(MissionAccomplishedDB.adventurers, currentRecord)
    else
        if not currentRecord.date then
            currentRecord.date = "Unknown"
        end
        UpdateRecord(MissionAccomplishedDB.hallOfLegends, currentRecord)
    end

    --------------------------------------------------
    -- 6) Build Content Strings for Multiple Characters
    --------------------------------------------------
    -- (a) Adventurers on their Journey (non-60 characters)
    -- Format: [RaceIcon][ClassIcon] Name the Class  |cff99ccffLevel:|r [level]  |cff99ccffProgress:|r [progress]%  |cff99ccffLast Seen:|r [date]
    local adventurersContent = ""
    for i, record in ipairs(MissionAccomplishedDB.adventurers) do
        local recRaceIcon  = GetRaceIcon(record.race or "Unknown")
        local recClassIcon = GetClassIcon(record.class or "Unknown")
        adventurersContent = adventurersContent ..
            string.format("%s%s %s the %s  |cff99ccffLevel:|r |cff00ff00%d|r  |cff99ccffProgress:|r |cff00ff00%.1f%%|r  |cff99ccffLast Seen:|r |cff00ffff%s|r\n",
                          recRaceIcon, recClassIcon, record.name, record.class,
                          record.level, record.percent, record.lastPlayed or "N/A")
    end
    if adventurersContent == "" then
        adventurersContent = "No adventurers on their journey yet."
    end

-- (b) Hall of Legends (level-60 characters)
local hallOfLegendsContent = ""
for i, record in ipairs(MissionAccomplishedDB.hallOfLegends) do
    local recRaceIcon  = GetRaceIcon(record.race or "Unknown")
    local recClassIcon = GetClassIcon(record.class or "Unknown")
    hallOfLegendsContent = hallOfLegendsContent ..
        string.format("%s%s %s the %s  |cff99ccffLevel:|r |cff00ff00%d|r  |cff99ccffCompleted on:|r |cff00ff00%s|r\n",
                      recRaceIcon, recClassIcon, record.name, record.class,
                      record.level, record.date)
end
if hallOfLegendsContent == "" then
    hallOfLegendsContent = "No Hall of Legends entries yet."
end


    --------------------------------------------------
    -- 7) Create Section Frames for Modular Layout (with Smaller Fonts & Heights)
    --------------------------------------------------
    local function CreateSection(parent, titleText, content)
        local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        frame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 16,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

        local header = frame:CreateFontString(nil, "OVERLAY")
        -- Use the same font type as the main title (MORPHEUS) for section headers.
        header:SetFont("Fonts\\MORPHEUS.TTF", 14, "OUTLINE")
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
        header:SetText(titleText)

        local text = frame:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        text:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
        text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 3)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        text:SetSpacing(2)
        text:SetWordWrap(true)
        text:SetNonSpaceWrap(true)  -- Allows breaking long words/numbers without spaces.
        text:SetText(content)

        return frame
    end

    -- Adjusted section heights for a more compact layout.
    local sectionSpacing    = 8
    local journeyHeight     = 100
    local combatHeight      = 80
    local adventurersHeight = 80
    local legendsHeight     = 100

    local journeySectionFrame = CreateSection(journeyFrame, "Journey Data", journeyContent)
    journeySectionFrame:SetPoint("TOPLEFT", journeyFrame, "TOPLEFT", 20, -60)
    journeySectionFrame:SetPoint("RIGHT", journeyFrame, "RIGHT", -5, 0)
    journeySectionFrame:SetHeight(journeyHeight)

    local combatSectionFrame = CreateSection(journeyFrame, "Combat Data", combatContent)
    combatSectionFrame:SetPoint("TOPLEFT", journeySectionFrame, "BOTTOMLEFT", 0, -sectionSpacing)
    combatSectionFrame:SetPoint("RIGHT", journeyFrame, "RIGHT", -5, 0)
    combatSectionFrame:SetHeight(combatHeight)

    local adventurersSectionFrame = CreateSection(journeyFrame, "Adventurers on their Journey", adventurersContent)
    adventurersSectionFrame:SetPoint("TOPLEFT", combatSectionFrame, "BOTTOMLEFT", 0, -sectionSpacing)
    adventurersSectionFrame:SetPoint("RIGHT", journeyFrame, "RIGHT", -5, 0)
    adventurersSectionFrame:SetHeight(adventurersHeight)

    local legendsSectionFrame = CreateSection(journeyFrame, "Hall of Legends", hallOfLegendsContent)
    legendsSectionFrame:SetPoint("TOPLEFT", adventurersSectionFrame, "BOTTOMLEFT", 0, -sectionSpacing)
    legendsSectionFrame:SetPoint("RIGHT", journeyFrame, "RIGHT", -5, 0)
    legendsSectionFrame:SetHeight(legendsHeight)

    --------------------------------------------------
    -- 8) Cache & Return the Scroll Frame (which contains the journeyFrame)
    --------------------------------------------------
    _G.SettingsFrameContent.journeyFrame = journeyFrame
    return scrollFrame
end

-- Expose globally
_G.GavrialCornerContent = GavrialCornerContent
