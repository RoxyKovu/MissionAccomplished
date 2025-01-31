-- stats.lua
-- Stats panel creation and updates for integration with the armory.

local function MahlersStatsContent(parentFrame)
    -- Ensure a valid parent frame is provided
    if not parentFrame then
        print("Error: Parent frame is not provided for stats.")
        return nil
    end

    -- Initialize Saved Variables
    if not MissionAccomplishedDB then
        MissionAccomplishedDB = {}
    end
    local db = MissionAccomplishedDB

    if not db.stats then
        db.stats = {}
    end

    if not db.dpsHistory then
        db.dpsHistory = {}
    end

    if not db.lastBattle then
        db.lastBattle = { totalDamage = 0, duration = 0 }
    end

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

    -- Stats Title
    local statsTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    statsTitle:SetPoint("TOP", statsFrame, "TOP", 0, -10)
    statsTitle:SetText("|cffffd700Character Stats|r")

    -- Item Level (Prominent Display)
    local itemLevelText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemLevelText:SetPoint("TOP", statsFrame, "TOP", 0, -30)
    itemLevelText:SetText("|cffff8000Item Level: |cffffffff0.0|r") -- Placeholder

    -- Table to hold each stat's text element for dynamic updates
    local statElements = {}

    -- Class Icon Coordinates
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
        -- Add other classes similarly
    }

    -- Function to properly case a string (e.g., "HUNTER" -> "Hunter")
    local function ProperCase(str)
        if not str or str == "" then return "" end
        return str:sub(1,1):upper() .. str:sub(2):lower()
    end

    -- Function to get the class icon as a texture string
    local function GetClassIcon(className)
        local proper = ProperCase(className)
        local coords = classIconCoords[proper]
        if coords then
            local tex   = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes.blp"
            local left   = coords.left   * 256
            local right  = coords.right  * 256
            local top    = coords.top    * 256
            local bottom = coords.bottom * 256

            return string.format("|T%s:16:16:0:0:256:256:%.0f:%.0f:%.0f:%.0f|t",
                                 tex, left, right, top, bottom)
        end
        return "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:0:0|t"
    end

    -- Class-Specific Primary Stat Tooltips
    local classStatTooltips = {
        WARRIOR = {
            Strength = "Increases your melee attack power by 2 per point. For example, 10 Strength adds 20 Attack Power, enhancing your weapon damage.",
            Agility = "Improves your critical strike chance and armor. For instance, 20 Agility increases your crit chance by approximately 1% and adds 40 armor.",
            Stamina = "Increases your health by 10 per point. Thus, 5 Stamina grants an additional 50 health.",
            Intellect = "Increases your mana pool, though warriors do not use mana, making this stat generally unimportant.",
            Spirit = "Enhances health regeneration rates outside of combat. Higher Spirit means faster health recovery when not fighting.",
        },
        MAGE = {
            Strength = "Increases your melee attack power by 1 per point. However, as a mage, melee combat is rarely utilized.",
            Agility = "Improves your chance to critically hit with physical attacks and increases armor slightly. Given mages focus on spells, this stat is less beneficial.",
            Stamina = "Increases your health by 10 per point. For example, 5 Stamina provides an extra 50 health, aiding in survivability.",
            Intellect = "Increases your mana by 15 per point and enhances your chance to critically hit with spells. For instance, 59.5 Intellect adds 1% spell crit chance.",
            Spirit = "Boosts your mana regeneration when not casting spells. Higher Spirit allows for quicker mana recovery between casting.",
        },
        HUNTER = {
            Strength = "Increases your melee attack power by 1 per point. While hunters primarily use ranged attacks, this can aid in close combat situations.",
            Agility = "Enhances your ranged attack power by 2 per point, increases critical strike chance, and adds to armor. For example, 20 Agility provides 40 ranged attack power.",
            Stamina = "Increases your health by 10 per point. Thus, 5 Stamina grants an additional 50 health.",
            Intellect = "Increases your mana by 15 per point, allowing for more ability usage.",
            Spirit = "Improves health and mana regeneration rates when not in combat. Higher Spirit means faster recovery.",
        },
        PALADIN = {
            Strength = "Increases your melee attack power by 2 per point. For example, 10 Strength adds 20 Attack Power, boosting your melee damage.",
            Agility = "Improves your chance to critically hit with melee attacks and increases armor. However, the benefit is less significant compared to Strength.",
            Stamina = "Increases your health by 10 per point. For instance, 5 Stamina provides an extra 50 health.",
            Intellect = "Increases your mana by 15 per point, enabling more spellcasting.",
            Spirit = "Enhances health and mana regeneration rates outside of combat. Higher Spirit leads to quicker recovery.",
        },
        ROGUE = {
            Strength = "Increases your melee attack power by 1 per point. While Agility is more critical, Strength still contributes to damage.",
            Agility = "Increases your melee attack power by 1 per point, improves critical strike chance, and adds to armor. For example, 20 Agility provides 20 Attack Power.",
            Stamina = "Increases your health by 10 per point. Thus, 5 Stamina grants an additional 50 health.",
            Intellect = "Not particularly beneficial for rogues, as they do not use mana.",
            Spirit = "Enhances health regeneration rates outside of combat. Higher Spirit means faster health recovery when not fighting.",
        },
        DRUID = {
            Strength = "Increases your melee attack power in Bear and Cat forms. For instance, 10 Strength adds 20 Attack Power in Bear Form.",
            Agility = "Improves your critical strike chance, dodge chance, and armor in Cat Form. For example, 20 Agility increases crit chance and adds 40 armor.",
            Stamina = "Increases your health by 10 per point. Thus, 5 Stamina grants an additional 50 health.",
            Intellect = "Increases your mana by 15 per point, allowing for more spellcasting.",
            Spirit = "Boosts health and mana regeneration rates when not in combat. Higher Spirit leads to quicker recovery.",
        },
        PRIEST = {
            Strength = "Increases your melee attack power by 1 per point. However, priests primarily focus on spells, making this less relevant.",
            Agility = "Improves your chance to critically hit with physical attacks and slightly increases armor. Given priests focus on spells, this stat is less beneficial.",
            Stamina = "Increases your health by 10 per point. For example, 5 Stamina provides an extra 50 health.",
            Intellect = "Increases your mana by 15 per point and enhances your chance to critically hit with spells. For instance, 59.2 Intellect adds 1% spell crit chance.",
            Spirit = "Significantly boosts mana regeneration when not casting spells. Higher Spirit allows for quicker mana recovery between casting.",
        },
        WARLOCK = {
            Strength = "Increases your melee attack power by 1 per point. However, warlocks primarily use spells, making this less relevant.",
            Agility = "Improves your chance to critically hit with physical attacks and slightly increases armor. Given warlocks focus on spells, this stat is less beneficial.",
            Stamina = "Increases your health by 10 per point. For example, 5 Stamina provides an extra 50 health.",
            Intellect = "Increases your mana by 15 per point and enhances your chance to critically hit with spells. For instance, 60.6 Intellect adds 1% spell crit chance.",
            Spirit = "Boosts health and mana regeneration rates when not in combat. Higher Spirit leads to quicker recovery.",
        },
        SHAMAN = {
            Strength = "Increases your melee attack power by 2 per point. For example, 10 Strength adds 20 Attack Power, enhancing your weapon damage.",
            Agility = "Improves your chance to critically hit with melee attacks, increases armor, and enhances dodge chance.",
            Stamina = "Increases your health by 10 per point. Thus, 5 Stamina grants an additional 50 health.",
            Intellect = "Increases your mana by 15 per point, allowing for more spellcasting.",
            Spirit = "Enhances health and mana regeneration rates outside of combat. Higher Spirit means faster recovery.",
        },
        -- Add other classes similarly
    }

    -- Secondary Stat Tooltips
    local secondaryStatTooltips = {
        ["Crit Chance"] = "Increases the chance to deal critical strikes, which deal extra damage.",
        ["Dodge Chance"] = "Increases the chance to dodge incoming attacks, avoiding damage.",
        ["Parry Chance"] = "Increases the chance to parry melee attacks, reducing damage taken.",
        ["Armor"] = "Reduces physical damage taken by increasing your armor value.",
        ["Total DPS"] = "Represents the total damage per second you are dealing.",
        ["Pet Effective Armor"] = "Indicates the armor value of your pet, reducing damage it takes.",
        ["Pet Attack Speed"] = "Shows the average time between your pet's attacks.",
        ["Total Damage Last Battle"] = "The total damage dealt by you and your pet in the last combat session.",
        ["Total Time Last Battle"] = "The duration of the last combat session in seconds.",
    }

    -- Function to get the player's class and localized class name
    local function GetPlayerClassInfo()
        local localizedClass, playerClass = UnitClass("player")
        return localizedClass, playerClass
    end

    -- Combat and Pet Attack Tracking Variables
    local combatStartTime = 0
    local totalDamageDone = 0
    local totalPetDamageDone = 0 -- Initialize pet damage accumulator
    local isInCombat = false

    -- Variables to store last battle's data
    local lastBattleTotalDamage = 0
    local lastBattleDuration = 0

    -- Pet Attack Tracking
    local petAttackIntervals = {}
    local petAttackSpeed = 0
    local petLastAttackTime = nil

    ------------------------------------------------------------
    -- Forward Declarations
    ------------------------------------------------------------
    local UpdateStats
    local EndCombat
    local CalculateDPS
    local RecordPetAttack
    local CreateStatRow
    local InitialUpdate

    ------------------------------------------------------------
    -- Combat Tracking Functions
    ------------------------------------------------------------
    --[[
    function StartCombat()
        isInCombat = true
        combatStartTime = GetTime()
        totalDamageDone = 0 -- Reset damage at the start of combat
    end
    ]]

    function EndCombat()
        if isInCombat then
            isInCombat = false
            -- Calculate combat duration
            lastBattleDuration = GetTime() - combatStartTime
            -- Calculate total damage for last battle
            lastBattleTotalDamage = totalDamageDone + totalPetDamageDone

            -- After combat ends, calculate average pet attack speed
            if #petAttackIntervals > 0 then
                local totalInterval = 0
                for _, interval in ipairs(petAttackIntervals) do
                    totalInterval = totalInterval + interval
                end
                petAttackSpeed = totalInterval / #petAttackIntervals
            else
                petAttackSpeed = 0
            end
            petAttackIntervals = {} -- Clear intervals after calculation

            -- Update stats to reflect last battle
            UpdateStats()

            -- Store last battle data in the database
            db.lastBattle = {
                totalDamage = lastBattleTotalDamage,
                duration = lastBattleDuration,
            }

            -- Reset current battle accumulators
            totalDamageDone = 0
            totalPetDamageDone = 0
            combatStartTime = 0
            lastBattleDuration = 0
            lastBattleTotalDamage = 0
        end
    end

    function CalculateDPS()
        local combatDuration = GetTime() - combatStartTime
        if combatDuration > 0 then
            local combinedDamage = totalDamageDone + totalPetDamageDone
            return combinedDamage / combatDuration
        else
            return 0
        end
    end

    ------------------------------------------------------------
    -- Pet Attack Speed Calculation Function
    ------------------------------------------------------------
    function RecordPetAttack()
        local currentTime = GetTime()
        if petLastAttackTime then
            local interval = currentTime - petLastAttackTime
            table.insert(petAttackIntervals, interval)
            -- Keep only the last 10 intervals to prevent memory issues
            if #petAttackIntervals > 10 then
                table.remove(petAttackIntervals, 1)
            end
        end
        petLastAttackTime = currentTime
    end

    ------------------------------------------------------------
    -- Function to Create Stat Rows with Tooltips
    ------------------------------------------------------------
    function CreateStatRow(parent, label, statKey, xOffset, yOffset)
        local statRow = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statRow:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
        statRow:SetJustifyH("LEFT")
        statRow:SetText(label)
        statRow.statKey = statKey -- Store the stat key for dynamic tooltip updates

        -- Add tooltip functionality
        statRow:EnableMouse(true)
        statRow:SetScript("OnEnter", function(self)
            local localizedClass, playerClass = GetPlayerClassInfo()
            local tooltipText

            -- Check if the stat is a primary or secondary stat
            if classStatTooltips[playerClass] and classStatTooltips[playerClass][self.statKey] then
                tooltipText = classStatTooltips[playerClass][self.statKey]
            elseif secondaryStatTooltips[self.statKey] then
                tooltipText = secondaryStatTooltips[self.statKey]
            else
                tooltipText = "Enhances your abilities."
            end

            -- Set up the tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            -- Add class icon if it's a primary stat
            if classStatTooltips[playerClass] and classStatTooltips[playerClass][self.statKey] then
                local classIcon = GetClassIcon(playerClass)
                if classIcon then
                    GameTooltip:AddLine(classIcon .. " " .. tooltipText, 1, 1, 1, true)
                else
                    GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
                end
            else
                GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        statRow:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return statRow
    end

    ------------------------------------------------------------
    -- Create Stat Rows with Categories
    ------------------------------------------------------------
    local yOffset = -50
    local xOffset = 10

    -- Primary Stats Section
    local primaryTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    primaryTitle:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", xOffset, yOffset)
    primaryTitle:SetText("|cff00ff00Primary Stats|r")

    statElements.strength = CreateStatRow(statsFrame, "Strength: |cffffffff0|r", "Strength", xOffset, yOffset - 15)
    statElements.agility = CreateStatRow(statsFrame, "Agility: |cffffffff0|r", "Agility", xOffset, yOffset - 30)
    statElements.stamina = CreateStatRow(statsFrame, "Stamina: |cffffffff0|r", "Stamina", xOffset, yOffset - 45)
    statElements.intellect = CreateStatRow(statsFrame, "Intellect: |cffffffff0|r", "Intellect", xOffset, yOffset - 60)
    statElements.spirit = CreateStatRow(statsFrame, "Spirit: |cffffffff0|r", "Spirit", xOffset, yOffset - 75)

    -- Secondary Stats Section
    local secondaryTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secondaryTitle:SetPoint("TOPLEFT", statElements.spirit, "BOTTOMLEFT", 0, -15)
    secondaryTitle:SetText("|cff00ffccSecondary Stats|r")

    statElements.critChance = CreateStatRow(statsFrame, "Crit Chance: |cffffffff0.00%%|r", "Crit Chance", xOffset, yOffset - 115)
    statElements.dodgeChance = CreateStatRow(statsFrame, "Dodge: |cffffffff0.00%%|r", "Dodge Chance", xOffset, yOffset - 130)
    statElements.parryChance = CreateStatRow(statsFrame, "Parry: |cffffffff0.00%%|r", "Parry Chance", xOffset, yOffset - 145)
    statElements.armor = CreateStatRow(statsFrame, "Armor: |cffffffff0|r", "Armor", xOffset, yOffset - 160)

    -- Combat Metrics Section
    local combatTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    combatTitle:SetPoint("TOPLEFT", statElements.armor, "BOTTOMLEFT", 0, -15)
    combatTitle:SetText("|cffffff00Combat Metrics|r")

    statElements.totalDPS = CreateStatRow(statsFrame, "Total DPS: |cffffffff0.00|r", "Total DPS", xOffset, yOffset - 200)
    statElements.totalDamageLastBattle = CreateStatRow(statsFrame, "Total Damage Last Battle: |cffffffff0|r", "Total Damage Last Battle", xOffset, yOffset - 215)
    statElements.totalTimeLastBattle = CreateStatRow(statsFrame, "Total Time Last Battle: |cffffffff0.00 sec|r", "Total Time Last Battle", xOffset, yOffset - 230)

    -- Pet Stats Section
    local petTitle = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    petTitle:SetPoint("TOPLEFT", statElements.totalTimeLastBattle, "BOTTOMLEFT", 0, -15)
    petTitle:SetText("|cffffd700Pet Stats|r")

    statElements.petEffectiveArmor = CreateStatRow(statsFrame, "Pet Effective Armor: |cffffffff0|r", "Pet Effective Armor", xOffset, yOffset - 270)
    statElements.petAttackSpeed = CreateStatRow(statsFrame, "Pet Attack Speed: |cffffffff0.00 sec|r", "Pet Attack Speed", xOffset, yOffset - 285)

    -- Initially hide pet stats
    statElements.petEffectiveArmor:Hide()
    statElements.petAttackSpeed:Hide()

    ------------------------------------------------------------
    -- Event Handling for Stats and Combat Tracking
    ------------------------------------------------------------
    statsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    statsFrame:RegisterEvent("UNIT_STATS")
    statsFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    statsFrame:RegisterEvent("UNIT_PET") -- Handles pet summon/dismiss events

    -- Register events related to combat
    -- statsFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat (Removed)
    statsFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leaving combat
    statsFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- Combat log for damage tracking

  statsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        EndCombat()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, spellName, spellSchool, amount, _, _, _, _, _, _, _ = CombatLogGetCurrentEventInfo()

        -- Track damage done by the player and pet
        if (subEvent == "SWING_DAMAGE" or subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE" or subEvent == "RANGE_DAMAGE") then
            -- Player Damage
            if sourceGUID == UnitGUID("player") then
                if not isInCombat then
                    -- Start combat tracking on first damage event (player or pet)
                    isInCombat = true
                    combatStartTime = GetTime()
                    totalDamageDone = 0
                    totalPetDamageDone = 0 -- Reset pet damage at start
                    totalPetAutoAttackDamage = 0 -- Reset pet auto-attack damage
                    totalPetAbilityDamage = 0 -- Reset pet ability damage
                    totalPetDoTDamage = 0 -- Reset pet DoT damage
                    totalPetRangedDamage = 0 -- Reset pet ranged damage
                end
                totalDamageDone = totalDamageDone + (amount or 0)
            end

            -- Pet Damage
            if UnitExists("pet") and sourceGUID == UnitGUID("pet") then
                if not isInCombat then
                    -- Start combat tracking on first damage event (player or pet)
                    isInCombat = true
                    combatStartTime = GetTime()
                    totalDamageDone = 0
                    totalPetDamageDone = 0 -- Reset pet damage at start
                    totalPetAutoAttackDamage = 0 -- Reset pet auto-attack damage
                    totalPetAbilityDamage = 0 -- Reset pet ability damage
                    totalPetDoTDamage = 0 -- Reset pet DoT damage
                    totalPetRangedDamage = 0 -- Reset pet ranged damage
                end

                -- Track individual pet damage types
                if subEvent == "SWING_DAMAGE" then
                    totalPetAutoAttackDamage = (totalPetAutoAttackDamage or 0) + (amount or 0)
                elseif subEvent == "SPELL_DAMAGE" then
                    totalPetAbilityDamage = (totalPetAbilityDamage or 0) + (amount or 0)
                elseif subEvent == "SPELL_PERIODIC_DAMAGE" then
                    totalPetDoTDamage = (totalPetDoTDamage or 0) + (amount or 0)
                elseif subEvent == "RANGE_DAMAGE" then
                    totalPetRangedDamage = (totalPetRangedDamage or 0) + (amount or 0)
                end

                -- Update total pet damage
                totalPetDamageDone = totalPetDamageDone + (amount or 0)

                -- Record the attack interval for pet attack speed calculations
                RecordPetAttack()
            end
        end
    end

    -- Update stats for relevant events
    if event == "PLAYER_ENTERING_WORLD" or
       event == "UNIT_STATS" or
       event == "PLAYER_EQUIPMENT_CHANGED" or
       event == "UNIT_PET" then
        UpdateStats()
    end
end)


    ------------------------------------------------------------
    -- Stats Update Function
    ------------------------------------------------------------
    function UpdateStats()
        -- Calculate and format stats
        local strength_base, strength_total = UnitStat("player", 1)
        local agility_base, agility_total = UnitStat("player", 2)
        local stamina_base, stamina_total = UnitStat("player", 3)
        local intellect_base, intellect_total = UnitStat("player", 4)
        local spirit_base, spirit_total = UnitStat("player", 5)

        local critChance = GetCritChance() or 0
        local dodgeChance = GetDodgeChance() or 0
        local parryChance = GetParryChance()
        local armor = select(2, UnitArmor("player")) or 0

        local dps = CalculateDPS()

        -- Calculate average item level
        local totalItemLevel, equippedItems = 0, 0
        for slot = 1, 19 do
            if slot ~= 4 and slot ~= 19 then -- Ignore Shirt and Tabard
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

        -- Pet Stats
        local petEffectiveArmor = 0
        if UnitExists("pet") then
            local _, petArmor = UnitArmor("pet")
            petEffectiveArmor = petArmor
        end

        -- Update text elements
        itemLevelText:SetText(string.format("|cffff8000Item Level: |cffffffff%.1f|r", averageItemLevel))
        statElements.strength:SetText(string.format("Strength: |cffffffff%d|r", strength_total))
        statElements.agility:SetText(string.format("Agility: |cffffffff%d|r", agility_total))
        statElements.stamina:SetText(string.format("Stamina: |cffffffff%d|r", stamina_total))
        statElements.intellect:SetText(string.format("Intellect: |cffffffff%d|r", intellect_total))
        statElements.spirit:SetText(string.format("Spirit: |cffffffff%d|r", spirit_total))
        statElements.critChance:SetText(string.format("Crit Chance: |cffffffff%.2f%%|r", critChance))
        statElements.dodgeChance:SetText(string.format("Dodge: |cffffffff%.2f%%|r", dodgeChance))
        if parryChance then
            statElements.parryChance:SetText(string.format("Parry: |cffffffff%.2f%%|r", parryChance))
        else
            statElements.parryChance:SetText("Parry: |cffffffffN/A|r")
        end
        statElements.armor:SetText(string.format("Armor: |cffffffff%d|r", armor))
        statElements.totalDPS:SetText(string.format("Total DPS: |cffffffff%.2f|r", dps))

        -- Update Last Battle Metrics
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

        -- Save stats to DB
        db.stats = {
            strength = strength_total,
            agility = agility_total,
            stamina = stamina_total,
            intellect = intellect_total,
            spirit = spirit_total,
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

        -- Save DPS history
        table.insert(db.dpsHistory, { time = time(), dps = dps })
        if #db.dpsHistory > 100 then
            table.remove(db.dpsHistory, 1) -- Keep only the latest 100 entries
        end
    end

    ------------------------------------------------------------
    -- Initial Stats Update
    ------------------------------------------------------------
    function InitialUpdate()
        UpdateStats()

        -- Display saved stats if available
        if db.stats then
            itemLevelText:SetText(string.format("|cffff8000Item Level: |cffffffff%.1f|r", db.stats.averageItemLevel))
            statElements.strength:SetText(string.format("Strength: |cffffffff%d|r", db.stats.strength))
            statElements.agility:SetText(string.format("Agility: |cffffffff%d|r", db.stats.agility))
            statElements.stamina:SetText(string.format("Stamina: |cffffffff%d|r", db.stats.stamina))
            statElements.intellect:SetText(string.format("Intellect: |cffffffff%d|r", db.stats.intellect))
            statElements.spirit:SetText(string.format("Spirit: |cffffffff%d|r", db.stats.spirit))
            statElements.critChance:SetText(string.format("Crit Chance: |cffffffff%.2f%%|r", db.stats.critChance))
            statElements.dodgeChance:SetText(string.format("Dodge: |cffffffff%.2f%%|r", db.stats.dodgeChance))
            if db.stats.parryChance then
                statElements.parryChance:SetText(string.format("Parry: |cffffffff%.2f%%|r", db.stats.parryChance))
            else
                statElements.parryChance:SetText("Parry: |cffffffffN/A|r")
            end
            statElements.armor:SetText(string.format("Armor: |cffffffff%d|r", db.stats.armor))
            statElements.totalDPS:SetText(string.format("Total DPS: |cffffffff%.2f|r", db.stats.dps))

            -- Update Last Battle Metrics
            statElements.totalDamageLastBattle:SetText(string.format("Total Damage Last Battle: |cffffffff%d|r", db.lastBattle.totalDamage))
            statElements.totalTimeLastBattle:SetText(string.format("Total Time Last Battle: |cffffffff%.2f sec|r", db.lastBattle.duration))

            if UnitExists("pet") then
                statElements.petEffectiveArmor:SetText(string.format("Pet Effective Armor: |cffffffff%d|r", db.stats.petEffectiveArmor))
                if db.stats.petAttackSpeed > 0 then
                    statElements.petAttackSpeed:SetText(string.format("Pet Attack Speed: |cffffffff%.2f sec|r", db.stats.petAttackSpeed))
                else
                    statElements.petAttackSpeed:SetText("Pet Attack Speed: |cffffffffN/A|r")
                end
                statElements.petEffectiveArmor:Show()
                statElements.petAttackSpeed:Show()
            else
                statElements.petEffectiveArmor:Hide()
                statElements.petAttackSpeed:Hide()
            end
        end
    end

    InitialUpdate()

    return statsFrame
end

-- Register the function globally for the armory to use
_G.MahlersStatsContent = MahlersStatsContent
