--[[
    AssignmentManager.lua
    Manages raid assignment data
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- AssignmentManager class
local AssignmentManager = {}
AssignmentManager.__index = AssignmentManager
BowbAssigns.Managers.AssignmentManager = AssignmentManager

--[[
    Create a new AssignmentManager instance
    @return AssignmentManager - The new instance
]]
function AssignmentManager:New()
    local instance = setmetatable({}, self)
    instance.roster = {}
    instance.cooldowns = {}
    instance.cooldownsByBoss = {}
    instance.pheromones = {}
    instance.isInitialized = false
    return instance
end

--[[
    Initialize and load saved data
]]
function AssignmentManager:Initialize()
    if self.isInitialized then
        return
    end
    
    -- Ensure BowbAssignsDB exists
    if not BowbAssignsDB then
        BowbAssignsDB = {}
    end
    
    -- Initialize assignments section
    if not BowbAssignsDB.assignments then
        BowbAssignsDB.assignments = {
            roster = {},
            cooldowns = {},
            pheromones = {},
            disabled = {}
        }
    end
    
    -- Ensure disabled table exists (for older saves)
    if not BowbAssignsDB.assignments.disabled then
        BowbAssignsDB.assignments.disabled = {}
    end
    
    -- Load saved data with deep copy to avoid reference issues
    local savedRoster = BowbAssignsDB.assignments.roster or {}
    local savedCooldowns = BowbAssignsDB.assignments.cooldowns or {}
    local savedPheromones = BowbAssignsDB.assignments.pheromones or {}
    
    self.roster = BowbAssigns.Utils.TableUtils:DeepCopy(savedRoster)
    self.cooldowns = BowbAssigns.Utils.TableUtils:DeepCopy(savedCooldowns)
    self.pheromones = BowbAssigns.Utils.TableUtils:DeepCopy(savedPheromones)
    
    -- Rebuild cooldowns by boss
    if #self.cooldowns > 0 then
        local parser = BowbAssigns.Managers.DataParser:New()
        self.cooldownsByBoss = parser:GroupByBoss(self.cooldowns)
    end
    
    self.isInitialized = true
    
    BowbAssigns:DebugPrint("AssignmentManager initialized with saved data")
end

--[[
    Set the roster data
    @param roster table - Parsed roster map
]]
function AssignmentManager:SetRoster(roster)
    self.roster = roster or {}
    
    -- Ensure SavedVariables structure exists
    if not BowbAssignsDB then
        BowbAssignsDB = {}
    end
    if not BowbAssignsDB.assignments then
        BowbAssignsDB.assignments = {}
    end
    
    -- Save to SavedVariables
    BowbAssignsDB.assignments.roster = BowbAssigns.Utils.TableUtils:DeepCopy(self.roster)
    
    local count = BowbAssigns.Utils.TableUtils:Size(self.roster)
    BowbAssigns:DebugPrint("Roster saved (" .. count .. " entries)")
    BowbAssigns:DebugPrint("Roster updated and saved to BowbAssignsDB")
end

--[[
    Set the cooldown assignments
    @param cooldowns table - Array of parsed cooldown assignments
]]
function AssignmentManager:SetCooldowns(cooldowns)
    self.cooldowns = cooldowns or {}
    
    -- Group by boss for easier access
    local parser = BowbAssigns.Managers.DataParser:New()
    self.cooldownsByBoss = parser:GroupByBoss(self.cooldowns)
    
    -- Ensure SavedVariables structure exists
    if not BowbAssignsDB then
        BowbAssignsDB = {}
    end
    if not BowbAssignsDB.assignments then
        BowbAssignsDB.assignments = {}
    end
    
    -- Save to SavedVariables
    BowbAssignsDB.assignments.cooldowns = BowbAssigns.Utils.TableUtils:DeepCopy(self.cooldowns)
    
    BowbAssigns:DebugPrint("Cooldowns saved (" .. #self.cooldowns .. " assignments)")
    BowbAssigns:DebugPrint("Cooldowns updated and saved to BowbAssignsDB")
end

--[[
    Set the pheromones assignments
    @param pheromones table - Array of player names
]]
function AssignmentManager:SetPheromones(pheromones)
    self.pheromones = pheromones or {}
    
    -- Ensure SavedVariables structure exists
    if not BowbAssignsDB then
        BowbAssignsDB = {}
    end
    if not BowbAssignsDB.assignments then
        BowbAssignsDB.assignments = {}
    end
    
    -- Save to SavedVariables
    BowbAssignsDB.assignments.pheromones = BowbAssigns.Utils.TableUtils:DeepCopy(self.pheromones)
    
    BowbAssigns:DebugPrint("Pheromones saved (" .. #self.pheromones .. " players)")
    BowbAssigns:DebugPrint("Pheromones updated and saved to BowbAssignsDB")
end

--[[
    Get roster data
    @return table - Roster map
]]
function AssignmentManager:GetRoster()
    return self.roster
end

--[[
    Get cooldowns for a specific boss
    @param bossName string - Boss name
    @return table - Array of assignments for that boss
]]
function AssignmentManager:GetCooldownsForBoss(bossName)
    return self.cooldownsByBoss[bossName] or {}
end

--[[
    Get all boss names
    @return table - Array of boss names
]]
function AssignmentManager:GetBossNames()
    local names = {}
    for bossName, _ in pairs(self.cooldownsByBoss) do
        table.insert(names, bossName)
    end
    table.sort(names)
    return names
end

--[[
    Get pheromones data
    @return table - Array of player names
]]
function AssignmentManager:GetPheromones()
    return self.pheromones
end

--[[
    Resolve role to player name
    @param role string - Role identifier (e.g., "RSHAM1")
    @return string - Player name or role if not found
]]
function AssignmentManager:ResolveRole(role)
    return self.roster[role] or role
end

--[[
    Clear all assignment data
]]
function AssignmentManager:Clear()
    self.roster = {}
    self.cooldowns = {}
    self.cooldownsByBoss = {}
    self.pheromones = {}
    
    -- Clear from SavedVariables
    if BowbAssignsDB and BowbAssignsDB.assignments then
        BowbAssignsDB.assignments.roster = {}
        BowbAssignsDB.assignments.cooldowns = {}
        BowbAssignsDB.assignments.pheromones = {}
    end
    
    BowbAssigns:Print("All assignments cleared")
end

--[[
    Check if an ability or assignment is disabled
    @param bossKey string - Boss key
    @param abilityKey string - Ability key
    @param assignmentIndex number|nil - Optional assignment index
    @return boolean - True if disabled
]]
function AssignmentManager:IsDisabled(bossKey, abilityKey, assignmentIndex)
    if not BowbAssignsDB.assignments.disabled then
        return false
    end
    
    if not BowbAssignsDB.assignments.disabled[bossKey] then
        return false
    end
    
    if not BowbAssignsDB.assignments.disabled[bossKey][abilityKey] then
        return false
    end
    
    -- If checking entire ability
    if not assignmentIndex then
        return BowbAssignsDB.assignments.disabled[bossKey][abilityKey].all == true
    end
    
    -- If checking specific assignment
    local assignments = BowbAssignsDB.assignments.disabled[bossKey][abilityKey].assignments
    return assignments and assignments[assignmentIndex] == true
end

--[[
    Set disabled state for an ability or assignment
    @param bossKey string - Boss key
    @param abilityKey string - Ability key
    @param disabled boolean - Disabled state
    @param assignmentIndex number|nil - Optional assignment index
]]
function AssignmentManager:SetDisabled(bossKey, abilityKey, disabled, assignmentIndex)
    if not BowbAssignsDB.assignments.disabled then
        BowbAssignsDB.assignments.disabled = {}
    end
    
    if not BowbAssignsDB.assignments.disabled[bossKey] then
        BowbAssignsDB.assignments.disabled[bossKey] = {}
    end
    
    if not BowbAssignsDB.assignments.disabled[bossKey][abilityKey] then
        BowbAssignsDB.assignments.disabled[bossKey][abilityKey] = {
            all = false,
            assignments = {}
        }
    end
    
    -- Set entire ability
    if not assignmentIndex then
        BowbAssignsDB.assignments.disabled[bossKey][abilityKey].all = disabled
    else
        -- Set specific assignment
        BowbAssignsDB.assignments.disabled[bossKey][abilityKey].assignments[assignmentIndex] = disabled
    end
end

