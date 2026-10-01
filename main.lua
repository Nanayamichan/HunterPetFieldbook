-- main.lua
local addonName, addonTable = ...

-------------------------------------------------
-- 1. MAIN WINDOW SETUP
-------------------------------------------------
local myWindow = CreateFrame("Frame", "MyAddonWindow", UIParent, "BasicFrameTemplate")
myWindow:SetSize(570, 480) -- Increased to 570
myWindow:Hide()
myWindow:SetMovable(true)
myWindow:EnableMouse(true)
myWindow:RegisterForDrag("LeftButton")
myWindow:SetScript("OnDragStart", myWindow.StartMoving)

myWindow.title = myWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
myWindow.title:SetPoint("CENTER", myWindow.TitleBg, "CENTER", 0, 0)
myWindow.title:SetText("Hunter Pet Guide")

-- Add Resizing Capabilities
myWindow:SetResizable(true)

-- Lock width at 570, allow height to expand up to 1200
if myWindow.SetResizeBounds then
    myWindow:SetResizeBounds(570, 480, 570, 1200) 
else
    myWindow:SetMinResize(570, 480)
    myWindow:SetMaxResize(570, 1200)
end

-- Create the draggable grip icon in the bottom right corner
local resizeGrip = CreateFrame("Button", nil, myWindow)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", myWindow, "BOTTOMRIGHT", -6, 6)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

-- Start sizing when clicked
resizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        -- "BOTTOM" tells the API to only drag the bottom edge vertically
        myWindow:StartSizing("BOTTOM")
    end
end)

-- Stop sizing and save the new dimensions when the mouse is released
resizeGrip:SetScript("OnMouseUp", function(self, button)
    myWindow:StopMovingOrSizing()
    if MyAddonState then
        MyAddonState.width = myWindow:GetWidth()
        MyAddonState.height = myWindow:GetHeight()
    end
end)

-------------------------------------------------
-- 2. VIEW ROUTING & STATE SETUP
-------------------------------------------------
local viewGeneral = addonTable.ViewGeneral
viewGeneral:SetParent(myWindow)
viewGeneral:SetAllPoints(myWindow)

local viewPetList = addonTable.ViewPetList
viewPetList:SetParent(myWindow)
viewPetList:SetAllPoints(myWindow)

local viewDietList = addonTable.ViewDietList
viewDietList:SetParent(myWindow)
viewDietList:SetAllPoints(myWindow)

local viewAbilitiesList = addonTable.ViewAbilitiesList
viewAbilitiesList:SetParent(myWindow)
viewAbilitiesList:SetAllPoints(myWindow)

local function LoadView(viewName)
    viewGeneral:Hide()
    viewPetList:Hide()
    viewDietList:Hide()
    viewAbilitiesList:Hide()
    
    if viewName == "General" then
        viewGeneral:Show()
        MyAddonState.lastView = "General"
        myWindow.title:SetText("Hunter Pet Fieldbook - General")
    elseif viewName == "PetList" then
        viewPetList:Show()
        MyAddonState.lastView = "PetList"
        myWindow.title:SetText("Hunter Pet Fieldbook - Pet List")
    elseif viewName == "DietList" then
        viewDietList:Show()
        MyAddonState.lastView = "DietList"
        myWindow.title:SetText("Hunter Pet Fieldbook - Diets")
    elseif viewName == "AbilitiesList" then
        viewAbilitiesList:Show()
        MyAddonState.lastView = "AbilitiesList"
        myWindow.title:SetText("Hunter Pet Fieldbook - Abilities")
    end
end

-- Explicitly expose the LoadView function to your other scripts
addonTable.LoadView = LoadView

-------------------------------------------------
-- 3. SAVED VARIABLES & EVENT HANDLING
-------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        MyAddonState = MyAddonState or {
            lastView = "General",
            posX = 0,
            posY = 0,
            width = 520,
            height = 480,
            minimapAngle = math.rad(225) -- Store default minimap angle
        }
        
        myWindow:ClearAllPoints()
        myWindow:SetPoint("CENTER", UIParent, "CENTER", MyAddonState.posX, MyAddonState.posY)
        
-- Apply saved dimensions (Force width to 570, keep custom height)
        if MyAddonState.height then
            myWindow:SetSize(570, MyAddonState.height)
        end
        
        -- Apply saved minimap button position
        if addonTable.UpdateMinimapPosition then
            addonTable.UpdateMinimapPosition(MyAddonState.minimapAngle)
        end
        
        LoadView(MyAddonState.lastView)
    end
end)

myWindow:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, xOfs, yOfs = self:GetPoint()
    MyAddonState.posX = xOfs
    MyAddonState.posY = yOfs
end)

-------------------------------------------------
-- 4. BASIC VIEW NAVIGATION BUTTONS
-------------------------------------------------
local btnToPets = CreateFrame("Button", nil, viewGeneral, "UIPanelButtonTemplate")
btnToPets:SetSize(120, 25)
btnToPets:SetPoint("BOTTOM", viewGeneral, "BOTTOM", -130, 15)
btnToPets:SetText("Lookup Pets")
btnToPets:SetScript("OnClick", function() LoadView("PetList") end)

local btnToDiets = CreateFrame("Button", nil, viewGeneral, "UIPanelButtonTemplate")
btnToDiets:SetSize(120, 25)
btnToDiets:SetPoint("BOTTOM", viewGeneral, "BOTTOM", 0, 15)
btnToDiets:SetText("Pet Diets")
btnToDiets:SetScript("OnClick", function() LoadView("DietList") end)

local btnToAbilities = CreateFrame("Button", nil, viewGeneral, "UIPanelButtonTemplate")
btnToAbilities:SetSize(120, 25)
btnToAbilities:SetPoint("BOTTOM", viewGeneral, "BOTTOM", 130, 15)
btnToAbilities:SetText("Pet Abilities")
btnToAbilities:SetScript("OnClick", function() LoadView("AbilitiesList") end)

local btnToGenFromPets = CreateFrame("Button", nil, viewPetList, "UIPanelButtonTemplate")
btnToGenFromPets:SetSize(120, 25)
btnToGenFromPets:SetPoint("BOTTOM", viewPetList, "BOTTOM", 0, 15)
btnToGenFromPets:SetText("Back to General")
btnToGenFromPets:SetScript("OnClick", function() LoadView("General") end)

local btnToGenFromDiets = CreateFrame("Button", nil, viewDietList, "UIPanelButtonTemplate")
btnToGenFromDiets:SetSize(120, 25)
btnToGenFromDiets:SetPoint("BOTTOM", viewDietList, "BOTTOM", 0, 15)
btnToGenFromDiets:SetText("Back to General")
btnToGenFromDiets:SetScript("OnClick", function() LoadView("General") end)

local btnToGenFromAbilities = CreateFrame("Button", nil, viewAbilitiesList, "UIPanelButtonTemplate")
btnToGenFromAbilities:SetSize(120, 25)
btnToGenFromAbilities:SetPoint("BOTTOM", viewAbilitiesList, "BOTTOM", 0, 15)
btnToGenFromAbilities:SetText("Back to General")
btnToGenFromAbilities:SetScript("OnClick", function() LoadView("General") end)

-------------------------------------------------
-- 5. MINIMAP BUTTON SETUP
-------------------------------------------------
local miniBtn = CreateFrame("Button", "MyAddonMinimapBtn", Minimap)
miniBtn:SetFrameLevel(8) 
miniBtn:SetSize(32, 32)
miniBtn:SetMovable(true)
miniBtn:RegisterForDrag("LeftButton")

local icon = miniBtn:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming")
icon:SetSize(20, 20)
icon:SetPoint("CENTER", miniBtn, "CENTER", 0, 0)
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local border = miniBtn:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("CENTER", miniBtn, "CENTER", 11, -11) 

local currentAngle = math.rad(225) 

local function UpdateButtonPosition()
    local radius = (Minimap:GetWidth() / 2) + 5
    local x = math.cos(currentAngle) * radius
    local y = math.sin(currentAngle) * radius
    miniBtn:ClearAllPoints()
    miniBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Expose function so Section 3 can set the angle when the game loads
addonTable.UpdateMinimapPosition = function(angle)
    if angle then
        currentAngle = angle
        UpdateButtonPosition()
    end
end
addonTable.UpdateMinimapPosition(currentAngle)

miniBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local minimapX, minimapY = Minimap:GetCenter()
        local cursorX, cursorY = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cursorX, cursorY = cursorX / scale, cursorY / scale
        currentAngle = math.atan2(cursorY - minimapY, cursorX - minimapX)
        UpdateButtonPosition()
    end)
end)

miniBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    -- Save the new position to Saved Variables when you release the mouse
    if MyAddonState then
        MyAddonState.minimapAngle = currentAngle
    end
end)

miniBtn:SetScript("OnClick", function()
    if myWindow:IsShown() then
        myWindow:Hide()
    else
        myWindow:Show()
    end
end)

miniBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Hunter Pet Fieldbook", 1, 0.82, 0)
    GameTooltip:Show()
end)

miniBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

--icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTaming") -- Hunter BM icon
--icon:SetTexture("Interface\\Icons\\Ability_Hunter_Pet_Bear") -- Bear icon
