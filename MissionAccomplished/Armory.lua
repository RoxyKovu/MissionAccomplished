--=============================================================================
-- armory.lua
-- Armory frame creation with integrated stats panel and pet model.
-- Enhanced with a custom background image (Armory.blp).
-- The frame now also displays Journey Data (using Core calculation functions)
-- to show overall XP progress, and if at level 60, displays overflow EXP.
-- Additionally, the stats frame is created (or reused) so that combat data is
-- recorded and calculated continuously even when the menu is closed.
--=============================================================================

local function MahlersArmoryContent()
    -- Ensure the parent frame exists
    if not _G.SettingsFrameContent or not _G.SettingsFrameContent.contentFrame then
        print("Error: Parent frame 'SettingsFrameContent.contentFrame' does not exist.")
        return nil
    end

    -- Create the parent frame for the armory
    local armoryFrame = CreateFrame("Frame", "MissionAccomplishedArmoryFrame", _G.SettingsFrameContent.contentFrame, "BackdropTemplate")
    armoryFrame:SetAllPoints(_G.SettingsFrameContent.contentFrame)
    armoryFrame:SetFrameStrata("DIALOG")
    armoryFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
    })
    armoryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    ------------------------------------------------------------
    -- Background Image Integration
    ------------------------------------------------------------
    local backgroundTexture = armoryFrame:CreateTexture(nil, "BACKGROUND")
    backgroundTexture:SetAllPoints(armoryFrame)
    backgroundTexture:SetTexture("Interface\\AddOns\\MissionAccomplished\\Contents\\Armory.blp") -- Ensure the path is correct
    backgroundTexture:SetAlpha(0.2) -- Adjust transparency as needed
    backgroundTexture:SetDrawLayer("BACKGROUND", -1)

    ------------------------------------------------------------
    -- Title
    ------------------------------------------------------------
    local title = armoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", armoryFrame, "TOP", 0, -20)
    title:SetText("|cffffd700Mahler's Armory|r")

    ------------------------------------------------------------
    -- Character Model
    ------------------------------------------------------------
    local characterModel = CreateFrame("PlayerModel", nil, armoryFrame)
    characterModel:SetSize(190, 290)
    characterModel:SetPoint("LEFT", armoryFrame, "LEFT", 50, 0)
    characterModel:SetUnit("player")
    characterModel:SetFacing(0.5)

    ------------------------------------------------------------
    -- Pet Model (if available)
    ------------------------------------------------------------
    local petModel = CreateFrame("PlayerModel", nil, armoryFrame)
    petModel:SetSize(150, 230)
    petModel:SetPoint("LEFT", characterModel, "LEFT", 25, -10) -- Adjusted position to place behind the player
    petModel:SetFacing(0.5)

    local function UpdatePetModel()
        if UnitExists("pet") then
            petModel:SetUnit("pet")
            petModel:Show()
        else
            petModel:Hide()
        end
    end

    petModel:RegisterEvent("PLAYER_ENTERING_WORLD")
    petModel:RegisterEvent("UNIT_PET")
    petModel:SetScript("OnEvent", UpdatePetModel)
    UpdatePetModel()

    ------------------------------------------------------------
    -- Load (or Reparent) Stats Frame (Always created so combat data is updated)
    ------------------------------------------------------------
    local statsFrame
    if _G.MahlersStatsFrame then
        statsFrame = _G.MahlersStatsFrame
        statsFrame:SetParent(armoryFrame)
        statsFrame:ClearAllPoints()
        statsFrame:SetPoint("LEFT", characterModel, "RIGHT", 60, 0)
        statsFrame:Show()
    elseif _G.MahlersStatsContent then
        statsFrame = _G.MahlersStatsContent(armoryFrame)
        _G.MahlersStatsFrame = statsFrame  -- store globally for continuous updates
        statsFrame:SetSize(200, 400) -- Adjust width and height as needed
        statsFrame:SetPoint("LEFT", characterModel, "RIGHT", 60, 0) -- Adjust position as needed
        statsFrame:Show()
    else
        print("Error: Failed to load Mahler's Stats frame.")
    end

    ------------------------------------------------------------
    -- Gear Slot Positions
    ------------------------------------------------------------
    local slotPositions = {
        Head          = { x = -222, y = 150 },
        Neck          = { x = -222, y = 113 },
        Shoulder      = { x = -222, y = 76  },
        Back          = { x = -222, y = 39  },
        Chest         = { x = -222, y = 2   },
        Shirt         = { x = -222, y = -35 },
        Tabard        = { x = -222, y = -72 },
        Wrist         = { x = -222, y = -109},
        Hands         = { x = -28,  y = 150 },
        Waist         = { x = -28,  y = 113 },
        Legs          = { x = -28,  y = 76  },
        Feet          = { x = -28,  y = 39  },
        Finger0       = { x = -28,  y = 2   },
        Finger1       = { x = -28,  y = -35 },
        Trinket0      = { x = -28,  y = -72 },
        Trinket1      = { x = -28,  y = -109},
        MainHand      = { x = -185, y = -119},
        SecondaryHand = { x = -150, y = -119},
        Ranged        = { x = -100, y = -119},
        Ammo          = { x = -65,  y = -119},
    }

    ------------------------------------------------------------
    -- Function to Create Slot Buttons (Icon Handling)
    ------------------------------------------------------------
    local function CreateSlotButtonCommon(slotName, defaultTexture, position)
        local slotButtonSize = 36
        local button = CreateFrame("Button", "MissionAccomplishedSlot" .. slotName, armoryFrame, "ItemButtonTemplate")
        button:SetSize(slotButtonSize, slotButtonSize)
        button:SetPoint("TOPLEFT", armoryFrame, "CENTER", position.x, position.y)
        button:SetFrameLevel(armoryFrame:GetFrameLevel() + 1)

        local function UpdateSlotIcon()
            local inventorySlot = GetInventorySlotInfo(slotName .. "Slot")
            if inventorySlot then
                local itemTexture = GetInventoryItemTexture("player", inventorySlot)
                local icon = _G[button:GetName() .. "IconTexture"]
                if icon then
                    if itemTexture then
                        icon:SetTexture(itemTexture)
                        icon:SetTexCoord(0, 1, 0, 1)
                    else
                        icon:SetTexture(defaultTexture)
                        icon:SetTexCoord(0, 1, 0, 1)
                    end
                    icon:SetDrawLayer("ARTWORK")
                    icon:SetAlpha(1)
                end
            end
        end

        button:HookScript("OnShow", UpdateSlotIcon)
        button:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        button:SetScript("OnEvent", function(_, _, slotID)
            if slotID == GetInventorySlotInfo(slotName .. "Slot") then
                UpdateSlotIcon()
            end
        end)

        button:SetScript("OnEnter", function(self)
            local inventorySlot = GetInventorySlotInfo(slotName .. "Slot")
            if inventorySlot then
                local itemLink = GetInventoryItemLink("player", inventorySlot)
                if itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(itemLink)
                    GameTooltip:Show()
                end
            end
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        UpdateSlotIcon()
        return button
    end

    ------------------------------------------------------------
    -- Create Slot Buttons
    ------------------------------------------------------------
    for slotName, position in pairs(slotPositions) do
        CreateSlotButtonCommon(slotName, "Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. slotName, position)
    end

    ------------------------------------------------------------
    -- (New) Journey Data Panel
    -- Uses Core calculation functions to display overall XP progress.
    ------------------------------------------------------------
    local journeyStats = armoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    journeyStats:SetPoint("BOTTOM", armoryFrame, "BOTTOM", 0, 20)
    journeyStats:SetJustifyH("CENTER")
    local totalXP = MissionAccomplished.GetTotalXPSoFar()
    local xpMax = MissionAccomplished.GetXPMaxTo60()
    local progress = MissionAccomplished.GetProgressPercentage()
    local xpRemaining = xpMax - totalXP
    if UnitLevel("player") >= 60 then
        local overflow = MissionAccomplished.GetOverflowXP()
        if overflow > 0 then
            journeyStats:SetText(string.format("Level 60 complete! Overflow: %d EXP", overflow))
        else
            journeyStats:SetText("Level 60 complete!")
        end
    else
        journeyStats:SetText(string.format("%.1f%% | XP Remaining: %d", progress, xpRemaining))
    end

    return armoryFrame
end

-- Register the function globally for external calls
_G.MahlersArmoryContent = MahlersArmoryContent
