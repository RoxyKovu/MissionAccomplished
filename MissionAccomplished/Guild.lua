--------------------------------------------------
-- Guild.lua
--------------------------------------------------

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
-- Helper: Get Profession Icon using WoW Icon Database
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
	
	-- Create a Refresh Button at the Top Right of the Frame
local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
refreshButton:SetSize(80, 22)
refreshButton:SetText("Refresh")
refreshButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
refreshButton:SetScript("OnClick", function(self)
    GuildRoster()  -- Force an update of the guild roster.
    -- Call the UpdateMemberList function to refresh the member list display.
    if UpdateMemberList then
        UpdateMemberList(0)
    end
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

    -- Built-in Pillar Textures Using "Interface\\Buttons\\WHITE8X8"
local builtInTexture = "Interface\\Buttons\\WHITE8X8"

-- Create a frame for the left pillar
local leftPillarFrame = CreateFrame("Frame", nil, frame)
leftPillarFrame:SetSize(20, 300)
leftPillarFrame:SetPoint("RIGHT", scrollFrame, "LEFT", -5, 0)
leftPillarFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 5)
-- Create the texture as a child of the pillar frame
local leftPillar = leftPillarFrame:CreateTexture(nil, "OVERLAY")
leftPillar:SetAllPoints(leftPillarFrame)
leftPillar:SetTexture(builtInTexture)
leftPillar:SetVertexColor(0, 0, 0, 1)  -- Tint completely black

-- Create a frame for the right pillar
local rightPillarFrame = CreateFrame("Frame", nil, frame)
rightPillarFrame:SetSize(20, 300)
rightPillarFrame:SetPoint("LEFT", scrollFrame, "RIGHT", 5, 0)
rightPillarFrame:SetFrameLevel(scrollFrame:GetFrameLevel() + 5)
local rightPillar = rightPillarFrame:CreateTexture(nil, "OVERLAY")
rightPillar:SetAllPoints(rightPillarFrame)
rightPillar:SetTexture(builtInTexture)
rightPillar:SetVertexColor(0, 0, 0, 1)


    -- Create a custom slider using UIPanelScrollBarTemplate
    local customSlider = CreateFrame("Slider", "GuildMembersCustomScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    customSlider:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -16)
    customSlider:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 16)
    customSlider:SetOrientation("VERTICAL")
    customSlider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")

    -- Define a helper function to hide the auto‑generated scroll bar
    local function HideAutoSlider()
        local autoSlider = _G[scrollFrame:GetName() .. "ScrollBar"]
        if autoSlider then
            autoSlider:Hide()
            autoSlider:SetParent(nil)
            autoSlider.SetValue = function() end
            autoSlider:HookScript("OnShow", function(self) self:Hide() end)
        end
    end

    -- Use HookScript to ensure HideAutoSlider is called every time these frames show:
    scrollFrame:HookScript("OnShow", HideAutoSlider)
    contentFrame:HookScript("OnShow", HideAutoSlider)
    frame:HookScript("OnShow", HideAutoSlider)  -- Optionally, hook the parent frame as well

    -- Call HideAutoSlider immediately to hide it on first load
    HideAutoSlider()

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
            
            -- Use the database entry (which was parsed with the same method as in the DB module)
            local progress, professions, version = nil, nil, nil
            if _G.guildPlayerDatabase then
                local addonData = _G.guildPlayerDatabase[cleanName]
                if addonData then
                    progress = addonData.progress
                    professions = addonData.professions  -- List of compressed profession strings (e.g. "L235")
                    version = addonData.version
                    if addonData.class and classCodeToName[addonData.class] then
                        addonData.class = classCodeToName[addonData.class]
                    end
                end
            end

            local memberData = {
                name = cleanName,
                race = "Unknown",  -- Classic doesn't reliably provide race info.
                class = class or "Unknown",
                level = level or 1,
                progress = progress,
                professions = professions,
                version = version,
            }
            if _G.guildPlayerDatabase and _G.guildPlayerDatabase[cleanName] and _G.guildPlayerDatabase[cleanName].class then
                memberData.class = _G.guildPlayerDatabase[cleanName].class
            end

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
            progress = MissionAccomplished.GetProgressPercentage() or 0,
            professions = nil,
        })
    end

    --------------------------------------------------
    -- Self Data Update: Pull exclusively from the database
    --------------------------------------------------
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
        }
    end

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

    local allMembers = {}
    for _, member in ipairs(onlineMembers) do
        table.insert(allMembers, member)
    end
    for _, member in ipairs(offlineMembers) do
        table.insert(allMembers, member)
    end

    local lineHeight = 20

    if DEBUG then
        print("Total members (allMembers):", #allMembers)
        print("Expected contentFrame height:", #allMembers * lineHeight)
    end

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
        fs:SetAllPoints(lf)
        fs:SetJustifyH("LEFT")
        lf.fs = fs

        local memData = member
        local trophy = ""
        if memData.level >= 60 then
            trophy = trophySymbol .. " "
        end
        local raceIcon = GetRaceIcon(memData.race)
        local classIcon = GetClassIcon(memData.class)
        local nameTheClass = string.format("%s the %s", memData.name, ProperCase(memData.class))
        local infoText = ""
        local isOnline = false
        for _, m in ipairs(onlineMembers) do
            if m.name:lower() == memData.name:lower() then
                isOnline = true
                break
            end
        end
        if isOnline then
            if memData.progress then
                infoText = string.format("Level: %d, Progress: %.1f%%", memData.level, memData.progress)
            else
                infoText = string.format("Level: %d, (does not have addon)", memData.level)
            end
        else
            infoText = string.format("Level: %d | Offline", memData.level)
        end
        local lineText = string.format("%s%s %s  %s | %s", trophy, raceIcon, classIcon, nameTheClass, infoText)
        lf.fs:SetText(lineText)

        local bgColor
        if isOnline and memData.progress then
            local classKey = ProperCase(memData.class)
            bgColor = customClassColors[classKey] or { r = 1, g = 1, b = 1 }
        elseif isOnline then
            bgColor = { r = 1, g = 0, b = 0 }
        else
            bgColor = { r = 0.5, g = 0.5, b = 0.5 }
        end
        local r, g, b = bgColor.r, bgColor.g, bgColor.b
        if memData.level >= 60 then
            r, g, b = r * 0.6, g * 0.6, b * 0.6
        end
        lf.bg:SetColorTexture(r, g, b, 0.2)

        if isOnline and memData.progress then
            local classKey = ProperCase(memData.class)
            local clr = customClassColors[classKey] or { r = 1, g = 1, b = 1 }
            lf.fs:SetTextColor(clr.r, clr.g, clr.b, 0.8)
        elseif isOnline then
            lf.fs:SetTextColor(1, 0, 0, 0.8)
        else
            lf.fs:SetTextColor(0.5, 0.5, 0.5, 0.8)
        end

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
            GameTooltip:AddLine("Level: " .. tooltipData.level, 1, 1, 1, false)
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
    -- Define a function to update the visible member list based on a given offset.
    --------------------------------------------------
    local function UpdateMemberList(offset)
        if DEBUG then
            print("UpdateMemberList called with offset:", offset)
        end
        scrollFrame:SetVerticalScroll(offset)
        local visibleLines = math.floor(300 / lineHeight)
        
        -- Update the FauxScrollFrame with the visibleLines count
        FauxScrollFrame_Update(scrollFrame, #allMembers, visibleLines, lineHeight)
        
        -- Hide or show the custom slider depending on whether scrolling is needed.
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

    --------------------------------------------------
    -- Mouse Wheel Handler: Use UpdateMemberList to adjust scrolling.
    --------------------------------------------------
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

    --------------------------------------------------
    -- Custom Slider Setup
    --------------------------------------------------
    local visibleLines = math.floor(300 / lineHeight)
    local maxOffset = math.max((#allMembers - visibleLines) * lineHeight, 0)
    if customSlider then
        customSlider:SetMinMaxValues(0, maxOffset)
        customSlider:SetValue(0)
        customSlider:SetValueStep(lineHeight)
        customSlider:SetObeyStepOnDrag(true)
        customSlider:SetScript("OnValueChanged", function(self, value)
            if DEBUG then
                print("Custom slider OnValueChanged triggered. New value:", value)
            end
            UpdateMemberList(value)
        end)
        
        -- Hide the slider immediately if there is no need for scrolling.
        if maxOffset == 0 then
            customSlider:Hide()
        else
            customSlider:Show()
        end
    end

    -- Force an initial update of the member list (scroll to top)
    UpdateMemberList(0)

    -- Hook OnShow so that every time the Guild Functions frame is shown,
    -- we wait a short moment before hiding the native scrollbar and updating the list.
    frame:HookScript("OnShow", function(self)
        C_Timer.After(0.05, function()  -- Adjust the delay if needed
            HideAutoSlider()  -- Ensure native scroll bar is hidden
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
