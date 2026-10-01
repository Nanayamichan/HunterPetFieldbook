-- ViewDietList.lua
local addonName, addonTable = ...
local viewDietList = CreateFrame("Frame")
viewDietList:Hide()

-- Forward declaration of our sorting function
local UpdateGrid 

-- 1. Configuration (Added "sortKey" to map buttons to food data)
local cols = {
    { title = "Pet Family", width = 100, sortKey = "name" },
    { title = "Bread", width = 55, sortKey = "Bread" },
    { title = "Cheese", width = 55, sortKey = "Cheese" },
    { title = "Fish", width = 55, sortKey = "Fish" },
    { title = "Fruit", width = 55, sortKey = "Fruit" },
    { title = "Fungus", width = 55, sortKey = "Fungus" },
    { title = "Meat", width = 55, sortKey = "Meat" },
}

-- 2. Interactive Column Headers
local currentX = 25
for _, col in ipairs(cols) do
    local btn = CreateFrame("Button", nil, viewDietList)
    btn:SetPoint("TOPLEFT", viewDietList, "TOPLEFT", currentX, -35)
    btn:SetSize(col.width, 20)
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetAllPoints(btn)
    label:SetJustifyH(col.title == "Pet Family" and "LEFT" or "CENTER")
    label:SetText(col.title)
    
    -- When clicked, sort the grid by this column's sortKey
    btn:SetScript("OnClick", function()
        UpdateGrid(col.sortKey)
    end)
    
    col.xOffset = currentX - 10 
    currentX = currentX + col.width
end

-- 3. ScrollFrame Setup
local scrollFrame = CreateFrame("ScrollFrame", nil, viewDietList, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

local content = CreateFrame("Frame")
content:SetSize(470, 480)
scrollFrame:SetScrollChild(content)

-- Helper function to check if the pet eats a specific food
local function EatenByPet(dietArray, foodType)
    if not dietArray then return false end
    for _, food in ipairs(dietArray) do
        if food == foodType then return true end
    end
    return false
end

local checkmark = "|cFF00FF00X|r" 

-- 4. Row Pooling (Create 18 empty rows with cell arrays)
local rows = {}
local rowHeight = 24

for i = 1, 18 do
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(470, rowHeight)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -((i - 1) * rowHeight))
    
    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetColorTexture(1, 1, 1, 0.3)
    PixelUtil.SetPoint(divider, "BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    PixelUtil.SetPoint(divider, "BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    PixelUtil.SetHeight(divider, 1)
    
    row.cells = {}
    
    -- Generate empty FontStrings based on our column config
    for colIdx, col in ipairs(cols) do
        local cell = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
            return a < b -- Alphabetical sort
        else
            local petA_eats = EatenByPet(HunterPetDB[a].diet, sortBy)
            local petB_eats = EatenByPet(HunterPetDB[b].diet, sortBy)
            
            -- If both have the same value (both true or both false), default to alphabetical
            if petA_eats == petB_eats then
                return a < b 
            end
            
            -- Rank pets that CAN eat the food (true) above those that CANNOT (false)
            return petA_eats and not petB_eats
        end
    end)
    
    -- Loop through the pre-made rows and populate the sorted data
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

-- Initialize the grid by sorting alphabetically
UpdateGrid("name")

addonTable.ViewDietList = viewDietList