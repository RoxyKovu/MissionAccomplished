--------------------------------------------------
-- Guild.lua
--------------------------------------------------

-- DEBUG flag (set to true for debugging prints, false when finished)
local DEBUG = false

--------------------------------------------------
-- Local Helper Functions
--------------------------------------------------
local function ProperCase(str)
    if not str or str == "" then
        return "Unknown"
    end
    return str:sub(1,1):upper() .. str:sub(2):lower()
end

local function CleanName(name)
    if not name then return "Unknown" end
    local clean = name:match("^(.-)%-.+") or name
    return clean
end

local function ColorToHex(color)
    return string.format("|cff%02x%02x%02x", math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255))
end

local customClassColors = {
    ["Death Knight"] = { r = 0xC4/255, g = 0x1F/255, b = 0x3B/255 },
    ["Demon Hunter"] = { r = 0xA3/255, g = 0x30/255, b = 0xC9/255 },
    ["Druid"]        = { r = 0xFF/255, g = 0x7D/255, b = 0x0A/255 },
    ["Evoker"]       = { r = 0x33/255, g = 0x93/255, b = 0x7F/255 },
    ["Hunter"]       = { r = 0xAB/255, g = 0xD4/255, b = 0x73/255 },
    ["Mage"]         = { r = 0x69/255, g = 0xCC/255, b = 0xF0/255 },
    ["Monk"]         = { r = 0x00/255, g = 0xFF/255, b = 0x96/255 },
    ["Paladin"]      = { r = 0xF5/255, g = 0x8C/255, b = 0xBA/255 },
    ["Priest"]       = { r = 1,        g = 1,        b = 1 },
    ["Rogue"]        = { r = 0xFF/255, g = 0xF5/255, b = 0x69/255 },
    ["Shaman"]       = { r = 0x00/255, g = 0x70/255, b = 0xDE/255 },
    ["Warlock"]      = { r = 0x94/255, g = 0x82/255, b = 0xC9/255 },
    ["Warrior"]      = { r = 0xC7/255, g = 0x9C/255, b = 0x6E/255 },
}

local allClassesForStats = { "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Mage", "Druid", "Shaman", "Warlock" }

-- Faction availability for stats grid
local function IsClassAvailableForFaction(className)
    local faction = UnitFactionGroup("player")
    if faction == "Alliance" then
        if className == "Shaman" then
            return false
        end
    elseif faction == "Horde" then
        if className == "Paladin" then
            return false
        end
    end
    return true
end

local classIconCoords = {
    Warrior    = { left = 0.00, right = 0.25, top = 0.00, bottom = 0.25 },
    Mage       = { left = 0.25, right = 0.50, top = 0.00, bottom = 0.25 },
    Rogue      = { left = 0.50, right = 0.75, top = 0.00, bottom = 0.25 },
    Druid      = { left = 0.75, right = 1.00, top = 0.00, bottom = 0.25 },
    Hunter     = { left = 0.00, right = 0.25, top = 0.25, bottom = 0.50 },
    Shaman     = { left = 0.25, right = 0.50, top = 0.25, bottom = 0.50 },
    Priest     = { left = 0.50, right = 0.75, top = 0.25, bottom = 0.50 },
    Warlock    = { left = 0.75, right = 1.00, top = 0.25, bottom = 0.50 },
    Paladin    = { left = 0.00, right = 0.25, top = 0.50, bottom = 0.75 },
}

local function GetClassIcon(className)
    local proper = ProperCase(className)
    local coords = classIconCoords[proper]
    if coords then
        local tex = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes.blp"
        local left   = coords.left * 256
        local right  = coords.right * 256
        local top    = coords.top * 256
        local bottom = coords.bottom * 256
        return string.format("|T%s:16:16:0:0:256:256:%.0f:%.0f:%.0f:%.0f|t", tex, left, right, top, bottom)
    end
    return ""
end

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
    local sex = UnitSex("player")
    local sexKey = (sex == 2) and "Male" or "Female"
    local data = (raceIcons[sexKey] or {})[raceName]
    if data then
        local tex = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races.blp"
        local left   = data.left * 256
        local right  = data.right * 256
        local top    = data.top * 256
        local bottom = data.bottom * 256
        return string.format("|T%s:16:16:0:0:256:256:%.0f:%.0f:%.0f:%.0f|t", tex, left, right, top, bottom)
    end
    return ""
end

local trophySymbol = "|TInterface\\Icons\\spell_holy_spellwarding:16:16:0:0|t"

--------------------------------------------------
-- Main Guild Functions Content
--------------------------------------------------
local function GuildFunctionsContent()
    local parentFrame = _G.SettingsFrameContent and _G.SettingsFrameContent.contentFrame
    if not parentFrame then
        parentFrame = CreateFrame("Frame", "TempContentFrame", UIParent)
        parentFrame:SetSize(520, 500)
        parentFrame:SetPoint("CENTER")
        _G.SettingsFrameContent = _G.SettingsFrameContent or {}
        _G.SettingsFrameContent.contentFrame = parentFrame
    end

    local frame = CreateFrame("Frame", "MissionAccomplishedGuildFunctionsFrame", parentFrame, "BackdropTemplate")
    frame:SetAllPoints(parentFrame)

    local backgroundTexture = frame:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetAllPoints(frame)
    backgroundTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\Guild.blp")
    backgroundTexture:SetAlpha(0.1)
    backgroundTexture:SetHorizTile(false)
    backgroundTexture:SetVertTile(false)
    local darkMask = frame:CreateTexture(nil, "ARTWORK")
    darkMask:SetAllPoints(frame)
    darkMask:SetColorTexture(0, 0, 0, 0.93)

    frame:SetBackdrop({
        bgFile = "Interface\\AddOns\\MissionAccomplished\\Contents\\Guild.blp",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(1, 1, 1, 1)

    local guildName = GetGuildInfo("player") or "Guild"
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetFont("Fonts\\MORPHEUS.TTF", 32, "OUTLINE")
    title:SetText("|cffcc99FF" .. guildName .. "|r")

    --------------------------------------------------
    -- Scroll Frame for the Member List
    --------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", "GuildMembersScrollFrame", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetSize(440, 300)
    scrollFrame:SetPoint("TOP", frame, "TOP", 0, -50)

    local contentFrame = CreateFrame("Frame", "GuildMembersContentFrame", scrollFrame)
    contentFrame:SetWidth(440)
    scrollFrame:SetScrollChild(contentFrame)

    --------------------------------------------------
    -- Build Member Lists (Online and Offline)
    --------------------------------------------------
    local onlineMembers = {}
    local offlineMembers = {}
    if IsInGuild() then
        GuildRoster()  -- Force a roster update
        local numTotal = GetNumGuildMembers()
        if DEBUG then print("Guild roster count:", numTotal) end
        for i = 1, numTotal do
            local name, _, _, level, class, zone, note, officerNote, online = GetGuildRosterInfo(i)
            local cleanName = CleanName(name)
            local progress = nil
            if _G.MissionAccomplished_GuildAddonMembers then
                for _, addonData in ipairs(_G.MissionAccomplished_GuildAddonMembers) do
                    if CleanName(addonData.name):lower() == cleanName:lower() then
                        progress = addonData.progress
                        break
                    end
                end
            end
            local memberData = {
                name = cleanName,
                race = "Unknown",  -- Classic doesn't reliably provide race info.
                class = class or "Unknown",
                level = level or 1,
                progress = progress
            }
            if online then
                table.insert(onlineMembers, memberData)
            else
                table.insert(offlineMembers, memberData)
            end
        end
    else
        table.insert(onlineMembers, {
            name = CleanName(UnitName("player")),
            race = UnitRace("player") or "Unknown",
            class = select(1, UnitClass("player")) or "Unknown",
            level = UnitLevel("player") or 1,
            progress = MissionAccomplished.GetProgressPercentage() or 0
        })
    end

    -- Ensure self data is present in onlineMembers.
    local selfName = CleanName(UnitName("player"))
    local selfData = {
        name = selfName,
        race = UnitRace("player") or "Unknown",
        class = select(1, UnitClass("player")) or "Unknown",
        level = UnitLevel("player") or 1,
        progress = MissionAccomplished.GetProgressPercentage() or 0
    }
    local foundSelf = false
    for i, member in ipairs(onlineMembers) do
        if member.name:lower() == selfName:lower() then
            onlineMembers[i] = selfData
            foundSelf = true
            break
        end
    end
    if not foundSelf then
        if DEBUG then print("Adding self data to onlineMembers.") end
        table.insert(onlineMembers, selfData)
    end

    -- Remove any self duplicates from offlineMembers.
    for i = #offlineMembers, 1, -1 do
        if offlineMembers[i].name:lower() == selfName:lower() then
            table.remove(offlineMembers, i)
        end
    end

    -- Sort the online members by level (descending) then name (alphabetical).
    table.sort(onlineMembers, function(a, b)
        if a.level == b.level then
            return a.name:lower() < b.name:lower()
        else
            return a.level > b.level
        end
    end)

    -- Sort the offline members by level (descending) then name (alphabetical).
    table.sort(offlineMembers, function(a, b)
        if a.level == b.level then
            return a.name:lower() < b.name:lower()
        else
            return a.level > b.level
        end
    end)

    local allMembers = {}
    -- Online members appear first.
    for _, member in ipairs(onlineMembers) do
        table.insert(allMembers, member)
    end
    -- Offline members follow.
    for _, member in ipairs(offlineMembers) do
        table.insert(allMembers, member)
    end

    local lineHeight = 20
    contentFrame:SetHeight(#allMembers * lineHeight)

    --------------------------------------------------
    -- Create a Frame for Each Guild Member
    --------------------------------------------------
    local allLineFrames = {}
    for i, member in ipairs(allMembers) do
        local lf = CreateFrame("Frame", nil, contentFrame)
        lf:SetSize(420, lineHeight)
        lf:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -((i-1)*lineHeight))
        local bg = lf:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(lf)
        lf.bg = bg
        local fs = lf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetAllPoints(lf)
        fs:SetJustifyH("LEFT")
        lf.fs = fs

        -- Build the line text and style for this member.
        local trophy = ""
        if member.level >= 60 then
            trophy = trophySymbol .. " "
        end
        local raceIcon = GetRaceIcon(member.race)
        local classIcon = GetClassIcon(member.class)
        local nameTheClass = string.format("%s the %s", member.name, ProperCase(member.class))
        local infoText = ""
        local isOnline = false
        for _, m in ipairs(onlineMembers) do
            if m.name:lower() == member.name:lower() then
                isOnline = true
                break
            end
        end
        if isOnline then
            if member.progress then
                infoText = string.format("Level: %d, Progress: %.1f%%", member.level, member.progress)
            else
                infoText = string.format("Level: %d, (does not have addon)", member.level)
            end
        else
            infoText = string.format("Level: %d | Offline", member.level)
        end
        local lineText = string.format("%s%s %s  %s | %s", trophy, raceIcon, classIcon, nameTheClass, infoText)
        lf.fs:SetText(lineText)

        local bgColor
        if isOnline and member.progress then
            local classKey = ProperCase(member.class)
            bgColor = customClassColors[classKey] or { r = 1, g = 1, b = 1 }
        elseif isOnline then
            bgColor = { r = 1, g = 0, b = 0 }
        else
            bgColor = { r = 0.5, g = 0.5, b = 0.5 }
        end
        local r, g, b = bgColor.r, bgColor.g, bgColor.b
        if member.level >= 60 then
            r, g, b = r * 0.6, g * 0.6, b * 0.6
        end
        lf.bg:SetColorTexture(r, g, b, 0.2)

        if isOnline and member.progress then
            local classKey = ProperCase(member.class)
            local clr = customClassColors[classKey] or { r = 1, g = 1, b = 1 }
            lf.fs:SetTextColor(clr.r, clr.g, clr.b, 0.8)
        elseif isOnline then
            lf.fs:SetTextColor(1, 0, 0, 0.8)
        else
            lf.fs:SetTextColor(0.5, 0.5, 0.5, 0.8)
        end

        lf:Show()
        allLineFrames[i] = lf
    end

    --------------------------------------------------
    -- Scroll Handler to Show/Hide Frames Based on Vertical Position
    --------------------------------------------------
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        self:SetVerticalScroll(offset)
        -- Update scroll thumb position
        FauxScrollFrame_Update(self, #allMembers, math.floor(300/lineHeight), lineHeight)
        for i, lf in ipairs(allLineFrames) do
            local posY = (i-1)*lineHeight - offset
            if posY + lineHeight >= 0 and posY <= 300 then
                lf:Show()
            else
                lf:Hide()
            end
        end
    end)
    scrollFrame:GetScript("OnVerticalScroll")(scrollFrame, 0)

    --------------------------------------------------
    -- Statistics Panel
    --------------------------------------------------
    local statsFrame = CreateFrame("Frame", "GuildStatsFrame", frame, "BackdropTemplate")
    statsFrame:SetSize(460, 130)
    statsFrame:SetPoint("TOP", scrollFrame, "BOTTOM", 0, -5)
    statsFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    statsFrame:SetBackdropColor(0, 0, 0, 0.5)

    local statsHeader = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsHeader:SetPoint("TOP", statsFrame, "TOP", 0, -10)
    statsHeader:SetJustifyH("CENTER")
    local totalLevel = 0
    local totalCount = 0
    local level60Count = 0
    local classCounts = {}
    if IsInGuild() then
        local numTotal = GetNumGuildMembers()
        for i = 1, numTotal do
            local name, _, _, level, class, zone, note, officerNote, online = GetGuildRosterInfo(i)
            if level then
                totalLevel = totalLevel + level
                totalCount = totalCount + 1
                if level >= 60 then
                    level60Count = level60Count + 1
                end
                local cls = ProperCase(class or "Unknown")
                classCounts[cls] = (classCounts[cls] or 0) + 1
            end
        end
    end
    local avgLevel = (totalCount > 0) and (totalLevel / totalCount) or 0
    statsHeader:SetText(string.format("Avg Level: %.1f  |  Level 60s: %d  |  Total Members: %d", avgLevel, level60Count, totalCount))

    local gridFrame = CreateFrame("Frame", nil, statsFrame)
    gridFrame:SetSize(440, 80)
    gridFrame:SetPoint("TOP", statsHeader, "BOTTOM", 0, -10)
    
    local cells = {}
    local faction = UnitFactionGroup("player")
    for _, cls in ipairs(allClassesForStats) do
        local available = IsClassAvailableForFaction(cls)
        local countText = ""
        if available then
            countText = tostring(classCounts[cls] or 0)
        else
            if faction == "Alliance" and cls == "Shaman" then
                countText = "Horde"
            elseif faction == "Horde" and cls == "Paladin" then
                countText = "Alliance"
            else
                countText = tostring(classCounts[cls] or 0)
            end
        end
        local icon = GetClassIcon(cls)
        local color = customClassColors[cls] or { r = 1, g = 1, b = 1 }
        local hexColor = ColorToHex(color)
        local cellStr = string.format("%s %s: %s", icon, available and (hexColor .. cls .. "|r") or ("|cff888888" .. cls .. "|r"), countText)
        table.insert(cells, { text = cellStr, available = available, cls = cls })
    end

    local cellsPerRow = 3
    local cellWidth = 440 / cellsPerRow
    local cellHeight = 80 / math.ceil(#cells / cellsPerRow)
    for i = 1, #cells do
        local cell = cells[i]
        local cellFrame = CreateFrame("Frame", nil, gridFrame, "BackdropTemplate")
        cellFrame:SetSize(cellWidth - 5, cellHeight - 5)
        local col = ((i - 1) % cellsPerRow)
        local row = math.floor((i - 1) / cellsPerRow)
        cellFrame:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", col * cellWidth + 5, - row * cellHeight - 5)
        cellFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        if cell.available then
            local clr = customClassColors[cell.cls] or { r = 1, g = 1, b = 1 }
            cellFrame:SetBackdropColor(clr.r, clr.g, clr.b, 0.1)
        else
            cellFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.1)
        end
        local cellFS = cellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cellFS:SetPoint("LEFT", cellFrame, "LEFT", 5, 0)
        cellFS:SetJustifyH("LEFT")
        cellFS:SetText(cell.text)
    end

    if DEBUG then
        print("Guild Statistics:")
        print("Average Level:", avgLevel, "Level 60s:", level60Count)
        for cls, cnt in pairs(classCounts) do
            print(cls, ":", cnt)
        end
    end

    return frame
end

--------------------------------------------------
-- Expose Guild Functions Content Globally
--------------------------------------------------
_G.MissionAccomplished_GuildContent = GuildFunctionsContent
