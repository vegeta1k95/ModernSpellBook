local totalSpellItems = 0
local totalSpellCategoryFrames = 0

local VERTICAL_SPACING = 50
local SECOND_PAGE_OFFSET = 510
local HORIZONTAL_OFFSET = 40

function ModernSpellBookFrame:CleanPages()
    for i = 1, totalSpellItems do
        ModernSpellBookFrame["Spell".. i]:Hide()
    end

    for i = 1, totalSpellCategoryFrames do
        local categoryFrame = ModernSpellBookFrame["Category".. i]
        categoryFrame:Hide()
    end
end

function ModernSpellBookFrame:GetOrCreateCategory(i)
    local categoryFrame = ModernSpellBookFrame["Category".. i]
    if categoryFrame ~= nil then
        return categoryFrame
    end

    totalSpellCategoryFrames = totalSpellCategoryFrames +1
    ModernSpellBookFrame["Category".. i] = CreateFrame("Frame", nil, ModernSpellBookFrame)
    categoryFrame = ModernSpellBookFrame["Category".. i]
    categoryFrame:SetWidth(450)
    categoryFrame:SetHeight(20)
    -- Spec icon next to category name
    categoryFrame.specIconFrame = CreateFrame("Frame", nil, categoryFrame)
    categoryFrame.specIconFrame:SetWidth(22)
    categoryFrame.specIconFrame:SetHeight(22)
    categoryFrame.specIconFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 10, 1)
    categoryFrame.specIconFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    categoryFrame.specIconFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    categoryFrame.specIcon = categoryFrame.specIconFrame:CreateTexture(nil, "OVERLAY")
    categoryFrame.specIcon:SetWidth(18)
    categoryFrame.specIcon:SetHeight(18)
    categoryFrame.specIcon:SetPoint("CENTER", categoryFrame.specIconFrame, "CENTER", 0, 0)
    categoryFrame.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    categoryFrame.text = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryFrame.text:SetPoint("LEFT", categoryFrame.specIconFrame, "RIGHT", 5, 0)
    categoryFrame.text:SetTextColor(0, 0, 0)
    categoryFrame.text:SetShadowOffset(0, 0)
    categoryFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 17)

    categoryFrame.lightBorder = categoryFrame:CreateTexture(nil, "OVERLAY")
    categoryFrame.lightBorder:SetWidth(500)
    categoryFrame.lightBorder:SetHeight(90)
    categoryFrame.lightBorder:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", -170, 35)
    categoryFrame.lightBorder:SetTexture("Interface\\Glues\\Models\\UI_Tauren\\gradientcircle")
    categoryFrame.lightBorder:SetBlendMode("ADD")
    categoryFrame.lightBorder:SetDrawLayer("OVERLAY", -2)
    categoryFrame.lightBorder:SetAlpha(0.15)

    categoryFrame.separator = categoryFrame:CreateTexture(nil, "OVERLAY")
    categoryFrame.separator:SetWidth(400)
    categoryFrame.separator:SetHeight(10)
    categoryFrame.separator:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 0, -30)
    categoryFrame.separator:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\separator")

    function categoryFrame:Set(categoryName, currentPageRows, page)
        categoryFrame.text:SetText(categoryName)

        -- Look up spec icon from talent tabs or spell tabs
        local specIconFound = false
        for t = 1, GetNumTalentTabs() do
            local tabName, tabIcon = GetTalentTabInfo(t)
            if tabName == categoryName then
                categoryFrame.specIcon:SetTexture(tabIcon)
                specIconFound = true
                break
            end
        end
        if not specIconFound then
            -- Try spell tabs
            local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
            for t = 1, numTabs do
                local tabName, tabIcon = GetSpellTabInfo(t)
                if tabName == categoryName and tabIcon then
                    categoryFrame.specIcon:SetTexture(tabIcon)
                    specIconFound = true
                    break
                end
            end
        end
        if not specIconFound then
            categoryFrame.specIconFrame:Hide()
            categoryFrame.text:SetPoint("LEFT", categoryFrame.specIconFrame, "LEFT", 0, 0)
        else
            categoryFrame.specIconFrame:Show()
            categoryFrame.text:SetPoint("LEFT", categoryFrame.specIconFrame, "RIGHT", 5, 0)
        end

        categoryFrame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", HORIZONTAL_OFFSET +SECOND_PAGE_OFFSET*(page -1), -80 +currentPageRows *-VERTICAL_SPACING -5)
        categoryFrame:Show()
    end

    return categoryFrame
end

-- ============================================================
-- SpellItem factory (creates MSB_SpellItem instances)
-- ============================================================

function ModernSpellBookFrame:GetOrCreateSpellItem(i)
    local spellItem = ModernSpellBookFrame["Spell".. i]
    if spellItem ~= nil then
        return spellItem
    end
    totalSpellItems = totalSpellItems + 1
    spellItem = MSB_SpellItem:New(ModernSpellBookFrame, i)
    ModernSpellBookFrame["Spell".. i] = spellItem
    return spellItem
end
