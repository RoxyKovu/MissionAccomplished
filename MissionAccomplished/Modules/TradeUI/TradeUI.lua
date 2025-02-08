--------------------------------------------------
-- Helper Functions
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

local function GetRaceIcon(raceName)
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

local function GetClassIcon(className)
    local functionCoords = {
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
    local proper = ProperCase(className)
    local coords = functionCoords[proper]
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

local trophySymbol = "|TInterface\\Icons\\achievement_level_60:16:16:0:0|t"

--------------------------------------------------
-- TradeUI Module Code
--------------------------------------------------
local TradeUI = CreateFrame("Frame")

--------------------------------------------------
-- Function: AddGuildInfoToTooltip
-- Adds data from the Guild UI plus additional data from our database.
-- Instead of showing both “Last Seen” and “Last Updated,” the
-- “Last Updated” line now uses the last seen data (from earlier).
--------------------------------------------------
local function AddGuildInfoToTooltip(tooltip, guildIndex)
    if not guildIndex then return end

    -- Basic data from Blizzard's Guild UI
    local fullName, rank, rankIndex, level, classDisplayName, zone, note, officernote, online, status =
        GetGuildRosterInfo(guildIndex)

    local cleanName = CleanName(fullName)

    tooltip:ClearLines()

    local gavicon = "|TInterface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp:16:16:0:0|t "
    tooltip:AddLine(gavicon .. "|cff00ff00MissionAccomplished|r")

    local classIcon = GetClassIcon(classDisplayName or "Unknown")
    local displayName = classIcon .. " " .. (cleanName or "No Data") .. " the " .. ProperCase(classDisplayName or "Unknown")
    tooltip:AddLine(displayName, 1, 1, 1)
    tooltip:AddLine("Rank: " .. (rank or "No Data"), 1, 1, 1)
    tooltip:AddLine("Level: " .. (level or "No Data"), 1, 1, 1)
    tooltip:AddLine("Zone: " .. (zone or "No Data"), 1, 1, 1)
    tooltip:AddLine("Note: " .. (note or "No Data"), 1, 1, 1)
    if CanViewOfficerNote() then
        tooltip:AddLine("Officer Note: " .. (officernote or "No Data"), 1, 1, 1)
    end

    -- Additional data from our database (if available)
    if _G.guildPlayerDatabase and _G.guildPlayerDatabase[cleanName] then
        local dbData = _G.guildPlayerDatabase[cleanName]
        tooltip:AddLine("----- Additional Data -----", 0.5, 1, 0.5)

        local race = dbData.race or "Unknown"
        tooltip:AddLine("Race: " .. race .. " " .. GetRaceIcon(race), 1, 1, 1)

        if dbData.progress then
            tooltip:AddLine("Progress: " .. dbData.progress .. "%", 1, 1, 1)
        else
            tooltip:AddLine("Progress: N/A", 1, 1, 1)
        end

        if dbData.professions then
            tooltip:AddLine("Professions:", 0.8, 0.8, 0.8)
            for _, profData in ipairs(dbData.professions) do
                local profCode = string.match(profData, "^%a+")
                local profLevel = string.match(profData, "%d+")
                if profData == "0" then
                    tooltip:AddLine("  None", 1, 1, 1)
                elseif profCode and profLevel then
                    local professionCodeToName = {
                        A  = "Alchemy", B  = "Blacksmithing", E  = "Enchanting", EN = "Engineering",
                        H  = "Herbalism", I  = "Inscription", J  = "Jewelcrafting", L  = "Leatherworking",
                        M  = "Mining", S  = "Skinning", T  = "Tailoring", F  = "Fishing",
                        C  = "Cooking", FA = "First Aid"
                    }
                    local profName = professionCodeToName[profCode] or profCode
                    local profIcon = GetProfessionIcon(profName)
                    tooltip:AddLine("  " .. profIcon .. " " .. profName .. ": " .. profLevel, 1, 1, 1)
                else
                    tooltip:AddLine("  " .. profData, 1, 1, 1)
                end
            end
        else
            tooltip:AddLine("Professions: N/A", 1, 1, 1)
        end

        -- Use the last seen data as the value for "Last Updated"
        local lastUpdatedStr = dbData.lastSeen and date("%Y-%m-%d %H:%M:%S", dbData.lastSeen) or "N/A"
        tooltip:AddLine("Last Updated: " .. lastUpdatedStr, 0.8, 0.8, 0.8)
    end

    tooltip:Show()
end

--------------------------------------------------
-- Function: HookGuildFrame
-- Hooks the tooltip events for each GuildFrame button
--------------------------------------------------
local function HookGuildFrame()
    local displayCount = GUILDMEMBERS_TO_DISPLAY or 16
    for i = 1, displayCount do
        local button = _G["GuildFrameButton" .. i]
        if button and not button.hooked then
            button:HookScript("OnEnter", function(self)
                local guildIndex = self.guildIndex
                if guildIndex then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    AddGuildInfoToTooltip(GameTooltip, guildIndex)
                end
            end)
            button:HookScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            button.hooked = true
        end
    end
end

--------------------------------------------------
-- Hook additional tooltip for players (when mousing over a unit)
--------------------------------------------------
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local name, unit = self:GetUnit()
    if unit and UnitIsPlayer(unit) then
        local cleanName = CleanName(name)
        if _G.guildPlayerDatabase and _G.guildPlayerDatabase[cleanName] then
            local dbData = _G.guildPlayerDatabase[cleanName]
            self:AddLine("----- Additional Data -----", 0.5, 1, 0.5)
            
            local race = dbData.race or "Unknown"
            self:AddLine("Race: " .. race .. " " .. GetRaceIcon(race), 1, 1, 1)
            
            if dbData.progress then
                self:AddLine("Progress: " .. dbData.progress .. "%", 1, 1, 1)
            else
                self:AddLine("Progress: N/A", 1, 1, 1)
            end
            
            if dbData.professions then
                self:AddLine("Professions:", 0.8, 0.8, 0.8)
                for _, profData in ipairs(dbData.professions) do
                    local profCode = string.match(profData, "^%a+")
                    local profLevel = string.match(profData, "%d+")
                    if profData == "0" then
                        self:AddLine("  None", 1, 1, 1)
                    elseif profCode and profLevel then
                        local professionCodeToName = {
                            A  = "Alchemy", B  = "Blacksmithing", E  = "Enchanting", EN = "Engineering",
                            H  = "Herbalism", I  = "Inscription", J  = "Jewelcrafting", L  = "Leatherworking",
                            M  = "Mining", S  = "Skinning", T  = "Tailoring", F  = "Fishing",
                            C  = "Cooking", FA = "First Aid"
                        }
                        local profName = professionCodeToName[profCode] or profCode
                        local profIcon = GetProfessionIcon(profName)
                        self:AddLine("  " .. profIcon .. " " .. profName .. ": " .. profLevel, 1, 1, 1)
                    else
                        self:AddLine("  " .. profData, 1, 1, 1)
                    end
                end
            else
                self:AddLine("Professions: N/A", 1, 1, 1)
            end
            
            local lastUpdatedStr = dbData.lastSeen and date("%Y-%m-%d %H:%M:%S", dbData.lastSeen) or "N/A"
            self:AddLine("Last Updated: " .. lastUpdatedStr, 0.8, 0.8, 0.8)
            self:Show()
        end
    end
end)

--------------------------------------------------
-- Event Handler
--------------------------------------------------
local function OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_GuildUI" then
            self:UnregisterEvent("ADDON_LOADED")
            GuildRoster() -- Force a roster update so the guild buttons are available
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        HookGuildFrame()
    end
end

--------------------------------------------------
-- Register events and set the script
--------------------------------------------------
TradeUI:RegisterEvent("ADDON_LOADED")
TradeUI:RegisterEvent("GUILD_ROSTER_UPDATE")
TradeUI:SetScript("OnEvent", OnEvent)
