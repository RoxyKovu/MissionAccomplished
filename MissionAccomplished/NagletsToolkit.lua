--=============================================================================
-- NagletsToolkit.lua
--=============================================================================
-- Creates a "Naglet's Toolkit" tab content frame with:
--   1) In-Game Tools (Ready Check, Roll, 10s Timer, Clear Marks)
--   2) MissionAccomplished Tools (Reset Combat Data, Test Event Functions)
--   3) System Tools (Reload UI, Clear Cache, etc.)
--
-- When "Reset Combat Data" is pressed, it zeroes out all relevant stats and
-- just prints "Combat data cleared!" with no forced tab switching.
-- When "Test Event Functions" is pressed, it shows local (user-only) test notifications
-- using GavrialsCall.HandleEventMessage (no addon messages are broadcast).
--=============================================================================

local function NagletsToolkitContent()
    -- Basic check for the parent content frame
    if not _G.SettingsFrameContent or not _G.SettingsFrameContent.contentFrame then
        return ""
    end

    -- If we already created the toolkitFrame, just show it and return
    if _G.SettingsFrameContent.toolkitFrame then
        _G.SettingsFrameContent.toolkitFrame:Show()
        return ""
    end

    -- Create the main toolkit frame
    local toolkitFrame = CreateFrame("Frame", nil, _G.SettingsFrameContent.contentFrame)
    toolkitFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame)
    toolkitFrame:SetFrameStrata("DIALOG") -- Keep on top

    -- Semi-transparent background (Naglet.blp)
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

    -- A simple 10-second timer
    local function StartTenSecondTimer()
        for i = 1, 10 do
            C_Timer.After(i, function()
                local remain = 10 - i
                if remain > 0 then
                    -- Optionally display time left
                    print("[Naglet's Toolkit] Timer: " .. remain .. " seconds remaining.")
                else
                    -- Notify that the timer is done
                    print("[Naglet's Toolkit] Timer completed.")
                    -- Optionally send an event message or local notification
                end
            end)
        end
    end

    local inGameButtons = {
        { "Ready Check", function()
            DoReadyCheck()
            print("[Naglet's Toolkit] Sent Ready Check.")
        end },
        { "Roll", function()
            local roll = RandomRoll(1, 100)
            print("[Naglet's Toolkit] Roll result: " .. roll)
        end },
        { "10s Timer", function()
            StartTenSecondTimer()
            print("[Naglet's Toolkit] Started 10-second timer.")
        end },
        { "Clear Marks", function()
            for i = 1, 40 do
                SetRaidTarget("raid" .. i, 0)  -- Clears all raid markers
            end
            print("[Naglet's Toolkit] Cleared all raid markers.")
            -- Optionally notify via GavrialsCall
            if MissionAccomplished
               and MissionAccomplished.GavrialsCall
               and MissionAccomplished.GavrialsCall.DisplayMessage then

                MissionAccomplished.GavrialsCall.DisplayMessage(
                    "Raid Markers",
                    "Cleared all raid markers!",
                    "Interface\\Icons\\INV_Misc_QuestionMark",
                    {1, 1, 1}
                )
            end
        end },
    }

    ----------------------------------------------------------------
    -- 2) MissionAccomplished Tools
    ----------------------------------------------------------------
    local missionButtons = {
        { "Reset Combat Data", function()
            -- Clear or reset relevant combat DB fields
            MissionAccomplishedDB = MissionAccomplishedDB or {}
            MissionAccomplishedDB.lowestHP        = nil
            MissionAccomplishedDB.highestDamage   = 0
            MissionAccomplishedDB.avgDPS          = 0
            MissionAccomplishedDB.avgDPM          = 0
            MissionAccomplishedDB.enemiesPerHour  = 0
            MissionAccomplishedDB.totalDamage     = 0
            MissionAccomplishedDB.totalEnemies    = 0
            MissionAccomplishedDB.totalCombatTime = 0

            -- Notify via GavrialsCall
            if MissionAccomplished
               and MissionAccomplished.GavrialsCall
               and MissionAccomplished.GavrialsCall.DisplayMessage then

                MissionAccomplished.GavrialsCall.DisplayMessage(
                    "Combat Data",
                    "Cleared!",
                    "Interface\\Icons\\INV_Misc_QuestionMark",
                    {1, 1, 1}
                )
            end
            print("[Naglet's Toolkit] Combat data cleared!")
        end },
        { "Test Event Functions", function()
            -- Instead of sending addon messages to PARTY,
            -- we'll directly invoke GavrialsCall.HandleEventMessage for user-only.
            if not (MissionAccomplished and MissionAccomplished.GavrialsCall) then
                print("[Naglet's Toolkit] MissionAccomplished.GavrialsCall not found.")
                return
            end

            local testEvents = {
                "LowHealth:Health is below 25%",
                "LevelUp:Reached level 15!",
                "Progress:50% to level 60!",
                "PlayerDeath:Player has been defeated."
            }
            
            local playerName = UnitName("player") or "You"
            for _, eventString in ipairs(testEvents) do
                -- This calls the local event handler, so only you see it
                MissionAccomplished.GavrialsCall.HandleEventMessage(eventString, playerName)
                print("[Naglet's Toolkit] Triggered local event: " .. eventString)
            end
        end },
    }

    ----------------------------------------------------------------
    -- 3) System Tools
    ----------------------------------------------------------------
    local systemButtons = {
        { "Reload UI", function()
            ReloadUI()
        end },
        { "Clear Cache", function()
            C_Timer.After(0.5, function() ReloadUI() end)
            print("[Naglet's Toolkit] Reloading UI in 0.5 seconds...")
        end },
        { "Show FPS", function()
            local fps = GetFramerate()
            print("[Naglet's Toolkit] Current FPS: " .. math.floor(fps))
            -- Optionally display via GavrialsCall
            if MissionAccomplished
               and MissionAccomplished.GavrialsCall
               and MissionAccomplished.GavrialsCall.DisplayMessage then

                MissionAccomplished.GavrialsCall.DisplayMessage(
                    "Current FPS",
                    tostring(math.floor(fps)),
                    "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings",
                    {1, 1, 1}
                )
            end
        end },
        { "Take Screenshot", function()
            Screenshot()
            if MissionAccomplished
               and MissionAccomplished.GavrialsCall
               and MissionAccomplished.GavrialsCall.DisplayMessage then

                MissionAccomplished.GavrialsCall.DisplayMessage(
                    "Screenshot",
                    "Taken and saved.",
                    "Interface\\Icons\\INV_Misc_QuestionMark",
                    {1, 1, 1}
                )
            end
            print("[Naglet's Toolkit] Screenshot taken.")
        end },
    }

    ----------------------------------------------------------------
    -- Create the button groups
    ----------------------------------------------------------------
    CreateButtonGroup(inGameHeader,  inGameButtons,  0, -10, toolkitFrame)
    CreateButtonGroup(missionHeader, missionButtons, 0, -10, toolkitFrame)
    CreateButtonGroup(systemHeader,  systemButtons,  0, -10, toolkitFrame)

    -- Save the frame reference
    _G.SettingsFrameContent.toolkitFrame = toolkitFrame
    return ""
end

_G.NagletsToolkitContent = NagletsToolkitContent
