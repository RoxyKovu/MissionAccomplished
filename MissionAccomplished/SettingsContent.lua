--=============================================================================
-- SettingsContent.lua
--=============================================================================
-- This file defines the content for the "Settings" tab in your addon's UI.
-- Now includes:
--   1) Enable/Disable GavrialsCall event frame
--   2) Enable/Disable XP bar
--   3) SHIFT+drag instructions for moving frames
--=============================================================================

local GavrialsCall = MissionAccomplished.GavrialsCall
local PREFIX = "MissionAcc"

-- The main function that creates and returns the settings frame
local function SettingsContent()
    local settingsFrame = CreateFrame("Frame", nil, _G.SettingsFrameContent.contentFrame)
    settingsFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame)
    settingsFrame:SetFrameStrata("DIALOG") -- ensure it's on top

    -- Background
    local background = settingsFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.1)

    -- Header
    local header = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 20, -20)
    header:SetText("General Settings")

    ----------------------------------------------------------------
    -- 1) SHIFT+Drag Instructions
    ----------------------------------------------------------------
    local instructions = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("|cff00ff00Tips:|r\n" ..
        "• |cff00ccffSHIFT+Drag|r the GavrialsCall frame to move notifications.\n" ..
        "• |cff00ccffSHIFT+Drag|r the XP bar to reposition it.\n" ..
        "• Enable or disable each feature below:"
    )

    ----------------------------------------------------------------
    -- Helper: Create a CheckButton
    ----------------------------------------------------------------
    local function CreateCheckButton(parent, label, pointTable, onClick)
        local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        check:SetPoint(unpack(pointTable))
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
        check.text:SetText(label)
        check:SetScript("OnClick", onClick)
        return check
    end

    -- Ensure a saved variables table
    if not MissionAccomplishedDB then
        MissionAccomplishedDB = {}
    end

    ----------------------------------------------------------------
    -- 2) Event Frame (GavrialsCall) Checkbox
    ----------------------------------------------------------------
    local function OnEnableEventFrameClick(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.eventFrameEnabled = enabled

        if enabled then
            if GavrialsCall and GavrialsCall.Show then
                GavrialsCall.Show(true) -- Show persistently
            end
            C_ChatInfo.SendAddonMessage(PREFIX, "EnableEventFrame", "PARTY")
        else
            if GavrialsCall and GavrialsCall.Hide then
                GavrialsCall.Hide()
            end
            C_ChatInfo.SendAddonMessage(PREFIX, "DisableEventFrame", "PARTY")
        end
    end

    local eventFrameCheckbox = CreateCheckButton(
        settingsFrame,
        "Enable GavrialsCall Notifications",
        { "TOPLEFT", instructions, "BOTTOMLEFT", 0, -20 },
        OnEnableEventFrameClick
    )
    eventFrameCheckbox:SetChecked(MissionAccomplishedDB.eventFrameEnabled or false)

    -- If already enabled, ensure it shows
    if MissionAccomplishedDB.eventFrameEnabled then
        if GavrialsCall and GavrialsCall.Show then
            GavrialsCall.Show(true)
        end
    end

    ----------------------------------------------------------------
    -- 3) XP Bar Checkbox
    ----------------------------------------------------------------
    local function OnEnableXPBarClick(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.enableXPBar = enabled

        -- We'll call a toggle function from Bar.lua:
        if enabled then
            MissionAccomplished_Bar_SetShown(true)
        else
            MissionAccomplished_Bar_SetShown(false)
        end
    end

    local xpBarCheckbox = CreateCheckButton(
        settingsFrame,
        "Enable XP Bar",
        { "TOPLEFT", eventFrameCheckbox, "BOTTOMLEFT", 0, -20 },
        OnEnableXPBarClick
    )
    xpBarCheckbox:SetChecked(MissionAccomplishedDB.enableXPBar or false)

    -- If already enabled, show it
    if MissionAccomplishedDB.enableXPBar then
        MissionAccomplished_Bar_SetShown(true)
    end

    ----------------------------------------------------------------
    -- 4) Behavior When Settings Frame Shown/Hidden
    ----------------------------------------------------------------
    settingsFrame:SetScript("OnShow", function()
        -- Make GavrialsCall frame persistent while settings are visible
        if GavrialsCall and GavrialsCall.Show then
            GavrialsCall.Show(true)
        end
    end)

    settingsFrame:SetScript("OnHide", function()
        -- Return to normal fade-out
        if GavrialsCall then
            GavrialsCall.isPersistent = false
            GavrialsCall.Hide() -- hide immediately
        end
    end)

    return settingsFrame
end

_G.SettingsContent = SettingsContent
