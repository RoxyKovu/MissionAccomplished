--======================================================
-- GuildNotification.lua (Single-Queue Version)
--======================================================
-- This file implements a guild event notification system
-- with compressed messages. All events flow through one
-- queue (chatQueue), preventing double notifications.
--
-- All event-related properties (icons, sounds, messages, etc.)
-- are now pulled from the external lookup table in EventsDictionary.lua.
--======================================================

---------------------------------------------------------------
-- GLOBALS & VARIABLES (No 'local' for globals)
---------------------------------------------------------------
chatQueue    = {}       -- Queue for both local & incoming events
addonEnabled = true     -- Activated 10s after login

-- This mapping converts full instance names into the short code used
-- in the external EventsDictionary.allEvents lookup.
local InstanceNameToCode = {
    ["Ragefire Chasm"]     = "RC",
    ["Wailing Caverns"]    = "WC",
    ["Deadmines"]          = "TD",
    ["Shadowfang Keep"]    = "SF",
    ["Blackfathom Deeps"]  = "BD",
    ["Stormwind Stockade"] = "TS",
    ["Gnomeregan"]         = "GN",
    ["Razorfen Kraul"]     = "RK",
    ["Scarlet Monastery: Graveyard"] = "SG",
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
-- (Queues a local event for later broadcast and display)
---------------------------------------------------------------
function OnGuildEventOccurred(eventCode, sender, extraData)
    if eventCode == "EI" and extraData then
        -- If extraData length is more than 2, assume it's a full name and normalize it.
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
            -- Otherwise, if it's a short code, force it to uppercase.
            extraData = string.upper(extraData)
        end
    end

    local compressedMessage = string.format("MAGuildEvent:%s,%s,%s", eventCode, sender, extraData or "??")
    table.insert(chatQueue, {
        message = compressedMessage,
        isLocal = true,
    })
end


---------------------------------------------------------------
-- Delayed Activation & Instance Check:
-- 1) On first PLAYER_ENTERING_WORLD, delay addon activation by 10s.
-- 2) Also check for instance changes.
---------------------------------------------------------------
EnterFrame = CreateFrame("Frame")
EnterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EnterFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- (A) Delay the addon by 10 seconds on first login
        if not self.hasDelayed then
            C_Timer.After(10, function()
                addonEnabled = true
            end)
            self.hasDelayed = true
        end

        if not addonEnabled then return end

        -- (B) Detect if the player is entering an instance
        local pName = UnitName("player") or "Unknown"
        local inInstance, instanceType = IsInInstance()
        local instanceName = GetInstanceInfo()  -- e.g., "Wailing Caverns"

        if inInstance and (instanceType == "party" or instanceType == "raid") then
            if not GavrialsCallPreviousInstance then
                -- Queue an instance event using the full instance name.
                OnGuildEventOccurred("EI", pName, instanceName)
            end
            GavrialsCallPreviousInstance = instanceName
        end
    end
end)

---------------------------------------------------------------
-- FUNCTION: EnsureGuildChannel
-- (Joins the custom guild channel if not already joined)
---------------------------------------------------------------
function EnsureGuildChannel()
    local guildName = GetGuildInfo("player")
    if not guildName then
        return 0 -- Not in a guild
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
-- FUNCTION: ProcessIncomingCompressedMessage
-- Decodes the compressed message and displays it using data
-- pulled from EventsDictionary.
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
            GavrialsCall.DisplayMessage("", finalMsg, eventData.icon, {1, 1, 1})
        else
            local fallbackMsg = string.format(
                "%s crosses into an uncharted domain—untold perils lie in wait!",
                sender
            )
            GavrialsCall.DisplayMessage("", fallbackMsg,
                (EventsDictionary.eventIcons and EventsDictionary.eventIcons.EI) or "Interface\\Icons\\INV_Misc_QuestionMark",
                {1, 1, 1})
        end

    elseif fullEvent == "LowHealth" then
        local eventData = EventsDictionary.allEvents["LH"]
        if eventData then
            local msg = string.format(eventData.message, sender, extraData or "??")
            GavrialsCall.DisplayMessage("", msg, eventData.icon, {1, 1, 1})
        end

    elseif fullEvent == "LevelUp" then
        local eventData = EventsDictionary.allEvents["LU"]
        if eventData then
            local msg = string.format(eventData.message, sender, extraData)
            GavrialsCall.DisplayMessage("", msg, eventData.icon, {1, 1, 1})
        end

    elseif fullEvent == "GuildDeath" then
        if extraData == "FD" then return end  -- Ignore feign deaths
        local eventData = EventsDictionary.allEvents["GD"]
        if eventData then
            local msg = string.format(eventData.message, sender)
            GavrialsCall.DisplayMessage("", msg, eventData.icon, {1, 1, 1})
        end

    elseif fullEvent == "MaxLevel" then
        local eventData = EventsDictionary.allEvents["ML"]
        if eventData then
            local msg = string.format(eventData.message, sender)
            GavrialsCall.DisplayMessage("", msg, eventData.icon, {1, 1, 1})
        end

    elseif fullEvent == "Progress" then
        local eventData = EventsDictionary.allEvents["PR"]
        if eventData then
            local msg = string.format(eventData.message, sender, extraData)
            GavrialsCall.DisplayMessage("", msg, eventData.icon, {1, 1, 1})
        end

    else
        -- Fallback for unknown events
        local fallbackMsg = string.format(
            "%s unleashed an enigma (%s) with data '%s'—mysteries deepen!",
            sender, eventCode, extraData or "??"
        )
        GavrialsCall.DisplayMessage("", fallbackMsg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
    end
end

---------------------------------------------------------------
-- MOUSE CLICK: Drain chatQueue on first left/right click
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
-- GUILD CHAT EVENT HANDLER: Enqueue incoming messages
---------------------------------------------------------------
GuildEventFrame = CreateFrame("Frame")
GuildEventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
GuildEventFrame:SetScript("OnEvent", function(_, _, message, sender, _, _, _, _, channelNumber, channelName)
    if not addonEnabled then return end

    local guildName = GetGuildInfo("player")
    if guildName then
        local expectedChannelName = "MA" .. guildName
        if channelName == expectedChannelName and sender ~= UnitName("player") then
            table.insert(chatQueue, {
                message = message,
                isLocal = false,
            })
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

function MissionAccomplished.GetXPMaxTo60()
    local xpMax = 0
    for i = 1, 59 do
        xpMax = xpMax + (XP_REQUIREMENTS[i] or 0)
    end
    return xpMax
end

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

---------------------------------------------------------------
-- FUNCTION: CheckAndSendProgress
---------------------------------------------------------------
function CheckAndSendProgress()
    local progressPct = MissionAccomplished.GetProgressPercentage()
    local roundedPct  = math.floor(progressPct + 0.5)
    local sender = UnitName("player")

    if roundedPct == 10 then
        -- At 10% progress, send an instance event that uses the RC (Ragefire Chasm)
        OnGuildEventOccurred("EI", sender, "RC")
    else
        local validThresholds = { [25] = true, [50] = true, [75] = true }
        if validThresholds[roundedPct] then
            local compressed = string.format("MAGuildEvent:PR,%s,%d", sender, roundedPct)
            table.insert(chatQueue, {
                message = compressed,
                isLocal = true,
            })
        end
    end
end

---------------------------------------------------------------
-- OPTIONAL TEST LINES (comment out if desired)
---------------------------------------------------------------
-- OnGuildEventOccurred("EI", "Gavrial", "WC")   -- Enter Wailing Caverns
-- OnGuildEventOccurred("LH", "Gavrial", "10")    -- Low health at 10%
-- OnGuildEventOccurred("LU", "Gavrial", "60")    -- Level up to 60
-- OnGuildEventOccurred("GD", "Gavrial", "XX")    -- Guild death
-- OnGuildEventOccurred("ML", "Gavrial", "XX")    -- Max level
-- CheckAndSendProgress()                        -- Queues progress events at 10%, 25%, 50%, or 75%

