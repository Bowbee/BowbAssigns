--[[
    ImportModal.lua
    Modal popup for importing data
]]

local ADDON_NAME = "BowbAssigns"
local BowbAssigns = _G[ADDON_NAME]

-- ImportModal class
local ImportModal = {}
ImportModal.__index = ImportModal
BowbAssigns.UI.ImportModal = ImportModal

--[[
    Create a new ImportModal instance
    @return ImportModal - The new instance
]]
function ImportModal:New()
    local instance = setmetatable({}, self)
    instance.frame = nil
    instance.callback = nil
    return instance
end

--[[
    Create the modal frame
]]
function ImportModal:Create()
    if self.frame then
        return
    end
    
    local frame = CreateFrame("Frame", "BowbAssignsImportModal", UIParent, "BasicFrameTemplateWithInset")
    self.frame = frame
    
    -- Frame properties
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Add to UISpecialFrames to enable ESC key closing
    table.insert(UISpecialFrames, "BowbAssignsImportModal")
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
    frame.title:SetText("Import Data")
    
    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -30)
    instructions:SetText("Paste your export data below:")
    frame.instructions = instructions
    
    -- Scrollable text area
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 50)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(450)
    editBox:SetHeight(300)  -- Set explicit height for multi-line
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed", function() self:Hide() end)
    editBox:SetScript("OnTextChanged", function(self)
        -- Auto-resize height based on content
        local text = self:GetText()
        local numLines = 1
        for _ in text:gmatch("\n") do
            numLines = numLines + 1
        end
        self:SetHeight(math.max(300, numLines * 14))
    end)
    
    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox
    
    -- OK button
    local okButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    okButton:SetSize(100, 25)
    okButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)
    okButton:SetText("OK")
    okButton:SetScript("OnClick", function()
        self:OnOK()
    end)
    frame.okButton = okButton
    
    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    cancelButton:SetSize(100, 25)
    cancelButton:SetPoint("RIGHT", okButton, "LEFT", -5, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.cancelButton = cancelButton
    
    frame:Hide()
    
    BowbAssigns:DebugPrint("ImportModal created")
end

--[[
    Show the modal with a title and callback
    @param title string - Modal title
    @param callback function - Function to call with the text when OK is clicked
]]
function ImportModal:Show(title, callback)
    if not self.frame then
        self:Create()
    end
    
    self.frame.title:SetText(title or "Import Data")
    self.callback = callback
    self.frame.editBox:SetText("")
    self.frame.editBox:SetFocus()
    self.frame:Show()
end

--[[
    Hide the modal
]]
function ImportModal:Hide()
    if self.frame then
        self.frame:Hide()
        self.frame.editBox:SetText("")
        self.frame.editBox:ClearFocus()
    end
end

--[[
    Handle OK button click
]]
function ImportModal:OnOK()
    local text = self.frame.editBox:GetText()
    
    if self.callback then
        self.callback(text)
    end
    
    self:Hide()
end

