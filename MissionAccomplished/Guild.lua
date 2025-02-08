-- DEBUG flag (set to true for debugging prints, false when finished)
local DEBUG = false

--------------------------------------------------
-- Class Short Codes and Reverse Lookup for Class Codes
--------------------------------------------------
local classCodes = {
    ["Warrior"] = "W", ["Paladin"] = "P", ["Hunter"] = "H", ["Rogue"] = "R",
    ["Priest"] = "PR", ["Death Knight"] = "DK", ["Shaman"] = "S", ["Mage"] = "M",
    ["Warlock"] = "WL", ["Druid"] = "D", ["Monk"] = "MO", ["Demon Hunter"] = "DH"
}
local classCodeToName = {}
for fullName, code in pairs(classCodes) do
    classCodeToName[code] = fullName
end

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

-- Expose GetRaceIcon globally
function GetRaceIcon(raceName)
    local sex = UnitSex("player")
    local sexKey = (sex == 2) and "Male" or "Female"
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

local trophySymbol = "|TInterface\\Icons\\achievement_level_60:16:16:0:0|t"

--------------------------------------------------
-- Helper: Get Profession Icon
--------------------------------------------------
local function GetProfessionIcon(profName)
    local iconMapping = {
        ["Blacksmithing"] = "trade_blacksmithing",
        ["Leatherworking"] = "trade_leatherworking",
        ["Alchemy"]        = "trade_alchemy",
        ["Herbalism"]      = "spell_nature_naturetouchgrow",
        ["Mining"]         = "trade_mining",
        ["Engineering"]    = "trade_engineering",
        ["Enchanting"]     = "trade_engraving",
        ["Tailoring"]      = "trade_tailoring",
        ["Skinning"]       = "inv_misc_pelt_wolf_01",
        ["Jewelcrafting"]  = "inv_misc_gem_01",
        ["Inscription"]    = "inv_inscription_tradeskill01",
        ["Cooking"]        = "inv_misc_food_15",
        ["First Aid"]      = "Spell_holy_sealofsacrifice",
        ["Fishing"]        = "trade_fishing",
    }
    local iconName = iconMapping[profName] or "INV_Misc_QuestionMark"
    return string.format("|TInterface\\Icons\\%s:12:12:0:0|t", iconName)
end

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

    -- Create a Refresh Button that does the following:
    -- 1. Updates guild data (calls GuildDatabaseBuild:SendCompressedPlayerInfo() if available)
    -- 2. Hides previous content and refreshes the Guild Functions tab exactly as if it were pressed.
    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(80, 22)
    refreshButton:SetText("Refresh")
    refreshButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    refreshButton:SetScript("OnClick", function(self)
        self:Disable()  -- Disable the button during refresh

        if IsInGuild() then
            GuildRoster()  -- Force an update of the guild roster
            if _G.guildPlayerDatabase then
                local roster = {}
                local numMembers = GetNumGuildMembers()
                for i = 1, numMembers do
                    local fullName = select(1, GetGuildRosterInfo(i))
                    if fullName then
                        local baseName = fullName:match("^(.-)%-.+") or fullName
                        roster[baseName] = true
                    end
                end
                for name, _ in pairs(_G.guildPlayerDatabase) do
                    if not roster[name] then
                        _G.guildPlayerDatabase[name] = nil
                    end
                end
            end
            -- Optional: Update guild data by sending compressed info
            if GuildDatabaseBuild and GuildDatabaseBuild.SendCompressedPlayerInfo then
                GuildDatabaseBuild:SendCompressedPlayerInfo()
            end
            if DEBUG then print("Guild data refreshed.") end
        else
            if DEBUG then print("Not in a guild.") end
        end

        -- Create or show the progress bar
        if not frame.refreshProgressBar then
            local pb = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
            pb:SetSize(100, 10)
            pb:SetPoint("TOPRIGHT", refreshButton, "BOTTOMRIGHT", 0, -5)
            pb:SetMinMaxValues(0, 1)
            pb:SetValue(0)
            pb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            pb:SetStatusBarColor(1, 0, 0)  -- Start red
            frame.refreshProgressBar = pb
        end
        local pb = frame.refreshProgressBar
        pb:SetValue(0)
        pb:SetStatusBarColor(1, 0, 0)
        pb:Show()

        local totalRefreshTime = 5  -- Simulated refresh time (seconds)
        local startTime = GetTime()
        pb:SetScript("OnUpdate", function(self, elapsed)
            local progress = (GetTime() - startTime) / totalRefreshTime
            if progress >= 1 then
                self:SetValue(1)
                self:SetStatusBarColor(0, 1, 0)  -- Turn green when complete
                self:SetScript("OnUpdate", nil)
                refreshButton:Enable()
                C_Timer.After(2, function() self:Hide() end)

                -- Mimic the Guild Functions tab press exactly as in Settings.lua:
                if _G.MissionAccomplished_GuildTabButton and _G.MissionAccomplished_GuildTabButton.Click then
                    _G.MissionAccomplished_GuildTabButton:Click()
                elseif _G.MissionAccomplished_UpdateContent and _G.MissionAccomplished_GuildContent then
                    if _G.SettingsFrameContent and _G.SettingsFrameContent.contentFrame then
                        for _, child in pairs({_G.SettingsFrameContent.contentFrame:GetChildren()}) do
                            child:Hide()
                        end
                    end
                    local content = _G.MissionAccomplished_GuildContent()
                    _G.MissionAccomplished_UpdateContent(content)
                end
            else
                self:SetValue(progress)
            end
        end)
    end)

    --------------------------------------------------
    -- Scroll Frame for the Member List
    --------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", "GuildMembersScrollFrame", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetSize(440, 300)
    scrollFrame:SetPoint("TOP", frame, "TOP", 0, -50)

    local contentFrame = CreateFrame("Frame", "GuildMembersContentFrame", scrollFrame)
    contentFrame:SetWidth(440)
    scrollFrame:SetScrollChild(contentFrame)

    -- Built-in Pillar Textures
    local builtInTexture = "Interface\\Buttons\\WHITE8X8"

    -- Left pillar
    local leftPillarFrame = CreateFrame("Frame", nil, frame)
    leftPillarFrame:SetSize(20, 300)
    leftPillarFrame:SetPoint("RIGHT", scrollFrame, "LEFT", -5, 0)
    leftPillarFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 5)
    local leftPillar = leftPillarFrame:CreateTexture(nil, "OVERLAY")
    leftPillar:SetAllPoints(leftPillarFrame)
    leftPillar:SetTexture(builtInTexture)
    leftPillar:SetVertexColor(0, 0, 0, 1)

    -- Right pillar
    local rightPillarFrame = CreateFrame("Frame", nil, frame)
    rightPillarFrame:SetSize(20, 300)
    rightPillarFrame:SetPoint("LEFT", scrollFrame, "RIGHT", 5, 0)
    rightPillarFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 5)
    local rightPillar = rightPillarFrame:CreateTexture(nil, "OVERLAY")
    rightPillar:SetAllPoints(rightPillarFrame)
    rightPillar:SetTexture(builtInTexture)
    rightPillar:SetVertexColor(0, 0, 0, 1)

    -- Custom slider
    local customSlider = CreateFrame("Slider", "GuildMembersCustomScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    customSlider:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -16)
    customSlider:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 16)
    customSlider:SetOrientation("VERTICAL")
    customSlider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")

    -- Hide the auto scroll bar
    local function HideAutoSlider()
        local autoSlider = _G[scrollFrame:GetName() .. "ScrollBar"]
        if autoSlider then
            autoSlider:Hide()
            autoSlider:SetParent(nil)
            autoSlider.SetValue = function() end
            autoSlider:HookScript("OnShow", function(self) self:Hide() end)
        end
    end
    scrollFrame:HookScript("OnShow", HideAutoSlider)
    contentFrame:HookScript("OnShow", HideAutoSlider)
    frame:HookScript("OnShow", HideAutoSlider)
    HideAutoSlider()

    --------------------------------------------------
    -- Build Member Lists (Online / Offline)
    --------------------------------------------------
    local onlineMembers = {}
    local offlineMembers = {}

    if IsInGuild() then
        GuildRoster()  -- Force a roster update
        local numTotal = GetNumGuildMembers()
        if DEBUG then print("Guild roster count:", numTotal) end
        for i = 1, numTotal do
            local name, _, _, level, class, zone, note, officerNote, online = GetGuildRosterInfo(i)
            local clean = CleanName(name)

            -- Pull from your database if available:
            local progress, professions, version = nil, nil, nil

            local memberData = {
                name = clean,
                race = "Unknown",   -- Classic might not provide race reliably
                class = class or "Unknown",
                level = level or 1,
                progress = progress,
                professions = professions,
                version = version,
                hasAddon = nil,   -- This field will be filled when data is received.
            }
            if _G.guildPlayerDatabase and _G.guildPlayerDatabase[clean] and _G.guildPlayerDatabase[clean].class then
                memberData.class = _G.guildPlayerDatabase[clean].class
                memberData.hasAddon = _G.guildPlayerDatabase[clean].hasAddon
                memberData.progress = _G.guildPlayerDatabase[clean].progress
                memberData.professions = _G.guildPlayerDatabase[clean].professions
            end

            if online then
                table.insert(onlineMembers, memberData)
            else
                table.insert(offlineMembers, memberData)
            end
        end
    else
        -- If not in a guild, add yourself.
        table.insert(onlineMembers, {
            name = CleanName(UnitName("player")),
            race = UnitRace("player") or "Unknown",
            class = select(1, UnitClass("player")) or "Unknown",
            level = UnitLevel("player") or 1,
            progress = MissionAccomplished.GetProgressPercentage() or 0,
            professions = nil,
            hasAddon = "Y",  -- Since you are running the addon.
        })
    end

    -- Insert or update self data from guild DB
    local selfName = CleanName(UnitName("player"))
    local selfData
    if _G.guildPlayerDatabase and _G.guildPlayerDatabase[selfName] then
        selfData = _G.guildPlayerDatabase[selfName]
        selfData.name = selfData.name or selfName
        selfData.race = selfData.race or "Unknown"
        selfData.class = selfData.class or "Unknown"
        selfData.level = selfData.level or 1
    else
        selfData = {
            name = selfName,
            race = UnitRace("player") or "Unknown",
            class = select(1, UnitClass("player")) or "Unknown",
            level = UnitLevel("player") or 1,
            progress = MissionAccomplished.GetProgressPercentage() or 0,
            professions = nil,
            hasAddon = "Y",
        }
    end

    -- Overwrite your own info if present in the online list
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
    for i = #offlineMembers, 1, -1 do
        if offlineMembers[i].name:lower() == selfName:lower() then
            table.remove(offlineMembers, i)
        end
    end

    -- Sort online and offline lists
    table.sort(onlineMembers, function(a, b)
        if a.level == b.level then
            return a.name:lower() < b.name:lower()
        else
            return a.level > b.level
        end
    end)
    table.sort(offlineMembers, function(a, b)
        if a.level == b.level then
            return a.name:lower() < b.name:lower()
        else
            return a.level > b.level
        end
    end)

    -- Combine the lists
    local allMembers = {}
    for _, mem in ipairs(onlineMembers) do
        table.insert(allMembers, mem)
    end
    for _, mem in ipairs(offlineMembers) do
        table.insert(allMembers, mem)
    end

    local lineHeight = 20
    contentFrame:SetHeight(#allMembers * lineHeight)

    --------------------------------------------------
    -- Create a Frame for Each Guild Member (with hover tooltip)
    --------------------------------------------------
    local allLineFrames = {}
    for i, member in ipairs(allMembers) do
        local lf = CreateFrame("Frame", nil, contentFrame)
        lf:SetSize(420, lineHeight)
        lf:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -((i - 1) * lineHeight))

        local bg = lf:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(lf)
        lf.bg = bg

        local fs = lf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        fs:SetAllPoints(lf)
        fs:SetJustifyH("LEFT")
        lf.fs = fs

        local memData = member

        -- Convert stored class (possibly a short code) to its full name.
        local rawClass = memData.class or "Unknown"
        local fullClassName = classCodeToName[rawClass] or rawClass

        local trophy = (memData.level >= 60) and trophySymbol .. " " or ""
        local raceIcon = GetRaceIcon(memData.race)
        local classIcon = GetClassIcon(fullClassName)
        local nameTheClass = string.format("%s the %s", memData.name, ProperCase(fullClassName))

        local isOnline = false
        for _, m in ipairs(onlineMembers) do
            if m.name:lower() == memData.name:lower() then
                isOnline = true
                break
            end
        end

        -- Append up to two profession icons if historic data exists.
        local profIcons = ""
        if memData.professions and #memData.professions > 0 then
            local professionCodeToName = {
                A  = "Alchemy", B  = "Blacksmithing", E  = "Enchanting", EN = "Engineering",
                H  = "Herbalism", I  = "Inscription", J  = "Jewelcrafting", L  = "Leatherworking",
                M  = "Mining", S  = "Skinning", T  = "Tailoring", F  = "Fishing",
                C  = "Cooking", FA = "First Aid"
            }
            for j = 1, math.min(2, #memData.professions) do
                local profData = memData.professions[j]
                local profCode = string.match(profData, "^%a+")
                local profName = professionCodeToName[profCode] or profCode
                profIcons = profIcons .. " " .. GetProfessionIcon(profName)
            end
        end

        -- Build the info text with proper coloring.
        local infoText = ""
        if memData.hasAddon == "Y" then
            if isOnline then
                infoText = string.format("Level: %d, Progress: %.1f%% | %sOnline|r", memData.level, memData.progress or 0, "|cff00ff00")
            else
                infoText = string.format("Level: %d, Progress: %.1f%% | Offline", memData.level, memData.progress or 0)
            end
        else
            if isOnline then
                infoText = string.format("Level: %d, %sNO ADDON|r | %sOnline|r", memData.level, "|cffff0000", "|cff00ff00")
            else
                infoText = string.format("Level: %d, %sNO ADDON|r | Offline", memData.level, "|cffff0000")
            end
        end

        local lineText = string.format("%s%s %s  %s %s| %s", trophy, raceIcon, classIcon, nameTheClass, profIcons, infoText)
        fs:SetText(lineText)

        -- Background color: online members get their class color; offline use grey.
        local bgColor
        if isOnline then
            local classKey = ProperCase(fullClassName)
            bgColor = customClassColors[classKey] or { r = 1, g = 1, b = 1 }
        else
            bgColor = { r = 0.5, g = 0.5, b = 0.5 }
        end
        local r, g, b = bgColor.r, bgColor.g, bgColor.b
        if memData.level >= 60 then
            r, g, b = r * 0.6, g * 0.6, b * 0.6
        end
        bg:SetColorTexture(r, g, b, 0.2)

        if isOnline then
            local classKey = ProperCase(fullClassName)
            local clr = customClassColors[classKey] or { r = 1, g = 1, b = 1 }
            fs:SetTextColor(clr.r, clr.g, clr.b, 0.8)
        else
            fs:SetTextColor(0.5, 0.5, 0.5, 0.8)
        end

        --------------------------------------------------
        -- OnEnter: Show tooltip with additional info
        --------------------------------------------------
        lf:SetScript("OnEnter", function(self)
            local now = GetTime()
            local tooltipData
            if (not self.lastDBPull) or (now - self.lastDBPull >= 10) then
                if _G.guildPlayerDatabase and _G.guildPlayerDatabase[memData.name] then
                    local updated = _G.guildPlayerDatabase[memData.name]
                    if not updated.name then
                        updated.name = memData.name
                    end
                    tooltipData = updated
                else
                    tooltipData = memData
                end
                self.cachedData = tooltipData
                self.lastDBPull = now
            else
                tooltipData = self.cachedData or memData
            end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cff00ff00" .. (tooltipData.name or "Unknown") .. "|r")
            GameTooltip:AddLine("Level: " .. (tooltipData.level or 0), 1, 1, 1, false)
            if tooltipData.lastSeen and tonumber(tooltipData.lastSeen) then
                GameTooltip:AddLine("Last Seen: " .. date("%Y-%m-%d %H:%M:%S", tooltipData.lastSeen), 0.8, 0.8, 0.8, false)
            else
                GameTooltip:AddLine("Last Seen: Unknown", 0.8, 0.2, 0.2, false)
            end
            if tooltipData.progress then
                GameTooltip:AddLine(string.format("Progress: %.1f%%", tooltipData.progress), 1, 1, 1, false)
            end
            if tooltipData.professions then
                GameTooltip:AddLine("Professions:", 0.8, 0.8, 0.8, false)
                for _, profData in ipairs(tooltipData.professions) do
                    local profCode = string.match(profData, "^%a+")
                    local profLevel = string.match(profData, "%d+")
                    if profData == "0" then
                        GameTooltip:AddLine("None", 1, 1, 1, false)
                    elseif profCode and profLevel then
                        local professionCodeToName = {
                            A = "Alchemy", B = "Blacksmithing", E = "Enchanting", EN = "Engineering",
                            H = "Herbalism", I = "Inscription", J = "Jewelcrafting", L = "Leatherworking",
                            M = "Mining", S = "Skinning", T = "Tailoring", F = "Fishing",
                            C = "Cooking", FA = "First Aid"
                        }
                        local profName = professionCodeToName[profCode] or profCode
                        local profIcon = GetProfessionIcon(profName)
                        GameTooltip:AddLine(profIcon .. " " .. profName .. ": " .. profLevel, 1, 1, 1, false)
                    else
                        GameTooltip:AddLine(profData, 1, 1, 1, false)
                    end
                end
            else
                GameTooltip:AddLine("Player Data Not Communicated", 1, 0.2, 0.2, false)
            end
            if tooltipData.version then
                GameTooltip:AddLine("Addon Version: " .. tooltipData.version, 0.8, 0.8, 0.8, false)
            end
            GameTooltip:Show()
        end)

        lf:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        lf:Show()
        allLineFrames[i] = lf
    end

    --------------------------------------------------
    -- UpdateMemberList function (for scrolling)
    --------------------------------------------------
    local function UpdateMemberList(offset)
        if DEBUG then
            print("UpdateMemberList called with offset:", offset)
        end

        scrollFrame:SetVerticalScroll(offset)
        local visibleLines = math.floor(300 / lineHeight)

        FauxScrollFrame_Update(scrollFrame, #allMembers, visibleLines, lineHeight)
        if #allMembers <= visibleLines then
            customSlider:Hide()
        else
            customSlider:Show()
        end

        if customSlider then
            customSlider:SetValue(offset)
        end

        for i, lf in ipairs(allLineFrames) do
            local posY = (i - 1) * lineHeight - offset
            if posY + lineHeight >= 0 and posY <= 300 then
                lf:Show()
            else
                lf:Hide()
            end
        end
    end

    -- Mouse Wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentOffset = self:GetVerticalScroll()
        local newOffset = currentOffset - (delta * lineHeight)
        local visibleLines = math.floor(300 / lineHeight)
        local maxOffset = math.max((#allMembers - visibleLines) * lineHeight, 0)

        if newOffset < 0 then
            newOffset = 0
        elseif newOffset > maxOffset then
            newOffset = maxOffset
        end

        UpdateMemberList(newOffset)

        if DEBUG then
            print("MouseWheel scrolled. New offset:", newOffset)
        end
    end)

    -- Custom Slider Setup
    local visibleLines = math.floor(300 / lineHeight)
    local maxOffset = math.max((#allMembers - visibleLines) * lineHeight, 0)
    if customSlider then
        customSlider:SetMinMaxValues(0, maxOffset)
        customSlider:SetValue(0)
        customSlider:SetValueStep(lineHeight)
        customSlider:SetObeyStepOnDrag(true)
        customSlider:SetScript("OnValueChanged", function(self, value)
            if DEBUG then
                print("Custom slider OnValueChanged triggered. Value:", value)
            end
            UpdateMemberList(value)
        end)
        if maxOffset == 0 then
            customSlider:Hide()
        else
            customSlider:Show()
        end
    end
    UpdateMemberList(0)

    frame:HookScript("OnShow", function(self)
        C_Timer.After(0.05, function()
            HideAutoSlider()
            UpdateMemberList(0)
        end)
    end)

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
            local name, _, _, lvl, cls = GetGuildRosterInfo(i)
            if lvl then
                totalLevel = totalLevel + lvl
                totalCount = totalCount + 1
                if lvl >= 60 then
                    level60Count = level60Count + 1
                end
                local properCls = ProperCase(cls or "Unknown")
                classCounts[properCls] = (classCounts[properCls] or 0) + 1
            end
        end
    end
    local avgLevel = (totalCount > 0) and (totalLevel / totalCount) or 0

    statsHeader:SetText(
        string.format("Avg Level: %.1f  |  Level 60s: %d  |  Total Members: %d",
            avgLevel, level60Count, totalCount)
    )

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
        local cellStr = string.format("%s %s: %s",
            icon,
            available and (hexColor .. cls .. "|r") or ("|cff888888" .. cls .. "|r"),
            countText
        )
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
