local classColors = {{0.87,0.38,0.21}, {0.96,0.55,0.73}, {0.67,0.83,0.45}, {1.00,0.96,0.41}, {1, 1, 1}, {0.77,0.12,0.23}, {0.00,0.44,0.87}, {0.25,0.78,0.92}, {0.53,0.53,0.93}, {0.00,1.00,0.60}, {1.00,0.49,0.04}, {0.64,0.19,0.79}, {0.20,0.58,0.50}}

local maximumPages = 2
local spellUpdateRequired = true
local NEW_KEYWORD = string.lower(";".. NEW.. ";")
local currentAddonVersion = "1.4"

local windowSettings = {
    posy = 155,
    height = 560,
    width1 = 550,
    width2 = 1058,
}

-- Build the frame manually since PortraitFrameTemplate doesn't exist in vanilla 1.12.1
ModernSpellBookFrame = CreateFrame("Frame", "ModernSpellBookFrame", SpellBookFrame)

-- Minimal frame setup (no PortraitFrameTemplate in vanilla)
-- The spellbook background textures handle the visual appearance
do
    local f = ModernSpellBookFrame

    -- Simple backdrop border
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    -- Close button
    f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.CloseButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
end

ModernSpellBookFrame.ADDON_LOADED = function(self, event, addon)
    if addon ~= "ModernSpellBook" then return end

    -- Our saved variables
    ModernSpellBook_DB = ModernSpellBook_DB or {showPassives = true, isMinimized = false, knownSpells = {}, addonVersion = currentAddonVersion}
    ModernSpellBookFrame:AlterOlderSavedVariables()

    ModernSpellBookFrame.ClientLocale = ModernSpellBookFrame.Locales[GetLocale()] or ModernSpellBookFrame.Locales["enUS"]
    ModernSpellBookFrame.currentPage = 1
    ModernSpellBookFrame.maxPages = 1
    ModernSpellBookFrame.stanceButtons = {}
    ModernSpellBookFrame.unlockedStances = {}
    ModernSpellBookFrame.isFirstLoad = true

    ModernSpellBookFrame:SetupFrame()
    ModernSpellBookFrame:AddPassiveCheckBox()
    ModernSpellBookFrame:AddSearchBar()

    ModernSpellBookFrame:AddPageButtons()
    ModernSpellBookFrame:AddCancelButton()
    ModernSpellBookFrame:AddMinimizeButton()

    ModernSpellBookFrame:SetShape(ModernSpellBook_DB.isMinimized)

    -- If the user first opens the spellbook in combat, nothing will show. So we force load the spellbook when they join the game.
    ModernSpellBookFrame:ForceLoad()

    ModernSpellBookFrame:UnregisterEvent("ADDON_LOADED")
end

function ModernSpellBookFrame:ForceLoad()
    ToggleSpellBook(BOOKTYPE_SPELL)
    ToggleSpellBook(BOOKTYPE_SPELL)
    C_Timer.After(0.5, function()
        if SpellBookFrame:IsShown() then
            ToggleSpellBook(BOOKTYPE_SPELL)
        end
    end)
end

function ModernSpellBookFrame:AlterOlderSavedVariables()
    if ModernSpellBook_DB.addonVersion == nil then
        ModernSpellBook_DB.addonVersion = currentAddonVersion
        ModernSpellBook_DB.knownSpells = {}
    end

    ModernSpellBook_DB.addonVersion = currentAddonVersion
end

function ModernSpellBookFrame:AddSearchBar()
    local defaultText = ModernSpellBookFrame.ClientLocale.SearchAbilities

    -- Build EditBox manually since SearchBoxTemplate doesn't exist in vanilla
    ModernSpellBookFrame.searchBar = CreateFrame("EditBox", "ModernSpellBookFrameSearchBar", ModernSpellBookFrame)
    local searchBar = ModernSpellBookFrame.searchBar
    searchBar:SetWidth(200)
    searchBar:SetHeight(20)
    searchBar:SetAutoFocus(false)
    searchBar:SetFontObject(ChatFontNormal)
    searchBar:SetTextInsets(16, 20, 0, 0)

    -- Background
    local left = searchBar:CreateTexture(nil, "BACKGROUND")
    left:SetTexture("Interface\\Common\\Common-Input-Border")
    left:SetWidth(8)
    left:SetHeight(20)
    left:SetPoint("LEFT", searchBar, "LEFT", -5, 0)
    left:SetTexCoord(0, 0.0625, 0, 0.625)

    local right = searchBar:CreateTexture(nil, "BACKGROUND")
    right:SetTexture("Interface\\Common\\Common-Input-Border")
    right:SetWidth(8)
    right:SetHeight(20)
    right:SetPoint("RIGHT", searchBar, "RIGHT", 5, 0)
    right:SetTexCoord(0.9375, 1, 0, 0.625)

    local mid = searchBar:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture("Interface\\Common\\Common-Input-Border")
    mid:SetWidth(10)
    mid:SetHeight(20)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetTexCoord(0.0625, 0.9375, 0, 0.625)

    -- Search icon
    local searchIcon = searchBar:CreateTexture(nil, "OVERLAY")
    searchIcon:SetWidth(14)
    searchIcon:SetHeight(14)
    searchIcon:SetPoint("LEFT", searchBar, "LEFT", 2, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetVertexColor(0.6, 0.6, 0.6)

    -- Instructions text (placeholder)
    searchBar.Instructions = searchBar:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    searchBar.Instructions:SetPoint("LEFT", searchBar, "LEFT", 16, 0)
    searchBar.Instructions:SetPoint("RIGHT", searchBar, "RIGHT", -20, 0)
    searchBar.Instructions:SetJustifyH("LEFT")
    searchBar.Instructions:SetText(defaultText)

    -- Clear button
    searchBar.clearButton = CreateFrame("Button", nil, searchBar)
    searchBar.clearButton:SetWidth(14)
    searchBar.clearButton:SetHeight(14)
    searchBar.clearButton:SetPoint("RIGHT", searchBar, "RIGHT", -3, 0)
    searchBar.clearButton:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    searchBar.clearButton:Hide()
    searchBar.clearButton:SetScript("OnClick", function()
        searchBar:SetText("")
        searchBar.Instructions:Show()
        searchBar.clearButton:Hide()
        ModernSpellBookFrame:RefreshPage()
    end)

    searchBar:SetScript("OnTextChanged", function()
        ModernSpellBookFrame:RefreshPage()

        local inputText = this:GetText()
        if inputText == "" then
            searchBar.clearButton:Hide()
            return
        end

        searchBar.clearButton:Show()
    end)

    ModernSpellBookFrame:SetScript("OnMouseDown", function()
        if ModernSpellBookFrame.searchBar.HasFocus and not ModernSpellBookFrame.searchBar:HasFocus() then return end
        if ModernSpellBookFrame.searchBar.IsCurrentFocusEditBox and not ModernSpellBookFrame.searchBar:IsCurrentFocusEditBox() then return end
        ModernSpellBookFrame.searchBar:ClearFocus()
    end)

    searchBar:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    searchBar:SetScript("OnEnterPressed", function() this:ClearFocus() end)

    searchBar:SetScript("OnEditFocusLost", function()
        local inputText = this:GetText()
        if inputText == "" or string.match(inputText, "^%s*$") then
            searchBar.Instructions:Show()
            this:SetText("")
        end

        this:HighlightText(0, 0)

        ModernSpellBookFrame:RefreshPage()
    end)

    searchBar:SetScript("OnEditFocusGained", function()
        this:HighlightText()
        searchBar.Instructions:Hide()
    end)
end

function ModernSpellBookFrame:SetupFrame()
    local classID = MSB_GetClassIndex()
    ModernSpellBookFrame:EnableMouse(true)
    ModernSpellBookFrame:SetWidth(windowSettings.width2)
    ModernSpellBookFrame:SetHeight(windowSettings.height)
    ModernSpellBookFrame:SetPoint("CENTER", UIParent, "CENTER", 0, windowSettings.posy)
    ModernSpellBookFrame:SetFrameStrata("HIGH")
    HideUIPanel(ModernSpellBookFrame)

    ModernSpellBookFrame.title = ModernSpellBookFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.title:SetPoint("TOP", ModernSpellBookFrame, "TOP", 0, -24)
    ModernSpellBookFrame.title:SetText(SPELLBOOK)

    -- Portrait mask removed (no PortraitFrameTemplate in vanilla)

    ModernSpellBookFrame.backgroundLeft = ModernSpellBookFrame:CreateTexture(nil, "ARTWORK")
    ModernSpellBookFrame.backgroundLeft:SetWidth(windowSettings.width1 -30)
    ModernSpellBookFrame.backgroundLeft:SetHeight(499)
    ModernSpellBookFrame.backgroundLeft:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 15, -50)
    ModernSpellBookFrame.backgroundLeft:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-page-1")
    ModernSpellBookFrame.backgroundLeft:SetTexCoord(1, 0.04, 0, 0.93)

    ModernSpellBookFrame.backgroundLeftEnd = ModernSpellBookFrame:CreateTexture(nil, "ARTWORK")
    ModernSpellBookFrame.backgroundLeftEnd:SetWidth(40)
    ModernSpellBookFrame.backgroundLeftEnd:SetHeight(499)
    ModernSpellBookFrame.backgroundLeftEnd:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", -15, -50)
    ModernSpellBookFrame.backgroundLeftEnd:SetTexture("Interface\\Spellbook\\spellbook-page-2")
    ModernSpellBookFrame.backgroundLeftEnd:SetTexCoord(1, 0.04, 0, 0.93)

    ModernSpellBookFrame.backgroundRight = ModernSpellBookFrame:CreateTexture(nil, "ARTWORK")
    ModernSpellBookFrame.backgroundRight:SetWidth(510)
    ModernSpellBookFrame.backgroundRight:SetHeight(499)
    ModernSpellBookFrame.backgroundRight:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 535, -50)
    ModernSpellBookFrame.backgroundRight:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-page-1")
    ModernSpellBookFrame.backgroundRight:SetTexCoord(0.123, 1, 0, 0.93)

    ModernSpellBookFrame.backgroundRightEnd = ModernSpellBookFrame:CreateTexture(nil, "ARTWORK")
    ModernSpellBookFrame.backgroundRightEnd:SetWidth(40)
    ModernSpellBookFrame.backgroundRightEnd:SetHeight(499)
    ModernSpellBookFrame.backgroundRightEnd:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 545 +500, -50)
    ModernSpellBookFrame.backgroundRightEnd:SetTexture("Interface\\Spellbook\\spellbook-page-2")
    ModernSpellBookFrame.backgroundRightEnd:SetTexCoord(0.125, 1, 0, 0.93)

    ModernSpellBookFrame.bookmark = ModernSpellBookFrame:CreateTexture(nil, "OVERLAY")
    ModernSpellBookFrame.bookmark:SetWidth(65)
    ModernSpellBookFrame.bookmark:SetHeight(340)
    ModernSpellBookFrame.bookmark:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", windowSettings.width1-75, -60)
    ModernSpellBookFrame.bookmark:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\bookmark")
    ModernSpellBookFrame.bookmark:SetTexCoord(1, 0, 0, 1)
    ModernSpellBookFrame.bookmark:SetVertexColor(classColors[classID][1], classColors[classID][2], classColors[classID][3])
    classColors = nil

    ModernSpellBookFrame.bookmarkRunes = ModernSpellBookFrame:CreateTexture(nil, "OVERLAY")
    ModernSpellBookFrame.bookmarkRunes:SetWidth(65)
    ModernSpellBookFrame.bookmarkRunes:SetHeight(340)
    ModernSpellBookFrame.bookmarkRunes:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", windowSettings.width1-75, -60)
    ModernSpellBookFrame.bookmarkRunes:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\bookmark_runes")
    ModernSpellBookFrame.bookmarkRunes:SetTexCoord(1, 0, 0, 1)
    ModernSpellBookFrame.bookmarkRunes:SetVertexColor(1, 1, 1)
    ModernSpellBookFrame.bookmarkRunes:SetDrawLayer("OVERLAY", 1)

    -- Book icon removed (no portrait mask support in vanilla)

    ModernSpellBookFrame.noresultsText = ModernSpellBookFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.noresultsText:SetPoint("CENTER", ModernSpellBookFrame.backgroundLeft, "CENTER", 0, 0)
    ModernSpellBookFrame.noresultsText:SetText(ModernSpellBookFrame.ClientLocale.NoResults.. NEW.. ", ".. TALENT.. "'")
    ModernSpellBookFrame.noresultsText:SetTextColor(0, 0, 0)
    ModernSpellBookFrame.noresultsText:SetShadowOffset(0, 0)
    ModernSpellBookFrame.noresultsText:Hide()

    -- UIPanelLayout attributes - try SetAttribute first, fall back to UIPanelWindows table
    if SpellBookFrame.SetAttribute then
        SpellBookFrame:SetAttribute("UIPanelLayout-defined", true)
        SpellBookFrame:SetAttribute("UIPanelLayout-enabled", true)
        SpellBookFrame:SetAttribute("UIPanelLayout-whileDead", nil)
        SpellBookFrame:SetAttribute("UIPanelLayout-pushable", 8)
    end
end

function ModernSpellBookFrame:AddPassiveCheckBox()
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox = CreateFrame("CheckButton", "ShowPassiveSpellsCheckBox", ModernSpellBookFrame, "UICheckButtonTemplate")
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox:SetWidth(20)
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox:SetHeight(20)

    ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text = ModernSpellBookFrame.ShowPassiveSpellsCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:SetPoint("TOPLEFT", ModernSpellBookFrame.ShowPassiveSpellsCheckBox, "TOPLEFT", 20, -3.5)
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:SetText(ModernSpellBookFrame.ClientLocale.ShowPassive)
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
    local passiveTextWidth = 80
    if ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text.GetStringWidth then
        passiveTextWidth = ModernSpellBookFrame.ShowPassiveSpellsCheckBox.text:GetStringWidth()
    end
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox:SetPoint("TOPRIGHT", ModernSpellBookFrame, "TOPRIGHT", -passiveTextWidth -20, -28)
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox:SetChecked(ModernSpellBook_DB.showPassives)
    ModernSpellBookFrame.ShowPassiveSpellsCheckBox:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        ModernSpellBook_DB.showPassives = this:GetChecked()
        ModernSpellBookFrame:DrawPage()
    end)
end

function ModernSpellBookFrame:AddAllRanksCheckBox()
    ShowAllSpellRanksCheckbox = CreateFrame("CheckButton", "ShowAllSpellRanksCheckbox", ModernSpellBookFrame, "UICheckButtonTemplate")
    ShowAllSpellRanksCheckbox:SetWidth(20)
    ShowAllSpellRanksCheckbox:SetHeight(20)
    ShowAllSpellRanksCheckbox:SetChecked(false)

    ShowAllSpellRanksCheckboxText = ShowAllSpellRanksCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ShowAllSpellRanksCheckboxText:SetPoint("TOPLEFT", ShowAllSpellRanksCheckbox, "TOPLEFT", 20, -3.5)
    ShowAllSpellRanksCheckboxText:SetText("All ranks")
    ShowAllSpellRanksCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 10)

    local labelWidth = 50
    if ShowAllSpellRanksCheckboxText.GetStringWidth then
        labelWidth = ShowAllSpellRanksCheckboxText:GetStringWidth()
    end
    ShowAllSpellRanksCheckbox:SetPoint("TOPRIGHT", ModernSpellBookFrame.ShowPassiveSpellsCheckBox, "TOPLEFT", -labelWidth - 10, 0)

    ShowAllSpellRanksCheckbox:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        ModernSpellBookFrame:DrawPage()
    end)
end

function ModernSpellBookFrame:AddPageButtons()
    ModernSpellBookFrame.pageText = ModernSpellBookFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.pageText:SetPoint("BOTTOMRIGHT", ModernSpellBookFrame, "BOTTOMRIGHT", -95, 25)
    ModernSpellBookFrame.pageText:SetText("Page 1")
    ModernSpellBookFrame.pageText:SetTextColor(0, 0, 0)
    ModernSpellBookFrame.pageText:SetShadowOffset(0, 0)

    ModernSpellBookFrame.previousPage = CreateFrame("Button", nil, ModernSpellBookFrame)
    ModernSpellBookFrame.previousPage:SetWidth(25)
    ModernSpellBookFrame.previousPage:SetHeight(25)
    ModernSpellBookFrame.previousPage:SetPoint("TOPLEFT", ModernSpellBookFrame.pageText, "TOPRIGHT", 10, 6.5)
    ModernSpellBookFrame.previousPage:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    ModernSpellBookFrame.previousPage:SetHighlightTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    ModernSpellBookFrame.previousPage:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    ModernSpellBookFrame.previousPage:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    ModernSpellBookFrame.previousPage:Disable()
    ModernSpellBookFrame.previousPage:SetScript("OnClick", function()
        if ModernSpellBookFrame.currentPage <= 1 then return end

        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
        ModernSpellBookFrame.currentPage = math.max(1, ModernSpellBookFrame.currentPage -1)
        ModernSpellBookFrame:RefreshPageElements()
    end)

    ModernSpellBookFrame.nextPage = CreateFrame("Button", nil, ModernSpellBookFrame)
    ModernSpellBookFrame.nextPage:SetWidth(25)
    ModernSpellBookFrame.nextPage:SetHeight(25)
    ModernSpellBookFrame.nextPage:SetPoint("TOPLEFT", ModernSpellBookFrame.previousPage, "TOPLEFT", 30, 0)
    ModernSpellBookFrame.nextPage:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    ModernSpellBookFrame.nextPage:SetHighlightTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    ModernSpellBookFrame.nextPage:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    ModernSpellBookFrame.nextPage:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    ModernSpellBookFrame.nextPage:SetScript("OnClick", function()
        if ModernSpellBookFrame.currentPage >= ModernSpellBookFrame.maxPages then return end

        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
        ModernSpellBookFrame.currentPage = math.min(ModernSpellBookFrame.currentPage +1, ModernSpellBookFrame.maxPages)
        ModernSpellBookFrame:RefreshPageElements()
    end)

    local scrollDebounceTimer = 0
    ModernSpellBookFrame:SetScript("OnMouseWheel", function()
        if GetTime() - scrollDebounceTimer < 0.2 then return end
        scrollDebounceTimer = GetTime()
        local delta = arg1
        if delta > 0 then
            ModernSpellBookFrame.previousPage:Click()
        else
            ModernSpellBookFrame.nextPage:Click()
        end
    end)
end

function ModernSpellBookFrame:AddMinimizeButton()
    ModernSpellBookFrame.minmaxButton = CreateFrame("Button", nil, ModernSpellBookFrame)
    ModernSpellBookFrame.minmaxButton:SetWidth(SpellBookCloseButton:GetWidth())
    ModernSpellBookFrame.minmaxButton:SetHeight(SpellBookCloseButton:GetHeight())
    ModernSpellBookFrame.minmaxButton:SetPoint("TOPRIGHT", SpellBookCloseButton, "TOPLEFT", 10, 0)

    function ModernSpellBookFrame.minmaxButton:UpdateTexture()
        local normalTex = ModernSpellBook_DB.isMinimized
            and "Interface\\Buttons\\UI-Panel-SmallerButton-Up"
            or "Interface\\Buttons\\UI-Panel-CollapseButton-Up"
        local pushedTex = ModernSpellBook_DB.isMinimized
            and "Interface\\Buttons\\UI-Panel-SmallerButton-Down"
            or "Interface\\Buttons\\UI-Panel-CollapseButton-Down"
        ModernSpellBookFrame.minmaxButton:SetNormalTexture(normalTex)
        ModernSpellBookFrame.minmaxButton:SetPushedTexture(pushedTex)
    end

    ModernSpellBookFrame.minmaxButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    ModernSpellBookFrame.minmaxButton:UpdateTexture()

    ModernSpellBookFrame.minmaxButton:SetScript("OnClick", function()
        ModernSpellBook_DB.isMinimized = not ModernSpellBook_DB.isMinimized
        ModernSpellBookFrame.minmaxButton:UpdateTexture()
        ModernSpellBookFrame:SetShape(ModernSpellBook_DB.isMinimized)
        ModernSpellBookFrame:PositionAllTabs()
        if ModernSpellBookFrame.isFirstLoad then return end
        ModernSpellBookFrame:DrawPage()
    end)
end

function ModernSpellBookFrame:SetShape(isMainFrameMinimized)
    if IsAddOnLoaded and IsAddOnLoaded("WhatsTraining") then
        if WhatsTrainingFrame.wtbackgroundframe == nil then
            -- Place a frame behind WhatsTrainingFrame (no BasicFrameTemplate, build manually)
            WhatsTrainingFrame.wtbackgroundframe = CreateFrame("Frame", "wtbackgroundframe", WhatsTrainingFrame)
            WhatsTrainingFrame.wtbackgroundframe:SetWidth(335)
            WhatsTrainingFrame.wtbackgroundframe:SetHeight(430)
            WhatsTrainingFrame.wtbackgroundframe:SetPoint("TOPLEFT", WhatsTrainingFrame, "TOPLEFT", 15, -10)
            WhatsTrainingFrame.wtbackgroundframe:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 8, right = 8, top = 8, bottom = 8 }
            })

            local titleText = WhatsTrainingFrame.wtbackgroundframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titleText:SetPoint("TOP", WhatsTrainingFrame.wtbackgroundframe, "TOP", 0, -10)
            titleText:SetText("What's Training")
            WhatsTrainingFrame.wtbackgroundframe.TitleText = titleText

            WhatsTrainingFrame.wtbutton = CreateFrame("Button", nil, ModernSpellBookFrame)
            WhatsTrainingFrame.wtbutton:SetWidth(28)
            WhatsTrainingFrame.wtbutton:SetHeight(28)
            WhatsTrainingFrame.wtbutton:SetPoint("BOTTOMRIGHT", ModernSpellBookFrame, "BOTTOMRIGHT", 28, 20)
            WhatsTrainingFrame.wtbutton:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            WhatsTrainingFrame.wtbutton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            WhatsTrainingFrame.wtbutton:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Whats Training")
                GameTooltip:Show()

                this:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    this:SetScript("OnLeave", nil)
                end)
            end)

            local texture = WhatsTrainingFrame.wtbutton:CreateTexture(nil, "BACKGROUND")
            texture:SetTexture("Interface\\Spellbook\\Spellbook-SkillLineTab")
            texture:SetPoint("CENTER", WhatsTrainingFrame.wtbutton, "CENTER", 13, -4)
            texture:SetWidth(60)
            texture:SetHeight(60)

            WhatsTrainingFrame.wtbutton:SetScript("OnClick", function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                ToggleFrame(WhatsTrainingFrame)
                HideUIPanel(ModernSpellBookFrame)

                SpellBookCloseButton:ClearAllPoints()
                if WhatsTrainingFrame.wtbackgroundframe.CloseButton then
                    SpellBookCloseButton:SetPoint("CENTER", WhatsTrainingFrame.wtbackgroundframe.CloseButton, "CENTER", 0, 0)
                else
                    SpellBookCloseButton:SetPoint("TOPRIGHT", WhatsTrainingFrame.wtbackgroundframe, "TOPRIGHT", -5, -5)
                end

                SpellBookFrame:SetScript("OnShow", function()
                    ModernSpellBookFrame:Show()
                    WhatsTrainingFrame:Hide()

                    SpellBookCloseButton:ClearAllPoints()
                    SpellBookCloseButton:SetPoint("CENTER", ModernSpellBookFrame.CloseButton, "CENTER", 0, 0)
                    SpellBookFrame:SetScript("OnShow", nil)
                end)
            end)
        end
        if isMainFrameMinimized then
            WhatsTrainingFrame.wtbutton:Show()
        else
            WhatsTrainingFrame.wtbutton:Hide()
        end
    end

    if isMainFrameMinimized then
        maximumPages = 1
        ModernSpellBookFrame:SetWidth(windowSettings.width1)
        ModernSpellBookFrame:SetHeight(windowSettings.height)
        if SpellBookFrame.SetAttribute then
            SpellBookFrame:SetAttribute("UIPanelLayout-area", "doublewide")
            SpellBookFrame:SetAttribute("UIPanelLayout-width", ModernSpellBookFrame:GetWidth())
        end

        ModernSpellBookFrame:SetPoint("LEFT", UIParent, "LEFT", 15, windowSettings.posy)
        ModernSpellBookFrame.backgroundRight:Hide()
        ModernSpellBookFrame.backgroundRightEnd:Hide()
        ModernSpellBookFrame.searchBar:Hide()
        ModernSpellBookFrame.searchBar:SetText("")
        ModernSpellBookFrame.searchBar.Instructions:Show()
        ModernSpellBookFrame.searchBar:ClearFocus()
    else
        maximumPages = 2
        ModernSpellBookFrame:SetWidth(windowSettings.width2)
        ModernSpellBookFrame:SetHeight(windowSettings.height)
        if SpellBookFrame.SetAttribute then
            SpellBookFrame:SetAttribute("UIPanelLayout-area", "center")
            SpellBookFrame:SetAttribute("UIPanelLayout-width", ModernSpellBookFrame:GetWidth())
        end

        ModernSpellBookFrame:ClearAllPoints()
        ModernSpellBookFrame:SetPoint("CENTER", UIParent, "CENTER", 0, windowSettings.posy)

        ModernSpellBookFrame.backgroundRight:Show()
        ModernSpellBookFrame.backgroundRightEnd:Show()
        ModernSpellBookFrame.searchBar:Show()
    end

    if SpellBookSpellIconsFrame and SpellBookSpellIconsFrame:IsShown() then
        SpellBookSpellIconsFrame:ClearAllPoints()
        SpellBookSpellIconsFrame:SetPoint("CENTER", ModernSpellBookFrame, "CENTER", 0, 0)
        SpellBookSpellIconsFrame:Hide()
    end

    if ModernSpellBookFrame.isFirstLoad then return end

    -- A cheat to get UIPanelPush to work immediately.
    ToggleSpellBook(BOOKTYPE_SPELL)
    ToggleSpellBook(BOOKTYPE_SPELL)
end

function ModernSpellBookFrame:AddCancelButton()
    -- Repurpose close button.
    SpellBookCloseButton:ClearAllPoints()
    SpellBookCloseButton:SetPoint("CENTER", ModernSpellBookFrame.CloseButton, "CENTER", 0, 0)
    SpellBookCloseButton:SetFrameStrata("DIALOG")
    ModernSpellBookFrame.CloseButton:Disable()
    ModernSpellBookFrame.CloseButton:Hide()
end

function ModernSpellBookFrame:SetupInitiallyKnownSpells()
    ModernSpellBook_DB.knownSpells = {}

    ShowPassiveSpellsCheckBox:SetChecked(true)

    local allInitialSpells = {}

    table.insert(allInitialSpells, ModernSpellBookFrame:GetPlayerSpells(false))
    table.insert(allInitialSpells, ModernSpellBookFrame:GetPlayerSpells(true))
    table.insert(allInitialSpells, ModernSpellBookFrame:GetPetSpells())

    for i = 1, 3 do
        for cat, spellList in pairs(allInitialSpells[i]) do
            for _, spellInfo in ipairs(spellList) do
                local lookupString = spellInfo.spellName.. spellInfo.spellRank
                if ModernSpellBook_DB.knownSpells[lookupString] then
                    ModernSpellBook_DB.knownSpells[lookupString] = string.gsub(ModernSpellBook_DB.knownSpells[lookupString], NEW_KEYWORD, "")
                end
            end
        end
    end

    ShowPassiveSpellsCheckBox:SetChecked(ModernSpellBook_DB.showPassives)
end

function ModernSpellBookFrame:BuildSpellLookupTable(spellInfo)
    local lookupString = ""

    lookupString = lookupString.. ModernSpellBookFrame:CreateLookup(spellInfo.spellName)
    if spellInfo.spellRank ~= "" then
        lookupString = lookupString.. ModernSpellBookFrame:CreateLookup(spellInfo.spellRank)
    end
    lookupString = lookupString.. ModernSpellBookFrame:CreateLookup(spellInfo.category)
    if spellInfo.isTalent or spellInfo.isTalentAbility then
        lookupString = lookupString.. ModernSpellBookFrame:CreateLookup(TALENT)
    else
        local spellDescription = GetSpellDescription(spellInfo.spellID)
        if spellDescription ~= nil then
            lookupString = lookupString.. ModernSpellBookFrame:CreateLookup(spellDescription)
        end
    end

    return string.lower(lookupString)
end

function ModernSpellBookFrame:CreateLookup(lookupWord)
    return lookupWord.. ";"
end

-- Filter spell list to only keep highest rank of each spell
function ModernSpellBookFrame:FilterHighestRanks(spellList)
    -- Parse rank number from rank string (e.g., "Rank 5" -> 5)
    local function getRankNum(rankStr)
        if not rankStr or rankStr == "" then return 0 end
        local _, _, num = string.find(rankStr, "(%d+)")
        return tonumber(num) or 0
    end

    -- First pass: find highest rank for each spell name
    local highestRank = {}
    for _, spellInfo in ipairs(spellList) do
        local name = spellInfo.spellName
        local rankNum = getRankNum(spellInfo.spellRank)
        if not highestRank[name] or rankNum > highestRank[name] then
            highestRank[name] = rankNum
        end
    end

    -- Second pass: keep only highest rank entries
    local filtered = {}
    for _, spellInfo in ipairs(spellList) do
        local rankNum = getRankNum(spellInfo.spellRank)
        if rankNum >= highestRank[spellInfo.spellName] then
            table.insert(filtered, spellInfo)
        end
    end
    return filtered
end

function ModernSpellBookFrame:CalculateSpellPositions(AllSpells, isPetTab)
    local pageCollection = {}
    local spellPage = {}
    local currentPageRows = -1.25
    local totalSpells = 0; local totalCategories = 0
    local maxPagesPerView = ModernSpellBook_DB.isMinimized and 1 or 2
    local drawingPageNumber = 1

    local allSpellCategories = {}
    for category, _ in pairs(AllSpells) do
        table.insert(allSpellCategories, category)
    end
    table.sort(allSpellCategories, function(a, b)
        return a < b
    end)
    for _, category in ipairs(allSpellCategories) do
        if AllSpells[category] ~= nil and table.getn(AllSpells[category]) > 0 then
            spells = AllSpells[category]
            if currentPageRows +(table.getn(spells) < 3 and 2 or 3) > 7.5 then
                currentPageRows = -1.25
                drawingPageNumber = math.mod(drawingPageNumber, maxPagesPerView) +1
                if drawingPageNumber == 1 then
                    table.insert(pageCollection, spellPage)
                    spellPage = {}
                end
            end
            currentPageRows = currentPageRows +1.5
            totalCategories = totalCategories +1

            table.insert(spellPage, {isCategory = true, category = category, currentPageRows = currentPageRows, drawingPageNumber = drawingPageNumber})

            local grid_x = -1
            local totalSpellsInCategory = table.getn(spells)
            for i, spellInfo in ipairs(spells) do
                totalSpells = totalSpells +1

                grid_x = math.mod(grid_x + 1, 3)
                if grid_x == 0 then
                    local isSpecialLeftPageCase = i +2 > totalSpellsInCategory and drawingPageNumber == 1
                    local maxRowLength = isSpecialLeftPageCase and 8.5 or 7.75
                    if currentPageRows +1 > maxRowLength then
                        if isSpecialLeftPageCase then
                            currentPageRows = currentPageRows -0.5
                            for j = table.getn(spellPage), 1, -1 do
                                spellPage[j].currentPageRows = spellPage[j].currentPageRows -0.5
                                if spellPage[j].isCategory then
                                    break
                                end
                            end
                        else
                            currentPageRows = 0
                            drawingPageNumber = math.mod(drawingPageNumber, maxPagesPerView) +1
                            if drawingPageNumber == 1 then
                                table.insert(pageCollection, spellPage)
                                spellPage = {}
                            end
                        end
                    end
                    currentPageRows = currentPageRows +1
                end

                table.insert(spellPage, {isCategory = false, spellInfo = spellInfo, currentPageRows = currentPageRows, drawingPageNumber = drawingPageNumber})
            end
        end
    end

    table.insert(pageCollection, spellPage)

    return pageCollection
end

function ModernSpellBookFrame:FilterSpells(filterString)
    local keywords = {}

    if not filterString then filterString = "" end
    filterString = string.lower(string.gsub(string.gsub(filterString, "%%", ""), "^", ""))
    for keyword in string.gmatch(filterString, "([^,; ]+)") do
        table.insert(keywords, keyword)
    end

    if table.getn(keywords) == 0 then return ModernSpellBookFrame.AllSpells end

    local filteredSpells = {}
    for category, spellList in pairs(ModernSpellBookFrame.AllSpells) do
        for _, spellInfo in ipairs(spellList) do
            local lookupString = spellInfo.spellName.. spellInfo.spellRank
            local isMatch = true
            for _, keyword in ipairs(keywords) do
                local knownSpell = ModernSpellBook_DB.knownSpells[lookupString]
                if (knownSpell ~= nil and not string.find(knownSpell, keyword)) then
                    isMatch = false
                    break
                end
            end

            if isMatch then
                if filteredSpells[category] == nil then
                    filteredSpells[category] = {}
                end
                table.insert(filteredSpells[category], spellInfo)
            end
        end
    end

    return filteredSpells
end

function ModernSpellBookFrame:RefreshPage()
    if InCombatLockdown() then return end

    local filterString = ModernSpellBookFrame.searchBar:GetText() or ""
    local filteredSpells = ModernSpellBookFrame:FilterSpells(filterString)

    if next(filteredSpells) == nil then
        ModernSpellBookFrame.noresultsText:Show()
        ModernSpellBookFrame:CleanPages()
        return
    end

    ModernSpellBookFrame.noresultsText:Hide()
    ModernSpellBookFrame.pageCollection = ModernSpellBookFrame:CalculateSpellPositions(filteredSpells, ModernSpellBookFrame.isPetTab)
    ModernSpellBookFrame:RefreshPageElements()
end

function ModernSpellBookFrame:DrawPage()
    if InCombatLockdown() then return end

    spellUpdateRequired = false
    ModernSpellBookFrame.stanceButtons = {}

    local AllSpells, isPetTab = ModernSpellBookFrame:GetAvailableSpells()
    ModernSpellBookFrame.AllSpells = AllSpells
    ModernSpellBookFrame.isPetTab = isPetTab

    if ModernSpellBookFrame.isPetTab then
        local totalSpells = 0
        for cat, spellList in pairs(AllSpells) do
            totalSpells = totalSpells + table.getn(spellList)
        end

        if totalSpells == 0 then
            ModernSpellBookFrame:CleanPages()
            ModernSpellBookFrame.noresultsText:SetText(ModernSpellBookFrame.ClientLocale.NoPetSpells)
            ModernSpellBookFrame.noresultsText:Show()
            return
        else
            ModernSpellBookFrame.noresultsText:Hide()
        end
    end

    ModernSpellBookFrame:RefreshPage()
end

function ModernSpellBookFrame:RefreshPageElements()
    ModernSpellBookFrame:CleanPages()

    local pageCollection = ModernSpellBookFrame.pageCollection
    ModernSpellBookFrame.currentPage = math.min(ModernSpellBookFrame.currentPage, table.getn(pageCollection))
    local currentPage = ModernSpellBookFrame.currentPage
    ModernSpellBookFrame.maxPages = math.max(1, table.getn(pageCollection))

    if ModernSpellBookFrame.maxPages > 1 then
        ModernSpellBookFrame.pageText:SetText(string.format(PRODUCT_CHOICE_PAGE_NUMBER, currentPage, ModernSpellBookFrame.maxPages))
        ModernSpellBookFrame.pageText:Show()
        ModernSpellBookFrame.nextPage:Show()
        ModernSpellBookFrame.previousPage:Show()
    else
        ModernSpellBookFrame.pageText:Hide()
        ModernSpellBookFrame.nextPage:Hide()
        ModernSpellBookFrame.previousPage:Hide()
    end
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

    local totalCategories = 0
    local totalSpells = 0
    local grid_x = -1

    if pageCollection[currentPage] == nil then return end
    for i, element in ipairs(pageCollection[currentPage]) do
        if element.isCategory then
            grid_x = -1
            totalCategories = totalCategories +1
            ModernSpellBookFrame:GetOrCreateCategory(totalCategories):Set(element.category, element.currentPageRows, element.drawingPageNumber)
        else
            grid_x = math.mod(grid_x + 1, 3)
            totalSpells = totalSpells +1
            ModernSpellBookFrame:GetOrCreateSpellFrame(totalSpells):Set(element.spellInfo, element.currentPageRows, element.drawingPageNumber, grid_x)
        end
    end
end

function ModernSpellBookFrame:GetPetSpells()
    local petName = UnitName("pet")
    if not petName then return {} end

    -- First we iterate through the pet spells from the action bar
    local actionBarSpells = {}
    for i = 1, NUM_PET_ACTION_SLOTS do
        local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i);
        if name == nil then name = -1 end
        actionBarSpells[name] = i
    end

    local passiveSpells = {}

    local petSpells = {}
    petSpells[petName] = {}
    for i = 1, NUM_PET_ACTION_SLOTS do
        local spellName, spellSubName = GetSpellBookItemName(i, BOOKTYPE_PET)
        if not spellName then break end

        local spellIcon = GetSpellBookItemTexture(i, BOOKTYPE_PET)
        local spellInfo = {
            spellName = spellName,
            spellIcon = spellIcon,
            spellRank = spellSubName or "",
            spellID = i,
            bookType = BOOKTYPE_PET,
            isPassive = IsPassiveSpell(i, BOOKTYPE_PET),
            isTalent = false,
            isPetSpell = true,
            castName = actionBarSpells[spellName],
            category = petName
        }

        local lookupString = spellInfo.spellName.. spellInfo.spellRank
        if ModernSpellBook_DB.knownSpells[lookupString] == nil then
            ModernSpellBook_DB.knownSpells[lookupString] = ModernSpellBookFrame:BuildSpellLookupTable(spellInfo).. string.lower(ModernSpellBookFrame:CreateLookup(NEW))
        end

        if not spellInfo.isPassive then
            table.insert(petSpells[petName], spellInfo)
        else
            table.insert(passiveSpells, spellInfo)
        end
    end

    local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()
    if canShowPassives then
        for _, spellInfo in ipairs(passiveSpells) do
            table.insert(petSpells[petName], spellInfo)
        end
    end

    return petSpells
end

function ModernSpellBookFrame:GetAvailableSpells()
    if ModernSpellBookFrame.selectedTab == 1 then
        return ModernSpellBookFrame:GetPlayerSpells(false), false
    elseif ModernSpellBookFrame.selectedTab == 2 then
        return ModernSpellBookFrame:GetPlayerSpells(true), false
    elseif ModernSpellBookFrame.selectedTab == 3 then
        return ModernSpellBookFrame:GetPetSpells(), true
    else
        -- Turtle WoW custom tabs (Companions, Mounts, Toys)
        local tabInfo = ModernSpellBookFrame.customTabs and ModernSpellBookFrame.customTabs[ModernSpellBookFrame.selectedTab]
        if tabInfo then
            return ModernSpellBookFrame:GetCustomTabSpells(tabInfo.spellTabName), false
        end
        return {}, false
    end
end

-- Get spells from a specific named spellbook tab (for Turtle WoW custom tabs)
function ModernSpellBookFrame:GetCustomTabSpells(targetTabName)
    local spellsDict = {}
    local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()
    local activeSpells = {}
    local passiveSpells = {}

    local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
    for i = 1, numTabs do
        local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
        if not tabName then break end

        if tabName == targetTabName then
            for s = offset + 1, offset + numSpells do
                local spellInfo = ModernSpellBookFrame:SpellInfoFromSpellBookItem(tabName, s)

                local lookupString = spellInfo.spellName.. spellInfo.spellRank
                if ModernSpellBook_DB.knownSpells[lookupString] == nil then
                    ModernSpellBook_DB.knownSpells[lookupString] = ModernSpellBookFrame:BuildSpellLookupTable(spellInfo).. string.lower(ModernSpellBookFrame:CreateLookup(NEW))
                end

                if spellInfo.isPassive then
                    table.insert(passiveSpells, spellInfo)
                else
                    table.insert(activeSpells, spellInfo)
                end
            end
            break
        end
    end

    spellsDict[targetTabName] = activeSpells
    if canShowPassives then
        for _, spellInfo in ipairs(passiveSpells) do
            table.insert(spellsDict[targetTabName], spellInfo)
        end
    end

    return spellsDict
end

function ModernSpellBookFrame:SpellInfoFromSpellBookItem(tabName, s)
    local spellNameFromBook, spellRank = GetSpellBookItemName(s, BOOKTYPE_SPELL)
    local spellIcon = GetSpellBookItemTexture(s, BOOKTYPE_SPELL)

    -- In vanilla, use the spellbook slot index as the spellID
    local spellID = s
    local castName = spellNameFromBook

    -- Create the base spellInfo object.
    local spellInfo = {
        spellName = spellNameFromBook, spellIcon = spellIcon,
        spellID = spellID, castName = castName, category = tabName,
        bookType = BOOKTYPE_SPELL
    }

    if ModernSpellBookFrame.unlockedStances[spellNameFromBook] then
        spellInfo.stanceIndex = ModernSpellBookFrame.unlockedStances[spellNameFromBook]
    end

    -- Supplement with rank info
    local isPassive = IsPassiveSpell(s, BOOKTYPE_SPELL)
    if isPassive then
        spellRank = (spellRank and spellRank ~= "") and spellRank or PET_PASSIVE
    end

    spellInfo.castName = (spellRank and spellRank ~= "") and (spellNameFromBook.. "(".. spellRank.. ")") or spellNameFromBook
    spellInfo.spellRank = spellRank or ""
    spellInfo.isPassive = isPassive

    return spellInfo
end

function ModernSpellBookFrame:GetPlayerSpells(showGeneralTab)
    local allSpellsDict = {}
    local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()
    local passiveSpellsDict = {}

    -- Look through all the stances using vanilla GetShapeshiftFormInfo
    ModernSpellBookFrame.unlockedStances = {}
    local stanceBar = StanceBarFrame or StanceBar
    local NStances = (stanceBar and stanceBar.numForms) and stanceBar.numForms or 10
    for stanceIndex = 1, NStances do
        local texture, name, isActive, isCastable = GetShapeshiftFormInfo(stanceIndex)
        if not texture then break end
        -- In vanilla, we map by name since there's no spellID from GetShapeshiftFormInfo
        if name then
            ModernSpellBookFrame.unlockedStances[name] = stanceIndex
        end
    end

    -- Turtle WoW custom tabs to skip (Companions, Toys, etc.)
    local skipTabs = {}
    if COMPANIONS then skipTabs[COMPANIONS] = true end
    skipTabs["Companions"] = true
    skipTabs["Toys"] = true
    skipTabs["Mounts"] = true

    local numTabs = GetNumSpellTabs and GetNumSpellTabs() or MAX_SKILLLINE_TABS or 4
    for i = 1, numTabs do
        local tabName, texture, offset, numSpells = GetSpellTabInfo(i);
        if not tabName then break end

        -- Skip Turtle WoW custom tabs
        if skipTabs[tabName] then
            -- do nothing, skip this tab
        elseif showGeneralTab == (tabName == GENERAL) then
            allSpellsDict[tabName] = {}
            passiveSpellsDict[tabName] = {}

            for s = offset + 1, offset + numSpells do
                if not IsSpellHidden(s, BOOKTYPE_SPELL) then
                    local spellInfo = ModernSpellBookFrame:SpellInfoFromSpellBookItem(tabName, s)

                    local lookupString = spellInfo.spellName.. spellInfo.spellRank
                    if ModernSpellBook_DB.knownSpells[lookupString] == nil then
                        ModernSpellBook_DB.knownSpells[lookupString] = ModernSpellBookFrame:BuildSpellLookupTable(spellInfo).. string.lower(ModernSpellBookFrame:CreateLookup(NEW))
                    end

                    if spellInfo.isPassive then
                        table.insert(passiveSpellsDict[tabName], spellInfo)
                    else
                        table.insert(allSpellsDict[tabName], spellInfo)
                    end
                end
            end
        end
    end

    if showGeneralTab then
        if canShowPassives then
            for tabName, passiveSpells in pairs(passiveSpellsDict) do
                for i = 1, table.getn(passiveSpells) do
                    table.insert(allSpellsDict[tabName], passiveSpells[i])
                end
            end
        end
        -- Filter to highest ranks only if checkbox is unchecked
        if not ShowAllSpellRanksCheckbox or not ShowAllSpellRanksCheckbox:GetChecked() then
            for tabName, spells in pairs(allSpellsDict) do
                allSpellsDict[tabName] = ModernSpellBookFrame:FilterHighestRanks(spells)
            end
        end
        return allSpellsDict
    end

    -- We merge the talents with the spells
    local talentGridPositions = ModernSpellBookFrame:GetAllTalents(true)
    for talentGroupName, talents in pairs(talentGridPositions) do
        if allSpellsDict[talentGroupName] == nil then
            for knownGroups, _ in pairs(allSpellsDict) do
                if string.find(string.lower(knownGroups), string.lower(string.sub(talentGroupName, 1, 4))) then
                    talentGroupName = knownGroups
                    for _, spellInfo in ipairs(talents) do
                        spellInfo.category = talentGroupName
                    end
                    break
                end
                allSpellsDict[talentGroupName] = {}
            end
        end
        if passiveSpellsDict[talentGroupName] == nil then
            passiveSpellsDict[talentGroupName] = {}
        end
        for i = 1, table.getn(talents) do
            table.insert(passiveSpellsDict[talentGroupName], talents[i])
        end
    end

    for tabName, passiveSpells in pairs(passiveSpellsDict) do
        local namesDict = {}
        if allSpellsDict[tabName] then
            for listIndex, spellinfo in ipairs(allSpellsDict[tabName]) do
                if namesDict[spellinfo.spellName] == nil then
                    namesDict[spellinfo.spellName] = {}
                end
                table.insert(namesDict[spellinfo.spellName], listIndex)
            end
        end

        if canShowPassives then
            table.sort(passiveSpells, function(a, b) return a.spellName < b.spellName end)
        end

        for i = 1, table.getn(passiveSpells) do
            local isActiveTalent = namesDict[passiveSpells[i].spellName]
            if isActiveTalent and allSpellsDict[tabName] then
                for _, alreadyActiveSpellListIndex in ipairs(isActiveTalent) do
                    local spellInfo = allSpellsDict[tabName][alreadyActiveSpellListIndex]
                    ModernSpellBookFrame:MarkSpellAsTalent(spellInfo)
                end
            elseif canShowPassives then
                if not allSpellsDict[tabName] then
                    allSpellsDict[tabName] = {}
                end
                table.insert(allSpellsDict[tabName], passiveSpells[i])
            end
        end
    end

    -- Filter to highest ranks only if checkbox is unchecked
    if not ShowAllSpellRanksCheckbox or not ShowAllSpellRanksCheckbox:GetChecked() then
        for tabName, spells in pairs(allSpellsDict) do
            allSpellsDict[tabName] = ModernSpellBookFrame:FilterHighestRanks(spells)
        end
    end

    return allSpellsDict
end


-- Create Turtle WoW custom tabs if they exist and haven't been created yet
function ModernSpellBookFrame:CreateCustomTabs()
    if not ModernSpellBookFrame.customTabs then
        ModernSpellBookFrame.customTabs = {}
    end

    local customTabDefs = {"Companions", "Mounts", "Toys"}
    local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4

    for _, customName in ipairs(customTabDefs) do
        -- Check if we already created this tab
        local alreadyExists = false
        for _, info in pairs(ModernSpellBookFrame.customTabs) do
            if info.spellTabName == customName then
                alreadyExists = true
                break
            end
        end

        if not alreadyExists then
            for i = 1, numTabs do
                local tabName = GetSpellTabInfo(i)
                if tabName == customName then
                    local tabIndex = table.getn(ModernSpellBookFrame.Tabgroups) + 1
                    ModernSpellBookFrame:NewTab(customName)
                    ModernSpellBookFrame.customTabs[tabIndex] = { spellTabName = customName }
                    ModernSpellBookFrame:PositionAllTabs()
                    break
                end
            end
        end
    end
end

-- Event dispatch for vanilla calling convention
function ModernSpellBookFrame.OnEvent()
    local eventName = event
    if ModernSpellBookFrame[eventName] then
        ModernSpellBookFrame[eventName](ModernSpellBookFrame, eventName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end
end

ModernSpellBookFrame:RegisterEvent("ADDON_LOADED")
ModernSpellBookFrame:RegisterEvent("SPELLS_CHANGED")
ModernSpellBookFrame:SetScript("OnEvent", ModernSpellBookFrame.OnEvent)

ModernSpellBookFrame:SetScript("OnHide", function()
    ModernSpellBookFrame:HideAllMultiActionBarGrids()
end)

ModernSpellBookFrame:SetScript("OnShow", function()
    PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)

    ModernSpellBookFrame:ShowAllMultiActionBarGrids()

    if ModernSpellBookFrame.isFirstLoad then
        ModernSpellBookFrame:AddAllRanksCheckBox()
        local className = UnitClass("player")

        local wasSearchBarShown = ModernSpellBookFrame.searchBar:IsShown()
        ModernSpellBookFrame.searchBar:Hide()
        ModernSpellBookFrame.searchBar:SetPoint("RIGHT", ModernSpellBookFrame:GetRightmostLeftButton(), "LEFT", -10, 1)
        if wasSearchBarShown then ModernSpellBookFrame.searchBar:Show() end

        ModernSpellBookFrame.selectedTab = 1
        ModernSpellBookFrame.tab1 = ModernSpellBookFrame:NewTab(className)
        ModernSpellBookFrame.tab2 = ModernSpellBookFrame:NewTab(GENERAL)
        ModernSpellBookFrame.tab3 = ModernSpellBookFrame:NewTab("Pet")

        ModernSpellBookFrame.customTabs = {}

        ModernSpellBookFrame.tab3:UpdateAsPetTab()
        ModernSpellBookFrame:SetShape(ModernSpellBook_DB.isMinimized)
        ModernSpellBookFrame:PositionAllTabs()

        if next(ModernSpellBook_DB.knownSpells) == nil then
            ModernSpellBookFrame:SetupInitiallyKnownSpells()
        end
    else
        ModernSpellBookFrame.tab3:UpdateAsPetTab()
    end

    -- Lazily create Turtle WoW custom tabs (Companions, Mounts, Toys)
    -- These may not be available during initial ForceLoad
    ModernSpellBookFrame:CreateCustomTabs()

    -- Always hide old spellbook elements when showing our frame
    -- (vanilla SpellBookFrame_OnShow re-shows its children each time)
    ModernSpellBookFrame:HideOldSpellBook()

    if spellUpdateRequired then
        ModernSpellBookFrame:DrawPage()
    end

    if not ModernSpellBookFrame.isFirstLoad then return end
    ModernSpellBookFrame.isFirstLoad = false

    if ShowAllSpellRanksCheckbox and ShowAllSpellRanksCheckbox.HookScript then
        HookScript(ShowAllSpellRanksCheckbox, "OnClick", function()
            ModernSpellBookFrame:DrawPage()
        end)
    end
end)

ModernSpellBookFrame.SPELLS_CHANGED = function(self, event, ...)
    if ModernSpellBookFrame.isFirstLoad then return end

    if ModernSpellBookFrame:IsVisible() then
        ModernSpellBookFrame:HideOldSpellBook()
        C_Timer.After(0.3, function()
            ModernSpellBookFrame.tab3:UpdateAsPetTab()
            ModernSpellBookFrame:DrawPage()
        end)
    else
        spellUpdateRequired = true
    end
end

function ModernSpellBookFrame:HideOldSpellBook()
    -- Hide all regions (background textures etc.)
    for i, region in ipairs( { SpellBookFrame:GetRegions() } ) do
        region:Hide()
    end
    -- Hide all children except our frame and close button
    for i, child in ipairs({SpellBookFrame:GetChildren()}) do
        local childName = child:GetName()
        if childName ~= "ModernSpellBookFrame" and childName ~= "SpellBookCloseButton" then
            child:Hide()
        end
    end
    -- Explicitly hide known vanilla SpellBook elements
    local vanillaElements = {
        "SpellBookTitleText", "SpellBookNameText", "SpellBookPageText",
        "SpellBookPrevPageButton", "SpellBookNextPageButton",
        "SpellBookPageNavigationFrame", "SpellBookSkillLineTab1",
        "SpellBookSkillLineTab2", "SpellBookSkillLineTab3", "SpellBookSkillLineTab4",
        "SpellBookSkillLineTab5", "SpellBookSkillLineTab6", "SpellBookSkillLineTab7",
        "SpellBookSkillLineTab8",
        "SpellBookTabFlashFrame", "SpellBookSpellIconsFrame",
        "SpellBookCompanionsFrame", "SpellBookCompanionModelFrame",
    }
    for _, name in ipairs(vanillaElements) do
        local frame = _G[name]
        if frame and frame.Hide then frame:Hide() end
    end
    -- Hide spell buttons (SpellButton1 through SpellButton12+)
    for i = 1, 20 do
        local btn = _G["SpellButton" .. i]
        if btn then btn:Hide() end
    end
end

-- Hook SpellBookFrame to show ModernSpellBookFrame when the spellbook opens.
-- In vanilla, XML OnShow handlers and SetScript handlers are separate,
-- so we hook the global SpellBookFrame_OnShow function instead.
if SpellBookFrame_OnShow then
    local orig_SpellBookFrame_OnShow = SpellBookFrame_OnShow
    SpellBookFrame_OnShow = function()
        orig_SpellBookFrame_OnShow()
        if InCombatLockdown() then return end
        ModernSpellBookFrame:HideOldSpellBook()
        ModernSpellBookFrame:Show()
        SpellBookFrame:EnableMouse(false)
    end
elseif ToggleSpellBook then
    -- Fallback: hook ToggleSpellBook
    local orig_ToggleSpellBook = ToggleSpellBook
    ToggleSpellBook = function(bookType)
        orig_ToggleSpellBook(bookType)
        if SpellBookFrame:IsVisible() then
            if InCombatLockdown() then return end
            ModernSpellBookFrame:HideOldSpellBook()
            ModernSpellBookFrame:Show()
            SpellBookFrame:EnableMouse(false)
        end
    end
else
    -- Last resort: use SetScript
    local origOnShow = SpellBookFrame:GetScript("OnShow")
    SpellBookFrame:SetScript("OnShow", function()
        if origOnShow then origOnShow() end
        if InCombatLockdown() then return end
        ModernSpellBookFrame:HideOldSpellBook()
        ModernSpellBookFrame:Show()
        SpellBookFrame:EnableMouse(false)
    end)
end

-- Allow crafting frames to work while on wide mode.
ModernSpellBookFrame:RegisterEvent("TRADE_SKILL_SHOW")
ModernSpellBookFrame.TRADE_SKILL_SHOW = function(self, event, ...)
    if ModernSpellBook_DB.isMinimized then return end
    HideUIPanel(SpellBookFrame)
    if TradeSkillFrame then ShowUIPanel(TradeSkillFrame) end
end

ModernSpellBookFrame:RegisterEvent("CRAFT_SHOW")
ModernSpellBookFrame.CRAFT_SHOW = function(self, event, ...)
    if ModernSpellBook_DB.isMinimized then return end
    HideUIPanel(SpellBookFrame)
    if CraftFrame then ShowUIPanel(CraftFrame) end
end
