--=============================================================================
-- GavrialsCall.lua
--=============================================================================
-- Basic configuration variables for frame settings
local FRAME_WIDTH    = 400
local FRAME_HEIGHT   = 60
local FRAME_STYLE    = "Organic"   -- Change this value to use different frame styles.
local FADE_IN_TIME   = 0.5
local FADE_OUT_TIME  = 1.0
local MAX_QUEUE_SIZE = 10
local PREFIX         = "MissionAcc"

-- New configuration for dynamic font sizing.
local MAX_FONT_SIZE = 14
local MIN_FONT_SIZE = 10
local TEXT_LENGTH_THRESHOLD = 50  -- messages longer than this will have a reduced font size

-- New configuration for dynamic display duration (in seconds).
local MIN_DISPLAY_TIME = 5
local MessageDurationMapping = {
    { maxLength = 50,  duration = 7 },
    { maxLength = 100, duration = 10 },
    { maxLength = 150, duration = 12 },
    { maxLength = math.huge, duration = 15 },
}

-- Default display time variable (will be overridden dynamically)
local DISPLAY_TIME = 7

-- Message queue and related variables
local QUEUE = {}  -- table to hold pending messages

-- Ensure our addon tables exist
MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.GavrialsCall = MissionAccomplished.GavrialsCall or {}
local GavrialsCall = MissionAccomplished.GavrialsCall

-- Communication version and throttle
local ADDON_VERSION = "1.1"
local ADDON_MESSAGE_THROTTLE = 1  -- seconds between allowed messages
local lastAddonMessageTime = 0

-- Import libraries for serialization/compression
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
-- (Optionally, you can integrate ChatThrottleLib if desired.)

-- Basic state
GavrialsCall.isPersistent             = false
GavrialsCall.healthThresholds         = {75, 50, 25, 10}
GavrialsCall.healthThresholdsNotified = {}
GavrialsCall.previousInstanceName     = nil
GavrialsCall.lastMessage              = nil
GavrialsCall.lastMessageTime          = 0
GavrialsCall.lastMessageCooldown      = 60

local welcomeShown = false -- ensures the welcome message is shown only once

-- Table to track previously online guild members for roster updates.
local prevGuildOnline = {}  -- initially empty

------------------------------------------------------------------------------
-- Communication Functions
------------------------------------------------------------------------------
-- SendAddonMessageCompressed
-- This function takes a table (with fields "cmd" and "payload") and sends it
-- using the registered PREFIX after serializing and compressing.
function GavrialsCall:SendAddonMessageCompressed(data, channel)
    if type(data) ~= "table" then
        error("SendAddonMessageCompressed expects a table", 2)
    end
    -- Add version info if needed
    data.version = ADDON_VERSION
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    -- Send the encoded message using Blizzard's API
    C_ChatInfo.SendAddonMessage(PREFIX, encoded, channel)
end

-- OnAddonMessage: Called when an addon message is received.
-- It decodes, decompresses, and deserializes the message.
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

    -- Throttle messages
    local now = GetTime()
    if now - lastAddonMessageTime < ADDON_MESSAGE_THROTTLE then
        return
    end
    lastAddonMessageTime = now

    -- If the message has a command, route to the handler
    if data.cmd then
        local handler = addonCommandHandlers[data.cmd]
        if handler then
            handler(sender, data.payload)
        else
            -- Fallback: treat data.cmd as an event and handle it like legacy messages.
            GavrialsCall:HandleEventMessage(data.cmd, sender)
        end
    end
end

------------------------------------------------------------------------------
-- Legacy SendAddonMessage (for non‐serialized commands)
-- (Kept for backward compatibility; new messages should use SendAddonMessageCompressed.)
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
-- Legacy Handler: If a message isn’t serialized, fall back to legacy handling.
function GavrialsCall:HandleEventMessageLegacy(message, sender)
    local eventName, messageText = strsplit(":", message, 2)
    if not eventName or not messageText then return end
    local iconPath = nil
    local color    = {1, 1, 1}
    if eventName == "Progress" then
        local xpPct = MissionAccomplished.GetProgressPercentage()
        local formattedPct = string.format("%.1f", xpPct)
        messageText = "you are " .. formattedPct .. "% done with the EXP left until completion"
        iconPath    = "Interface\\Icons\\INV_Misc_Map01"
        color       = {1, 0.8, 0}
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
    GavrialsCall.PlayEventSound(eventName)
end

------------------------------------------------------------------------------
-- Helper: Strip realm from a full name (e.g. "Player-Realm" -> "Player")
------------------------------------------------------------------------------  
local function GetShortName(fullName)
    if fullName then
        local shortName = fullName:match("([^%-]+)")
        return shortName or fullName
    end
    return fullName
end

------------------------------------------------------------------------------
-- Helper: Check if a player is in your guild (using short names)
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
-- Helper: Retrieve a player's class from stored guild addon data (if available)
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
-- Define the Gavrials Tips table (each tip has text and an associated icon)
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
-- Idle Tip Timer Management
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

------------------------------------------------------------------------------
-- Helper: Display a Random Gavrials Tip (if tips are enabled)
------------------------------------------------------------------------------
function GavrialsCall.DisplayRandomTip()
    if not MissionAccomplishedDB.enableGavrialsTips then return end
    local tip = GAVRIALS_TIPS[math.random(#GAVRIALS_TIPS)]
    GavrialsCall.DisplayMessage("", tip.text, tip.icon, {1, 1, 1})
end

------------------------------------------------------------------------------
-- Communication: Send a robust addon message.
-- This function now sends a serialized/compressed table with a "cmd" and "payload".
------------------------------------------------------------------------------
function GavrialsCall:SendMessage(cmd, payload, channel)
    local data = {
        cmd = cmd,
        payload = payload
    }
    self:SendAddonMessageCompressed(data, channel)
end

------------------------------------------------------------------------------
-- Legacy SendAddonMessage remains (for non‑serialized commands)
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
-- Communication: SendAddonMessageCompressed (see above)
------------------------------------------------------------------------------
function GavrialsCall:SendAddonMessageCompressed(data, channel)
    if type(data) ~= "table" then
        error("SendAddonMessageCompressed expects a table parameter", 2)
    end
    data.version = ADDON_VERSION
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    C_ChatInfo.SendAddonMessage(PREFIX, encoded, channel)
end

------------------------------------------------------------------------------
-- Communication: OnAddonMessage – process incoming addon messages.
------------------------------------------------------------------------------
function GavrialsCall:OnAddonMessage(prefix, message, distribution, sender)
    if prefix ~= PREFIX then return end

    local decoded = LibDeflate:DecodeForPrint(message)
    if not decoded then return end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end

    local success, data = LibSerialize:Deserialize(decompressed)
    if not success or type(data) ~= "table" then return end

    -- Throttle
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
            -- Fallback to legacy event handling if unknown command.
            GavrialsCall:HandleEventMessageLegacy(data.cmd, sender)
        end
    end
end

------------------------------------------------------------------------------
-- Helpers for local/guild/global/inter-addon communication.
------------------------------------------------------------------------------
function GavrialsCall:PullLocalData()
    local localData = {
        info = "Local data sample",
        timestamp = GetTime()
    }
    self:SendMessage("LOCAL_INFO", localData, "PARTY")
end

function GavrialsCall:PullGuildData()
    local guildData = {
        info = "Guild data sample",
        timestamp = GetTime()
    }
    self:SendMessage("GUILD_INFO", guildData, "GUILD")
end

function GavrialsCall:PullGlobalData()
    local globalData = {
        info = "Global data sample",
        timestamp = GetTime()
    }
    self:SendMessage("GLOBAL_INFO", globalData, "RAID")
end

function GavrialsCall:SendInterAddonMessage(customData)
    customData = customData or {}
    self:SendMessage("INTER_ADDON", customData, "GUILD")
end

------------------------------------------------------------------------------
-- New Functions for Guild Profession Data (added)
------------------------------------------------------------------------------
function GavrialsCall:GetPlayerProfessionsClassic()
    local prof1, prof2, fishing, cooking = GetProfessions()
    local profData = {}

    if prof1 then
        local name, icon, skillLevel, maxLevel = GetProfessionInfo(prof1)
        if name then
            profData[name] = { level = skillLevel, max = maxLevel }
        end
    end
    if prof2 then
        local name, icon, skillLevel, maxLevel = GetProfessionInfo(prof2)
        if name then
            profData[name] = { level = skillLevel, max = maxLevel }
        end
    end
    if fishing then
        local name, icon, skillLevel, maxLevel = GetProfessionInfo(fishing)
        if name then
            profData[name] = { level = skillLevel, max = maxLevel }
        end
    end
    if cooking then
        local name, icon, skillLevel, maxLevel = GetProfessionInfo(cooking)
        if name then
            profData[name] = { level = skillLevel, max = maxLevel }
        end
    end

    return profData
end

function GavrialsCall:SendProfessionDataClassic()
    local professions = self:GetPlayerProfessionsClassic()
    local payload = { professions = professions }
    self:SendMessage("ProfessionData", payload, "GUILD")
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
-- 2) Build the Notification Banner with a Semi-Transparent Background
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
    staticIconFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            MissionAccomplished_ToggleSettings()
        end
    end)
    frame.staticIconFrame = staticIconFrame
    frame.staticIcon = staticIcon
    local eventIconSize = 36
    local eventIconFrame = CreateFrame("Frame", nil, frame)
    eventIconFrame:SetSize(eventIconSize, eventIconSize)
    eventIconFrame:SetPoint("LEFT", frame, "LEFT", 20, 0)
    local eventIcon = eventIconFrame:CreateTexture(nil, "ARTWORK")
    eventIcon:SetAllPoints(true)
    eventIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.eventIconFrame = eventIconFrame
    frame.eventIcon = eventIcon
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
-- 2.5) Tooltip for the Event Frame (Updated)
------------------------------------------------------------------------------
function MissionAccomplished_Event_ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cff00ff00MissionAccomplished Notifications|r")
    GameTooltip:AddLine("Hold SHIFT and drag to reposition this frame.", 1, 1, 1)
    GameTooltip:AddLine("Click the icon in the top left corner to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

------------------------------------------------------------------------------
-- 3) Create the Main Event Frame (with Fade Animation and Message Queue)
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
-- 3.5) Helper: Play Sound for an Event (with event-sounds toggle)
------------------------------------------------------------------------------
function GavrialsCall.PlayEventSound(eventKey)
    if MissionAccomplishedDB and MissionAccomplishedDB.eventSoundsEnabled == false then return end
    local soundMap = {
        Progress             = "Sound\\Interface\\RaidWarning.wav",
        LowHealth            = "Sound\\Spells\\PVPFlagTaken.wav",
        LevelUp              = "Sound\\Interface\\LevelUp.wav",
        MaxLevel             = "Sound\\Interface\\Achievement.wav",
        PlayerDeath          = "Sound\\Creature\\CaveBear\\CaveBearDeath.wav",
        EnteredInstance      = "Sound\\Interface\\RaidWarning.wav",
        LeftInstance         = "Sound\\Interface\\RaidWarning.wav",
        GuildDeath           = "Sound\\Spells\\PVPFlagTaken.wav",
        GuildLevelUp         = "Sound\\Interface\\LevelUp.wav",
        GuildAchievement     = "Sound\\Interface\\RaidWarning.wav",
        GuildLowHealth       = "Sound\\Spells\\PVPFlagTaken.wav",
        GuildEnteredInstance = "Sound\\Interface\\RaidWarning.wav",
        Welcome              = "Sound\\Interface\\LevelUp.wav",
        GuildMemberOnline    = "Sound\\Interface\\RaidWarning.wav",
    }
    local soundFile = soundMap[eventKey]
    if soundFile then
        PlaySoundFile(soundFile, "Master")
    end
end

------------------------------------------------------------------------------
-- 4) DisplayMessage (Formats messages as if spoken by a person)
------------------------------------------------------------------------------
function GavrialsCall.DisplayMessage(sender, text, iconPath, color)
    if not GavrialsCall.frame then GavrialsCall.CreateFrame() end
    local frame = GavrialsCall.frame

    if frame:IsShown() and frame.InOut:IsPlaying() then
        if #QUEUE < MAX_QUEUE_SIZE then
            table.insert(QUEUE, { playerName = sender, text = text, icon = iconPath, color = color })
        end
        return
    end

    local baseFontSize = MAX_FONT_SIZE
    local textLength = text and #text or 0
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
    if frame.animWait then frame.animWait:SetDuration(messageDuration) end

    local prefix = ""
    if sender and sender ~= "" then prefix = GetShortName(sender) .. ", " end
    local msgFormatted = prefix .. (text or "")
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
            local msg = onlineCount .. " guild members are currently online."
            GavrialsCall.DisplayMessage(UnitName("player"), msg, "Interface\\Icons\\INV_Misc_GroupLooking", {0.2, 0.8, 1})
        end
    end)
end

------------------------------------------------------------------------------
-- 6) Show a “Welcome Back” Message Once (Displayed on login)
------------------------------------------------------------------------------
local function DisplayWelcomeTextOnce()
    if welcomeShown then return end
    welcomeShown = true
    local playerName = UnitName("player") or "Player"
    local playerLevel = UnitLevel("player") or 1
    if playerLevel >= 60 then
        local msg = string.format("Welcome back, %s! You've reached level 60! Embrace your legacy!", playerName)
        GavrialsCall.DisplayMessage("", msg, "Interface\\Icons\\Achievement_Level_60", {1, 1, 1})
    else
        local xpSoFar = MissionAccomplished.GetTotalXPSoFar() or 0
        local xpMax   = MissionAccomplished.GetXPMaxTo60() or 1
        local remain  = xpMax - xpSoFar
        if remain < 0 then remain = 0 end
        local pct = (xpSoFar / xpMax) * 100
        local msg = string.format("Welcome back, %s! You are currently %.1f%% done with %d EXP remaining. Keep grinding!", playerName, pct, remain)
        GavrialsCall.DisplayMessage(playerName, msg, "Interface\\Icons\\INV_Misc_Map01", {1, 1, 1})
    end
    GavrialsCall.PlayEventSound("Welcome")
    if GetGuildInfo("player") then
        C_Timer.After(4, DisplayGuildOnlineMessage)
    end
end

------------------------------------------------------------------------------
-- 7) Handle Event Message from Addon Communication
------------------------------------------------------------------------------
function GavrialsCall.HandleEventMessage(message, sender)
    -- This function is used as a fallback when a received message does not use
    -- our new serialized format.
    GavrialsCall:HandleEventMessageLegacy(message, sender)
end

------------------------------------------------------------------------------
-- 8) Handle Character Events (Local Notifications)
------------------------------------------------------------------------------
function GavrialsCall.HandleCharacterEvent(event, ...)
    local pName = UnitName("player") or "Player"
    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        if newLevel == 60 then
            local guildName = GetGuildInfo("player")
            if guildName then
                local specialMsg = string.format("Congratulations, you have reached level 60 – the pinnacle of achievement! (%s from your guild)", guildName)
                GavrialsCall.DisplayMessage(pName, specialMsg, "Interface\\Icons\\INV_Misc_Rune_04", {1, 0.84, 0})
            else
                local className = select(2, UnitClass("player")) or "Unknown"
                local specialMsg = string.format("%s the %s has reached level 60! (Not in your Guild)", pName, className)
                GavrialsCall.DisplayMessage(pName, specialMsg, "Interface\\Icons\\INV_Misc_Rune_04", {1, 0.84, 0})
            end
            GavrialsCall.PlayEventSound("MaxLevel")
            GavrialsCall:SendMessage("MaxLevel", pName .. " has reached level 60 – the pinnacle of achievement! Your legend now begins!", "GUILD")
        else
            GavrialsCall.DisplayMessage(pName, "you have reached level " .. newLevel .. "! Congrats!", "Interface\\Icons\\Spell_Holy_Heal", {0, 1, 0})
            GavrialsCall.PlayEventSound("LevelUp")
        end
    elseif event == "UNIT_HEALTH" then
        local unit = ...
        if unit == "player" then
            local health    = UnitHealth("player")
            local maxHealth = UnitHealthMax("player")
            local pct       = (health / maxHealth) * 100
            for _, threshold in ipairs(GavrialsCall.healthThresholds) do
                if pct <= threshold and not GavrialsCall.healthThresholdsNotified[threshold] then
                    local msg, iconPath, col
                    if threshold > 10 then
                        msg      = "you are below " .. threshold .. "% health. Be careful!"
                        iconPath = "Interface\\Icons\\ability_warlock_fireandbrimstone"
                        col      = {1, 0, 0}
                    else
                        msg      = "you are critically low (" .. math.floor(pct) .. "% health)! Help!"
                        iconPath = "Interface\\Icons\\ability_warlock_fireandbrimstone"
                        col      = {1, 0, 0}
                        local guildMsg = pName .. " is at 10% HP! Send help!"
                        GavrialsCall:SendMessage("GuildLowHealth", guildMsg, "GUILD")
                    end
                    GavrialsCall.DisplayMessage(pName, msg, iconPath, col)
                    GavrialsCall.PlayEventSound("LowHealth")
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
        GavrialsCall.DisplayMessage(pName, "you have been defeated!", "Interface\\Icons\\Spell_Shadow_SoulLeech", {0.5, 0, 0})
        GavrialsCall.PlayEventSound("PlayerDeath")
    elseif event == "PLAYER_ENTERING_WORLD" then
        local inInstance, instanceType = IsInInstance()
        local instanceName = GetInstanceInfo()
        if inInstance and (instanceType == "party" or instanceType == "raid") then
            if not GavrialsCall.previousInstanceName then
                GavrialsCall.DisplayMessage(pName, "you are entering " .. instanceName .. ", good luck!", "Interface\\Icons\\INV_Misc_Map02", {0, 1, 0})
                local guildMsg = pName .. " from your guild is entering " .. instanceName .. ", good luck!"
                GavrialsCall:SendMessage("GuildEnteredInstance", guildMsg, "GUILD")
                GavrialsCall.PlayEventSound("EnteredInstance")
            end
            GavrialsCall.previousInstanceName = instanceName
        else
            if GavrialsCall.previousInstanceName then
                GavrialsCall.DisplayMessage(pName, "you have left " .. GavrialsCall.previousInstanceName .. ".", "Interface\\Icons\\INV_Misc_Map01", {1, 1, 0})
                GavrialsCall.PlayEventSound("LeftInstance")
                GavrialsCall.previousInstanceName = nil
            end
        end
    elseif event == "UPDATE_EXHAUSTION" then
        local restXP = GetXPExhaustion()
        if not restXP then
            GavrialsCall.DisplayMessage(pName, "you have no Rested XP left.", "Interface\\Icons\\Spell_Nature_Sleep", {0.7, 0.7, 1})
        else
            GavrialsCall.DisplayMessage(pName, "you have Rested XP. Keep leveling!", "Interface\\Icons\\Spell_Nature_Sleep", {0.7, 0.7, 1})
        end
        GavrialsCall.PlayEventSound("Progress")
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            local i = 1
            while true do
                local name, icon, count, debuffType, duration, expirationTime = UnitBuff("player", i)
                if not name then break end
                if name == "Rallying Cry of the Dragonslayer" and duration and expirationTime then
                    local timeLeft = expirationTime - GetTime()
                    if timeLeft < 60 then
                        GavrialsCall.DisplayMessage(pName, "you have only " .. math.floor(timeLeft) .. " seconds left on Rallying Cry!", icon, {1, 0.5, 0})
                    end
                end
                i = i + 1
            end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timeStamp, subEvent, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName, _, amount = CombatLogGetCurrentEventInfo()
        if (subEvent == "SWING_DAMAGE" or subEvent == "RANGE_DAMAGE" or subEvent:find("_DAMAGE")) then
            if destName == pName then
                local maxHP = UnitHealthMax("player")
                if amount and maxHP and amount > 0.5 * maxHP then
                    GavrialsCall.DisplayMessage(pName, "you took a massive hit of " .. amount .. " damage!", "Interface\\Icons\\Ability_Warrior_BloodFrenzy", {1, 0.2, 0.2})
                    GavrialsCall.PlayEventSound("LowHealth")
                end
            end
        end
        if subEvent == "UNIT_DIED" then
            if UnitInParty(destName) or UnitInRaid(destName) then
                GavrialsCall.DisplayMessage(destName or "A group member", "has been defeated in your group!", "Interface\\Icons\\INV_Healthstone", {1, 0, 0})
                GavrialsCall.PlayEventSound("GuildDeath")
            end
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        local numTotal = GetNumGuildMembers()
        local currentOnline = {}
        local onlineCount = 0
        for i = 1, numTotal do
            local fullName, _, _, level, classDisplayName, zone, note, officerNote, isOnline, status, classFileName = GetGuildRosterInfo(i)
            if isOnline and fullName then
                local shortName = GetShortName(fullName)
                onlineCount = onlineCount + 1
                currentOnline[shortName] = {
                    classFileName = classFileName,
                    classDisplayName = classDisplayName,
                }
            end
        end
        if next(prevGuildOnline) then
            local classIcons = {
                WARRIOR     = "Interface\\Icons\\ClassIcon_Warrior",
                PALADIN     = "Interface\\Icons\\ClassIcon_Paladin",
                HUNTER      = "Interface\\Icons\\ClassIcon_Hunter",
                ROGUE       = "Interface\\Icons\\ClassIcon_Rogue",
                PRIEST      = "Interface\\Icons\\ClassIcon_Priest",
                DEATHKNIGHT = "Interface\\Icons\\ClassIcon_DeathKnight",
                SHAMAN      = "Interface\\Icons\\ClassIcon_Shaman",
                MAGE        = "Interface\\Icons\\ClassIcon_Mage",
                WARLOCK     = "Interface\\Icons\\ClassIcon_Warlock",
                DRUID       = "Interface\\Icons\\ClassIcon_Druid",
            }
            for shortName, info in pairs(currentOnline) do
                if not prevGuildOnline[shortName] then
                    local iconPath = (info.classFileName and classIcons[info.classFileName]) or "Interface\\Icons\\INV_Misc_QuestionMark"
                    local msg = shortName .. " the " .. (info.classDisplayName or "Unknown") .. " is now online!"
                    GavrialsCall.DisplayMessage("", msg, iconPath, {0.2, 0.8, 1})
                    GavrialsCall.PlayEventSound("GuildMemberOnline")
                end
            end
        end
        prevGuildOnline = currentOnline
    elseif event == "CHAT_MSG_SYSTEM" then
        local sysMsg = select(1, ...)
        GavrialsCall.HandleSystemMessage(sysMsg)
    end
end

------------------------------------------------------------------------------
-- New: Handle CHAT_MSG_SYSTEM for level 60 messages
------------------------------------------------------------------------------
function GavrialsCall.HandleSystemMessage(message, ...)
    local name = message:match("^(%S+) has reached level 60!$")
    if name and not IsPlayerInGuild(name) then
        local class = GetPlayerClass(name)
        local customMsg = string.format("%s the %s has reached level 60! (Not in your Guild)", name, class)
        GavrialsCall.DisplayMessage("", customMsg, "Interface\\Icons\\Achievement_Level_60", {1, 0.84, 0})
    end
end

------------------------------------------------------------------------------
-- Global Definitions & API Exposure for Callbacks
------------------------------------------------------------------------------
MissionAccomplished = MissionAccomplished or {}
MissionAccomplished._callbacks = MissionAccomplished._callbacks or {}
function MissionAccomplished.RegisterCallback(event, callback)
    MissionAccomplished._callbacks[event] = MissionAccomplished._callbacks[event] or {}
    table.insert(MissionAccomplished._callbacks[event], callback)
end

local function TriggerCallbacks(event, ...)
    if MissionAccomplished._callbacks[event] then
        for _, callback in ipairs(MissionAccomplished._callbacks[event]) do
            pcall(callback, event, ...)
        end
    end
end

------------------------------------------------------------------------------
-- Modular Command Handlers for Addon Messages
------------------------------------------------------------------------------
local addonCommandHandlers = {
    EnableEventFrame = function(sender, payload)
        GavrialsCall.Show(false)
    end,
    DisableEventFrame = function(sender, payload)
        GavrialsCall.Hide()
    end,
    AddonPing = function(sender, payload)
        local playerName = UnitName("player")
        local race = UnitRace("player") or "Unknown"
        local class = select(1, UnitClass("player")) or "Unknown"
        local level = UnitLevel("player") or 1
        local progress = MissionAccomplished.GetProgressPercentage() or 0
        local replyPayload = string.format("%s;%s;%s;%d;%.1f;%s", playerName, race, class, level, progress, ADDON_VERSION)
        GavrialsCall:SendMessage("AddonReply", replyPayload, "GUILD")
    end,
    AddonReply = function(sender, payload)
        local name, race, class, level, progress, version = strsplit(";", payload)
        level = tonumber(level) or 1
        progress = tonumber(progress) or 0
        _G.MissionAccomplished_GuildAddonMembers = _G.MissionAccomplished_GuildAddonMembers or {}
        local updated = false
        for i, v in ipairs(_G.MissionAccomplished_GuildAddonMembers) do
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
        local selfName = UnitName("player")
        if GetShortName(name):lower() == GetShortName(selfName):lower() then
            for i, v in ipairs(_G.MissionAccomplished_GuildAddonMembers) do
                if GetShortName(v.name):lower() == GetShortName(selfName):lower() then
                    v.progress = progress
                    break
                end
            end
        end
    end,
    ProfessionData = function(sender, payload)
        _G.MissionAccomplished_GuildAddonMembers = _G.MissionAccomplished_GuildAddonMembers or {}
        local updated = false
        for i, v in ipairs(_G.MissionAccomplished_GuildAddonMembers) do
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
    frame:SetScript("OnEvent", function(_, event, ...)
        GavrialsCall.HandleCharacterEvent(event, ...)
        TriggerCallbacks(event, ...)
    end)
end

------------------------------------------------------------------------------
-- Updated Initialization Function
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
-- ADDON_LOADED / CHAT_MSG_ADDON Handling
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
        -- First try our new robust communication handler:
        GavrialsCall:OnAddonMessage(prefix, message, distribution, sender)
    end
end)
