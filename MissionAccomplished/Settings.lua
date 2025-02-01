--=============================================================================
-- Settings.lua
--=============================================================================
-- Creates the settings window UI and integrates the tab content functions.
--=============================================================================

-- Ensure the global "MissionAccomplished" table exists
MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.Settings = MissionAccomplished.Settings or {}
local Settings = MissionAccomplished.Settings

-- Initialize variables
local settingsFrame
local activeTabButton = nil
_G.SettingsFrameContent = {}  -- Global table to share references (used by the toolkit tab)

-- Define content functions
-- Ensure that all content functions are defined and loaded before this point
-- Assuming GavrialCornerContent, NagletsToolkitContent, MahlersArmoryContent, SettingsContent, and AboutContent are defined in their respective files

-- Define tabs. The "Mahler's Armory" tab's content function handles showing or creating the Armory frame.
local menuTabs = {
    { name = "Gavrial's Corner",   contentFunc = GavrialCornerContent },
    { name = "Naglet's Toolkit",   contentFunc = NagletsToolkitContent },
    { 
        name = "Mahler's Armory",    
        contentFunc = function()
            local armoryFrame
            if _G.MissionAccomplishedArmoryFrame then
                armoryFrame = _G.MissionAccomplishedArmoryFrame
                armoryFrame:Show()
            else
                armoryFrame = _G.MahlersArmoryContent()
            end
            return armoryFrame
        end
    },
    { name = "Guild Functions",    contentFunc = _G.MissionAccomplished_GuildContent },  -- Fixed reference
    { name = "Settings",           contentFunc = SettingsContent },
    { name = "About",              contentFunc = AboutContent },
}

-- Function to hide all tab content frames
local function HideAllTabFrames()
    if settingsFrame.contentFrame then
        for _, child in pairs({ settingsFrame.contentFrame:GetChildren() }) do
            if child:IsShown() then
                child:Hide()
            end
        end
    end
    if settingsFrame.toolkitFrame then
        settingsFrame.toolkitFrame:Hide()
    end
    if _G.SettingsFrameContent and _G.SettingsFrameContent.toolkitFrame then
        _G.SettingsFrameContent.toolkitFrame:Hide()
    end
end

-- Generic update function – works the same as for your other tabs.
local function MissionAccomplished_UpdateContent(content, isToolkit)
    if not settingsFrame or not settingsFrame.contentText then
        return
    end
    HideAllTabFrames() -- Hide any previous content

    if isToolkit then
        settingsFrame.contentText:Hide()
        if _G.SettingsFrameContent.toolkitFrame then
            _G.SettingsFrameContent.toolkitFrame:Show()
        else
            content()  -- Call the function directly for toolkit content.
        end
    elseif type(content) == "string" then
        settingsFrame.contentText:SetText(content)
        settingsFrame.contentText:Show()
    elseif type(content) == "table" and content.IsObjectType and content:IsObjectType("Frame") then
        settingsFrame.contentText:Hide()
        content:Show()
    else
        settingsFrame.contentText:SetText("Unable to display content.")
        settingsFrame.contentText:Show()
    end
end

-- Function to set up the settings window UI
local function MissionAccomplished_Settings_Setup()
    if settingsFrame then
        settingsFrame:Show()
        return
    end

    -- Create the main settings frame
    settingsFrame = CreateFrame("Frame", "MissionAccomplishedSettingsFrame", UIParent, "BackdropTemplate")
    settingsFrame:SetSize(750, 600)
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    settingsFrame:SetBackdropColor(0, 0, 0, 0.8)
    settingsFrame:SetClipsChildren(false)

    -- Create the title
    local title = settingsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.ttf", 52, "OUTLINE")
    title:SetPoint("TOP", 0, -20)
    title:SetText("MissionAccomplished")
    title:SetJustifyH("CENTER")

    -- Create the poster texture
    local posterTexture = settingsFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    posterTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavposter.blp")
    posterTexture:SetSize(140, 140)
    posterTexture:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -50, 50)

    -- Apply a mask to the poster texture
    local mask = settingsFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(posterTexture)
    posterTexture:AddMaskTexture(mask)

    -- Create the close button
    local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() settingsFrame:Hide() end)

    -- Create the menu background frame
    local menuBackground = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
    menuBackground:SetSize(180, 500)
    menuBackground:SetPoint("TOPLEFT", 20, -80)
    menuBackground:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    menuBackground:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    -- Create a button for each tab.
    local visibleTabIndex = 0
    for i, tab in ipairs(menuTabs) do
        -- If this is the "Guild Functions" tab and the player is not in a guild, skip it.
        if tab.name == "Guild Functions" and not IsInGuild() then
            -- Optionally, you can print a debug message:
            -- print("Player not in a guild; skipping Guild Functions tab.")
        else
            visibleTabIndex = visibleTabIndex + 1
            local button = CreateFrame("Button", nil, menuBackground, "UIPanelButtonTemplate")
            button:SetSize(160, 40)
            button:SetPoint("TOPLEFT", 10, -10 - (visibleTabIndex - 1) * 50)
            button:SetText(tab.name)
            button.contentFunc = tab.contentFunc

            button:SetScript("OnClick", function(self)
                if activeTabButton and activeTabButton ~= self then
                    activeTabButton:SetNormalFontObject("GameFontNormal")
                end
                activeTabButton = self
                self:SetNormalFontObject("GameFontHighlight")

                HideAllTabFrames()  -- Hide previous content

                -- Debugging: Check if contentFunc exists
                if not self.contentFunc then
                    print("Error: contentFunc is nil for tab '" .. (self:GetText() or "Unknown") .. "'")
                    return
                end

                -- Handle specific tabs
                if self.contentFunc == NagletsToolkitContent then
                    local content = self.contentFunc()
                    MissionAccomplished_UpdateContent(content, true)
                elseif self.contentFunc == menuTabs[3].contentFunc then  -- Mahler's Armory
                    local content = self.contentFunc()
                    if type(content) == "table" and content.armory then
                        -- Create a container to hold both the armory and stats.
                        local container = CreateFrame("Frame", nil, settingsFrame.contentFrame, "BackdropTemplate")
                        container:SetAllPoints(settingsFrame.contentFrame)
                        settingsFrame.contentText:Hide()

                        content.armory:SetParent(container)
                        content.armory:ClearAllPoints()
                        content.armory:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
                        content.armory:Show()

                        if content.stats then
                            content.stats:SetParent(container)
                            content.stats:ClearAllPoints()
                            content.stats:SetPoint("TOPLEFT", content.armory, "BOTTOMLEFT", 0, -10)
                            content.stats:Show()
                        end

                        MissionAccomplished_UpdateContent(container)
                    else
                        MissionAccomplished_UpdateContent(content)
                    end
                else
                    local content = self.contentFunc()
                    MissionAccomplished_UpdateContent(content)
                end
            end)
        end
    end

    -- Create the content frame
    local contentFrame = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
    contentFrame:SetSize(520, 500)
    contentFrame:SetPoint("TOPLEFT", menuBackground, "TOPRIGHT", 20, 0)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    contentFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    -- Create the content text
    local contentText = contentFrame:CreateFontString(nil, "OVERLAY")
    contentText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    contentText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10)
    contentText:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -10, 10)
    contentText:SetJustifyH("LEFT")
    contentText:SetJustifyV("TOP")
    contentText:SetWordWrap(true)
    contentText:SetText("Select a tab to view content.")

    settingsFrame.contentText = contentText
    settingsFrame.contentFrame = contentFrame

    _G.SettingsFrameContent.contentFrame = contentFrame
    _G.SettingsFrameContent.toolkitFrame = nil

    -- Auto-click the first tab to show default content.
    local children = { menuBackground:GetChildren() }
    if #children > 0 and children[1] then
        children[1]:GetScript("OnClick")(children[1])
    end

    settingsFrame:Show()
end

-- Function to toggle the settings window
function MissionAccomplished_ToggleSettings()
    if settingsFrame and settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        MissionAccomplished_Settings_Setup()
    end
end

_G.MissionAccomplished_ToggleSettings = MissionAccomplished_ToggleSettings

-- Register a slash command to open settings
SLASH_MISSIONACCOMPLISHED1 = "/macomp"
SlashCmdList["MISSIONACCOMPLISHED"] = function(msg)
    MissionAccomplished_ToggleSettings()
end
