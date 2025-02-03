--[[
    RoxyKovus Profession Library - WoW Classic Profession Utility Library
    ---------------------------------------------------------------------
    This library provides functions to retrieve profession data in WoW Classic.

    USAGE:
    - To get the player's professions:
        local prof1, prof2, fishing, cooking, firstAid = RoxyKovusProfLib:GetProfessions()

    - To get detailed info about a profession:
        local profData = RoxyKovusProfLib:GetProfessionInfo(prof1)
        if profData then
            print("Profession:", profData.name, "Level:", profData.level, "/", profData.maxLevel)
            -- You can use profData.icon to display the profession icon.
        end

    Place this file in your addon folder and ensure it is loaded before calling its functions.
]]--

-- Create a global table for the library
RoxyKovusProfLib = {}

RoxyKovusProfLib.PROFESSION_FIRST_INDEX = 1
RoxyKovusProfLib.PROFESSION_SECOND_INDEX = 2
RoxyKovusProfLib.PROFESSION_FISHING_INDEX = 3
RoxyKovusProfLib.PROFESSION_COOKING_INDEX = 4
RoxyKovusProfLib.PROFESSION_FIRST_AID_INDEX = 5

local GetNumSkillLines, GetSkillLineInfo = GetNumSkillLines, GetSkillLineInfo
local FindSpellBookSlotBySpellID, GetSpellBookItemTexture = FindSpellBookSlotBySpellID, GetSpellBookItemTexture

-- Updated Profession Icons using WoW Icon Database names
local PROFESSION_ICONS = {
    ["Blacksmithing"] = "trade_blacksmithing",
    ["Leatherworking"] = "trade_leatherworking",
    ["Alchemy"]        = "trade_alchemy",
    ["Herbalism"]      = "spell_nature_naturetouchgrow",
    ["Mining"]         = "trade_mining",
    ["Engineering"]    = "trade_engineering",
    ["Enchanting"]     = "trade_engraving",
    ["Tailoring"]      = "trade_tailoring",
    ["Skinning"]       = "inv_misc_pelt_wolf_01",
    ["Jewelcrafting"]  = "inv_misc_gem_01",
    ["Inscription"]    = "inv_inscription_tradeskill01",
    ["Cooking"]        = "inv_misc_food_15",
    ["First Aid"]      = "Spell_holy_sealofsacrifice",
    ["Fishing"]        = "trade_fishing"
}

-- Helper: Get Profession Icon as a texture string (12x12)
local function GetProfessionIcon(profName)
    local iconName = PROFESSION_ICONS[profName] or "INV_Misc_QuestionMark"
    return string.format("|TInterface\\Icons\\%s:12:12:0:0|t", iconName)
end
RoxyKovusProfLib.GetProfessionIcon = GetProfessionIcon

-- Get player's learned professions
function RoxyKovusProfLib:GetProfessions()
    local professions = {
        first = nil,
        second = nil,
        fishing = nil,
        cooking = nil,
        first_aid = nil
    }

    for skillIndex = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, skillMaxRank, isAbandonable = GetSkillLineInfo(skillIndex)

        if skillName and not isHeader then
            if isAbandonable then
                if not professions.first then
                    professions.first = skillIndex
                else
                    professions.second = skillIndex
                end
            else
                if skillName == "Cooking" then
                    professions.cooking = skillIndex
                elseif skillName == "First Aid" then
                    professions.first_aid = skillIndex
                elseif skillName == "Fishing" then
                    professions.fishing = skillIndex
                end
            end
        end
    end

    return professions.first, professions.second, professions.fishing, professions.cooking, professions.first_aid
end

-- Get detailed information about a specific profession.
-- The returned table now includes an 'icon' field formatted as a texture string.
function RoxyKovusProfLib:GetProfessionInfo(skillIndex)
    if not skillIndex then return nil end

    local skillName, _, _, skillRank, _, skillModifier, skillMaxRank = GetSkillLineInfo(skillIndex)
    local iconName = PROFESSION_ICONS[skillName] or "INV_Misc_QuestionMark"
    local icon = string.format("|TInterface\\Icons\\%s:16:16:0:0|t", iconName)

    -- Find a profession spell (if available)
    local spellOffset = FindSpellBookSlotBySpellID(skillIndex) or nil

    return {
        name = skillName,
        icon = icon,
        level = skillRank,
        maxLevel = skillMaxRank,
        skillModifier = skillModifier or 0,
        spellOffset = spellOffset
    }
end
