--[[
    RaidData.lua
    Hardcoded raid and boss data for MoP
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- Raid and boss data
BowbAssigns.RaidData = {
    raids = {
        {
            id = "MSV",
            name = "Mogu'shan Vaults",
            tier = 14,
            enabled = true,
            bosses = {
                { name = "The Stone Guard", ejID = 679, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT_MOGURAID_01", key = "STONEGUARD" },
                { name = "Feng the Accursed", ejID = 689, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT_MOGURAID_02", key = "FENG" },
                { name = "Gara'jal the Spiritbinder", ejID = 682, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT_MOGURAID_03", key = "GARAJAL" },
                { name = "The Spirit Kings", ejID = 687, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT_MOGURAID_04", key = "SPIRITkings" },
                { name = "Elegon", ejID = 726, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT_MOGURAID_05", key = "ELEGON" },
                { name = "Will of the Emperor", ejID = 677, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT_MOGURAID_06", key = "WILLOFEMPEROR" }
            }
        },
        {
            id = "HOF",
            name = "Heart of Fear",
            tier = 14,
            enabled = true,
            bosses = {
                { name = "Imperial Vizier Zor'lok", ejID = 745, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-MANTIDRAID02", key = "ZORLOK" },
                { name = "Blade Lord Ta'yak", ejID = 744, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-MANTIDRAID03", key = "TAYAK" },
                { name = "Garalon", ejID = 713, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-MANTIDRAID04", key = "GARALON" },
                { name = "Wind Lord Mel'jarak", ejID = 741, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-MANTIDRAID05", key = "MELJARAK" },
                { name = "Amber-Shaper Un'sok", ejID = 737, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-MANTIDRAID06", key = "UNSOK" },
                { name = "Grand Empress Shek'zeer", ejID = 743, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-MANTIDRAID07", key = "SHEKZEER" }
            }
        },
        {
            id = "TOES",
            name = "Terrace of Endless Spring",
            tier = 14,
            enabled = true,
            bosses = {
                { name = "Protectors of the Endless", ejID = 683, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-TERRACEOFENDLESSSPRING01", key = "PROTECTORS" },
                { name = "Tsulong", ejID = 742, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-TERRACEOFENDLESSSPRING02", key = "TSULONG" },
                { name = "Lei Shi", ejID = 729, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-TERRACEOFENDLESSSPRING03", key = "LEISHI" },
                { name = "Sha of Fear", ejID = 709, texture = "Interface\\ACHIEVEMENT\\ACHIEVEMENT-RAID-TERRACEOFENDLESSSPRING04", key = "SHA" }
            }
        },
        {
            id = "TOT",
            name = "Throne of Thunder",
            tier = 15,
            enabled = true,
            bosses = {
                { name = "Jin'rokh the Breaker", ejID = 827, key = "JINROKH" },
                { name = "Horridon", ejID = 819, key = "HORRIDON" },
                { name = "Council of Elders", ejID = 816, key = "COUNCIL" },
                { name = "Tortos", ejID = 825, key = "TORTOS" },
                { name = "Megaera", ejID = 821, key = "MEGAERA" },
                { name = "Ji-Kun", ejID = 828, key = "JIKUN" },
                { name = "Durumu the Forgotten", ejID = 818, key = "DURUMU" },
                { name = "Primordius", ejID = 820, key = "PRIMORDIUS" },
                { name = "Dark Animus", ejID = 824, key = "DARKANIMUS" },
                { name = "Iron Qon", ejID = 817, key = "IRONQON" },
                { name = "Twin Consorts", ejID = 829, key = "TWINS" },
                { name = "Lei Shen", ejID = 832, key = "LEISHEN" },
                { name = "Ra-den", ejID = 831, key = "RADEN" }
            }
        },
        {
            id = "SOO",
            name = "Siege of Orgrimmar",
            tier = 16,
            enabled = true, -- Enabled for development
            bosses = {
                { name = "Immerseus", ejID = 852, key = "IMMERSEUS" },
                { name = "Fallen Protectors", ejID = 849, key = "PROTECTORS" },
                { name = "Norushen", ejID = 866, key = "NORUSHEN" },
                { name = "Sha of Pride", ejID = 867, key = "SHA" },
                { name = "Galakras", ejID = 881, key = "GALAKRAS" },
                { name = "Iron Juggernaut", ejID = 864, key = "JUGGERNAUT" },
                { name = "Kor'kron Dark Shaman", ejID = 856, key = "SHAMAN" },
                { name = "General Nazgrim", ejID = 850, key = "NAZGRIM" },
                { name = "Malkorok", ejID = 846, key = "MALKOROK" },
                { name = "Spoils of Pandaria", ejID = 870, key = "SPOILS" },
                { name = "Thok the Bloodthirsty", ejID = 851, key = "THOK" },
                { name = "Siegecrafter Blackfuse", ejID = 865, key = "BLACKFUSE" },
                { name = "Paragons of the Klaxxi", ejID = 853, key = "PARAGONS" },
                { name = "Garrosh Hellscream", ejID = 869, key = "GARROSH" }
            }
        }
    }
}

--[[
    Get all raids
    @return table - Array of raid data
]]
function BowbAssigns.RaidData:GetRaids()
    return self.raids
end

--[[
    Get raid by ID
    @param raidId string - Raid ID (e.g., "HOF")
    @return table - Raid data or nil
]]
function BowbAssigns.RaidData:GetRaid(raidId)
    for _, raid in ipairs(self.raids) do
        if raid.id == raidId then
            return raid
        end
    end
    return nil
end

--[[
    Get bosses for a raid
    @param raidId string - Raid ID
    @return table - Array of boss names
]]
function BowbAssigns.RaidData:GetBosses(raidId)
    local raid = self:GetRaid(raidId)
    if raid then
        return raid.bosses
    end
    return {}
end

--[[
    Check if a boss has special mechanics (like Garalon pheromones)
    @param bossName string - Boss name
    @return boolean - True if boss has special UI
]]
function BowbAssigns.RaidData:HasSpecialMechanic(bossName)
    -- Handle both string and table boss entries
    local name = type(bossName) == "table" and bossName.name or bossName
    return name == "Garalon"
end

--[[
    Get boss name from boss entry
    @param boss string or table - Boss entry
    @return string - Boss name
]]
function BowbAssigns.RaidData:GetBossName(boss)
    return type(boss) == "table" and boss.name or boss
end

