--[[
    StringUtils.lua
    Utility functions for string operations
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- StringUtils class
local StringUtils = {}
BowbAssigns.Utils.StringUtils = StringUtils

--[[
    Trim whitespace from both ends of a string
    @param str string - The string to trim
    @return string - The trimmed string
]]
function StringUtils:Trim(str)
    return str:match("^%s*(.-)%s*$")
end

--[[
    Split a string by a delimiter
    @param str string - The string to split
    @param delimiter string - The delimiter to split by
    @return table - Array of split strings
]]
function StringUtils:Split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    
    return result
end

--[[
    Check if a string starts with a prefix
    @param str string - The string to check
    @param prefix string - The prefix to look for
    @return boolean - True if the string starts with the prefix
]]
function StringUtils:StartsWith(str, prefix)
    return str:sub(1, #prefix) == prefix
end

--[[
    Check if a string ends with a suffix
    @param str string - The string to check
    @param suffix string - The suffix to look for
    @return boolean - True if the string ends with the suffix
]]
function StringUtils:EndsWith(str, suffix)
    return str:sub(-#suffix) == suffix
end

--[[
    Capitalize the first letter of a string
    @param str string - The string to capitalize
    @return string - The capitalized string
]]
function StringUtils:Capitalize(str)
    return str:gsub("^%l", string.upper)
end

