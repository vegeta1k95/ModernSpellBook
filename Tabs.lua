ModernSpellBookFrame.Tabgroups = {}

-- Tab colors
local disabledVertexColor = {0.5, 0.5, 0.5, 1}
local enabledVertexColor = {1, 1, 1, 1}
local normalFontColor = {1, 0.82, 0}
local highlightFontColor = {1, 1, 1}
local disabledFontColor = {0.5, 0.41, 0}

function ModernSpellBookFrame:NewTab(name)
    local tabNumber = table.getn(ModernSpellBookFrame.Tabgroups) +1
    local tab = CreateFrame("Button", "ModernSpellBookFrame_Tab".. tabNumber, ModernSpellBookFrame)
    tab:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
    tab:SetHighlightTexture("Interface\\Spellbook\\UI-SpellBook-Tab1-Selected")

    -- Create font string manually (vanilla doesn't have SetNormalFontObject on buttons)
    local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tab:SetFontString(tabText)

    tab.SetName = function(self, name)
        tab.Name = name
        tabText:SetText(name)
        local tw = 60
        if tabText.GetStringWidth then tw = tabText:GetStringWidth() end
        tab:SetWidth(tw +40)
        tab:SetHeight(55)
    end

    tab:SetName(name)

    table.insert(ModernSpellBookFrame.Tabgroups, tab)
    local relativePosition = ModernSpellBookFrame
    if tabNumber == 1 then
        tab:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
        tab:GetNormalTexture():SetVertexColor(unpack(enabledVertexColor))
        tab:GetFontString():SetTextColor(unpack(normalFontColor))
    else
        relativePosition = ModernSpellBookFrame.Tabgroups[tabNumber - 1]
        tab:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
        tab:GetNormalTexture():SetVertexColor(unpack(disabledVertexColor))
        tab:GetFontString():SetTextColor(unpack(disabledFontColor))
    end

    tab.UpdatePosition = function(self, isMainFrameMinimized)
        tab:ClearAllPoints()

        if tabNumber == 1 then
            if isMainFrameMinimized then
                tab:SetPoint("BOTTOMLEFT", ModernSpellBookFrame, "BOTTOMLEFT", 20, -41)
            else
                tab:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 50, -10)
            end
        else
            -- Find previous visible tab to anchor to
            local anchor = nil
            for j = tabNumber - 1, 1, -1 do
                local prevTab = ModernSpellBookFrame.Tabgroups[j]
                if prevTab and prevTab:IsShown() then
                    anchor = prevTab
                    break
                end
            end
            if anchor then
                tab:SetPoint("TOPLEFT", anchor, "TOPRIGHT", -13, 0)
            else
                -- No visible previous tab, anchor to frame
                if isMainFrameMinimized then
                    tab:SetPoint("BOTTOMLEFT", ModernSpellBookFrame, "BOTTOMLEFT", 20, -41)
                else
                    tab:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 50, -10)
                end
            end
        end
    end

    tab.SetMinmaxPosition = function(self, isMainFrameMinimized)
        if isMainFrameMinimized then
            tab:GetFontString():SetPoint("CENTER", tab, "CENTER", 0, 2.5)
            tab:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
            tab:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
        else
            tab:GetFontString():SetPoint("CENTER", tab, "CENTER", 0, -2.5)
            tab:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
            tab:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
        end

        tab:UpdatePosition(isMainFrameMinimized)
    end

    tab:SetScript("OnClick", function()
        local wasPreviousSelectionDifferent = ModernSpellBookFrame.selectedTab ~= tabNumber
        if not wasPreviousSelectionDifferent then return end

        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        ModernSpellBookFrame.selectedTab = tabNumber
        ModernSpellBook_DB.lastTab = tabNumber

        tab:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
        tab:GetNormalTexture():SetVertexColor(unpack(enabledVertexColor))

        for _, other_tab in ipairs(ModernSpellBookFrame.Tabgroups) do
            if other_tab ~= tab then
                other_tab:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
                other_tab:GetNormalTexture():SetVertexColor(unpack(disabledVertexColor))
                other_tab:GetFontString():SetTextColor(unpack(disabledFontColor))
            end
        end

        ModernSpellBookFrame.currentPage = 1
        ModernSpellBook_DB.lastPage = 1
        ModernSpellBookFrame.previousPage:Disable()
        ModernSpellBookFrame:DrawPage()
    end)

    tab:SetScript("OnEnter", function()
        tab:GetFontString():SetTextColor(unpack(highlightFontColor))
    end)

    tab:SetScript("OnLeave", function()
        tab:SetDefaultFontColor()
    end)

    tab.SetDefaultFontColor = function(self)
        if ModernSpellBookFrame.selectedTab == tabNumber then
            tab:GetFontString():SetTextColor(unpack(normalFontColor))
        else
            tab:GetFontString():SetTextColor(unpack(disabledFontColor))
        end
    end

    tab.UpdateAsPetTab = function(self)
        local petType = UnitCreatureType("pet")
        if petType then
            tab:SetName(petType)
            tab:Show()
        else
            tab:Hide()
            if ModernSpellBookFrame.selectedTab == tabNumber then
                ModernSpellBookFrame.selectedTab = 1
                ModernSpellBookFrame.Tabgroups[1]:Click()
                ModernSpellBookFrame.Tabgroups[1]:GetFontString():SetTextColor(unpack(normalFontColor))
            end
        end

        ModernSpellBookFrame:PositionAllTabs()
    end

    return tab
end

function ModernSpellBookFrame:GetFinalVisibleTab()
    local finalVisibleTab = 1
    for i = 1, table.getn(ModernSpellBookFrame.Tabgroups) do
        if ModernSpellBookFrame.Tabgroups[i]:IsShown() then
            finalVisibleTab = i
        end
    end
    return ModernSpellBookFrame.Tabgroups[finalVisibleTab]
end

local leftButtons = {"ShowPassiveSpellsCheckBox", "ShowAllSpellRanksCheckbox", "ModernSpellBookFrameSearchBar"}
function ModernSpellBookFrame:GetRightmostLeftButton()
    local finalVisibleButton = _G[leftButtons[1]]

    for _, item in ipairs(leftButtons) do
        local button = _G[item]
        if button == nil or not button:IsShown() then
            return finalVisibleButton
        end

        finalVisibleButton = button
    end

    return ShowPassiveSpellsCheckBox
end

function ModernSpellBookFrame:PositionAllTabs()
    if ModernSpellBook_DB.isMinimized then
        for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
            tab:UpdatePosition(false)
        end

        local left = ModernSpellBookFrame:GetFinalVisibleTab():GetRight()
        local right = ModernSpellBookFrame:GetRightmostLeftButton():GetLeft()

        for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
            tab:SetMinmaxPosition(left and right and left > right)
        end
    else
        for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
            tab:SetMinmaxPosition(false)
        end
    end
end

ModernSpellBookFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ModernSpellBookFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

ModernSpellBookFrame.PLAYER_REGEN_DISABLED = function(self)
    if ModernSpellBookFrame.isFirstLoad then return end
    local selected_tab = ModernSpellBookFrame.Tabgroups[ModernSpellBookFrame.selectedTab]
    for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
        tab:Disable()
        if tab ~= selected_tab then
            if tab:GetNormalTexture().SetDesaturated then
                tab:GetNormalTexture():SetDesaturated(true)
            end
            tab:GetFontString():SetTextColor(0.5, 0.5, 0.5)
        end
    end
    if ShowAllSpellRanksCheckbox and ShowAllSpellRanksCheckbox.Disable then
        ShowAllSpellRanksCheckbox:Disable()
    end
    if ShowAllSpellRanksCheckboxText and ShowAllSpellRanksCheckboxText.SetTextColor then
        ShowAllSpellRanksCheckboxText:SetTextColor(0.5, 0.5, 0.5)
    end
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox:Disable()
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:SetTextColor(0.5, 0.5, 0.5)
    ModernSpellBookFrame.nextPage:Disable()
    ModernSpellBookFrame.previousPage:Disable()
    if ModernSpellBookFrame.searchBar.Disable then
        ModernSpellBookFrame.searchBar:Disable()
    end
end

ModernSpellBookFrame.PLAYER_REGEN_ENABLED = function(self)
    if ModernSpellBookFrame.isFirstLoad then return end

    for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
        tab:Enable()
        if tab:GetNormalTexture().SetDesaturated then
            tab:GetNormalTexture():SetDesaturated(false)
        end
        tab:SetDefaultFontColor()
    end
    if ShowAllSpellRanksCheckbox and ShowAllSpellRanksCheckbox.Enable then
        ShowAllSpellRanksCheckbox:Enable()
    end
    if ShowAllSpellRanksCheckboxText and ShowAllSpellRanksCheckboxText.SetTextColor then
        ShowAllSpellRanksCheckboxText:SetTextColor(1, 0.82, 0)
    end
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox:Enable()
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:SetTextColor(1, 0.82, 0)
    if ModernSpellBookFrame.searchBar.Enable then
        ModernSpellBookFrame.searchBar:Enable()
    end

    local currentPage = ModernSpellBookFrame.currentPage
    if currentPage <= 1 then
        ModernSpellBookFrame.previousPage:Disable()
    else
        ModernSpellBookFrame.previousPage:Enable()
    end
    if currentPage >= ModernSpellBookFrame.maxPages then
        ModernSpellBookFrame.nextPage:Disable()
    else
        ModernSpellBookFrame.nextPage:Enable()
    end
end
