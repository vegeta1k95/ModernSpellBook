-- MSB_Settings.lua
-- Settings dropdown UI extracted from MSB_Core.lua

function ModernSpellBookFrame:AddSettingsButton()
    local btn = CreateFrame("Button", nil, ModernSpellBookFrame)
    btn:SetWidth(20)
    btn:SetHeight(20)
    btn:SetPoint("RIGHT", ModernSpellBookFrame.searchBar.frame, "LEFT", -15, 0)
    btn:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    btn:SetPushedTexture("Interface\\Icons\\INV_Misc_Gear_01")

    if not ModernSpellBook_DB.iconFrame then
        ModernSpellBook_DB.iconFrame = { spells = true, passives = true, other = true, unlearned = false }
    end
    if ModernSpellBook_DB.iconFrame.unlearned == nil then
        ModernSpellBook_DB.iconFrame.unlearned = false
    end

    -- Apply text color settings live
    local function applyTextColors()
        local nameR, nameG, nameB, subR, subG, subB
        local isDark = ModernSpellBook_DB.textColorMode == "dark"
        if isDark then
            nameR, nameG, nameB = 0, 0, 0
            subR, subG, subB = 0, 0, 0
        else
            nameR, nameG, nameB = 0.989, 0.857, 0.343
            subR, subG, subB = 1, 1, 1
        end
        for i = 1, 50 do
            local f = ModernSpellBookFrame["Spell"..i]
            if f then
                if f.nameText then
                    f.nameText:SetTextColor(nameR, nameG, nameB)
                    f.rankText:SetTextColor(subR, subG, subB)
                    if isDark then
                        f.nameText:SetShadowOffset(0, 0)
                        f.rankText:SetShadowOffset(0, 0)
                    else
                        f.nameText:SetShadowOffset(1, -1)
                        f.nameText:SetShadowColor(0, 0, 0, 0.7)
                        f.rankText:SetShadowOffset(1, -1)
                        f.rankText:SetShadowColor(0, 0, 0, 0.7)
                    end
                end
                if f.trailBg then
                    if isDark then
                        f.trailBg:SetBlendMode("ADD")
                    else
                        f.trailBg:SetBlendMode("BLEND")
                    end
                end
            end
        end
    end
    ModernSpellBookFrame.applyTextColors = applyTextColors

    -- Dropdown menu using vanilla UIDropDownMenu
    local dropdown = CreateFrame("Frame", "ModernSpellBookSettingsDropDown", ModernSpellBookFrame)
    dropdown.displayMode = "MENU"
    dropdown.initialize = function(level)
        level = level or 1
        local info = {}

        if level == 1 then
            -- Remember page
            info = {}
            info.text = "Remember page"
            info.checked = ModernSpellBook_DB.rememberPage
            info.keepShownOnClick = 1
            info.func = function()
                ModernSpellBook_DB.rememberPage = not ModernSpellBook_DB.rememberPage
            end
            UIDropDownMenu_AddButton(info, level)

            -- Spell counter
            info = {}
            info.text = "Spell counter"
            info.checked = ModernSpellBook_DB.showSpellCounter
            info.keepShownOnClick = 1
            info.func = function()
                ModernSpellBook_DB.showSpellCounter = not ModernSpellBook_DB.showSpellCounter
                SpellDataService:UpdateSpellCounter()
            end
            UIDropDownMenu_AddButton(info, level)

            -- Show unlearned spells
            info = {}
            info.text = "Show unlearned"
            info.checked = ModernSpellBook_DB.showUnlearned
            info.keepShownOnClick = 1
            info.func = function()
                ModernSpellBook_DB.showUnlearned = not ModernSpellBook_DB.showUnlearned
                ModernSpellBookFrame:DrawPage()
            end
            UIDropDownMenu_AddButton(info, level)

            -- Highlights submenu
            info = {}
            info.text = "Highlights"
            info.hasArrow = 1
            info.notCheckable = 1
            info.value = "highlights"
            UIDropDownMenu_AddButton(info, level)

            -- Font size submenu
            info = {}
            info.text = "Font size"
            info.hasArrow = 1
            info.notCheckable = 1
            info.value = "fontSize"
            UIDropDownMenu_AddButton(info, level)

            -- Spell Text Color submenu
            info = {}
            info.text = "Spell text color"
            info.hasArrow = 1
            info.notCheckable = 1
            info.value = "textColor"
            UIDropDownMenu_AddButton(info, level)

            -- Icon Frame submenu
            info = {}
            info.text = "Spell icon frame"
            info.hasArrow = 1
            info.notCheckable = 1
            info.value = "iconFrame"
            UIDropDownMenu_AddButton(info, level)

        elseif level == 2 then
            if UIDROPDOWNMENU_MENU_VALUE == "textColor" then
                info = {}
                info.text = "Light"
                info.checked = ModernSpellBook_DB.textColorMode ~= "dark"
                info.func = function()
                    ModernSpellBook_DB.textColorMode = "light"
                    ModernSpellBookFrame:DrawPage()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)

                info = {}
                info.text = "Dark"
                info.checked = ModernSpellBook_DB.textColorMode == "dark"
                info.func = function()
                    ModernSpellBook_DB.textColorMode = "dark"
                    ModernSpellBookFrame:DrawPage()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)

            elseif UIDROPDOWNMENU_MENU_VALUE == "fontSize" then
                local sizes = {9, 10, 10.5, 11, 11.5, 12, 13}
                for _, size in ipairs(sizes) do
                    info = {}
                    info.text = size
                    info.value = size
                    info.checked = (ModernSpellBook_DB.fontSize == size)
                    info.func = function()
                        ModernSpellBook_DB.fontSize = this.value
                        ModernSpellBookFrame:DrawPage()
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end

            elseif UIDROPDOWNMENU_MENU_VALUE == "highlights" then
                info = {}
                info.text = "Learned spells glow"
                info.checked = ModernSpellBook_DB.highlights.learnedGlow
                info.keepShownOnClick = 1
                info.func = function()
                    ModernSpellBook_DB.highlights.learnedGlow = not ModernSpellBook_DB.highlights.learnedGlow
                    ModernSpellBookFrame:DrawPage()
                end
                UIDropDownMenu_AddButton(info, level)

                info = {}
                info.text = "Learned spells badge"
                info.checked = ModernSpellBook_DB.highlights.learnedBadge
                info.keepShownOnClick = 1
                info.func = function()
                    ModernSpellBook_DB.highlights.learnedBadge = not ModernSpellBook_DB.highlights.learnedBadge
                    ModernSpellBookFrame:DrawPage()
                end
                UIDropDownMenu_AddButton(info, level)

                info = {}
                info.text = "Available spells glow"
                info.checked = ModernSpellBook_DB.highlights.availableGlow
                info.keepShownOnClick = 1
                info.func = function()
                    ModernSpellBook_DB.highlights.availableGlow = not ModernSpellBook_DB.highlights.availableGlow
                    ModernSpellBookFrame:DrawPage()
                end
                UIDropDownMenu_AddButton(info, level)

                info = {}
                info.text = "Available spells badge"
                info.checked = ModernSpellBook_DB.highlights.availableBadge
                info.keepShownOnClick = 1
                info.func = function()
                    ModernSpellBook_DB.highlights.availableBadge = not ModernSpellBook_DB.highlights.availableBadge
                    ModernSpellBookFrame:DrawPage()
                end
                UIDropDownMenu_AddButton(info, level)

            elseif UIDROPDOWNMENU_MENU_VALUE == "iconFrame" then
                info = {}
                info.text = "Spells"
                info.checked = ModernSpellBook_DB.iconFrame.spells
                info.keepShownOnClick = 1
                info.func = function()
                    ModernSpellBook_DB.iconFrame.spells = not ModernSpellBook_DB.iconFrame.spells
                    ModernSpellBookFrame:DrawPage()
                end
                UIDropDownMenu_AddButton(info, level)

                info = {}
                info.text = "Other"
                info.checked = ModernSpellBook_DB.iconFrame.other
                info.keepShownOnClick = 1
                info.func = function()
                    ModernSpellBook_DB.iconFrame.other = not ModernSpellBook_DB.iconFrame.other
                    ModernSpellBookFrame:DrawPage()
                end
                UIDropDownMenu_AddButton(info, level)

                info = {}
                info.text = "Unlearned"
                info.checked = ModernSpellBook_DB.iconFrame.unlearned
                info.keepShownOnClick = 1
                info.func = function()
                    ModernSpellBook_DB.iconFrame.unlearned = not ModernSpellBook_DB.iconFrame.unlearned
                    ModernSpellBookFrame:DrawPage()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end

    ModernSpellBookFrame.settingsButton = btn

    btn:SetScript("OnClick", function()
        ToggleDropDownMenu(1, nil, dropdown, btn, 0, 0)
    end)

    -- Hide dropdown when spellbook closes
    ModernSpellBookFrame:SetScript("OnHide", function()
        CloseDropDownMenus()
        ActionBarHelper:HideAllGrids()
    end)
end

