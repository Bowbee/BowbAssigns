--[[
    Namespace.lua
    Creates and manages the addon's global namespace
]]

local ADDON_NAME = "BowbAssigns"

-- Create addon namespace
local BowbAssigns = {}
_G[ADDON_NAME] = BowbAssigns

-- Version info
BowbAssigns.Version = "1.0.0"
BowbAssigns.BuildDate = "2025-11-23"

-- Namespace containers
BowbAssigns.Core = {}
BowbAssigns.Utils = {}
BowbAssigns.Managers = {}
BowbAssigns.UI = {}

-- Debug flag
BowbAssigns.Debug = false

--[[
    Print debug messages if debug mode is enabled
    @param message string - The message to print
]]
function BowbAssigns:DebugPrint(message)
    if self.Debug then
        print("|cFF00FF00[" .. ADDON_NAME .. " Debug]|r " .. tostring(message))
    end
end

--[[
    Print standard addon messages
    @param message string - The message to print
]]
function BowbAssigns:Print(message)
    print("|cFF1E90FF[" .. ADDON_NAME .. "]|r " .. tostring(message))
end

--[[
    Print error messages
    @param message string - The error message to print
]]
function BowbAssigns:Error(message)
    print("|cFFFF0000[" .. ADDON_NAME .. " Error]|r " .. tostring(message))
end

--[[
    Print debug messages (only if debug mode is enabled)
    @param message string - The debug message to print
]]
function BowbAssigns:DebugPrint(message)
    -- Only print if debug mode is enabled (can be toggled in settings later)
    local debugMode = false -- Change to true to see debug messages
    if debugMode then
        print("|cFF808080[" .. ADDON_NAME .. " Debug]|r " .. tostring(message))
    end
end

