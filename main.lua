-- main.lua
local addonName, addonTable = ...

-------------------------------------------------
-- 1. MAIN WINDOW SETUP & RESIZE LOGIC
-------------------------------------------------
local myWindow = CreateFrame("Frame", "HunterPetWindow", UIParent, "BasicFrameTemplate")
myWindow:Hide()
myWindow:SetMovable(true)
myWindow:EnableMouse(true)
myWindow:RegisterForDrag("LeftButton")
myWindow:SetScript("OnDragStart", myWindow.StartMoving)
myWindow:SetResizable(true)

myWindow.title = myWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
myWindow.title:SetPoint("CENTER", myWindow.TitleBg, "CENTER", 0, 0)
myWindow.title:SetText("Hunter Pet Fieldbook")

local function ApplyResizeSettings()
    if not MyAddonState then return end
    
    if MyAddonState.allowHorizontalResize then
        if myWindow.SetResizeBounds then
            myWindow:SetResizeBounds(620, 480, 1200, 1200)
        else
            myWindow:SetMinResize(620, 480)
            myWindow:SetMaxResize(1200, 1200)
        end
    else
        if myWindow.SetResizeBounds then
            myWindow:SetResizeBounds(620, 480, 620, 1200)
        else
            myWindow:SetMinResize(620, 480)
            myWindow:SetMaxResize(620, 1200)
        end
        
        if myWindow:GetWidth() > 620 then
            myWindow:SetWidth(620)
            MyAddonState.width = 620
        end
    end
end
addonTable.ApplyResizeSettings = ApplyResizeSettings

local resizeGrip = CreateFrame("Button", nil, myWindow)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", myWindow, "BOTTOMRIGHT", -6, 6)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        if MyAddonState and MyAddonState.allowHorizontalResize then
            myWindow:StartSizing("BOTTOMRIGHT")
        else
            myWindow:StartSizing("BOTTOM")
        end
    end
end)

resizeGrip:SetScript("OnMouseUp", function(self, button)
    myWindow:StopMovingOrSizing()
    if MyAddonState then
        MyAddonState.height = myWindow:GetHeight()
        if MyAddonState.allowHorizontalResize then
            MyAddonState.width = myWindow:GetWidth()
        end
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

local viewSettings = addonTable.ViewSettings
viewSettings:SetParent(myWindow)
viewSettings:SetAllPoints(myWindow)

local function LoadView(viewName)
    viewGeneral:Hide()
    viewPetList:Hide()
    viewDietList:Hide()
    viewAbilitiesList:Hide()
    viewSettings:Hide()
    
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
    elseif viewName == "Settings" then
        viewSettings:Show()
        MyAddonState.lastView = "Settings"
        myWindow.title:SetText("Hunter Pet Fieldbook - Settings")
    end
end

addonTable.LoadView = LoadView

-------------------------------------------------
-- 3. SAVED VARIABLES & EVENT HANDLING
-------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        MyAddonState = MyAddonState or {}
        
        MyAddonState.startupView = MyAddonState.startupView or "General"
        if MyAddonState.showMinimap == nil then MyAddonState.showMinimap = true end
        
        if MyAddonState.colorPetLevels == nil then MyAddonState.colorPetLevels = true end 

        MyAddonState.posX = MyAddonState.posX or 0
        MyAddonState.posY = MyAddonState.posY or 0
        MyAddonState.width = MyAddonState.width or 620
        MyAddonState.height = MyAddonState.height or 480
        MyAddonState.minimapAngle = MyAddonState.minimapAngle or math.rad(225)
        MyAddonState.allowHorizontalResize = MyAddonState.allowHorizontalResize or false
        
        myWindow:ClearAllPoints()
        myWindow:SetPoint("CENTER", UIParent, "CENTER", MyAddonState.posX, MyAddonState.posY)
        
        if not MyAddonState.allowHorizontalResize then
            MyAddonState.width = 620
        end
        myWindow:SetSize(MyAddonState.width, MyAddonState.height)
        
        addonTable.ApplyResizeSettings()
        
        if addonTable.UpdateMinimapPosition then
            addonTable.UpdateMinimapPosition(MyAddonState.minimapAngle)
        end
        if addonTable.UpdateMinimapVisibility then
            addonTable.UpdateMinimapVisibility()
        end
        
        LoadView(MyAddonState.startupView)
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
btnToPets:SetSize(110, 25)
btnToPets:SetPoint("BOTTOM", viewGeneral, "BOTTOM", -165, 15)
btnToPets:SetText("Lookup Pets")
btnToPets:SetScript("OnClick", function() LoadView("PetList") end)

local btnToDiets = CreateFrame("Button", nil, viewGeneral, "UIPanelButtonTemplate")
btnToDiets:SetSize(110, 25)
btnToDiets:SetPoint("BOTTOM", viewGeneral, "BOTTOM", -55, 15)
btnToDiets:SetText("Pet Diets")
btnToDiets:SetScript("OnClick", function() LoadView("DietList") end)

local btnToAbilities = CreateFrame("Button", nil, viewGeneral, "UIPanelButtonTemplate")
btnToAbilities:SetSize(110, 25)
btnToAbilities:SetPoint("BOTTOM", viewGeneral, "BOTTOM", 55, 15)
btnToAbilities:SetText("Pet Abilities")
btnToAbilities:SetScript("OnClick", function() LoadView("AbilitiesList") end)

local btnToSettings = CreateFrame("Button", nil, viewGeneral, "UIPanelButtonTemplate")
btnToSettings:SetSize(110, 25)
btnToSettings:SetPoint("BOTTOM", viewGeneral, "BOTTOM", 165, 15)
btnToSettings:SetText("Settings")
btnToSettings:SetScript("OnClick", function() LoadView("Settings") end)

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

local btnToGenFromSettings = CreateFrame("Button", nil, viewSettings, "UIPanelButtonTemplate")
btnToGenFromSettings:SetSize(120, 25)
btnToGenFromSettings:SetPoint("BOTTOM", viewSettings, "BOTTOM", 0, 15)
btnToGenFromSettings:SetText("Back to General")
btnToGenFromSettings:SetScript("OnClick", function() LoadView("General") end)

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

addonTable.UpdateMinimapPosition = function(angle)
    if angle then
        currentAngle = angle
        UpdateButtonPosition()
    end
end
addonTable.UpdateMinimapPosition(currentAngle)

addonTable.UpdateMinimapVisibility = function()
    if MyAddonState and MyAddonState.showMinimap == false then
        miniBtn:Hide()
    else
        miniBtn:Show()
    end
end

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

-------------------------------------------------
-- 6. SLASH COMMANDS
-------------------------------------------------
SLASH_HUNTERPETFIELDBOOK1 = "/hpf"
SLASH_HUNTERPETFIELDBOOK2 = "/nana"

SlashCmdList["HUNTERPETFIELDBOOK"] = function()
    if myWindow:IsShown() then
        myWindow:Hide()
    else
        myWindow:Show()
    end
end