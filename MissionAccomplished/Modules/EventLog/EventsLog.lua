--=============================================================================
-- EventsLog.lua
--=============================================================================
-- Handles the UI for the Events Log tab in the settings window.
--=============================================================================

-- Ensure the global "MissionAccomplished" table exists
MissionAccomplished = MissionAccomplished or {}
MissionAccomplished.EventsLog = MissionAccomplished.EventsLog or {}

local function EventsLogContent()
    -- Create the parent frame for the Events Log content.
    local eventsLogFrame = CreateFrame("Frame", "MissionAccomplishedEventsLogFrame", _G.SettingsFrameContent.contentFrame)
    eventsLogFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame) -- Fit within the provided content frame.
    eventsLogFrame:SetFrameStrata("DIALOG")

    -----------------------------------------------------------------------------
    -- Background Texture Setup (Using UndeadBackground.blp)
    -----------------------------------------------------------------------------
    local backgroundTexture = eventsLogFrame:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\UndeadBackground.blp")
    backgroundTexture:SetPoint("CENTER", eventsLogFrame, "CENTER") -- Center the texture.
    backgroundTexture:SetSize(eventsLogFrame:GetWidth() * 0.8, eventsLogFrame:GetHeight() * 0.8) -- Scale to 80% of the frame size.
    backgroundTexture:SetAlpha(0.2) -- 20% transparency.
    backgroundTexture:SetTexCoord(0, 1, 0, 1)
    
    -- Fallback if texture doesn't load.
    if not backgroundTexture:IsShown() then
        print("|cffff0000Warning: UndeadBackground.blp texture not found. Using fallback.|r")
        backgroundTexture:SetTexture("Interface\\Buttons\\WHITE8x8") -- Fallback texture.
        backgroundTexture:SetAlpha(0.1) -- Even lighter transparency.
    end

    -----------------------------------------------------------------------------
    -- Title (Using provided title format, in blue)
    -----------------------------------------------------------------------------
    local title = eventsLogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", eventsLogFrame, "TOP", 0, -10)
    title:SetFont("Fonts\\MORPHEUS.TTF", 32, "OUTLINE")
    title:SetText("|cff0099FFEvents Log|r")  -- Blue title text

    -----------------------------------------------------------------------------
    -- Subtitle
    -----------------------------------------------------------------------------
    local subtitle = eventsLogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -10)
    subtitle:SetText("|cff00ff00Recording all system and gameplay events|r")

    -----------------------------------------------------------------------------
    -- Scroll Frame Setup for the Log Messages
    -----------------------------------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", "MissionAccomplishedEventsLogScrollFrame", eventsLogFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", eventsLogFrame, "TOPLEFT", 20, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", eventsLogFrame, "BOTTOMRIGHT", -40, 20)

    -- Create a content frame for the scroll frame.
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight())
    scrollFrame:SetScrollChild(content)

    -- Create a FontString to display the log entries.
    local logText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    logText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    logText:SetJustifyH("LEFT")
    logText:SetJustifyV("TOP")
    logText:SetWidth(scrollFrame:GetWidth())
    logText:SetWordWrap(true)

    -----------------------------------------------------------------------------
    -- UpdateLog Method: Refreshes the displayed log content.
    -----------------------------------------------------------------------------
    function eventsLogFrame:UpdateLog()
        local text = ""
        if MissionAccomplished and MissionAccomplished.GavrialsCall and MissionAccomplished.GavrialsCall.messageLog then
            for i, entry in ipairs(MissionAccomplished.GavrialsCall.messageLog) do
                text = text .. entry .. "\n"
            end
        else
            text = "No log messages available."
        end
        logText:SetText(text)
        -- Adjust the content frame's height to match the text.
        content:SetHeight(logText:GetStringHeight())
    end

    -----------------------------------------------------------------------------
    -- Initialize the log display immediately.
    -----------------------------------------------------------------------------
    eventsLogFrame:UpdateLog()

    return eventsLogFrame
end

_G.EventsLogContent = EventsLogContent
