--[[
    TableUtils.lua
    Utility functions for table operations
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- TableUtils class
local TableUtils = {}
BowbAssigns.Utils.TableUtils = TableUtils

--[[
    Deep copy a table
    @param original table - The table to copy
    @return table - A deep copy of the original table
]]
function TableUtils:DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = self:DeepCopy(value)
    end
    
    return copy
end

--[[
    Merge two tables (shallow merge)
    @param target table - The target table
    @param source table - The source table
    @return table - The merged table
]]
function TableUtils:Merge(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
    return target
end

--[[
    Check if a table contains a value
    @param tbl table - The table to search
    @param value any - The value to find
    @return boolean - True if the value exists in the table
]]
function TableUtils:Contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

--[[
    Get the size of a table
    @param tbl table - The table to measure
    @return number - The number of elements in the table
]]
function TableUtils:Size(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

