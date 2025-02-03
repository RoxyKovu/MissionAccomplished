---------------------------------------------------------------
-- Full Updated Stats Panel for WoW Classic with Persistent DPS
-- DPS calculations start only when the first hit (player or pet) lands.
---------------------------------------------------------------
local function MahlersStatsContent(parentFrame)
    if not parentFrame then
        print("Error: Parent frame is not provided for stats.")
        return nil
    end

    -- Initialize Saved Variables
    MissionAccomplishedDB = MissionAccomplishedDB or {}
    local db = MissionAccomplishedDB
    db.stats      = db.stats or {}
    db.dpsHistory = db.dpsHistory or {}
    db.lastBattle = db.lastBattle or { totalDamage = 0, duration = 0, averageDPS = 0 }

    -- Create the stats frame
    local statsFrame = CreateFrame("Frame", "MissionAccomplishedStatsFrame", parentFrame, "BackdropTemplate")
    statsFrame:SetSize(300, 700) -- Adjust size as needed
    statsFrame:SetPoint("LEFT", parentFrame, "RIGHT", 50, 20)
    statsFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
    })
    statsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    statsFrame:Hide() -- Start hidden

    -- Stats Title and Item Level display
    local statsTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    statsTitle:SetPoint("TOP", statsFrame, "TOP", 0, -10)
    statsTitle:SetText("|cffffd700Character Stats|r")

    local itemLevelText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemLevelText:SetPoint("TOP", statsFrame, "TOP", 0, -30)
    itemLevelText:SetText("|cffff8000Item Level: |cffffffff0.0|r")

    -- Table to hold each stat's UI element
    local statElements = {}

    -----------------------------------------------------------------------
    -- Class Icon Coordinates
    -----------------------------------------------------------------------
    local classIconCoords = {
        Warrior = { left = 0.00, right = 0.25, top = 0.00, bottom = 0.25 },
        Mage    = { left = 0.25, right = 0.50, top = 0.00, bottom = 0.25 },
        Rogue   = { left = 0.50, right = 0.75, top = 0.00, bottom = 0.25 },
        Druid   = { left = 0.75, right = 1.00, top = 0.00, bottom = 0.25 },
        Hunter  = { left = 0.00, right = 0.25, top = 0.25, bottom = 0.50 },
        Shaman  = { left = 0.25, right = 0.50, top = 0.25, bottom = 0.50 },
        Priest  = { left = 0.50, right = 0.75, top = 0.25, bottom = 0.50 },
        Warlock = { left = 0.75, right = 1.00, top = 0.25, bottom = 0.50 },
        Paladin = { left = 0.00, right = 0.25, top = 0.50, bottom = 0.75 },
    }

    -----------------------------------------------------------------------
    -- Utility Functions
    -----------------------------------------------------------------------
    local function ProperCase(str)
        if not str or str == "" then return "" end
        return str:sub(1,1):upper() .. str:sub(2):lower()
    end

    local function GetClassIcon(className)
        local proper = ProperCase(className)
        local coords = classIconCoords[proper]
        if coords then
            local tex = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes.blp"
            return string.format("|T%s:16:16:0:0:256:256:%.0f:%.0f:%.0f:%.0f|t",
                                 tex, coords.left * 256, coords.right * 256, coords.top * 256, coords.bottom * 256)
        end
        return "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:0:0|t"
    end

    -----------------------------------------------------------------------
    -- Expanded Class-Specific Primary Stat Tooltips
    -----------------------------------------------------------------------
    local classStatTooltips = {
        WARRIOR = {
            Strength = "Increases melee Attack Power by 2 per point. With a shield, every 20 Strength gives a chance to block 1 damage.",
            Agility  = "Gives 2 Armor per point, 1% Crit chance per 20 Agility, and 1% Dodge per 20 Agility.",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "Offers little benefit but can help with weapon skill progression.",
            Spirit   = "Improves out-of-combat Health regeneration.",
        },
        MAGE = {
            Strength = "Minimal benefit as melee is rarely used.",
            Agility  = "Slightly boosts crit chance and dodge, but not a priority.",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "Primary stat: Grants 15 Mana per point and ~1% Spell Crit chance per ~59.5 Intellect.",
            Spirit   = "Enhances Mana regen after 5 seconds (approx. Spirit/4 + 12.5 every 2 sec).",
        },
        HUNTER = {
            Strength = "Adds 1 melee Attack Power per point.",
            Agility  = "Key stat: 2 ranged Attack Power per point, 2 Armor per point, 1% Crit chance per 53 Agility, 1% Dodge per 26 Agility.",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "Provides 15 Mana per point.",
            Spirit   = "Improves Mana regen (roughly Spirit/5 + 15 every 2 sec).",
        },
        PALADIN = {
            Strength = "For Protection/Retribution: +2 melee Attack Power per point; with a shield, 1 damage blocked per 20 Strength.",
            Agility  = "Adds 2 Armor per point, 1% Crit chance per 20 Agility, and 1% Dodge per 20 Agility.",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "For Holy: +15 Mana per point and ~1% Spell Crit chance per ~54 Intellect.",
            Spirit   = "Boosts Mana regen (roughly Spirit/5 + 15 every 2 sec).",
        },
        ROGUE = {
            Strength = "Adds 1 melee Attack Power per point.",
            Agility  = "Primary stat: +1 melee Attack Power per point, 1% Crit chance per 29 Agility, 1% Dodge per 14.5 Agility, and 2 Armor per point.",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "Not a priority.",
            Spirit   = "Improves out-of-combat Health regen.",
        },
        DRUID = {
            Strength = "In Feral form: +2 melee Attack Power per point.",
            Agility  = "In Cat Form: +1 melee Attack Power per point, plus 2 Armor, 1% Crit chance per 20 Agility, 1% Dodge per 20 Agility.",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "For caster druids: +15 Mana per point and ~1% Spell Crit chance per ~60 Intellect.",
            Spirit   = "For casters: Improves Mana regen (approx. Spirit/4.5 + 15 every 2 sec).",
        },
        PRIEST = {
            Strength = "Offers little benefit.",
            Agility  = "Minor improvements in crit and dodge.",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "Primary stat: +15 Mana per point and ~1% Spell Crit chance per ~59.2 Intellect.",
            Spirit   = "Enhances Mana regen after 5 seconds (approx. Spirit/4 + 12.5 every 2 sec).",
        },
        WARLOCK = {
            Strength = "Little benefit; melee is rarely used.",
            Agility  = "Slight improvements in crit and dodge.",
            Stamina  = "Increases Health by 10 per point; also benefits your pet.",
            Intellect= "Primary stat: +15 Mana per point and ~1% Spell Crit chance per ~60.6 Intellect; also boosts pet stats.",
            Spirit   = "Improves Mana regen (roughly Spirit/5 + 15 every 2 sec).",
        },
        SHAMAN = {
            Strength = "For Enhancement: +2 melee Attack Power per point.",
            Agility  = "Provides 2 Armor per point and improves crit/dodge (~1% per 20 Agility).",
            Stamina  = "Increases Health by 10 per point.",
            Intellect= "For Elemental/Restoration: +15 Mana per point and ~1% Spell Crit chance per ~59.5 Intellect.",
            Spirit   = "For Elemental/Restoration: Improves Mana regen (approx. Spirit/5 + 17 every 2 sec).",
        },
    }

    -----------------------------------------------------------------------
    -- Secondary Stat Tooltips
    -----------------------------------------------------------------------
    local secondaryStatTooltips = {
        ["Crit Chance"] = "Increases the chance to deal critical strikes with extra damage.",
        ["Dodge Chance"] = "Increases the chance to completely avoid an incoming attack.",
        ["Parry Chance"] = "Increases the chance to negate a melee attack entirely.",
        ["Armor"] = "Reduces incoming physical damage.",
        ["Total DPS"] = "Total damage per second dealt.",
        ["Pet Effective Armor"] = "The effective Armor value for your pet.",
        ["Pet Attack Speed"] = "Average time between your pet's auto-attacks.",
        ["Total Damage Last Battle"] = "Total damage dealt in your last combat encounter.",
        ["Total Time Last Battle"] = "Duration of the last battle (in seconds).",
    }

    -----------------------------------------------------------------------
    -- Function to get the player's class info
    -----------------------------------------------------------------------
    local function GetPlayerClassInfo()
        local localizedClass, playerClass = UnitClass("player")
        return localizedClass, playerClass
    end

    -----------------------------------------------------------------------
    -- Combat and Pet Tracking Variables
    -----------------------------------------------------------------------
    local combatStartTime = 0
    local totalDamageDone = 0
    local totalPetDamageDone = 0
    local isInCombat = false

    local petAttackIntervals = {}
    local petAttackSpeed = 0
    local petLastAttackTime = nil

    -----------------------------------------------------------------------
    -- Forward Declarations for Update Functions
    -----------------------------------------------------------------------
    local UpdateStats, EndCombatFunc, CalculateDPSFunc, RecordPetAttackFunc, CreateStatRow

    -----------------------------------------------------------------------
    -- Combat Tracking Functions
    -----------------------------------------------------------------------
    local function EndCombatFunc()
        if isInCombat then
            isInCombat = false
            local battleDuration = GetTime() - combatStartTime
            local battleDamage = totalDamageDone + totalPetDamageDone

            local averageDPS = 0
            if battleDuration > 0 then
                averageDPS = battleDamage / battleDuration
            end

            if #petAttackIntervals > 0 then
                local totalInterval = 0
                for _, interval in ipairs(petAttackIntervals) do
                    totalInterval = totalInterval + interval
                end
                petAttackSpeed = totalInterval / #petAttackIntervals
            else
                petAttackSpeed = 0
            end
            petAttackIntervals = {}

            -- Save last battle data for persistence
            db.lastBattle.totalDamage = battleDamage
            db.lastBattle.duration = battleDuration
            db.lastBattle.averageDPS = averageDPS

            -- Reset accumulators
            totalDamageDone = 0
            totalPetDamageDone = 0
            combatStartTime = 0

            UpdateStats()
        end
    end

    local function CalculateDPSFunc()
        if isInCombat then
            local duration = GetTime() - combatStartTime
            if duration > 0 then
                return (totalDamageDone + totalPetDamageDone) / duration
            end
            return 0
        else
            return db.lastBattle.averageDPS or 0
        end
    end

    local function RecordPetAttackFunc()
        local currentTime = GetTime()
        if petLastAttackTime then
            local interval = currentTime - petLastAttackTime
            table.insert(petAttackIntervals, interval)
            if #petAttackIntervals > 10 then
                table.remove(petAttackIntervals, 1)
            end
        end
        petLastAttackTime = currentTime
    end

    -----------------------------------------------------------------------
    -- Function to Create Stat Rows with Expanded Tooltips
    -----------------------------------------------------------------------
    function CreateStatRow(parent, label, statKey, xOffset, yOffset)
        local statRow = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statRow:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
        statRow:SetJustifyH("LEFT")
        statRow:SetText(label)
        statRow.statKey = statKey

        statRow:EnableMouse(true)
        statRow:SetScript("OnEnter", function(self)
            local _, playerClass = GetPlayerClassInfo()
            local tooltipText = (classStatTooltips[playerClass] and classStatTooltips[playerClass][self.statKey])
                                  or secondaryStatTooltips[self.statKey] or "Enhances your abilities."
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if classStatTooltips[playerClass] and classStatTooltips[playerClass][self.statKey] then
                local classIcon = GetClassIcon(playerClass)
                GameTooltip:AddLine(classIcon .. " " .. tooltipText, 1, 1, 1, true)
            else
                GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        statRow:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return statRow
    end

    -----------------------------------------------------------------------
    -- UI Layout: Create Stat Rows for Primary and Secondary Stats
    -----------------------------------------------------------------------
    local yOffset = -50
    local xOffset = 10

    -- Primary Stats Section
    local primaryTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    primaryTitle:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", xOffset, yOffset)
    primaryTitle:SetText("|cff00ff00Primary Stats|r")

    statElements.strength  = CreateStatRow(statsFrame, "Strength: |cffffffff0|r", "Strength", xOffset, yOffset - 15)
    statElements.agility   = CreateStatRow(statsFrame, "Agility: |cffffffff0|r", "Agility", xOffset, yOffset - 30)
    statElements.stamina   = CreateStatRow(statsFrame, "Stamina: |cffffffff0|r", "Stamina", xOffset, yOffset - 45)
    statElements.intellect = CreateStatRow(statsFrame, "Intellect: |cffffffff0|r", "Intellect", xOffset, yOffset - 60)
    statElements.spirit    = CreateStatRow(statsFrame, "Spirit: |cffffffff0|r", "Spirit", xOffset, yOffset - 75)

    -- Secondary Stats Section
    local secondaryTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secondaryTitle:SetPoint("TOPLEFT", statElements.spirit, "BOTTOMLEFT", 0, -15)
    secondaryTitle:SetText("|cff00ffccSecondary Stats|r")

    statElements.critChance   = CreateStatRow(statsFrame, "Crit Chance: |cffffffff0.00%%|r", "Crit Chance", xOffset, yOffset - 115)
    statElements.dodgeChance  = CreateStatRow(statsFrame, "Dodge: |cffffffff0.00%%|r", "Dodge Chance", xOffset, yOffset - 130)
    statElements.parryChance  = CreateStatRow(statsFrame, "Parry: |cffffffff0.00%%|r", "Parry Chance", xOffset, yOffset - 145)
    statElements.armor        = CreateStatRow(statsFrame, "Armor: |cffffffff0|r", "Armor", xOffset, yOffset - 160)

    -- Combat Metrics Section
    local combatTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    combatTitle:SetPoint("TOPLEFT", statElements.armor, "BOTTOMLEFT", 0, -15)
    combatTitle:SetText("|cffffff00Combat Metrics|r")

    statElements.totalDPS             = CreateStatRow(statsFrame, "Total DPS: |cffffffff0.00|r", "Total DPS", xOffset, yOffset - 200)
    statElements.totalDamageLastBattle = CreateStatRow(statsFrame, "Total Damage Last Battle: |cffffffff0|r", "Total Damage Last Battle", xOffset, yOffset - 215)
    statElements.totalTimeLastBattle   = CreateStatRow(statsFrame, "Total Time Last Battle: |cffffffff0.00 sec|r", "Total Time Last Battle", xOffset, yOffset - 230)

    -- Pet Stats Section
    local petTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    petTitle:SetPoint("TOPLEFT", statElements.totalTimeLastBattle, "BOTTOMLEFT", 0, -15)
    petTitle:SetText("|cffffd700Pet Stats|r")

    statElements.petEffectiveArmor = CreateStatRow(statsFrame, "Pet Effective Armor: |cffffffff0|r", "Pet Effective Armor", xOffset, yOffset - 270)
    statElements.petAttackSpeed    = CreateStatRow(statsFrame, "Pet Attack Speed: |cffffffff0.00 sec|r", "Pet Attack Speed", xOffset, yOffset - 285)
    statElements.petEffectiveArmor:Hide()
    statElements.petAttackSpeed:Hide()

    -----------------------------------------------------------------------
    -- Real-Time Update Queue: Throttle updates via OnUpdate
    -----------------------------------------------------------------------
    local updateFrame = CreateFrame("Frame")
    local function QueueStatsUpdate()
        updateFrame:SetScript("OnUpdate", function(self, elapsed)
            self:SetScript("OnUpdate", nil)
            UpdateStats()
        end)
    end

    -----------------------------------------------------------------------
    -- Core Stats Update Function (Real-Time Data Pull)
    -----------------------------------------------------------------------
    function UpdateStats()
        local _, strTotal = UnitStat("player", 1)
        local _, agiTotal = UnitStat("player", 2)
        local _, staTotal = UnitStat("player", 3)
        local _, intTotal = UnitStat("player", 4)
        local _, spiTotal = UnitStat("player", 5)

        local critChance  = GetCritChance() or 0
        local dodgeChance = GetDodgeChance() or 0
        local parryChance = GetParryChance() or 0
        local armor       = select(2, UnitArmor("player")) or 0
        local dps         = CalculateDPSFunc()

        local totalItemLevel, equippedItems = 0, 0
        for slot = 1, 19 do
            if slot ~= 4 and slot ~= 19 then
                local itemLink = GetInventoryItemLink("player", slot)
                if itemLink then
                    local _, _, _, itemLevel = GetItemInfo(itemLink)
                    if itemLevel then
                        totalItemLevel = totalItemLevel + itemLevel
                        equippedItems = equippedItems + 1
                    end
                end
            end
        end
        local averageItemLevel = equippedItems > 0 and (totalItemLevel / equippedItems) or 0

        local petEffectiveArmor = 0
        if UnitExists("pet") then
            local _, pArmor = UnitArmor("pet")
            petEffectiveArmor = pArmor
        end

        itemLevelText:SetText(string.format("|cffff8000Item Level: |cffffffff%.1f|r", averageItemLevel))
        statElements.strength:SetText(string.format("Strength: |cffffffff%d|r", strTotal))
        statElements.agility:SetText(string.format("Agility: |cffffffff%d|r", agiTotal))
        statElements.stamina:SetText(string.format("Stamina: |cffffffff%d|r", staTotal))
        statElements.intellect:SetText(string.format("Intellect: |cffffffff%d|r", intTotal))
        statElements.spirit:SetText(string.format("Spirit: |cffffffff%d|r", spiTotal))
        statElements.critChance:SetText(string.format("Crit Chance: |cffffffff%.2f%%|r", critChance))
        statElements.dodgeChance:SetText(string.format("Dodge: |cffffffff%.2f%%|r", dodgeChance))
        statElements.parryChance:SetText(string.format("Parry: |cffffffff%.2f%%|r", parryChance))
        statElements.armor:SetText(string.format("Armor: |cffffffff%d|r", armor))
        statElements.totalDPS:SetText(string.format("Total DPS: |cffffffff%.2f|r", dps))
        statElements.totalDamageLastBattle:SetText(string.format("Total Damage Last Battle: |cffffffff%d|r", db.lastBattle.totalDamage))
        statElements.totalTimeLastBattle:SetText(string.format("Total Time Last Battle: |cffffffff%.2f sec|r", db.lastBattle.duration))

        if UnitExists("pet") then
            statElements.petEffectiveArmor:SetText(string.format("Pet Effective Armor: |cffffffff%d|r", petEffectiveArmor))
            if petAttackSpeed > 0 then
                statElements.petAttackSpeed:SetText(string.format("Pet Attack Speed: |cffffffff%.2f sec|r", petAttackSpeed))
            else
                statElements.petAttackSpeed:SetText("Pet Attack Speed: |cffffffffN/A|r")
            end
            statElements.petEffectiveArmor:Show()
            statElements.petAttackSpeed:Show()
        else
            statElements.petEffectiveArmor:Hide()
            statElements.petAttackSpeed:Hide()
        end

        -- Save current stats to DB for persistence
        db.stats = {
            strength = strTotal,
            agility = agiTotal,
            stamina = staTotal,
            intellect = intTotal,
            spirit = spiTotal,
            critChance = critChance,
            dodgeChance = dodgeChance,
            parryChance = parryChance,
            armor = armor,
            dps = dps,
            averageItemLevel = averageItemLevel,
            petEffectiveArmor = petEffectiveArmor,
            petAttackSpeed = petAttackSpeed,
            lastBattle = db.lastBattle,
        }

        table.insert(db.dpsHistory, { time = time(), dps = dps })
        if #db.dpsHistory > 100 then
            table.remove(db.dpsHistory, 1)
        end
    end

    -----------------------------------------------------------------------
    -- Event Handling for Real-Time Updates
    -----------------------------------------------------------------------
    local events = {
        "PLAYER_ENTERING_WORLD", "UNIT_STATS", "PLAYER_EQUIPMENT_CHANGED", "UNIT_PET",
        "UNIT_AURA", "PLAYER_DAMAGE_DONE_MODS", "SKILL_LINES_CHANGED", "UPDATE_SHAPESHIFT_FORM",
        "UNIT_DAMAGE", "UNIT_ATTACK_SPEED", "UNIT_RANGEDDAMAGE", "UNIT_ATTACK",
        "UNIT_RESISTANCES", "UNIT_MAXHEALTH", "UNIT_ATTACK_POWER", "UNIT_RANGED_ATTACK_POWER",
        "COMBAT_RATING_UPDATE", "VARIABLES_LOADED"
    }
    for _, event in ipairs(events) do
        statsFrame:RegisterEvent(event)
    end
    statsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- End combat event
    statsFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    statsFrame:SetScript("OnEvent", function(self, event, arg1, ...)
        if (arg1 == "player") or (event ~= "UNIT_DAMAGE" and event ~= "UNIT_ATTACK" and event ~= "UNIT_ATTACK_SPEED") then
            QueueStatsUpdate()
        end

        if event == "PLAYER_ENTERING_WORLD" then
            isInCombat = false
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            QueueStatsUpdate()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local timestamp, subEvent, hideCaster,
                  sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
                  destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount = CombatLogGetCurrentEventInfo()

            if subEvent and (subEvent == "SWING_DAMAGE" or subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE" or subEvent == "RANGE_DAMAGE") then
                if sourceGUID == UnitGUID("player") then
                    if not isInCombat then
                        isInCombat = true
                        combatStartTime = GetTime()
                        totalDamageDone = 0
                        totalPetDamageDone = 0
                    end
                    totalDamageDone = totalDamageDone + (amount or 0)
                elseif UnitExists("pet") and sourceGUID == UnitGUID("pet") then
                    if not isInCombat then
                        isInCombat = true
                        combatStartTime = GetTime()
                        totalDamageDone = 0
                        totalPetDamageDone = 0
                    end
                    totalPetDamageDone = totalPetDamageDone + (amount or 0)
                    RecordPetAttackFunc()
                end
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            EndCombatFunc()
        end
    end)

    -----------------------------------------------------------------------
    -- Perform an initial update and return the stats frame
    -----------------------------------------------------------------------
    UpdateStats()
    return statsFrame
end

-- Expose the function globally for integration
_G.MahlersStatsContent = MahlersStatsContent
