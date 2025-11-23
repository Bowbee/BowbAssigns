--[[
    MinimapManager.lua
    Manages the minimap button for the addon
    Uses LibDBIcon when available, with fallback to custom implementation
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- MinimapManager class
local MinimapManager = {}
MinimapManager.__index = MinimapManager
BowbAssigns.Managers.MinimapManager = MinimapManager

-- LibStub references
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)

--[[
    Create a new MinimapManager instance
    @return MinimapManager - The new instance
]]
function MinimapManager:New()
    local instance = setmetatable({}, self)
    instance.button = nil
    instance.ldbObject = nil
    instance.isInitialized = false
    return instance
end

--[[
    Initialize the minimap button
    Creates and configures the minimap icon
]]
function MinimapManager:Initialize()
    if self.isInitialized then
        BowbAssigns:DebugPrint("MinimapManager already initialized")
        return
    end
    
    -- Ensure minimap settings exist
    self:EnsureMinimapSettings()
    
    -- Create LibDataBroker object if available
    if LDB then
        self:CreateLDBObject()
    end
    
    -- Register with LibDBIcon if available
    if LDBIcon and self.ldbObject then
        self:RegisterWithLDBIcon()
    else
        -- Fallback to custom minimap button
        self:CreateCustomButton()
    end
    
    self.isInitialized = true
    BowbAssigns:DebugPrint("MinimapManager initialized")
end

--[[
    Ensure minimap settings exist in saved variables
]]
function MinimapManager:EnsureMinimapSettings()
    local config = BowbAssigns.ConfigManager:Get("minimap")
    if not config then
        config = {
            hide = false,
            minimapPos = 220,
            radius = 80
        }
        BowbAssigns.ConfigManager:Set("minimap", config)
    end
end

--[[
    Create LibDataBroker object
]]
function MinimapManager:CreateLDBObject()
    self.ldbObject = LDB:NewDataObject(ADDON_NAME, {
        type = "launcher",
        text = ADDON_NAME,
        icon = 589118, -- Condescending Remark icon
        OnClick = function(clickedFrame, button)
            if button == "LeftButton" then
                if BowbAssigns.MainFrame then
                    BowbAssigns.MainFrame:Toggle()
                end
            elseif button == "RightButton" then
                self:ShowContextMenu(clickedFrame)
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("|cFF1E90FFBowbAssigns|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFFFFFFLeft-click:|r Toggle main window", 1, 1, 1)
            tooltip:AddLine("|cFFFFFFFFRight-click:|r Options", 1, 1, 1)
            tooltip:AddLine("|cFFFFFFFFDrag:|r Move this button", 1, 1, 1)
            tooltip:Show()
        end,
    })
    
    BowbAssigns:DebugPrint("LibDataBroker object created")
end

--[[
    Register with LibDBIcon
]]
function MinimapManager:RegisterWithLDBIcon()
    LDBIcon:Register(ADDON_NAME, self.ldbObject, BowbAssignsDB.minimap)
    BowbAssigns:DebugPrint("Registered with LibDBIcon")
end

--[[
    Create custom minimap button (fallback when libraries not available)
]]
function MinimapManager:CreateCustomButton()
    if self.button then return end
    
    local button = CreateFrame("Button", ADDON_NAME .. "MinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("anyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Icon
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(589118) -- Condescending Remark icon
    button.icon = icon
    
    -- Border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.overlay = overlay
    
    -- Position update function
    local function UpdatePosition()
        local config = BowbAssigns.ConfigManager:Get("minimap")
        if not config then return end
        
        local angle = math.rad(config.minimapPos or 220)
        local radius = config.radius or 80
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    
    -- Drag functionality
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            
            local angle = math.atan2(py - my, px - mx)
            local degrees = math.deg(angle)
            if degrees < 0 then degrees = degrees + 360 end
            
            local config = BowbAssigns.ConfigManager:Get("minimap")
            config.minimapPos = degrees
            BowbAssigns.ConfigManager:Set("minimap", config)
            UpdatePosition()
        end)
    end)
    
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    
    -- Click handling
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            if BowbAssigns.MainFrame then
                BowbAssigns.MainFrame:Toggle()
            end
        elseif mouseButton == "RightButton" then
            MinimapManager:ShowContextMenu(self)
        end
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFF1E90FFBowbAssigns|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFFFFFFFLeft-click:|r Toggle main window", 1, 1, 1)
        GameTooltip:AddLine("|cFFFFFFFFRight-click:|r Options", 1, 1, 1)
        GameTooltip:AddLine("|cFFFFFFFFDrag:|r Move this button", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    UpdatePosition()
    
    -- Show/hide based on settings
    local config = BowbAssigns.ConfigManager:Get("minimap")
    if config and config.hide then
        button:Hide()
    else
        button:Show()
    end
    
    self.button = button
    BowbAssigns:DebugPrint("Custom minimap button created")
end

--[[
    Show context menu
    @param anchor Frame - The frame to anchor the menu to
]]
function MinimapManager:ShowContextMenu(anchor)
    -- Simple context menu implementation
    if not self.contextMenu then
        self.contextMenu = CreateFrame("Frame", ADDON_NAME .. "MinimapContextMenu", UIParent)
        self.contextMenu:SetSize(200, 100)
        self.contextMenu:SetFrameStrata("TOOLTIP")
        self.contextMenu:SetFrameLevel(1000)
        self.contextMenu:Hide()
        self.contextMenu:EnableMouse(true)
        
        -- Background
        local bg = self.contextMenu:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.95)
        
        -- Border
        local border = self.contextMenu:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetColorTexture(0.5, 0.5, 0.5, 1)
        
        self.contextMenu.buttons = {}
        
        -- Close on right-click
        self.contextMenu:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                self:Hide()
            end
        end)
    end
    
    -- Clear existing buttons
    for i, button in ipairs(self.contextMenu.buttons) do
        button:Hide()
    end
    
    local menuFrame = self.contextMenu
    local buttonHeight = 25
    local buttonCount = 0
    
    -- Helper to create menu button
    local function CreateMenuButton(text, onClick)
        local button = self.contextMenu.buttons[buttonCount + 1]
        if not button then
            button = CreateFrame("Button", nil, menuFrame)
            button:SetSize(180, buttonHeight)
            button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            
            local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            buttonText:SetPoint("LEFT", 10, 0)
            button.text = buttonText
            
            self.contextMenu.buttons[buttonCount + 1] = button
        end
        
        button:SetPoint("TOP", menuFrame, "TOP", 0, -(buttonCount * buttonHeight + 5))
        button.text:SetText(text)
        button:SetScript("OnClick", function()
            onClick()
            menuFrame:Hide()
        end)
        button:Show()
        
        buttonCount = buttonCount + 1
    end
    
    -- Create menu options
    CreateMenuButton("Toggle UI", function()
        if BowbAssigns.MainFrame then
            BowbAssigns.MainFrame:Toggle()
        end
    end)
    
    CreateMenuButton("Hide Minimap Icon", function()
        self:Hide()
        BowbAssigns:Print("Minimap icon hidden. Use /bass minimap to show it again.")
    end)
    
    CreateMenuButton("Settings", function()
        if BowbAssigns.MainFrame then
            BowbAssigns.MainFrame:Show()
            BowbAssigns.MainFrame:SwitchTab(3) -- Switch to settings tab
        end
    end)
    
    -- Adjust menu size and position
    menuFrame:SetHeight(buttonCount * buttonHeight + 10)
    menuFrame:ClearAllPoints()
    menuFrame:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, 0)
    menuFrame:Show()
end

--[[
    Show the minimap button
]]
function MinimapManager:Show()
    if LDBIcon then
        LDBIcon:Show(ADDON_NAME)
    elseif self.button then
        self.button:Show()
    end
    
    local config = BowbAssigns.ConfigManager:Get("minimap")
    config.hide = false
    BowbAssigns.ConfigManager:Set("minimap", config)
    BowbAssigns:DebugPrint("Minimap button shown")
end

--[[
    Hide the minimap button
]]
function MinimapManager:Hide()
    if LDBIcon then
        LDBIcon:Hide(ADDON_NAME)
    elseif self.button then
        self.button:Hide()
    end
    
    local config = BowbAssigns.ConfigManager:Get("minimap")
    config.hide = true
    BowbAssigns.ConfigManager:Set("minimap", config)
    BowbAssigns:DebugPrint("Minimap button hidden")
end

--[[
    Toggle minimap button visibility
]]
function MinimapManager:Toggle()
    local config = BowbAssigns.ConfigManager:Get("minimap")
    if config and config.hide then
        self:Show()
    else
        self:Hide()
    end
end

--[[
    Check if the minimap button is visible
    @return boolean - True if visible, false otherwise
]]
function MinimapManager:IsVisible()
    local config = BowbAssigns.ConfigManager:Get("minimap")
    if not config then return true end
    return not config.hide
end
