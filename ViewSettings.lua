-- ViewSettings.lua
local addonName, addonTable = ...
local viewSettings = CreateFrame("Frame")
viewSettings:Hide()

local titleText = viewSettings:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
titleText:SetPoint("TOPLEFT", 20, -15)
titleText:SetText("Settings")

-- 1. Horizontal Resize Toggle
local resizeCheckbox = CreateFrame("CheckButton", "NanaPetResizeCheck", viewSettings, "UICheckButtonTemplate")
resizeCheckbox:SetSize(26, 26)
resizeCheckbox:SetPoint("TOPLEFT", 20, -50)

local resizeLabel = resizeCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
resizeLabel:SetPoint("LEFT", resizeCheckbox, "RIGHT", 5, 1)
resizeLabel:SetText("Allow window to be resized horizontally")

resizeCheckbox:SetScript("OnClick", function(self)
    MyAddonState.allowHorizontalResize = self:GetChecked()
    if addonTable.ApplyResizeSettings then addonTable.ApplyResizeSettings() end
end)

-- 2. Minimap Toggle
local minimapCheckbox = CreateFrame("CheckButton", "NanaPetMinimapCheck", viewSettings, "UICheckButtonTemplate")
minimapCheckbox:SetSize(26, 26)
minimapCheckbox:SetPoint("TOPLEFT", 20, -90)

local minimapLabel = minimapCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
minimapLabel:SetPoint("LEFT", minimapCheckbox, "RIGHT", 5, 1)
minimapLabel:SetText("Show minimap button")

local minimapSubLabel = viewSettings:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
minimapSubLabel:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 6, 2)
minimapSubLabel:SetText("You can always type /hpf or /nana in chat to open the Fieldbook.")

minimapCheckbox:SetScript("OnClick", function(self)
    MyAddonState.showMinimap = self:GetChecked()
    if addonTable.UpdateMinimapVisibility then addonTable.UpdateMinimapVisibility() end
end)

-- 3. Default Startup View Dropdown
local startupLabel = viewSettings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
startupLabel:SetPoint("TOPLEFT", 25, -150)
startupLabel:SetText("Default Startup View:")

local startupSubLabel = viewSettings:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
startupSubLabel:SetPoint("TOPLEFT", startupLabel, "BOTTOMLEFT", 0, -14)
startupSubLabel:SetText("(Applies when you first log in or type /reload)")

local startupDropdown = CreateFrame("Frame", "NanaPetStartupDropdown", viewSettings, "UIDropDownMenuTemplate")
startupDropdown:SetPoint("TOPLEFT", 150, -145)
UIDropDownMenu_SetWidth(startupDropdown, 120)

local viewOptions = {
    { text = "General", value = "General" },
    { text = "Pet List", value = "PetList" },
    { text = "Diets", value = "DietList" },
    { text = "Abilities", value = "AbilitiesList" }
}

UIDropDownMenu_Initialize(startupDropdown, function(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    for _, opt in ipairs(viewOptions) do
        info.text = opt.text
        info.value = opt.value
        info.func = function(self)
            MyAddonState.startupView = self.value
            UIDropDownMenu_SetSelectedValue(startupDropdown, self.value)
            UIDropDownMenu_SetText(startupDropdown, opt.text)
        end
        info.checked = (MyAddonState and MyAddonState.startupView == opt.value)
        UIDropDownMenu_AddButton(info)
    end
end)

-- 4. Dynamic Level Colors Toggle
local levelColorCheckbox = CreateFrame("CheckButton", "NanaPetLevelColorCheck", viewSettings, "UICheckButtonTemplate")
levelColorCheckbox:SetSize(26, 26)
levelColorCheckbox:SetPoint("TOPLEFT", 20, -210)

local levelColorLabel = levelColorCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
levelColorLabel:SetPoint("LEFT", levelColorCheckbox, "RIGHT", 5, 1)
levelColorLabel:SetText("Color pet levels based on my current level")

local levelColorSubLabel = viewSettings:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
levelColorSubLabel:SetPoint("TOPLEFT", levelColorCheckbox, "BOTTOMLEFT", 6, 2)
levelColorSubLabel:SetText("Red = Untameable, Orange = Some are Tameable, Yellow = Equal, Green = Lower, White = Trivial")

levelColorCheckbox:SetScript("OnClick", function(self)
    MyAddonState.colorPetLevels = self:GetChecked()
    -- If the user clicks this while on the Pet List, refresh the list immediately so colors update
    if addonTable.UpdateNPCList then
        -- This re-triggers the filter function to redraw the current view with/without colors
        addonTable.UpdateNPCList(addonTable.selectedFamily, addonTable.selectedAbility, addonTable.selectedSpeed, addonTable.selectedRarity)
    end
end)

-- Ensure elements sync with saved variables when the tab opens
viewSettings:SetScript("OnShow", function()
    if MyAddonState then
        resizeCheckbox:SetChecked(MyAddonState.allowHorizontalResize or false)
        
        if MyAddonState.showMinimap == nil then MyAddonState.showMinimap = true end
        minimapCheckbox:SetChecked(MyAddonState.showMinimap)
        
        if MyAddonState.colorPetLevels == nil then MyAddonState.colorPetLevels = true end
        levelColorCheckbox:SetChecked(MyAddonState.colorPetLevels)
        
        local currentStartup = MyAddonState.startupView or "General"
        UIDropDownMenu_SetSelectedValue(startupDropdown, currentStartup)
        for _, opt in ipairs(viewOptions) do
            if opt.value == currentStartup then
                UIDropDownMenu_SetText(startupDropdown, opt.text)
            end
        end
    end
end)

addonTable.ViewSettings = viewSettings