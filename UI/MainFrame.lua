--[[
    MainFrame.lua
    Main UI frame for the addon - Redesigned
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- MainFrame class
local MainFrame = {}
MainFrame.__index = MainFrame
BowbAssigns.UI.MainFrame = MainFrame

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
    
    -- Create main frame with modern styling
    local frame = CreateFrame("Frame", "BowbAssignsMainFrame", UIParent, "BackdropTemplate")
    self.frame = frame
    
    -- Frame properties
    frame:SetSize(900, 650)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    
    -- Add to UISpecialFrames to enable ESC key closing
    table.insert(UISpecialFrames, "BowbAssignsMainFrame")
    
    -- Modern backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(32)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    titleBar:SetBackdropColor(0.15, 0.15, 0.2, 1)
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.5)
    frame.titleBar = titleBar
    
    -- Title text
    frame.title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    frame.title:SetText("BowbAssigns - Raid Assignments")
    frame.title:SetTextColor(1, 0.82, 0, 1)
    
    -- Close button
    frame.closeButton = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    frame.closeButton:SetSize(22, 22)
    frame.closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)
    frame.closeButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame.closeButton:SetBackdropColor(0.3, 0.1, 0.1, 0.8)
    frame.closeButton:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)
    
    local closeText = frame.closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("×")
    closeText:SetTextColor(1, 1, 1, 1)
    
    frame.closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.closeButton:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.6, 0.1, 0.1, 1)
    end)
    frame.closeButton:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.3, 0.1, 0.1, 0.8)
    end)
    
    -- Create tabs
    self:CreateTabs()
    
    -- Create content areas
    self:CreateRosterTab()
    self:CreateAssignmentsTab()
    self:CreateSettingsTab()
    
    -- Initially hide
    frame:Hide()
    
    BowbAssigns:DebugPrint("MainFrame created")
end

--[[
    Style a scrollbar with modern appearance
    @param scrollBar Frame - ScrollBar to style
]]
function MainFrame:StyleScrollBar(scrollBar)
    if not scrollBar then
        return
    end
    
    -- Style the thumb (the draggable part)
    local thumbTexture = scrollBar:GetThumbTexture()
    if thumbTexture then
        thumbTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        thumbTexture:SetVertexColor(0.3, 0.3, 0.35, 0.9)
    end
    
    -- Style the up button
    if scrollBar.ScrollUpButton then
        scrollBar.ScrollUpButton:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        scrollBar.ScrollUpButton:GetNormalTexture():SetVertexColor(0.2, 0.2, 0.25, 0.8)
        scrollBar.ScrollUpButton:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        scrollBar.ScrollUpButton:GetHighlightTexture():SetVertexColor(0.3, 0.3, 0.35, 1)
    end
    
    -- Style the down button
    if scrollBar.ScrollDownButton then
        scrollBar.ScrollDownButton:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        scrollBar.ScrollDownButton:GetNormalTexture():SetVertexColor(0.2, 0.2, 0.25, 0.8)
        scrollBar.ScrollDownButton:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        scrollBar.ScrollDownButton:GetHighlightTexture():SetVertexColor(0.3, 0.3, 0.35, 1)
    end
    
    -- Hide default background textures
    if scrollBar.Background then
        scrollBar.Background:SetAlpha(0)
    end
    if scrollBar.Top then
        scrollBar.Top:SetAlpha(0)
    end
    if scrollBar.Bottom then
        scrollBar.Bottom:SetAlpha(0)
    end
    if scrollBar.Middle then
        scrollBar.Middle:SetAlpha(0)
    end
end

--[[
    Create custom tab button
    @param name string - Tab name
    @param id number - Tab ID
    @param xOffset number - X offset from previous tab (or from frame)
    @param anchor Frame - Anchor point frame
    @param anchorPoint string - Anchor point
    @return Button - Created tab button
]]
function MainFrame:CreateCustomTab(name, id, anchor, anchorPoint, xOffset)
    local frame = self.frame
    
    local tab = CreateFrame("Button", frame:GetName() .. "Tab" .. id, frame, "BackdropTemplate")
    tab:SetSize(120, 28)
    tab:SetPoint("TOPLEFT", anchor, anchorPoint, xOffset, -1)
    tab:SetID(id)
    
    -- Backdrop
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 0 }
    })
    tab:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
    tab:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
    
    -- Text
    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", 0, 0)
    text:SetText(name)
    text:SetTextColor(0.7, 0.7, 0.7, 1)
    tab.text = text
    
    -- Click handler
    tab:SetScript("OnClick", function()
        self:SwitchTab(id)
    end)
    
    -- Hover effects
    tab:SetScript("OnEnter", function(self)
        if self:GetID() ~= frame.selectedTab then
            self:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
        end
    end)
    
    tab:SetScript("OnLeave", function(self)
        if self:GetID() ~= frame.selectedTab then
            self:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
        end
    end)
    
    return tab
end

--[[
    Create tab buttons
]]
function MainFrame:CreateTabs()
    local frame = self.frame
    frame.selectedTab = 1
    
    -- Tab 1: Roster
    local tab1 = self:CreateCustomTab("Roster", 1, frame.titleBar, "BOTTOMLEFT", 5)
    frame.tab1 = tab1
    
    -- Tab 2: Assignments
    local tab2 = self:CreateCustomTab("Assignments", 2, tab1, "TOPRIGHT", 2)
    frame.tab2 = tab2
    
    -- Tab 3: Settings
    local tab3 = self:CreateCustomTab("Settings", 3, tab2, "TOPRIGHT", 2)
    frame.tab3 = tab3
    
    -- Set initial selected tab style
    tab1:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    tab1:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    tab1.text:SetTextColor(1, 0.82, 0, 1)
end

--[[
    Switch to a specific tab
    @param tabId number - Tab ID (1-3)
]]
function MainFrame:SwitchTab(tabId)
    local frame = self.frame
    frame.selectedTab = tabId
    
    -- Update all tabs to unselected style
    local tabs = {frame.tab1, frame.tab2, frame.tab3}
    for _, tab in ipairs(tabs) do
        tab:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
        tab:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
        tab.text:SetTextColor(0.7, 0.7, 0.7, 1)
    end
    
    -- Update selected tab style
    local selectedTab = tabs[tabId]
    selectedTab:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    selectedTab:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    selectedTab.text:SetTextColor(1, 0.82, 0, 1)
    
    -- Hide all content
    frame.rosterContent:Hide()
    frame.assignmentsContent:Hide()
    frame.settingsContent:Hide()
    
    -- Show selected content
    if tabId == 1 then
        frame.rosterContent:Show()
        self:UpdateRosterDisplay()
    elseif tabId == 2 then
        frame.assignmentsContent:Show()
    elseif tabId == 3 then
        frame.settingsContent:Show()
    end
end

--[[
    Create roster tab content
]]
function MainFrame:CreateRosterTab()
    local frame = self.frame
    local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 6, -35)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    content:SetBackdropColor(0.03, 0.03, 0.05, 0.8)
    content:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)
    frame.rosterContent = content
    
    -- Title
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -12)
    title:SetText("Roster Management")
    title:SetTextColor(1, 0.82, 0, 1)
    
    -- Instructions
    local instructions = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -8)
    instructions:SetText("Import your roster to map role identifiers to player names")
    instructions:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Import button
    local importBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    importBtn:SetSize(150, 28)
    importBtn:SetPoint("TOP", instructions, "BOTTOM", 0, -15)
    importBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    importBtn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
    importBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local btnText = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetPoint("CENTER")
    btnText:SetText("Import Roster")
    
    importBtn:SetScript("OnClick", function()
        self:ShowRosterImport()
    end)
    importBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
    end)
    importBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
    end)
    
    -- Roster display - ScrollFrame for better display
    local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", importBtn, "BOTTOM", 0, -20)
    scrollFrame:SetPoint("LEFT", content, "LEFT", 10, 0)
    scrollFrame:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    scrollFrame:SetPoint("BOTTOM", content, "BOTTOM", 0, 10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth() - 20, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    content.rosterScrollFrame = scrollFrame
    content.rosterScrollChild = scrollChild
    
    -- Status text (shows when no roster)
    local statusText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOP", importBtn, "BOTTOM", 0, -20)
    statusText:SetText("No roster loaded")
    content.rosterStatusText = statusText
end

--[[
    Get class from role identifier
    @param role string - Role identifier (e.g., "BLOODDK1", "DISC1")
    @return string|nil - Class name or nil if generic role
]]
local function GetClassFromRole(role)
    -- Map role prefixes to class (specific classes only)
    -- Order matters - check longer prefixes first to avoid partial matches
    local classMap = {
        -- Death Knight
        BLOODDK = "DEATHKNIGHT", FROSTDK = "DEATHKNIGHT", UHDK = "DEATHKNIGHT",
        -- Paladin
        PROTPALA = "PALADIN", RETPALA = "PALADIN", HPALA = "PALADIN",
        -- Druid
        RDRUID = "DRUID", BOOMIE = "DRUID", FERAL = "DRUID",
        -- Priest
        DISC = "PRIEST", HOLYPRIEST = "PRIEST", SPRIEST = "PRIEST",
        -- Shaman
        RSHAM = "SHAMAN", ENH = "SHAMAN", ELE = "SHAMAN",
        -- Monk
        MISTWEAVE = "MONK",
        -- Warrior
        DPSWARR = "WARRIOR", PROTWARR = "WARRIOR",
        -- Rogue
        ROGUE = "ROGUE",
        -- Mage
        MAGE = "MAGE",
        -- Warlock
        LOCK = "WARLOCK",
        -- Hunter
        SURVIVAL = "HUNTER"
    }
    
    -- Try to match role prefix (check longer matches first)
    local sortedPrefixes = {}
    for prefix, _ in pairs(classMap) do
        table.insert(sortedPrefixes, prefix)
    end
    table.sort(sortedPrefixes, function(a, b) return #a > #b end)
    
    for _, prefix in ipairs(sortedPrefixes) do
        if role:find("^" .. prefix) then
            return classMap[prefix]
        end
    end
    
    return nil -- Generic role (TANK1, etc.)
end

--[[
    Get class color
    @param class string|nil - Class name or nil for generic
    @return table - {r, g, b} color values
]]
local function GetClassColor(class)
    if class and RAID_CLASS_COLORS[class] then
        local color = RAID_CLASS_COLORS[class]
        return {color.r, color.g, color.b}
    end
    -- Grey for unknown/generic roles
    return {0.5, 0.5, 0.5}
end

--[[
    Get role priority (lower is better, class-specific roles prioritized)
    @param role string - Role identifier
    @return number - Priority value
]]
local function GetRolePriority(role)
    -- Generic roles have low priority
    if role:find("^TANK%d") or role:find("^HEALER%d") or role:find("^DPS%d") then
        return 10
    end
    -- Class-specific roles have high priority
    return 1
end

--[[
    Update roster display with current roster data
]]
function MainFrame:UpdateRosterDisplay()
    local roster = BowbAssigns.AssignmentManager:GetRoster()
    local content = self.frame.rosterContent
    local scrollChild = content.rosterScrollChild
    local statusText = content.rosterStatusText
    
    -- Clear existing entries
    if scrollChild.entries then
        for _, entry in ipairs(scrollChild.entries) do
            entry:Hide()
            entry:SetParent(nil)
        end
    end
    scrollChild.entries = {}
    
    if not roster or BowbAssigns.Utils.TableUtils:Size(roster) == 0 then
        statusText:Show()
        statusText:SetText("No roster loaded")
        content.rosterScrollFrame:Hide()
        return
    end
    
    -- Hide status text and show scroll frame
    statusText:Hide()
    content.rosterScrollFrame:Show()
    
    -- Group roles by player name
    local playerData = {} -- { [playerName] = { roles = {role1, role2}, bestRole = role, class = class } }
    for role, player in pairs(roster) do
        if not playerData[player] then
            playerData[player] = {
                roles = {},
                bestRole = nil,
                bestPriority = 999,
                class = nil
            }
        end
        
        table.insert(playerData[player].roles, role)
        
        -- Determine if this is the best role to display
        local priority = GetRolePriority(role)
        if priority < playerData[player].bestPriority then
            playerData[player].bestPriority = priority
            playerData[player].bestRole = role
            playerData[player].class = GetClassFromRole(role)
        end
    end
    
    -- Convert to sorted array
    local entries = {}
    for player, data in pairs(playerData) do
        table.insert(entries, {
            player = player,
            roles = data.roles,
            class = data.class,
            bestRole = data.bestRole
        })
    end
    table.sort(entries, function(a, b) return a.player < b.player end)
    
    -- Calculate column width
    local totalWidth = scrollChild:GetWidth() or 500
    local columnWidth = (totalWidth - 20) / 2
    local columnHeight = math.ceil(#entries / 2)
    
    -- Create entries in 2 columns
    for i, data in ipairs(entries) do
        local col = (i <= columnHeight) and 0 or 1
        local row = (i <= columnHeight) and (i - 1) or (i - columnHeight - 1)
        
        local entry = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        entry:SetSize(columnWidth - 5, 28)
        entry:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", col * (columnWidth + 10), -5 - (row * 30))
        
        -- Background
        entry:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 16,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        entry:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
        
        -- Player name (left, class colored)
        local playerText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playerText:SetPoint("LEFT", entry, "LEFT", 8, 0)
        
        -- Build display text with roles in brackets
        -- Show brackets UNLESS they have ONLY a single class-specific role
        local displayText = data.player
        local hasOnlyClassRole = (#data.roles == 1 and data.class ~= nil)
        
        if not hasOnlyClassRole then
            -- Show all non-class roles, or best role if no class
            local rolesToShow = {}
            for _, role in ipairs(data.roles) do
                if role ~= data.bestRole or not data.class then
                    table.insert(rolesToShow, role)
                end
            end
            
            if #rolesToShow > 0 then
                table.sort(rolesToShow)
                displayText = data.player .. " (" .. table.concat(rolesToShow, ", ") .. ")"
            end
        end
        playerText:SetText(displayText)
        
        local classColor = GetClassColor(data.class)
        playerText:SetTextColor(classColor[1], classColor[2], classColor[3], 1)
        entry.playerText = playerText
        
        -- Checkbox (right)
        local checkbox = CreateFrame("CheckButton", nil, entry, "UICheckButtonTemplate")
        checkbox:SetPoint("RIGHT", entry, "RIGHT", -5, 0)
        checkbox:SetSize(22, 22)
        checkbox:SetChecked(true) -- Default to enabled
        checkbox.player = data.player
        checkbox.roles = data.roles
        checkbox:SetScript("OnClick", function(self)
            -- Future: Handle enable/disable for ALL roles of this player
            local status = self:GetChecked() and "enabled" or "disabled"
            local rolesList = table.concat(self.roles, ", ")
            BowbAssigns:DebugPrint(data.player .. " (" .. rolesList .. ") is now " .. status)
        end)
        entry.checkbox = checkbox
        
        table.insert(scrollChild.entries, entry)
    end
    
    -- Update scroll child height
    scrollChild:SetHeight((columnHeight * 30) + 10)
end

--[[
    Create assignments tab content
]]
function MainFrame:CreateAssignmentsTab()
    local frame = self.frame
    local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 6, -35)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    content:SetBackdropColor(0.03, 0.03, 0.05, 0.8)
    content:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)
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
    Create raid dropdown and import button
    @param parent Frame - Parent frame
]]
function MainFrame:CreateRaidDropdown(parent)
    local raids = BowbAssigns.RaidData:GetRaids()
    local mainFrame = self
    
    -- Container for raid buttons
    local buttonContainer = CreateFrame("Frame", nil, parent)
    buttonContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -8)
    buttonContainer:SetSize(600, 30)
    parent.raidButtonContainer = buttonContainer
    
    -- Create raid selection buttons
    local xOffset = 0
    parent.raidButtons = {}
    
    for i, raid in ipairs(raids) do
        if raid.enabled then
            local btn = CreateFrame("Button", nil, buttonContainer, "BackdropTemplate")
            btn:SetSize(70, 26)
            btn:SetPoint("LEFT", buttonContainer, "LEFT", xOffset, 0)
            
            -- Backdrop
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false, tileSize = 16, edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            btn:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
            
            -- Text (show raid ID instead of full name)
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER", 0, 0)
            text:SetText(raid.id)
            text:SetTextColor(0.7, 0.7, 0.7, 1)
            btn.text = text
            btn.raidId = raid.id
            
            -- Click handler
            btn:SetScript("OnClick", function()
                mainFrame:SelectRaid(raid.id)
            end)
            
            -- Hover effects
            btn:SetScript("OnEnter", function(self)
                if parent.selectedRaidId ~= self.raidId then
                    self:SetBackdropColor(0.15, 0.15, 0.18, 0.9)
                end
            end)
            
            btn:SetScript("OnLeave", function(self)
                if parent.selectedRaidId ~= self.raidId then
                    self:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
                end
            end)
            
            table.insert(parent.raidButtons, btn)
            xOffset = xOffset + 72
        end
    end
    
    -- Import Cooldowns button (raid level) - modern style, red
    local importBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    importBtn:SetSize(150, 26)
    importBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -8)
    importBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    importBtn:SetBackdropColor(0.25, 0.08, 0.08, 0.9)
    importBtn:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)
    
    local btnText = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetPoint("CENTER")
    btnText:SetText("Import Cooldowns")
    btnText:SetTextColor(1, 0.8, 0.8, 1)
    
    importBtn:SetScript("OnClick", function()
        self:ShowCooldownImport()
    end)
    
    importBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.35, 0.12, 0.12, 1)
        btnText:SetTextColor(1, 1, 1, 1)
    end)
    
    importBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.25, 0.08, 0.08, 0.9)
        btnText:SetTextColor(1, 0.8, 0.8, 1)
    end)
    
    parent.importButton = importBtn
end

--[[
    Update raid button visual states
    @param selectedRaidId string - Currently selected raid ID
]]
function MainFrame:UpdateRaidButtonStates(selectedRaidId)
    local parent = self.frame.assignmentsContent
    parent.selectedRaidId = selectedRaidId
    
    for _, btn in ipairs(parent.raidButtons) do
        if btn.raidId == selectedRaidId then
            -- Selected state
            btn:SetBackdropColor(0.15, 0.15, 0.2, 1)
            btn:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)
            btn.text:SetTextColor(1, 0.82, 0, 1)
        else
            -- Unselected state
            btn:SetBackdropColor(0.1, 0.1, 0.12, 0.8)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
            btn.text:SetTextColor(0.7, 0.7, 0.7, 1)
        end
    end
end

--[[
    Create boss list panel
    @param parent Frame - Parent frame
]]
function MainFrame:CreateBossListPanel(parent)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -40)
    panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 5, 5)
    panel:SetWidth(250)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    panel:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
    panel:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("Bosses")
    title:SetTextColor(1, 0.82, 0, 1)
    
    -- Container for boss buttons (no scrolling needed)
    local container = CreateFrame("Frame", nil, panel)
    container:SetPoint("TOPLEFT", 10, -35)
    container:SetPoint("BOTTOMRIGHT", -10, 10)
    
    panel.bossContainer = container
    parent.bossListPanel = panel
end

--[[
    Create assignment display panel
    @param parent Frame - Parent frame
]]
function MainFrame:CreateAssignmentPanel(parent)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent.bossListPanel, "TOPRIGHT", 10, 0)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -5, 5)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    panel:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
    panel:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
    
    -- Title area
    local bossTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bossTitle:SetPoint("TOP", panel, "TOP", 0, -12)
    bossTitle:SetText("Select a boss")
    bossTitle:SetTextColor(1, 0.82, 0, 1)
    panel.bossTitle = bossTitle
    
    -- Manage Pheromones button (shown only for Garalon)
    local pheroBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    pheroBtn:SetSize(150, 24)
    pheroBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -15, -10)
    pheroBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    pheroBtn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
    pheroBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    pheroBtn:Hide()
    
    local pheroText = pheroBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pheroText:SetPoint("CENTER")
    pheroText:SetText("Manage Pheromones")
    pheroText:SetTextColor(0.9, 0.9, 0.9, 1)
    
    pheroBtn:SetScript("OnClick", function()
        self:TogglePheromonesView()
    end)
    
    pheroBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        pheroText:SetTextColor(1, 1, 1, 1)
    end)
    
    pheroBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
        pheroText:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    
    panel.pheromonesButton = pheroBtn
    
    -- Assignment display scroll area
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 55)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(580, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Style the scrollbar
    self:StyleScrollBar(scrollFrame.ScrollBar or scrollFrame:GetName() and _G[scrollFrame:GetName().."ScrollBar"])
    
    panel.scrollFrame = scrollFrame
    panel.scrollChild = scrollChild
    panel.collapsedSections = {} -- Track which sections are collapsed
    
    -- Post to Chat button - modern style
    local postBtn = CreateFrame("Button", nil, panel, "BackdropTemplate")
    postBtn:SetSize(140, 28)
    postBtn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
    postBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    postBtn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
    postBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local btnText = postBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetPoint("CENTER")
    btnText:SetText("Post to Chat")
    btnText:SetTextColor(0.9, 0.9, 0.9, 1)
    
    postBtn:SetScript("OnClick", function()
        self:PostCurrentBoss()
    end)
    
    postBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        btnText:SetTextColor(1, 1, 1, 1)
    end)
    
    postBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)
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
    -- Full pheromones management view (replaces assignment display)
    local view = CreateFrame("Frame", nil, parent)
    view:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -45)
    view:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -15, 55)
    view:Hide()
    
    -- Instructions
    local instructions = view:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", view, "TOP", 0, -5)
    instructions:SetText("Drag players to reorder the pheromones assignment")
    instructions:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Scroll frame for player list
    local scrollFrame = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(550, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Style the scrollbar
    self:StyleScrollBar(scrollFrame.ScrollBar or scrollFrame:GetName() and _G[scrollFrame:GetName().."ScrollBar"])
    
    view.scrollFrame = scrollFrame
    view.scrollChild = scrollChild
    
    parent.pheromonesView = view
    
    -- Add buttons to main button area when in pheromones view (centered)
    local btnContainer = CreateFrame("Frame", nil, parent)
    btnContainer:SetSize(280, 28)
    btnContainer:SetPoint("BOTTOM", parent, "BOTTOM", 0, 10)
    btnContainer:Hide()
    
    -- Post Order button (right side, 5px right of center)
    local postBtn = CreateFrame("Button", nil, btnContainer, "BackdropTemplate")
    postBtn:SetSize(110, 26)
    postBtn:SetPoint("LEFT", btnContainer, "CENTER", 5, 0)
    postBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    postBtn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
    postBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local postText = postBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    postText:SetPoint("CENTER")
    postText:SetText("Post Order")
    postText:SetTextColor(0.9, 0.9, 0.9, 1)
    
    postBtn:SetScript("OnClick", function()
        self:PostPheromones()
    end)
    
    postBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        postText:SetTextColor(1, 1, 1, 1)
    end)
    
    postBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
        postText:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    
    -- Import button (left side, 5px left of center)
    local importBtn = CreateFrame("Button", nil, btnContainer, "BackdropTemplate")
    importBtn:SetSize(160, 26)
    importBtn:SetPoint("RIGHT", btnContainer, "CENTER", -5, 0)
    importBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    importBtn:SetBackdropColor(0.25, 0.08, 0.08, 0.9)
    importBtn:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)
    
    local importText = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    importText:SetPoint("CENTER")
    importText:SetText("Import Pheromones")
    importText:SetTextColor(1, 0.8, 0.8, 1)
    
    importBtn:SetScript("OnClick", function()
        self:ShowPheromonesImport()
        self:RefreshPheromonesView()
    end)
    
    importBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.35, 0.12, 0.12, 1)
        importText:SetTextColor(1, 1, 1, 1)
    end)
    
    importBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.25, 0.08, 0.08, 0.9)
        importText:SetTextColor(1, 0.8, 0.8, 1)
    end)
    
    parent.pheromonesButtons = btnContainer
end

--[[
    Select a raid and populate boss list
    @param raidId string - Raid ID
]]
function MainFrame:SelectRaid(raidId)
    self.selectedRaid = raidId
    self.selectedBoss = nil
    
    -- Update raid button states
    self:UpdateRaidButtonStates(raidId)
    
    local raid = BowbAssigns.RaidData:GetRaid(raidId)
    if not raid then
        return
    end
    
    -- Clear boss list
    local container = self.frame.assignmentsContent.bossListPanel.bossContainer
    local children = {container:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Store boss buttons for later reference
    local bossButtons = {}
    self.frame.assignmentsContent.bossButtons = bossButtons
    
    -- Create boss buttons
    local bosses = raid.bosses
    local yOffset = 0
    
    -- Capture self for closures
    local mainFrame = self
    
    for _, boss in ipairs(bosses) do
        local bossName = boss.name or boss
        local bossKey = boss.key or bossName:upper()
        local ejID = boss.ejID
        
        -- Create clickable frame with modern styling
        local btn = CreateFrame("Frame", nil, container, "BackdropTemplate")
        btn:SetSize(230, 32)
        btn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
        btn:EnableMouse(true)
        
        -- Modern background with 1px borders
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 16, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        btn:SetBackdropColor(0.08, 0.08, 0.12, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
        
        -- Boss name text (smaller font)
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 8, 0)
        text:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
        text:SetJustifyH("LEFT")
        text:SetText(bossName)
        text:SetTextColor(0.9, 0.9, 0.9, 1)
        btn.text = text
        
        -- Store boss data for click handler
        btn.bossName = bossName
        btn.bossKey = bossKey
        
        -- Mouse interactions with modern styling
        btn:SetScript("OnEnter", function(self)
            if mainFrame.selectedBoss ~= self.bossName then
                self:SetBackdropColor(0.12, 0.12, 0.16, 1)
                self:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)
                text:SetTextColor(1, 1, 1, 1)
            end
        end)
        
        btn:SetScript("OnLeave", function(self)
            if mainFrame.selectedBoss ~= self.bossName then
                self:SetBackdropColor(0.08, 0.08, 0.12, 0.9)
                self:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
                text:SetTextColor(0.9, 0.9, 0.9, 1)
            end
        end)
        
        btn:SetScript("OnMouseDown", function(self)
            self:SetBackdropColor(0.05, 0.05, 0.08, 1)
        end)
        
        btn:SetScript("OnMouseUp", function(self)
            if mainFrame.selectedBoss ~= self.bossName then
                self:SetBackdropColor(0.12, 0.12, 0.16, 1)
            end
            -- Trigger boss selection with key
            mainFrame:SelectBoss(self.bossName, self.bossKey)
        end)
        
        table.insert(bossButtons, btn)
        yOffset = yOffset - 34
    end
    
    -- Clear assignment panel
    self.frame.assignmentsContent.assignmentPanel.bossTitle:SetText("Select a boss")
    self.frame.assignmentsContent.assignmentPanel.assignmentText:SetText("")
    self.frame.assignmentsContent.assignmentPanel.pheromonesSection:Hide()
end

--[[
    Select a boss and display assignments
    @param bossName string - Boss name
    @param bossKey string - Boss key for lookups (optional)
]]
function MainFrame:SelectBoss(bossName, bossKey)
    self.selectedBoss = bossName
    self.selectedBossKey = bossKey or bossName:upper()
    
    -- Update boss button states
    self:UpdateBossButtonStates(bossName)
    
    local panel = self.frame.assignmentsContent.assignmentPanel
    panel.bossTitle:SetText(bossName)
    
    -- Show/hide pheromones button for Garalon
    if BowbAssigns.RaidData:HasSpecialMechanic(bossName) then
        panel.pheromonesButton:Show()
    else
        panel.pheromonesButton:Hide()
    end
    
    -- Ensure we're showing assignments view (not pheromones)
    panel.pheromonesView:Hide()
    panel.pheromonesButtons:Hide()
    panel.scrollFrame:Show()
    panel.postButton:Show()
    panel.pheromonesButton:SetText("Manage Pheromones")
    
    -- Display assignments
    self:RefreshAssignments()
end

--[[
    Toggle between assignments view and pheromones management view
]]
function MainFrame:TogglePheromonesView()
    local panel = self.frame.assignmentsContent.assignmentPanel
    local isShowingPheromones = panel.pheromonesView:IsShown()
    
    if isShowingPheromones then
        -- Switch back to assignments
        panel.pheromonesView:Hide()
        panel.pheromonesButtons:Hide()
        panel.scrollFrame:Show()
        panel.postButton:Show()
        panel.pheromonesButton:SetText("Manage Pheromones")
        self:RefreshAssignments()
    else
        -- Switch to pheromones view
        panel.scrollFrame:Hide()
        panel.postButton:Hide()
        panel.pheromonesView:Show()
        panel.pheromonesButtons:Show()
        panel.pheromonesButton:SetText("Back to Assignments")
        self:RefreshPheromonesView()
    end
end

--[[
    Refresh the pheromones management view with current data
]]
function MainFrame:RefreshPheromonesView()
    local panel = self.frame.assignmentsContent.assignmentPanel
    local scrollChild = panel.pheromonesView.scrollChild
    
    -- Clear existing entries
    if scrollChild.entries then
        for _, entry in ipairs(scrollChild.entries) do
            entry:Hide()
            entry:SetParent(nil)
        end
    end
    scrollChild.entries = {}
    
    -- Get current pheromones order
    local pheromones = BowbAssigns.AssignmentManager:GetPheromones()
    
    if #pheromones == 0 then
        local noDataText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
        noDataText:SetText("No pheromones order loaded.\n\nClick 'Import Pheromones' to load the player order.")
        noDataText:SetTextColor(0.7, 0.7, 0.7, 1)
        table.insert(scrollChild.entries, noDataText)
        scrollChild:SetHeight(100)
        return
    end
    
    -- Create draggable player entries
    local yOffset = 0
    for i, playerName in ipairs(pheromones) do
        local entry = self:CreateDraggablePheromonesEntry(scrollChild, playerName, i, yOffset)
        table.insert(scrollChild.entries, entry)
        yOffset = yOffset - 32
    end
    
    scrollChild:SetHeight(math.abs(yOffset) + 10)
end

--[[
    Create a draggable pheromones entry
    @param parent Frame - Parent frame
    @param playerName string - Player name
    @param index number - Current index in list
    @param yOffset number - Y offset for positioning
    @return Frame - Created entry
]]
function MainFrame:CreateDraggablePheromonesEntry(parent, playerName, index, yOffset)
    local entry = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    entry:SetSize(540, 30)
    entry:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
    
    -- Capture mainFrame reference
    local mainFrame = self
    
    -- Background
    entry:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    entry:SetBackdropColor(0.08, 0.08, 0.12, 0.9)
    entry:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
    
    entry.playerName = playerName
    entry.index = index
    
    -- Index number container with border
    local indexContainer = CreateFrame("Frame", nil, entry, "BackdropTemplate")
    indexContainer:SetSize(32, 22)
    indexContainer:SetPoint("LEFT", entry, "LEFT", 8, 0)
    indexContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    indexContainer:SetBackdropColor(0.05, 0.05, 0.08, 0.9)
    indexContainer:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
    
    -- Index number (editable)
    local indexBox = CreateFrame("EditBox", nil, indexContainer)
    indexBox:SetSize(28, 18)
    indexBox:SetPoint("CENTER")
    indexBox:SetFontObject("GameFontNormal")
    indexBox:SetTextColor(0.7, 0.7, 0.7, 1)
    indexBox:SetAutoFocus(false)
    indexBox:SetNumeric(true)
    indexBox:SetMaxLetters(3)
    indexBox:SetText(tostring(index))
    indexBox:SetCursorPosition(0)
    indexBox:SetJustifyH("CENTER")
    entry.indexBox = indexBox
    entry.indexContainer = indexContainer
    
    -- Handle position change
    indexBox:SetScript("OnEnterPressed", function(self)
        local newPos = tonumber(self:GetText())
        if newPos and newPos > 0 then
            mainFrame:MovePheromonesTo(index, newPos)
        else
            self:SetText(tostring(index))
        end
        self:ClearFocus()
    end)
    
    indexBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(index))
        self:ClearFocus()
    end)
    
    indexBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
        self:SetTextColor(1, 0.82, 0, 1)
        indexContainer:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)
    
    indexBox:SetScript("OnEditFocusLost", function(self)
        self:SetText(tostring(entry.index))
        self:SetTextColor(0.7, 0.7, 0.7, 1)
        self:HighlightText(0, 0)
        indexContainer:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
    end)
    
    -- Player name (with class color)
    local classColor = self:GetPlayerClassColor(playerName)
    local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", indexContainer, "RIGHT", 10, 0)
    nameText:SetText(playerName)
    nameText:SetTextColor(classColor[1], classColor[2], classColor[3], 1)
    
    -- Remove button (X) - rightmost
    local removeBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    removeBtn:SetSize(22, 22)
    removeBtn:SetPoint("RIGHT", entry, "RIGHT", -5, 0)
    removeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    removeBtn:SetBackdropColor(0.3, 0.1, 0.1, 0.9)
    removeBtn:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)
    
    local removeText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    removeText:SetPoint("CENTER")
    removeText:SetText("×")
    removeText:SetTextColor(1, 0.8, 0.8, 1)
    
    removeBtn:SetScript("OnClick", function()
        mainFrame:RemoveFromPheromones(index)
    end)
    
    removeBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.5, 0.1, 0.1, 1)
        removeText:SetTextColor(1, 1, 1, 1)
    end)
    
    removeBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.3, 0.1, 0.1, 0.9)
        removeText:SetTextColor(1, 0.8, 0.8, 1)
    end)
    
    -- Down arrow button
    local downBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    downBtn:SetSize(22, 22)
    downBtn:SetPoint("RIGHT", removeBtn, "LEFT", -3, 0)
    downBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    downBtn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
    downBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local downText = downBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    downText:SetPoint("CENTER", 0, -8)
    downText:SetText("^")
    downText:SetTextColor(0.9, 0.9, 0.9, 1)
    downText:SetRotation(math.pi) -- Rotate 180 degrees
    
    downBtn:SetScript("OnClick", function()
        mainFrame:MovePheromonesDown(index)
    end)
    
    downBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        downText:SetTextColor(1, 1, 1, 1)
    end)
    
    downBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
        downText:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    
    -- Up arrow button
    local upBtn = CreateFrame("Button", nil, entry, "BackdropTemplate")
    upBtn:SetSize(22, 22)
    upBtn:SetPoint("RIGHT", downBtn, "LEFT", -3, 0)
    upBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    upBtn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
    upBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local upText = upBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    upText:SetPoint("CENTER", 0, -2)
    upText:SetText("^")
    upText:SetTextColor(0.9, 0.9, 0.9, 1)
    
    upBtn:SetScript("OnClick", function()
        mainFrame:MovePheromonesUp(index)
    end)
    
    upBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        upText:SetTextColor(1, 1, 1, 1)
    end)
    
    upBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
        upText:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    
    return entry
end

--[[
    Reorder pheromones list
    @param fromIndex number - Original index
    @param toIndex number - New index
]]
function MainFrame:ReorderPheromones(fromIndex, toIndex)
    local pheromones = BowbAssigns.AssignmentManager:GetPheromones()
    
    -- Remove from old position
    local player = table.remove(pheromones, fromIndex)
    
    -- Insert at new position
    table.insert(pheromones, toIndex, player)
    
    -- Save the new order
    BowbAssigns.AssignmentManager:SetPheromones(pheromones)
    
    -- Refresh the view
    self:RefreshPheromonesView()
    
    BowbAssigns:DebugPrint("Reordered: " .. player .. " moved from position " .. fromIndex .. " to " .. toIndex)
end

--[[
    Move pheromones entry up one position
    @param index number - Current index
]]
function MainFrame:MovePheromonesUp(index)
    if index <= 1 then
        return -- Already at top
    end
    self:ReorderPheromones(index, index - 1)
end

--[[
    Move pheromones entry down one position
    @param index number - Current index
]]
function MainFrame:MovePheromonesDown(index)
    local pheromones = BowbAssigns.AssignmentManager:GetPheromones()
    if index >= #pheromones then
        return -- Already at bottom
    end
    self:ReorderPheromones(index, index + 1)
end

--[[
    Move pheromones entry to a specific position (shuffles others up)
    @param fromIndex number - Current index
    @param toIndex number - Target position
]]
function MainFrame:MovePheromonesTo(fromIndex, toIndex)
    local pheromones = BowbAssigns.AssignmentManager:GetPheromones()
    
    -- Validate bounds
    if toIndex < 1 or toIndex > #pheromones then
        BowbAssigns:Print("Position must be between 1 and " .. #pheromones)
        return
    end
    
    if fromIndex == toIndex then
        return -- No change needed
    end
    
    -- Remove from old position
    local player = table.remove(pheromones, fromIndex)
    
    -- Insert at new position (this automatically shifts others)
    table.insert(pheromones, toIndex, player)
    
    -- Save the new order
    BowbAssigns.AssignmentManager:SetPheromones(pheromones)
    
    -- Refresh the view
    self:RefreshPheromonesView()
    
    BowbAssigns:DebugPrint(player .. " moved to position " .. toIndex)
end

--[[
    Remove player from pheromones list
    @param index number - Index to remove
]]
function MainFrame:RemoveFromPheromones(index)
    local pheromones = BowbAssigns.AssignmentManager:GetPheromones()
    local player = pheromones[index]
    
    table.remove(pheromones, index)
    BowbAssigns.AssignmentManager:SetPheromones(pheromones)
    
    self:RefreshPheromonesView()
    
    BowbAssigns:DebugPrint("Removed " .. player .. " from pheromones order")
end

--[[
    Get player class color from roster
    @param playerName string - Player name
    @return table - RGB color values
]]
function MainFrame:GetPlayerClassColor(playerName)
    local roster = BowbAssigns.AssignmentManager:GetRoster()
    
    -- Find player in roster
    for roleKey, name in pairs(roster) do
        if name == playerName then
            -- Extract class from role key
            local classKey = self:ExtractClassFromRole(roleKey)
            if classKey then
                local classColor = RAID_CLASS_COLORS[classKey]
                if classColor then
                    return {classColor.r, classColor.g, classColor.b}
                end
            end
        end
    end
    
    -- Default to grey if class not found
    return {0.7, 0.7, 0.7}
end

--[[
    Extract class key from role string
    @param roleKey string - Role key (e.g., "BLOODDK1", "TANK1")
    @return string|nil - Class key or nil
]]
function MainFrame:ExtractClassFromRole(roleKey)
    local classMap = {
        ["BLOODDK"] = "DEATHKNIGHT",
        ["FROSTDK"] = "DEATHKNIGHT",
        ["UHDK"] = "DEATHKNIGHT",
        ["PROTPALA"] = "PALADIN",
        ["RETPALA"] = "PALADIN",
        ["HPALA"] = "PALADIN",
        ["PROTWARR"] = "WARRIOR",
        ["DPSWARR"] = "WARRIOR",
        ["RDRUID"] = "DRUID",
        ["FERAL"] = "DRUID",
        ["BOOMIE"] = "DRUID",
        ["DISC"] = "PRIEST",
        ["HOLYPRIEST"] = "PRIEST",
        ["SPRIEST"] = "PRIEST",
        ["RSHAM"] = "SHAMAN",
        ["ENH"] = "SHAMAN",
        ["ELE"] = "SHAMAN",
        ["MISTWEAVE"] = "MONK",
        ["BREWMASTER"] = "MONK",
        ["WINDWALKER"] = "MONK",
        ["ROGUE"] = "ROGUE",
        ["MAGE"] = "MAGE",
        ["LOCK"] = "WARLOCK",
        ["SURVIVAL"] = "HUNTER",
        ["BM"] = "HUNTER",
        ["MM"] = "HUNTER",
    }
    
    for prefix, class in pairs(classMap) do
        if roleKey:find("^" .. prefix) then
            return class
        end
    end
    
    return nil
end

--[[
    Update boss button visual states
    @param selectedBossName string - Currently selected boss name
]]
function MainFrame:UpdateBossButtonStates(selectedBossName)
    local bossButtons = self.frame.assignmentsContent.bossButtons
    if not bossButtons then
        return
    end
    
    for _, btn in ipairs(bossButtons) do
        if btn.bossName == selectedBossName then
            -- Selected state
            btn:SetBackdropColor(0.15, 0.15, 0.2, 1)
            btn:SetBackdropBorderColor(0.6, 0.6, 0.65, 1)
            btn.text:SetTextColor(1, 0.82, 0, 1)
        else
            -- Unselected state
            btn:SetBackdropColor(0.08, 0.08, 0.12, 0.9)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
            btn.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end
    end
end

--[[
    Refresh assignment display for current boss
]]
function MainFrame:RefreshAssignments()
    if not self.selectedBoss then
        return
    end
    
    local panel = self.frame.assignmentsContent.assignmentPanel
    local scrollChild = panel.scrollChild
    
    -- Clear existing UI elements
    if scrollChild.sections then
        for _, section in ipairs(scrollChild.sections) do
            section:Hide()
            section:SetParent(nil)
        end
    end
    scrollChild.sections = {}
    
    -- Clear any existing no-data text
    if scrollChild.noDataText then
        scrollChild.noDataText:Hide()
        scrollChild.noDataText:SetText("")
    end
    
    -- Use boss key for lookup (more reliable than full name)
    local lookupKey = self.selectedBossKey or self.selectedBoss:upper()
    local assignments = BowbAssigns.AssignmentManager:GetCooldownsForBoss(lookupKey)
    
    if #assignments == 0 then
        if not scrollChild.noDataText then
            scrollChild.noDataText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            scrollChild.noDataText:SetPoint("TOPLEFT", 5, -5)
        end
        scrollChild.noDataText:SetText("No assignments loaded for this boss.\n\nClick 'Import Cooldowns' to load data.")
        scrollChild.noDataText:Show()
        scrollChild:SetHeight(100)
        return
    end
    
    -- Build collapsible UI
    local yOffset = -5
    local structuredData = self:BuildStructuredAssignments(lookupKey, assignments)
    
    for _, abilityData in ipairs(structuredData) do
        local section = self:CreateAbilitySection(scrollChild, abilityData, yOffset)
        table.insert(scrollChild.sections, section)
        yOffset = yOffset - section.totalHeight
    end
    
    scrollChild:SetHeight(math.abs(yOffset) + 10)
end

--[[
    Build structured assignment data for UI display
    @param bossKey string - Boss key
    @param assignments table - Array of assignments
    @return table - Structured ability data
]]
function MainFrame:BuildStructuredAssignments(bossKey, assignments)
    local assignmentManager = BowbAssigns.AssignmentManager
    
    -- Group by ability, tracking global index
    local byAbility = {}
    for globalIndex, assignment in ipairs(assignments) do
        -- Skip if role is not rostered (unless it's "ALL")
        local resolvedName = assignmentManager:ResolveRole(assignment.role)
        if resolvedName ~= assignment.role or assignment.role == "ALL" then
            -- Add global index to assignment for tracking
            assignment.globalIndex = globalIndex
            
            if not byAbility[assignment.ability] then
                byAbility[assignment.ability] = {}
            end
            table.insert(byAbility[assignment.ability], assignment)
        end
    end
    
    -- Sort abilities and build structured data
    local sortedAbilities = {}
    for ability in pairs(byAbility) do
        table.insert(sortedAbilities, ability)
    end
    table.sort(sortedAbilities)
    
    local result = {}
    for _, ability in ipairs(sortedAbilities) do
        local abilityData = {
            ability = ability,
            displayName = self:FormatAbilityName(ability),
            isHealthPercent = ability:find("HEALTH") ~= nil,
            casts = {}
        }
        
        local abilityAssignments = byAbility[ability]
        
        -- Group by count (cast number or health %)
        local byCount = {}
        for _, assignment in ipairs(abilityAssignments) do
            local count = assignment.count or "default"
            
            -- Split comma-separated counts
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
        
        -- Sort counts
        local sortedCounts = {}
        for count in pairs(byCount) do
            table.insert(sortedCounts, count)
        end
        
        table.sort(sortedCounts, function(a, b)
            local numA = tonumber(a:match("^(%d+)")) or 999
            local numB = tonumber(b:match("^(%d+)")) or 999
            
            if abilityData.isHealthPercent then
                return numA > numB
            else
                return numA < numB
            end
        end)
        
        -- Build cast data
        for _, count in ipairs(sortedCounts) do
            local countAssignments = byCount[count]
            
            -- Sort by timing
            table.sort(countAssignments, function(a, b)
                local timeA = tonumber(a.timing) or 0
                local timeB = tonumber(b.timing) or 0
                return timeA < timeB
            end)
            
            table.insert(abilityData.casts, {
                count = count,
                assignments = countAssignments
            })
        end
        
        table.insert(result, abilityData)
    end
    
    return result
end

--[[
    Format ability name for display
    @param ability string - Raw ability name
    @return string - Formatted ability name
]]
function MainFrame:FormatAbilityName(ability)
    local name = ability:gsub("_", " ")
    name = name:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return name
end

--[[
    Create a collapsible ability section
    @param parent Frame - Parent frame
    @param abilityData table - Ability data structure
    @param yOffset number - Y offset for positioning
    @return Frame - Created section
]]
function MainFrame:CreateAbilitySection(parent, abilityData, yOffset)
    local panel = self.frame.assignmentsContent.assignmentPanel
    local sectionKey = abilityData.ability
    
    -- Check if ability is disabled
    local isDisabled = BowbAssigns.AssignmentManager:IsDisabled(
        self.selectedBossKey,
        abilityData.ability,
        nil  -- nil = entire ability
    )
    
    -- Default to collapsed if disabled, unless explicitly set
    local isCollapsed
    if panel.collapsedSections[sectionKey] ~= nil then
        isCollapsed = panel.collapsedSections[sectionKey]
    else
        isCollapsed = isDisabled  -- Auto-collapse if disabled
    end
    
    -- Main section frame
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
    section:SetWidth(550)
    section:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    section:SetBackdropColor(0.05, 0.05, 0.05, 0.5)
    section:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    
    -- Header (clickable to collapse/expand)
    local header = CreateFrame("Button", nil, section, "BackdropTemplate")
    header:SetPoint("TOPLEFT", section, "TOPLEFT", 2, -2)
    header:SetSize(546, 25)
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    header:SetBackdropColor(0.2, 0.2, 0.3, 0.9)
    header:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
    
    -- Collapse indicator
    local indicator = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    indicator:SetPoint("LEFT", header, "LEFT", 5, 0)
    indicator:SetText(isCollapsed and "+" or "-")
    indicator:SetTextColor(1, 0.8, 0, 1)
    header.indicator = indicator
    
    -- Ability name
    local titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", indicator, "RIGHT", 5, 0)
    titleText:SetText(abilityData.displayName)
    titleText:SetTextColor(1, 1, 0.5, 1)
    
    -- Checkbox for entire ability (parented to section, not header, to avoid click conflicts)
    local checkbox = CreateFrame("CheckButton", nil, section, "UICheckButtonTemplate")
    checkbox:SetPoint("RIGHT", header, "RIGHT", -5, 0)
    checkbox:SetSize(20, 20)
    checkbox:EnableMouse(true)
    checkbox:SetFrameLevel(header:GetFrameLevel() + 2) -- Well above header
    
    -- Set checkbox state (isDisabled was calculated above)
    checkbox:SetChecked(not isDisabled)
    
    checkbox.ability = abilityData.ability
    section.checkbox = checkbox
    
    -- Content container
    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    content:SetWidth(546)
    section.content = content
    
    -- Build cast entries
    local contentHeight = 0
    if not isCollapsed then
        contentHeight = self:BuildCastEntries(content, abilityData)
    end
    content:SetHeight(contentHeight)
    
    -- Capture mainFrame instance for click handler
    local mainFrame = self
    
    -- Toggle collapse on click
    header:SetScript("OnClick", function(self, button)
        isCollapsed = not isCollapsed
        panel.collapsedSections[sectionKey] = isCollapsed
        mainFrame:RefreshAssignments()
    end)
    
    -- Handle checkbox clicks
    checkbox:SetScript("OnClick", function(self)
        local isEnabled = self:GetChecked()
        local isDisabled = not isEnabled
        
        -- Save disabled state
        BowbAssigns.AssignmentManager:SetDisabled(
            mainFrame.selectedBossKey,
            abilityData.ability,
            isDisabled,
            nil  -- nil = entire ability
        )
        
        -- Auto-collapse when disabling, auto-expand when enabling
        if isDisabled then
            panel.collapsedSections[sectionKey] = true
        else
            panel.collapsedSections[sectionKey] = false
        end
        
        local status = isEnabled and "enabled" or "disabled"
        BowbAssigns:DebugPrint(abilityData.displayName .. " is now " .. status .. " (boss: " .. mainFrame.selectedBossKey .. ", ability: " .. abilityData.ability .. ")")
        
        -- Refresh to show collapsed/expanded state
        mainFrame:RefreshAssignments()
        
        -- Don't propagate to header
        return true
    end)
    
    header:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.4, 1)
    end)
    
    header:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.3, 0.9)
    end)
    
    section.totalHeight = 29 + contentHeight + 7 -- header + content + spacing
    section:SetHeight(section.totalHeight)
    
    return section
end

--[[
    Get class color for a player based on their role
    @param role string - Role identifier
    @return table - {r, g, b} color values
]]
local function GetPlayerClassColor(role)
    -- Map role prefixes to class (same as roster)
    local classMap = {
        -- Death Knight
        BLOODDK = "DEATHKNIGHT", FROSTDK = "DEATHKNIGHT", UHDK = "DEATHKNIGHT",
        -- Paladin
        PROTPALA = "PALADIN", RETPALA = "PALADIN", HPALA = "PALADIN",
        -- Druid
        RDRUID = "DRUID", BOOMIE = "DRUID", FERAL = "DRUID",
        -- Priest
        DISC = "PRIEST", HOLYPRIEST = "PRIEST", SPRIEST = "PRIEST",
        -- Shaman
        RSHAM = "SHAMAN", ENH = "SHAMAN", ELE = "SHAMAN",
        -- Monk
        MISTWEAVE = "MONK",
        -- Warrior
        DPSWARR = "WARRIOR", PROTWARR = "WARRIOR",
        -- Rogue
        ROGUE = "ROGUE",
        -- Mage
        MAGE = "MAGE",
        -- Warlock
        LOCK = "WARLOCK",
        -- Hunter
        SURVIVAL = "HUNTER"
    }
    
    -- Sort prefixes by length (longer first)
    local sortedPrefixes = {}
    for prefix, _ in pairs(classMap) do
        table.insert(sortedPrefixes, prefix)
    end
    table.sort(sortedPrefixes, function(a, b) return #a > #b end)
    
    for _, prefix in ipairs(sortedPrefixes) do
        if role:find("^" .. prefix) then
            local class = classMap[prefix]
            if RAID_CLASS_COLORS[class] then
                local color = RAID_CLASS_COLORS[class]
                return {color.r, color.g, color.b}
            end
        end
    end
    
    -- Default white for ALL or unknown
    return {1, 1, 1}
end

--[[
    Build cast entries within an ability section
    @param parent Frame - Parent frame
    @param abilityData table - Ability data
    @return number - Total height used
]]
function MainFrame:BuildCastEntries(parent, abilityData)
    local yOffset = -2
    local assignmentManager = BowbAssigns.AssignmentManager
    local rowIndex = 0
    
    for _, castData in ipairs(abilityData.casts) do
        -- Cast/Health header (if applicable)
        if castData.count ~= "default" and castData.count ~= "-1" then
            local castHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            castHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
            
            local headerText
            if abilityData.isHealthPercent then
                headerText = "At " .. castData.count .. "%:"
            else
                headerText = "Cast #" .. castData.count .. ":"
            end
            castHeader:SetText(headerText)
            castHeader:SetTextColor(0, 1, 0, 1)
            
            yOffset = yOffset - 18
        end
        
        -- Assignment rows
        for _, assignment in ipairs(castData.assignments) do
            rowIndex = rowIndex + 1
            local isEvenRow = (rowIndex % 2 == 0)
            
            local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
            row:SetSize(536, 20)
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false, tileSize = 16, edgeSize = 1,
                insets = { left = 1, right = 1, top = 0, bottom = 0 }
            })
            
            -- Alternating background colors
            if isEvenRow then
                row:SetBackdropColor(0.08, 0.08, 0.12, 0.8)
            else
                row:SetBackdropColor(0.05, 0.05, 0.08, 0.8)
            end
            row:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.3)
            
            -- Timing
            local timingNum = tonumber(assignment.timing) or 0
            local timingText = ""
            if timingNum < 0 then
                timingText = assignment.timing .. "s"
            elseif timingNum > 0 then
                timingText = "+" .. assignment.timing .. "s"
            else
                timingText = "0s"
            end
            
            local timing = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            timing:SetPoint("LEFT", row, "LEFT", 8, 0)
            timing:SetText(timingText)
            timing:SetTextColor(0.6, 0.6, 0.6, 1)
            timing:SetWidth(45)
            timing:SetJustifyH("LEFT")
            
            -- Player name (class colored)
            local playerName = assignmentManager:ResolveRole(assignment.role)
            local classColor = GetPlayerClassColor(assignment.role)
            
            local player = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            player:SetPoint("LEFT", timing, "RIGHT", 5, 0)
            player:SetText(playerName)
            player:SetTextColor(classColor[1], classColor[2], classColor[3], 1)
            player:SetWidth(100)
            player:SetJustifyH("LEFT")
            
            -- Spell link
            local spellLink = ""
            if assignment.spellId and assignment.spellId ~= "nil" and tonumber(assignment.spellId) then
                spellLink = GetSpellLink(tonumber(assignment.spellId)) or ""
            end
            
            local spell = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            spell:SetPoint("LEFT", player, "RIGHT", 5, 0)
            spell:SetText(spellLink)
            spell:SetWidth(120)
            spell:SetJustifyH("LEFT")
            
            -- Note (comment3)
            local lastAnchor = spell
            if assignment.comment3 and assignment.comment3 ~= "nil" then
                local note = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                note:SetPoint("LEFT", lastAnchor, "RIGHT", 5, 0)
                note:SetText(assignment.comment3)
                note:SetTextColor(0.8, 0.8, 0.8, 1)
                note:SetWidth(180)
                note:SetJustifyH("LEFT")
            end
            
            -- Checkbox at the end
            local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            checkbox:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            checkbox:SetSize(18, 18)
            
            -- Use global index for consistent tracking
            local globalIndex = assignment.globalIndex or rowIndex
            
            -- Load saved disabled state
            local isDisabled = BowbAssigns.AssignmentManager:IsDisabled(
                self.selectedBossKey,
                abilityData.ability,
                globalIndex
            )
            checkbox:SetChecked(not isDisabled)
            
            checkbox.assignment = assignment
            checkbox.assignmentIndex = globalIndex
            
            -- Capture mainFrame for closure
            local mainFrame = self
            
            checkbox:SetScript("OnClick", function(self)
                local isEnabled = self:GetChecked()
                local isDisabled = not isEnabled
                
                -- Save disabled state
                BowbAssigns.AssignmentManager:SetDisabled(
                    mainFrame.selectedBossKey,
                    abilityData.ability,
                    isDisabled,
                    self.assignmentIndex
                )
                
                local status = isEnabled and "enabled" or "disabled"
                BowbAssigns:DebugPrint(playerName .. " assignment is now " .. status .. " (index: " .. self.assignmentIndex .. ", ability: " .. abilityData.ability .. ")")
            end)
            row.checkbox = checkbox
            
            yOffset = yOffset - 21
        end
    end
    
    return math.abs(yOffset) + 5
end

--[[
    Format assignments for display in the UI (LEGACY - kept for compatibility)
    @param bossKey string - Boss key
    @param assignments table - Array of assignments
    @return table - Array of formatted lines
]]
function MainFrame:FormatAssignmentsForDisplay(bossKey, assignments)
    local lines = {}
    local assignmentManager = BowbAssigns.AssignmentManager
    
    -- Group by ability
    local byAbility = {}
    for _, assignment in ipairs(assignments) do
        -- Skip if role is not rostered (unless it's "ALL")
        local resolvedName = assignmentManager:ResolveRole(assignment.role)
        if resolvedName ~= assignment.role or assignment.role == "ALL" then
            if not byAbility[assignment.ability] then
                byAbility[assignment.ability] = {}
            end
            table.insert(byAbility[assignment.ability], assignment)
        end
    end
    
    -- Sort abilities
    local sortedAbilities = {}
    for ability in pairs(byAbility) do
        table.insert(sortedAbilities, ability)
    end
    table.sort(sortedAbilities)
    
    -- Format each ability group
    for _, ability in ipairs(sortedAbilities) do
        local abilityAssignments = byAbility[ability]
        
        -- Clean up ability name
        local abilityName = ability:gsub("_", " ")
        abilityName = abilityName:gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
        
        table.insert(lines, "|cFFFFD700-- " .. abilityName .. " --|r")
        
        -- Group by count
        local byCount = {}
        for _, assignment in ipairs(abilityAssignments) do
            local count = assignment.count or "default"
            
            -- Split comma-separated counts
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
        
        -- Sort counts
        local sortedCounts = {}
        for count in pairs(byCount) do
            table.insert(sortedCounts, count)
        end
        
        local isHealthPercent = ability:find("HEALTH") ~= nil
        table.sort(sortedCounts, function(a, b)
            local numA = tonumber(a:match("^(%d+)")) or 999
            local numB = tonumber(b:match("^(%d+)")) or 999
            
            if isHealthPercent then
                return numA > numB
            else
                return numA < numB
            end
        end)
        
        -- Format each count group
        for _, count in ipairs(sortedCounts) do
            local countAssignments = byCount[count]
            
            -- Sort by timing
            table.sort(countAssignments, function(a, b)
                local timeA = tonumber(a.timing) or 0
                local timeB = tonumber(b.timing) or 0
                return timeA < timeB
            end)
            
            -- Count label
            local countLabel
            if count == "default" or count == "-1" then
                countLabel = ""
            elseif isHealthPercent then
                countLabel = "|cFF00FF00At " .. count .. "%:|r"
            else
                countLabel = "|cFF00FF00Cast #" .. count .. ":|r"
            end
            
            if countLabel ~= "" then
                table.insert(lines, "  " .. countLabel)
            end
            
            -- Format assignments
            for _, assignment in ipairs(countAssignments) do
                local name = assignmentManager:ResolveRole(assignment.role)
                local timing = ""
                
                local timingNum = tonumber(assignment.timing) or 0
                if timingNum < 0 then
                    timing = "[" .. assignment.timing .. "s] "
                elseif timingNum > 0 then
                    timing = "[+" .. assignment.timing .. "s] "
                else
                    timing = "[0s] "
                end
                
                local note = ""
                if assignment.comment3 and assignment.comment3 ~= "nil" then
                    note = " - " .. assignment.comment3
                end
                
                table.insert(lines, "    " .. timing .. name .. note)
            end
        end
        
        table.insert(lines, "") -- Empty line between abilities
    end
    
    return lines
end

--[[
    Show roster import modal
]]
function MainFrame:ShowRosterImport()
    BowbAssigns.ImportModal:Show("Import Roster", function(text)
        local parser = BowbAssigns.Managers.DataParser:New()
        local roster, err = parser:ParseRoster(text)
        
        if roster then
            BowbAssigns.AssignmentManager:SetRoster(roster)
            BowbAssigns:Print("Roster imported successfully! (" .. 
                BowbAssigns.Utils.TableUtils:Size(roster) .. " entries)")
            self:UpdateRosterDisplay()
        else
            BowbAssigns:Error("Failed to parse roster: " .. (err or "unknown error"))
        end
    end)
end

--[[
    Show cooldown import modal
]]
function MainFrame:ShowCooldownImport()
    BowbAssigns.ImportModal:Show("Import Cooldowns", function(text)
        local parser = BowbAssigns.Managers.DataParser:New()
        local cooldowns, err = parser:ParseCooldowns(text)
        
        if cooldowns then
            BowbAssigns.AssignmentManager:SetCooldowns(cooldowns)
            BowbAssigns:Print("Cooldowns imported successfully!")
            self:RefreshAssignments()
        else
            BowbAssigns:Error("Failed to parse cooldowns: " .. (err or "unknown error"))
        end
    end)
end

--[[
    Show pheromones import modal
]]
function MainFrame:ShowPheromonesImport()
    BowbAssigns.ImportModal:Show("Import Pheromones", function(text)
        local parser = BowbAssigns.Managers.DataParser:New()
        local pheromones, err = parser:ParsePheromones(text)
        
        if pheromones then
            BowbAssigns.AssignmentManager:SetPheromones(pheromones)
            BowbAssigns:Print("Pheromones imported successfully!")
        else
            BowbAssigns:Error("Failed to parse pheromones: " .. (err or "unknown error"))
        end
    end)
end

--[[
    Post current boss assignments to chat
]]
function MainFrame:PostCurrentBoss()
    if not self.selectedBoss then
        BowbAssigns:Error("No boss selected")
        return
    end
    
    -- Use boss key for lookup
    local lookupKey = self.selectedBossKey or self.selectedBoss:upper()
    
    local lines = BowbAssigns.MacroManager:GenerateBossMacro(
        lookupKey,
        BowbAssigns.AssignmentManager
    )
    
    BowbAssigns.MacroManager:PostToChat(lines)
    BowbAssigns:DebugPrint("Posted assignments for " .. self.selectedBoss)
end

--[[
    Post pheromones to chat
]]
function MainFrame:PostPheromones()
    local lines = BowbAssigns.MacroManager:GeneratePheromoneMacro(
        BowbAssigns.AssignmentManager
    )
    BowbAssigns.MacroManager:PostToChat(lines)
end

--[[
    Create settings tab content
]]
function MainFrame:CreateSettingsTab()
    local frame = self.frame
    local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 6, -35)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    content:SetBackdropColor(0.03, 0.03, 0.05, 0.8)
    content:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)
    content:Hide()
    frame.settingsContent = content
    
    -- Title
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -12)
    title:SetText("Settings")
    title:SetTextColor(1, 0.82, 0, 1)
    
    -- Chat Channel Section
    local channelLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -50)
    channelLabel:SetText("Post Assignments To:")
    channelLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    
    local channelDropdown = CreateFrame("Frame", "BowbAssignsChatChannelDropdown", content, "UIDropDownMenuTemplate")
    channelDropdown:SetPoint("LEFT", channelLabel, "RIGHT", -10, -3)
    
    UIDropDownMenu_SetWidth(channelDropdown, 150)
    
    -- Get current setting
    local currentChannel = BowbAssigns.ConfigManager:Get("chatChannel") or "raid"
    local channelNames = {
        party = "Party",
        raid = "Raid",
        ["raid_warning"] = "Raid Warning",
        guild = "Guild",
        officer = "Officer"
    }
    UIDropDownMenu_SetText(channelDropdown, channelNames[currentChannel] or "Raid")
    
    -- Capture self for closure
    local mainFrameInstance = self
    
    UIDropDownMenu_Initialize(channelDropdown, function(self, level)
        local channels = {
            { key = "party", name = "Party" },
            { key = "raid", name = "Raid" },
            { key = "raid_warning", name = "Raid Warning" },
            { key = "guild", name = "Guild" },
            { key = "officer", name = "Officer" }
        }
        
        for _, channel in ipairs(channels) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = channel.name
            info.value = channel.key
            info.func = function()
                BowbAssigns.ConfigManager:Set("chatChannel", channel.key)
                UIDropDownMenu_SetText(channelDropdown, channel.name)
                BowbAssigns:Print("Chat channel set to: " .. channel.name)
            end
            
            -- Check current selection
            if channel.key == currentChannel then
                info.checked = true
            end
            
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    content.channelDropdown = channelDropdown
    
    -- Test Mode Section (moved from assignments tab)
    local testModeLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    testModeLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -110)
    testModeLabel:SetText("Test Mode:")
    
    local testModeCheckbox = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    testModeCheckbox:SetPoint("LEFT", testModeLabel, "RIGHT", 10, 0)
    testModeCheckbox.Text:SetText("Use Party Chat (for testing)")
    testModeCheckbox:SetChecked(BowbAssigns.MacroManager.testMode)
    testModeCheckbox:SetScript("OnClick", function(self)
        BowbAssigns.MacroManager:SetTestMode(self:GetChecked())
    end)
    content.testModeCheckbox = testModeCheckbox
    
    -- Description text
    local description = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", testModeCheckbox, "BOTTOMLEFT", -10, -10)
    description:SetWidth(500)
    description:SetJustifyH("LEFT")
    description:SetText("Test mode temporarily overrides the chat channel setting above and posts to party chat instead.")
    
    -- Minimap Button Section
    local minimapLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minimapLabel:SetPoint("TOPLEFT", description, "BOTTOMLEFT", -10, -30)
    minimapLabel:SetText("Minimap Button:")
    
    local minimapCheckbox = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    minimapCheckbox:SetPoint("LEFT", minimapLabel, "RIGHT", 10, 0)
    minimapCheckbox.Text:SetText("Show minimap icon")
    
    -- Set initial state
    local minimapConfig = BowbAssigns.ConfigManager:Get("minimap")
    local isVisible = not (minimapConfig and minimapConfig.hide)
    minimapCheckbox:SetChecked(isVisible)
    
    minimapCheckbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            BowbAssigns.MinimapManager:Show()
        else
            BowbAssigns.MinimapManager:Hide()
        end
    end)
    content.minimapCheckbox = minimapCheckbox
    
    -- Minimap description
    local minimapDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minimapDesc:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", -10, -10)
    minimapDesc:SetWidth(500)
    minimapDesc:SetJustifyH("LEFT")
    minimapDesc:SetText("The minimap button can be dragged to reposition it. You can also use /bass minimap to toggle visibility.")
    
    -- Chat Rate Limiting Section
    local rateLimitLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rateLimitLabel:SetPoint("TOPLEFT", minimapDesc, "BOTTOMLEFT", -10, -30)
    rateLimitLabel:SetText("Chat Rate Limiting:")
    
    local rateLimitInfo = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rateLimitInfo:SetPoint("TOPLEFT", rateLimitLabel, "BOTTOMLEFT", 10, -10)
    rateLimitInfo:SetWidth(500)
    rateLimitInfo:SetJustifyH("LEFT")
    local batchSize = BowbAssigns.ConfigManager:Get("chatBatchSize") or 20
    local batchDelay = BowbAssigns.ConfigManager:Get("chatBatchDelay") or 1.5
    rateLimitInfo:SetText(string.format("Messages are sent in batches of %d with %.1f second delay between batches to avoid rate limiting.", batchSize, batchDelay))
    rateLimitInfo:SetTextColor(0.7, 0.7, 0.7)
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
    
    -- Update roster display (frame defaults to roster tab)
    self:UpdateRosterDisplay()
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

