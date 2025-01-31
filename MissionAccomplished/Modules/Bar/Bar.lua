--=============================================================================
-- Bar.lua
--=============================================================================
-- Creates and updates the XP bar for MissionAccomplished, positioned near
-- the player frame. Includes an attached custom icon (gavicon) overlapping on
-- the left. SHIFT+Drag to move. Provides a toggle function to show/hide.
--=============================================================================

MissionAccomplished = MissionAccomplished or {}
MissionAccomplishedDB = MissionAccomplishedDB or {}

---------------------------------------------------------------
-- 1) CREATE THE XP BAR FRAME
---------------------------------------------------------------
function MissionAccomplished_Bar_Setup()
    -- Prevent duplicate bar creation
    if MissionAccomplished.xpBar then
        return
    end

    -- Retrieve or create the XP bar's main frame
    local barFrame = _G["MissionAccomplishedXPBarFrame"]
        or CreateFrame("Frame", "MissionAccomplishedXPBarFrame", UIParent, "BackdropTemplate")
    barFrame:SetSize(190, 16) -- Bar shortened on the right
    barFrame:SetClampedToScreen(true)
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")

    -- SHIFT+Drag to move
    barFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    barFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relPoint, x, y = self:GetPoint()
        MissionAccomplishedDB.xpBar = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    -- Default positioning relative to the PlayerFrame (or load saved)
    if MissionAccomplishedDB.xpBar then
        local pos = MissionAccomplishedDB.xpBar
        barFrame:ClearAllPoints()
        barFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        -- Position above the PlayerFrame (default)
        barFrame:ClearAllPoints()
        barFrame:SetPoint("BOTTOMLEFT", PlayerFrame, "TOPLEFT", -5, 10)
    end

    -- Add a background + border
    barFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    barFrame:SetBackdropColor(0, 0, 0, 0.8)

    -- Create a red StatusBar for XP progress
    local xpBar = CreateFrame("StatusBar", "MissionAccomplishedXPBar", barFrame, "BackdropTemplate")
    xpBar:SetSize(180, 12) -- Slightly smaller for a border effect
    xpBar:SetPoint("CENTER", barFrame, "CENTER", 0, 0)
    xpBar:SetMinMaxValues(0, 1)
    xpBar:SetValue(0)
    xpBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    xpBar:SetStatusBarColor(1, 0, 0) -- Red

    -- XP text
    local xpText = xpBar:CreateFontString("MissionAccomplishedXPText", "OVERLAY", "GameFontHighlight")
    xpText:SetPoint("CENTER", xpBar, "CENTER", 0, 0)
    xpText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE") 
    xpText:SetText("0.0% | XP Remaining: 0") 

    -- Attach icon on the left
    local icon = MissionAccomplished_Bar_AddIcon(barFrame)
    icon:SetPoint("RIGHT", barFrame, "LEFT", 5, 0) 
    icon:SetFrameLevel(barFrame:GetFrameLevel() + 1) 

    -- Tooltip for bar
    barFrame:SetScript("OnEnter", function(self)
        MissionAccomplished_Bar_ShowTooltip(self)
    end)
    barFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Save references
    MissionAccomplished.barFrame = barFrame
    MissionAccomplished.xpBar   = xpBar
    MissionAccomplished.xpText  = xpText

    barFrame:Show()
end

---------------------------------------------------------------
-- 2) ATTACH ICON TO THE XP BAR
---------------------------------------------------------------
function MissionAccomplished_Bar_AddIcon(parent)
    local iconFrame = _G["MissionAccomplishedIconFrame"]
        or CreateFrame("Frame", "MissionAccomplishedIconFrame", parent)
    iconFrame:SetSize(24, 24) 
    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    iconTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp")

    iconFrame:EnableMouse(true)
    iconFrame:SetScript("OnEnter", function(self)
        MissionAccomplished_Bar_ShowTooltip(self)
    end)
    iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    iconFrame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            -- Open your Settings frame
            MissionAccomplished_ToggleSettings()
        end
    end)

    return iconFrame
end

---------------------------------------------------------------
-- 3) SHOW TOOLTIP
---------------------------------------------------------------
function MissionAccomplished_Bar_ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local playerName       = UnitName("player") or "Player"
    local level            = UnitLevel("player") or 0
    local currentXP        = UnitXP("player") or 0
    local xpThisLevel      = UnitXPMax("player") or 1
    local xpSoFar          = MissionAccomplished.GetTotalXPSoFar()
    local xpMax            = MissionAccomplished.GetXPMaxTo60()
    local xpLeft           = xpMax - xpSoFar
    local percentComplete  = (xpSoFar / xpMax) * 100
    local timePlayed       = MissionAccomplished.GetTotalTimePlayed()

    GameTooltip:AddLine("|cff00ff00MissionAccomplished|r")
    GameTooltip:AddLine(playerName .. "'s Journey", 1, 1, 1, true)
    GameTooltip:AddLine("Current Level: " .. level, 1, 1, 1)
    GameTooltip:AddLine(string.format("XP This Level: %d / %d", currentXP, xpThisLevel), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("To Level 60:")
    GameTooltip:AddLine(string.format("Overall Progress: %.1f%%", percentComplete), 1, 1, 1)
    GameTooltip:AddLine(string.format("EXP Needed: %d", xpLeft), 1, 1, 1)
    GameTooltip:AddLine(string.format("Time Played: %s", timePlayed), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Shift + Drag the bar to reposition it.", 1, 1, 1)
    GameTooltip:AddLine("Click the icon to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

---------------------------------------------------------------
-- 4) UPDATE THE XP BAR
---------------------------------------------------------------
function MissionAccomplished_Bar_Update()
    local xpBar  = MissionAccomplished.xpBar
    local xpText = MissionAccomplished.xpText
    if not xpBar or not xpText then
        return
    end

    local xpSoFar = MissionAccomplished.GetTotalXPSoFar()
    local xpMax   = MissionAccomplished.GetXPMaxTo60()

    local percent = (xpSoFar / xpMax) * 100
    local xpLeft  = xpMax - xpSoFar

    xpBar:SetValue(percent / 100)
    xpText:SetText(string.format("%.1f%% | XP Remaining: %d", percent, xpLeft))
end

---------------------------------------------------------------
-- 5) HOOK XP EVENTS
---------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_XP_UPDATE"
       or event == "PLAYER_LEVEL_UP"
       or event == "PLAYER_ENTERING_WORLD"
    then
        MissionAccomplished_Bar_Update()
    end
end)

---------------------------------------------------------------
-- Initialize the XP bar
---------------------------------------------------------------
MissionAccomplished_Bar_Setup()
MissionAccomplished_Bar_Update()

---------------------------------------------------------------
-- 6) TOGGLE FUNCTION FOR SETTINGS
---------------------------------------------------------------
function MissionAccomplished_Bar_SetShown(enable)
    if not MissionAccomplished.barFrame then
        return
    end
    if enable then
        MissionAccomplished.barFrame:Show()
    else
        MissionAccomplished.barFrame:Hide()
    end
end
