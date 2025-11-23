--[[
    Init.lua
    Addon initialization and bootstrap
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- Create manager instances
local configManager = BowbAssigns.Managers.ConfigManager:New()
local eventManager = BowbAssigns.Managers.EventManager:New()
local assignmentManager = BowbAssigns.Managers.AssignmentManager:New()
local macroManager = BowbAssigns.Managers.MacroManager:New()
local minimapManager = BowbAssigns.Managers.MinimapManager:New()

-- Store manager references
BowbAssigns.ConfigManager = configManager
BowbAssigns.EventManager = eventManager
BowbAssigns.AssignmentManager = assignmentManager
BowbAssigns.MacroManager = macroManager
BowbAssigns.MinimapManager = minimapManager

-- Create UI instances
local mainFrame = BowbAssigns.UI.MainFrame:New()
local importModal = BowbAssigns.UI.ImportModal:New()
BowbAssigns.MainFrame = mainFrame
BowbAssigns.ImportModal = importModal

--[[
    Handle ADDON_LOADED event
]]
local function OnAddonLoaded(event, addonName)
    if addonName ~= ADDON_NAME then
        return
    end
    
    -- Initialize configuration
    configManager:Initialize()
    
    -- Initialize assignments (loads saved data)
    assignmentManager:Initialize()
    
    -- Initialize minimap button
    minimapManager:Initialize()
    
    -- Show welcome message with loaded data summary
    BowbAssigns:Print("BowbAssigns v" .. BowbAssigns.Version .. " loaded!")
    
    -- Show what data was loaded
    local rosterSize = BowbAssigns.Utils.TableUtils:Size(assignmentManager:GetRoster())
    local cooldownsSize = #assignmentManager.cooldowns
    local pheromonesSize = #assignmentManager:GetPheromones()
    
    if rosterSize > 0 or cooldownsSize > 0 or pheromonesSize > 0 then
        if rosterSize > 0 then
            BowbAssigns:Print("  Roster: " .. rosterSize .. " entries")
        end
        if cooldownsSize > 0 then
            BowbAssigns:Print("  Cooldowns: " .. cooldownsSize .. " assignments")
        end
        if pheromonesSize > 0 then
            BowbAssigns:Print("  Pheromones: " .. pheromonesSize .. " players")
        end
    else
        BowbAssigns:Print("  No saved data - type /bass to get started!")
    end
    
    BowbAssigns:DebugPrint("Addon loaded - initialization complete")
end

--[[
    Handle PLAYER_LOGIN event
]]
local function OnPlayerLogin(event)
    BowbAssigns:DebugPrint("Player logged in")
end

--[[
    Handle PLAYER_ENTERING_WORLD event
]]
local function OnPlayerEnteringWorld(event, isInitialLogin, isReloadingUi)
    if isInitialLogin then
        BowbAssigns:DebugPrint("Initial login detected")
    elseif isReloadingUi then
        BowbAssigns:DebugPrint("UI reload detected")
    end
end

-- Register event handlers
eventManager:RegisterHandler("ADDON_LOADED", OnAddonLoaded, "core_addon_loaded")
eventManager:RegisterHandler("PLAYER_LOGIN", OnPlayerLogin, "core_player_login")
eventManager:RegisterHandler("PLAYER_ENTERING_WORLD", OnPlayerEnteringWorld, "core_entering_world")

-- Slash command handler
SLASH_BOWBASSIGNS1 = "/bass"
SLASH_BOWBASSIGNS2 = "/bowbassigns"

SlashCmdList["BOWBASSIGNS"] = function(msg)
    local args = BowbAssigns.Utils.StringUtils:Split(msg, " ")
    local command = args[1] and args[1]:lower() or ""
    
    if command == "" then
        -- Default action: toggle UI
        mainFrame:Toggle()
    elseif command == "help" then
        BowbAssigns:Print("Available commands:")
        print("  /bass - Toggle the main window")
        print("  /bass help - Show this help message")
        print("  /bass show - Open the main window")
        print("  /bass hide - Close the main window")
        print("  /bass minimap - Toggle minimap button")
        print("  /bass debug - Toggle debug mode")
        print("  /bass reset - Reset configuration to defaults")
        print("  /bass version - Show addon version")
    elseif command == "show" then
        mainFrame:Show()
    elseif command == "hide" then
        mainFrame:Hide()
    elseif command == "minimap" then
        minimapManager:Toggle()
        local status = minimapManager:IsVisible() and "shown" or "hidden"
        BowbAssigns:Print("Minimap button " .. status)
    elseif command == "debug" then
        BowbAssigns.Debug = not BowbAssigns.Debug
        BowbAssigns:Print("Debug mode: " .. (BowbAssigns.Debug and "ON" or "OFF"))
    elseif command == "reset" then
        configManager:Reset()
    elseif command == "version" then
        BowbAssigns:Print("Version: " .. BowbAssigns.Version)
        BowbAssigns:Print("Build Date: " .. BowbAssigns.BuildDate)
    else
        BowbAssigns:Print("Unknown command. Type /bass help for available commands")
    end
end

