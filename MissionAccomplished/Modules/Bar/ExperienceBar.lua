-- ExperienceBar.lua
--=============================================================================
-- This file creates and updates the UI XP bar for MissionAccomplished.
-- It shares XP calculation functions with Bar.lua but uses separate frames
-- so that it does not conflict with the moveable XP bar.
-- The progress bar is placed behind the header textures.
--=============================================================================

-- Ensure the main tables exist.
MissionAccomplished = MissionAccomplished or {}
MissionAccomplishedDB = MissionAccomplishedDB or {}

-- Layering configuration variables:
local customFrameStrata = "DIALOG"   -- One of the highest strata available.
local maxFrameLevel = 9999           -- An arbitrarily high frame level.

-- MultiBar offset configuration (adjust these values as desired):
local multiBarBottomLeftYOffset = 10   -- Pixels to move MultiBarBottomLeft upward.
local multiBarBottomRightYOffset = 0   -- Pixels to move MultiBarBottomRight upward.

---------------------------------------------------------------
-- 1) SETUP THE EXPERIENCE HEADER FRAME (UI XP Bar Header)
---------------------------------------------------------------
local basePartWidth = 250   -- Each part's width (4 parts = 1000 total)
local baseTotalWidth = basePartWidth * 4
local baseHeight = 13       -- Header height

-- New dimensions for the progress bar
local progressBarWidth = 990   -- New progress bar width
local progressBarHeight = 10   -- New progress bar height

-- Crop variables (normalized coordinates)
local cropTop = 0.04    -- Crop 4% from the top
local cropBottom = 0.16 -- Crop 16% from the bottom

-- Internal helper function to obtain the overlay texture.
local function UI_GetOverlayTexturePath()
    if ReputationWatchBar 
       and ReputationWatchBar.StatusBar 
       and ReputationWatchBar.StatusBar.XPBarTexture2 then
        return ReputationWatchBar.StatusBar.XPBarTexture2:GetTexture()
    end
    return "Interface\\Buttons\\WHITE8X8"
end

local function UI_SetupExperienceHeader()
    local headerFrame = CreateFrame("Frame", "UIExperienceHeaderFrame", UIParent, "BackdropTemplate")
    headerFrame:SetSize(baseTotalWidth, baseHeight)
    headerFrame:ClearAllPoints()
    -- If the native experience bar exists, position immediately above it; otherwise, center on screen.
    if MainMenuExpBar then
        headerFrame:SetPoint("BOTTOM", MainMenuExpBar, "TOP", 0, 0)  -- No extra vertical offset
    else
        headerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Force our header frame to use the high strata and max frame level.
    headerFrame:SetFrameStrata(customFrameStrata)
    headerFrame:SetFrameLevel(maxFrameLevel)

    headerFrame:SetBackdrop({
        tile = false,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    headerFrame:SetBackdropColor(0, 0, 0, 0.8)
    
    headerFrame:EnableMouse(true)
    headerFrame:SetScript("OnEnter", function(self)
         MissionAccomplished_ExperienceBar_ShowTooltip(self)
    end)
    headerFrame:SetScript("OnLeave", function(self)
         GameTooltip:Hide()
    end)
    
    local overlayPath = UI_GetOverlayTexturePath()
    local parts = {
        { top = 0,     bottom = 0.25 },
        { top = 0.25,  bottom = 0.5 },
        { top = 0.5,   bottom = 0.75 },
        { top = 0.75,  bottom = 1 },
    }
    
    local xOffset = 0
    for i = 1, 4 do
        local j = 5 - i
        local texRegion = headerFrame:CreateTexture(nil, "OVERLAY")
        texRegion:SetTexture(overlayPath)
        local newTop = parts[j].top + cropTop
        local newBottom = parts[j].bottom - cropBottom
        texRegion:SetTexCoord(0, 1, newTop, newBottom)
        texRegion:SetSize(basePartWidth, baseHeight)
        texRegion:SetPoint("LEFT", headerFrame, "LEFT", xOffset, 0)
        xOffset = xOffset + basePartWidth
    end

    headerFrame:Show()
    return headerFrame
end

---------------------------------------------------------------
-- 2) SETUP THE GAVICON ICON FRAME (UI XP Bar Icon)
---------------------------------------------------------------
local function UI_SetupGaviconIcon()
    local iconSize = 32
    local iconFrame = CreateFrame("Frame", "UIExperienceHeaderIconFrame", UIParent, "BackdropTemplate")
    iconFrame:SetSize(iconSize, iconSize)
    iconFrame:ClearAllPoints()
    if UIExperienceHeaderFrame then
         iconFrame:SetPoint("RIGHT", UIExperienceHeaderFrame, "LEFT", 5, 0)
    else
         iconFrame:SetPoint("RIGHT", UIParent, "CENTER", -5, 0)
    end

    -- Force the icon to use the same high strata and max frame level.
    iconFrame:SetFrameStrata(customFrameStrata)
    iconFrame:SetFrameLevel(maxFrameLevel)
    
    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    iconTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp")
    
    iconFrame:EnableMouse(true)
    iconFrame:SetScript("OnEnter", function(self)
         MissionAccomplished_ExperienceBar_ShowTooltip(self)
    end)
    iconFrame:SetScript("OnLeave", function(self)
         GameTooltip:Hide()
    end)
    iconFrame:SetScript("OnMouseUp", function(_, button)
         if button == "LeftButton" then
              MissionAccomplished_ToggleSettings()
         end
    end)
    
    iconFrame:Show()
end

---------------------------------------------------------------
-- 3) SETUP THE UI XP BAR (Separate from Bar.lua)
---------------------------------------------------------------
function MissionAccomplished_ExperienceBar_Setup()
    if MissionAccomplished.uiXPBar then
         return -- Prevent duplicate creation.
    end

    -- Parent the UI XP bar frame to the header so that it appears behind the header textures.
    local parentHeader = UIExperienceHeaderFrame or UI_SetupExperienceHeader()
    local uiXPBarFrame = _G["MissionAccomplishedUIXPBarFrame"] or
         CreateFrame("Frame", "MissionAccomplishedUIXPBarFrame", parentHeader, "BackdropTemplate")
    uiXPBarFrame:SetSize(progressBarWidth, progressBarHeight)
    uiXPBarFrame:SetClampedToScreen(true)
    uiXPBarFrame:EnableMouse(true)
    uiXPBarFrame:ClearAllPoints()
    uiXPBarFrame:SetPoint("CENTER", parentHeader, "CENTER", 0, 0)

    -- Force the XP bar frame to use the same high strata and max frame level.
    uiXPBarFrame:SetFrameStrata(customFrameStrata)
    uiXPBarFrame:SetFrameLevel(maxFrameLevel)

    uiXPBarFrame:SetBackdrop({
         tile = true,
         tileSize = 16,
         edgeSize = 12,
         insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    uiXPBarFrame:SetBackdropColor(0, 0, 0, 0)  -- Fully transparent
    
    local uiXPBar = CreateFrame("StatusBar", "MissionAccomplishedUIXPBar", uiXPBarFrame)
    uiXPBar:SetSize(progressBarWidth, progressBarHeight)
    uiXPBar:SetPoint("CENTER", uiXPBarFrame, "CENTER", 0, 0)
    uiXPBar:SetMinMaxValues(0, 1)
    uiXPBar:SetValue(0.5)  -- Example initial value
    uiXPBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    uiXPBar:SetStatusBarColor(1, 0, 0)  -- Red by default
    uiXPBar:SetFrameLevel(uiXPBarFrame:GetFrameLevel() + 2)
    if uiXPBar.SetStatusBarDrawLayer then
         uiXPBar:SetStatusBarDrawLayer("LOW")
    end
    
    local uiXPTextFrame = CreateFrame("Frame", "MissionAccomplishedUIXPTextFrame", uiXPBar)
    uiXPTextFrame:SetSize(progressBarWidth, progressBarHeight)
    uiXPTextFrame:SetPoint("CENTER", uiXPBar, "CENTER", 0, 0)
    uiXPTextFrame:SetFrameLevel(uiXPBar:GetFrameLevel() + 10)
    uiXPTextFrame:EnableMouse(false)
    
    local uiXPText = uiXPTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    uiXPText:SetPoint("CENTER", uiXPTextFrame, "CENTER", 0, 0)
    uiXPText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    uiXPText:SetText("50% XP")
    
    -- Hide XP text until hover
    uiXPTextFrame:Hide()
    
    -- Save references for later use.
    MissionAccomplished.uiXPBarFrame = uiXPBarFrame
    MissionAccomplished.uiXPBar = uiXPBar
    MissionAccomplished.uiXPTextFrame = uiXPTextFrame
    MissionAccomplished.uiXPText = uiXPText
    
    uiXPBarFrame:SetScript("OnEnter", function(self)
         MissionAccomplished_ExperienceBar_ShowTooltip(self)
         if MissionAccomplished.uiXPTextFrame then
              MissionAccomplished.uiXPTextFrame:Show()
         end
    end)
    uiXPBarFrame:SetScript("OnLeave", function()
         GameTooltip:Hide()
         if MissionAccomplished.uiXPTextFrame then
              MissionAccomplished.uiXPTextFrame:Hide()
         end
    end)
    
    uiXPBarFrame:Show()
end

---------------------------------------------------------------
-- 5) SHOW TOOLTIP FOR UI XP BAR
---------------------------------------------------------------
function MissionAccomplished_ExperienceBar_ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
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
    GameTooltip:AddLine("Click the icon to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

---------------------------------------------------------------
-- 6) UPDATE THE UI XP BAR
---------------------------------------------------------------
function MissionAccomplished_ExperienceBar_Update()
    if not MissionAccomplished.uiXPBar or not MissionAccomplished.uiXPText then
         return
    end

    local xpSoFar = MissionAccomplished.GetTotalXPSoFar()
    local xpMax = MissionAccomplished.GetXPMaxTo60()
    local level = UnitLevel("player") or 1

    if level >= 60 then
         MissionAccomplished.uiXPBar:SetValue(1)
         MissionAccomplished.uiXPBar:SetStatusBarColor(1, 0.84, 0)
         local achievementIcon = "|TInterface\\Icons\\achievement_level_60:16:16:0:0|t"
         MissionAccomplished.uiXPText:SetText("Mission Accomplished " .. achievementIcon)
    else
         local percent = (xpSoFar / xpMax) * 100
         MissionAccomplished.uiXPBar:SetValue(percent / 100)
         MissionAccomplished.uiXPBar:SetStatusBarColor(1, 0, 0)
         local xpLeft = xpMax - xpSoFar
         MissionAccomplished.uiXPText:SetText(string.format("%.1f%% | XP Remaining: %d", percent, xpLeft))
    end
end

---------------------------------------------------------------
-- 7) HOOK XP EVENTS FOR UI XP BAR
---------------------------------------------------------------
local uiEventFrame = CreateFrame("Frame")
uiEventFrame:RegisterEvent("PLAYER_XP_UPDATE")
uiEventFrame:RegisterEvent("PLAYER_LEVEL_UP")
uiEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
uiEventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
         if MissionAccomplished and MissionAccomplished.uiXPTextFrame then
              MissionAccomplished.uiXPTextFrame:Hide()
         end
    end
    if event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" then
         MissionAccomplished_ExperienceBar_Update()
    end
end)

---------------------------------------------------------------
-- 8) INITIALIZATION
---------------------------------------------------------------
local header = UI_SetupExperienceHeader()
UI_SetupGaviconIcon()
MissionAccomplished_ExperienceBar_Setup()
MissionAccomplished_ExperienceBar_Update()

---------------------------------------------------------------
-- 9) TOGGLE FUNCTION FOR UI XP BAR
---------------------------------------------------------------
function MissionAccomplished_ExperienceBar_SetShown(enable)
    if MissionAccomplished.uiXPBarFrame then
        if enable then
            MissionAccomplished.uiXPBarFrame:Show()
        else
            MissionAccomplished.uiXPBarFrame:Hide()
        end
    end

    if UIExperienceHeaderFrame then
        if enable then
            UIExperienceHeaderFrame:Show()
        else
            UIExperienceHeaderFrame:Hide()
        end
    end

    if UIExperienceHeaderIconFrame then
        if enable then
            UIExperienceHeaderIconFrame:Show()
        else
            UIExperienceHeaderIconFrame:Hide()
        end
    end
end

---------------------------------------------------------------
-- 10) ADJUST MULTIBARS (MultiBarBottomLeft & MultiBarBottomRight)
---------------------------------------------------------------
local multiBarAdjustFrame = CreateFrame("Frame")
multiBarAdjustFrame:RegisterEvent("PLAYER_LOGIN")
multiBarAdjustFrame:SetScript("OnEvent", function(self, event)
    -- Delay the adjustment by 0.5 seconds to ensure the default UI has finished anchoring the bars.
    C_Timer.After(0.5, function()
        -- Adjust MultiBarBottomLeft using its absolute position.
        local left = MultiBarBottomLeft:GetLeft() or 0
        local bottom = MultiBarBottomLeft:GetBottom() or 0
        MultiBarBottomLeft:ClearAllPoints()
        MultiBarBottomLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom + multiBarBottomLeftYOffset)

        -- Adjust MultiBarBottomRight using its absolute position.
        local rLeft = MultiBarBottomRight:GetLeft() or 0
        local rBottom = MultiBarBottomRight:GetBottom() or 0
        MultiBarBottomRight:ClearAllPoints()
        MultiBarBottomRight:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", rLeft, rBottom + multiBarBottomRightYOffset)
    end)
end)
