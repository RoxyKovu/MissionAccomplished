--=============================================================================
-- About.lua
-- This file defines the content for the "About" tab with enhanced visuals
-- and adjustments for size and greater transparency.
--=============================================================================

local function AboutContent()
    -- Create the parent frame for the "About" content.
    local aboutFrame = CreateFrame("Frame", "MissionAccomplishedAboutFrame", _G.SettingsFrameContent.contentFrame)
    aboutFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame) -- Fit within the provided content frame.
    aboutFrame:SetFrameStrata("DIALOG")

    -- Background texture setup.
    local backgroundTexture = aboutFrame:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\RoxyKovu.blp")
    backgroundTexture:SetPoint("CENTER", aboutFrame, "CENTER") -- Center the texture.
    backgroundTexture:SetSize(aboutFrame:GetWidth() * 0.8, aboutFrame:GetHeight() * 0.8) -- Scale to 80% of the frame size.
    backgroundTexture:SetAlpha(0.2) -- 20% transparency.
    backgroundTexture:SetTexCoord(0, 1, 0, 1)

    -- Fallback if texture doesn't load.
    if not backgroundTexture:IsShown() then
        print("|cffff0000Warning: RoxyKovu.blp texture not found. Using fallback.|r")
        backgroundTexture:SetTexture("Interface\\Buttons\\WHITE8x8") -- Fallback texture.
        backgroundTexture:SetAlpha(0.1) -- Even lighter transparency.
    end

    -----------------------------------------------------------------------------
    -- Title (Morpheus font, 32pt, outlined, white) with gavicon.blp to its left.
    -----------------------------------------------------------------------------
    local title = aboutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", aboutFrame, "TOP", 10, -10)  -- Slight right offset to make room for the icon.
    title:SetFont("Fonts\\MORPHEUS.TTF", 32, "OUTLINE")
    title:SetText("|cffffffffMissionAccomplished|r")

    -- Create the gavicon texture and position it to the left of the title.
    local icon = aboutFrame:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\gavicon.blp")
    icon:SetSize(32, 32)  -- Adjust the size as needed.
    icon:SetPoint("RIGHT", title, "LEFT", -5, 0)

-----------------------------------------------------------------------------
-- Subtitle and Body Text
-----------------------------------------------------------------------------
local subtitle = aboutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -10)
subtitle:SetText("|cff00ff00Inspired by the many failed trials of Gavrial|r")

local body = aboutFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
body:SetPoint("TOP", subtitle, "BOTTOM", 0, -20)
body:SetWidth(aboutFrame:GetWidth() * 0.9) -- Limit text width for readability.
body:SetJustifyH("LEFT")
body:SetText([[ 
Welcome, adventurer. Thank you for exploring **MissionAccomplished**. This project is the result of extensive experimentation and the hard lessons learned from the many failed trials of Gavrial, all aimed at enhancing the overall player experience.

At |cff00ff00RoxyKovu|r, we believe that games are far more than a mere pastime—they serve as gateways to adventure, foster meaningful connections, and provide the canvas for unforgettable stories. MissionAccomplished was conceived through persistent effort and inspired by the challenges overcome along the way, with the goal of enriching every journey in Azeroth.

Our dedicated team is driven by creativity, resilience, and a deep respect for the gaming community. Every feature is meticulously designed to enhance your experience—whether you are tracking your progress, preparing for your next quest, or simply immersing yourself in the world around you.

We welcome your feedback and suggestions as we continuously strive to refine and improve this tool for all players.

Thank you for being an integral part of this journey. We look forward to welcoming you in Azeroth.
]])


    ---------------------------------------------------------------------
    -- Add Global Addon Users Count at the Bottom of the About Tab
    ---------------------------------------------------------------------
    local userCountFrame = CreateFrame("Frame", nil, aboutFrame)
    userCountFrame:SetSize(220, 20)
    userCountFrame:SetPoint("BOTTOM", aboutFrame, "BOTTOM", 0, 10)

    -- Create a small icon (using a group-looking icon as an example).
    local userIcon = userCountFrame:CreateTexture(nil, "OVERLAY")
    userIcon:SetSize(16, 16)
    userIcon:SetPoint("LEFT", userCountFrame, "LEFT", 0, 0)
    userIcon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")

    -- Create a FontString to show the count.
    local userCountText = userCountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    userCountText:SetPoint("LEFT", userIcon, "RIGHT", 5, 0)
    userCountText:SetText("Addon Users: ?")

    -- Function to update the player count.
    local function UpdateOnlineUserCount()
        local currentTime = time()
        local activePlayerCount = 0

        -- Ensure playerDatabase exists.
        if not playerDatabase or type(playerDatabase) ~= "table" then
            userCountText:SetText("|cffff0000Still parsing information, please come back in 5 minutes|r")
            return
        end

        for name, data in pairs(playerDatabase) do
            local lastSeen = data.lastSeen or 0
            -- Count if the player was seen within the last 10 minutes (600 seconds).
            if (currentTime - lastSeen) <= 600 then
                activePlayerCount = activePlayerCount + 1
            end
        end

        if activePlayerCount > 0 then
            userCountText:SetText("|cff00ff00Addon Users Online in this Faction: " .. activePlayerCount .. "|r")
        else
            userCountText:SetText("|cffff0000Still parsing information, please come back in 5 minutes|r")
        end
    end

    -- Run the update function immediately when the About tab is opened, and set up a ticker.
    aboutFrame:SetScript("OnShow", function()
        -- Cancel any existing timer.
        if aboutFrame.updateTimer then
            aboutFrame.updateTimer:Cancel()
            aboutFrame.updateTimer = nil
        end

        UpdateOnlineUserCount()
        aboutFrame.updateTimer = C_Timer.NewTicker(10, function()
            if aboutFrame:IsShown() then
                UpdateOnlineUserCount()
            end
        end)
    end)

    -- Stop the timer when the About tab is hidden.
    aboutFrame:SetScript("OnHide", function()
        if aboutFrame.updateTimer then
            aboutFrame.updateTimer:Cancel()
            aboutFrame.updateTimer = nil
        end
    end)

    -- Return the frame so it integrates properly with your settings UI.
    return aboutFrame
end

_G.AboutContent = AboutContent
