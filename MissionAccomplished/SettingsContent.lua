--=============================================================================
-- SettingsContent.lua
--=============================================================================
-- Sections:
--   1) Event Box (Notifications)
--   2) XP Bar
--   3) Story & Tips
--   4) Other
--=============================================================================

local GavrialsCall = MissionAccomplished.GavrialsCall
local PREFIX = "MissionAcc"

-- 1) HELPER: Create checkboxes for event filters (Entered Instance, Low Health, etc.)
local function CreateEventFilterOptions(parentFrame)
    -- Ensure the DB table for eventFilters exists.
    MissionAccomplishedDB.eventFilters = MissionAccomplishedDB.eventFilters or {
        EnteredInstance = true,
        LowHealth       = true,
        LevelUp         = true,
        GuildDeath      = true,
        MaxLevel        = true,
        Progress        = true,
    }

    local header = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", 20, -60)
    header:SetText("|cff00ff00Event Notifications|r\n\n• Each toggle below lets you choose which types of notifications appear in your Event Box.\n• When checked, you will receive epic notifications for that event type.\n• Unchecking a toggle disables that notification type so you won’t see events like instance entries, low health warnings, level-ups, guild deaths, maximum level announcements, or progress updates.\n\nChoose the notifications you want to see:")

    local filterNames = {
        { label = "Entered Instance", key = "EnteredInstance" },
        { label = "Low Health",       key = "LowHealth" },
        { label = "Level Up",         key = "LevelUp" },
        { label = "Guild Death",      key = "GuildDeath" },
        { label = "Max Level",        key = "MaxLevel" },
        { label = "Progress",         key = "Progress" },
    }

    for i, filter in ipairs(filterNames) do
        local checkbox = CreateFrame("CheckButton", nil, parentFrame, "UICheckButtonTemplate")
        -- Position each checkbox a bit lower than the previous one
        checkbox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -(i - 1) * 25 - 20)
        checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkbox.text:SetText(filter.label)
        checkbox:SetChecked(MissionAccomplishedDB.eventFilters[filter.key])
        checkbox:SetScript("OnClick", function(self)
            -- Toggle this event type in the DB.
            MissionAccomplishedDB.eventFilters[filter.key] = self:GetChecked()
        end)
    end
end

-- 2) MAIN SETTINGS CONTENT FUNCTION
function SettingsContent()
    local parentFrame = _G.SettingsFrameContent.contentFrame

    -- Create the scrollable area
    local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints(parentFrame)
    if scrollFrame.ScrollBar then
        scrollFrame.ScrollBar:ClearAllPoints()
        scrollFrame.ScrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -5, -20)
        scrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -5, 20)
    end

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight() + 50)
    scrollFrame:SetScrollChild(content)
    content:SetFrameStrata("DIALOG")

    local background = content:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(content)
    background:SetColorTexture(0, 0, 0, 0.3)

    -----------------------------------------------------------------------------
    -- SETTINGS TITLE (Morpheus font, 32pt, outlined, white)
    -----------------------------------------------------------------------------
    local settingsTitle = content:CreateFontString(nil, "OVERLAY")
    settingsTitle:SetFont("Fonts\\MORPHEUS.TTF", 32, "OUTLINE")
    settingsTitle:SetPoint("TOP", content, "TOP", 0, -10)
    settingsTitle:SetText("|cffffffffSettings|r")
    settingsTitle:SetJustifyH("CENTER")

    -----------------------------------------------------------------------------
    -- TABS FRAME (Positioned below the title, centered)
    -----------------------------------------------------------------------------
    local tabsFrame = CreateFrame("Frame", nil, content)
    tabsFrame:SetSize(content:GetWidth(), 30)
    tabsFrame:SetPoint("TOP", settingsTitle, "BOTTOM", 0, -20)

    -----------------------------------------------------------------------------
    -- TAB BUTTONS ALONG THE TOP
    -----------------------------------------------------------------------------
    local tabNames = { "Event Box", "XP Bar", "Story & Tips", "Other" }
    local tabButtons = {}
    for i, name in ipairs(tabNames) do
        local btn = CreateFrame("Button", nil, tabsFrame, "UIPanelButtonTemplate")
        btn:SetSize(100, 22)
        btn:SetText(name)
        if i == 1 then
            -- Anchor the first button to the center-left of the tabsFrame.
            btn:SetPoint("LEFT", tabsFrame, "LEFT", 10, 0)
        else
            btn:SetPoint("LEFT", tabButtons[i - 1], "RIGHT", 10, 0)
        end
        tabButtons[i] = btn
    end

    -----------------------------------------------------------------------------
    -- EACH TAB GETS A SEPARATE FRAME (Centered below the tabsFrame)
    -----------------------------------------------------------------------------
    local sectionHeight = content:GetHeight() - (settingsTitle:GetStringHeight() or 32) - tabsFrame:GetHeight() - 10

    local eventBoxFrame = CreateFrame("Frame", nil, content)
    eventBoxFrame:SetSize(content:GetWidth(), sectionHeight)
    eventBoxFrame:SetPoint("TOP", tabsFrame, "BOTTOM", 0, -10)

    local xpBarFrame = CreateFrame("Frame", nil, content)
    xpBarFrame:SetSize(content:GetWidth(), sectionHeight)
    xpBarFrame:SetPoint("TOP", tabsFrame, "BOTTOM", 0, -10)

    local storyFrame = CreateFrame("Frame", nil, content)
    storyFrame:SetSize(content:GetWidth(), sectionHeight)
    storyFrame:SetPoint("TOP", tabsFrame, "BOTTOM", 0, -10)

    local otherFrame = CreateFrame("Frame", nil, content)
    otherFrame:SetSize(content:GetWidth(), sectionHeight)
    otherFrame:SetPoint("TOP", tabsFrame, "BOTTOM", 0, -10)


    --------------------------------------------------------------------------
    -- 1) EVENT BOX TAB (Using a Sub-Frame for Filters)
    --------------------------------------------------------------------------
    local eventHeader = eventBoxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eventHeader:SetPoint("TOPLEFT", 20, -20)
    eventHeader:SetJustifyH("LEFT")
    eventHeader:SetText("Event Box Settings")

    -- Shorter tips, left-justified
    local eventTips = eventBoxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eventTips:SetPoint("TOPLEFT", eventHeader, "BOTTOMLEFT", 0, -6)
    eventTips:SetJustifyH("LEFT")
    eventTips:SetWordWrap(true)
    eventTips:SetWidth(eventBoxFrame:GetWidth() - 40)
    eventTips:SetText("Tips:\n• SHIFT+Drag to move.\n• Sounds play on notify.")

    -- Separator below tips
    local separator1 = eventBoxFrame:CreateTexture(nil, "BACKGROUND")
    separator1:SetColorTexture(1, 1, 1, 0.2)
    separator1:SetPoint("TOPLEFT", eventTips, "BOTTOMLEFT", 0, -8)
    separator1:SetPoint("TOPRIGHT", eventTips, "BOTTOMRIGHT", 0, -8)
    separator1:SetHeight(1)

    --------------------------------------------------------------------------
    -- Enable/Disable the Event Box
    --------------------------------------------------------------------------
    local function OnToggleEventBox(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.eventFrameEnabled = enabled
        if enabled then
            if GavrialsCall and GavrialsCall.Show then
                GavrialsCall:Show(true)
            end
            C_ChatInfo.SendAddonMessage(PREFIX, "EnableEventFrame", "PARTY")
        else
            if GavrialsCall and GavrialsCall.Hide then
                GavrialsCall:Hide()
            end
            C_ChatInfo.SendAddonMessage(PREFIX, "DisableEventFrame", "PARTY")
        end
    end

    local eventBoxCheckbox = CreateFrame("CheckButton", nil, eventBoxFrame, "UICheckButtonTemplate")
    eventBoxCheckbox:SetPoint("TOPLEFT", separator1, "BOTTOMLEFT", 0, -12)
    eventBoxCheckbox.text = eventBoxCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eventBoxCheckbox.text:SetPoint("LEFT", eventBoxCheckbox, "RIGHT", 5, 0)
    eventBoxCheckbox.text:SetJustifyH("LEFT")
    eventBoxCheckbox.text:SetText("Enable Event Box")
    eventBoxCheckbox:SetScript("OnClick", OnToggleEventBox)
    eventBoxCheckbox:SetChecked(MissionAccomplishedDB.eventFrameEnabled or false)
    if MissionAccomplishedDB.eventFrameEnabled and GavrialsCall and GavrialsCall.Show then
        GavrialsCall:Show(true)
    end

    --------------------------------------------------------------------------
    -- Enable/Disable Event Sounds
    --------------------------------------------------------------------------
    local function OnToggleEventSounds(self)
        MissionAccomplishedDB.eventSoundsEnabled = self:GetChecked()
    end

    local eventSoundsCheckbox = CreateFrame("CheckButton", nil, eventBoxFrame, "UICheckButtonTemplate")
    eventSoundsCheckbox:SetPoint("TOPLEFT", eventBoxCheckbox, "BOTTOMLEFT", 0, -10)
    eventSoundsCheckbox.text = eventSoundsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eventSoundsCheckbox.text:SetPoint("LEFT", eventSoundsCheckbox, "RIGHT", 5, 0)
    eventSoundsCheckbox.text:SetJustifyH("LEFT")
    eventSoundsCheckbox.text:SetText("Enable Event Sounds")
    eventSoundsCheckbox:SetScript("OnClick", OnToggleEventSounds)
    eventSoundsCheckbox:SetChecked(MissionAccomplishedDB.eventSoundsEnabled ~= false)

    --------------------------------------------------------------------------
    -- Create a Sub-Frame for Event Filters
    --------------------------------------------------------------------------
    local filtersSubFrame = CreateFrame("Frame", nil, eventBoxFrame, "BackdropTemplate")
    filtersSubFrame:SetSize(eventBoxFrame:GetWidth() - 40, 140)
    filtersSubFrame:SetPoint("TOPLEFT", eventSoundsCheckbox, "BOTTOMLEFT", 0, -16)
    -- Optional: give it a transparent backdrop to see its bounds (remove in production):
    -- filtersSubFrame:SetBackdrop({
    --     bgFile = "Interface\\Buttons\\WHITE8x8",
    --     edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    --     tile = false, edgeSize = 16,
    -- })
    -- filtersSubFrame:SetBackdropColor(0, 0, 0, 0.1)

    local filtersHeader = filtersSubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filtersHeader:SetPoint("TOPLEFT", 0, -2)
    filtersHeader:SetJustifyH("LEFT")
    filtersHeader:SetText("Event Filters:")

    -- We'll define each event filter within this sub-frame
    local filterNames = {
        { label = "Entered Instance", key = "EnteredInstance" },
        { label = "Low Health",       key = "LowHealth" },
        { label = "Level Up",         key = "LevelUp" },
        { label = "Guild Death",      key = "GuildDeath" },
        { label = "Max Level",        key = "MaxLevel" },
        { label = "Progress",         key = "Progress" },
    }

    local yOffset = -20
    for i, filter in ipairs(filterNames) do
        local checkbox = CreateFrame("CheckButton", nil, filtersSubFrame, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", filtersHeader, "BOTTOMLEFT", 0, yOffset)
        checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkbox.text:SetJustifyH("LEFT")
        checkbox.text:SetText(filter.label)
        checkbox:SetChecked(MissionAccomplishedDB.eventFilters and MissionAccomplishedDB.eventFilters[filter.key])
        checkbox:SetScript("OnClick", function(self)
            if not MissionAccomplishedDB.eventFilters then
                MissionAccomplishedDB.eventFilters = {}
            end
            MissionAccomplishedDB.eventFilters[filter.key] = self:GetChecked()
        end)

        yOffset = yOffset - 20  -- move each subsequent checkbox down
    end

    --------------------------------------------------------------------------
    -- 2) XP BAR TAB
    --------------------------------------------------------------------------
    local xpHeader = xpBarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpHeader:SetPoint("TOPLEFT", 20, -20)
    xpHeader:SetText("XP Bar Settings")

    local xpTips = xpBarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpTips:SetPoint("TOPLEFT", xpHeader, "BOTTOMLEFT", 0, -8)
    xpTips:SetJustifyH("LEFT")
    xpTips:SetWordWrap(true)
    xpTips:SetWidth(xpBarFrame:GetWidth() - 40)
    xpTips:SetText("|cff00ff00Tips:|r\n• Hold SHIFT and drag the XP Bar to reposition it.\n• The XP Bar displays your progress toward level 60.")

    local separator2 = xpBarFrame:CreateTexture(nil, "BACKGROUND")
    separator2:SetColorTexture(1, 1, 1, 0.2)
    separator2:SetPoint("TOPLEFT", xpTips, "BOTTOMLEFT", 0, -10)
    separator2:SetPoint("TOPRIGHT", xpTips, "BOTTOMRIGHT", 0, -10)
    separator2:SetHeight(1)

    local function OnToggleMoveableXPBar(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.enableMoveableXPBar = enabled
        if enabled then
            MissionAccomplished_Bar_SetShown(true)
        else
            MissionAccomplished_Bar_SetShown(false)
        end
    end

    local moveableXPCheckbox = CreateFrame("CheckButton", nil, xpBarFrame, "UICheckButtonTemplate")
    moveableXPCheckbox:SetPoint("TOPLEFT", separator2, "BOTTOMLEFT", 0, -15)
    moveableXPCheckbox.text = moveableXPCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    moveableXPCheckbox.text:SetPoint("LEFT", moveableXPCheckbox, "RIGHT", 5, 0)
    moveableXPCheckbox.text:SetText("Enable Moveable XP Bar")
    moveableXPCheckbox:SetScript("OnClick", OnToggleMoveableXPBar)
    moveableXPCheckbox:SetChecked(MissionAccomplishedDB.enableMoveableXPBar or false)
    if MissionAccomplishedDB.enableMoveableXPBar then
        MissionAccomplished_Bar_SetShown(true)
    end

    local function OnToggleUIXPBar(self)
        print("UI XP Bar is coming soon!")
        self:SetChecked(false)
    end

    local uiXPCheckbox = CreateFrame("CheckButton", nil, xpBarFrame, "UICheckButtonTemplate")
    uiXPCheckbox:SetPoint("LEFT", moveableXPCheckbox.text, "RIGHT", 20, 0)
    uiXPCheckbox.text = uiXPCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    uiXPCheckbox.text:SetPoint("LEFT", uiXPCheckbox, "RIGHT", 5, 0)
    uiXPCheckbox.text:SetText("UI XP Bar (Coming Soon)")
    uiXPCheckbox:SetScript("OnClick", OnToggleUIXPBar)
    uiXPCheckbox:SetChecked(false)

    --------------------------------------------------------------------------
    -- 3) STORY & TIPS TAB
    --------------------------------------------------------------------------
    local storyText = storyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    storyText:SetPoint("TOPLEFT", 20, -20)
    storyText:SetJustifyH("LEFT")
    storyText:SetWordWrap(true)
    storyText:SetWidth(storyFrame:GetWidth() - 40)
    storyText:SetText("|cff00ff00A Word from Gavrial:|r\nFor the everyday player – not some min-maxing junkie – mistakes are part of the ride. Even my character, Gavrial the 9th, reached level 60 after many trials. Embrace the journey, laugh off missteps, and enjoy the adventure!")

    local tipsCheckbox = CreateFrame("CheckButton", nil, storyFrame, "UICheckButtonTemplate")
    tipsCheckbox:SetPoint("TOPLEFT", storyText, "BOTTOMLEFT", 0, -15)
    tipsCheckbox.text = tipsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tipsCheckbox.text:SetPoint("LEFT", tipsCheckbox, "RIGHT", 5, 0)
    tipsCheckbox.text:SetText("Enable Gavrial's Tips")
    tipsCheckbox:SetScript("OnClick", function(self)
        local enabled = self:GetChecked()
        MissionAccomplishedDB.enableGavrialsTips = enabled
        if not enabled and GavrialsCall.CancelIdleTipTimer then
            GavrialsCall.CancelIdleTipTimer()
        end
    end)
    tipsCheckbox:SetChecked(MissionAccomplishedDB.enableGavrialsTips or false)

    --------------------------------------------------------------------------
    -- 4) OTHER TAB
    --------------------------------------------------------------------------
    local otherHeader = otherFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    otherHeader:SetPoint("TOPLEFT", 20, -20)
    otherHeader:SetText("Other Settings")

    local otherTips = otherFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    otherTips:SetPoint("TOPLEFT", otherHeader, "BOTTOMLEFT", 0, -8)
    otherTips:SetJustifyH("LEFT")
    otherTips:SetWordWrap(true)
    otherTips:SetWidth(otherFrame:GetWidth() - 40)
    otherTips:SetText("Additional settings and options:")

    local separatorOther = otherFrame:CreateTexture(nil, "BACKGROUND")
    separatorOther:SetColorTexture(1, 1, 1, 0.2)
    separatorOther:SetPoint("TOPLEFT", otherTips, "BOTTOMLEFT", 0, -10)
    separatorOther:SetPoint("TOPRIGHT", otherTips, "BOTTOMRIGHT", 0, -10)
    separatorOther:SetHeight(1)

    local firstTimeToggleCheckbox = CreateFrame("CheckButton", nil, otherFrame, "UICheckButtonTemplate")
    firstTimeToggleCheckbox:SetPoint("TOPLEFT", separatorOther, "BOTTOMLEFT", 0, -15)
    firstTimeToggleCheckbox.text = firstTimeToggleCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    firstTimeToggleCheckbox.text:SetPoint("LEFT", firstTimeToggleCheckbox, "RIGHT", 5, 0)
    firstTimeToggleCheckbox.text:SetText("Show First Time Prompt on Login")
    if MissionAccomplishedDB.showFirstTimePrompt == nil then
        MissionAccomplishedDB.showFirstTimePrompt = false
    end
    firstTimeToggleCheckbox:SetChecked(MissionAccomplishedDB.showFirstTimePrompt)
    firstTimeToggleCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        MissionAccomplishedDB.showFirstTimePrompt = checked
        if checked then
            MissionAccomplishedDB.firstTimeSetup = false
            if MissionAccomplished.ShowFirstTimeUsePrompt then
                MissionAccomplished.ShowFirstTimeUsePrompt()
            else
               -- print("MissionAccomplished.ShowFirstTimeUsePrompt function not found!")
            end
        end
    end)

    --------------------------------------------------------------------------
    -- By default, show the "Event Box" tab. Hide the others.
    --------------------------------------------------------------------------
    eventBoxFrame:Show()
    xpBarFrame:Hide()
    storyFrame:Hide()
    otherFrame:Hide()

    local function SwitchTab(index)
        for i, btn in ipairs(tabButtons) do
            if i == index then
                btn:SetNormalFontObject("GameFontHighlight")
            else
                btn:SetNormalFontObject("GameFontNormal")
            end
        end
        if index == 1 then
            eventBoxFrame:Show()
            xpBarFrame:Hide()
            storyFrame:Hide()
            otherFrame:Hide()
        elseif index == 2 then
            eventBoxFrame:Hide()
            xpBarFrame:Show()
            storyFrame:Hide()
            otherFrame:Hide()
        elseif index == 3 then
            eventBoxFrame:Hide()
            xpBarFrame:Hide()
            storyFrame:Show()
            otherFrame:Hide()
        elseif index == 4 then
            eventBoxFrame:Hide()
            xpBarFrame:Hide()
            storyFrame:Hide()
            otherFrame:Show()
        end
    end

    for i, btn in ipairs(tabButtons) do
        btn:SetScript("OnClick", function()
            SwitchTab(i)
        end)
    end

    -- If the user opens the settings window, we show the event box (if it’s enabled).
    content:SetScript("OnShow", function()
        if MissionAccomplishedDB.eventFrameEnabled and GavrialsCall and GavrialsCall.Show then
            GavrialsCall:Show(true)
        end
    end)

    content:SetScript("OnHide", function()
        if GavrialsCall then
            GavrialsCall.isPersistent = false
            GavrialsCall:Hide()
        end
    end)

    return scrollFrame
end

_G.SettingsContent = SettingsContent

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
        if not MissionAccomplishedDB.firstTimeSetup
           and MissionAccomplishedDB.showFirstTimePrompt
        then
            if MissionAccomplished.ShowFirstTimeUsePrompt then
                MissionAccomplished.ShowFirstTimeUsePrompt()
            else
             --   print("MissionAccomplished.ShowFirstTimeUsePrompt function not found!")
            end
        end
    end)
end)

MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.ShowFirstTimeUsePrompt = MissionAccomplished.ShowFirstTimeUsePrompt or function()
    print("ShowFirstTimeUsePrompt not defined!")
end
