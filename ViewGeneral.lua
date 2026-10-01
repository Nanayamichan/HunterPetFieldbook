-- ViewGeneral.lua
local addonName, addonTable = ...
local viewGeneral = CreateFrame("Frame")
viewGeneral:Hide()

local UpdateGrid 

-- 1. Create Interactive Header Buttons
local function CreateHeaderButton(text, xOffset, width, sortKey)
    local btn = CreateFrame("Button", nil, viewGeneral)
    btn:SetPoint("TOPLEFT", viewGeneral, "TOPLEFT", xOffset, -35)
    btn:SetSize(width, 20)
    
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetAllPoints(btn)
    label:SetJustifyH("LEFT")
    label:SetText(text)

    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    
    btn:SetScript("OnClick", function()
        UpdateGrid(sortKey)
    end)
end

CreateHeaderButton("Pet Family", 25, 110, "name")
CreateHeaderButton("Health", 140, 110, "health")
CreateHeaderButton("Armor", 260, 110, "armor")
CreateHeaderButton("Damage", 380, 110, "damage")

-- 2. ScrollFrame Setup
local scrollFrame = CreateFrame("ScrollFrame", nil, viewGeneral, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

local content = CreateFrame("Frame")
content:SetSize(520, 480)
scrollFrame:SetScrollChild(content)

-- 3. Row Pooling
local rows = {}
local rowHeight = 24

for i = 1, 18 do
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(520, rowHeight)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -((i - 1) * rowHeight))
    
    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetColorTexture(1, 1, 1, 0.3)
    PixelUtil.SetPoint(divider, "BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    PixelUtil.SetPoint(divider, "BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    PixelUtil.SetHeight(divider, 1)
    
    -- CREATE THE INTERACTIVE LINK BUTTON
    row.nameBtn = CreateFrame("Button", nil, row)
    row.nameBtn:SetSize(110, rowHeight)
    row.nameBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
    
    -- Add a faint white background highlight when hovered
    local hl = row.nameBtn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetColorTexture(1, 1, 1, 0.1)
    hl:SetAllPoints()

    -- When clicked, update the dropdown filters in PetList, then swap the view
    row.nameBtn:SetScript("OnClick", function(self)
        if self.petName and addonTable.UpdateNPCList and addonTable.LoadView then
            addonTable.UpdateNPCList(self.petName, nil, nil)
            addonTable.LoadView("PetList")
        end
    end)
    
    -- Attach the text label directly to our new button
    row.name = row.nameBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetAllPoints(row.nameBtn)
    row.name:SetJustifyH("LEFT")
    
    row.health = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.health:SetPoint("LEFT", row, "LEFT", 115, 0)
    row.health:SetWidth(110)
    row.health:SetJustifyH("LEFT")
    
    row.armor = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.armor:SetPoint("LEFT", row, "LEFT", 235, 0)
    row.armor:SetWidth(110)
    row.armor:SetJustifyH("LEFT")
    
    row.damage = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.damage:SetPoint("LEFT", row, "LEFT", 355, 0)
    row.damage:SetWidth(110)
    row.damage:SetJustifyH("LEFT")
    
    rows[i] = row
end

-- 4. Formatting Helper
local function FormatStat(val)
    if val > 0 then 
        return "|cFF00FF00+" .. val .. "%|r"
    elseif val < 0 then 
        return "|cFFFF0000" .. val .. "%|r"
    else 
        return "|cFF9999990%|r"
    end
end

-- 5. Sorting and Updating Logic
UpdateGrid = function(sortBy)
    local sortedPets = {}
    for petName in pairs(HunterPetDB) do 
        table.insert(sortedPets, petName) 
    end
    
    table.sort(sortedPets, function(a, b)
        if sortBy == "name" then
            return a < b 
        else
            local statA = HunterPetDB[a].stats[sortBy]
            local statB = HunterPetDB[b].stats[sortBy]
            if statA == statB then
                return a < b 
            end
            return statA > statB 
        end
    end)
    
    for i, petName in ipairs(sortedPets) do
        local petData = HunterPetDB[petName]
        local row = rows[i]
        
        row.nameBtn.petName = petName -- Store the name inside the button so OnClick knows what to load
        row.name:SetText(petName)
        row.health:SetText(FormatStat(petData.stats.health))
        row.armor:SetText(FormatStat(petData.stats.armor))
        row.damage:SetText(FormatStat(petData.stats.damage))
    end
end

UpdateGrid("name")

addonTable.ViewGeneral = viewGeneral