--=============================================================================
-- NagletsToolkit.lua
--=============================================================================
-- Creates a "Naglet's Toolkit" tab content frame with:
--   1) In-Game Tools (Ready Check, Roll, 10s Timer, Clear Marks)
--   2) MissionAccomplished Tools (Reset Combat Data, Test Event Functions, Send Progress)
--   3) System Tools (Reload UI, Clear Cache, Show FPS, Take Screenshot)
--
-- When "Reset Combat Data" is pressed, it zeroes out all relevant stats and
-- prints "Combat data cleared!" without forcing a tab switch.
-- When "Test Event Functions" is pressed, it shows local (user-only) test
-- notifications using a local event handler so that no addon messages are broadcast.
-- The "Send Progress" button calculates your progress toward level 60 and:
--   - Displays it in your event box.
--   - Broadcasts it to your guild if you are in one.
-- If you are not in a guild, a friendly message is displayed locally.
--=============================================================================

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
    -- 1) In-Game Tools
    ----------------------------------------------------------------
    local function StartTenSecondTimer()
        for i = 1, 10 do
            C_Timer.After(i, function()
                local remain = 10 - i
                if remain > 0 then
                    print("[Naglet's Toolkit] Timer: " .. remain .. " seconds remaining.")
                else
                    print("[Naglet's Toolkit] Timer completed.")
                end
            end)
        end
    end

    local inGameButtons = {
        { "Ready Check", function()
            DoReadyCheck()
            local msg = "I've initiated a ready check for you!"
            print("[Naglet's Toolkit] Sent Ready Check.")
            MissionAccomplished.GavrialsCall.DisplayMessage("Ready Check", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
        end },
        { "Roll", function()
            local roll = math.random(1, 100)
            local msg = "You rolled a " .. roll .. ". Nice roll!"
            print("[Naglet's Toolkit] Roll result: " .. roll)
            MissionAccomplished.GavrialsCall.DisplayMessage("Roll", msg, "Interface\\Icons\\INV_Dice_02", {1, 1, 1})
        end },
        { "10s Timer", function()
            StartTenSecondTimer()
            local msg = "I've started a 10-second countdown for you!"
            print("[Naglet's Toolkit] Started 10-second timer.")
            MissionAccomplished.GavrialsCall.DisplayMessage("Timer", msg, "Interface\\Icons\\INV_Misc_Map_01", {1, 1, 1})
        end },
        { "Clear Marks", function()
            for i = 1, 40 do
                SetRaidTarget("raid" .. i, 0)
            end
            local msg = "I've cleared all raid markers for you."
            print("[Naglet's Toolkit] Cleared all raid markers.")
            MissionAccomplished.GavrialsCall.DisplayMessage("Raid Markers", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
        end },
    }

    ----------------------------------------------------------------
    -- 2) MissionAccomplished Tools
    ----------------------------------------------------------------
    local missionButtons = {
{ "Reset Combat Data", function()
    -- Ensure the database exists
    if not MissionAccomplishedDB then
        MissionAccomplishedDB = {}
    end

    -- Clear all combat-related data
    MissionAccomplishedDB.lowestHP        = nil
    MissionAccomplishedDB.highestDamage   = 0
    MissionAccomplishedDB.totalDamage     = 0
    MissionAccomplishedDB.totalEnemies    = 0
    MissionAccomplishedDB.totalCombatTime = 0
    MissionAccomplishedDB.avgDPS          = 0
    MissionAccomplishedDB.avgDPM          = 0
    MissionAccomplishedDB.enemiesPerHour  = 0

    local msg = "All combat data has been cleared."
    print("[Naglet's Toolkit] Combat data cleared!")
    MissionAccomplished.GavrialsCall.DisplayMessage("Combat Data", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
end },
        { "Test Event Functions", function()
            if not (MissionAccomplished and MissionAccomplished.GavrialsCall) then
                print("[Naglet's Toolkit] MissionAccomplished.GavrialsCall not found.")
                return
            end

            -- Ensure the event box is visible for testing.
            MissionAccomplished.GavrialsCall.Show(true)

            -- Local helper that mimics HandleEventMessage without broadcasting.
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
                MissionAccomplished.GavrialsCall.DisplayMessage(sender, messageText, iconPath, color)
                MissionAccomplished.GavrialsCall.PlayEventSound(eventName)
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
                print("[Naglet's Toolkit] Triggered local event: " .. eventString)
            end
        end },
        { "Send Progress", function()
            local playerName = UnitName("player") or "Player"
            local xpSoFar = MissionAccomplished.GetTotalXPSoFar() or 0
            local xpMax = MissionAccomplished.GetXPMaxTo60() or 1
            local xpLeft = xpMax - xpSoFar
            local xpPct = (xpSoFar / xpMax) * 100
            local msg = string.format("Hey, you are %.1f%% done with %d EXP left until level 60!", xpPct, xpLeft)
            -- Display the progress locally.
            MissionAccomplished.GavrialsCall.DisplayMessage(playerName, msg, "Interface\\Icons\\INV_Misc_Map_01", {1, 0.8, 0})
            -- Check if you're in a guild.
            if not IsInGuild() then
                local noGuildMsg = "You're not in a guild right now, so I can't broadcast your progress."
                MissionAccomplished.GavrialsCall.DisplayMessage(playerName, noGuildMsg, "Interface\\Icons\\INV_Misc_Token_OrcTroll", {1, 0.2, 0.2})
                return
            end
            local result = C_ChatInfo.SendAddonMessage(PREFIX, "Progress:" .. msg, "GUILD")
            print("[Naglet's Toolkit] Sent progress to guild.")
        end },
    }

    ----------------------------------------------------------------
    -- 3) System Tools
    ----------------------------------------------------------------
    local systemButtons = {
        { "Reload UI", function()
            local msg = "Reloading the UI now!"
            MissionAccomplished.GavrialsCall.DisplayMessage("System", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
            ReloadUI()
        end },
        { "Clear Cache", function()
            local msg = "Clearing cache and reloading UI!"
            MissionAccomplished.GavrialsCall.DisplayMessage("System", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
            C_Timer.After(0.5, function() ReloadUI() end)
            print("[Naglet's Toolkit] Reloading UI in 0.5 seconds...")
        end },
        { "Show FPS", function()
            local fps = GetFramerate()
            local msg = "Your current FPS is " .. math.floor(fps) .. "."
            print("[Naglet's Toolkit] " .. msg)
            MissionAccomplished.GavrialsCall.DisplayMessage("Current FPS", tostring(math.floor(fps)), "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", {1, 1, 1})
        end },
        { "Take Screenshot", function()
            Screenshot()
            local msg = "I've taken a screenshot for you."
            MissionAccomplished.GavrialsCall.DisplayMessage("Screenshot", msg, "Interface\\Icons\\INV_Misc_QuestionMark", {1, 1, 1})
            print("[Naglet's Toolkit] Screenshot taken.")
        end },
    }

    ----------------------------------------------------------------
    -- Create the button groups
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
    -- Create the main toolkit frame content
    ----------------------------------------------------------------
    CreateButtonGroup(inGameHeader,  inGameButtons,  0, -10, toolkitFrame)
    CreateButtonGroup(missionHeader, missionButtons, 0, -10, toolkitFrame)
    CreateButtonGroup(systemHeader,  systemButtons,  0, -10, toolkitFrame)

    -- Save the frame reference.
    _G.SettingsFrameContent.toolkitFrame = toolkitFrame
    return ""
end

_G.NagletsToolkitContent = NagletsToolkitContent
