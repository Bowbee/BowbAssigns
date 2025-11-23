--[[
    MainFrame.lua
    Main UI frame for the addon - Redesigned
]]

local ADDON_NAME = "Bowbassigns"
local Bowbassigns = _G[ADDON_NAME]

-- MainFrame class
local MainFrame = {}
MainFrame.__index = MainFrame
Bowbassigns.UI.MainFrame = MainFrame

--[[
    Create a new MainFrame instance
    @return MainFrame - The new instance
]]
function MainFrame:New()
    local instance = setmetatable({}, self)
    instance.frame = nil
    instance.isVisible = false
    instance.selectedRaid = nil
    instance.selectedBoss = nil
    return instance
end

--[[
    Create the main UI frame
]]
function MainFrame:Create()
    if self.frame then
        return
    end
    
    local frame = CreateFrame("Frame", "BowbassignsMainFrame", UIParent, "BasicFrameTemplateWithInset")
    self.frame = frame
    
    -- Frame properties
    frame:SetSize(900, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
    frame.title:SetText("Bowbassigns - Raid Assignments")
    
    -- Create tabs
    self:CreateTabs()
    
    -- Create content areas
    self:CreateRosterTab()
    self:CreateAssignmentsTab()
    
    -- Initially hide
    frame:Hide()
    
    Bowbassigns:DebugPrint("MainFrame created")
end

--[[
    Create tab buttons
]]
function MainFrame:CreateTabs()
    local frame = self.frame
    local frameName = frame:GetName()
    
    -- Tab 1: Roster
    local tab1 = CreateFrame("Button", frameName .. "Tab1", frame, "CharacterFrameTabButtonTemplate")
    tab1:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 2)
    tab1:SetText("Roster")
    tab1:SetID(1)
    tab1:SetScript("OnClick", function() self:SwitchTab(1) end)
    frame.tab1 = tab1
    
    -- Tab 2: Assignments
    local tab2 = CreateFrame("Button", frameName .. "Tab2", frame, "CharacterFrameTabButtonTemplate")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -15, 0)
    tab2:SetText("Assignments")
    tab2:SetID(2)
    tab2:SetScript("OnClick", function() self:SwitchTab(2) end)
    frame.tab2 = tab2
    
    PanelTemplates_SetNumTabs(frame, 2)
    PanelTemplates_SetTab(frame, 1)
end

--[[
    Switch to a specific tab
    @param tabId number - Tab ID (1-2)
]]
function MainFrame:SwitchTab(tabId)
    PanelTemplates_SetTab(self.frame, tabId)
    
    -- Hide all content
    self.frame.rosterContent:Hide()
    self.frame.assignmentsContent:Hide()
    
    -- Show selected content
    if tabId == 1 then
        self.frame.rosterContent:Show()
    elseif tabId == 2 then
        self.frame.assignmentsContent:Show()
    end
end

--[[
    Create roster tab content
]]
function MainFrame:CreateRosterTab()
    local frame = self.frame
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    frame.rosterContent = content
    
    -- Title
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Roster Management")
    
    -- Instructions
    local instructions = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -10)
    instructions:SetText("Import your roster to map role identifiers to player names")
    
    -- Import button
    local importBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    importBtn:SetSize(150, 30)
    importBtn:SetPoint("TOP", instructions, "BOTTOM", 0, -20)
    importBtn:SetText("Import Roster")
    importBtn:SetScript("OnClick", function()
        self:ShowRosterImport()
    end)
    
    -- Roster display area (placeholder for now)
    local rosterDisplay = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rosterDisplay:SetPoint("TOP", importBtn, "BOTTOM", 0, -20)
    rosterDisplay:SetText("No roster loaded")
    content.rosterDisplay = rosterDisplay
end

--[[
    Create assignments tab content
]]
function MainFrame:CreateAssignmentsTab()
    local frame = self.frame
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    content:Hide()
    frame.assignmentsContent = content
    
    -- Raid dropdown at top
    self:CreateRaidDropdown(content)
    
    -- Left panel: Boss list (30%)
    self:CreateBossListPanel(content)
    
    -- Right panel: Assignment display (70%)
    self:CreateAssignmentPanel(content)
end

--[[
    Create raid dropdown
    @param parent Frame - Parent frame
]]
function MainFrame:CreateRaidDropdown(parent)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -5)
    label:SetText("Select Raid:")
    
    local dropdown = CreateFrame("Frame", "BowbassignsRaidDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", -10, -3)
    
    UIDropDownMenu_SetWidth(dropdown, 200)
    UIDropDownMenu_SetText(dropdown, "Select a raid...")
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local raids = Bowbassigns.RaidData:GetRaids()
        
        for _, raid in ipairs(raids) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = raid.name
            info.value = raid.id
            info.func = function()
                MainFrame:SelectRaid(raid.id)
                UIDropDownMenu_SetText(dropdown, raid.name)
            end
            
            if not raid.enabled then
                info.disabled = true
                info.tooltipTitle = raid.name
                info.tooltipText = "Not yet available in Classic"
            end
            
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    parent.raidDropdown = dropdown
end

--[[
    Create boss list panel
    @param parent Frame - Parent frame
]]
function MainFrame:CreateBossListPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -40)
    panel:SetSize(250, 520)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("Bosses")
    
    -- Scroll frame for boss buttons
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(210, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    panel.scrollFrame = scrollFrame
    panel.scrollChild = scrollChild
    parent.bossListPanel = panel
end

--[[
    Create assignment display panel
    @param parent Frame - Parent frame
]]
function MainFrame:CreateAssignmentPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent.bossListPanel, "TOPRIGHT", 10, 0)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -5, 5)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    
    -- Title area
    local bossTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bossTitle:SetPoint("TOP", panel, "TOP", 0, -10)
    bossTitle:SetText("Select a boss")
    panel.bossTitle = bossTitle
    
    -- Import Cooldowns button
    local importBtn = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    importBtn:SetSize(140, 25)
    importBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -15, -10)
    importBtn:SetText("Import Cooldowns")
    importBtn:SetScript("OnClick", function()
        self:ShowCooldownImport()
    end)
    panel.importButton = importBtn
    
    -- Test Mode checkbox
    local testMode = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
    testMode:SetPoint("RIGHT", importBtn, "LEFT", -50, 0)
    testMode.Text:SetText("Test Mode")
    testMode:SetScript("OnClick", function(self)
        Bowbassigns.MacroManager:SetTestMode(self:GetChecked())
    end)
    panel.testModeCheckbox = testMode
    
    -- Assignment display scroll area
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 80)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(580, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    panel.scrollFrame = scrollFrame
    panel.scrollChild = scrollChild
    panel.assignmentText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.assignmentText:SetPoint("TOPLEFT", 5, -5)
    panel.assignmentText:SetJustifyH("LEFT")
    panel.assignmentText:SetWidth(560)
    panel.assignmentText:SetText("Select a boss to view assignments")
    
    -- Post to Chat button
    local postBtn = CreateFrame("Button", nil, panel, "GameMenuButtonTemplate")
    postBtn:SetSize(140, 30)
    postBtn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 15)
    postBtn:SetText("Post to Chat")
    postBtn:SetScript("OnClick", function()
        self:PostCurrentBoss()
    end)
    panel.postButton = postBtn
    
    -- Pheromones section (only shown for Garalon)
    self:CreatePheromonesSection(panel)
    
    parent.assignmentPanel = panel
end

--[[
    Create pheromones section (hidden by default, shown for Garalon)
    @param parent Frame - Parent frame
]]
function MainFrame:CreatePheromonesSection(parent)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 15, 50)
    section:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 50)
    section:SetHeight(30)
    section:Hide()
    
    local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", section, "LEFT", 5, 0)
    label:SetText("Pheromones:")
    
    local importBtn = CreateFrame("Button", nil, section, "GameMenuButtonTemplate")
    importBtn:SetSize(130, 25)
    importBtn:SetPoint("LEFT", label, "RIGHT", 10, 0)
    importBtn:SetText("Import Pheromones")
    importBtn:SetScript("OnClick", function()
        self:ShowPheromonesImport()
    end)
    
    local postBtn = CreateFrame("Button", nil, section, "GameMenuButtonTemplate")
    postBtn:SetSize(120, 25)
    postBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
    postBtn:SetText("Post to Chat")
    postBtn:SetScript("OnClick", function()
        self:PostPheromones()
    end)
    
    parent.pheromonesSection = section
end

--[[
    Select a raid and populate boss list
    @param raidId string - Raid ID
]]
function MainFrame:SelectRaid(raidId)
    self.selectedRaid = raidId
    self.selectedBoss = nil
    
    local raid = Bowbassigns.RaidData:GetRaid(raidId)
    if not raid then
        return
    end
    
    -- Clear boss list
    local scrollChild = self.frame.assignmentsContent.bossListPanel.scrollChild
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Create boss buttons
    local bosses = raid.bosses
    local yOffset = -5
    
    for _, bossName in ipairs(bosses) do
        local btn = CreateFrame("Button", nil, scrollChild, "GameMenuButtonTemplate")
        btn:SetSize(210, 30)
        btn:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
        btn:SetText(bossName)
        btn:SetScript("OnClick", function()
            self:SelectBoss(bossName)
        end)
        
        yOffset = yOffset - 35
    end
    
    scrollChild:SetHeight(math.abs(yOffset))
    
    -- Clear assignment panel
    self.frame.assignmentsContent.assignmentPanel.bossTitle:SetText("Select a boss")
    self.frame.assignmentsContent.assignmentPanel.assignmentText:SetText("")
    self.frame.assignmentsContent.assignmentPanel.pheromonesSection:Hide()
end

--[[
    Select a boss and display assignments
    @param bossName string - Boss name
]]
function MainFrame:SelectBoss(bossName)
    self.selectedBoss = bossName
    
    local panel = self.frame.assignmentsContent.assignmentPanel
    panel.bossTitle:SetText(bossName)
    
    -- Show pheromones section if this is Garalon
    if Bowbassigns.RaidData:HasSpecialMechanic(bossName) then
        panel.pheromonesSection:Show()
    else
        panel.pheromonesSection:Hide()
    end
    
    -- Display assignments
    self:RefreshAssignments()
end

--[[
    Refresh assignment display for current boss
]]
function MainFrame:RefreshAssignments()
    if not self.selectedBoss then
        return
    end
    
    local panel = self.frame.assignmentsContent.assignmentPanel
    
    -- Get assignments from AssignmentManager
    local assignments = Bowbassigns.AssignmentManager:GetCooldownsForBoss(self.selectedBoss:upper())
    
    if #assignments == 0 then
        panel.assignmentText:SetText("No assignments loaded for this boss.\n\nClick 'Import Cooldowns' to load data.")
    else
        panel.assignmentText:SetText("Assignments loaded. Click 'Post to Chat' to share.")
    end
end

--[[
    Show roster import modal
]]
function MainFrame:ShowRosterImport()
    Bowbassigns.ImportModal:Show("Import Roster", function(text)
        local parser = Bowbassigns.Managers.DataParser:New()
        local roster, err = parser:ParseRoster(text)
        
        if roster then
            Bowbassigns.AssignmentManager:SetRoster(roster)
            Bowbassigns:Print("Roster imported successfully!")
            self.frame.rosterContent.rosterDisplay:SetText("Roster loaded with " .. 
                Bowbassigns.Utils.TableUtils:Size(roster) .. " entries")
        else
            Bowbassigns:Error("Failed to parse roster: " .. (err or "unknown error"))
        end
    end)
end

--[[
    Show cooldown import modal
]]
function MainFrame:ShowCooldownImport()
    Bowbassigns.ImportModal:Show("Import Cooldowns", function(text)
        local parser = Bowbassigns.Managers.DataParser:New()
        local cooldowns, err = parser:ParseCooldowns(text)
        
        if cooldowns then
            Bowbassigns.AssignmentManager:SetCooldowns(cooldowns)
            Bowbassigns:Print("Cooldowns imported successfully!")
            self:RefreshAssignments()
        else
            Bowbassigns:Error("Failed to parse cooldowns: " .. (err or "unknown error"))
        end
    end)
end

--[[
    Show pheromones import modal
]]
function MainFrame:ShowPheromonesImport()
    Bowbassigns.ImportModal:Show("Import Pheromones", function(text)
        local parser = Bowbassigns.Managers.DataParser:New()
        local pheromones, err = parser:ParsePheromones(text)
        
        if pheromones then
            Bowbassigns.AssignmentManager:SetPheromones(pheromones)
            Bowbassigns:Print("Pheromones imported successfully!")
        else
            Bowbassigns:Error("Failed to parse pheromones: " .. (err or "unknown error"))
        end
    end)
end

--[[
    Post current boss assignments to chat
]]
function MainFrame:PostCurrentBoss()
    if not self.selectedBoss then
        Bowbassigns:Error("No boss selected")
        return
    end
    
    local lines = Bowbassigns.MacroManager:GenerateBossMacro(
        self.selectedBoss:upper(),
        Bowbassigns.AssignmentManager
    )
    
    Bowbassigns.MacroManager:PostToChat(lines)
    Bowbassigns:Print("Posted assignments for " .. self.selectedBoss)
end

--[[
    Post pheromones to chat
]]
function MainFrame:PostPheromones()
    local lines = Bowbassigns.MacroManager:GeneratePheromoneMacro(
        Bowbassigns.AssignmentManager
    )
    Bowbassigns.MacroManager:PostToChat(lines)
end

--[[
    Show the main frame
]]
function MainFrame:Show()
    if not self.frame then
        self:Create()
    end
    self.frame:Show()
    self.isVisible = true
end

--[[
    Hide the main frame
]]
function MainFrame:Hide()
    if self.frame then
        self.frame:Hide()
    end
    self.isVisible = false
end

--[[
    Toggle frame visibility
]]
function MainFrame:Toggle()
    if self.isVisible then
        self:Hide()
    else
        self:Show()
    end
end

