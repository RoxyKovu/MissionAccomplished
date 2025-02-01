--=============================================================================
-- SettingsContent.lua
--=============================================================================
-- This file defines the content for the "Settings" tab in your addon's UI.
-- It now includes:
--   1) A section for Gavrials Callouts (events) with usage tips and toggles.
--      - Toggle for enabling/disabling callouts.
--      - Toggle for enabling/disabling event sounds.
--   2) A section for the XP Bar with its own usage tips and toggle.
--   3) Options are clearly separated by their effect.
--
-- When the settings window is shown, if the callouts are enabled the event
-- frame stays up for repositioning. When the settings window is closed, the
-- event frame reverts to its normal (fading out) behavior.
--=============================================================================

local GavrialsCall = MissionAccomplished.GavrialsCall
local PREFIX = "MissionAcc"

local function SettingsContent()
    local settingsFrame = CreateFrame("Frame", nil, _G.SettingsFrameContent.contentFrame)
    settingsFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame)
    settingsFrame:SetFrameStrata("DIALOG") -- ensure it's on top

    -- Background: A dark semi-transparent background.
    local background = settingsFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.3)

    -- Main Header
    local header = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 20, -20)
    header:SetText("General Settings")

    ----------------------------------------------------------------------------
    -- Section 1: Gavrials Callouts (Events)
    ----------------------------------------------------------------------------
    local calloutsHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    calloutsHeader:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -20)
    calloutsHeader:SetText("Gavrials Callouts")

    local calloutsTips = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    calloutsTips:SetPoint("TOPLEFT", calloutsHeader, "BOTTOMLEFT", 0, -10)
    calloutsTips:SetJustifyH("LEFT")
    calloutsTips:SetText("|cff00ff00Tips:|r\n" ..
        "• Hold SHIFT and drag the notifications frame to reposition it.\n" ..
        "• Event sounds play with each notification."
    )

    -- Separator line
    local separator1 = settingsFrame:CreateTexture(nil, "BACKGROUND")
    separator1:SetColorTexture(1, 1, 1, 0.2)
    separator1:SetPoint("TOPLEFT", calloutsTips, "BOTTOMLEFT", 0, -15)
    separator1:SetPoint("TOPRIGHT", calloutsTips, "BOTTOMRIGHT", 0, -15)
    separator1:SetHeight(1)

    ----------------------------------------------------------------------------
    -- Toggle: Enable Gavrials Callouts
    ----------------------------------------------------------------------------
    local function OnToggleCallouts(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.eventFrameEnabled = enabled

        if enabled then
            if GavrialsCall and GavrialsCall.Show then
                GavrialsCall.Show(true)  -- Show persistently (no fade)
            end
            C_ChatInfo.SendAddonMessage(PREFIX, "EnableEventFrame", "PARTY")
        else
            if GavrialsCall and GavrialsCall.Hide then
                GavrialsCall.Hide()  -- Fade out when disabled
            end
            C_ChatInfo.SendAddonMessage(PREFIX, "DisableEventFrame", "PARTY")
        end
    end

    local calloutsCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    calloutsCheckbox:SetPoint("TOPLEFT", separator1, "BOTTOMLEFT", 0, -20)
    calloutsCheckbox.text = calloutsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    calloutsCheckbox.text:SetPoint("LEFT", calloutsCheckbox, "RIGHT", 5, 0)
    calloutsCheckbox.text:SetText("Enable Gavrials Callouts")
    calloutsCheckbox:SetScript("OnClick", OnToggleCallouts)
    calloutsCheckbox:SetChecked(MissionAccomplishedDB.eventFrameEnabled or false)
    if MissionAccomplishedDB.eventFrameEnabled and GavrialsCall and GavrialsCall.Show then
        GavrialsCall.Show(true)
    end

    ----------------------------------------------------------------------------
    -- Toggle: Enable Event Sounds
    ----------------------------------------------------------------------------
    local function OnToggleEventSounds(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.eventSoundsEnabled = enabled
    end

    local eventSoundsCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    eventSoundsCheckbox:SetPoint("TOPLEFT", calloutsCheckbox, "BOTTOMLEFT", 0, -15)
    eventSoundsCheckbox.text = eventSoundsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    eventSoundsCheckbox.text:SetPoint("LEFT", eventSoundsCheckbox, "RIGHT", 5, 0)
    eventSoundsCheckbox.text:SetText("Enable Event Sounds")
    eventSoundsCheckbox:SetScript("OnClick", OnToggleEventSounds)
    eventSoundsCheckbox:SetChecked(MissionAccomplishedDB.eventSoundsEnabled ~= false)

    ----------------------------------------------------------------------------
    -- Section 2: XP Bar
    ----------------------------------------------------------------------------
    local xpHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    xpHeader:SetPoint("TOPLEFT", eventSoundsCheckbox, "BOTTOMLEFT", 0, -40)
    xpHeader:SetText("XP Bar")

    local xpTips = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpTips:SetPoint("TOPLEFT", xpHeader, "BOTTOMLEFT", 0, -10)
    xpTips:SetJustifyH("LEFT")
    xpTips:SetText("|cff00ff00Tips:|r\n" ..
        "• Hold SHIFT and drag the XP Bar to reposition it.\n" ..
        "• The XP Bar displays your progress toward level 60."
    )

    local separator2 = settingsFrame:CreateTexture(nil, "BACKGROUND")
    separator2:SetColorTexture(1, 1, 1, 0.2)
    separator2:SetPoint("TOPLEFT", xpTips, "BOTTOMLEFT", 0, -15)
    separator2:SetPoint("TOPRIGHT", xpTips, "BOTTOMRIGHT", 0, -15)
    separator2:SetHeight(1)

    ----------------------------------------------------------------------------
    -- Toggle: Enable XP Bar
    ----------------------------------------------------------------------------
    local function OnToggleXPBar(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.enableXPBar = enabled

        if enabled then
            MissionAccomplished_Bar_SetShown(true)
        else
            MissionAccomplished_Bar_SetShown(false)
        end
    end

    local xpCheckbox = CreateFrame("CheckButton", nil, settingsFrame, "UICheckButtonTemplate")
    xpCheckbox:SetPoint("TOPLEFT", separator2, "BOTTOMLEFT", 0, -20)
    xpCheckbox.text = xpCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpCheckbox.text:SetPoint("LEFT", xpCheckbox, "RIGHT", 5, 0)
    xpCheckbox.text:SetText("Enable XP Bar")
    xpCheckbox:SetScript("OnClick", OnToggleXPBar)
    xpCheckbox:SetChecked(MissionAccomplishedDB.enableXPBar or false)
    if MissionAccomplishedDB.enableXPBar then
        MissionAccomplished_Bar_SetShown(true)
    end

    ----------------------------------------------------------------------------
    -- Settings Frame Show/Hide Behavior
    ----------------------------------------------------------------------------
    settingsFrame:SetScript("OnShow", function()
        -- When the settings window is shown and if callouts are enabled,
        -- keep the event box up so the user can reposition it.
        if MissionAccomplishedDB.eventFrameEnabled and GavrialsCall and GavrialsCall.Show then
            GavrialsCall.Show(true)
        end
    end)

    settingsFrame:SetScript("OnHide", function()
        -- When the settings window is closed, revert the event box
        -- to its normal behavior (fade out according to its settings).
        if GavrialsCall then
            GavrialsCall.isPersistent = false
            GavrialsCall.Hide()
        end
    end)

    return settingsFrame
end

_G.SettingsContent = SettingsContent
