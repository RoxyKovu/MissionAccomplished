---------------------------------------------------------------
-- GuildNotifications.lua
-- This file implements a guild event notification system with a
-- single queue for both local and incoming events.
---------------------------------------------------------------

---------------------------------------------------------------
-- GLOBALS & VARIABLES (No 'local' for globals)
---------------------------------------------------------------
chatQueue    = {}       -- Queue for both local & incoming events
addonEnabled = true     -- Activated 10s after login

-- Mapping for instance names (used to convert full names to short codes)
local InstanceNameToCode = {
    ["Ragefire Chasm"]     = "RC",
    ["Wailing Caverns"]    = "WC",
    ["Stormwind Deadmines"] = "TD",
    ["Shadowfang Keep"]    = "SF",
    ["Blackfathom Deeps"]  = "BD",
    ["Stormwind Stockade"] = "TS",
    ["Gnomeregan"]         = "GN",
    ["Razorfen Kraul"]     = "RK",
    ["Scarlet Monastery"] = "SG",
    ["Scarlet Monastery: Library"]   = "SL",
    ["Scarlet Monastery: Armory"]    = "SA",
    ["Scarlet Monastery: Cathedral"] = "SC",
    ["Razorfen Downs"]     = "RD",
    ["Uldaman"]            = "UL",
    ["Zul'Farrak"]         = "ZF",
    ["Maraudon"]           = "MR",
    ["Temple of Atal'Hakkar"] = "TA",
    ["Blackrock Depths"]   = "BD2",
    ["Lower Blackrock Spire"] = "LBS",
    ["Upper Blackrock Spire"] = "UBS",
    ["Dire Maul: East"]    = "DME",
    ["Dire Maul: West"]    = "DMW",
    ["Dire Maul: North"]   = "DMN",
    ["Stratholme: Living Side"] = "SLL",
    ["Stratholme: Undead Side"] = "SLU",
    ["Scholomance"]        = "SCOL",
}

---------------------------------------------------------------
-- FUNCTION: OnGuildEventOccurred
-- Queues a local event for later broadcast and display.
---------------------------------------------------------------
function OnGuildEventOccurred(eventCode, sender, extraData)
    if eventCode == "EI" and extraData then
        if #extraData > 2 then
            extraData = strtrim(extraData):lower()
            if extraData:sub(1, 4) == "the " then
                extraData = extraData:sub(5)
            end
            for fullName, shortCode in pairs(InstanceNameToCode) do
                if strtrim(fullName):lower() == extraData then
                    extraData = shortCode
                    break
                end
            end
        else
            extraData = string.upper(extraData)
        end
    end

    local compressedMessage = string.format("MAGuildEvent:%s,%s,%s", eventCode, sender, extraData or "??")
    table.insert(chatQueue, { message = compressedMessage, isLocal = true })
end

---------------------------------------------------------------
-- LEVEL UP EVENT HANDLER (for guild messaging)
---------------------------------------------------------------
local LevelUpFrame = CreateFrame("Frame")
LevelUpFrame:RegisterEvent("PLAYER_LEVEL_UP")
LevelUpFrame:SetScript("OnEvent", function(self, event, newLevel)
    if event == "PLAYER_LEVEL_UP" then
        local pName = UnitName("player") or "Unknown"
        local _, playerClass = UnitClass("player")
        -- Queue a Level Up event with new level and class as extra data.
        OnGuildEventOccurred("LU", pName, tostring(newLevel) .. "," .. playerClass)
    end
end)

---------------------------------------------------------------
-- LOW HEALTH EVENT HANDLER (for guild messaging)
---------------------------------------------------------------
local LowHealthFrame = CreateFrame("Frame")
LowHealthFrame:RegisterEvent("UNIT_HEALTH")
LowHealthFrame.lowHealthNotified = false  -- flag to prevent duplicate messages
LowHealthFrame:SetScript("OnEvent", function(self, event, unit)
    if unit == "player" then
        local pName = UnitName("player") or "Unknown"
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        if maxHealth == 0 then return end  -- safeguard against division by zero
        local pct = (health / maxHealth) * 100
        if pct <= 10 and not self.lowHealthNotified then
            OnGuildEventOccurred("LH", pName, tostring(math.floor(pct)))
            self.lowHealthNotified = true
        elseif pct > 10 then
            self.lowHealthNotified = false
        end
    end
end)

---------------------------------------------------------------
-- Delayed Activation & Instance Check:
-- Delays addon activation for 10 seconds on first PLAYER_ENTERING_WORLD,
-- and also checks for instance changes.
---------------------------------------------------------------
local EnterFrame = CreateFrame("Frame")
EnterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EnterFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if not self.hasDelayed then
            C_Timer.After(10, function() addonEnabled = true end)
            self.hasDelayed = true
        end
        if not addonEnabled then return end

        local pName = UnitName("player") or "Unknown"
        local inInstance, instanceType = IsInInstance()
        local instanceName = GetInstanceInfo()  -- e.g., "Wailing Caverns"
        if inInstance and (instanceType == "party" or instanceType == "raid") then
            if not GavrialsCallPreviousInstance then
                OnGuildEventOccurred("EI", pName, instanceName)
            end
            GavrialsCallPreviousInstance = instanceName
        end
    end
end)

---------------------------------------------------------------
-- FUNCTION: EnsureGuildChannel
-- Joins the custom guild channel ("MA" .. guildName) if not already joined.
---------------------------------------------------------------
function EnsureGuildChannel()
    local guildName = GetGuildInfo("player")
    if not guildName then return 0 end
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
-- FUNCTION: ProcessIncomingCompressedMessage
-- Decodes the compressed message and displays it using data from EventsDictionary.
---------------------------------------------------------------
function ProcessIncomingCompressedMessage(message)
    if string.sub(message, 1, 13) ~= "MAGuildEvent:" then return end
    local data = string.sub(message, 14)  -- Remove the prefix
    local eventCode, sender, extraData = strsplit(",", data)
    local fullEvent = EventsDictionary.eventTypeLookup[eventCode] or eventCode

    if fullEvent == "EnteredInstance" then
        local eventData = EventsDictionary.allEvents[extraData]
        if eventData then
            local finalMsg = string.format(eventData.message, sender)
            GavrialsCall:DisplayMessage(sender, finalMsg, eventData.icon, {1, 1, 1}, "EI")
        else
            local fallbackMsg = string.format("%s crosses into an uncharted domain—untold perils lie in wait!", sender)
            GavrialsCall:DisplayMessage(sender, fallbackMsg, (EventsDictionary.eventIcons and EventsDictionary.eventIcons.EI) or "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1}, "EI")
        end
    elseif fullEvent == "LowHealth" then
        local eventData = EventsDictionary.allEvents["LH"]
        if eventData then
            local msg = string.format(eventData.message, sender, extraData or "??")
            GavrialsCall:DisplayMessage(sender, msg, eventData.icon, {1, 1, 1}, "LH")
        end
    elseif fullEvent == "LevelUp" then
        local eventData = EventsDictionary.allEvents["LU"]
        if eventData then
            local level, playerClass = strsplit(",", extraData)
            local msg = string.format(eventData.message, sender, playerClass, level)
            GavrialsCall:DisplayMessage(sender, msg, eventData.icon, {1, 1, 1}, "LU")
        end
    elseif fullEvent == "GuildDeath" then
        if extraData == "FD" then return end  -- Ignore feign deaths
        local eventData = EventsDictionary.allEvents["GD"]
        if eventData then
            local msg = string.format(eventData.message, sender)
            GavrialsCall:DisplayMessage(sender, msg, eventData.icon, {1, 1, 1}, "GD")
        end
    elseif fullEvent == "MaxLevel" then
        local eventData = EventsDictionary.allEvents["ML"]
        if eventData then
            local msg = string.format(eventData.message, sender)
            GavrialsCall:DisplayMessage(sender, msg, eventData.icon, {1, 1, 1}, "ML")
        end
    elseif fullEvent == "Progress" then
        local eventData = EventsDictionary.allEvents["PR"]
        if eventData then
            local msg = string.format(eventData.message, sender, extraData)
            GavrialsCall:DisplayMessage(sender, msg, eventData.icon, {1, 1, 1}, "PR")
        end
    else
        local fallbackMsg = string.format("%s unleashed an enigma (%s) with data '%s'—mysteries deepen!", sender, eventCode, extraData or "??")
        GavrialsCall:DisplayMessage(sender, fallbackMsg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1}, eventCode)
    end
end

---------------------------------------------------------------
-- MOUSE CLICK: Drain chatQueue on left/right click
---------------------------------------------------------------
WorldFrame:HookScript("OnMouseDown", function(_, button)
    if not addonEnabled then return end
    if button == "LeftButton" or button == "RightButton" then
        while #chatQueue > 0 do
            local entry = table.remove(chatQueue, 1)
            local msg = entry.message
            if entry.isLocal then
                local channelNum = EnsureGuildChannel()
                if channelNum and channelNum > 0 then
                    SendChatMessage(msg, "CHANNEL", nil, channelNum)
                end
            end
            ProcessIncomingCompressedMessage(msg)
        end
    end
end)

---------------------------------------------------------------
-- GUILD CHAT EVENT HANDLER: Enqueue incoming messages from the custom channel.
-- Note: This version no longer filters by sender; all messages on the channel are read.
---------------------------------------------------------------
local GuildEventFrame = CreateFrame("Frame")
GuildEventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
GuildEventFrame:SetScript("OnEvent", function(_, _, message, sender, _, _, _, _, channelNumber, channelName)
    if not addonEnabled then return end
    local guildName = GetGuildInfo("player")
    if guildName then
        local expectedChannelName = "MA" .. guildName
        if channelName == expectedChannelName then
            table.insert(chatQueue, { message = message, isLocal = false })
        end
    end
end)

---------------------------------------------------------------
-- XP / PROGRESS UTILS
---------------------------------------------------------------
XP_REQUIREMENTS = {
    400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,
    8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
    25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,
    50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,
    95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,
    153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800, 217400,
}

function MissionAccomplished_GetTotalXPSoFar()
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

function MissionAccomplished_GetXPMaxTo60()
    local xpMax = 0
    for i = 1, 59 do
        xpMax = xpMax + (XP_REQUIREMENTS[i] or 0)
    end
    return xpMax
end

function MissionAccomplished_GetProgressPercentage()
    local level = UnitLevel("player") or 1
    if level >= 60 then
        return 100
    end
    local totalXP = MissionAccomplished_GetTotalXPSoFar()
    local xpMax   = MissionAccomplished_GetXPMaxTo60()
    if xpMax > 0 then
        return (totalXP / xpMax) * 100
    else
        return 0
    end
end

---------------------------------------------------------------
-- FUNCTION: CheckAndSendProgress
---------------------------------------------------------------
function CheckAndSendProgress()
    local progressPct = MissionAccomplished_GetProgressPercentage()
    local roundedPct  = math.floor(progressPct + 0.5)
    local sender = UnitName("player")
    if roundedPct == 10 then
        OnGuildEventOccurred("EI", sender, "RC")
    else
        local validThresholds = { [25] = true, [50] = true, [75] = true }
        if validThresholds[roundedPct] then
            local compressed = string.format("MAGuildEvent:PR,%s,%d", sender, roundedPct)
            table.insert(chatQueue, { message = compressed, isLocal = true })
        end
    end
end

---------------------------------------------------------------
-- OPTIONAL TEST LINES (comment out if desired)
---------------------------------------------------------------
-- OnGuildEventOccurred("EI", "Gavrial", "WC")    -- Test: Enter instance
-- OnGuildEventOccurred("LH", "Gavrial", "10")     -- Test: Low health
-- OnGuildEventOccurred("LU", "Gavrial", "60,Paladin")  -- Test: Level up
-- OnGuildEventOccurred("GD", "Gavrial", "XX")     -- Test: Guild death
-- OnGuildEventOccurred("ML", "Gavrial", "XX")     -- Test: Max level
-- CheckAndSendProgress()                         -- Test: Progress event
