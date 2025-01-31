-- About.lua
-- This file defines the content for the "About" tab with enhanced visuals and adjustments for size and greater transparency.

local function AboutContent()
    -- Create the parent frame for the "About" content
    local aboutFrame = CreateFrame("Frame", "MissionAccomplishedAboutFrame", _G.SettingsFrameContent.contentFrame)
    aboutFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame) -- Ensure it fits within the provided content frame
    aboutFrame:SetFrameStrata("DIALOG")

    -- Background texture setup
    local backgroundTexture = aboutFrame:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\RoxyKovu.blp")
    backgroundTexture:SetPoint("CENTER", aboutFrame, "CENTER") -- Center the texture within the frame
    backgroundTexture:SetSize(aboutFrame:GetWidth() * 0.8, aboutFrame:GetHeight() * 0.8) -- Scale it to 80% of the frame size
    backgroundTexture:SetAlpha(0.2) -- 20% transparency for a subtle effect

    -- Adjust the texture's aspect ratio
    backgroundTexture:SetTexCoord(0, 1, 0, 1)

    -- Fallback if texture doesn't load
    if not backgroundTexture:IsShown() then
        print("|cffff0000Warning: RoxyKovu.blp texture not found. Using fallback.|r")
        backgroundTexture:SetTexture("Interface\\Buttons\\WHITE8x8") -- Fallback texture
        backgroundTexture:SetAlpha(0.1) -- Even lighter fallback transparency
    end

    -- Title and content text
    local title = aboutFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", aboutFrame, "TOP", 0, -20)
    title:SetText("|cffffd700MissionAccomplished|r")

    local subtitle = aboutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -10)
    subtitle:SetText("|cff00ff00A Labor of Love by Gavrial|r")

    local body = aboutFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOP", subtitle, "BOTTOM", 0, -20)
    body:SetWidth(aboutFrame:GetWidth() * 0.9) -- Limit text width for readability
    body:SetJustifyH("LEFT")
    body:SetText([[
Welcome, adventurer! Thank you for checking out **MissionAccomplished**, a humble project created by someone who just loves games and wants others to enjoy them even more.

At |cff00ff00RoxyKovu|r, our philosophy is simple: games are more than just entertainment—they’re adventures, connections, and stories waiting to unfold. MissionAccomplished was born out of this love for gaming, with the goal of making every journey in Azeroth even more memorable.

We’re a small team fueled by creativity and passion, and every feature we develop is designed to enhance your experience. Whether you’re tracking your progress, planning your next adventure, or just enjoying the ride, we hope this tool brings a bit of joy and utility to your gaming sessions.

Your feedback and support mean the world to us. If you have suggestions or ideas, please don’t hesitate to reach out. We’re always striving to make things better—for the love of the game.

Thank you for being part of this journey. See you out there, champion!
    ]])

    -- Return the frame so it integrates properly
    return aboutFrame
end

_G.AboutContent = AboutContent
