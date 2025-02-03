--=============================================================================
-- SettingsContent.lua
--=============================================================================
-- This file defines the content for the "Settings" tab in your addon's UI.
-- It now includes:
--   1) A section for Gavrials Callouts (events) with usage tips and toggles.
--      - Toggle for enabling/disabling callouts.
--      - Toggle for enabling/disabling event sounds.
--   2) A section for the XP Bar with its own usage tips and toggle.
--   3) A section at the bottom that adds "The Story" about the average player’s
--      journey and a nod to "Gavrial the 9th."
--   4) A Gavrials Tips toggle added below the story.
--
-- When the settings window is shown, if the callouts are enabled the event
-- frame stays up for repositioning. When the settings window is closed, the
-- event frame reverts to its normal (fading out) behavior.
--=============================================================================

local GavrialsCall = MissionAccomplished.GavrialsCall
local PREFIX = "MissionAcc"

local function SettingsContent()
    local parentFrame = _G.SettingsFrameContent.contentFrame

    -- Create a scrolling frame to contain the settings content.
    local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints(parentFrame)
    
    -- Reposition the scrollbar 5 pixels in from the right, top, and bottom edges.
    if scrollFrame.ScrollBar then
        scrollFrame.ScrollBar:ClearAllPoints()
        scrollFrame.ScrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -5, -20)
        scrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -5, 20)
    end

    -- Create a content frame that will be the scroll child.
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight())
    scrollFrame:SetScrollChild(content)
    content:SetFrameStrata("DIALOG")

    -- Background: A dark semi-transparent background.
    local background = content:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(content)
    background:SetColorTexture(0, 0, 0, 0.3)

    -- Main Header (using the larger font as a title)
    local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 20, -20)
    header:SetText("General Settings")

    ----------------------------------------------------------------------------
    -- Section 1: Gavrials Callouts (Events)
    ----------------------------------------------------------------------------
    local calloutsHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    calloutsHeader:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -15)
    calloutsHeader:SetText("Gavrials Callouts")

    local calloutsTips = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    calloutsTips:SetPoint("TOPLEFT", calloutsHeader, "BOTTOMLEFT", 0, -8)
    calloutsTips:SetJustifyH("LEFT")
    calloutsTips:SetWordWrap(true)
    calloutsTips:SetWidth(content:GetWidth() - 40)
    calloutsTips:SetText("|cff00ff00Tips:|r\n" ..
        "• Hold SHIFT and drag the notifications frame to reposition it.\n" ..
        "• Event sounds play with each notification.")

    -- Separator line
    local separator1 = content:CreateTexture(nil, "BACKGROUND")
    separator1:SetColorTexture(1, 1, 1, 0.2)
    separator1:SetPoint("TOPLEFT", calloutsTips, "BOTTOMLEFT", 0, -10)
    separator1:SetPoint("TOPRIGHT", calloutsTips, "BOTTOMRIGHT", 0, -10)
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

    local calloutsCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    calloutsCheckbox:SetPoint("TOPLEFT", separator1, "BOTTOMLEFT", 0, -15)
    calloutsCheckbox.text = calloutsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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

    local eventSoundsCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    eventSoundsCheckbox:SetPoint("TOPLEFT", calloutsCheckbox, "BOTTOMLEFT", 0, -10)
    eventSoundsCheckbox.text = eventSoundsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eventSoundsCheckbox.text:SetPoint("LEFT", eventSoundsCheckbox, "RIGHT", 5, 0)
    eventSoundsCheckbox.text:SetText("Enable Event Sounds")
    eventSoundsCheckbox:SetScript("OnClick", OnToggleEventSounds)
    eventSoundsCheckbox:SetChecked(MissionAccomplishedDB.eventSoundsEnabled ~= false)

    ----------------------------------------------------------------------------
    -- Section 2: XP Bar
    ----------------------------------------------------------------------------
    local xpHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpHeader:SetPoint("TOPLEFT", eventSoundsCheckbox, "BOTTOMLEFT", 0, -30)
    xpHeader:SetText("XP Bar")

    local xpTips = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpTips:SetPoint("TOPLEFT", xpHeader, "BOTTOMLEFT", 0, -8)
    xpTips:SetJustifyH("LEFT")
    xpTips:SetWordWrap(true)
    xpTips:SetWidth(content:GetWidth() - 40)
    xpTips:SetText("|cff00ff00Tips:|r\n" ..
        "• Hold SHIFT and drag the XP Bar to reposition it.\n" ..
        "• The XP Bar displays your progress toward level 60.")

    local separator2 = content:CreateTexture(nil, "BACKGROUND")
    separator2:SetColorTexture(1, 1, 1, 0.2)
    separator2:SetPoint("TOPLEFT", xpTips, "BOTTOMLEFT", 0, -10)
    separator2:SetPoint("TOPRIGHT", xpTips, "BOTTOMRIGHT", 0, -10)
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

    local xpCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    xpCheckbox:SetPoint("TOPLEFT", separator2, "BOTTOMLEFT", 0, -15)
    xpCheckbox.text = xpCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpCheckbox.text:SetPoint("LEFT", xpCheckbox, "RIGHT", 5, 0)
    xpCheckbox.text:SetText("Enable XP Bar")
    xpCheckbox:SetScript("OnClick", OnToggleXPBar)
    xpCheckbox:SetChecked(MissionAccomplishedDB.enableXPBar or false)
    if MissionAccomplishedDB.enableXPBar then
        MissionAccomplished_Bar_SetShown(true)
    end

    ----------------------------------------------------------------------------
    -- Section 3: The Story (added at the bottom)
    ----------------------------------------------------------------------------
    local storyHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    storyHeader:SetPoint("TOPLEFT", xpCheckbox, "BOTTOMLEFT", 0, -30)
    storyHeader:SetText("")

    local storyText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    storyText:SetPoint("TOPLEFT", storyHeader, "BOTTOMLEFT", 0, -8)
    storyText:SetJustifyH("LEFT")
    storyText:SetWordWrap(true)
    storyText:SetWidth(content:GetWidth() - 40)
    storyText:SetText("|cff00ff00A Word from Gavrial:|r\n" ..
"For the everyday player —not some min-maxing junkie— mistakes are just part of the ride. " ..
"Even my character, Gavrial, who made it to level 60, is known as Gavrial the 9th for a reason… " ..
"let’s just say the first eight didn’t quite make it. So take it in stride, laugh off your missteps, " ..
"and enjoy the adventure!")

    ----------------------------------------------------------------------------
    -- Section 4: Gavrials Tips Toggle (below the story)
    ----------------------------------------------------------------------------
    local tipsCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    tipsCheckbox:SetPoint("TOPLEFT", storyText, "BOTTOMLEFT", 0, -15)
    tipsCheckbox.text = tipsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tipsCheckbox.text:SetPoint("LEFT", tipsCheckbox, "RIGHT", 5, 0)
    tipsCheckbox.text:SetText("Enable Gavrials Tips")
    local function OnToggleGavrialsTips(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.enableGavrialsTips = enabled
        if not enabled and GavrialsCall.CancelIdleTipTimer then
            GavrialsCall.CancelIdleTipTimer()
        end
    end
    tipsCheckbox:SetScript("OnClick", OnToggleGavrialsTips)
    tipsCheckbox:SetChecked(MissionAccomplishedDB.enableGavrialsTips or false)

    ----------------------------------------------------------------------------
    -- Settings Frame Show/Hide Behavior
    ----------------------------------------------------------------------------
    content:SetScript("OnShow", function()
        -- When the settings window is shown and if callouts are enabled,
        -- keep the event box up so the user can reposition it.
        if MissionAccomplishedDB.eventFrameEnabled and GavrialsCall and GavrialsCall.Show then
            GavrialsCall.Show(true)
        end
    end)

    content:SetScript("OnHide", function()
        -- When the settings window is closed, revert the event box
        -- to its normal behavior (fade out according to its settings).
        if GavrialsCall then
            GavrialsCall.isPersistent = false
            GavrialsCall.Hide()
        end
    end)

    return scrollFrame
end

_G.SettingsContent = SettingsContent
