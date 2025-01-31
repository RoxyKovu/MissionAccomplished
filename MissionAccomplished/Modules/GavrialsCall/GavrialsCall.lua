--=============================================================================
-- GavrialsCall.lua
--=============================================================================
-- Single animation: fade in -> 5s wait -> fade out.
-- Smaller, wrapped text for ALL messages, including welcome swirl.
-- Guild broadcasts at 10% HP & instance entry.
--=============================================================================

MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.GavrialsCall = MissionAccomplished.GavrialsCall or {}
local GavrialsCall = MissionAccomplished.GavrialsCall

-- Basic config
local FRAME_WIDTH    = 400
local FRAME_HEIGHT   = 50
local FADE_IN_TIME   = 0.5
local DISPLAY_TIME   = 5.0
local FADE_OUT_TIME  = 1.0
local MAX_QUEUE_SIZE = 10
local PREFIX         = "MissionAcc"
local QUEUE          = {}

GavrialsCall.isPersistent             = false
GavrialsCall.healthThresholds         = {75, 50, 25, 10}
GavrialsCall.healthThresholdsNotified = {}
GavrialsCall.previousInstanceName     = nil
GavrialsCall.lastMessage              = nil
GavrialsCall.lastMessageTime          = 0
GavrialsCall.lastMessageCooldown      = 30

local welcomeShown                    = false -- show the welcome swirl once

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
    if not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.3)
    frame:SetBackdropBorderColor(1, 1, 1, 1)

    local swirlBar = frame:CreateTexture(nil, "ARTWORK")
    swirlBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    swirlBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    swirlBar:SetTexture("Interface\\PetPaperDollFrame\\UI-PetPaperDollFrame-LoyaltyBar")
    swirlBar:SetTexCoord(0, 1, 0, 1)
    swirlBar:SetVertexColor(1, 1, 1, 1)

    local iconSize = 40
    local iconFrame = CreateFrame("Frame", nil, frame)
    iconFrame:SetSize(iconSize, iconSize)
    iconFrame:SetPoint("RIGHT", frame, "LEFT", 14, 0)

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(true)
    icon:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp")

    frame.iconFrame = iconFrame
    frame.icon      = icon

    -- Now create the message font string
    local messageText = frame:CreateFontString(nil, "OVERLAY")
    -- Use a smaller font + multiline wrap for ALL messages
    messageText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    messageText:SetWordWrap(true)
    messageText:SetWidth(FRAME_WIDTH - 40)

    -- Anchor it center
    messageText:SetPoint("CENTER", frame, "CENTER")
    messageText:SetJustifyH("CENTER")
    if messageText.SetJustifyV then
        messageText:SetJustifyV("MIDDLE")
    end

    messageText:SetTextColor(1, 1, 1, 1)
    frame.messageText = messageText
end

------------------------------------------------------------------------------
-- 3) Create Main Frame (Single In-Out Animation)
------------------------------------------------------------------------------
function GavrialsCall.CreateFrame()
    if GavrialsCall.frame then
        return GavrialsCall.frame
    end

    local frame = CreateFrame(
        "Frame",
        "MissionAccomplishedGavrialsCallFrame",
        UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil
    )

    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    -- Shift-drag to move
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if MissionAccomplishedDB then
            local point, _, relPoint, x, y = self:GetPoint()
            MissionAccomplishedDB.gavFramePos = {
                point=point,
                relPoint=relPoint,
                x=x,
                y=y
            }
        end
    end)

    ApplyOrganicBanner(frame)

    -- Single fade in -> wait -> fade out
    frame.InOut = frame:CreateAnimationGroup()

    -- (1) Fade In
    local animFadeIn = frame.InOut:CreateAnimation("Alpha")
    animFadeIn:SetOrder(1)
    animFadeIn:SetDuration(FADE_IN_TIME)
    animFadeIn:SetFromAlpha(0)
    animFadeIn:SetToAlpha(1)

    -- (2) Wait
    local animWait = frame.InOut:CreateAnimation("Alpha")
    animWait:SetOrder(2)
    animWait:SetDuration(DISPLAY_TIME)
    animWait:SetFromAlpha(1)
    animWait:SetToAlpha(1)

    -- (3) Fade Out
    local animFadeOut = frame.InOut:CreateAnimation("Alpha")
    animFadeOut:SetOrder(3)
    animFadeOut:SetDuration(FADE_OUT_TIME)
    animFadeOut:SetFromAlpha(1)
    animFadeOut:SetToAlpha(0)

    frame.InOut:SetScript("OnFinished", function()
        frame:Hide()
        -- After each message, if there are queued messages, show next
        if #QUEUE > 0 then
            local nextMsg = table.remove(QUEUE, 1)
            GavrialsCall.DisplayMessage(nextMsg.playerName, nextMsg.text,
                                        nextMsg.icon, nextMsg.color)
        end
    end)

    frame:Hide()

    -- Restore saved position if any
    if MissionAccomplishedDB and MissionAccomplishedDB.gavFramePos then
        local pos = MissionAccomplishedDB.gavFramePos
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end

    GavrialsCall.frame = frame
    return frame
end

------------------------------------------------------------------------------
-- 4) DisplayMessage (Prepends PlayerName (no colon))
------------------------------------------------------------------------------
function GavrialsCall.DisplayMessage(playerName, text, iconPath, color)
    if not GavrialsCall.frame then
        GavrialsCall.CreateFrame()
    end
    local frame = GavrialsCall.frame

    local prefix = ""
    if playerName and playerName ~= "" then
        prefix = playerName .. " "
    end
    local msgFormatted = prefix .. (text or "")

    local now = GetTime()

    -- Skip repeated identical messages if within 30s
    if GavrialsCall.lastMessage == msgFormatted then
        if (now - GavrialsCall.lastMessageTime) < GavrialsCall.lastMessageCooldown then
            return
        end
    end

    -- If a message is displayed & we’re not persistent, queue
    if frame:IsShown() and not GavrialsCall.isPersistent then
        if #QUEUE < MAX_QUEUE_SIZE then
            table.insert(QUEUE, {
                playerName = playerName,
                text       = text,
                icon       = iconPath,
                color      = color,
            })
        end
        return
    end

    GavrialsCall.lastMessage       = msgFormatted
    GavrialsCall.lastMessageTime   = now

    -- Set text + icon
    frame.messageText:SetText(msgFormatted)
    if iconPath and type(iconPath) == "string" then
        frame.icon:SetTexture(iconPath)
    else
        frame.icon:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp")
    end

    if type(color) == "table" and #color >= 3 then
        frame.messageText:SetTextColor(color[1], color[2], color[3])
    else
        frame.messageText:SetTextColor(1, 1, 1)
    end

    if GavrialsCall.isPersistent then
        frame.InOut:Stop()
        frame:SetAlpha(1)
        frame:Show()
    else
        frame.InOut:Stop()
        frame:SetAlpha(0)
        frame:Show()
        frame.InOut:Play()
    end
end

------------------------------------------------------------------------------
-- 5) Show / Hide
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
            if GavrialsCall.frame.messageText:GetText() ~= "" then
                GavrialsCall.frame.InOut:Stop()
                GavrialsCall.frame:SetAlpha(0)
                GavrialsCall.frame:Show()
                GavrialsCall.frame.InOut:Play()
            end
        else
            GavrialsCall.CreateFrame()
        end
    end
end

function GavrialsCall.Hide()
    if GavrialsCall.isPersistent and GavrialsCall.frame then
        GavrialsCall.isPersistent = false
        GavrialsCall.frame:Hide()
    elseif GavrialsCall.frame then
        GavrialsCall.frame.InOut:Stop()
        GavrialsCall.frame:SetAlpha(1)
        GavrialsCall.frame.InOut:Finish()
    end
end

------------------------------------------------------------------------------
-- 6) Show a smaller “Welcome Back” swirl once
------------------------------------------------------------------------------
local function DisplayWelcomeTextOnce()
    if welcomeShown then return end
    welcomeShown = true

    local playerName = UnitName("player") or "Player"
    local xpSoFar    = MissionAccomplished.GetTotalXPSoFar() or 0
    local xpMax      = MissionAccomplished.GetXPMaxTo60() or 1
    local remain     = xpMax - xpSoFar
    if remain < 0 then
        remain = 0
    end

    local pct = (xpSoFar / xpMax) * 100

    -- Because the entire swirl is smaller/wrapped now, we just pass normal text
    local msg = string.format(
        "Welcome back, %s! You are currently %.1f%% completed with %d XP to go. Keep grinding and stay alive!",
        playerName, pct, remain
    )

    -- Show swirl with the player's name in front
    -- If you want "Gavrial " or "PlayerName " for the welcome swirl, pass that as the first param.
    -- But typically you'd do no name or do "PlayerName, " inside the message. Let's just do nil for first param:
    GavrialsCall.DisplayMessage(nil, msg, "Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp", {1,1,1})
end

------------------------------------------------------------------------------
-- 7) HandleEventMessage
------------------------------------------------------------------------------
function GavrialsCall.HandleEventMessage(message, sender)
    local eventName, messageText = strsplit(":", message, 2)
    if not eventName or not messageText then
        return
    end

    local iconPath = nil
    local color    = {1, 1, 1}

    if eventName == "Progress" then
        local xpPct = MissionAccomplished.GetProgressPercentage()
        local formattedPct = string.format("%.1f", xpPct)
        messageText = "You are at " .. formattedPct .. "%% of the way to 60!"
        iconPath    = "Interface\\Icons\\INV_Misc_Map_01"
        color       = {0, 0, 1}

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

    -- Guild-based events
    elseif eventName == "GuildDeath" then
        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
        color    = {1, 0.2, 0.2}
    elseif eventName == "GuildLevelUp" then
        iconPath = "Interface\\Icons\\INV_Scroll_02"
        color    = {0, 0.8, 1}
    elseif eventName == "GuildAchievement" then
        iconPath = "Interface\\Icons\\INV_Stone_15"
        color    = {1, 1, 0.2}
    elseif eventName == "GuildLowHealth" then
        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
        color    = {1, 0, 0}
    elseif eventName == "GuildEnteredInstance" then
        iconPath = "Interface\\Icons\\Spell_Nature_AstralRecalGroup"
        color    = {0, 1, 0}
    end

    -- Prepend the 'sender' name
    GavrialsCall.DisplayMessage(sender, messageText, iconPath, color)
end

------------------------------------------------------------------------------
-- 8) HandleCharacterEvent
------------------------------------------------------------------------------
function GavrialsCall.HandleCharacterEvent(event, ...)
    local pName = UnitName("player") or "Player"

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        GavrialsCall.DisplayMessage(
            pName,
            "has reached level " .. newLevel .. "! Congrats!",
            "Interface\\Icons\\Spell_Nature_EnchantArmor",
            {0, 1, 0}
        )

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
                        msg      = "is below " .. threshold .. "% health. Be careful!"
                        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
                        col      = {1, 0, 0}
                    else
                        msg      = "is critically low (" .. math.floor(pct) .. "% health)! Help!"
                        iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
                        col      = {1, 0, 0}

                        local guildMsg = pName .. " is at 10% HP! Send help!"
                        C_ChatInfo.SendAddonMessage(PREFIX, "GuildLowHealth:" .. guildMsg, "GUILD")
                    end

                    GavrialsCall.DisplayMessage(pName, msg, iconPath, col)
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
        GavrialsCall.DisplayMessage(
            pName,
            "was defeated!",
            "Interface\\Icons\\Spell_Shadow_SoulLeech_3",
            {0.5, 0, 0}
        )

    elseif event == "PLAYER_ENTERING_WORLD" then
        local inInstance, instanceType = IsInInstance()
        local instanceName            = GetInstanceInfo()
        if inInstance and (instanceType == "party" or instanceType == "raid") then
            if not GavrialsCall.previousInstanceName then
                GavrialsCall.DisplayMessage(
                    pName,
                    "is entering " .. instanceName .. "! Good luck!",
                    "Interface\\Icons\\Spell_Nature_AstralRecalGroup",
                    {0, 1, 0}
                )
                local guildMsg = pName .. " is entering " .. instanceName .. "! Good luck!"
                C_ChatInfo.SendAddonMessage(PREFIX, "GuildEnteredInstance:" .. guildMsg, "GUILD")
            end
            GavrialsCall.previousInstanceName = instanceName
        else
            if GavrialsCall.previousInstanceName then
                GavrialsCall.DisplayMessage(
                    pName,
                    "has left " .. GavrialsCall.previousInstanceName .. ".",
                    "Interface\\Icons\\Spell_Nature_AstralRecal",
                    {1, 1, 0}
                )
                GavrialsCall.previousInstanceName = nil
            end
        end

    elseif event == "UPDATE_EXHAUSTION" then
        local restXP = GetXPExhaustion()
        if not restXP then
            GavrialsCall.DisplayMessage(
                pName,
                "has no Rested XP left.",
                "Interface\\Icons\\Spell_Nature_Sleep",
                {0.7, 0.7, 1}
            )
        else
            GavrialsCall.DisplayMessage(
                pName,
                "has Rested XP. Keep leveling!",
                "Interface\\Icons\\Spell_Nature_Sleep",
                {0.7, 0.7, 1}
            )
        end

    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            local i = 1
            while true do
                local name, icon, count, debuffType, duration, expirationTime = UnitBuff("player", i)
                if not name then
                    break
                end
                if name == "Rallying Cry of the Dragonslayer" and duration and expirationTime then
                    local timeLeft = expirationTime - GetTime()
                    if timeLeft < 60 then
                        GavrialsCall.DisplayMessage(
                            pName,
                            "has only " .. math.floor(timeLeft) .. "s left on Rallying Cry!",
                            icon,
                            {1, 0.5, 0}
                        )
                    end
                end
                i = i + 1
            end
        end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timeStamp, subEvent, _, 
              sourceGUID, sourceName, _, _, 
              destGUID, destName, destFlags, _, 
              spellID, spellName, _, amount = CombatLogGetCurrentEventInfo()

        if subEvent == "SWING_DAMAGE" or subEvent == "RANGE_DAMAGE" or subEvent:find("_DAMAGE") then
            if destName == pName then
                local maxHP = UnitHealthMax("player")
                if amount and maxHP and amount > 0.5 * maxHP then
                    GavrialsCall.DisplayMessage(
                        pName,
                        "took a massive hit of " .. amount .. " damage!",
                        "Interface\\Icons\\Ability_Warrior_BloodFrenzy",
                        {1, 0.2, 0.2}
                    )
                end
            end
        end

        if subEvent == "UNIT_DIED" then
            if UnitInParty(destName) or UnitInRaid(destName) then
                GavrialsCall.DisplayMessage(
                    destName or "A group member",
                    "has died in your group!",
                    "Interface\\Icons\\Ability_Creature_Cursed_05",
                    {1, 0, 0}
                )
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

    if MissionAccomplishedDB and MissionAccomplishedDB.eventFrameEnabled then
        GavrialsCall.Show(false)
    end

    -- Show welcome swirl after 2 seconds
    C_Timer.After(2, DisplayWelcomeTextOnce)
end

-- ADDON_LOADED / CHAT_MSG_ADDON
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
