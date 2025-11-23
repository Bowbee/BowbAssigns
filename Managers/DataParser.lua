--[[
    DataParser.lua
    Parses spreadsheet export data for roster and cooldown assignments
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- DataParser class
local DataParser = {}
DataParser.__index = DataParser
BowbAssigns.Managers.DataParser = DataParser

--[[
    Create a new DataParser instance
    @return DataParser - The new instance
]]
function DataParser:New()
    local instance = setmetatable({}, self)
    return instance
end

--[[
    Parse the master roster export string
    @param rosterString string - The roster export (ROLE-Name,ROLE-Name,...)
    @return table - Map of role to player name
]]
function DataParser:ParseRoster(rosterString)
    if not rosterString or rosterString == "" then
        return nil, "Empty roster string"
    end
    
    local roster = {}
    local pairs = BowbAssigns.Utils.StringUtils:Split(rosterString, ",")
    
    for _, pair in ipairs(pairs) do
        local parts = BowbAssigns.Utils.StringUtils:Split(pair, "-")
        if #parts == 2 then
            local role = BowbAssigns.Utils.StringUtils:Trim(parts[1])
            local name = BowbAssigns.Utils.StringUtils:Trim(parts[2])
            roster[role] = name
        end
    end
    
    BowbAssigns:DebugPrint("Parsed roster with " .. 
        BowbAssigns.Utils.TableUtils:Size(roster) .. " entries")
    
    return roster
end

--[[
    Parse a single cooldown assignment line
    @param line string - Single assignment (ABILITY/count/role/timing/spellID/...)
    @return table - Parsed assignment data
]]
function DataParser:ParseCooldownLine(line)
    local parts = BowbAssigns.Utils.StringUtils:Split(line, "/")
    
    if #parts < 5 then
        return nil
    end
    
    return {
        ability = parts[1],
        count = parts[2],
        role = parts[3],
        timing = parts[4],
        spellId = parts[5],
        comment1 = parts[6] ~= "nil" and parts[6] or nil,
        comment2 = parts[7] ~= "nil" and parts[7] or nil,
        comment3 = parts[8] ~= "nil" and parts[8] or nil,
        comment4 = parts[9] ~= "nil" and parts[9] or nil,
    }
end

--[[
    Parse the cooldown export string
    @param cooldownString string - The cooldown export (entries separated by *)
    @return table - Array of parsed assignments grouped by boss/ability
]]
function DataParser:ParseCooldowns(cooldownString)
    if not cooldownString or cooldownString == "" then
        return nil, "Empty cooldown string"
    end
    
    local assignments = {}
    local lines = BowbAssigns.Utils.StringUtils:Split(cooldownString, "*")
    
    for _, line in ipairs(lines) do
        local assignment = self:ParseCooldownLine(line)
        if assignment then
            table.insert(assignments, assignment)
        end
    end
    
    BowbAssigns:DebugPrint("Parsed " .. #assignments .. " cooldown assignments")
    
    return assignments
end

--[[
    Group cooldown assignments by boss
    @param assignments table - Array of parsed assignments
    @return table - Assignments grouped by boss name
]]
function DataParser:GroupByBoss(assignments)
    local grouped = {}
    
    for _, assignment in ipairs(assignments) do
        local boss = self:ExtractBossName(assignment.ability)
        
        if not grouped[boss] then
            grouped[boss] = {}
        end
        
        table.insert(grouped[boss], assignment)
    end
    
    return grouped
end

--[[
    Extract boss name from ability string
    @param ability string - Ability name (e.g., "ZORLOK_HEALTH")
    @return string - Boss name
]]
function DataParser:ExtractBossName(ability)
    local parts = BowbAssigns.Utils.StringUtils:Split(ability, "_")
    return parts[1] or ability
end

--[[
    Parse pheromones assignment list
    @param pheromoneString string - Comma or newline separated player names
    @return table - Array of player names
]]
function DataParser:ParsePheromones(pheromoneString)
    if not pheromoneString or pheromoneString == "" then
        return nil, "Empty pheromones string"
    end
    
    -- Replace newlines with commas for consistent parsing
    local normalized = pheromoneString:gsub("\n", ",")
    local players = BowbAssigns.Utils.StringUtils:Split(normalized, ",")
    
    -- Trim whitespace from each name
    local trimmed = {}
    for _, name in ipairs(players) do
        local clean = BowbAssigns.Utils.StringUtils:Trim(name)
        if clean ~= "" then
            table.insert(trimmed, clean)
        end
    end
    
    BowbAssigns:DebugPrint("Parsed " .. #trimmed .. " pheromones players")
    
    return trimmed
end

