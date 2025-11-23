--[[
    Constants.lua
    Global constants used throughout the addon
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- Constants namespace
BowbAssigns.Constants = {}

-- Event names
BowbAssigns.Constants.Events = {
    ADDON_LOADED = "ADDON_LOADED",
    PLAYER_LOGIN = "PLAYER_LOGIN",
    PLAYER_LOGOUT = "PLAYER_LOGOUT",
    PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",
}

-- Configuration defaults
BowbAssigns.Constants.Defaults = {
    -- Add your default configuration values here
    enabled = true,
    version = "1.0.0",
    chatChannel = "raid", -- Default chat channel for posting assignments
    chatBatchSize = 20, -- Number of messages per batch (rate limit)
    chatBatchDelay = 1.5, -- Delay in seconds between batches
    minimap = {
        hide = false,
        minimapPos = 220, -- Default position in degrees
        radius = 80,
    },
}

-- UI Constants
BowbAssigns.Constants.UI = {
    FRAME_WIDTH = 400,
    FRAME_HEIGHT = 300,
    PADDING = 10,
}

-- Color codes
BowbAssigns.Constants.Colors = {
    HEADER = "|cFF1E90FF",
    SUCCESS = "|cFF00FF00",
    ERROR = "|cFFFF0000",
    WARNING = "|cFFFFFF00",
    RESET = "|r",
}

