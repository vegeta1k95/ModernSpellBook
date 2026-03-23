local classColors = {{0.87,0.38,0.21}, {0.96,0.55,0.73}, {0.67,0.83,0.45}, {1.00,0.96,0.41}, {1, 1, 1}, {0.77,0.12,0.23}, {0.00,0.44,0.87}, {0.25,0.78,0.92}, {0.53,0.53,0.93}, {0.00,1.00,0.60}, {1.00,0.49,0.04}, {0.64,0.19,0.79}, {0.20,0.58,0.50}}

local maximumPages = 2
local spellUpdateRequired = true
-- NEW_KEYWORD defined in MSB_SpellData.lua as MSB_NEW_KEYWORD
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
    if ModernSpellBook_DB.showSpellCounter == nil then
        ModernSpellBook_DB.showSpellCounter = true
    end
    if ModernSpellBook_DB.rememberPage == nil then
        ModernSpellBook_DB.rememberPage = true
    end
    if ModernSpellBook_DB.showUnlearned == nil then
        ModernSpellBook_DB.showUnlearned = true
    end
    if not ModernSpellBook_DB.fontSize then
        ModernSpellBook_DB.fontSize = 11.5
    end
    if not ModernSpellBook_DB.highlights then
        ModernSpellBook_DB.highlights = { learnedGlow = true, learnedBadge = true, availableGlow = true, availableBadge = true }
    end
    ModernSpellBookFrame:AlterOlderSavedVariables()

    ModernSpellBookFrame.ClientLocale = ModernSpellBookFrame.Locales[GetLocale()] or ModernSpellBookFrame.Locales["enUS"]
    ModernSpellBookFrame.currentPage = ModernSpellBook_DB.rememberPage and ModernSpellBook_DB.lastPage or 1
    ModernSpellBookFrame.maxPages = 1
    ModernSpellBookFrame.stanceButtons = {}
    ModernSpellBookFrame.unlockedStances = {}
    ModernSpellBookFrame.isFirstLoad = true

    ModernSpellBookFrame:SetupFrame()
    ModernSpellBookFrame:AddPassiveCheckBox()
    ModernSpellBookFrame:AddSearchBar()

    ModernSpellBookFrame:AddPageButtons()
    ModernSpellBookFrame:AddCancelButton()
    ModernSpellBookFrame:AddSettingsButton()

    ModernSpellBookFrame:SetShape(ModernSpellBook_DB.isMinimized)

    -- If the user first opens the spellbook in combat, nothing will show. So we force load the spellbook when they join the game.
    ModernSpellBookFrame:ForceLoad()

    ModernSpellBookFrame:UnregisterEvent("ADDON_LOADED")
end

function ModernSpellBookFrame:ForceLoad()
    ModernSpellBookFrame.isForceLoading = true
    ToggleSpellBook(BOOKTYPE_SPELL)
    ToggleSpellBook(BOOKTYPE_SPELL)
    C_Timer.After(0.5, function()
        if SpellBookFrame:IsShown() then
            ToggleSpellBook(BOOKTYPE_SPELL)
        end
        ModernSpellBookFrame.isForceLoading = false
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
    ModernSpellBookFrame.searchBar = CSearchBar(
        ModernSpellBookFrame,
        ModernSpellBookFrame.ClientLocale.SearchAbilities,
        function() ModernSpellBookFrame:RefreshPage() end
    )
end

function ModernSpellBookFrame:SetupFrame()
    local classID = MSB_GetClassIndex()
    ModernSpellBookFrame:EnableMouse(true)
    ModernSpellBookFrame:SetMovable(true)
    ModernSpellBookFrame:RegisterForDrag("LeftButton")
    ModernSpellBookFrame:SetScript("OnDragStart", function ()
        this:StartMoving()
    end)
    ModernSpellBookFrame:SetScript("OnDragStop", function() 
        this:StopMovingOrSizing()
    end)
    ModernSpellBookFrame:SetWidth(windowSettings.width2)
    ModernSpellBookFrame:SetHeight(windowSettings.height)
    ModernSpellBookFrame:SetPoint("CENTER", UIParent, "CENTER", 0, windowSettings.posy)
    ModernSpellBookFrame:SetFrameStrata("HIGH")
    HideUIPanel(ModernSpellBookFrame)

    ModernSpellBookFrame.title = ModernSpellBookFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.title:SetPoint("TOP", ModernSpellBookFrame, "TOP", 0, -24)
    ModernSpellBookFrame.title:SetText(SPELLBOOK)

    -- Portrait frame: black fill + book icon + border
    ModernSpellBookFrame.portraitBg = ModernSpellBookFrame:CreateTexture(nil, "ARTWORK")
    ModernSpellBookFrame.portraitBg:SetWidth(44)
    ModernSpellBookFrame.portraitBg:SetHeight(44)
    ModernSpellBookFrame.portraitBg:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", -10, 10)
    ModernSpellBookFrame.portraitBg:SetTexture(0, 0, 0, 1)

    ModernSpellBookFrame.book = ModernSpellBookFrame:CreateTexture(nil, "OVERLAY")
    ModernSpellBookFrame.book:SetWidth(40)
    ModernSpellBookFrame.book:SetHeight(40)
    ModernSpellBookFrame.book:SetPoint("CENTER", ModernSpellBookFrame.portraitBg, "CENTER", 0, 0)
    ModernSpellBookFrame.book:SetTexture("Interface\\Spellbook\\Spellbook-Icon")
    ModernSpellBookFrame.book:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    ModernSpellBookFrame.portraitBorderFrame = CreateFrame("Frame", nil, ModernSpellBookFrame)
    ModernSpellBookFrame.portraitBorderFrame:SetWidth(76)
    ModernSpellBookFrame.portraitBorderFrame:SetHeight(76)
    ModernSpellBookFrame.portraitBorderFrame:SetPoint("CENTER", ModernSpellBookFrame.portraitBg, "CENTER", 0, 0)
    ModernSpellBookFrame.portraitBorderFrame:SetFrameLevel(ModernSpellBookFrame:GetFrameLevel() + 5)
    ModernSpellBookFrame.portraitBorder = ModernSpellBookFrame.portraitBorderFrame:CreateTexture(nil, "OVERLAY")
    ModernSpellBookFrame.portraitBorder:SetAllPoints(ModernSpellBookFrame.portraitBorderFrame)
    ModernSpellBookFrame.portraitBorder:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")

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

    ModernSpellBookFrame.noresultsText = ModernSpellBookFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.noresultsText:SetPoint("CENTER", ModernSpellBookFrame.backgroundLeft, "CENTER", 0, 0)
    ModernSpellBookFrame.noresultsText:SetText(ModernSpellBookFrame.ClientLocale.NoResults.. NEW.. ", ".. TALENT.. "'")
    ModernSpellBookFrame.noresultsText:SetTextColor(0, 0, 0)
    ModernSpellBookFrame.noresultsText:SetShadowOffset(0, 0)
    ModernSpellBookFrame.noresultsText:Hide()

    -- Trainer hint - subtle bottom text
    ModernSpellBookFrame.trainerHint = ModernSpellBookFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.trainerHint:SetPoint("BOTTOM", ModernSpellBookFrame, "BOTTOM", 0, 15)
    ModernSpellBookFrame.trainerHint:SetText("Visit a class trainer in a major city to fetch the FULL list of available spells.")
    ModernSpellBookFrame.trainerHint:SetFont("Fonts\\FRIZQT__.TTF", 10)
    ModernSpellBookFrame.trainerHint:SetTextColor(0.6, 0.6, 0.6)
    ModernSpellBookFrame.trainerHint:Hide()

    -- Spell counter
    ModernSpellBookFrame.spellCounter = ModernSpellBookFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ModernSpellBookFrame.spellCounter:SetPoint("BOTTOMLEFT", ModernSpellBookFrame, "BOTTOMLEFT", 30, 25)
    ModernSpellBookFrame.spellCounter:SetFont("Fonts\\FRIZQT__.TTF", 10)
    ModernSpellBookFrame.spellCounter:SetTextColor(1, 1, 1)

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
    ShowAllSpellRanksCheckbox:SetChecked(ModernSpellBook_DB.showAllRanks or false)

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
        ModernSpellBook_DB.showAllRanks = this:GetChecked()
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
        ModernSpellBook_DB.lastPage = ModernSpellBookFrame.currentPage
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
        ModernSpellBook_DB.lastPage = ModernSpellBookFrame.currentPage
        ModernSpellBookFrame:RefreshPageElements()
    end)

    local scrollDebounceTimer = 0
    ModernSpellBookFrame:EnableMouseWheel(true)
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

-- Minimize removed


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
        ModernSpellBookFrame.searchBar:Clear()
        ModernSpellBookFrame.searchBar:Hide()
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




function ModernSpellBookFrame:CalculateSpellPositions(AllSpells, isPetTab)
    local pageCollection = {}
    local spellPage = {}
    local currentPageRows = -2
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
            if currentPageRows +(table.getn(spells) < 3 and 3 or 4) > 7.5 then
                currentPageRows = -2
                drawingPageNumber = math.mod(drawingPageNumber, maxPagesPerView) +1
                if drawingPageNumber == 1 then
                    table.insert(pageCollection, spellPage)
                    spellPage = {}
                end
            end
            currentPageRows = currentPageRows +2
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


function ModernSpellBookFrame:RefreshPage()
    if InCombatLockdown() then return end

    local filterString = ModernSpellBookFrame.searchBar:GetText() or ""
    local filteredSpells = SpellDataService:FilterSpells(filterString)

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

    local AllSpells, isPetTab = SpellDataService:GetAvailableSpells()
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
    SpellDataService:UpdateSpellCounter()
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
            ModernSpellBookFrame:GetOrCreateSpellItem(totalSpells):Set(element.spellInfo, element.currentPageRows, element.drawingPageNumber, grid_x)
        end
    end
end



-- Get spells from a specific named spellbook tab (for Turtle WoW custom tabs)




-- Merge unlearned spells from trainer data into the spell dict

-- Detect profession spells by rank string or known spell names


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
    ActionBarHelper:HideAllGrids()
end)

ModernSpellBookFrame:SetScript("OnShow", function()
    PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)

    ActionBarHelper:ShowAllGrids()

    if ModernSpellBookFrame.isFirstLoad then
        ModernSpellBookFrame:AddAllRanksCheckBox()
        local className = UnitClass("player")

        local wasSearchBarShown = ModernSpellBookFrame.searchBar:IsShown()
        ModernSpellBookFrame.searchBar:Hide()
        ModernSpellBookFrame.searchBar:SetPoint("RIGHT", ModernSpellBookFrame:GetRightmostLeftButton(), "LEFT", -10, 1)
        if wasSearchBarShown then ModernSpellBookFrame.searchBar:Show() end

        ModernSpellBookFrame.selectedTab = ModernSpellBook_DB.rememberPage and ModernSpellBook_DB.lastTab or 1
        ModernSpellBookFrame.tab1 = ModernSpellBookFrame:NewTab(className)
        ModernSpellBookFrame.tab2 = ModernSpellBookFrame:NewTab(GENERAL)
        ModernSpellBookFrame.tab3 = ModernSpellBookFrame:NewTab("Pet")

        ModernSpellBookFrame.customTabs = {}

        ModernSpellBookFrame.tab3:UpdateAsPetTab()
        ModernSpellBookFrame:SetShape(ModernSpellBook_DB.isMinimized)
        ModernSpellBookFrame:PositionAllTabs()

        if next(ModernSpellBook_DB.knownSpells) == nil then
            SpellDataService:SetupInitiallyKnownSpells()
        end

        -- Restore last selected tab
        local lastTab = ModernSpellBook_DB.rememberPage and ModernSpellBook_DB.lastTab or 1
        if lastTab > 1 and ModernSpellBookFrame.Tabgroups[lastTab] then
            ModernSpellBookFrame.Tabgroups[lastTab]:Click()
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

    -- Reset to page 1 / tab 1 if "Remember page" is off
    if not ModernSpellBook_DB.rememberPage then
        ModernSpellBookFrame.currentPage = 1
        if ModernSpellBookFrame.selectedTab ~= 1 and ModernSpellBookFrame.Tabgroups[1] then
            ModernSpellBookFrame.selectedTab = 1
            -- Visually reset tabs without triggering a separate DrawPage
            for _, tab in ipairs(ModernSpellBookFrame.Tabgroups) do
                tab:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
                tab:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5, 1)
                tab:GetFontString():SetTextColor(0.5, 0.41, 0)
            end
            ModernSpellBookFrame.Tabgroups[1]:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
            ModernSpellBookFrame.Tabgroups[1]:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
            ModernSpellBookFrame.Tabgroups[1]:GetFontString():SetTextColor(1, 0.82, 0)
        end
        spellUpdateRequired = true
    end

    if spellUpdateRequired then
        ModernSpellBookFrame:DrawPage()
    end

    -- Show/hide trainer hint
    if ModernSpellBookFrame.trainerHint then
        local _, englishClass = UnitClass("player")
        local spellCount = 0
        if ModernSpellBook_DB.trainerSpells and ModernSpellBook_DB.trainerSpells[englishClass] then
            for _ in pairs(ModernSpellBook_DB.trainerSpells[englishClass]) do
                spellCount = spellCount + 1
            end
        end
        if ModernSpellBook_DB.showUnlearned and spellCount < 50 then
            ModernSpellBookFrame.trainerHint:Show()
        else
            ModernSpellBookFrame.trainerHint:Hide()
        end
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
        if ModernSpellBookFrame.isForceLoading then return end
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

-- Reset seen-available list on level up so newly available spells glow
local levelTracker = CreateFrame("Frame")
levelTracker:RegisterEvent("PLAYER_LEVEL_UP")
levelTracker:SetScript("OnEvent", function()
    ModernSpellBook_DB.seenAvailable = {}
end)
