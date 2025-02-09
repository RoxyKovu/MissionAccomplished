--=============================================================================
-- GavrialsCall.lua (Updated to Use EventsDictionary for Event Lookups,
-- include session logging, and avoid using SendWho for system messages)
--=============================================================================
-- This file handles local notifications (health, level, instance, etc.)
-- and uses a centralized EventsDictionary (see EventsDictionary.lua)
-- to look up messages, icons, and sounds for each event.
-- It also logs each notification (except Gavrials tips) to a running log,
-- stored in GavrialsCall.messageLog.
--=============================================================================

----------------------------------------
-- Basic Configuration and Constants
----------------------------------------
local FRAME_WIDTH    = 400
local FRAME_HEIGHT   = 60
local FRAME_STYLE    = "Organic"
local FADE_IN_TIME   = 0.5
local FADE_OUT_TIME  = 1.0
local MAX_QUEUE_SIZE = 10
local PREFIX         = "MissionAcc"

local MAX_FONT_SIZE         = 14
local MIN_FONT_SIZE         = 10
local TEXT_LENGTH_THRESHOLD = 50

local MIN_DISPLAY_TIME      = 5
local MessageDurationMapping = {
    { maxLength = 50,       duration = 7 },
    { maxLength = 100,      duration = 10 },
    { maxLength = 150,      duration = 12 },
    { maxLength = math.huge, duration = 15 },
}
local DISPLAY_TIME = 7

-- New constant: the idle delay (in seconds) after which a tip is shown.
local IDLE_TIP_DELAY = 10  -- Reduced from 60 seconds for quicker tip display

----------------------------------------
-- Message Queue and Library References
----------------------------------------
local QUEUE = {}  -- Used for animation queuing

MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.GavrialsCall = MissionAccomplished.GavrialsCall or {}
_G.GavrialsCall = MissionAccomplished.GavrialsCall
local GavrialsCall = _G.GavrialsCall

local ADDON_VERSION          = "1.1"
local ADDON_MESSAGE_THROTTLE = 1
local lastAddonMessageTime   = 0

local LibSerialize = LibStub("LibSerialize")
local LibDeflate   = LibStub("LibDeflate")

----------------------------------------
-- Basic State
----------------------------------------
GavrialsCall.isPersistent             = false
GavrialsCall.healthThresholds         = {75, 50, 25, 10}
GavrialsCall.healthThresholdsNotified = {}
GavrialsCall.previousInstanceName     = nil
GavrialsCall.lastMessage              = nil
GavrialsCall.lastMessageTime          = 0
GavrialsCall.lastMessageCooldown      = 60  -- in seconds

-- Flag used to notify the user that the frame is enabled.
GavrialsCall.frameEnabledNotified = false

local welcomeShown = false
local prevGuildOnline = {}

----------------------------------------
-- Local Helper Functions
----------------------------------------

local function isGavrialsTip(msg)
    if not EventsDictionary or not EventsDictionary.allEvents then
        return false
    end
    for key, eventData in pairs(EventsDictionary.allEvents) do
        if key:sub(1,2) == "GT" and eventData.text == msg then
            return true
        end
    end
    return false
end

local function GetShortName(fullName)
    if fullName then
        local shortName = fullName:match("([^%-]+)")
        return shortName or fullName
    end
    return fullName
end

local function IsPlayerInGuild(name)
    local numTotal = GetNumGuildMembers()
    local shortName = GetShortName(name)
    for i = 1, numTotal do
        local guildName = select(1, GetGuildRosterInfo(i))
        if guildName and GetShortName(guildName):lower() == shortName:lower() then
            return true
        end
    end
    return false
end

local function GetPlayerClass(name)
    if _G.MissionAccomplished_GuildAddonMembers then
        for _, member in ipairs(_G.MissionAccomplished_GuildAddonMembers) do
            if GetShortName(member.name):lower() == GetShortName(name):lower() then
                return member.class or "Unknown"
            end
        end
    end
    return "Unknown"
end

local function CleanName(name)
    if not name then 
        return "Unknown" 
    end
    local clean = name:match("^(.-)%-.+") or name
    return clean
end

----------------------------------------
-- Logging Setup
----------------------------------------
GavrialsCall.messageLog = {}

function GavrialsCall:LogMessage(msg)
    if isGavrialsTip(msg) then
        return
    end
    local timestamp = date("%H:%M:%S")
    local logEntry = string.format("[%s] %s", timestamp, msg)
    table.insert(self.messageLog, logEntry)
    -- Optionally: DEFAULT_CHAT_FRAME:AddMessage(logEntry)
    if self.logFrame and self.logFrame.UpdateLog then
        self.logFrame:UpdateLog()
    end
end

----------------------------------------
-- Idle Tip Timer and Random Tip Display
----------------------------------------
local idleTipTimerHandle = nil

local function StartIdleTipTimer()
    if not MissionAccomplishedDB.enableGavrialsTips then return end
    if idleTipTimerHandle then return end
    local currentLast = GavrialsCall.lastMessageTime
    idleTipTimerHandle = C_Timer.NewTimer(IDLE_TIP_DELAY, function()
        idleTipTimerHandle = nil
        if MissionAccomplishedDB.enableGavrialsTips and (GetTime() - currentLast) >= IDLE_TIP_DELAY then
            GavrialsCall:DisplayRandomTip()
        end
    end)
end

function GavrialsCall:CancelIdleTipTimer()
    if idleTipTimerHandle then
        idleTipTimerHandle:Cancel()
        idleTipTimerHandle = nil
    end
end

function GavrialsCall:DisplayRandomTip()
    if not MissionAccomplishedDB.enableGavrialsTips then return end
    if not EventsDictionary or not EventsDictionary.allEvents then return end
    local tipEvents = {}
    for key, eventData in pairs(EventsDictionary.allEvents) do
        if key:sub(1,2) == "GT" then
            table.insert(tipEvents, eventData)
        end
    end
    if #tipEvents == 0 then return end
    local tip = tipEvents[math.random(#tipEvents)]
    self:DisplayMessage("", tip.text, tip.icon, {1, 1, 1})
    if tip.sound then
        self:PlayEventSound(tip.sound)
    end
end

----------------------------------------
-- Communication Functions
----------------------------------------
function GavrialsCall:SendAddonMessageCompressed(data, channel)
    if type(data) ~= "table" then
        error("SendAddonMessageCompressed expects a table", 2)
    end
    data.version = ADDON_VERSION
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded    = LibDeflate:EncodeForPrint(compressed)
    C_ChatInfo.SendAddonMessage(PREFIX, encoded, channel)
end

function GavrialsCall:OnAddonMessage(prefix, message, distribution, sender)
    if prefix ~= PREFIX then return end
    local decoded = LibDeflate:DecodeForPrint(message)
    if not decoded then return end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end
    local success, data = LibSerialize:Deserialize(decompressed)
    if not success or type(data) ~= "table" then return end
    local now = GetTime()
    if now - lastAddonMessageTime < ADDON_MESSAGE_THROTTLE then return end
    lastAddonMessageTime = now
    if data.cmd then
        local handler = addonCommandHandlers[data.cmd]
        if handler then
            handler(sender, data.payload)
        else
            self:HandleEventMessage(data.cmd, sender)
        end
    end
end

function GavrialsCall.SendAddonMessageLegacy(params)
    if type(params) ~= "table" then
        error("SendAddonMessage expects a table parameter", 2)
    end
    if C_ChatInfo and type(C_ChatInfo.SendAddonMessage) == "function" then
        local success, result = pcall(C_ChatInfo.SendAddonMessage, params)
        if success then
            return result
        else
            return C_ChatInfo.SendAddonMessage(params.prefix, params.message, params.channel)
        end
    end
end

----------------------------------------
-- Legacy Event Message Handler
----------------------------------------
function GavrialsCall:HandleEventMessageLegacy(message, sender)
    local eventName, messageText = strsplit(":", message, 2)
    if not eventName or not messageText then return end
    local mapping = {
        Progress             = "PR",
        LowHealth            = "LH",
        LevelUp              = "LU",
        PlayerDeath          = "PlayerDeath",
        EnteredInstance      = "EI",
        LeftInstance         = "LI",
        GuildDeath           = "GD",
        GuildLevelUp         = "GLU",
        GuildAchievement     = "GAch",
        GuildLowHealth       = "GLH",
        GuildEnteredInstance = "GEI",
        MaxLevel             = "ML",
    }
    local dictKey = mapping[eventName]
    if not dictKey then
        print("Warning: No mapping found for event name:", eventName)
        return
    end
    local eventData = EventsDictionary.allEvents[dictKey]
    if not eventData then
        print("Warning: Missing event data for key:", dictKey)
        return
    end
    local color = {1, 1, 1}
    self:DisplayMessage(sender, messageText, eventData.icon, color)
    self:PlayEventSound(eventData.sound or "Sound\\Interface\\RaidWarning.wav")
end

----------------------------------------
-- Reset Health Notifications
----------------------------------------
function GavrialsCall:ResetHealthNotifications()
    for _, threshold in ipairs(self.healthThresholds) do
        self.healthThresholdsNotified[threshold] = false
    end
end

----------------------------------------
-- UI Functions
----------------------------------------
local function ApplyOrganicBanner(frame)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetBackdropBorderColor(1, 1, 1, 1)
    local swirlBar = frame:CreateTexture(nil, "ARTWORK")
    swirlBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    swirlBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    swirlBar:SetTexture("Interface\\PetPaperDollFrame\\UI-PetPaperDollFrame-LoyaltyBar")
    swirlBar:SetTexCoord(0, 1, 0, 1)
    swirlBar:SetVertexColor(1, 1, 1, 0.3)
    local staticIconSize = 40
    local staticIconFrame = CreateFrame("Frame", nil, frame)
    staticIconFrame:SetSize(staticIconSize, staticIconSize)
    staticIconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -15, 15)
    local staticIcon = staticIconFrame:CreateTexture(nil, "ARTWORK")
    staticIcon:SetAllPoints(true)
    staticIcon:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp")
    staticIconFrame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            MissionAccomplished_ToggleSettings()
        end
    end)
    frame.staticIconFrame = staticIconFrame
    frame.staticIcon      = staticIcon
    local eventIconSize   = 36
    local eventIconFrame  = CreateFrame("Frame", nil, frame)
    eventIconFrame:SetSize(eventIconSize, eventIconSize)
    eventIconFrame:SetPoint("LEFT", frame, "LEFT", 20, 0)
    local eventIcon = eventIconFrame:CreateTexture(nil, "ARTWORK")
    eventIcon:SetAllPoints(true)
    eventIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.eventIconFrame = eventIconFrame
    frame.eventIcon       = eventIcon
    local messageText = frame:CreateFontString(nil, "OVERLAY")
    messageText:SetPoint("LEFT", frame, "LEFT", 60, 0)
    messageText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    messageText:SetJustifyH("CENTER")
    messageText:SetJustifyV("MIDDLE")
    messageText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    messageText:SetWordWrap(true)
    messageText:SetTextColor(1, 1, 1, 1)
    frame.messageText = messageText
end

function MissionAccomplished_Event_ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cff00ff00MissionAccomplished Notifications|r")
    GameTooltip:AddLine("Hold SHIFT and drag to reposition this frame.", 1, 1, 1)
    GameTooltip:AddLine("Click the icon in the top left corner to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

----------------------------------------
-- Process Incoming Chat Messages with MAGuildEvent:
----------------------------------------
function GavrialsCall:ProcessIncomingCompressedMessage(message)
    if string.sub(message, 1, 13) ~= "MAGuildEvent:" then return end
    local data = string.sub(message, 14)
    local eventCode, remoteSender, extraData = strsplit(",", data)
    local fullEvent = EventsDictionary.eventTypeLookup[eventCode] or eventCode

    if fullEvent == "Progress" or fullEvent == "PR" then
        local eventData = EventsDictionary.allEvents.PR
        if eventData then
            local localName = UnitName("player")
            local msg = string.format(eventData.message, remoteSender, extraData)
            self:DisplayMessage(localName, msg, eventData.icon, {1, 1, 1})
        end
    elseif fullEvent == "EnteredInstance" or fullEvent == "EI" then
        local eventData = EventsDictionary.allEvents.EI
        if eventData then
            local msg = string.format(eventData.message, remoteSender)
            self:DisplayMessage(remoteSender, msg, eventData.icon, {1, 1, 1})
        end
    elseif fullEvent == "LowHealth" or fullEvent == "LH" then
        local eventData = EventsDictionary.allEvents.LH
        if eventData then
            local msg = string.format(eventData.message, remoteSender, extraData or "??")
            self:DisplayMessage(remoteSender, msg, eventData.icon, {1, 1, 1})
        end
    elseif fullEvent == "LevelUp" or fullEvent == "LU" then
        local eventData = EventsDictionary.allEvents.LU
        if eventData then
            local level, playerClass = strsplit(",", extraData)
            local msg = string.format(eventData.message, remoteSender, playerClass, level)
            self:DisplayMessage(remoteSender, msg, eventData.icon, {1, 1, 1})
        end
    elseif fullEvent == "GuildDeath" or fullEvent == "GD" then
        if extraData == "FD" then return end
        local eventData = EventsDictionary.allEvents.GD
        if eventData then
            local msg = string.format(eventData.message, remoteSender)
            self:DisplayMessage(remoteSender, msg, eventData.icon, {1, 1, 1})
        end
    elseif fullEvent == "MaxLevel" or fullEvent == "ML" then
        local eventData = EventsDictionary.allEvents.ML
        if eventData then
            local msg = string.format(eventData.message, remoteSender)
            self:DisplayMessage(remoteSender, msg, eventData.icon, {1, 1, 1})
        end
    else
        local fallbackMsg = string.format("%s unleashed an enigma (%s) with data '%s'—mysteries deepen!", remoteSender, eventCode, extraData or "??")
        self:DisplayMessage(remoteSender, fallbackMsg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
    end
end

----------------------------------------
-- Chat Filter to Process MAGuildEvent: Messages
----------------------------------------
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(self, event, message, sender, ...)
    if string.sub(message, 1, 13) == "MAGuildEvent:" then
        GavrialsCall:ProcessIncomingCompressedMessage(message)
        return false  -- Let the message appear in chat as normal.
    end
end)

----------------------------------------
-- Create the Main Event Frame (with fade animation)
----------------------------------------
function GavrialsCall:CreateFrame()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "MissionAccomplishedGavrialsCallFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if MissionAccomplishedDB then
            local point, _, relPoint, x, y = self:GetPoint()
            MissionAccomplishedDB.gavFramePos = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)
    if FRAME_STYLE == "Organic" then
        ApplyOrganicBanner(frame)
    else
        frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
        frame:SetBackdropColor(0, 0, 0, 0.5)
    end
    frame:SetScript("OnShow", function(self)
        if not MissionAccomplishedDB.eventFrameEnabled then
            self:Hide()
        end
    end)
    frame:SetScript("OnEnter", function(self)
        -- Once the frame is shown, hover functions work normally.
        MissionAccomplished_Event_ShowTooltip(self)
        if self:GetAlpha() < 1 then
            UIFrameFadeIn(self, 0.5, self:GetAlpha(), 1)
        end
    end)
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if not GavrialsCall.isPersistent then
            UIFrameFadeOut(self, FADE_OUT_TIME)
        end
    end)
    frame.InOut = frame:CreateAnimationGroup()
    local animFadeIn = frame.InOut:CreateAnimation("Alpha")
    animFadeIn:SetOrder(1)
    animFadeIn:SetDuration(FADE_IN_TIME)
    animFadeIn:SetFromAlpha(0)
    animFadeIn:SetToAlpha(1)
    local animWait = frame.InOut:CreateAnimation("Alpha")
    animWait:SetOrder(2)
    animWait:SetDuration(DISPLAY_TIME)
    animWait:SetFromAlpha(1)
    animWait:SetToAlpha(1)
    frame.animWait = animWait
    local animFadeOut = frame.InOut:CreateAnimation("Alpha")
    animFadeOut:SetOrder(3)
    animFadeOut:SetDuration(FADE_OUT_TIME)
    animFadeOut:SetFromAlpha(1)
    animFadeOut:SetToAlpha(0)
    frame.InOut:SetScript("OnFinished", function()
        frame:SetAlpha(0)
        if #QUEUE > 0 then
            local nextMsg = table.remove(QUEUE, 1)
            GavrialsCall:DisplayMessage(nextMsg.playerName, nextMsg.text, nextMsg.icon, nextMsg.color)
        else
            StartIdleTipTimer()
        end
    end)
    frame:Hide()
    if MissionAccomplishedDB and MissionAccomplishedDB.gavFramePos then
        local pos = MissionAccomplishedDB.gavFramePos
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end
    self.frame = frame
    return frame
end

----------------------------------------
-- PlayEventSound: Plays a sound for an event (if enabled).
----------------------------------------
function GavrialsCall:PlayEventSound(soundFile)
    if MissionAccomplishedDB and MissionAccomplishedDB.eventSoundsEnabled == false then return end
    if soundFile then
        PlaySoundFile(soundFile, "Master")
    end
end

----------------------------------------
-- DisplayMessage: Logs the message and shows a notification on the main event frame.
-- Even if the event box is disabled, the message is still logged.
----------------------------------------
function GavrialsCall:DisplayMessage(sender, text, iconPath, color)
    local player = UnitName("player")
    if sender and sender ~= "" and GetShortName(sender):lower() == (player and player:lower() or "") then
        sender = ""
    end
    local prefix = ""
    if sender and sender ~= "" then
        prefix = GetShortName(sender) .. ", "
    end
    local msgFormatted = prefix .. (text or "")
    
    -- Duplicate filtering: if the same message was processed within the cooldown, skip it.
    local now = GetTime()
    if self.lastMessage == msgFormatted and (now - self.lastMessageTime) < self.lastMessageCooldown then
        return
    end
    self.lastMessage = msgFormatted
    self.lastMessageTime = now
    
    -- Always log the message.
    self:LogMessage(msgFormatted)
    
    -- Only display the UI if the event box is enabled.
    if not MissionAccomplishedDB.eventFrameEnabled then
        return
    end
    if not self.frame then self:CreateFrame() end
    local frame = self.frame
    if frame:IsShown() and frame.InOut:IsPlaying() then
        for _, queuedMsg in ipairs(QUEUE) do
            if queuedMsg.playerName == sender and queuedMsg.text == text then
                return  -- Duplicate in queue; do not add.
            end
        end
        if #QUEUE < MAX_QUEUE_SIZE then
            table.insert(QUEUE, { playerName = sender, text = text, icon = iconPath, color = color })
        end
        return
    end
    local baseFontSize = MAX_FONT_SIZE
    local textLength   = text and #text or 0
    if textLength > TEXT_LENGTH_THRESHOLD then
        local reduction = math.floor((textLength - TEXT_LENGTH_THRESHOLD) / 20)
        baseFontSize = math.max(MIN_FONT_SIZE, MAX_FONT_SIZE - reduction)
    end
    frame.messageText:SetFont("Fonts\\FRIZQT__.TTF", baseFontSize, "OUTLINE")
    local messageDuration = MIN_DISPLAY_TIME
    for _, mapping in ipairs(MessageDurationMapping) do
        if textLength <= mapping.maxLength then
            messageDuration = mapping.duration
            break
        end
    end
    if frame.animWait then frame.animWait:SetDuration(messageDuration) end
    frame.messageText:SetText(msgFormatted)
    if iconPath and type(iconPath) == "string" then
        frame.eventIcon:SetTexture(iconPath)
    else
        frame.eventIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    if type(color) == "table" and #color >= 3 then
        frame.messageText:SetTextColor(color[1], color[2], color[3])
    else
        frame.messageText:SetTextColor(1, 1, 1)
    end
    frame.InOut:Stop()
    frame:SetAlpha(0)
    frame:Show()
    frame.InOut:Play()
    StartIdleTipTimer()
end

----------------------------------------
-- New: NotifyFrameEnabled – shows a one‑time “Event Box Enabled” message.
----------------------------------------
function GavrialsCall:NotifyFrameEnabled()
    self:DisplayMessage("", "Event Box Enabled", "Interface\\Icons\\INV_Misc_ChatBubble_01", {0, 1, 0})
end

----------------------------------------
-- New: SendLocalProgress – sends a local progress event message to the user.
-- (Assumes that MissionAccomplished_GetProgressPercentage is defined elsewhere.)
----------------------------------------
function GavrialsCall:SendLocalProgress()
    local progressPct = MissionAccomplished_GetProgressPercentage and MissionAccomplished_GetProgressPercentage() or 0
    local rounded = math.floor(progressPct + 0.5)
    local eventData = EventsDictionary.allEvents.PR
    if eventData then
        local formattedMessage = string.format(eventData.message, UnitName("player"), rounded)
        self:DisplayMessage(UnitName("player"), formattedMessage, eventData.icon, {1, 1, 1})
    end
end

----------------------------------------
-- Show and Hide Functions
----------------------------------------
function GavrialsCall:Show(persistent)
    if not MissionAccomplishedDB.eventFrameEnabled then
        self:Hide()
        return  -- Do not show if the event box is disabled.
    end

    -- Simulate PLAYER_ENTERING_WORLD / login behavior when enabling the Event Box:
    if not welcomeShown then
        local playerName  = UnitName("player") or "Player"
        local playerLevel = UnitLevel("player") or 1
        if playerLevel >= 60 then
            local eventData = EventsDictionary.allEvents.Welcome60
            local formattedMessage = string.format(eventData.message, playerName)
            self:DisplayMessage("", formattedMessage, eventData.icon, {1, 1, 1})
            self:PlayEventSound(eventData.sound)
        else
            local xpSoFar = MissionAccomplished.GetTotalXPSoFar() or 0
            local xpMax   = MissionAccomplished.GetXPMaxTo60() or 1
            local remain  = xpMax - xpSoFar
            if remain < 0 then remain = 0 end
            local pct = (xpSoFar / xpMax) * 100
            local eventData = EventsDictionary.allEvents.Welcome
            local formattedMessage = string.format(eventData.message, playerName, pct, remain)
            self:DisplayMessage("", formattedMessage, eventData.icon, {1, 1, 1})
            self:PlayEventSound(eventData.sound)
        end
        welcomeShown = true
    end

    -- Reset the idle timer so that if no other events occur, a tip will appear promptly.
    self.lastMessageTime = GetTime() - IDLE_TIP_DELAY

    if not self.frameEnabledNotified then
        self:NotifyFrameEnabled()
        self.frameEnabledNotified = true
        self:SendLocalProgress()  -- Send local progress when enabling.
    end
    self.isPersistent = persistent and true or false
    if self.frame then
        self.frame.InOut:Stop()
        if persistent then
            self.frame:SetAlpha(1)
        else
            self.frame:SetAlpha(0)
        end
        self.frame:Show()
        if not persistent then
            self.frame.InOut:Play()
        end
    else
        self:CreateFrame()
        self.frame.InOut:Stop()
        if persistent then
            self.frame:SetAlpha(1)
        else
            self.frame:SetAlpha(0)
        end
        self.frame:Show()
        if not persistent then
            self.frame.InOut:Play()
        end
    end
end

function GavrialsCall:Hide()
    if self.frame then
        self.isPersistent = false
        self.frame.InOut:Stop()
        self.frame:Hide()  -- Immediately hide the frame.
    end
    self.frameEnabledNotified = false
end

----------------------------------------
-- Event Handling Helpers
----------------------------------------
local function handlePlayerLevelUp(self, newLevel)
    local pName = UnitName("player") or "Player"
    if newLevel == 60 then
        local eventData = EventsDictionary.allEvents.ML
        local formattedMessage = string.format(eventData.message, pName)
        local guildName = GetGuildInfo("player")
        if guildName then
            self:SendMessage("ML", formattedMessage, "GUILD")
        else
            self:DisplayMessage(pName, formattedMessage, eventData.icon, {1, 1, 1})
        end
        self:PlayEventSound(eventData.sound)
    else
        local eventData = EventsDictionary.allEvents.LU
        local formattedMessage = string.format(eventData.message, pName, newLevel)
        local guildName = GetGuildInfo("player")
        if guildName then
            self:SendMessage("LU", formattedMessage, "GUILD")
        else
            self:DisplayMessage(pName, formattedMessage, eventData.icon, {0, 1, 0})
        end
        self:PlayEventSound(eventData.sound)
    end
end

local function handleUnitHealth(self, unit)
    if unit == "player" then
        local pName = UnitName("player") or "Unknown"
        local health = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        if maxHealth == 0 then return end
        local pct = (health / maxHealth) * 100
        for _, threshold in ipairs(self.healthThresholds) do
            if pct <= threshold and not self.healthThresholdsNotified[threshold] then
                local eventData = EventsDictionary.allEvents.LH
                local formattedMessage = string.format(eventData.message, pName, math.floor(pct))
                self:DisplayMessage(pName, formattedMessage, eventData.icon, {1, 0, 0})
                self:PlayEventSound(eventData.sound)
                self.healthThresholdsNotified[threshold] = true
                if threshold == 10 then
                    local guildName = GetGuildInfo("player")
                    if guildName then
                        OnGuildEventOccurred("LH", pName, math.floor(pct))
                    end
                end
            end
        end
        local allNotified = true
        for _, thr in ipairs(self.healthThresholds) do
            if pct > thr then
                allNotified = false
                break
            end
        end
        if allNotified then
            self:ResetHealthNotifications()
        end
    end
end

local function handlePlayerDead(self)
    local pName = UnitName("player") or "Player"
    local guildName = GetGuildInfo("player")
    if guildName then
        local eventData = EventsDictionary.allEvents.GD
        local formattedMessage = string.format(eventData.message, pName)
        self:SendMessage("GD", formattedMessage, "GUILD")
        self:PlayEventSound(eventData.sound)
    else
        local eventData = EventsDictionary.allEvents.PlayerDeath
        local formattedMessage = string.format(eventData.message, pName)
        self:DisplayMessage(pName, formattedMessage, eventData.icon, {0.5, 0, 0})
        self:PlayEventSound(eventData.sound)
    end
end

local function handleUpdateExhaustion(self)
    local pName = UnitName("player") or "Player"
    local guildName = GetGuildInfo("player")
    local xpPct = MissionAccomplished_GetProgressPercentage() or 0
    local rounded = math.floor(xpPct + 0.5)
    local eventData = EventsDictionary.allEvents.PR
    local formattedMessage = string.format(eventData.message, pName, rounded)
    if guildName then
        self:SendMessage("PR", formattedMessage, "GUILD")
    else
        self:DisplayMessage(pName, formattedMessage, eventData.icon, {0.7, 0.7, 1})
    end
    self:PlayEventSound(eventData.sound)
end

local function handleUnitAura(self, unit)
    if unit == "player" then
        local pName = UnitName("player") or "Player"
        if not self.activeBuffs then self.activeBuffs = {} end
        local currentBuffs = {}
        local index = 1
        while true do
            local buffName, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff("player", index)
            if not buffName then break end
            currentBuffs[buffName] = { icon = EventsDictionary.allEvents.BE.icon, expirationTime = expirationTime, duration = duration }
            index = index + 1
        end
        local buffChangeAnnounced = false
        for buffName, data in pairs(currentBuffs) do
            if not self.activeBuffs[buffName] then
                local eventData = EventsDictionary.allEvents.BE
                local formattedMessage = string.format(eventData.messageGain, pName, buffName)
                self:DisplayMessage(pName, formattedMessage, eventData.icon, {0, 1, 1})
                self:PlayEventSound(eventData.sound)
                buffChangeAnnounced = true
                break
            end
        end
        if not buffChangeAnnounced then
            for buffName, data in pairs(self.activeBuffs) do
                if not currentBuffs[buffName] then
                    local eventData = EventsDictionary.allEvents.BE
                    local formattedMessage = string.format(eventData.messageLost, pName, buffName)
                    self:DisplayMessage(pName, formattedMessage, eventData.icon, {1, 0, 0})
                    self:PlayEventSound(eventData.sound)
                    break
                end
            end
        end
        self.activeBuffs = currentBuffs
    end
end

local function handleCombatLogEvent(self)
    local pName = UnitName("player") or "Player"
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount = CombatLogGetCurrentEventInfo()
    if subevent == "SPELL_DAMAGE" and sourceName == pName then
        local currentHealth = UnitHealth("player")
        if amount and currentHealth and amount > (currentHealth * 0.30) then
            local eventData = EventsDictionary.allEvents.BH
            local formattedMessage = string.format(eventData.message, pName, destName or "an enemy", amount)
            self:DisplayMessage(pName, formattedMessage, eventData.icon, {1, 0.5, 0})
            self:PlayEventSound(eventData.sound)
        end
    end
end

local function handleGuildRosterUpdate(self)
    local pName = UnitName("player") or "Player"
    GuildRoster()
    local numTotal = GetNumGuildMembers()
    local eventData = EventsDictionary.allEvents.GR
    if not self.announcedGuildMembers then
        self.announcedGuildMembers = {}
        for i = 1, numTotal do
            local fullName = select(1, GetGuildRosterInfo(i))
            if fullName then
                local cleanName = CleanName(fullName)
                self.announcedGuildMembers[cleanName] = true
            end
        end
    else
        for i = 1, numTotal do
            local fullName, rank, rankIndex, level, class, zone, note, officerNote, isOnline = GetGuildRosterInfo(i)
            if isOnline then
                local cleanName = CleanName(fullName)
                if not self.announcedGuildMembers[cleanName] then
                    local formattedMessage = string.format(eventData.message, cleanName, class)
                    self:DisplayMessage(pName, formattedMessage, eventData.icon, {0.2, 0.8, 1})
                    self:PlayEventSound(eventData.sound)
                    self.announcedGuildMembers[cleanName] = true
                end
            end
        end
    end
end

local function handleChatMsgSystem(self, ...)
    local sysMsg = select(1, ...)
    self:HandleSystemMessage(sysMsg)
end

function GavrialsCall:HandleCharacterEvent(event, ...)
    local pName = UnitName("player") or "Player"
    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        handlePlayerLevelUp(self, newLevel)
    elseif event == "UNIT_HEALTH" then
        local unit = ...
        handleUnitHealth(self, unit)
    elseif event == "PLAYER_DEAD" then
        handlePlayerDead(self)
    elseif event == "UPDATE_EXHAUSTION" then
        handleUpdateExhaustion(self)
    elseif event == "UNIT_AURA" then
        local unit = ...
        handleUnitAura(self, unit)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        handleCombatLogEvent(self)
    elseif event == "GUILD_ROSTER_UPDATE" then
        handleGuildRosterUpdate(self)
    elseif event == "CHAT_MSG_SYSTEM" then
        handleChatMsgSystem(self, ...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Do nothing; instance entry is handled elsewhere.
    end
end

function GavrialsCall:HandleSystemMessage(message, ...)
    local name = message:match("^(%S+) has reached level 60!$")
    local playerName = UnitName("player")
    if name and name == playerName then 
        return 
    end
    if name then
        local playerClass, guildName
        if IsPlayerInGuild(name) then
            playerClass = GetPlayerClass(name)
            guildName = GetGuildInfo("player") or "No Guild"
        else
            playerClass = "Adventurer"
            guildName = "Azeroth"
        end
        local eventData = EventsDictionary.allEvents.EP
        if not eventData then
            print("Warning: Missing EP event data in EventsDictionary.allEvents.")
            return
        end
        local formattedMessage = string.format(eventData.message, name, playerClass, guildName)
        self:DisplayMessage("", formattedMessage, eventData.icon, {1, 0.84, 0})
        self:PlayEventSound(eventData.sound)
    end
end

------------------------------------------------------------------------------
-- Modular Command Handlers
------------------------------------------------------------------------------
addonCommandHandlers = {
    EnableEventFrame = function(sender, payload)
        GavrialsCall:Show(false)
    end,
    DisableEventFrame = function(sender, payload)
        GavrialsCall:Hide()
    end,
    AddonPing = function(sender, payload)
        local playerName = UnitName("player") or "Player"
        local race       = UnitRace("player") or "Unknown"
        local class      = select(1, UnitClass("player")) or "Unknown"
        local level      = UnitLevel("player") or 1
        local progress   = MissionAccomplished.GetProgressPercentage() or 0
        local replyPayload = string.format("%s;%s;%s;%d;%.1f;%s", playerName, race, class, level, progress, ADDON_VERSION)
        GavrialsCall:SendMessage("AddonReply", replyPayload, "GUILD")
    end,
    AddonReply = function(sender, payload)
        local name, race, class, level, progress, version = strsplit(";", payload)
        level    = tonumber(level) or 1
        progress = tonumber(progress) or 0
        _G.MissionAccomplished_GuildAddonMembers = _G.MissionAccomplished_GuildAddonMembers or {}
        local updated = false
        for _, v in ipairs(_G.MissionAccomplished_GuildAddonMembers) do
            if GetShortName(v.name):lower() == GetShortName(name):lower() then
                v.race     = race
                v.class    = class
                v.level    = level
                v.progress = progress
                v.version  = version
                updated = true
                break
            end
        end
        if not updated then
            table.insert(_G.MissionAccomplished_GuildAddonMembers, { name = name, race = race, class = class, level = level, progress = progress, version = version })
        end
    end,
    ProfessionData = function(sender, payload)
        _G.MissionAccomplished_GuildAddonMembers = _G.MissionAccomplished_GuildAddonMembers or {}
        local updated = false
        for _, v in ipairs(_G.MissionAccomplished_GuildAddonMembers) do
            if GetShortName(v.name):lower() == GetShortName(sender):lower() then
                v.professions = payload.professions
                updated = true
                break
            end
        end
        if not updated then
            table.insert(_G.MissionAccomplished_GuildAddonMembers, { name = sender, professions = payload.professions })
        end
    end,
    INTER_ADDON = function(sender, payload)
        if payload.professions then
            addonCommandHandlers["ProfessionData"](sender, payload)
        end
    end,
}

------------------------------------------------------------------------------
-- Communication: Send a robust addon message
------------------------------------------------------------------------------
function GavrialsCall:SendMessage(cmd, payload, channel)
    local data = { cmd = cmd, payload = payload }
    self:SendAddonMessageCompressed(data, channel)
end

------------------------------------------------------------------------------
-- Global Callback Registration
------------------------------------------------------------------------------
MissionAccomplished._callbacks = MissionAccomplished._callbacks or {}
function MissionAccomplished.RegisterCallback(event, callback)
    MissionAccomplished._callbacks[event] = MissionAccomplished._callbacks[event] or {}
    table.insert(MissionAccomplished._callbacks[event], callback)
end

local function TriggerCallbacks(event, ...)
    if MissionAccomplished._callbacks[event] then
        for _, cb in ipairs(MissionAccomplished._callbacks[event]) do
            pcall(cb, event, ...)
        end
    end
end

------------------------------------------------------------------------------
-- Centralized Event Registration
------------------------------------------------------------------------------
local function RegisterEvents(frame)
    local events = {
        "PLAYER_LEVEL_UP",
        "UNIT_HEALTH",
        "PLAYER_DEAD",
        "PLAYER_ENTERING_WORLD",
        "UPDATE_EXHAUSTION",
        "UNIT_AURA",
        "COMBAT_LOG_EVENT_UNFILTERED",
        "GUILD_ROSTER_UPDATE",
        "CHAT_MSG_SYSTEM",
    }
    for _, eventName in ipairs(events) do
        frame:RegisterEvent(eventName)
    end
    frame:SetScript("OnEvent", function(_, ev, ...)
        GavrialsCall:HandleCharacterEvent(ev, ...)
        TriggerCallbacks(ev, ...)
    end)
end

------------------------------------------------------------------------------
-- New: SendLocalProgress – sends a local progress event message to the user.
------------------------------------------------------------------------------
function GavrialsCall:SendLocalProgress()
    local progressPct = MissionAccomplished_GetProgressPercentage and MissionAccomplished_GetProgressPercentage() or 0
    local rounded = math.floor(progressPct + 0.5)
    local eventData = EventsDictionary.allEvents.PR
    if eventData then
        local formattedMessage = string.format(eventData.message, UnitName("player"), rounded)
        self:DisplayMessage(UnitName("player"), formattedMessage, eventData.icon, {1, 1, 1})
    end
end

----------------------------------------
-- Initialization
----------------------------------------
function GavrialsCall:Init()
    self:CreateFrame()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(PREFIX) then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
    self.eventFrame = CreateFrame("Frame")
    RegisterEvents(self.eventFrame)
    self:ResetHealthNotifications()
    GuildRoster()
    local function DisplayWelcomeTextOnce()
        if welcomeShown then return end
        welcomeShown = true
        local playerName  = UnitName("player") or "Player"
        local playerLevel = UnitLevel("player") or 1
        if playerLevel >= 60 then
            local eventData = EventsDictionary.allEvents.Welcome60
            local formattedMessage = string.format(eventData.message, playerName)
            self:DisplayMessage("", formattedMessage, eventData.icon, {1, 1, 1})
            self:PlayEventSound(eventData.sound)
        else
            local xpSoFar = MissionAccomplished.GetTotalXPSoFar() or 0
            local xpMax   = MissionAccomplished.GetXPMaxTo60() or 1
            local remain  = xpMax - xpSoFar
            if remain < 0 then remain = 0 end
            local pct = (xpSoFar / xpMax) * 100
            local eventData = EventsDictionary.allEvents.Welcome
            local formattedMessage = string.format(eventData.message, playerName, pct, remain)
            self:DisplayMessage("", formattedMessage, eventData.icon, {1, 1, 1})
            self:PlayEventSound(eventData.sound)
        end
    end
    DisplayWelcomeTextOnce()
    if MissionAccomplishedDB and MissionAccomplishedDB.eventFrameEnabled then
        self:Show(false)
    else
        self:Hide()  -- Ensure it is hidden if disabled.
    end
end

------------------------------------------------------------------------------
-- ADDON_LOADED / CHAT_MSG_ADDON
------------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("CHAT_MSG_ADDON")
initFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MissionAccomplished" then
            GavrialsCall:Init()
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, distribution, sender = ...
        if prefix ~= PREFIX then return end
        GavrialsCall:OnAddonMessage(prefix, message, distribution, sender)
    end
end)

-- END of GavrialsCall.lua
