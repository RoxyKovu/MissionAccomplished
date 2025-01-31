--=============================================================================
-- GavrialsCall.lua
--=============================================================================
-- Handles the "Gavrial's Call" notification frame.
-- Sends and listens to a hidden chat channel "GavrialcallsHCeventscodes".
-- Displays notifications based on messages received from the hidden channel.
--=============================================================================

-- Ensure the global MissionAccomplished table exists
MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.GavrialsCall = MissionAccomplished.GavrialsCall or {}
local GavrialsCall = MissionAccomplished.GavrialsCall

-- Configuration Constants
local NOTIFICATION_WIDTH = 400
local NOTIFICATION_HEIGHT = 100
local FADE_IN_TIME = 0.5
local FADE_OUT_TIME = 1.0
local DISPLAY_TIME = 5.0
local HIDDEN_CHANNEL_NAME = "GavrialcallsHCeventscodes"
local QUEUE = {}

-- Create or join the hidden channel
function GavrialsCall.CreateOrJoinHiddenChannel()
    local channelIndex = GetChannelName(HIDDEN_CHANNEL_NAME)
    if channelIndex == 0 then
        JoinTemporaryChannel(HIDDEN_CHANNEL_NAME)
        print("[GavrialsCall] Joined hidden channel: " .. HIDDEN_CHANNEL_NAME)
    else
        print("[GavrialsCall] Already in hidden channel.")
    end
end

-- Function to create the notification frame
function GavrialsCall.CreateFrame()
    -- Check if the frame already exists
    if _G.GavrialsCallFrame then
        return _G.GavrialsCallFrame
    end

    -- Create the main frame
    local frame = CreateFrame("Frame", "GavrialsCallFrame", UIParent, "BackdropTemplate")
    frame:SetSize(NOTIFICATION_WIDTH, NOTIFICATION_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200) -- Position the box
    frame:SetFrameStrata("HIGH")
    frame:SetAlpha(1) -- Keep the frame visible at all times

    -- Frame backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = false,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(1, 1, 1, 1)

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(50, 50)
    icon:SetPoint("LEFT", frame, "LEFT", 10, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- Default icon
    frame.icon = icon

    -- Message text
    local message = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    message:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    message:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    message:SetJustifyH("LEFT")
    message:SetText("Listening for events...")
    frame.message = message

    _G.GavrialsCallFrame = frame
    return frame
end

-- Function to display a message in the notification frame
function GavrialsCall.DisplayMessage(text, iconPath, color)
    if not _G.GavrialsCallFrame then
        GavrialsCall.CreateFrame()
    end

    local frame = _G.GavrialsCallFrame
    frame.message:SetText(text)

    if iconPath then
        frame.icon:SetTexture(iconPath)
    else
        frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- Default
    end

    if color then
        frame.message:SetTextColor(unpack(color))
    else
        frame.message:SetTextColor(1, 1, 1) -- Default white
    end
end

-- Function to send a test message to the hidden channel
function GavrialsCall.SendMessageToChannel(eventType, message)
    local channelIndex = GetChannelName(HIDDEN_CHANNEL_NAME)
    if channelIndex == 0 then
        print("[GavrialsCall] Not in hidden channel!")
        return
    end
    SendChatMessage(eventType .. ":" .. message, "CHANNEL", nil, channelIndex)
end

-- Function to handle incoming chat messages
function GavrialsCall.HandleChatMessage(message, _, _, channelName, _, _, _, channelNumber)
    if channelName ~= HIDDEN_CHANNEL_NAME then
        return
    end

    local eventType, eventMessage = strsplit(":", message, 2)
    if not eventType or not eventMessage then
        return
    end

    -- Customize display for specific event types
    local iconPath = nil
    local color = {1, 1, 1} -- Default white

    if eventType == "HEALTH" then
        iconPath = "Interface\\Icons\\Spell_Holy_SealOfSacrifice"
        color = {1, 0, 0} -- Red
    elseif eventType == "LEVEL" then
        iconPath = "Interface\\Icons\\Achievement_Level_10"
        color = {0, 1, 0} -- Green
    elseif eventType == "PROGRESS" then
        iconPath = "Interface\\Icons\\Spell_Nature_TimeStop"
        color = {0, 0.5, 1} -- Blue
    elseif eventType == "DUNGEON" then
        iconPath = "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider"
        color = {1, 0.843, 0} -- Gold
    end

    GavrialsCall.DisplayMessage(eventMessage, iconPath, color)
end

-- Slash commands for testing
SLASH_GAVRIALSCALL1 = "/gcall"
SlashCmdList["GAVRIALSCALL"] = function(msg)
    if msg == "testhealth" then
        GavrialsCall.SendMessageToChannel("HEALTH", "Health below 25%!")
    elseif msg == "testlevel" then
        GavrialsCall.SendMessageToChannel("LEVEL", "Reached level 10!")
    elseif msg == "testprogress" then
        GavrialsCall.SendMessageToChannel("PROGRESS", "25% progress to level 60!")
    elseif msg == "testdungeon" then
        GavrialsCall.SendMessageToChannel("DUNGEON", "Entering Deadmines!")
    else
        print("Usage: /gcall [testhealth|testlevel|testprogress|testdungeon]")
    end
end

-- Initialization
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MissionAccomplished" then
            GavrialsCall.CreateOrJoinHiddenChannel()
            GavrialsCall.CreateFrame()
        end
    elseif event == "CHAT_MSG_CHANNEL" then
        GavrialsCall.HandleChatMessage(...)
    end
end)
