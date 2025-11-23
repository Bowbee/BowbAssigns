--[[
    MacroManager.lua
    Creates and manages boss assignment macros
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- MacroManager class
local MacroManager = {}
MacroManager.__index = MacroManager
BowbAssigns.Managers.MacroManager = MacroManager

--[[
    Create a new MacroManager instance
    @return MacroManager - The new instance
]]
function MacroManager:New()
    local instance = setmetatable({}, self)
    instance.testMode = false -- Use party chat instead of raid
    instance.messageQueue = {} -- Queue for batched message sending
    instance.queueTimer = nil -- Timer for processing queue
    return instance
end

--[[
    Set test mode (party chat vs raid chat)
    @param enabled boolean - True for party chat, false for raid chat
]]
function MacroManager:SetTestMode(enabled)
    self.testMode = enabled
    BowbAssigns:DebugPrint("Test mode: " .. (enabled and "ON" or "OFF"))
end

--[[
    Get the appropriate chat channel
    @return string - Chat channel (e.g., /raid, /party, /rw)
]]
function MacroManager:GetChatChannel()
    if self.testMode then
        return "/party"
    end
    
    -- Get channel from settings
    local channel = BowbAssigns.ConfigManager:Get("chatChannel") or "raid"
    
    -- Map channel keys to slash commands
    local channelMap = {
        party = "/party",
        raid = "/raid",
        raid_warning = "/rw",
        guild = "/guild",
        officer = "/o"
    }
    
    return channelMap[channel] or "/raid"
end

--[[
    Format a single assignment line (for table formatting)
    @param assignment table - Assignment data
    @param assignmentManager AssignmentManager - For role resolution
    @return table - {timing, name, spell, note, spellLink} for formatting
]]
function MacroManager:FormatAssignmentParts(assignment, assignmentManager)
    local name = assignmentManager:ResolveRole(assignment.role)
    local timing = ""
    local spell = ""
    local spellLink = ""
    local note = ""
    
    -- Always format timing for consistent alignment
    local timingNum = tonumber(assignment.timing) or 0
    if timingNum < 0 then
        timing = "[" .. assignment.timing .. "s]"
    elseif timingNum > 0 then
        timing = "[+" .. assignment.timing .. "s]"
    else
        timing = "[0s]"
    end
    
    -- Get spell link from spellId
    if assignment.spellId and assignment.spellId ~= "nil" then
        local spellId = tonumber(assignment.spellId)
        if spellId then
            local link = GetSpellLink(spellId)
            if link then
                spellLink = link
                -- Also get plain text name for width calculation
                local spellName = GetSpellInfo(spellId)
                if spellName then
                    spell = spellName
                end
            end
        end
    end
    
    -- Only show Override TTS (comment3)
    if assignment.comment3 and assignment.comment3 ~= "nil" then
        note = assignment.comment3
    end
    
    return {
        timing = timing,
        name = name,
        spell = spell,
        spellLink = spellLink,
        note = note
    }
end

--[[
    Pad string to width
    @param str string - String to pad
    @param width number - Target width
    @return string - Padded string
]]
function MacroManager:PadString(str, width)
    local padding = width - #str
    if padding > 0 then
        return str .. string.rep(" ", padding)
    end
    return str
end

--[[
    Generate macro text for a boss
    @param bossName string - Boss name
    @param assignmentManager AssignmentManager - Assignment data source
    @return table - Array of macro lines (each max 255 chars)
]]
function MacroManager:GenerateBossMacro(bossName, assignmentManager)
    local assignments = assignmentManager:GetCooldownsForBoss(bossName)
    local channel = self:GetChatChannel()
    
    local lines = {}
    table.insert(lines, channel .. " ===== " .. bossName .. " ASSIGNMENTS =====")
    
    -- Group by ability
    local byAbility = {}
    local assignmentIndex = 0
    for _, assignment in ipairs(assignments) do
        assignmentIndex = assignmentIndex + 1
        
        -- Skip if entire ability is disabled
        local abilityDisabled = assignmentManager:IsDisabled(bossName, assignment.ability, nil)
        local assignmentDisabled = assignmentManager:IsDisabled(bossName, assignment.ability, assignmentIndex)
        
        if abilityDisabled then
            BowbAssigns:DebugPrint("Skipping ability " .. assignment.ability .. " (entire ability disabled)")
        elseif assignmentDisabled then
            BowbAssigns:DebugPrint("Skipping assignment " .. assignmentIndex .. " for " .. assignment.ability .. " (assignment disabled)")
        end
        
        if not abilityDisabled and not assignmentDisabled then
            -- Skip if role is not rostered (unless it's "ALL")
            local resolvedName = assignmentManager:ResolveRole(assignment.role)
            if resolvedName ~= assignment.role or assignment.role == "ALL" then
                if not byAbility[assignment.ability] then
                    byAbility[assignment.ability] = {}
                end
                table.insert(byAbility[assignment.ability], assignment)
            end
        end
    end
    
    -- Sort abilities by name for consistent ordering
    local sortedAbilities = {}
    for ability in pairs(byAbility) do
        table.insert(sortedAbilities, ability)
    end
    table.sort(sortedAbilities)
    
    -- Format each ability group
    for _, ability in ipairs(sortedAbilities) do
        local abilityAssignments = byAbility[ability]
        
        -- Clean up ability name for display
        local abilityName = ability:gsub("_", " ")
        abilityName = abilityName:gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
        
        table.insert(lines, channel .. " -- " .. abilityName .. " --")
        
        -- Group by count (cast # or health %)
        -- Split comma-separated counts into individual entries
        local byCount = {}
        for _, assignment in ipairs(abilityAssignments) do
            local count = assignment.count or "default"
            
            -- Split comma-separated counts (e.g., "1,3,5" → ["1", "3", "5"])
            if count:find(",") then
                local counts = BowbAssigns.Utils.StringUtils:Split(count, ",")
                for _, singleCount in ipairs(counts) do
                    local trimmedCount = BowbAssigns.Utils.StringUtils:Trim(singleCount)
                    if not byCount[trimmedCount] then
                        byCount[trimmedCount] = {}
                    end
                    table.insert(byCount[trimmedCount], assignment)
                end
            else
                if not byCount[count] then
                    byCount[count] = {}
                end
                table.insert(byCount[count], assignment)
            end
        end
        
        -- Sort count keys based on ability type
        local sortedCounts = {}
        for count in pairs(byCount) do
            table.insert(sortedCounts, count)
        end
        
        -- Determine sort order based on ability name
        local isHealthPercent = ability:find("HEALTH") ~= nil
        
        table.sort(sortedCounts, function(a, b)
            -- Extract first number from count string
            local numA = tonumber(a:match("^(%d+)")) or 999
            local numB = tonumber(b:match("^(%d+)")) or 999
            
            if isHealthPercent then
                return numA > numB  -- Descending for health % (99 → 10)
            else
                return numA < numB  -- Ascending for casts (1 → 10)
            end
        end)
        
        -- Format each count group
        for _, count in ipairs(sortedCounts) do
            local countAssignments = byCount[count]
            
            -- Sort by timing within count
            table.sort(countAssignments, function(a, b)
                local timeA = tonumber(a.timing) or 0
                local timeB = tonumber(b.timing) or 0
                return timeA < timeB
            end)
            
            -- Determine if this is health % or cast #
            local isHealthPercent = ability:find("HEALTH") ~= nil
            local countLabel
            if count == "default" or count == "-1" then
                countLabel = ""
            elseif isHealthPercent then
                countLabel = "At " .. count .. "%:"
            elseif count:find(",") then
                countLabel = "Cast #" .. count .. ":"
            else
                countLabel = "Cast #" .. count .. ":"
            end
            
            if countLabel ~= "" then
                table.insert(lines, channel .. " " .. countLabel)
            end
            
            -- Calculate column widths for this group
            local maxTimingWidth = 0
            local maxNameWidth = 0
            local maxSpellWidth = 0
            local formattedParts = {}
            
            for _, assignment in ipairs(countAssignments) do
                local parts = self:FormatAssignmentParts(assignment, assignmentManager)
                table.insert(formattedParts, parts)
                maxTimingWidth = math.max(maxTimingWidth, #parts.timing)
                maxNameWidth = math.max(maxNameWidth, #parts.name)
                maxSpellWidth = math.max(maxSpellWidth, #parts.spell)
            end
            
            -- Format each assignment with padding
            for _, parts in ipairs(formattedParts) do
                local line = "  "
                
                -- Add timing (always present now for alignment)
                line = line .. self:PadString(parts.timing, maxTimingWidth) .. " "
                
                -- Add padded name
                line = line .. self:PadString(parts.name, maxNameWidth)
                
                -- Add spell link (or plain spell name if no link)
                if parts.spellLink ~= "" then
                    line = line .. " - " .. parts.spellLink
                elseif parts.spell ~= "" then
                    line = line .. " - " .. parts.spell
                end
                
                -- Add override TTS note
                if parts.note ~= "" then
                    line = line .. " - " .. parts.note
                end
                
                table.insert(lines, channel .. line)
            end
        end
    end
    
    return lines
end

--[[
    Generate pheromones macro text
    @param assignmentManager AssignmentManager - Assignment data source
    @return table - Array of macro lines
]]
function MacroManager:GeneratePheromoneMacro(assignmentManager)
    local players = assignmentManager:GetPheromones()
    local channel = self:GetChatChannel()
    
    local lines = {}
    table.insert(lines, channel .. " ===== PHEROMONES ASSIGNMENTS =====")
    
    for i, player in ipairs(players) do
        table.insert(lines, channel .. " " .. i .. ". " .. player)
    end
    
    return lines
end

--[[
    Send a single message to the appropriate chat channel
    @param line string - The message line to send
]]
function MacroManager:SendSingleMessage(line)
    -- Remove the channel prefix and send via SendChatMessage
    local channelCmd = self:GetChatChannel():sub(2) -- Remove leading /
    local message = line:gsub("^/[^ ]+ ", "")
    
    -- Map slash command to API channel
    local apiChannel = nil
    if channelCmd == "raid" and GetNumGroupMembers() > 0 then
        apiChannel = "RAID"
    elseif channelCmd == "party" and GetNumSubgroupMembers() > 0 then
        apiChannel = "PARTY"
    elseif channelCmd == "rw" and GetNumGroupMembers() > 0 then
        apiChannel = "RAID_WARNING"
    elseif channelCmd == "guild" and IsInGuild() then
        apiChannel = "GUILD"
    elseif channelCmd == "o" and IsInGuild() then
        apiChannel = "OFFICER"
    end
    
    if apiChannel then
        SendChatMessage(message, apiChannel)
    else
        -- Fallback to print if not in appropriate channel
        print(message)
    end
end

--[[
    Process the message queue in batches
]]
function MacroManager:ProcessMessageQueue()
    if #self.messageQueue == 0 then
        -- Queue is empty, cancel timer
        if self.queueTimer then
            self.queueTimer:Cancel()
            self.queueTimer = nil
        end
        BowbAssigns:DebugPrint("Message queue processing complete")
        return
    end
    
    -- Get batch size from config
    local batchSize = BowbAssigns.ConfigManager:Get("chatBatchSize") or 20
    
    -- Send next batch
    local sentCount = 0
    while sentCount < batchSize and #self.messageQueue > 0 do
        local line = table.remove(self.messageQueue, 1)
        self:SendSingleMessage(line)
        sentCount = sentCount + 1
    end
    
    BowbAssigns:DebugPrint("Sent batch of " .. sentCount .. " messages. " .. #self.messageQueue .. " remaining in queue")
    
    -- Schedule next batch if queue not empty
    if #self.messageQueue > 0 then
        local delay = BowbAssigns.ConfigManager:Get("chatBatchDelay") or 1.5
        if not self.queueTimer then
            self.queueTimer = C_Timer.NewTimer(delay, function()
                self:ProcessMessageQueue()
            end)
        end
    else
        self.queueTimer = nil
    end
end

--[[
    Post macro lines to chat with rate limiting
    @param lines table - Array of lines to post
]]
function MacroManager:PostToChat(lines)
    if not lines or #lines == 0 then
        return
    end
    
    -- Add all lines to queue
    for _, line in ipairs(lines) do
        table.insert(self.messageQueue, line)
    end
    
    BowbAssigns:DebugPrint("Queued " .. #lines .. " messages. Sending in batches of 20...")
    
    -- Start processing queue if not already running
    if not self.queueTimer then
        self:ProcessMessageQueue()
    end
end

--[[
    Create actual WoW macro for a boss
    @param bossName string - Boss name
    @param assignmentManager AssignmentManager - Assignment data source
    @return boolean, string - Success status and message
]]
function MacroManager:CreateWoWMacro(bossName, assignmentManager)
    local lines = self:GenerateBossMacro(bossName, assignmentManager)
    local macroName = "Bass_" .. bossName
    
    -- WoW macros are limited to 255 characters
    local macroText = table.concat(lines, "\n")
    
    if #macroText > 255 then
        return false, "Macro too long (" .. #macroText .. " chars). Split needed."
    end
    
    -- Try to create or update the macro
    local macroIndex = GetMacroIndexByName(macroName)
    
    if macroIndex == 0 then
        -- Create new macro
        CreateMacro(macroName, "INV_Misc_QuestionMark", macroText, nil)
        return true, "Created macro: " .. macroName
    else
        -- Update existing macro
        EditMacro(macroIndex, macroName, "INV_Misc_QuestionMark", macroText)
        return true, "Updated macro: " .. macroName
    end
end

