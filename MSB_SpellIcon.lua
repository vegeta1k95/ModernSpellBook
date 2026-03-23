-- MSB_SpellIcon.lua
-- OOP class for the spell icon area: icon texture, tile/socket, borders, glows, badges, cooldown, stance indicator.

local ICON_SIZE = 28

MSB_SpellIcon = MSB_Class()

function MSB_SpellIcon:Init(parent)
    self.parent = parent

    -- New spell glow (highest layer)
    self.glowNewFrame, self.glowNew = MSB_CreateGlow(parent, 60, nil, 15)

    -- "New" badge for newly learned spells
    self.badgeNew = MSB_CreateBadge(parent, "New", {1, 0.878, 0.078, 0.7}, {1, 0.9, 0.1, 0.8}, 12)
    self.badgeNew:SetPoint("BOTTOM", parent, "TOP", 0, 2)

    -- Socket background
    self.tile = parent:CreateTexture(nil, "ARTWORK")
    self.tile:SetWidth(ICON_SIZE + 22)
    self.tile:SetHeight(ICON_SIZE + 22)
    self.tile:SetPoint("CENTER", parent, "CENTER", 0, 0)
    self.tile:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")

    -- Spell icon texture
    self.icon = parent:CreateTexture(nil, "OVERLAY")
    self.icon:SetWidth(ICON_SIZE)
    self.icon:SetHeight(ICON_SIZE)
    self.icon:SetPoint("CENTER", parent, "CENTER", 0, 0)
    self.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    -- Decorative frame overlay
    self.fancyFrame = CreateFrame("Frame", nil, parent)
    self.fancyFrame:SetWidth(60)
    self.fancyFrame:SetHeight(60)
    self.fancyFrame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    self.fancyFrame:SetFrameLevel(parent:GetFrameLevel() + 3)
    self.border = self.fancyFrame:CreateTexture(nil, "OVERLAY")
    self.border:SetAllPoints(self.fancyFrame)
    self.border:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")

    -- Passive spell round border (hidden by default)
    self.roundBorderFrame = CreateFrame("Frame", nil, parent)
    self.roundBorderFrame:SetWidth(56)
    self.roundBorderFrame:SetHeight(56)
    self.roundBorderFrame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
    self.roundBorderFrame:SetFrameLevel(parent:GetFrameLevel() + 3)
    self.roundBorder = self.roundBorderFrame:CreateTexture(nil, "OVERLAY")
    self.roundBorder:SetAllPoints(self.roundBorderFrame)
    self.roundBorder:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\bluemenu-ring")
    self.roundBorderFrame:Hide()

    -- Hover highlight
    self.glowCheckedFrame, self.glowChecked = MSB_CreateGlow(parent, ICON_SIZE, nil, 4, "Interface\\Buttons\\CheckButtonHilight")
    self.glowCheckedFrame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
    self.glowCheckedFrame:Show()
    self.glowChecked:SetAlpha(0)
    self.glowChecked.checkedAlpha = 0.5

    -- Cooldown
    local cdType = COOLDOWN_FRAME_TYPE or "Model"
    local cdOk, cdFrame = pcall(CreateFrame, cdType, nil, parent, "CooldownFrameTemplate")
    if not cdOk then
        cdOk, cdFrame = pcall(CreateFrame, "Cooldown", nil, parent, "CooldownFrameTemplate")
    end
    if cdOk and cdFrame then
        self.cooldown = cdFrame
        self.cooldown:SetPoint("TOPLEFT", self.icon, "TOPLEFT", 0, 0)
        self.cooldown:SetPoint("BOTTOMRIGHT", self.icon, "BOTTOMRIGHT", 0, 0)
        if self.cooldown.SetDrawEdge then
            self.cooldown:SetDrawEdge(false)
        end
    else
        self.cooldown = nil
    end

    -- Stance active indicator
    self.glowActiveFrame = CreateFrame("Frame", nil, parent)
    self.glowActiveFrame:SetWidth(ICON_SIZE + 2)
    self.glowActiveFrame:SetHeight(ICON_SIZE + 2)
    self.glowActiveFrame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
    self.glowActiveFrame:SetFrameLevel(parent:GetFrameLevel() + 5)
    self.glowActive = self.glowActiveFrame:CreateTexture(nil, "OVERLAY")
    self.glowActive:SetWidth(ICON_SIZE + 2)
    self.glowActive:SetHeight(ICON_SIZE + 2)
    self.glowActive:SetAllPoints(self.glowActiveFrame)
    self.glowActive:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    self.glowActive:SetBlendMode("ADD")
    self.glowActive:SetAlpha(0)

    -- Available-to-learn glow (light blue)
    self.glowAvailableFrame, self.glowAvailable = MSB_CreateGlow(parent, 60, {0.204, 0.765, 0.922}, 8)

    -- "Train" badge for available-to-learn spells
    self.badgeTrain = MSB_CreateBadge(parent, "Train", {0, 0.8, 0, 0.4}, {0.1, 0.8, 0.1, 0.8}, 7)
    self.badgeTrain:SetPoint("BOTTOM", self.icon, "TOP", 0, 2)

    self.isPassive = false
end

-- ============================================================
-- Visual state methods
-- ============================================================

function MSB_SpellIcon:SetStyle(spellInfo)
    if spellInfo.isPassive then
        if SetPortraitToTexture then
            SetPortraitToTexture(self.icon, spellInfo.spellIcon)
        else
            self.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
        end
        self.icon:SetVertexColor(1, 1, 1)
        self.tile:SetTexture("")
        self.tile:SetAlpha(0)
        self.fancyFrame:Hide()
        self.roundBorderFrame:Show()
        self.glowChecked.checkedAlpha = 0
    else
        self.icon:SetTexture(spellInfo.spellIcon)
        self.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
        self.icon:SetVertexColor(1, 1, 1)
        self.tile:SetAlpha(1)
        self.tile:SetWidth(ICON_SIZE + 22)
        self.tile:SetHeight(ICON_SIZE + 22)
        self.tile:SetPoint("TOPLEFT", self.parent, "TOPLEFT", -3, 3)
        self.tile:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
        self.tile:SetVertexColor(1, 1, 1, 1)
        self.roundBorderFrame:Hide()
        self.border:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")
        self.border:SetDrawLayer("OVERLAY", 1)
        self.border:SetVertexColor(1, 1, 1)
        self.glowChecked.checkedAlpha = 0.5
    end
    self.isPassive = spellInfo.isPassive
end

function MSB_SpellIcon:SetFancyFrame(spellInfo)
    local showFrame = true
    if ModernSpellBook_DB and ModernSpellBook_DB.iconFrame then
        local isOtherTab = ModernSpellBookFrame.selectedTab and ModernSpellBookFrame.selectedTab > 2
        if spellInfo.isUnlearned then
            showFrame = ModernSpellBook_DB.iconFrame.unlearned
        elseif spellInfo.isPassive then
            showFrame = false
        elseif isOtherTab then
            showFrame = ModernSpellBook_DB.iconFrame.other
        else
            showFrame = ModernSpellBook_DB.iconFrame.spells
        end
    end
    if showFrame then
        self.fancyFrame:Show()
    else
        self.fancyFrame:Hide()
    end
end

function MSB_SpellIcon:SetHighlights(spellInfo, isNew)
    local hl = ModernSpellBook_DB.highlights
    -- Learned spell glow/badge
    if isNew and not spellInfo.isPassive then
        if hl and hl.learnedGlow then
            self.glowNewFrame:ClearAllPoints()
            self.glowNewFrame:SetPoint("CENTER", self.icon, "CENTER", 0.5, 0)
            self.glowNewFrame:Show()
        else
            self.glowNewFrame:Hide()
        end
        if hl and hl.learnedBadge then
            self.badgeNew:Show()
        else
            self.badgeNew:Hide()
        end
    else
        self.glowNewFrame:Hide()
        self.badgeNew:Hide()
    end

    -- Available-to-learn glow/badge
    if spellInfo.isUnlearned and not spellInfo.isTalent and spellInfo.levelReq then
        local playerLevel = UnitLevel("player")
        local availKey = spellInfo.spellName .. (spellInfo.spellRank or "")
        local alreadySeen = ModernSpellBook_DB.seenAvailable and ModernSpellBook_DB.seenAvailable[availKey]
        if spellInfo.levelReq <= playerLevel and not alreadySeen and not spellInfo.talentBlocked then
            if hl and hl.availableGlow then
                self.glowAvailableFrame:ClearAllPoints()
                self.glowAvailableFrame:SetWidth(60)
                self.glowAvailableFrame:SetHeight(60)
                self.glowAvailableFrame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
                self.glowAvailableFrame:Show()
            else
                self.glowAvailableFrame:Hide()
            end
            if hl and hl.availableBadge then
                self.badgeTrain:Show()
            else
                self.badgeTrain:Hide()
            end
        else
            self.glowAvailableFrame:Hide()
            self.badgeTrain:Hide()
        end
    else
        self.glowAvailableFrame:Hide()
        self.badgeTrain:Hide()
    end
end

function MSB_SpellIcon:SetLearnedState(spellInfo)
    if spellInfo.isUnlearned then
        if self.icon.SetDesaturated then
            self.icon:SetDesaturated(true)
        else
            self.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
        self.icon:SetAlpha(0.5)
        local showUnlearnedFrame = ModernSpellBook_DB and ModernSpellBook_DB.iconFrame and ModernSpellBook_DB.iconFrame.unlearned
        if not showUnlearnedFrame then
            self.fancyFrame:Hide()
        else
            if self.border and self.border.SetDesaturated then
                self.border:SetDesaturated(true)
            end
            self.border:SetAlpha(0.5)
        end
        self.tile:SetAlpha(0.5)
        self.glowChecked.checkedAlpha = 0
    else
        if self.icon.SetDesaturated then
            self.icon:SetDesaturated(false)
        end
        if self.border and self.border.SetDesaturated then
            self.border:SetDesaturated(false)
        end
        if self.border then self.border:SetAlpha(1) end
        self.icon:SetAlpha(1)
        self.tile:SetAlpha(1)
    end
end

function MSB_SpellIcon:SetStance(isActive)
    self.glowActive:SetAlpha(isActive and 1 or 0)
end

function MSB_SpellIcon:DismissNewHighlight()
    self.glowNewFrame:Hide()
    self.badgeNew:Hide()
end

function MSB_SpellIcon:DismissAvailableHighlight(spellInfo)
    if self.glowAvailableFrame:IsShown() then
        self.glowAvailableFrame:Hide()
        self.badgeTrain:Hide()
        if not ModernSpellBook_DB.seenAvailable then
            ModernSpellBook_DB.seenAvailable = {}
        end
        local availKey = spellInfo.spellName .. (spellInfo.spellRank or "")
        ModernSpellBook_DB.seenAvailable[availKey] = true
    end
end
