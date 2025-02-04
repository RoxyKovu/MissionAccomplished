---------------------------------------------------------------
-- DatabaseBuild.lua (Database Tracking, Slash Command, & Fixes)
---------------------------------------------------------------

DatabaseBuild = DatabaseBuild or {}

local CTL = _G.ChatThrottleLib
local RoxyKovusProfLib = _G.RoxyKovusProfLib

---------------------------------------------------------------
-- Configuration
---------------------------------------------------------------
local pingPriority = "BULK"
local dedicatedChannelName = "MissionAccChannel"
local lastMessageTime = 0  -- Stores last message send time.
local cooldownTime = 300  -- 5-minute cooldown.
local cleanupInterval = 600  -- 10-minute cleanup interval.
_G.playerDatabase = _G.playerDatabase or {}  -- Stores active player data (Now Global)

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

-- Converts profession data into short format (e.g., "L235" for Leatherworking level 235).
local function EncodeProfession(profIndex)
    if not profIndex then return "0" end  -- "0" if no profession is found.
    
    local profData = RoxyKovusProfLib:GetProfessionInfo(profIndex)
    if profData and professionCodes[profData.name] then
        return professionCodes[profData.name] .. profData.level
    end
    return "0"  -- Default for no profession.
end


---------------------------------------------------------------
-- Dedicated Channel Management
---------------------------------------------------------------
local function EnsureDedicatedChannel()
    local channelNum = GetChannelName(dedicatedChannelName)
    if channelNum == 0 then
        JoinChannelByName(dedicatedChannelName)
        channelNum = GetChannelName(dedicatedChannelName)
        for i = 1, 10 do
            if _G['ChatFrame' .. i] then
                ChatFrame_RemoveChannel(_G['ChatFrame' .. i], dedicatedChannelName)
            end
        end
    end
    return channelNum
end

---------------------------------------------------------------
-- Compressed Player Info Message Builder (Includes Timestamp)
---------------------------------------------------------------
local function BuildCompressedPlayerInfoMessage()
    local name = UnitName("player")
    local class = classCodes[UnitClass("player")] or "U"
    local level = UnitLevel("player")
    local guildName = GetGuildInfo("player") or "NoGuild"
    
    local prof1, prof2, fishing, cooking, firstAid = RoxyKovusProfLib:GetProfessions()
    local p1 = EncodeProfession(prof1)
    local p2 = EncodeProfession(prof2)
    local fish = EncodeProfession(fishing)
    local cook = EncodeProfession(cooking)
    local firstA = EncodeProfession(firstAid)

    -- Get current server time
    local timestamp = time()

    -- Compressed format: MA,Name,Class,Level,Guild,Prof1,Prof2,Fishing,Cooking,FirstAid,Timestamp
    return string.format("MA,%s,%s,%d,%s,%s,%s,%s,%s,%s,%d",
        name, class, level, guildName, p1, p2, fish, cook, firstA, timestamp)
end
---------------------------------------------------------------
-- Message Send Function (No Queue, Strict Cooldown)
---------------------------------------------------------------
function DatabaseBuild:SendCompressedPlayerInfo()
    local currentTime = time()  -- Use server time instead of GetTime()

    -- If the cooldown hasn't expired, ignore the request
    if (currentTime - lastMessageTime) < cooldownTime then
        return
    end

    local channelNum = EnsureDedicatedChannel()
    if channelNum == 0 then
        return  -- Exit if channel isn't available.
    end

    -- Send the message (only one per cooldown)
    local msg = BuildCompressedPlayerInfoMessage()
    CTL:SendChatMessage(pingPriority, dedicatedChannelName, msg, "CHANNEL", nil, channelNum)

    -- Update last message time to enforce cooldown
    lastMessageTime = currentTime
end

---------------------------------------------------------------
-- Database Management: Parsing Incoming Messages
---------------------------------------------------------------
local function ParseIncomingMessage(msg)
    -- Ensure the message starts with "MA," and strip it before splitting
    if not string.find(msg, "^MA,") then return end
    msg = string.sub(msg, 4) -- Remove the "MA," prefix

    -- Split the remaining message into parts
    local name, class, level, guild, p1, p2, fish, cook, firstAid, timestamp = strsplit(",", msg)
    
    -- Convert numeric values properly
    level = tonumber(level) or 0
    timestamp = tonumber(timestamp) or time()

    -- Ensure proper database storage
    playerDatabase[name] = {
        class = class or "Unknown",
        level = level,
        guild = guild or "No Guild",
        professions = { p1 or "None", p2 or "None", fish or "None", cook or "None", firstAid or "None" },
        lastSeen = timestamp
    }
end



---------------------------------------------------------------
-- Message Event Listener
---------------------------------------------------------------
local function OnChatMessageReceived(_, _, message, _, _, sender)
    -- Check if the message starts with "MA,"
    if string.sub(message, 1, 3) == "MA," then
        ParseIncomingMessage(message)
    end
end


---------------------------------------------------------------
-- Cleanup Inactive Players (Runs Every 10 Minutes)
---------------------------------------------------------------
local function CleanupDatabase()
    local currentTime = time()
    for name, data in pairs(playerDatabase) do
        if data.lastSeen and (currentTime - data.lastSeen) > cleanupInterval then
            playerDatabase[name] = nil  -- Remove inactive player
        end
    end
end


-- Schedule cleanup every 10 minutes
C_Timer.NewTicker(cleanupInterval, CleanupDatabase)

---------------------------------------------------------------
-- Command to Retrieve the Database (/dbcheck)
---------------------------------------------------------------
SLASH_DBCHECK1 = "/dbcheck"
SlashCmdList["DBCHECK"] = function()
    if next(playerDatabase) == nil then
        print("|cff00ff00[DatabaseBuild]|r No active players in the database.")
        return
    end

    print("|cff00ff00[DatabaseBuild]|r Active Player Database:")

    local currentTime = time()
    local activePlayerCount = 0

    for name, data in pairs(playerDatabase) do
        -- Translate class from short code
        local classFull = classCodeToName[data.class] or "Unknown"

        -- Translate professions
        local translatedProfessions = {}
        for _, profData in ipairs(data.professions) do
            local profCode = string.match(profData, "%a+")  -- Extract letter part
            local profLevel = string.match(profData, "%d+") -- Extract number part

            if profCode and professionCodeToName[profCode] then
                table.insert(translatedProfessions, professionCodeToName[profCode] .. " (Level " .. (profLevel or "0") .. ")")
            elseif profData == "0" then
                table.insert(translatedProfessions, "None")
            else
                table.insert(translatedProfessions, profData) -- Fallback to raw data if no match
            end
        end

        -- Ensure level, guild, and timestamp are valid
        local level = data.level or 0
        local guild = data.guild or "No Guild"
        local lastSeen = data.lastSeen or time()

        -- Check if the player was seen within the last 10 minutes
        if (currentTime - lastSeen) <= 600 then
            activePlayerCount = activePlayerCount + 1
        end

        -- Print formatted output
        print(string.format("|cffffff00%s|r (|cff00ff00%s|r) - Level |cffffff00%d|r, Guild: |cff00ff00%s|r", 
            name, classFull, level, guild))
        print("  Professions: " .. table.concat(translatedProfessions, ", "))
        print("  Last Seen: " .. date("%Y-%m-%d %H:%M:%S", lastSeen))
    end

    -- Print total number of active players
    print(string.format("|cff00ff00[DatabaseBuild]|r %d players active in the last 10 minutes.", activePlayerCount))
end

---------------------------------------------------------------
-- Event Hook: Sends message when player right or left clicks a target.
---------------------------------------------------------------
WorldFrame:HookScript("OnMouseDown", function(self, button)
    if button == "RightButton" or button == "LeftButton" then
        local targetName = UnitName("target")
        if targetName then
            DatabaseBuild:SendCompressedPlayerInfo()
        end
    end
end)

-- Register event to listen for incoming chat messages.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:SetScript("OnEvent", OnChatMessageReceived)

---------------------------------------------------------------
-- End of DatabaseBuild.lua
---------------------------------------------------------------