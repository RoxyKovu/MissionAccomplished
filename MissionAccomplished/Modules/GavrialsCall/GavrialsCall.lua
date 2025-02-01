--=============================================================================
-- GavrialsCall.lua
--=============================================================================
-- Single animation: fade in -> 5s wait -> fade out.
-- All messages are phrased as if a person is speaking to you.
-- The event box has a semi-transparent background and improved styling.
-- Guild broadcasts occur for level 60, instance entry, and critical health events.
-- A message queue is implemented so that incoming messages are queued and
-- displayed sequentially.
--=============================================================================

MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.GavrialsCall = MissionAccomplished.GavrialsCall or {}
local GavrialsCall = MissionAccomplished.GavrialsCall

-- Basic configuration
local FRAME_WIDTH    = 400
local FRAME_HEIGHT   = 50
local FADE_IN_TIME   = 0.5
local DISPLAY_TIME   = 5.0
local FADE_OUT_TIME  = 1.0
local MAX_QUEUE_SIZE = 10
local PREFIX         = "MissionAcc"

-- Message queue and related variables
local QUEUE = {}  -- table to hold pending messages

GavrialsCall.isPersistent             = false
GavrialsCall.healthThresholds         = {75, 50, 25, 10}
GavrialsCall.healthThresholdsNotified = {}
GavrialsCall.previousInstanceName     = nil
GavrialsCall.lastMessage              = nil
GavrialsCall.lastMessageTime          = 0
GavrialsCall.lastMessageCooldown      = 30

local welcomeShown = false -- ensures the welcome message is shown only once

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

    -- Create a static gavicon (always in the upper left corner)
    local staticIconSize = 40
    local staticIconFrame = CreateFrame("Frame", nil, frame)
    staticIconFrame:SetSize(staticIconSize, staticIconSize)
    staticIconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -15, 15)  -- Always fixed at top left
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

    -- Create a dynamic event icon (for event-specific icons)
    local eventIconSize = 36
    local eventIconFrame = CreateFrame("Frame", nil, frame)
    eventIconFrame:SetSize(eventIconSize, eventIconSize)
    eventIconFrame:SetPoint("LEFT", frame, "LEFT", 25, 0)
    local eventIcon = eventIconFrame:CreateTexture(nil, "ARTWORK")
    eventIcon:SetAllPoints(true)
    eventIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- default icon
    frame.eventIconFrame = eventIconFrame
    frame.eventIcon = eventIcon

    -- Create the message text.
    local messageText = frame:CreateFontString(nil, "OVERLAY")
    -- Anchor the text so it doesn't overlap the icons
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

    local frame = CreateFrame("Frame", "MissionAccomplishedGavrialsCallFrame", UIParent, 
        BackdropTemplateMixin and "BackdropTemplate" or nil)
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

    ApplyOrganicBanner(frame)

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

    local animFadeOut = frame.InOut:CreateAnimation("Alpha")
    animFadeOut:SetOrder(3)
    animFadeOut:SetDuration(FADE_OUT_TIME)
    animFadeOut:SetFromAlpha(1)
    animFadeOut:SetToAlpha(0)

    frame.InOut:SetScript("OnFinished", function()
        frame:SetAlpha(0)  -- keep frame visible (but transparent) for hover
        if #QUEUE > 0 then
            local nextMsg = table.remove(QUEUE, 1)
            GavrialsCall.DisplayMessage(nextMsg.playerName, nextMsg.text, nextMsg.icon, nextMsg.color)
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
    if MissionAccomplishedDB and MissionAccomplishedDB.eventSoundsEnabled == false then
        return
    end
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
    if not GavrialsCall.frame then
        GavrialsCall.CreateFrame()
    end
    local frame = GavrialsCall.frame

    local prefix = ""
    if sender and sender ~= "" then
        prefix = sender .. ", "
    end
    local msgFormatted = prefix .. (text or "")
    local now = GetTime()
    if GavrialsCall.lastMessage == msgFormatted and (now - GavrialsCall.lastMessageTime) < GavrialsCall.lastMessageCooldown then
        return
    end
    GavrialsCall.lastMessage = msgFormatted
    GavrialsCall.lastMessageTime = now

    -- If the frame's animation is currently playing, queue this message.
    if frame:IsShown() and frame.InOut:IsPlaying() then
        if #QUEUE < MAX_QUEUE_SIZE then
            table.insert(QUEUE, {
                playerName = sender,
                text = text,
                icon = iconPath,
                color = color
            })
        end
        return
    end

    frame.messageText:SetText(msgFormatted)
    -- Update the dynamic event icon (the static gavicon remains unchanged).
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
end

------------------------------------------------------------------------------
-- New: DisplayProgressMessage (Local-only message on login)
------------------------------------------------------------------------------
local function DisplayProgressMessage()
    local playerName = UnitName("player") or "Player"
    local xpSoFar = MissionAccomplished.GetTotalXPSoFar() or 0
    local xpMax   = MissionAccomplished.GetXPMaxTo60() or 1
    local xpLeft  = xpMax - xpSoFar
    local xpPct   = (xpSoFar / xpMax) * 100
    local progressMsg = string.format("you are %.1f%% done with %d EXP left until completion", xpPct, xpLeft)
    GavrialsCall.DisplayMessage(playerName, progressMsg, "Interface\\Icons\\INV_Misc_Map_01", {1, 0.8, 0})
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
-- 6) Show a “Welcome Back” Message Once
------------------------------------------------------------------------------
local function DisplayWelcomeTextOnce()
    if welcomeShown then return end
    welcomeShown = true

    local playerName = UnitName("player") or "Player"
    local xpSoFar    = MissionAccomplished.GetTotalXPSoFar() or 0
    local xpMax      = MissionAccomplished.GetXPMaxTo60() or 1
    local remain     = xpMax - xpSoFar
    if remain < 0 then remain = 0 end

    local pct = (xpSoFar / xpMax) * 100
    local msg = string.format("Welcome back, %s! You are currently %.1f%% done with %d EXP remaining. Keep grinding!", playerName, pct, remain)
    GavrialsCall.DisplayMessage(playerName, msg, "Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp", {1, 1, 1})
    GavrialsCall.PlayEventSound("Welcome")
end

------------------------------------------------------------------------------
-- 7) Handle Event Message from CHAT_MSG_ADDON
------------------------------------------------------------------------------
function GavrialsCall.HandleEventMessage(message, sender)
    local eventName, messageText = strsplit(":", message, 2)
    if not eventName or not messageText then return end

    local iconPath = nil
    local color    = {1, 1, 1}

    if eventName == "Progress" then
        local xpPct = MissionAccomplished.GetProgressPercentage()
        local formattedPct = string.format("%.1f", xpPct)
        messageText = "you are " .. formattedPct .. "% done with the EXP left until completion"
        iconPath    = "Interface\\Icons\\INV_Misc_Map_01"
        color       = {1, 0.8, 0}
    elseif eventName == "LowHealth" then
        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
        color    = {1, 0, 0}
    elseif eventName == "LevelUp" then
        iconPath = "Interface\\Icons\\Spell_Nature_EnchantArmor"
        color    = {0, 1, 0}
    elseif eventName == "PlayerDeath" then
        iconPath = "Interface\\Icons\\Spell_Shadow_SoulLeech_3"
        color    = {0.5, 0, 0}
    elseif eventName == "EnteredInstance" then
        iconPath = "Interface\\Icons\\Spell_Nature_AstralRecalGroup"
        color    = {0, 1, 0}
    elseif eventName == "LeftInstance" then
        iconPath = "Interface\\Icons\\Spell_Nature_AstralRecal"
        color    = {1, 1, 0}
    elseif eventName == "GuildDeath" then
        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
        color    = {1, 0, 0}
    elseif eventName == "GuildLevelUp" then
        iconPath = "Interface\\Icons\\INV_Scroll_02"
        color    = {0, 1, 0}
    elseif eventName == "GuildAchievement" then
        iconPath = "Interface\\Icons\\INV_Stone_15"
        color    = {1, 1, 0}
    elseif eventName == "GuildLowHealth" then
        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
        color    = {1, 0, 0}
    elseif eventName == "GuildEnteredInstance" then
        iconPath = "Interface\\Icons\\Spell_Nature_AstralRecalGroup"
        color    = {0, 1, 0}
    elseif eventName == "MaxLevel" then
        iconPath = "Interface\\Icons\\INV_Misc_Token_OrcTroll"
        color    = {1, 0.84, 0}
    end

    GavrialsCall.DisplayMessage(sender, messageText, iconPath, color)
    GavrialsCall.PlayEventSound(eventName)
end

------------------------------------------------------------------------------
-- 8) Handle Character Events (Local Notifications)
------------------------------------------------------------------------------
function GavrialsCall.HandleCharacterEvent(event, ...)
    local pName = UnitName("player") or "Player"

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        if newLevel == 60 then
            local guildName = GetGuildInfo("player") or "No Guild"
            local specialMsg = string.format("Congratulations, you have reached level 60 – the pinnacle of achievement! (%s from your guild)", guildName)
            GavrialsCall.DisplayMessage(pName, specialMsg, "Interface\\Icons\\INV_Misc_Token_OrcTroll", {1, 0.84, 0})
            GavrialsCall.PlayEventSound("MaxLevel")
            C_ChatInfo.SendAddonMessage(PREFIX, "MaxLevel:" .. pName .. " from your guild has reached level 60 – the pinnacle of achievement! Your legend now begins!", "GUILD")
        else
            GavrialsCall.DisplayMessage(pName, "you have reached level " .. newLevel .. "! Congrats!", "Interface\\Icons\\Spell_Nature_EnchantArmor", {0, 1, 0})
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
                        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
                        col      = {1, 0, 0}
                    else
                        msg      = "you are critically low (" .. math.floor(pct) .. "% health)! Help!"
                        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
                        col      = {1, 0, 0}
                        local guildMsg = pName .. " is at 10% HP! Send help!"
                        C_ChatInfo.SendAddonMessage(PREFIX, "GuildLowHealth:" .. guildMsg, "GUILD")
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
        GavrialsCall.DisplayMessage(pName, "you have been defeated!", "Interface\\Icons\\Spell_Shadow_SoulLeech_3", {0.5, 0, 0})
        GavrialsCall.PlayEventSound("PlayerDeath")

    elseif event == "PLAYER_ENTERING_WORLD" then
        local inInstance, instanceType = IsInInstance()
        local instanceName            = GetInstanceInfo()
        if inInstance and (instanceType == "party" or instanceType == "raid") then
            if not GavrialsCall.previousInstanceName then
                GavrialsCall.DisplayMessage(pName, "you are entering " .. instanceName .. ", good luck!", "Interface\\Icons\\Spell_Nature_AstralRecalGroup", {0, 1, 0})
                local guildMsg = pName .. " from your guild is entering " .. instanceName .. ", good luck!"
                C_ChatInfo.SendAddonMessage(PREFIX, "GuildEnteredInstance:" .. guildMsg, "GUILD")
                GavrialsCall.PlayEventSound("EnteredInstance")
            end
            GavrialsCall.previousInstanceName = instanceName
        else
            if GavrialsCall.previousInstanceName then
                GavrialsCall.DisplayMessage(pName, "you have left " .. GavrialsCall.previousInstanceName .. ".", "Interface\\Icons\\Spell_Nature_AstralRecal", {1, 1, 0})
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
                GavrialsCall.DisplayMessage(destName or "A group member", "has been defeated in your group!", "Interface\\Icons\\Ability_Creature_Cursed_05", {1, 0, 0})
                GavrialsCall.PlayEventSound("GuildDeath")
            end
        end
    end
end

------------------------------------------------------------------------------
-- 10) Initialization
------------------------------------------------------------------------------
function GavrialsCall.Init()
    GavrialsCall.CreateFrame()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(PREFIX) then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end

    GavrialsCall.eventFrame = CreateFrame("Frame")
    GavrialsCall.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    GavrialsCall.eventFrame:RegisterEvent("UNIT_HEALTH")
    GavrialsCall.eventFrame:RegisterEvent("PLAYER_DEAD")
    GavrialsCall.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    GavrialsCall.eventFrame:RegisterEvent("UPDATE_EXHAUSTION")
    GavrialsCall.eventFrame:RegisterEvent("UNIT_AURA")
    GavrialsCall.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    GavrialsCall.eventFrame:SetScript("OnEvent", function(_, e, ...)
        GavrialsCall.HandleCharacterEvent(e, ...)
    end)

    GavrialsCall.ResetHealthNotifications()

    -- Display the progress message locally immediately upon login.
    DisplayProgressMessage()

    if MissionAccomplishedDB and MissionAccomplishedDB.eventFrameEnabled then
        GavrialsCall.Show(false)
    end

    -- Show the welcome message after 2 seconds.
    C_Timer.After(2, DisplayWelcomeTextOnce)
end

-- ADDON_LOADED / CHAT_MSG_ADDON Handling
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
        if prefix == PREFIX then
            if message == "EnableEventFrame" then
                GavrialsCall.Show(false)
            elseif message == "DisableEventFrame" then
                GavrialsCall.Hide()
            else
                GavrialsCall.HandleEventMessage(message, sender)
            end
        end
    end
end)
