-- ViewDietList.lua
local addonName, addonTable = ...
local viewDietList = CreateFrame("Frame")
viewDietList:Hide()

local UpdateGrid 

-- 1. Configuration (Columns expanded to fill a 560px inner grid)
local cols = {
    { title = "Pet Family", width = 130, sortKey = "name" },
    { title = "Bread", width = 70, sortKey = "Bread" },
    { title = "Cheese", width = 70, sortKey = "Cheese" },
    { title = "Fish", width = 70, sortKey = "Fish" },
    { title = "Fruit", width = 70, sortKey = "Fruit" },
    { title = "Fungus", width = 70, sortKey = "Fungus" },
    { title = "Meat", width = 70, sortKey = "Meat" },
}

-- 2. Interactive Column Headers (Math synchronized for perfect alignment)
local currentX = 0
for _, col in ipairs(cols) do
    local btn = CreateFrame("Button", nil, viewDietList)
    -- 25 represents the 15px ScrollFrame offset + 10px Row offset
    btn:SetPoint("TOPLEFT", viewDietList, "TOPLEFT", 25 + currentX, -35)
    btn:SetSize(col.width, 20)
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetAllPoints(btn)
    label:SetJustifyH(col.title == "Pet Family" and "LEFT" or "CENTER")
    label:SetText(col.title)
    
    btn:SetScript("OnClick", function()
        UpdateGrid(col.sortKey)
    end)
    
    col.xOffset = currentX 
    currentX = currentX + col.width
end

-- 3. ScrollFrame Setup
local scrollFrame = CreateFrame("ScrollFrame", nil, viewDietList, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

local content = CreateFrame("Frame")
content:SetSize(560, 480) -- Stretched to match the new 620px window
scrollFrame:SetScrollChild(content)

local function EatenByPet(dietArray, foodType)
    if not dietArray then return false end
    for _, food in ipairs(dietArray) do
        if food == foodType then return true end
    end
    return false
end

local checkmark = "|cFF00FF00X|r" 

-- 4. Row Pooling
local rows = {}
local rowHeight = 24

for i = 1, 18 do
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(560, rowHeight) -- Stretched to match the new 620px window
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -((i - 1) * rowHeight))
    
    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetColorTexture(1, 1, 1, 0.3)
    PixelUtil.SetPoint(divider, "BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    PixelUtil.SetPoint(divider, "BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    PixelUtil.SetHeight(divider, 1)
    
    row.cells = {}
    
    for colIdx, col in ipairs(cols) do
        local cell = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        -- xOffset now perfectly mirrors the header offset
        cell:SetPoint("LEFT", row, "LEFT", col.xOffset, 0)
        cell:SetWidth(col.width)
        cell:SetJustifyH(col.title == "Pet Family" and "LEFT" or "CENTER")
        row.cells[colIdx] = cell
    end
    
    rows[i] = row
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
            local petA_eats = EatenByPet(HunterPetDB[a].diet, sortBy)
            local petB_eats = EatenByPet(HunterPetDB[b].diet, sortBy)
            
            if petA_eats == petB_eats then
                return a < b 
            end
            
            return petA_eats and not petB_eats
        end
    end)
    
    for i, petName in ipairs(sortedPets) do
        local petData = HunterPetDB[petName]
        local row = rows[i]
        
        row.cells[1]:SetText(petName)
        row.cells[2]:SetText(EatenByPet(petData.diet, "Bread") and checkmark or "")
        row.cells[3]:SetText(EatenByPet(petData.diet, "Cheese") and checkmark or "")
        row.cells[4]:SetText(EatenByPet(petData.diet, "Fish") and checkmark or "")
        row.cells[5]:SetText(EatenByPet(petData.diet, "Fruit") and checkmark or "")
        row.cells[6]:SetText(EatenByPet(petData.diet, "Fungus") and checkmark or "")
        row.cells[7]:SetText(EatenByPet(petData.diet, "Meat") and checkmark or "")
    end
end

UpdateGrid("name")

addonTable.ViewDietList = viewDietList