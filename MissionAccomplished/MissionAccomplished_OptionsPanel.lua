--=============================================================================
-- MissionAccomplished_OptionsPanel.lua (Fixed for WoW Classic Era, With Artwork & Menu Closing)
--=============================================================================

local addOnName, MissionAccomplished = ...

-- Create the main parent frame
local panel = CreateFrame("Frame", "MissionAccomplishedOptionsPanel", UIParent)
panel.name = "MissionAccomplished"  -- Name shown in Interface → AddOns

-- Manually Register Panel for Classic UI
local category = SettingsPanel and Settings.RegisterCanvasLayoutCategory and Settings.RegisterCanvasLayoutCategory(panel, "MissionAccomplished")
if category then
    Settings.RegisterAddOnCategory(category)
end

-- Create a child frame inside the panel
local container = CreateFrame("Frame", nil, panel)
container:SetSize(450, 180)  -- Increased height for new elements
container:SetPoint("CENTER", 16, -16)

-- Manually add background (Fix for removed SetBackdrop())
local bgTexture = container:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints()
bgTexture:SetColorTexture(0.1, 0.1, 0.1, 0.9)  -- Dark background

-- Create the poster texture (Addon Artwork)
local posterTexture = container:CreateTexture(nil, "ARTWORK", nil, -1)
posterTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavposter.blp")
posterTexture:SetSize(140, 140)
posterTexture:SetPoint("TOPLEFT", container, "TOPLEFT", -50, 50)

-- Title Text
local title = container:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 100, -16)  -- Adjusted to not overlap with artwork
title:SetText("MissionAccomplished")

-- Description Text (Updated Description)
local description = container:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
description:SetWidth(280) -- Adjust width to avoid overlapping the poster
description:SetJustifyH("LEFT")
description:SetText("A comprehensive Hardcore add-on with various enhancements to improve gameplay.\n\n\n          Developed by RoxyKovu.")

-- Developer Logo (Scaled Properly)
local devLogo = container:CreateTexture(nil, "ARTWORK")
devLogo:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\RoxyKovu.blp")
devLogo:SetSize(24, 24)  -- Scaled down for a clean fit
devLogo:SetPoint("TOPLEFT", description, "LEFT", 0, -10)  -- Positioned under the developer name

-- Open Settings Button
local openSettingsBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
openSettingsBtn:SetSize(160, 30)
openSettingsBtn:SetPoint("TOPLEFT", devLogo, "BOTTOMLEFT", 0, -10)  -- Adjusted position
openSettingsBtn:SetText("Open Settings")

-- Button Click: Close WoW UI and Open Settings
openSettingsBtn:SetScript("OnClick", function()
    -- Completely Close the WoW Main Menu
    if GameMenuFrame:IsShown() then
        ToggleGameMenu()  -- Pressing Escape Effect
    end

    -- Also Close Interface Options if Open
    HideUIPanel(InterfaceOptionsFrame)

    -- Open the Addon Settings
    if MissionAccomplished_ToggleSettings and type(MissionAccomplished_ToggleSettings) == "function" then
        MissionAccomplished_ToggleSettings()
    else
        print("|cffff0000MissionAccomplished_ToggleSettings() not found!|r")
    end
end)

-- Slash Command to Open Options Panel Directly
SLASH_MISSIONACCOMPLISHEDOPTIONS1 = "/maopts"
SlashCmdList["MISSIONACCOMPLISHEDOPTIONS"] = function(msg)
    -- Ensure the panel is registered
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)  -- Call twice due to Blizzard bug
end
