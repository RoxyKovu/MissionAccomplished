---------------------------------------------------------------
-- GuildDatabaseBuild.lua (Guild Database Tracking, Slash Command, & Fixes)
---------------------------------------------------------------

GuildDatabaseBuild = GuildDatabaseBuild or {}

local CTL = _G.ChatThrottleLib
local RoxyKovusProfLib = _G.RoxyKovusProfLib

---------------------------------------------------------------
-- Configuration
---------------------------------------------------------------
local pingPriority = "BULK"
local lastMessageTime = 0         -- Stores the last message send time.
local cooldownTime = 120          -- 2-minute cooldown.
_G.guildPlayerDatabase = _G.guildPlayerDatabase or {}  -- Stores active guild player data.

-- Flag to disable functions for the first 10 seconds after entering the world.
local addonEnabled = false

-- Ticker to update the DB every minute once triggered.
local dbUpdateTicker = nil

---------------------------------------------------------------
-- Delay Activation Until 10 Seconds After Entering the World
---------------------------------------------------------------
local enterFrame = CreateFrame("Frame")
enterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
enterFrame:SetScript("OnEvent", function(self, event, ...)
    -- Wait 10 seconds before enabling the addon.
    C_Timer.After(10, function()
        addonEnabled = true
    end)
end)

---------------------------------------------------------------
-- Utility: Get Base Name (Strip Realm)
---------------------------------------------------------------
local function GetBaseName(fullName)
    -- Returns the base name (everything before a '-' if present)
    local name = string.match(fullName, "^(.-)%-.+") or fullName
    return name
end

---------------------------------------------------------------
-- Compression Lookup Tables
---------------------------------------------------------------
-- Class Short Codes
local classCodes = {
    ["Warrior"] = "W", ["Paladin"] = "P", ["Hunter"] = "H", ["Rogue"] = "R",
    ["Priest"] = "PR", ["Death Knight"] = "DK", ["Shaman"] = "S", ["Mage"] = "M",
    ["Warlock"] = "WL", ["Druid"] = "D", ["Monk"] = "MO", ["Demon Hunter"] = "DH"
}

-- Reverse lookup for class codes
local classCodeToName = {}
for className, code in pairs(classCodes) do
    classCodeToName[code] = className
end

-- Profession Short Codes
local professionCodes = {
    ["Alchemy"] = "A", ["Blacksmithing"] = "B", ["Enchanting"] = "E", ["Engineering"] = "EN",
    ["Herbalism"] = "H", ["Inscription"] = "I", ["Jewelcrafting"] = "J", ["Leatherworking"] = "L",
    ["Mining"] = "M", ["Skinning"] = "S", ["Tailoring"] = "T", ["Fishing"] = "F",
    ["Cooking"] = "C", ["First Aid"] = "FA"
}

-- Reverse lookup for profession codes
local professionCodeToName = {}
for profName, code in pairs(professionCodes) do
    professionCodeToName[code] = profName
end

-- Converts profession data into a short format (e.g., "L235" for Leatherworking level 235).
local function EncodeProfession(profIndex)
    if not profIndex then return "0" end  -- "0" if no profession is found.
    
    local profData = RoxyKovusProfLib:GetProfessionInfo(profIndex)
    if profData and professionCodes[profData.name] then
        return professionCodes[profData.name] .. profData.level
    end
    return "0"  -- Default for no profession.
end

---------------------------------------------------------------
-- Dedicated Guild Channel Management
---------------------------------------------------------------
-- This function ensures that a channel with the name "MA<GuildName>" exists.
local function EnsureGuildChannel()
    local guildName = GetGuildInfo("player")
    if not guildName then
        return 0  -- Player is not in a guild.
    end

    local guildChannelName = "MA" .. guildName
    local channelNum = GetChannelName(guildChannelName)
    if channelNum == 0 then
        JoinChannelByName(guildChannelName)
        channelNum = GetChannelName(guildChannelName)
        for i = 1, 10 do
            if _G["ChatFrame" .. i] then
                ChatFrame_RemoveChannel(_G["ChatFrame" .. i], guildChannelName)
            end
        end
    end
    return channelNum, guildChannelName
end

---------------------------------------------------------------
-- Compressed Player Info Message Builder (Includes Timestamp, Race, Progress, & Addon Tag)
---------------------------------------------------------------
local function BuildCompressedPlayerInfoMessage()
    local name = UnitName("player")
    local class = classCodes[UnitClass("player")] or "U"
    local level = UnitLevel("player")
    local guildName = GetGuildInfo("player")
    
    if not guildName then
        return nil  -- Exit if not in a guild.
    end
    
    -- Additional fields:
    local race = UnitRace("player") or "Unknown"
    local progress = (MissionAccomplished and MissionAccomplished.GetProgressPercentage)
                        and MissionAccomplished.GetProgressPercentage() or 0
    local hasAddon = "Y"  -- Mark that the addon is installed.

    local prof1, prof2, fishing, cooking, firstAid = RoxyKovusProfLib:GetProfessions()
    local p1 = EncodeProfession(prof1)
    local p2 = EncodeProfession(prof2)
    local fish = EncodeProfession(fishing)
    local cook = EncodeProfession(cooking)
    local firstA = EncodeProfession(firstAid)

    local timestamp = time()  -- Current server time.

    -- Compressed format:
    -- MA,Name,Class,Level,Guild,Race,Progress,HasAddon,Prof1,Prof2,Fishing,Cooking,FirstAid,Timestamp
    return string.format("MA,%s,%s,%d,%s,%s,%.1f,%s,%s,%s,%s,%s,%s,%d",
        name, class, level, guildName, race, progress, hasAddon, p1, p2, fish, cook, firstA, timestamp)
end

---------------------------------------------------------------
-- Database Update: Check Guild Roster and Remove Players Not in Guild
---------------------------------------------------------------
local function UpdateGuildDatabaseRoster()
    if IsInGuild() then
        local roster = {}
        GuildRoster()  -- Force a roster update.
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local fullName = select(1, GetGuildRosterInfo(i))
            if fullName then
                local baseName = GetBaseName(fullName)
                roster[baseName] = true
            end
        end

        for name, _ in pairs(guildPlayerDatabase) do
            if not roster[name] then
                guildPlayerDatabase[name] = nil
            end
        end
    end
end

---------------------------------------------------------------
-- Message Send Function (No Queue, Strict Cooldown)
---------------------------------------------------------------
function GuildDatabaseBuild:SendCompressedPlayerInfo()
    if not addonEnabled then return end  -- Do nothing if within the first 10 seconds.

    local guildName = GetGuildInfo("player")
    if not guildName then
        print("|cff00ff00[GuildDatabaseBuild]|r You are not in a guild. Function aborted.")
        return
    end

    local currentTime = time()
    if (currentTime - lastMessageTime) < cooldownTime then
        return  -- Enforce cooldown.
    end

    local channelNum, guildChannelName = EnsureGuildChannel()
    if channelNum == 0 then
        return  -- Exit if channel isn't available.
    end

    local msg = BuildCompressedPlayerInfoMessage()
    if not msg then return end

    CTL:SendChatMessage(pingPriority, guildChannelName, msg, "CHANNEL", nil, channelNum)
    lastMessageTime = currentTime

    -- Immediately update the database.
    UpdateGuildDatabaseRoster()

    -- Start a repeating ticker to update the database every minute if not already started.
    if not dbUpdateTicker then
        dbUpdateTicker = C_Timer.NewTicker(60, UpdateGuildDatabaseRoster)
    end
end

---------------------------------------------------------------
-- Database Management: Parsing Incoming Messages
---------------------------------------------------------------
local function ParseIncomingMessage(msg)
    if not string.find(msg, "^MA,") then return end
    msg = string.sub(msg, 4)  -- Remove the "MA," prefix.

    local name, class, level, guild, race, progress, hasAddon, p1, p2, fish, cook, firstAid, timestamp = strsplit(",", msg)
    level = tonumber(level) or 0
    progress = tonumber(progress) or 0
    timestamp = tonumber(timestamp) or time()

    guildPlayerDatabase[name] = {
        class = class or "Unknown",
        level = level,
        guild = guild or "No Guild",
        race = race or "Unknown",
        progress = progress,
        hasAddon = hasAddon or "N",
        professions = { p1 or "None", p2 or "None", fish or "None", cook or "None", firstAid or "None" },
        lastSeen = timestamp
    }
end

---------------------------------------------------------------
-- Message Event Listener
---------------------------------------------------------------
local function OnChatMessageReceived(_, _, message, _, _, sender)
    if string.sub(message, 1, 3) == "MA," then
        ParseIncomingMessage(message)
        -- Schedule a roster update 5 seconds after receiving a message.
        C_Timer.After(5, UpdateGuildDatabaseRoster)
    end
end

---------------------------------------------------------------
-- Command to Retrieve the Database (/gdbcheck)
-- It updates the database, waits 2 seconds, then prints the contents.
---------------------------------------------------------------
SLASH_GDBCHECK1 = "/gdbcheck"
SlashCmdList["GDBCHECK"] = function()
    UpdateGuildDatabaseRoster()
    print("|cff00ff00[GuildDatabaseBuild]|r Updating guild database, please wait 2 seconds...")
    C_Timer.After(2, function()
        if next(guildPlayerDatabase) == nil then
            print("|cff00ff00[GuildDatabaseBuild]|r No active guild players in the database.")
            return
        end

        print("|cff00ff00[GuildDatabaseBuild]|r Active Guild Player Database:")
        for name, data in pairs(guildPlayerDatabase) do
            local classFull = classCodeToName[data.class] or "Unknown"
            local translatedProfessions = {}
            for _, profData in ipairs(data.professions) do
                local profCode = string.match(profData, "%a+")
                local profLevel = string.match(profData, "%d+")
                if profCode and professionCodeToName[profCode] then
                    table.insert(translatedProfessions, professionCodeToName[profCode] .. " (Level " .. (profLevel or "0") .. ")")
                elseif profData == "0" then
                    table.insert(translatedProfessions, "None")
                else
                    table.insert(translatedProfessions, profData)
                end
            end

            print(string.format("|cffffff00%s|r (|cff00ff00%s|r) - Level |cffffff00%d|r, Guild: |cff00ff00%s|r",
                name, classFull, data.level or 0, data.guild or "No Guild"))
            print("  Race: " .. (data.race or "Unknown") .. " | Progress: " .. data.progress .. "% | Has Addon: " .. (data.hasAddon or "N"))
            print("  Professions: " .. table.concat(translatedProfessions, ", "))
            print("  Last Seen: " .. date("%Y-%m-%d %H:%M:%S", data.lastSeen or time()))
        end
    end)
end

---------------------------------------------------------------
-- Trigger: Sends message when player right or left clicks a target.
---------------------------------------------------------------
WorldFrame:HookScript("OnMouseDown", function(self, button)
    if button == "LeftButton" or button == "RightButton" then
        local targetName = UnitName("target")
        if targetName then
            GuildDatabaseBuild:SendCompressedPlayerInfo()
        end
    end
end)

---------------------------------------------------------------
-- Register event to listen for incoming chat messages.
---------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:SetScript("OnEvent", OnChatMessageReceived)

---------------------------------------------------------------
-- End of GuildDatabaseBuild.lua
---------------------------------------------------------------
