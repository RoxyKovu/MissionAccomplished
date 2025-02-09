--=============================================================================
-- NagletsToolkit.lua
--=============================================================================
-- Creates a "Naglet's Toolkit" tab content frame with:
--   1) In-Game Tools (Ready Check, Roll, 10s Timer, Clear Marks)
--   2) MissionAccomplished Tools (Reset Combat Data, Test Event Functions, Send Progress)
--   3) System Tools (Reload UI, Clear Cache, Show FPS, Take Screenshot)
--
-- The "Send Progress" button computes your EXP progress toward level 60 and
-- builds a compressed string in the format:
--
--    MAGuildEvent:PR,<sender>,<roundedPct>
--
-- This string is sent to your custom guild channel (for example, "/MAguildname")
-- via SendChatMessage. Your guild chat handler (in GuildNotification.lua) will
-- then read and process this string (using the event data from your EventsDictionary).
--=============================================================================

-- Fallback definition for EnsureGuildChannel() if not defined globally.
if not EnsureGuildChannel then
    function EnsureGuildChannel()
        local guildName = GetGuildInfo("player")
        if not guildName then
            return 0, nil  -- Not in a guild.
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
end

local function NagletsToolkitContent()
    -- Basic check for the parent content frame.
    if not _G.SettingsFrameContent or not _G.SettingsFrameContent.contentFrame then
        return ""
    end

    -- If we've already created the toolkitFrame, just show it and return.
    if _G.SettingsFrameContent.toolkitFrame then
        _G.SettingsFrameContent.toolkitFrame:Show()
        return ""
    end

    -- Create the main toolkit frame.
    local toolkitFrame = CreateFrame("Frame", nil, _G.SettingsFrameContent.contentFrame)
    toolkitFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame)
    toolkitFrame:SetFrameStrata("DIALOG") -- Keep on top

    -- Semi-transparent background (using Naglet.blp).
    local backgroundTexture = toolkitFrame:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetAllPoints()
    backgroundTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\Naglet.blp")
    backgroundTexture:SetAlpha(0.1) -- 10% transparency

    ----------------------------------------------------------------
    -- Section Headers
    ----------------------------------------------------------------
    local inGameHeader = toolkitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    inGameHeader:SetPoint("TOPLEFT", 20, -20)
    inGameHeader:SetText("In Game Tools")

    local missionHeader = toolkitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    missionHeader:SetPoint("TOPLEFT", 20, -180)
    missionHeader:SetText("MissionAccomplished Tools")

    local systemHeader = toolkitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    systemHeader:SetPoint("TOPLEFT", 20, -320)
    systemHeader:SetText("System Tools")

    ----------------------------------------------------------------
    -- Helper: Create a UIPanelButton
    ----------------------------------------------------------------
    local function CreateButton(parent, text, point, onClickScript)
        local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetSize(150, 40)
        button:SetPoint(unpack(point))
        button:SetText(text)
        button:SetScript("OnClick", onClickScript)
        return button
    end

    local function CreateButtonGroup(header, buttonData, startX, startY, parent)
        local x, y = startX, startY
        local columnSpacing = 160
        local rowSpacing = -50
        for i, data in ipairs(buttonData) do
            local text, script = unpack(data)
            CreateButton(parent, text, { "TOPLEFT", header, "BOTTOMLEFT", x, y }, script)
            if i % 2 == 0 then
                x = startX
                y = y + rowSpacing
            else
                x = x + columnSpacing
            end
        end
    end

    ----------------------------------------------------------------
    -- Timer function that starts a 10-second countdown.
    ----------------------------------------------------------------
    local function StartTenSecondTimer()
        if SlashCmdList and SlashCmdList["COUNTDOWN"] then
            SlashCmdList["COUNTDOWN"]("10")
        elseif Countdown_Start then
            Countdown_Start(10)
        else
            for i = 1, 10 do
                C_Timer.After(i, function()
                    local remain = 10 - i
                    if remain > 0 then
                        MissionAccomplished.GavrialsCall:DisplayMessage("Timer", remain .. " seconds remaining.", "Interface\\Icons\\spell_holy_borrowedtime", {1, 1, 1})
                    else
                        MissionAccomplished.GavrialsCall:DisplayMessage("Timer", "Timer completed.", "Interface\\Icons\\spell_holy_borrowedtime", {1, 1, 1})
                    end
                end)
            end
        end
    end

    ----------------------------------------------------------------
    -- 1) In-Game Tools
    ----------------------------------------------------------------
    local inGameButtons = {
        { "Ready Check", function()
            if SlashCmdList and SlashCmdList["READYCHECK"] then
                SlashCmdList["READYCHECK"]("")
            else
                DoReadyCheck()
            end
            local msg = "Ready check started."
            MissionAccomplished.GavrialsCall:DisplayMessage("Ready Check", msg, "Interface\\Icons\\spell_holy_resurrection", {1, 1, 1})
        end },
        { "Roll", function()
            RandomRoll(1, 100)
            local msg = "Rolling a dice... Check the chat for the result!"
            MissionAccomplished.GavrialsCall:DisplayMessage("Roll", msg, "Interface\\Icons\\inv_misc_dice_02", {1, 1, 1})
        end },
        { "10s Timer", function()
            if SlashCmdList and SlashCmdList["COUNTDOWN"] then
                SlashCmdList["COUNTDOWN"]("10")
            else
                StartTenSecondTimer()
            end
            local msg = "Timer started."
            MissionAccomplished.GavrialsCall:DisplayMessage("Timer", msg, "Interface\\Icons\\inv_misc_ticket_tarot_blessings", {1, 1, 1})
        end },
        { "Clear Marks", function()
            for i = 1, 40 do
                SetRaidTarget("raid" .. i, 0)
            end
            local msg = "I've cleared all raid markers for you."
            MissionAccomplished.GavrialsCall:DisplayMessage("Raid Markers", msg, "Interface\\Icons\\achievement_dungeon_heroic_gloryoftheraider", {1, 1, 1})
        end },
    }

    ----------------------------------------------------------------
    -- 2) MissionAccomplished Tools
    ----------------------------------------------------------------
    local missionButtons = {
        { "Reset Combat Data", function()
            if not MissionAccomplishedDB then
                MissionAccomplishedDB = {}
            end
            MissionAccomplishedDB.lowestHP        = nil
            MissionAccomplishedDB.highestDamage   = 0
            MissionAccomplishedDB.totalDamage     = 0
            MissionAccomplishedDB.totalEnemies    = 0
            MissionAccomplishedDB.totalCombatTime = 0
            MissionAccomplishedDB.avgDPS          = 0
            MissionAccomplishedDB.avgDPM          = 0
            MissionAccomplishedDB.enemiesPerHour  = 0
            local msg = "All combat data has been cleared."
            MissionAccomplished.GavrialsCall:DisplayMessage("Combat Data", msg, "Interface\\Icons\\spell_misc_hellifrepvpcombatmorale", {1, 1, 1})
        end },
        { "Test Event Functions", function()
            if not (MissionAccomplished and MissionAccomplished.GavrialsCall) then
                MissionAccomplished.GavrialsCall:DisplayMessage("Error", "MissionAccomplished.GavrialsCall not found.", "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
                return
            end
            MissionAccomplished.GavrialsCall:Show(true)
            local function HandleEventMessageLocal(message, sender)
                local eventName, messageText = strsplit(":", message, 2)
                if not eventName or not messageText then return end
                local iconPath, color = nil, {1, 1, 1}
                if eventName == "LowHealth" then
                    iconPath = "Interface\\Icons\\Ability_Creature_Cursed_05"
                    color = {1, 0, 0}
                elseif eventName == "LevelUp" then
                    iconPath = "Interface\\Icons\\Spell_Nature_EnchantArmor"
                    color = {0, 1, 0}
                elseif eventName == "Progress" then
                    iconPath = "Interface\\Icons\\INV_Misc_Map_01"
                    color = {1, 0.8, 0}
                elseif eventName == "PlayerDeath" then
                    iconPath = "Interface\\Icons\\Spell_Shadow_SoulLeech_3"
                    color = {0.5, 0, 0}
                end
                MissionAccomplished.GavrialsCall:DisplayMessage(sender, messageText, iconPath, color)
                MissionAccomplished.GavrialsCall:PlayEventSound(eventName)
            end

            local testEvents = {
                "LowHealth:Hey, your health is below 25%!",
                "LevelUp:Congratulations, you reached level 15!",
                "Progress:You're halfway there – 50% done with plenty of EXP left!",
                "PlayerDeath:Oh no, you've been defeated!"
            }
            
            local playerName = UnitName("player") or "You"
            for _, eventString in ipairs(testEvents) do
                HandleEventMessageLocal(eventString, playerName)
            end
        end },
        { "Send Progress", function()
            local sender = UnitName("player") or "Player"
            local xpSoFar = MissionAccomplished.GetTotalXPSoFar() or 0
            local xpMax = MissionAccomplished.GetXPMaxTo60() or 1
            local xpPct = (xpSoFar / xpMax) * 100
            local roundedPct = math.floor(xpPct + 0.5)
            -- Build the compressed progress string (using the PR event format)
            local compressedMessage = string.format("MAGuildEvent:PR,%s,%d", sender, roundedPct)
            if not IsInGuild() then
                MissionAccomplished.GavrialsCall:DisplayMessage(sender, "Not in a guild; progress: " .. compressedMessage, "Interface\\Icons\\INV_Misc_Token_OrcTroll", {1, 0.2, 0.2})
                return
            end
            local channelNum, channelName = EnsureGuildChannel()
            if channelNum and channelNum > 0 then
                SendChatMessage(compressedMessage, "CHANNEL", nil, channelNum)
            else
                MissionAccomplished.GavrialsCall:DisplayMessage(sender, compressedMessage, "Interface\\Icons\\INV_Misc_Map_01", {1, 1, 1})
            end
        end },
    }

    ----------------------------------------------------------------
    -- 3) System Tools
    ----------------------------------------------------------------
    local systemButtons = {
        { "Reload UI", function()
            local msg = "Reloading the UI now!"
            MissionAccomplished.GavrialsCall:DisplayMessage("System", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
            ReloadUI()
        end },
        { "Clear Cache", function()
            local msg = "Clearing cache and reloading UI!"
            MissionAccomplished.GavrialsCall:DisplayMessage("System", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
            C_Timer.After(0.5, function() ReloadUI() end)
        end },
        { "Show FPS", function()
            local fps = GetFramerate()
            local msg = "Your current FPS is " .. math.floor(fps) .. "."
            MissionAccomplished.GavrialsCall:DisplayMessage("Current FPS", tostring(math.floor(fps)), "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", {1, 1, 1})
        end },
        { "Take Screenshot", function()
            Screenshot()
            local msg = "I've taken a screenshot for you."
            MissionAccomplished.GavrialsCall:DisplayMessage("Screenshot", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
        end },
    }

    ----------------------------------------------------------------
    -- Create the button groups
    ----------------------------------------------------------------
    CreateButtonGroup(inGameHeader,  inGameButtons,  0, -10, toolkitFrame)
    CreateButtonGroup(missionHeader, missionButtons, 0, -10, toolkitFrame)
    CreateButtonGroup(systemHeader,  systemButtons,  0, -10, toolkitFrame)

    -- Save the frame reference.
    _G.SettingsFrameContent.toolkitFrame = toolkitFrame
    return ""
end

_G.NagletsToolkitContent = NagletsToolkitContent

-------------------------------------------------------------------------------
-- First-Time Prompt Hook
-------------------------------------------------------------------------------
local firstTimeFrame = CreateFrame("Frame")
firstTimeFrame:RegisterEvent("PLAYER_LOGIN")
firstTimeFrame:SetScript("OnEvent", function()
    C_Timer.After(1, function()
        if MissionAccomplishedDB.showFirstTimePrompt == nil then
            MissionAccomplishedDB.showFirstTimePrompt = true
        end
        if not MissionAccomplishedDB.firstTimeSetup and MissionAccomplishedDB.showFirstTimePrompt then
            if MissionAccomplished.ShowFirstTimeUsePrompt then
                MissionAccomplished.ShowFirstTimeUsePrompt()
            else
                -- print("MissionAccomplished.ShowFirstTimeUsePrompt function not found!")
            end
        end
    end)
end)

MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.ShowFirstTimeUsePrompt = MissionAccomplished.ShowFirstTimeUsePrompt or function()
    print("ShowFirstTimeUsePrompt not defined!")
end
