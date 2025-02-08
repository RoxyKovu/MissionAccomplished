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

-- Basic configuration
local FRAME_WIDTH    = 400
local FRAME_HEIGHT   = 60
local FRAME_STYLE    = "Organic"
local FADE_IN_TIME   = 0.5
local FADE_OUT_TIME  = 1.0
local MAX_QUEUE_SIZE = 10
local PREFIX         = "MissionAcc"

-- Dynamic font sizing
local MAX_FONT_SIZE         = 14
local MIN_FONT_SIZE         = 10
local TEXT_LENGTH_THRESHOLD = 50

-- Dynamic display duration
local MIN_DISPLAY_TIME      = 5
local MessageDurationMapping = {
    { maxLength = 50,       duration = 7 },
    { maxLength = 100,      duration = 10 },
    { maxLength = 150,      duration = 12 },
    { maxLength = math.huge, duration = 15 },
}
local DISPLAY_TIME = 7

-- Message queue
local QUEUE = {}

-- Ensure addon table
MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.GavrialsCall = MissionAccomplished.GavrialsCall or {}
_G.GavrialsCall = MissionAccomplished.GavrialsCall
local GavrialsCall = _G.GavrialsCall

-- Throttles
local ADDON_VERSION          = "1.1"
local ADDON_MESSAGE_THROTTLE = 1
local lastAddonMessageTime   = 0

-- Library references
local LibSerialize = LibStub("LibSerialize")
local LibDeflate   = LibStub("LibDeflate")

-- Basic state
GavrialsCall.isPersistent             = false
GavrialsCall.healthThresholds         = {75, 50, 25, 10}
GavrialsCall.healthThresholdsNotified = {}
GavrialsCall.previousInstanceName     = nil
GavrialsCall.lastMessage              = nil
GavrialsCall.lastMessageTime          = 0
GavrialsCall.lastMessageCooldown      = 60

local welcomeShown = false
local prevGuildOnline = {}

------------------------------------------------------------------------------
-- Gavrials Tips Table
------------------------------------------------------------------------------
local GAVRIALS_TIPS = {
    { text = "Close Call from The Warrior, Gavrial the 1st: Trust Your Gut – If you have a bad feeling about an enemy or quest, skip it.", icon = "Interface\\Icons\\Ability_Rogue_FeignDeath" },
    { text = "Close Call from The Warrior, Gavrial the 1st: Group Up – Strength in numbers—team up whenever possible.", icon = "Interface\\Icons\\inv_misc_groupneedmore" },
    { text = "Close Call from The Rogue, Gavrial the 2nd: Plan Realistic Escapes – An escape route is essential, but make it practical—many have drowned fleeing through windows.", icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
    { text = "Final Lesson of The Mage, Gavrial the 3rd: Know Your Limits – Don’t overestimate your strength; play smart.", icon = "Interface\\Icons\\Ability_Defend" },
    { text = "Close Call from The Druid, Gavrial the 4th: Run, Don’t Die – If things go south, don’t hesitate to run.", icon = "Interface\\Icons\\ability_rogue_sprint" },
    { text = "Lesson from The Mage, Gavrial the 3rd: Be an Engineer – If you are not confident in your skills as a player, Engineering opens up powerful tools and gadgets that can save your life.", icon = "Interface\\Icons\\Trade_Engineering" },
    { text = "Lesson from The Mage, Gavrial the 3rd: Train Your Skills – Regularly visit trainers to keep your abilities updated—outdated skills can cost you your life.", icon = "Interface\\Icons\\spell_shadow_scourgebuild" },
    { text = "Lesson from The Mage, Gavrial the 3rd: Buy Big Bags – Trash in large amounts is worth its weight in gold.", icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    { text = "Final Lesson of The Shaman, Gavrial the 5th: Play It Safe – If you’re not feeling confident, go for green mobs.", icon = "Interface\\Icons\\Ability_Hunter_SniperShot" },
    { text = "Final Lesson of The Warrior, Gavrial the 1st: Stick With Friends – When possible, run dungeons with people you know. If not, assume strangers won’t prioritize your safety.", icon = "Interface\\Icons\\INV_Misc_GroupLooking" },
    { text = "Lesson from The Druid, Gavrial the 4th: Keep Big Pots – Always carry potions, just in case.", icon = "Interface\\Icons\\INV_Potion_54" },
    { text = "Lesson from The Druid, Gavrial the 4th: Save Gold – Don’t waste money on unnecessary purchases.", icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    { text = "Lesson from The Rogue, Gavrial the 2nd: Scout Ahead – Use stealth or careful planning to avoid traps.", icon = "Interface\\Icons\\Ability_Stealth" },
    { text = "Lesson from The Paladin, Gavrial the 6th: Know Your Role – Play to your class’s strengths in groups.", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight" },
    { text = "Lesson from The Paladin, Gavrial the 6th: Stay Informed – Read up on dungeons, quests, and zones before diving in.", icon = "Interface\\Icons\\INV_Misc_Book_03" },
    { text = "Final Lesson of The Paladin, Gavrial the 6th: Beware Murlocs – They choose violence and have too many friends.", icon = "Interface\\Icons\\INV_Misc_MonsterHead_02" },
    { text = "Final Lesson of The Priest, Gavrial the 7th: Happy Healer, Happy Party – Keep your healer safe and supplied!", icon = "Interface\\Icons\\Spell_Holy_Renew" },
    { text = "Final Lesson of The Druid, Gavrial the 4th: Beware of Caves – In hardcore WoW, caves are death traps—escape routes are rare.", icon = "Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility" },
    { text = "Lesson from The Hunter, Gavrial the 9th: Play Smart, Not Flashy – Dying at level 32 because of a risky move isn’t impressive—reaching level 60 is the real achievement.", icon = "Interface\\Icons\\Achievement_Level_60" },
    { text = "Final Lesson of The Warlock, Gavrial the 8th: Log Out Safely – Only log out in safe areas—dungeons are not safe.", icon = "Interface\\Icons\\inv_hearthstonebronze" },
    { text = "Final Lesson from The Rogue, Gavrial the 2nd: Escape Abilities Can Fail – Vanish, Feign Death, Frost Nova, Blind, and Gouge can be resisted—always have a backup plan.", icon = "Interface\\Icons\\ability_vanish" },
    { text = "Close Call from The Paladin, Gavrial the 6th: Don’t Risk the Jump – If it looks like you can barely make it, you probably can’t—unless you have fall mitigation abilities.", icon = "Interface\\Icons\\spell_magic_featherfall" },
    { text = "Close Call from The Hunter, Gavrial the 9th: Assume a High-Level Elite is Always Nearby – Even if you haven’t seen one, there’s probably a powerful roaming elite in your zone. Many players have met their end by assuming otherwise.", icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath" },
    { text = "Close Call from The Warlock, Gavrial the 8th: Your Pet Doesn’t Know How to Jump – If you’re playing a Hunter or Warlock, remember: pets take the long way down. It will always choose the death march, pulling half the zone in the process.", icon = "Interface\\Icons\\Ability_Hunter_BeastCall" },
    { text = "Lesson from The Hunter, Gavrial the 9th: Portals Before Risky Sections of Dungeons Can Be a Lifesaver – Mages dropping portals before dangerous fights can give your group an instant escape option when things go wrong.", icon = "Interface\\Icons\\Spell_Arcane_PortalStormwind" },
    { text = "Lesson from The Hunter, Gavrial the 9th: Buffs Can Be the Difference Between Life and Death – A well-timed food buff, potion, or world buff might seem minor, but at higher levels, every buff can save you from disaster.", icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings" },
}

------------------------------------------------------------------------------
-- Helper: Determine if a message is one of the Gavrials tips.
------------------------------------------------------------------------------
local function isGavrialsTip(msg)
    for _, tip in ipairs(GAVRIALS_TIPS) do
        if tip.text == msg then
            return true
        end
    end
    return false
end

------------------------------------------------------------------------------
-- Logging Setup
------------------------------------------------------------------------------
-- Create a table to hold all log messages for the session.
GavrialsCall.messageLog = {}

-- LogMessage now ignores messages that are Gavrials tips.
function GavrialsCall.LogMessage(msg)
    if isGavrialsTip(msg) then
        return
    end

    local timestamp = date("%H:%M:%S")  -- Get current time.
    local logEntry = string.format("[%s] %s", timestamp, msg)
    table.insert(GavrialsCall.messageLog, logEntry)
    
    -- Print the log entry to the default chat frame.
    -- DEFAULT_CHAT_FRAME:AddMessage(logEntry)

    -- Update the Event Log frame if it exists.
    if GavrialsCall.logFrame and GavrialsCall.logFrame.UpdateLog then
        GavrialsCall.logFrame:UpdateLog()
    end
end

------------------------------------------------------------------------------
-- Communication Functions
------------------------------------------------------------------------------
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
    if not success or type(data) ~= "table" then
        return
    end

    local now = GetTime()
    if now - lastAddonMessageTime < ADDON_MESSAGE_THROTTLE then
        return
    end
    lastAddonMessageTime = now

    if data.cmd then
        local handler = addonCommandHandlers[data.cmd]
        if handler then
            handler(sender, data.payload)
        else
            GavrialsCall:HandleEventMessage(data.cmd, sender)
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

function GavrialsCall:HandleEventMessageLegacy(message, sender)
    local eventName, messageText = strsplit(":", message, 2)
    if not eventName or not messageText then return end

    local iconPath = nil
    local color    = {1, 1, 1}

    if eventName == "Progress" then
        iconPath = "Interface\\Icons\\INV_Misc_Map01"
        color    = {1, 0.8, 0}
    elseif eventName == "LowHealth" then
        iconPath = "Interface\\Icons\\INV_Healthstone"
        color    = {1, 0, 0}
    elseif eventName == "LevelUp" then
        iconPath = "Interface\\Icons\\Spell_Holy_Heal"
        color    = {0, 1, 0}
    elseif eventName == "PlayerDeath" then
        iconPath = "Interface\\Icons\\Spell_Shadow_SoulLeech"
        color    = {0.5, 0, 0}
    elseif eventName == "EnteredInstance" then
        iconPath = "Interface\\Icons\\INV_Misc_Map02"
        color    = {0, 1, 0}
    elseif eventName == "LeftInstance" then
        iconPath = "Interface\\Icons\\INV_Misc_Map01"
        color    = {1, 1, 0}
    elseif eventName == "GuildDeath" then
        iconPath = "Interface\\Icons\\INV_Healthstone"
        color    = {1, 0, 0}
    elseif eventName == "GuildLevelUp" then
        iconPath = "Interface\\Icons\\INV_Scroll_01"
        color    = {0, 1, 0}
    elseif eventName == "GuildAchievement" then
        iconPath = "Interface\\Icons\\INV_Misc_Coin_03"
        color    = {1, 1, 0}
    elseif eventName == "GuildLowHealth" then
        iconPath = "Interface\\Icons\\INV_Healthstone"
        color    = {1, 0, 0}
    elseif eventName == "GuildEnteredInstance" then
        iconPath = "Interface\\Icons\\INV_Misc_Map02"
        color    = {0, 1, 0}
    elseif eventName == "MaxLevel" then
        iconPath = "Interface\\Icons\\INV_Misc_Rune_04"
        color    = {1, 0.84, 0}
    end

    GavrialsCall.DisplayMessage(sender, messageText, iconPath, color)
    GavrialsCall.PlayEventSound("Sound\\Interface\\RaidWarning.wav")
end

------------------------------------------------------------------------------
-- Helper: Strip realm from a full name
------------------------------------------------------------------------------
local function GetShortName(fullName)
    if fullName then
        local shortName = fullName:match("([^%-]+)")
        return shortName or fullName
    end
    return fullName
end

------------------------------------------------------------------------------
-- Helper: Check if a player is in your guild
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- Helper: Retrieve a player's class
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- Idle Tip Timer
------------------------------------------------------------------------------
local idleTipTimerHandle = nil

local function StartIdleTipTimer()
    if not MissionAccomplishedDB.enableGavrialsTips then return end
    if idleTipTimerHandle then return end
    local currentLast = GavrialsCall.lastMessageTime
    idleTipTimerHandle = C_Timer.NewTimer(60, function()
        idleTipTimerHandle = nil
        if MissionAccomplishedDB.enableGavrialsTips and (GetTime() - currentLast) >= 60 then
            GavrialsCall.DisplayRandomTip()
        end
    end)
end

function GavrialsCall.CancelIdleTipTimer()
    if idleTipTimerHandle then
        idleTipTimerHandle:Cancel()
        idleTipTimerHandle = nil
    end
end

function GavrialsCall.DisplayRandomTip()
    if not MissionAccomplishedDB.enableGavrialsTips then return end
    local tip = GAVRIALS_TIPS[math.random(#GAVRIALS_TIPS)]
    GavrialsCall.DisplayMessage("", tip.text, tip.icon, {1, 1, 1})
end

------------------------------------------------------------------------------
-- Communication: Send a robust addon message
------------------------------------------------------------------------------
function GavrialsCall:SendMessage(cmd, payload, channel)
    local data = {
        cmd = cmd,
        payload = payload
    }
    self:SendAddonMessageCompressed(data, channel)
end

------------------------------------------------------------------------------
-- Legacy SendAddonMessage
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- 1) Reset Health Notifications
------------------------------------------------------------------------------
function GavrialsCall.ResetHealthNotifications()
    for _, threshold in ipairs(GavrialsCall.healthThresholds) do
        GavrialsCall.healthThresholdsNotified[threshold] = false
    end
end

------------------------------------------------------------------------------
-- 2) Build the Notification Banner
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- 2.5) Tooltip for the Event Frame
------------------------------------------------------------------------------
function MissionAccomplished_Event_ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cff00ff00MissionAccomplished Notifications|r")
    GameTooltip:AddLine("Hold SHIFT and drag to reposition this frame.", 1, 1, 1)
    GameTooltip:AddLine("Click the icon in the top left corner to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

------------------------------------------------------------------------------
-- 3) Create the Main Event Frame (with Fade Animation)
------------------------------------------------------------------------------
function GavrialsCall.CreateFrame()
    if GavrialsCall.frame then
        return GavrialsCall.frame
    end
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

    frame:SetScript("OnEnter", function(self)
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
            GavrialsCall.DisplayMessage(nextMsg.playerName, nextMsg.text, nextMsg.icon, nextMsg.color)
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
    GavrialsCall.frame = frame
    return frame
end

------------------------------------------------------------------------------
-- 3.5) Helper: Play Sound for an Event
------------------------------------------------------------------------------
function GavrialsCall.PlayEventSound(soundFile)
    if MissionAccomplishedDB and MissionAccomplishedDB.eventSoundsEnabled == false then return end
    if soundFile then
        PlaySoundFile(soundFile, "Master")
    end
end

------------------------------------------------------------------------------
-- 4) DisplayMessage (with Logging)
------------------------------------------------------------------------------
function GavrialsCall.DisplayMessage(sender, text, iconPath, color, skipSender)
    if not GavrialsCall.frame then 
        GavrialsCall.CreateFrame() 
    end
    local frame = GavrialsCall.frame

    -- If a message is already playing, queue this one (including the skipSender flag)
    if frame:IsShown() and frame.InOut:IsPlaying() then
        if #QUEUE < MAX_QUEUE_SIZE then
            table.insert(QUEUE, {
                playerName = sender,
                text = text,
                icon = iconPath,
                color = color,
                skipSender = skipSender
            })
        end
        return
    end

    local baseFontSize = MAX_FONT_SIZE
    local textLength   = text and #text or 0
    if textLength > TEXT_LENGTH_THRESHOLD then
        local reduction = math.floor((textLength - TEXT_LENGTH_THRESHOLD) / 20)
        baseFontSize = math.max(MIN_FONT_SIZE, MAX_FONT_SIZE - reduction)
    end
    if sender == "" then
        baseFontSize = math.max(MIN_FONT_SIZE, baseFontSize - 2)
    end
    frame.messageText:SetFont("Fonts\\FRIZQT__.TTF", baseFontSize, "OUTLINE")

    local messageDuration = MIN_DISPLAY_TIME
    for _, mapping in ipairs(MessageDurationMapping) do
        if textLength <= mapping.maxLength then
            messageDuration = mapping.duration
            break
        end
    end
    if frame.animWait then 
        frame.animWait:SetDuration(messageDuration) 
    end

    -- Determine whether to prepend the sender's name.
    local currentPlayer = UnitName("player")
    local prefix = ""
    -- Only add the sender prefix if skipSender is not set and the sender is not the current player.
    if not skipSender and sender and sender ~= "" and sender ~= currentPlayer then
        prefix = GetShortName(sender) .. ", "
    end
    local msgFormatted = prefix .. (text or "")

    -- Log the message for session history (ignoring tip messages).
    GavrialsCall.LogMessage(msgFormatted)

    local now = GetTime()
    if GavrialsCall.lastMessage == msgFormatted and (now - GavrialsCall.lastMessageTime) < GavrialsCall.lastMessageCooldown then
        return
    end
    GavrialsCall.lastMessage = msgFormatted
    GavrialsCall.lastMessageTime = now

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

------------------------------------------------------------------------------
-- 5) Show / Hide Functions
------------------------------------------------------------------------------
function GavrialsCall.Show(persistent)
    if persistent then
        GavrialsCall.isPersistent = true
        if GavrialsCall.frame then
            GavrialsCall.frame.InOut:Stop()
            GavrialsCall.frame:SetAlpha(1)
            GavrialsCall.frame:Show()
        else
            GavrialsCall.CreateFrame()
            GavrialsCall.frame.InOut:Stop()
            GavrialsCall.frame:SetAlpha(1)
            GavrialsCall.frame:Show()
        end
    else
        GavrialsCall.isPersistent = false
        if GavrialsCall.frame then
            GavrialsCall.frame.InOut:Stop()
            GavrialsCall.frame:SetAlpha(0)
            GavrialsCall.frame:Show()
            GavrialsCall.frame.InOut:Play()
        else
            GavrialsCall.CreateFrame()
        end
    end
end

function GavrialsCall.Hide()
    if GavrialsCall.frame then
        GavrialsCall.isPersistent = false
        GavrialsCall.frame.InOut:Stop()
        UIFrameFadeOut(GavrialsCall.frame, FADE_OUT_TIME)
    end
end

------------------------------------------------------------------------------
-- Helper: Display Guild Online Message (Initial Count)
------------------------------------------------------------------------------
local function DisplayGuildOnlineMessage()
    GuildRoster()
    C_Timer.After(3, function()
        local numTotal = GetNumGuildMembers()
        local onlineCount = 0
        for i = 1, numTotal do
            local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
            if isOnline and name then
                onlineCount = onlineCount + 1
            end
        end
        if onlineCount > 0 then
            local eventData = EventsDictionary.allEvents.GA  -- Guild Amount event
            local formattedMessage = string.format(eventData.message, onlineCount)
            GavrialsCall.DisplayMessage(UnitName("player"), formattedMessage, eventData.icon, {0.2, 0.8, 1})
        end
    end)
end

------------------------------------------------------------------------------
-- 6) Show a “Welcome Back” Message Once using EventsDictionary
------------------------------------------------------------------------------
local function DisplayWelcomeTextOnce()
    if welcomeShown then return end
    welcomeShown = true

    local playerName  = UnitName("player") or "Player"
    local playerLevel = UnitLevel("player") or 1

    if playerLevel >= 60 then
        local eventData = EventsDictionary.allEvents.Welcome60
        local formattedMessage = string.format(eventData.message, playerName)
        GavrialsCall.DisplayMessage("", formattedMessage, eventData.icon, {1, 1, 1})
        GavrialsCall.PlayEventSound(eventData.sound)
    else
        local xpSoFar = MissionAccomplished.GetTotalXPSoFar() or 0
        local xpMax   = MissionAccomplished.GetXPMaxTo60() or 1
        local remain  = xpMax - xpSoFar
        if remain < 0 then remain = 0 end
        local pct = (xpSoFar / xpMax) * 100
        local eventData = EventsDictionary.allEvents.Welcome
        local formattedMessage = string.format(eventData.message, playerName, pct, remain)
        GavrialsCall.DisplayMessage("", formattedMessage, eventData.icon, {1, 1, 1})
        GavrialsCall.PlayEventSound(eventData.sound)
    end

    if GetGuildInfo("player") then
        C_Timer.After(4, DisplayGuildOnlineMessage)
    end
end

------------------------------------------------------------------------------
-- 7) Handle Event Message (fallback)
------------------------------------------------------------------------------
function GavrialsCall.HandleEventMessage(message, sender)
    GavrialsCall:HandleEventMessageLegacy(message, sender)
end

------------------------------------------------------------------------------
-- 8) Handle Character Events (Local or Guild) using EventsDictionary
------------------------------------------------------------------------------
function GavrialsCall.HandleCharacterEvent(event, ...)
    local pName = UnitName("player") or "Player"

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        if newLevel == 60 then
            local eventData = EventsDictionary.allEvents.ML
            local formattedMessage = string.format(eventData.message, pName)
            local guildName = GetGuildInfo("player")
            if guildName then
                GavrialsCall:SendMessage("ML", formattedMessage, "GUILD")
            else
                GavrialsCall.DisplayMessage(pName, formattedMessage, eventData.icon, {1, 1, 1})
            end
            GavrialsCall.PlayEventSound(eventData.sound)
        else
            local eventData = EventsDictionary.allEvents.LU
            local formattedMessage = string.format(eventData.message, pName, newLevel)
            local guildName = GetGuildInfo("player")
            if guildName then
                GavrialsCall:SendMessage("LU", formattedMessage, "GUILD")
            else
                GavrialsCall.DisplayMessage(pName, formattedMessage, eventData.icon, {0, 1, 0})
            end
            GavrialsCall.PlayEventSound(eventData.sound)
        end

    elseif event == "UNIT_HEALTH" then
        local unit = ...
        if unit == "player" then
            local health = UnitHealth("player")
            local maxHealth = UnitHealthMax("player")
            local pct = (health / maxHealth) * 100
            for _, threshold in ipairs(GavrialsCall.healthThresholds) do
                if pct <= threshold and not GavrialsCall.healthThresholdsNotified[threshold] then
                    local eventData = EventsDictionary.allEvents.LH
                    local formattedMessage = string.format(eventData.message, pName, math.floor(pct))
                    GavrialsCall.DisplayMessage(pName, formattedMessage, eventData.icon, {1, 0, 0})
                    GavrialsCall.PlayEventSound(eventData.sound)
                    GavrialsCall.healthThresholdsNotified[threshold] = true
                end
            end
            local allNotified = true
            for _, thr in ipairs(GavrialsCall.healthThresholds) do
                if pct > thr then
                    allNotified = false
                    break
                end
            end
            if allNotified then
                GavrialsCall.ResetHealthNotifications()
            end
        end

    elseif event == "PLAYER_DEAD" then
        local guildName = GetGuildInfo("player")
        if guildName then
            local eventData = EventsDictionary.allEvents.GD
            local formattedMessage = string.format(eventData.message, pName)
            GavrialsCall:SendMessage("GD", formattedMessage, "GUILD")
            GavrialsCall.PlayEventSound(eventData.sound)
        else
            local eventData = EventsDictionary.allEvents.PlayerDeath
            local formattedMessage = string.format(eventData.message, pName)
            GavrialsCall.DisplayMessage(pName, formattedMessage, eventData.icon, {0.5, 0, 0})
            GavrialsCall.PlayEventSound(eventData.sound)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Do nothing; instance entry is handled elsewhere.
    
    elseif event == "UPDATE_EXHAUSTION" then
        local guildName = GetGuildInfo("player")
        local xpPct = MissionAccomplished.GetProgressPercentage() or 0
        local rounded = math.floor(xpPct + 0.5)
        local eventData = EventsDictionary.allEvents.PR
        local formattedMessage = string.format(eventData.message, pName, rounded)
        if guildName then
            GavrialsCall:SendMessage("PR", formattedMessage, "GUILD")
        else
            GavrialsCall.DisplayMessage(pName, formattedMessage, eventData.icon, {0.7, 0.7, 1})
        end
        GavrialsCall.PlayEventSound(eventData.sound)

    elseif event == "UNIT_AURA" then
        -- your existing code for buffs
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        -- your existing code for big hits / group deaths
    elseif event == "GUILD_ROSTER_UPDATE" then
        -- your existing code for guild members coming online
    elseif event == "CHAT_MSG_SYSTEM" then
        local sysMsg = select(1, ...)
        GavrialsCall.HandleSystemMessage(sysMsg)
    end
end

------------------------------------------------------------------------------
-- New: Handle System Message for level 60 using local fallback info 
------------------------------------------------------------------------------
function GavrialsCall.HandleSystemMessage(message, ...)
    -- Look for a message like "PlayerName has reached level 60!"
    local name = message:match("^(%S+) has reached level 60!$")
    if name then
        local playerClass, guildName
        if IsPlayerInGuild(name) then
            -- If the player is in your guild, retrieve their class info and guild name.
            playerClass = GetPlayerClass(name)
            guildName = GetGuildInfo("player") or "No Guild"
        else
            -- If not in your guild, default to "Adventurer" and "Azeroth."
            playerClass = "Adventurer"
            guildName = "Azeroth"
        end

        -- Retrieve the EP event data from the centralized dictionary.
        local eventData = EventsDictionary.allEvents.EP
        if not eventData then
            print("Warning: Missing EP event data in EventsDictionary.allEvents.")
            return  -- Optionally, exit the function to avoid an error.
        end

        local formattedMessage = string.format(eventData.message, name, playerClass, guildName)
        GavrialsCall.DisplayMessage("", formattedMessage, eventData.icon, {1, 0.84, 0})
        GavrialsCall.PlayEventSound(eventData.sound)
    end
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
-- Modular Command Handlers
------------------------------------------------------------------------------
local addonCommandHandlers = {
    EnableEventFrame = function(sender, payload)
        GavrialsCall.Show(false)
    end,
    DisableEventFrame = function(sender, payload)
        GavrialsCall.Hide()
    end,
    AddonPing = function(sender, payload)
        local playerName = UnitName("player") or "Player"
        local race       = UnitRace("player") or "Unknown"
        local class      = select(1, UnitClass("player")) or "Unknown"
        local level      = UnitLevel("player") or 1
        local progress   = MissionAccomplished.GetProgressPercentage() or 0
        local replyPayload = string.format(
            "%s;%s;%s;%d;%.1f;%s", playerName, race, class, level, progress, ADDON_VERSION
        )
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
            table.insert(_G.MissionAccomplished_GuildAddonMembers, {
                name = name, race = race, class = class, level = level, progress = progress, version = version
            })
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
            table.insert(_G.MissionAccomplished_GuildAddonMembers, {
                name = sender, professions = payload.professions
            })
        end
    end,
    INTER_ADDON = function(sender, payload)
        if payload.professions then
            addonCommandHandlers["ProfessionData"](sender, payload)
        end
        -- Process other inter-addon messages as needed.
    end,
}

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
        GavrialsCall.HandleCharacterEvent(ev, ...)
        TriggerCallbacks(ev, ...)
    end)
end

------------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------------
function GavrialsCall.Init()
    GavrialsCall.CreateFrame()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(PREFIX) then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end
    GavrialsCall.eventFrame = CreateFrame("Frame")
    RegisterEvents(GavrialsCall.eventFrame)
    GavrialsCall.ResetHealthNotifications()
    GuildRoster()
    DisplayWelcomeTextOnce()

    if MissionAccomplishedDB and MissionAccomplishedDB.eventFrameEnabled then
        GavrialsCall.Show(false)
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
            GavrialsCall.Init()
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, distribution, sender = ...
        if prefix ~= PREFIX then return end
        GavrialsCall:OnAddonMessage(prefix, message, distribution, sender)
    end
end)

-- END of GavrialsCall.lua
