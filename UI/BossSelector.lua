--[[
    BossSelector.lua
    UI for selecting and posting boss assignments
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- BossSelector class
local BossSelector = {}
BossSelector.__index = BossSelector
BowbAssigns.UI.BossSelector = BossSelector

--[[
    Create a new BossSelector instance
    @return BossSelector - The new instance
]]
function BossSelector:New()
    local instance = setmetatable({}, self)
    instance.frame = nil
    instance.buttons = {}
    return instance
end

--[[
    Create the boss selector frame
    @param parent Frame - Parent frame
]]
function BossSelector:Create(parent)
    if self.frame then
        return
    end
    
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -320)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -5, 40)
    self.frame = frame
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText("Boss Assignments")
    
    -- Scroll frame for buttons
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(540, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild
    
    BowbAssigns:DebugPrint("BossSelector created")
end

--[[
    Refresh boss buttons based on current assignments
]]
function BossSelector:Refresh()
    if not self.frame then
        return
    end
    
    -- Clear existing buttons
    for _, btn in ipairs(self.buttons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    self.buttons = {}
    
    -- Get boss names
    local bossNames = BowbAssigns.AssignmentManager:GetBossNames()
    
    if #bossNames == 0 then
        -- Show message if no bosses
        local msg = self.frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msg:SetPoint("TOP", 0, -10)
        msg:SetText("Import cooldowns to see boss assignments")
        return
    end
    
    -- Create button for each boss
    local yOffset = -10
    for _, bossName in ipairs(bossNames) do
        local btn = self:CreateBossButton(bossName)
        btn:SetPoint("TOP", self.frame.scrollChild, "TOP", 0, yOffset)
        table.insert(self.buttons, btn)
        yOffset = yOffset - 35
    end
    
    -- Update scroll child height
    self.frame.scrollChild:SetHeight(math.abs(yOffset) + 10)
end

--[[
    Create a button for a specific boss
    @param bossName string - Boss name
    @return Frame - The created button
]]
function BossSelector:CreateBossButton(bossName)
    local btn = CreateFrame("Button", nil, self.frame.scrollChild, "GameMenuButtonTemplate")
    btn:SetSize(520, 30)
    btn:SetText(bossName)
    
    btn:SetScript("OnClick", function()
        self:PostBossAssignments(bossName)
    end)
    
    return btn
end

--[[
    Post assignments for a specific boss to chat
    @param bossName string - Boss name
]]
function BossSelector:PostBossAssignments(bossName)
    local lines = BowbAssigns.MacroManager:GenerateBossMacro(
        bossName,
        BowbAssigns.AssignmentManager
    )
    
    BowbAssigns.MacroManager:PostToChat(lines)
    BowbAssigns:Print("Posted assignments for " .. bossName)
end

