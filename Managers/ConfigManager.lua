--[[
    ConfigManager.lua
    Manages addon configuration and saved variables
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- ConfigManager class
local ConfigManager = {}
ConfigManager.__index = ConfigManager
BowbAssigns.Managers.ConfigManager = ConfigManager

--[[
    Create a new ConfigManager instance
    @return ConfigManager - The new instance
]]
function ConfigManager:New()
    local instance = setmetatable({}, self)
    instance.config = {}
    instance.isInitialized = false
    return instance
end

--[[
    Initialize the configuration
    Loads saved variables or creates defaults
]]
function ConfigManager:Initialize()
    if self.isInitialized then
        BowbAssigns:DebugPrint("ConfigManager already initialized")
        return
    end
    
    -- Load saved variables or create defaults
    if not BowbAssignsDB then
        BowbAssignsDB = BowbAssigns.Utils.TableUtils:DeepCopy(
            BowbAssigns.Constants.Defaults
        )
        BowbAssigns:DebugPrint("Created default configuration")
    end
    
    self.config = BowbAssignsDB
    self.isInitialized = true
    
    BowbAssigns:DebugPrint("ConfigManager initialized")
end

--[[
    Get a configuration value
    @param key string - The configuration key
    @return any - The configuration value
]]
function ConfigManager:Get(key)
    return self.config[key]
end

--[[
    Set a configuration value
    @param key string - The configuration key
    @param value any - The value to set
]]
function ConfigManager:Set(key, value)
    self.config[key] = value
    BowbAssigns:DebugPrint("Config updated: " .. key .. " = " .. tostring(value))
end

--[[
    Reset configuration to defaults
]]
function ConfigManager:Reset()
    self.config = BowbAssigns.Utils.TableUtils:DeepCopy(
        BowbAssigns.Constants.Defaults
    )
    BowbAssignsDB = self.config
    BowbAssigns:Print("Configuration reset to defaults")
end

