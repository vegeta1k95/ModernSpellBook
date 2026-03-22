local totalSpellIconFrames = 0
local totalSpellCategoryFrames = 0

local NEW_KEYWORD = string.lower(";".. NEW.. ";")
local SPELL_ICON_SIZE = 28
local TOTAL_SPELL_SIZE = 40
local SPELL_HORIZONTAL_SPACING = 150
local VERTICAL_SPACING = 50
local SECOND_PAGE_OFFSET = 510
local HORIZONTAL_OFFSET = 40
local SPELL_INSET = 20

function ModernSpellBookFrame:CleanPages() -- Hides all spell and category frames.
    for i = 1, totalSpellIconFrames do
        local spellFrame = ModernSpellBookFrame["Spell".. i]
        spellFrame:Hide()
    end

    for i = 1, totalSpellCategoryFrames do
        local categoryFrame = ModernSpellBookFrame["Category".. i]
        categoryFrame:Hide()
    end
end

function ModernSpellBookFrame:GetOrCreateCategory(i)
    local categoryFrame = ModernSpellBookFrame["Category".. i]
    if categoryFrame ~= nil then -- Search if category exists already
        return categoryFrame
    end

    totalSpellCategoryFrames = totalSpellCategoryFrames +1
    ModernSpellBookFrame["Category".. i] = CreateFrame("Frame", nil, ModernSpellBookFrame)
    categoryFrame = ModernSpellBookFrame["Category".. i]
    categoryFrame:SetWidth(450)
    categoryFrame:SetHeight(20)
    categoryFrame.text = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryFrame.text:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 10, 0)
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
        categoryFrame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", HORIZONTAL_OFFSET +SECOND_PAGE_OFFSET*(page -1), -80 +currentPageRows *-VERTICAL_SPACING -5)
        categoryFrame:Show()
    end

    return categoryFrame
end

function ModernSpellBookFrame:GetOrCreateSpellFrame(i)
    local spellFrame = ModernSpellBookFrame["Spell".. i]
    if spellFrame ~= nil then
        return spellFrame
    end
    totalSpellIconFrames = totalSpellIconFrames +1
    -- Use regular Button instead of SecureActionButtonTemplate (doesn't exist in vanilla)
    ModernSpellBookFrame["Spell".. i] = CreateFrame("Button", "ModernSpellBookSpell"..i, ModernSpellBookFrame)
    spellFrame = ModernSpellBookFrame["Spell".. i]
    spellFrame:SetWidth(SPELL_ICON_SIZE)
    spellFrame:SetHeight(SPELL_ICON_SIZE)
    spellFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    spellFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
        spellFrame.checkedGlow:SetAlpha(0)
    end)

    spellFrame:SetMovable(true)
    spellFrame:RegisterForDrag("LeftButton")

    -- Text container - vertically centered on the icon
    spellFrame.textGroup = CreateFrame("Frame", nil, spellFrame)
    spellFrame.textGroup:SetWidth(100)
    spellFrame.textGroup:SetHeight(SPELL_ICON_SIZE)
    spellFrame.textGroup:SetPoint("LEFT", spellFrame, "LEFT", 36, 0)

    spellFrame.text = spellFrame.textGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellFrame.text:SetPoint("TOPLEFT", spellFrame.textGroup, "TOPLEFT", 0, 0)
    if ModernSpellBook_DB and ModernSpellBook_DB.textColorMode == "dark" then
        spellFrame.text:SetTextColor(0, 0, 0)
        spellFrame.text:SetShadowOffset(0, 0)
    else
        spellFrame.text:SetTextColor(0.989, 0.857, 0.343)
        spellFrame.text:SetShadowOffset(1, -1)
        spellFrame.text:SetShadowColor(0, 0, 0, 0.7)
    end
    if spellFrame.text.SetWordWrap then spellFrame.text:SetWordWrap(true) end
    spellFrame.text:SetWidth(100)
    spellFrame.text:SetJustifyH("LEFT")
    spellFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 11.5)
    if spellFrame.text.SetJustifyV then spellFrame.text:SetJustifyV("TOP") end

    -- Light border behind text area
    spellFrame.lightBorder = spellFrame:CreateTexture(nil, "ARTWORK")
    spellFrame.lightBorder:SetWidth(170)
    spellFrame.lightBorder:SetHeight(TOTAL_SPELL_SIZE)
    spellFrame.lightBorder:SetPoint("LEFT", spellFrame, "CENTER", 0, 0)
    spellFrame.lightBorder:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-trail")
    if ModernSpellBook_DB and ModernSpellBook_DB.textColorMode == "dark" then
        spellFrame.lightBorder:SetBlendMode("ADD")
    end
    spellFrame.lightBorder:SetAlpha(1)

    -- === SpellIcon container: newGlow -> tile/socket -> icon -> border -> cooldown ===
    -- Layer 1 (bottom): New spell glow
    spellFrame.newGlow = spellFrame:CreateTexture(nil, "BACKGROUND")
    spellFrame.newGlow:SetWidth(70)
    spellFrame.newGlow:SetHeight(62)
    spellFrame.newGlow:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
    spellFrame.newGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
    spellFrame.newGlow:SetBlendMode("ADD")
    spellFrame.newGlow:SetAlpha(0.8)

    -- Layer 2: Tile/socket background
    spellFrame.tile = spellFrame:CreateTexture(nil, "ARTWORK")
    spellFrame.tile:SetWidth(SPELL_ICON_SIZE + 22)
    spellFrame.tile:SetHeight(SPELL_ICON_SIZE + 22)
    spellFrame.tile:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
    spellFrame.tile:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")

    -- Layer 3: The spell icon
    spellFrame.icon = spellFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.icon:SetWidth(SPELL_ICON_SIZE)
    spellFrame.icon:SetHeight(SPELL_ICON_SIZE)
    spellFrame.icon:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
    spellFrame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    -- Layer 4: Fancy frame overlay (in front of icon)
    spellFrame.fancyFrame = CreateFrame("Frame", nil, spellFrame)
    spellFrame.fancyFrame:SetWidth(60)
    spellFrame.fancyFrame:SetHeight(60)
    spellFrame.fancyFrame:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
    spellFrame.fancyFrame:SetFrameLevel(spellFrame:GetFrameLevel() + 3)
    spellFrame.fancyFrameTex = spellFrame.fancyFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.fancyFrameTex:SetAllPoints(spellFrame.fancyFrame)
    spellFrame.fancyFrameTex:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")

    -- Keep old border reference for passive/active logic
    spellFrame.border = spellFrame.fancyFrameTex

    -- Layer 5: Hover highlight
    spellFrame.checkedGlow = spellFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.checkedGlow:SetWidth(SPELL_ICON_SIZE)
    spellFrame.checkedGlow:SetHeight(SPELL_ICON_SIZE)
    spellFrame.checkedGlow:SetPoint("CENTER", spellFrame.icon, "CENTER", 0, 0)
    spellFrame.checkedGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    spellFrame.checkedGlow:SetBlendMode("ADD")
    spellFrame.checkedGlow:SetAlpha(0)
    spellFrame.checkedGlow.checkedAlpha = 0.5

    -- Layer 6: Cooldown (separate frame, on top)
    local cdType = COOLDOWN_FRAME_TYPE or "Model"
    local cdOk, cdFrame = pcall(CreateFrame, cdType, nil, spellFrame, "CooldownFrameTemplate")
    if not cdOk then
        cdOk, cdFrame = pcall(CreateFrame, "Cooldown", nil, spellFrame, "CooldownFrameTemplate")
    end
    if cdOk and cdFrame then
        spellFrame.cooldown = cdFrame
        spellFrame.cooldown:SetPoint("TOPLEFT", spellFrame.icon, "TOPLEFT", 0, 0)
        spellFrame.cooldown:SetPoint("BOTTOMRIGHT", spellFrame.icon, "BOTTOMRIGHT", 0, 0)
        if spellFrame.cooldown.SetDrawEdge then
            spellFrame.cooldown:SetDrawEdge(false)
        end
    else
        spellFrame.cooldown = nil
    end

    -- Rank/passive text inside the text group
    spellFrame.subText = spellFrame.textGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellFrame.subText:SetPoint("TOPLEFT", spellFrame.text, "BOTTOMLEFT", 0, -1)
    if ModernSpellBook_DB and ModernSpellBook_DB.textColorMode == "dark" then
        spellFrame.subText:SetTextColor(0, 0, 0)
        spellFrame.subText:SetShadowOffset(0, 0)
    else
        spellFrame.subText:SetTextColor(1, 1, 1)
        spellFrame.subText:SetShadowOffset(1, -1)
        spellFrame.subText:SetShadowColor(0, 0, 0, 0.7)
    end
    spellFrame.subText:SetFont("Fonts\\FRIZQT__.TTF", 9.5)
    spellFrame.subText:SetJustifyH("LEFT")
    if spellFrame.subText.SetWordWrap then spellFrame.subText:SetWordWrap(true) end
    spellFrame.subText:SetWidth(80)
    spellFrame.subText:SetHeight(10)

    -- Use a child frame so the glow always renders on top of the icon
    spellFrame.activeLightFrame = CreateFrame("Frame", nil, spellFrame)
    spellFrame.activeLightFrame:SetWidth(SPELL_ICON_SIZE + 2)
    spellFrame.activeLightFrame:SetHeight(SPELL_ICON_SIZE + 2)
    spellFrame.activeLightFrame:SetPoint("CENTER", spellFrame.icon, "CENTER", 0, 0)
    spellFrame.activeLightFrame:SetFrameLevel(spellFrame:GetFrameLevel() + 5)

    spellFrame.activeLight = spellFrame.activeLightFrame:CreateTexture(nil, "OVERLAY")
    spellFrame.activeLight:SetWidth(SPELL_ICON_SIZE + 2)
    spellFrame.activeLight:SetHeight(SPELL_ICON_SIZE + 2)
    spellFrame.activeLight:SetAllPoints(spellFrame.activeLightFrame)
    spellFrame.activeLight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    spellFrame.activeLight:SetBlendMode("ADD")
    spellFrame.activeLight:SetAlpha(0)

    spellFrame.icon.isPassive = false

    function spellFrame:SetStance(isActive)
        spellFrame.activeLight:SetAlpha(isActive and 1 or 0)
    end

    function spellFrame:Set(spellInfo, currentPageRows, page, grid_x)
        -- Set up click handler for casting (replaces SetAttribute-based casting)
        spellFrame:SetScript("OnClick", function()
            if spellInfo.isPassive then return end
            if InCombatLockdown() then return end

            if spellInfo.isPetSpell then
                if spellInfo.castName then
                    CastPetAction(spellInfo.castName)
                    -- Update icon after a short delay in case it changed
                    C_Timer.After(0.2, function()
                        if spellInfo.castName == nil then
                            UIErrorsFrame:AddMessage("ModernSpellBook: Warning - Pet spell ".. spellInfo.spellName.. " cannot be cast outside the pet action bar. Please drag the spell there.", 1.0, 0.1, 0.1, 1.0)
                            PlaySound("igQuestFailed")
                            return
                        end
                        local name, texture = GetPetActionInfo(spellInfo.castName)
                        spellFrame.icon:SetTexture(texture)
                    end)
                else
                    UIErrorsFrame:AddMessage("ModernSpellBook: Warning - Pet spell ".. spellInfo.spellName.. " cannot be cast outside the pet action bar. Please drag the spell there.", 1.0, 0.1, 0.1, 1.0)
                    PlaySound("igQuestFailed")
                end
            else
                -- Cast player spell by name (with rank if available)
                CastSpellByName(spellInfo.castName)
            end
        end)

        spellFrame.icon:SetTexture(spellInfo.spellIcon)
        spellFrame.text:SetText(spellInfo.spellName)
        spellFrame.subText:SetText(spellInfo.spellRank)
        spellFrame.spellID = spellInfo.spellID
        spellFrame.bookType = spellInfo.bookType

        local stanceState = false
        if spellInfo.stanceIndex ~= nil then
            local _, _, isActive = GetShapeshiftFormInfo(spellInfo.stanceIndex)
            stanceState = isActive
            ModernSpellBookFrame.stanceButtons[spellInfo.spellName] = spellFrame
        end

        spellFrame:SetStance(stanceState)

        -- Calculate total text height and vertically center the group on the icon
        local nameHeight = 13 -- default single line
        if spellFrame.text.GetStringHeight then
            nameHeight = spellFrame.text:GetStringHeight()
        elseif spellFrame.text.GetHeight then
            nameHeight = spellFrame.text:GetHeight()
        end
        local subHeight = 0
        if spellInfo.spellRank and spellInfo.spellRank ~= "" then
            subHeight = 11 -- subText line height + gap
        end
        local totalHeight = nameHeight + subHeight
        local yOffset = (SPELL_ICON_SIZE - totalHeight) / 2
        spellFrame.textGroup:ClearAllPoints()
        spellFrame.textGroup:SetPoint("TOPLEFT", spellFrame, "TOPLEFT", 36, -yOffset)

        local lookupString = spellInfo.spellName.. spellInfo.spellRank
        local knownSpell = ModernSpellBook_DB.knownSpells[lookupString]
        local isNew = knownSpell and string.find(knownSpell, NEW_KEYWORD) ~= nil

        if isNew then
            spellFrame.newGlow:Show()
        else
            spellFrame.newGlow:Hide()
        end

        spellFrame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", HORIZONTAL_OFFSET +SPELL_INSET +SECOND_PAGE_OFFSET*(page -1) +grid_x *SPELL_HORIZONTAL_SPACING, -80 +currentPageRows *-VERTICAL_SPACING)

        -- Should be able to link spells to the chat
        spellFrame:SetScript("OnMouseDown", function()
            local button = arg1
            local isChatLink = IsModifiedClick and IsModifiedClick("CHATLINK") or IsShiftKeyDown()
            if isChatLink then
                if MacroFrameText and MacroFrameText.HasFocus and MacroFrameText:HasFocus() then
                    if spellInfo.isPassive then return end

                    if spellInfo.spellRank == "" then
                        ChatEdit_InsertLink(spellInfo.spellName)
                    elseif spellInfo.spellRank ~= "" then
                        ChatEdit_InsertLink(spellInfo.spellName.. "(".. spellInfo.spellRank.. ")")
                    end
                elseif spellInfo.isTalent then
                    local chatlink = GetTalentLink(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
                    if chatlink then
                        ChatEdit_InsertLink(chatlink)
                    else
                        ChatEdit_InsertLink(spellInfo.spellName)
                    end
                else
                    local spellLink = "|cff71d5ff|Hspell:".. spellInfo.spellID .. "|h[".. spellInfo.spellName .."]|h|r"
                    ChatEdit_InsertLink(spellLink)
                end
            end

            return;
        end)

        -- When hovered display the spell's tooltip
        spellFrame:SetScript("OnEnter", function()
            spellFrame.checkedGlow:SetAlpha(spellFrame.checkedGlow.checkedAlpha)

            if isNew then
                ModernSpellBook_DB.knownSpells[lookupString] = string.gsub(ModernSpellBook_DB.knownSpells[lookupString], NEW_KEYWORD, "")
                isNew = false
            end
            spellFrame.newGlow:Hide()

            GameTooltip:SetOwner(spellFrame, "ANCHOR_RIGHT")
            if not spellInfo.isTalent then
                -- In vanilla, use SetSpell with spellbook slot and bookType
                if spellInfo.bookType then
                    GameTooltip:SetSpell(spellInfo.spellID, spellInfo.bookType)
                else
                    GameTooltip:SetSpellByID(spellInfo.spellID)
                end
            else
                -- For talents, try SetTalent or use a hyperlink
                if GameTooltip.SetTalent then
                    GameTooltip:SetTalent(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
                else
                    local talentLink = GetTalentLink(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
                    if talentLink then
                        GameTooltip:SetHyperlink(talentLink)
                    else
                        GameTooltip:SetText(spellInfo.spellName)
                    end
                end
            end
            GameTooltip:Show()
        end)

        -- Add a dynamically updating cooldown
        if not spellInfo.isPassive then
            spellFrame:SetMovable(true)
            spellFrame:SetScript("OnDragStart", function()
                if InCombatLockdown() then return end
                if spellInfo.isPetSpell then
                    PickupSpell(spellInfo.spellID, BOOKTYPE_PET)
                else
                    PickupSpell(spellInfo.spellID, BOOKTYPE_SPELL)
                end
            end)

            spellFrame:SetScript("OnUpdate", function()
                -- Use spellbook slot index and bookType for cooldown query
                local start, duration, enable
                if spellInfo.bookType then
                    start, duration, enable = GetSpellCooldown(spellInfo.spellID, spellInfo.bookType)
                else
                    -- Fallback: try by name
                    start, duration, enable = GetSpellCooldown(spellInfo.spellName)
                end
                if start and spellFrame.cooldown then
                    local cdFunc = CooldownFrame_SetTimer or CooldownFrame_Set
                    if cdFunc then cdFunc(spellFrame.cooldown, start, duration, enable) end
                end
            end)
        else
            if spellFrame.cooldown then spellFrame.cooldown:Hide() end
            spellFrame:SetMovable(false)
            spellFrame:SetScript("OnUpdate", nil)
            spellFrame:SetScript("OnDragStart", nil)
        end
        spellFrame:Show()

        -- Show/hide fancyFrame based on settings
        if spellFrame.fancyFrame then
            local showFrame = true
            if ModernSpellBook_DB and ModernSpellBook_DB.iconFrame then
                local isOtherTab = ModernSpellBookFrame.selectedTab and ModernSpellBookFrame.selectedTab > 2
                if spellInfo.isPassive then
                    showFrame = ModernSpellBook_DB.iconFrame.passives
                elseif isOtherTab then
                    showFrame = ModernSpellBook_DB.iconFrame.other
                else
                    showFrame = ModernSpellBook_DB.iconFrame.spells
                end
            end
            if showFrame then
                spellFrame.fancyFrame:Show()
            else
                spellFrame.fancyFrame:Hide()
            end
        end

        if spellInfo.isPassive then
            spellFrame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
            spellFrame.icon:SetVertexColor(1, 1, 1)

            spellFrame.tile:SetAlpha(1)
            spellFrame.tile:SetWidth(SPELL_ICON_SIZE + 22)
            spellFrame.tile:SetHeight(SPELL_ICON_SIZE + 22)
            spellFrame.tile:SetPoint("CENTER", spellFrame, "CENTER", 0, 0)
            spellFrame.tile:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
            spellFrame.tile:SetVertexColor(1, 1, 1, 1)

            spellFrame.border:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")
            spellFrame.border:SetVertexColor(1, 1, 1)

            spellFrame.checkedGlow.checkedAlpha = 0
        else
            spellFrame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
            spellFrame.icon:SetVertexColor(1, 1, 1)

            -- Show square tile/border
            spellFrame.tile:SetAlpha(1)
            spellFrame.tile:SetWidth(SPELL_ICON_SIZE + 22)
            spellFrame.tile:SetHeight(SPELL_ICON_SIZE + 22)
            spellFrame.tile:SetPoint("TOPLEFT", spellFrame, "TOPLEFT", -3, 3)
            spellFrame.tile:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
            spellFrame.tile:SetVertexColor(1, 1, 1, 1)

            spellFrame.border:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")
            spellFrame.border:SetDrawLayer("OVERLAY", 1)
            spellFrame.border:SetVertexColor(1, 1, 1)

            spellFrame.checkedGlow.checkedAlpha = 0.5
        end
        spellFrame.icon.isPassive = spellInfo.isPassive
    end

    return spellFrame
end
