--[[
    EventManager.lua
    Manages WoW event registration and handling
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- EventManager class
local EventManager = {}
EventManager.__index = EventManager
BowbAssigns.Managers.EventManager = EventManager

--[[
    Create a new EventManager instance
    @return EventManager - The new instance
]]
function EventManager:New()
    local instance = setmetatable({}, self)
    instance.frame = CreateFrame("Frame")
    instance.handlers = {}
    
    -- Set up the event dispatcher
    instance.frame:SetScript("OnEvent", function(frame, event, ...)
        instance:DispatchEvent(event, ...)
    end)
    
    return instance
end

--[[
    Register a handler for an event
    @param event string - The event name
    @param handler function - The handler function
    @param key string - Optional unique key for the handler
]]
function EventManager:RegisterHandler(event, handler, key)
    if not self.handlers[event] then
        self.handlers[event] = {}
        self.frame:RegisterEvent(event)
        BowbAssigns:DebugPrint("Registered event: " .. event)
    end
    
    local handlerKey = key or tostring(handler)
    self.handlers[event][handlerKey] = handler
end

--[[
    Unregister a handler for an event
    @param event string - The event name
    @param key string - The unique key for the handler
]]
function EventManager:UnregisterHandler(event, key)
    if self.handlers[event] then
        self.handlers[event][key] = nil
        
        -- If no more handlers, unregister the event
        if BowbAssigns.Utils.TableUtils:Size(self.handlers[event]) == 0 then
            self.frame:UnregisterEvent(event)
            self.handlers[event] = nil
            BowbAssigns:DebugPrint("Unregistered event: " .. event)
        end
    end
end

--[[
    Dispatch an event to all registered handlers
    @param event string - The event name
    @param ... any - Event arguments
]]
function EventManager:DispatchEvent(event, ...)
    if self.handlers[event] then
        for key, handler in pairs(self.handlers[event]) do
            local success, err = pcall(handler, event, ...)
            if not success then
                BowbAssigns:Error("Error in event handler for " .. event .. ": " .. tostring(err))
            end
        end
    end
end

