-- ViewPetList.lua
local addonName, addonTable = ...

local viewPetList = CreateFrame("Frame")
viewPetList:Hide()

-- Current filter states
local selectedFamily = nil
local selectedAbility = nil 
local selectedSpeed = nil
local searchQuery = ""
local filterByLevel = false

-- 1. Header & Controls
local titleText = viewPetList:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
titleText:SetPoint("TOPLEFT", 20, -15)
titleText:SetText("Pet Lookup")

local familyDropdown = CreateFrame("Frame", "NanaPetFamilyDropdown", viewPetList, "UIDropDownMenuTemplate")
familyDropdown:SetPoint("TOPLEFT", viewPetList, "TOPLEFT", 0, -45)
UIDropDownMenu_SetWidth(familyDropdown, 110)

local abilityDropdown = CreateFrame("Frame", "NanaPetAbilityDropdown", viewPetList, "UIDropDownMenuTemplate")
abilityDropdown:SetPoint("TOPLEFT", familyDropdown, "TOPRIGHT", -15, 0)
UIDropDownMenu_SetWidth(abilityDropdown, 120)

local speedDropdown = CreateFrame("Frame", "NanaPetSpeedDropdown", viewPetList, "UIDropDownMenuTemplate")
speedDropdown:SetPoint("TOPLEFT", abilityDropdown, "TOPRIGHT", -15, 0)
UIDropDownMenu_SetWidth(speedDropdown, 90)

local UpdateNPCList

local searchBox = CreateFrame("EditBox", "NanaPetSearchBox", viewPetList, "InputBoxTemplate")
searchBox:SetSize(110, 20)
searchBox:SetPoint("TOPLEFT", speedDropdown, "TOPRIGHT", 0, -3)
searchBox:SetAutoFocus(false) 
searchBox:SetMaxLetters(50)

local searchLabel = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
searchLabel:SetPoint("LEFT", searchBox, "LEFT", 5, 0)
searchLabel:SetText("Search...")

searchBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    if text == "" then searchLabel:Show() else searchLabel:Hide() end
    searchQuery = string.lower(text)
    UpdateNPCList(selectedFamily, selectedAbility, selectedSpeed)
end)

searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

local levelCheckbox = CreateFrame("CheckButton", "NanaPetLevelCheck", viewPetList, "UICheckButtonTemplate")
levelCheckbox:SetSize(26, 26)
levelCheckbox:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", -45, -2)

local levelCheckLabel = levelCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
levelCheckLabel:SetPoint("LEFT", levelCheckbox, "RIGHT", 0, 1)
levelCheckLabel:SetText("Hide pets above my level")

levelCheckbox:SetScript("OnClick", function(self)
    filterByLevel = self:GetChecked()
    UpdateNPCList(selectedFamily, selectedAbility, selectedSpeed)
end)

UIDropDownMenu_Initialize(familyDropdown, function(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Pets"
    info.value = nil
    info.func = function(self)
        UpdateNPCList(nil, nil, nil)
        UIDropDownMenu_SetSelectedValue(familyDropdown, nil)
    end
    info.checked = (selectedFamily == nil)
    UIDropDownMenu_AddButton(info)

    local families = {}
    if HunterTameableDB then
        for k in pairs(HunterTameableDB) do table.insert(families, k) end
        table.sort(families)
    end
    for _, fam in ipairs(families) do
        info.text = fam
        info.value = fam
        info.func = function(self)
            UpdateNPCList(self.value, nil, nil)
            UIDropDownMenu_SetSelectedValue(familyDropdown, self.value)
        end
        info.checked = (selectedFamily == fam)
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_Initialize(abilityDropdown, function(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Abilities"
    info.value = nil
    info.func = function(self) UpdateNPCList(selectedFamily, nil, selectedSpeed) end
    info.checked = (selectedAbility == nil)
    UIDropDownMenu_AddButton(info)

    local uniqueMap = {}
    local abilities = {}
    if HunterTameableDB then
        for fam, beasts in pairs(HunterTameableDB) do
            if selectedFamily == nil or selectedFamily == fam then
                for _, beast in ipairs(beasts) do
                    if beast.abilities then
                        for _, ab in ipairs(beast.abilities) do
                            local baseAb = string.gsub(ab, "%d+", "")
                            baseAb = strtrim(baseAb)
                            if baseAb ~= "" and not uniqueMap[baseAb] then
                                uniqueMap[baseAb] = true
                                table.insert(abilities, baseAb)
                            end
                        end
                    end
                end
            end
        end
        table.sort(abilities)
    end
    for _, ab in ipairs(abilities) do
        info.text = ab
        info.value = ab
        info.func = function(self) UpdateNPCList(selectedFamily, self.value, selectedSpeed) end
        info.checked = (selectedAbility == ab)
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_Initialize(speedDropdown, function(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Speeds"
    info.value = nil
    info.func = function(self) UpdateNPCList(selectedFamily, selectedAbility, nil) end
    info.checked = (selectedSpeed == nil)
    UIDropDownMenu_AddButton(info)

    local uniqueMap = {}
    local speeds = {}
    if HunterTameableDB then
        for fam, beasts in pairs(HunterTameableDB) do
            if selectedFamily == nil or selectedFamily == fam then
                for _, beast in ipairs(beasts) do
                    if beast.speed and beast.speed ~= "" and not uniqueMap[beast.speed] then
                        uniqueMap[beast.speed] = true
                        table.insert(speeds, beast.speed)
                    end
                end
            end
        end
        table.sort(speeds)
    end
    for _, spd in ipairs(speeds) do
        info.text = spd .. " Speed"
        info.value = spd
        info.func = function(self) UpdateNPCList(selectedFamily, selectedAbility, self.value) end
        info.checked = (selectedSpeed == spd)
        UIDropDownMenu_AddButton(info)
    end
end)

-- 2. Scroll Area Setup
local scrollFrame = CreateFrame("ScrollFrame", nil, viewPetList, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -85)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

local content = CreateFrame("Frame")
content:SetSize(520, 500)
scrollFrame:SetScrollChild(content)

local npcRows = {}
local rowHeight = 32

-- Formatting helper for the tooltip stats
local function FormatStatTooltip(val)
    if not val or val == 0 then return "|cFF9999990%|r" end
    if val > 0 then return "|cFF00FF00+" .. val .. "%|r" end
    return "|cFFFF0000" .. val .. "%|r"
end

for i = 1, 500 do
    local row = CreateFrame("Button", nil, content)
    row:SetSize(520, rowHeight)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -((i - 1) * rowHeight))
    
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetColorTexture(1, 1, 1, 0.05)
    highlight:SetAllPoints(row)
    
    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetColorTexture(1, 1, 1, 0.15)
    PixelUtil.SetPoint(divider, "BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    PixelUtil.SetPoint(divider, "BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    PixelUtil.SetHeight(divider, 1)
    
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", 0, 6)
    
    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.info:SetPoint("LEFT", 0, -8)
    
    row.skills = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.skills:SetPoint("RIGHT", -10, 0)
    
    -- Shift-Click to Chat
    row:SetScript("OnClick", function(self)
        if IsShiftKeyDown() and self.chatString then
            local activeChat = ChatEdit_GetActiveWindow()
            if activeChat then
                activeChat:Insert(self.chatString)
            end
        end
    end)
    
-- Rich Hover Tooltips
    row:SetScript("OnEnter", function(self)
        if self.beast then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            
            -- Main Title
            GameTooltip:AddLine(self.beast.name, 1, 0.82, 0) -- Classic gold text
            GameTooltip:AddLine(self.beast.familyName .. " Family", 1, 1, 1)
            
            -- Pull data from General Tab's HunterPetDB
            if HunterPetDB and HunterPetDB[self.beast.familyName] then
                local famData = HunterPetDB[self.beast.familyName]
                
                -- Check for diet data and format it safely
                local dietData = famData.diet or famData.diets
                if dietData then
                    local dietText = type(dietData) == "table" and table.concat(dietData, ", ") or dietData
                    GameTooltip:AddLine("Diet: |cFFFFFFFF" .. dietText .. "|r", 1, 0.82, 0)
                end
                
                if famData.stats then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Stat Modifiers:", 1, 0.82, 0)
                    GameTooltip:AddDoubleLine("Health:", FormatStatTooltip(famData.stats.health))
                    GameTooltip:AddDoubleLine("Armor:", FormatStatTooltip(famData.stats.armor))
                    GameTooltip:AddDoubleLine("Damage:", FormatStatTooltip(famData.stats.damage))
                end
            end
            
            GameTooltip:Show()
        end
    end)


    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    row:Hide()
    npcRows[i] = row
end

-- 3. Populate Function
UpdateNPCList = function(family, requiredAbility, requiredSpeed)
    selectedFamily = family 
    selectedAbility = requiredAbility
    selectedSpeed = requiredSpeed
    
    UIDropDownMenu_SetText(familyDropdown, selectedFamily or "All Pets")
    UIDropDownMenu_SetText(abilityDropdown, selectedAbility or "All Abilities")
    UIDropDownMenu_SetText(speedDropdown, selectedSpeed and (selectedSpeed .. " Speed") or "All Speeds")
    
    for _, row in ipairs(npcRows) do row:Hide() end
    
    local playerLevel = UnitLevel("player") or 60
    local familyBeasts = {}
    
    if HunterTameableDB then
        for fam, beasts in pairs(HunterTameableDB) do
            if selectedFamily == nil or selectedFamily == fam then
                for _, b in ipairs(beasts) do
                    b.familyName = fam
                    table.insert(familyBeasts, b)
                end
            end
        end
    end

    table.sort(familyBeasts, function(a, b)
        local lvlA = tonumber(string.match(a.level, "^%d+")) or 0
        local lvlB = tonumber(string.match(b.level, "^%d+")) or 0
        if lvlA == lvlB then return a.name < b.name end
        return lvlA < lvlB
    end)
    
    local rowIndex = 1
    
    for _, beast in ipairs(familyBeasts) do
        local hasAbility = true
        local hasSpeed = true
        local matchesSearch = true
        local isTameable = true
        
        if requiredAbility then
            hasAbility = false
            if beast.abilities then
                for _, ab in ipairs(beast.abilities) do
                    if string.find(ab, requiredAbility) then
                        hasAbility = true
                        break
                    end
                end
            end
        end
        
        if requiredSpeed and beast.speed ~= requiredSpeed then
            hasSpeed = false
        end
        
        if searchQuery ~= "" then
            local lowerName = string.lower(beast.name)
            local lowerZone = string.lower(beast.zone)
            if not (string.find(lowerName, searchQuery, 1, true) or string.find(lowerZone, searchQuery, 1, true)) then
                matchesSearch = false
            end
        end
        
        if filterByLevel then
            local minLevel = tonumber(string.match(beast.level, "^%d+")) or 999
            if minLevel > playerLevel then
                isTameable = false
            end
        end
        
        if hasAbility and hasSpeed and matchesSearch and isTameable and npcRows[rowIndex] then
            local row = npcRows[rowIndex]
            
            -- Bind the beast data to the row so the Tooltip script can read it
            row.beast = beast
            
            local nameText = beast.name
            if beast.rare then nameText = "|cFF00FFFF[Rare]|r " .. nameText end
            if beast.isNew then nameText = nameText .. " |cFF00FF00[New]|r" end
            row.name:SetText(nameText)
            
            local familyPrefix = (selectedFamily == nil) and (beast.familyName .. " - ") or ""
            local speedText = beast.speed and (" - " .. beast.speed .. " Speed") or ""
            
            row.info:SetText("|cFFCCCCCC" .. familyPrefix .. beast.zone .. " (Lvl " .. beast.level .. ")" .. speedText .. "|r")
            
            if beast.abilities and #beast.abilities > 0 then
                row.skills:SetText(table.concat(beast.abilities, ", "))
            else
                row.skills:SetText("")
            end
            
            local chatRareTag = beast.rare and "[Rare] " or ""
            row.chatString = chatRareTag .. beast.name .. " - " .. beast.zone .. " (Lvl " .. beast.level .. ")"
            
            row:Show()
            rowIndex = rowIndex + 1
        end
    end
end

UpdateNPCList(selectedFamily, selectedAbility, selectedSpeed)
addonTable.ViewPetList = viewPetList
addonTable.UpdateNPCList = UpdateNPCList