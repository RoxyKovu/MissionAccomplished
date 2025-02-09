--------------------------------------------------
-- FirstTimeUsePrompt.lua
-- Creates a multi-page first-time use prompt for an addon
-- that enhances the WOW Classic gaming experience.
--
-- Pages:
-- 1. Welcome
-- 2. MissionAccomplished UI
-- 3. Event Notifications
-- 4. XP Bars
-- 5. Gavrial's Corner
-- 6. Naglet's Toolkit
-- 7. Mahler's Armory
-- 8. Guild Dashboard
-- 9. TradeUI
-- 10. Extras: Story & Tips
-- 11. Review Your Choices
--------------------------------------------------

local function ShowFirstTimeUsePrompt()
    -- Only show the prompt if it has not been completed and if the toggle is enabled.
    if MissionAccomplishedDB.firstTimeSetup or (MissionAccomplishedDB.showFirstTimePrompt == false) then
        return
    end

    -- Main explanation frame.
    local ftFrame = CreateFrame("Frame", "MissionAccomplishedFirstTimeFrame", UIParent, "BackdropTemplate")
    ftFrame:SetSize(800, 500)
    ftFrame:SetPoint("CENTER")
    ftFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    ftFrame:SetBackdropColor(0, 0, 0, 1) -- opaque
    ftFrame:SetFrameStrata("DIALOG")
    ftFrame:EnableMouse(true)
    ftFrame:SetMovable(true)
    ftFrame:RegisterForDrag("LeftButton")
    ftFrame:SetScript("OnDragStart", ftFrame.StartMoving)
    ftFrame:SetScript("OnDragStop", ftFrame.StopMovingOrSizing)

    local closeBtn = CreateFrame("Button", nil, ftFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", ftFrame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        MissionAccomplishedDB.firstTimeSetup = true
        MissionAccomplishedDB.showFirstTimePrompt = false
        ftFrame:Hide()
    end)

    local currentPage = 1
    local totalPages = 11

    local titleText = ftFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", ftFrame, "TOP", 0, -20)
    titleText:SetFont("Fonts\\MORPHEUS.TTF", 24, "OUTLINE")
    titleText:SetText("|cffffff00MissionAccomplished|r")

    local bodyText = ftFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bodyText:SetPoint("TOP", titleText, "BOTTOM", 0, -10)
    bodyText:SetPoint("LEFT", ftFrame, "LEFT", 20, 0)
    bodyText:SetPoint("RIGHT", ftFrame, "RIGHT", -240, 0)  -- Reserve space on the right for toggles.
    bodyText:SetHeight(300)
    bodyText:SetJustifyH("LEFT")
    bodyText:SetJustifyV("TOP")
    bodyText:SetWordWrap(true)

    --------------------------------------------------
    -- Create Section Textures (hidden by default)
    --------------------------------------------------
    local gavposterTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    gavposterTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavposter.blp")
    gavposterTexture:SetSize(300, 300)
    gavposterTexture:SetPoint("TOP", bodyText, "BOTTOM", 50, 190)
    gavposterTexture:Hide()

    local gavrialsCornerTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    gavrialsCornerTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\GavrialsCorner.blp")
    gavrialsCornerTexture:SetSize(300, 300)
    gavrialsCornerTexture:SetPoint("TOP", bodyText, "BOTTOM", 300, 190)
    gavrialsCornerTexture:Hide()

    local eventBoxTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    eventBoxTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\EventBox.blp")
    eventBoxTexture:SetSize(500, 500)
    eventBoxTexture:SetPoint("TOP", bodyText, "BOTTOM", 0, 290)
    eventBoxTexture:Hide()

    local xpBarTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    xpBarTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\XPBar.blp")
    xpBarTexture:SetSize(500, 500)
    xpBarTexture:SetPoint("TOP", bodyText, "BOTTOM", 0, 290)
    xpBarTexture:Hide()

    local nagletsToolkitTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    nagletsToolkitTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\NagletsToolkit.blp")
    nagletsToolkitTexture:SetSize(400, 400)
    nagletsToolkitTexture:SetPoint("TOP", bodyText, "BOTTOM", 0, 250)
    nagletsToolkitTexture:Hide()

    local mahlersArmoryTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    mahlersArmoryTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\MahlersArmory.blp")
    mahlersArmoryTexture:SetSize(350, 350)
    mahlersArmoryTexture:SetPoint("TOP", bodyText, "BOTTOM", 200, 210)
    mahlersArmoryTexture:Hide()

    local guildUIText = ftFrame:CreateTexture(nil, "ARTWORK")
    guildUIText:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\GuildUI.blp")
    guildUIText:SetSize(300, 300)
    guildUIText:SetPoint("TOP", bodyText, "BOTTOM", 200, 190)
    guildUIText:Hide()

    local tradeUIText = ftFrame:CreateTexture(nil, "ARTWORK")
    tradeUIText:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\TradeUI.blp")
    tradeUIText:SetSize(500, 500)
    tradeUIText:SetPoint("TOP", bodyText, "BOTTOM", 100, 290)
    tradeUIText:Hide()

    local settingsTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    settingsTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\Settings.blp")
    settingsTexture:SetSize(300, 300)
    settingsTexture:SetPoint("TOP", bodyText, "BOTTOM", 0, 190)
    settingsTexture:Hide()

    local gavTipsTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    gavTipsTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\GavrialsTips.blp")
    gavTipsTexture:SetSize(300, 300)
    gavTipsTexture:SetPoint("TOP", bodyText, "BOTTOM", 0, 190)
    gavTipsTexture:Hide()

    local gavMoonTexture = ftFrame:CreateTexture(nil, "ARTWORK")
    gavMoonTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\GavrialMoon.blp")
    gavMoonTexture:SetSize(400, 400)
    gavMoonTexture:SetPoint("TOP", bodyText, "BOTTOM", 0, 250)
    gavMoonTexture:Hide()

    --------------------------------------------------
    -- Create the Toggles Frame on the right side.
    --------------------------------------------------
    local togglesFrame = CreateFrame("Frame", "MissionAccomplishedTogglesFrame", ftFrame, "BackdropTemplate")
    togglesFrame:SetSize(200, 360)
    togglesFrame:SetPoint("TOPRIGHT", ftFrame, "TOPRIGHT", -20, -60)
    togglesFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    togglesFrame:SetBackdropColor(0, 0, 0, 1)
    togglesFrame:Hide()

    --------------------------------------------------
    -- Create Option Checkboxes (as children of togglesFrame).
    --------------------------------------------------
    local optionCheckboxes = {}

    local eventsBoxCheckbox = CreateFrame("CheckButton", nil, togglesFrame, "UICheckButtonTemplate")
    eventsBoxCheckbox.text = eventsBoxCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eventsBoxCheckbox.text:SetPoint("LEFT", eventsBoxCheckbox, "RIGHT", 5, 0)
    eventsBoxCheckbox.text:SetText("Enable Events Box")
    eventsBoxCheckbox:SetChecked(MissionAccomplishedDB.eventFrameEnabled or false)
    optionCheckboxes.callouts = eventsBoxCheckbox

    local eventSoundsCheckbox = CreateFrame("CheckButton", nil, togglesFrame, "UICheckButtonTemplate")
    eventSoundsCheckbox.text = eventSoundsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    eventSoundsCheckbox.text:SetPoint("LEFT", eventSoundsCheckbox, "RIGHT", 5, 0)
    eventSoundsCheckbox.text:SetText("Enable Event Sounds")
    eventSoundsCheckbox:SetChecked(MissionAccomplishedDB.eventSoundsEnabled ~= false)
    optionCheckboxes.eventSounds = eventSoundsCheckbox

    local moveableXPCheckbox = CreateFrame("CheckButton", nil, togglesFrame, "UICheckButtonTemplate")
    moveableXPCheckbox.text = moveableXPCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    moveableXPCheckbox.text:SetPoint("LEFT", moveableXPCheckbox, "RIGHT", 5, 0)
    moveableXPCheckbox.text:SetText("Enable Moveable XP Bar")
    moveableXPCheckbox:SetChecked(MissionAccomplishedDB.enableMoveableXPBar or false)
    optionCheckboxes.moveableXP = moveableXPCheckbox

local uiXPCheckbox = CreateFrame("CheckButton", nil, togglesFrame, "UICheckButtonTemplate")
uiXPCheckbox.text = uiXPCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
uiXPCheckbox.text:SetPoint("LEFT", uiXPCheckbox, "RIGHT", 5, 0)
uiXPCheckbox.text:SetText("Enable UI XP Bar") -- ✅ Enabled and renamed
uiXPCheckbox:SetChecked(MissionAccomplishedDB.enableUIXPBar or false)
optionCheckboxes.uiXP = uiXPCheckbox


    local tipsCheckbox = CreateFrame("CheckButton", nil, togglesFrame, "UICheckButtonTemplate")
    tipsCheckbox.text = tipsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tipsCheckbox.text:SetPoint("LEFT", tipsCheckbox, "RIGHT", 5, 0)
    tipsCheckbox.text:SetText("Enable Gavrial's Tips")
    tipsCheckbox:SetChecked(MissionAccomplishedDB.enableGavrialsTips or false)
    optionCheckboxes.tips = tipsCheckbox

    --------------------------------------------------
    -- Helper Function: AddTooltip
    --------------------------------------------------
    local function AddTooltip(toggle, tooltipText)
        toggle:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        toggle:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    AddTooltip(eventsBoxCheckbox, "Click to enable or disable the Events Box. Left-click toggles its display.")
    AddTooltip(eventSoundsCheckbox, "Click to enable or disable event sounds for notifications.")
    AddTooltip(moveableXPCheckbox, "Click to enable the moveable XP bar. Once enabled, hold SHIFT and drag the XP bar to reposition it.")
    AddTooltip(uiXPCheckbox, "UI XP Bar is coming soon!")
    AddTooltip(tipsCheckbox, "Click to enable Gavrial's Tips for periodic gameplay advice.")

    --------------------------------------------------
    -- Helper Function: PositionCheckboxes
    --------------------------------------------------
    local function PositionCheckboxes(checkboxList)
        local spacing = 30
        for i, checkbox in ipairs(checkboxList) do
            checkbox:ClearAllPoints()
            checkbox:SetPoint("TOPLEFT", togglesFrame, "TOPLEFT", 10, -10 - ((i - 1) * spacing))
            checkbox:Show()
        end
    end

    --------------------------------------------------
    -- Navigation Buttons
    --------------------------------------------------
    local backButton = CreateFrame("Button", nil, ftFrame, "UIPanelButtonTemplate")
    backButton:SetSize(80, 22)
    backButton:SetPoint("BOTTOMLEFT", ftFrame, "BOTTOMLEFT", 20, 20)
    backButton:SetText("Back")
    backButton:SetScript("OnClick", function(self)
        if currentPage > 1 then
            currentPage = currentPage - 1
            UpdatePage()
        end
    end)

    local nextButton = CreateFrame("Button", nil, ftFrame, "UIPanelButtonTemplate")
    nextButton:SetSize(80, 22)
    nextButton:SetPoint("BOTTOMRIGHT", ftFrame, "BOTTOMRIGHT", -20, 20)
    nextButton:SetText("Next")
-- Function to update toggle settings in real-time when changed
local function ApplyToggleChanges()
    MissionAccomplishedDB.eventFrameEnabled = optionCheckboxes.callouts:GetChecked()
    MissionAccomplishedDB.eventSoundsEnabled = optionCheckboxes.eventSounds:GetChecked()
    MissionAccomplishedDB.enableMoveableXPBar = optionCheckboxes.moveableXP:GetChecked()
    MissionAccomplishedDB.enableUIXPBar = optionCheckboxes.uiXP:GetChecked()
    MissionAccomplishedDB.enableGavrialsTips = optionCheckboxes.tips:GetChecked()

    -- Apply settings in real-time
    if MissionAccomplished_Bar_SetShown then
        MissionAccomplished_Bar_SetShown(MissionAccomplishedDB.enableMoveableXPBar)
    end
    if MissionAccomplished_ExperienceBar_SetShown then
        MissionAccomplished_ExperienceBar_SetShown(MissionAccomplishedDB.enableUIXPBar)
    end
end

-- Ensure checkboxes apply changes immediately on click
for _, checkbox in pairs(optionCheckboxes) do
    checkbox:SetScript("OnClick", ApplyToggleChanges)
end

-- Modify Next Button to save settings properly on finish
nextButton:SetScript("OnClick", function(self)
    if currentPage < totalPages then
        currentPage = currentPage + 1
        UpdatePage()
    else
        -- Ensure final settings are stored
        ApplyToggleChanges()
        MissionAccomplishedDB.firstTimeSetup = true
        MissionAccomplishedDB.showFirstTimePrompt = false
        ftFrame:Hide()
    end
end)


    --------------------------------------------------
    -- UpdatePage: Set text, manage toggles, and show textures.
    --------------------------------------------------
    function UpdatePage()
        -- Hide all toggles and textures first.
        for key, checkbox in pairs(optionCheckboxes) do
            checkbox:Hide()
        end
        togglesFrame:Hide()
        gavposterTexture:Hide()
        gavrialsCornerTexture:Hide()
        eventBoxTexture:Hide()
        xpBarTexture:Hide()
        nagletsToolkitTexture:Hide()
        mahlersArmoryTexture:Hide()
        guildUIText:Hide()
        tradeUIText:Hide()
        settingsTexture:Hide()
        gavTipsTexture:Hide()
        gavMoonTexture:Hide()

        if currentPage == 1 then
            titleText:SetText("Welcome to MissionAccomplished!")
            bodyText:SetText("• Thank you for installing MissionAccomplished.\n\n• This addon enhances the WOW Classic gaming experience by offering a range of features to optimize your gameplay.\n\n• This guide will walk you through the main features and help you customize your experience.")
            gavposterTexture:Show()
        elseif currentPage == 2 then
            titleText:SetText("MissionAccomplished UI")
            bodyText:SetText("• The MissionAccomplished UI provides access to the core features of the addon, including:\n\n   • Gavrial's Corner – Your personal progress report with character info and combat stats.\n\n   • Naglet's Toolkit – Quick in-game tools for ready checks, dice rolls, and more.\n\n   • Mahler's Armory – A custom 3D display of your character and pet, complete with gear slots and combat statistics.\n\n   • Guild Dashboard – Comprehensive management and statistics for your guild.\n\n   • Settings – Additional configuration options.\n\n• Use these features to customize and optimize your gameplay.")
            gavrialsCornerTexture:Show()
        elseif currentPage == 3 then
            titleText:SetText("Event Notifications")
            bodyText:SetText("• To enhance your alertness in WOW Classic (and especially in Hard Core mode), the Event Box provides critical notifications to keep you and your fellow players informed.\n\n• The top-left icon gives quick access to your main MissionAccomplished UI — hover over it to view the latest event message and SHIFT-drag to reposition it.\n\n• To enable the Event Box and its notification sounds, check the boxes on the right.")
            togglesFrame:Show()
            PositionCheckboxes({ optionCheckboxes.callouts, optionCheckboxes.eventSounds })
            eventBoxTexture:Show()
        elseif currentPage == 4 then
            titleText:SetText("XP Bars")
            bodyText:SetText("• Track your XP progress with customizable XP bars.\n\n• Enable a moveable XP bar for personalized positioning (UI XP Bar coming soon).\n\n• Once enabled, hold SHIFT and drag the XP bar to reposition it.")
            togglesFrame:Show()
            PositionCheckboxes({ optionCheckboxes.moveableXP, optionCheckboxes.uiXP })
            xpBarTexture:Show()
elseif currentPage == 5 then
    titleText:SetText("Gavrial's Corner")
    bodyText:SetText("• Gavrial's Corner offers a comprehensive statistical breakdown of your epic journey to level 60.\n\n• Here, you’ll find detailed records of your progress, covering journey milestones, combat performance, and historical achievements.\n\n• Each section is packed with insightful stats designed to help you gauge your success and fine-tune your strategy for the challenges ahead.")
    gavrialsCornerTexture:Show()

        elseif currentPage == 6 then
            titleText:SetText("Naglet's Toolkit")
            bodyText:SetText("• Naglet's Toolkit provides quick access to essential in-game tools. It includes:\n\n   • In-Game Tools: Ready Check, Roll, 10s Timer, and Clear Marks.\n\n   • MissionAccomplished Tools: Reset Combat Data, Test Event Functions, and Send Progress.\n\n   • System Tools: Reload UI, Clear Cache, Show FPS, and Take Screenshot.")
            nagletsToolkitTexture:Show()
        elseif currentPage == 7 then
            titleText:SetText("Mahler's Armory")
            bodyText:SetText("• Mahler's Armory provides a custom window to enhance your gaming experience by:\n\n   • Displaying your 3D character and pet models (or default icons if unequipped).\n\n   • Continuously updating combat stats in a dedicated panel.\n\n   • Presenting your XP progress with percentage and overflow info.")
            mahlersArmoryTexture:Show()
        elseif currentPage == 8 then
            titleText:SetText("Guild Dashboard")
            bodyText:SetText("• The Guild Dashboard enhances your guild management by:\n\n   • Displaying a stylish header with your guild’s name.\n\n   • Providing a refresh button to update the guild roster.\n\n   • Offering a scrollable member list with names, class icons, levels, XP progress, profession icons, and online status.\n\n   • Summarizing key guild stats in a dedicated panel.")
            guildUIText:Show()
        elseif currentPage == 9 then
            titleText:SetText("TradeUI")
            bodyText:SetText("• TradeUI enhances your trading experience in WOW Classic by:\n\n   • Formatting player names properly.\n\n   • Displaying race and class icons.\n\n   • Showing profession icons.\n\n   • Adding extra tooltip data on guild or trade UI elements to help you make informed decisions.")
            tradeUIText:Show()
        elseif currentPage == 10 then
            titleText:SetText("Extras: Story & Tips")
            bodyText:SetText("• |cff00ff00A Word from Gavrial:|r\n    For the everyday player—not some min-maxing junkie—mistakes are part of the ride.\n    Even my character, Gavrial, who reached level 60, is known as Gavrial the 9th for a reason.\n    Take it in stride, laugh off your missteps, and enjoy the adventure.\n\n• Tip: Use the toggle on the right to enable Gavrial's Tips for periodic gameplay advice.")
            togglesFrame:Show()
            PositionCheckboxes({ optionCheckboxes.tips })
            gavTipsTexture:Show()
        elseif currentPage == 11 then
            titleText:SetText("Review Your Choices")
            bodyText:SetText("• Review the options you selected.\n\n• You can change these settings later in the Options menu.\n\n• Click 'Finish' to complete setup.\n\n• Wishing you an epic journey – may your adventures be thrilling and your victories many!")
            togglesFrame:Show()
            PositionCheckboxes({ optionCheckboxes.callouts, optionCheckboxes.eventSounds, optionCheckboxes.moveableXP, optionCheckboxes.uiXP, optionCheckboxes.tips })
            gavMoonTexture:Show()
        end

        if currentPage == 1 then
            backButton:Disable()
        else
            backButton:Enable()
        end

        if currentPage == totalPages then
            nextButton:SetText("Finish")
        else
            nextButton:SetText("Next")
        end
    end

    UpdatePage()
    ftFrame:Show()
end

-- Expose the function globally so other parts of your addon can call it.
_G.ShowFirstTimeUsePrompt = ShowFirstTimeUsePrompt
MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.ShowFirstTimeUsePrompt = ShowFirstTimeUsePrompt
