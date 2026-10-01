-- ViewAbilitiesList.lua
local addonName, addonTable = ...
local viewAbilitiesList = CreateFrame("Frame")
viewAbilitiesList:Hide()

-- 1. Headers
local function CreateHeader(text, xOffset, width)
    local header = viewAbilitiesList:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", viewAbilitiesList, "TOPLEFT", xOffset, -35)
    header:SetWidth(width)
    header:SetJustifyH("LEFT")
    header:SetText(text)
end

CreateHeader("Pet Family", 25, 110)
CreateHeader("Special Abilities", 140, 150)
CreateHeader("Normal Abilities", 290, 150)

-- 2. Scroll Setup
local scrollFrame = CreateFrame("ScrollFrame", nil, viewAbilitiesList, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

local content = CreateFrame("Frame")
content:SetSize(470, 480)
scrollFrame:SetScrollChild(content)

-- 3. Spell Icon Generator Logic
local function CreateSpellIcon(parentRow, spellID, xOffset)
    -- Fetch the data from the WoW client
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then return end -- Failsafe if a spell ID is invalid
    
    local btn = CreateFrame("Button", nil, parentRow)
    btn:SetSize(20, 20)
    btn:SetPoint("LEFT", parentRow, "LEFT", xOffset, 0)
    
    -- Apply the official game icon
    local tex = btn:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture(spellInfo.iconID)
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Crop the rounded corners
    
    -- Bind the native WoW Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID) -- This automatically generates the full tooltip!
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return btn
end

-- 4. Draw the Grid
local sortedPets = {}
for petName in pairs(HunterPetDB) do table.insert(sortedPets, petName) end
table.sort(sortedPets)

local rowHeight = 24
for i, petName in ipairs(sortedPets) do
    local petData = HunterPetDB[petName]
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(470, rowHeight)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -((i - 1) * rowHeight))
    
    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetColorTexture(1, 1, 1, 0.3)
    PixelUtil.SetPoint(divider, "BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    PixelUtil.SetPoint(divider, "BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    PixelUtil.SetHeight(divider, 1)
    
    -- Family Name
    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", row, "LEFT", 0, 0)
    nameLabel:SetWidth(110)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetText(petName)
    
    -- Render Special Abilities
    local currentX = 115
    if petData.abilities and petData.abilities.special then
        for _, spellID in ipairs(petData.abilities.special) do
            CreateSpellIcon(row, spellID, currentX)
            currentX = currentX + 24 -- Move over 24 pixels for the next icon
        end
    end
    
    -- Render Normal Abilities
    currentX = 265
    if petData.abilities and petData.abilities.normal then
        for _, spellID in ipairs(petData.abilities.normal) do
            CreateSpellIcon(row, spellID, currentX)
            currentX = currentX + 24 
        end
    end
end

addonTable.ViewAbilitiesList = viewAbilitiesList