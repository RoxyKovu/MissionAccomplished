-- Bar.lua
--=============================================================================
-- Creates and updates the XP bar for MissionAccomplished, positioned near
-- the player frame. Includes an attached custom icon (gavicon) overlapping on
-- the left (which remains visible at all times). SHIFT+Drag to move.
-- Provides a toggle function to show/hide.
--
-- When the player reaches level 60:
--   - The bar fills completely and turns gold.
--   - The text displays "Mission Accomplished" plus the level 60 achievement icon.
--   - The tooltip shows the standard header without the extra achievement icon.
--=============================================================================

MissionAccomplished = MissionAccomplished or {}
MissionAccomplishedDB = MissionAccomplishedDB or {}

local function WaitForMoveableXPBarValue()
    if MissionAccomplishedDB and MissionAccomplishedDB.enableMoveableXPBar ~= nil then
        MissionAccomplished_Bar_SetShown(MissionAccomplishedDB.enableMoveableXPBar)
    else
        C_Timer.After(0.5, WaitForMoveableXPBarValue)  -- Keep checking every 0.5s until the value is found
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        WaitForMoveableXPBarValue() -- Start checking after the world loads
    end
end)


---------------------------------------------------------------
-- 1) CREATE THE XP BAR FRAME
---------------------------------------------------------------
function MissionAccomplished_Bar_Setup()
    -- Prevent duplicate bar creation
    if MissionAccomplished.barFrame then
        return
    end

    local barFrame = _G["MissionAccomplishedXPBarFrame"] or 
        CreateFrame("Frame", "MissionAccomplishedXPBarFrame", UIParent, "BackdropTemplate")
    barFrame:SetSize(190, 16)  -- Bar dimensions
    barFrame:SetClampedToScreen(true)
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")

    barFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    barFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        MissionAccomplishedDB.xpBar = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    if MissionAccomplishedDB.xpBar then
        local pos = MissionAccomplishedDB.xpBar
        barFrame:ClearAllPoints()
        barFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        barFrame:ClearAllPoints()
        barFrame:SetPoint("BOTTOMLEFT", PlayerFrame, "TOPLEFT", 100, -22)
    end

    barFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    barFrame:SetBackdropColor(0, 0, 0, 0.8)

    local xpBar = CreateFrame("StatusBar", "MissionAccomplishedXPBar", barFrame, "BackdropTemplate")
    xpBar:SetSize(180, 12)
    xpBar:SetPoint("CENTER", barFrame, "CENTER", 0, 0)
    xpBar:SetMinMaxValues(0, 1)
    xpBar:SetValue(0)
    xpBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    xpBar:SetStatusBarColor(1, 0, 0)

    local xpText = xpBar:CreateFontString("MissionAccomplishedXPText", "OVERLAY", "GameFontHighlight")
    xpText:SetPoint("CENTER", xpBar, "CENTER", 0, 0)
    xpText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    xpText:SetText("0.0% | XP Remaining: 0")

    local icon = MissionAccomplished_Bar_AddIcon(barFrame)
    icon:SetPoint("RIGHT", barFrame, "LEFT", 5, 0)
    icon:SetFrameLevel(barFrame:GetFrameLevel() + 1)

    barFrame:SetScript("OnEnter", function(self)
        MissionAccomplished_Bar_ShowTooltip(self)
    end)
    barFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    MissionAccomplished.barFrame = barFrame
    MissionAccomplished.xpBar = xpBar
    MissionAccomplished.xpText = xpText

    barFrame:Show()
end

---------------------------------------------------------------
-- 2) ATTACH ICON TO THE XP BAR
---------------------------------------------------------------
function MissionAccomplished_Bar_AddIcon(parent)
    local iconFrame = _G["MissionAccomplishedIconFrame"] or 
        CreateFrame("Frame", "MissionAccomplishedIconFrame", parent)
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
    
    local gavicon = "|TInterface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp:16:16:0:0|t "
    local headerLine = gavicon .. "|cff00ff00MissionAccomplished|r"
    GameTooltip:AddLine(headerLine)
    
    local playerName = UnitName("player") or "Player"
    local level = UnitLevel("player") or 0
    GameTooltip:AddLine(playerName .. "'s Journey", 1, 1, 1, true)
    GameTooltip:AddLine("Current Level: " .. level, 1, 1, 1)
    
    if level < 60 then
        local currentXP = UnitXP("player") or 0
        local xpThisLevel = UnitXPMax("player") or 1
        GameTooltip:AddLine(string.format("XP This Level: %d / %d", currentXP, xpThisLevel), 1, 1, 1)
        
        local xpSoFar = MissionAccomplished.GetTotalXPSoFar()
        local xpMax = MissionAccomplished.GetXPMaxTo60()
        local xpLeft = xpMax - xpSoFar
        local percentComplete = (xpSoFar / xpMax) * 100

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("To Level 60:")
        GameTooltip:AddLine(string.format("Overall Progress: %.1f%%", percentComplete), 1, 1, 1)
        GameTooltip:AddLine(string.format("EXP Needed: %d", xpLeft), 1, 1, 1)
        local timeTo60 = MissionAccomplished.GetTimeToLevel60()
        GameTooltip:AddLine(string.format("Time until level 60: %s", MissionAccomplished.FormatSeconds(timeTo60)), 1, 1, 1)
    else
        local achievementIcon = "|TInterface\\Icons\\achievement_level_60:16:16:0:0|t"
        GameTooltip:AddLine("XP This Level: Mission Accomplished " .. achievementIcon, 1, 1, 1)
    end

    local timePlayed = MissionAccomplished.GetTotalTimePlayed()
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
    local xpBar = MissionAccomplished.xpBar
    local xpText = MissionAccomplished.xpText
    if not xpBar or not xpText then
        return
    end

    local xpSoFar = MissionAccomplished.GetTotalXPSoFar()
    local xpMax = MissionAccomplished.GetXPMaxTo60()
    local level = UnitLevel("player") or 1

    if level >= 60 then
        xpBar:SetValue(1)
        xpBar:SetStatusBarColor(1, 0.84, 0)
        local achievementIcon = "|TInterface\\Icons\\achievement_level_60:16:16:0:0|t"
        xpText:SetText("Mission Accomplished " .. achievementIcon)
    else
        local percent = (xpSoFar / xpMax) * 100
        xpBar:SetValue(percent / 100)
        xpBar:SetStatusBarColor(1, 0, 0)
        local xpLeft = xpMax - xpSoFar
        xpText:SetText(string.format("%.1f%% | XP Remaining: %d", percent, xpLeft))
    end
end

---------------------------------------------------------------
-- 5) HOOK XP EVENTS
---------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" then
        MissionAccomplished_Bar_Update()
    end
end)

---------------------------------------------------------------
-- Initialize the XP bar
---------------------------------------------------------------
MissionAccomplished_Bar_Setup()
MissionAccomplished_Bar_Update()

---------------------------------------------------------------
-- 6) TOGGLE FUNCTION FOR THE MOVEABLE XP BAR
---------------------------------------------------------------
MissionAccomplished_Bar_SetShown = function(enable)
    -- Ensure our saved variable table exists.
    MissionAccomplishedDB = MissionAccomplishedDB or {}
    -- Save the toggle state.
    MissionAccomplishedDB.enableMoveableXPBar = enable

    if not MissionAccomplished.barFrame then
        return
    end

    if enable then
        if MissionAccomplishedDB.xpBar then
            local pos = MissionAccomplishedDB.xpBar
            MissionAccomplished.barFrame:ClearAllPoints()
            MissionAccomplished.barFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
        else
            MissionAccomplished.barFrame:ClearAllPoints()
            MissionAccomplished.barFrame:SetPoint("BOTTOMLEFT", PlayerFrame, "TOPLEFT", 100, -22)
        end
        MissionAccomplished.barFrame:Show()
    else
        MissionAccomplished.barFrame:Hide()
    end
end
_G.MissionAccomplished_Bar_SetShown = MissionAccomplished_Bar_SetShown

---------------------------------------------------------------
-- Apply the saved toggle state on load (after barFrame is created)
---------------------------------------------------------------
MissionAccomplished_Bar_SetShown(MissionAccomplishedDB.enableMoveableXPBar)
