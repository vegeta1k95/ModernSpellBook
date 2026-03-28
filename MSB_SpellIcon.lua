--[[
	CIcon: Generic reusable icon component.
	Contains: socket, icon texture, border, round border,
	hover highlight, cooldown. No addon-specific logic.
--]]

local DEFAULT_ICON_SIZE = 28

class "CIcon"
{
	__init = function(self, parent, size)
		self.parent = parent
		self.size = size or DEFAULT_ICON_SIZE

		-- Socket background
		self.socket = parent:CreateTexture(nil, "ARTWORK")
		self.socket:SetWidth(self.size + 22)
		self.socket:SetHeight(self.size + 22)
		self.socket:SetPoint("CENTER", parent, "CENTER", 0, 0)

		-- Icon texture
		self.icon = parent:CreateTexture(nil, "OVERLAY")
		self.icon:SetWidth(self.size)
		self.icon:SetHeight(self.size)
		self.icon:SetPoint("CENTER", parent, "CENTER", 0, 0)
		self.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

		-- Border frame overlay
		self.border_frame = CreateFrame("Frame", nil, parent)
		self.border_frame:SetWidth(self.size + 32)
		self.border_frame:SetHeight(self.size + 32)
		self.border_frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
		self.border_frame:SetFrameLevel(parent:GetFrameLevel() + 3)
		self.border = self.border_frame:CreateTexture(nil, "OVERLAY")
		self.border:SetAllPoints(self.border_frame)

		-- Round border (alternative style, hidden by default)
		self.round_border_frame = CreateFrame("Frame", nil, parent)
		self.round_border_frame:SetWidth(self.size + 8)
		self.round_border_frame:SetHeight(self.size + 8)
		self.round_border_frame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
		self.round_border_frame:SetFrameLevel(parent:GetFrameLevel() + 3)
		self.round_border = self.round_border_frame:CreateTexture(nil, "OVERLAY")
		self.round_border:SetAllPoints(self.round_border_frame)
		self.round_border_frame:Hide()

		-- Hover highlight
		self.hover_frame, self.hover_glow = MSB_CreateGlow(parent, self.size, nil, 4, "Interface\\Buttons\\CheckButtonHilight")
		self.hover_frame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
		self.hover_frame:Show()
		self.hover_glow:SetAlpha(0)
		self.hover_alpha = 0.5

		-- Cooldown
		local cd_type = COOLDOWN_FRAME_TYPE or "Model"
		local cd_ok, cd_frame = pcall(CreateFrame, cd_type, nil, parent, "CooldownFrameTemplate")
		if (not cd_ok) then
			cd_ok, cd_frame = pcall(CreateFrame, "Cooldown", nil, parent, "CooldownFrameTemplate")
		end
		if (cd_ok and cd_frame) then
			self.cooldown = cd_frame
			self.cooldown:SetPoint("TOPLEFT", self.icon, "TOPLEFT", 0, 0)
			self.cooldown:SetPoint("BOTTOMRIGHT", self.icon, "BOTTOMRIGHT", 0, 0)
			if (self.cooldown.SetDrawEdge) then
				self.cooldown:SetDrawEdge(false)
			end
		else
			self.cooldown = nil
		end
	end;

	-- ========================= ICON ==============================

	SetIcon = function(self, texture)
		self.icon:SetTexture(texture)
	end;

	SetIconCoords = function(self, l, r, t, b)
		self.icon:SetTexCoord(l, r, t, b)
	end;

	SetPortrait = function(self, texture)
		if (SetPortraitToTexture) then
			SetPortraitToTexture(self.icon, texture)
		else
			self.icon:SetTexture(texture)
			self.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
		end
	end;

	SetIconAlpha = function(self, alpha)
		self.icon:SetAlpha(alpha)
	end;

	SetIconColor = function(self, r, g, b)
		self.icon:SetVertexColor(r, g, b)
	end;

	-- ======================== SOCKET =============================

	SetSocket = function(self, texture)
		self.socket:SetTexture(texture)
	end;

	SetSocketAlpha = function(self, alpha)
		self.socket:SetAlpha(alpha)
	end;

	ShowSocket = function(self)
		self.socket:Show()
	end;

	HideSocket = function(self)
		self.socket:Hide()
	end;

	-- ======================== BORDER =============================

	SetBorder = function(self, texture)
		self.border:SetTexture(texture)
	end;

    SetBorderWidth = function(self, w)
        self.border_frame:SetWidth(w)
    end;

    SetBorderHeight = function(self, h)
        self.border_frame:SetHeight(h)
    end;

    SetBorderSize = function(self, size)
        self.border_frame:SetWidth(size)
        self.border_frame:SetHeight(size)
    end;

    SetBorderColor = function(self, r, g, b)
        self.border:SetVertexColor(r, g, b)
    end;

	SetBorderAlpha = function(self, alpha)
		self.border:SetAlpha(alpha)
	end;

	ShowBorder = function(self)
		self.border_frame:Show()
	end;

	HideBorder = function(self)
		self.border_frame:Hide()
	end;

	-- ==================== ROUND BORDER ===========================

	SetRoundBorder = function(self, texture)
		self.round_border:SetTexture(texture)
	end;

	ShowRoundBorder = function(self)
		self.round_border_frame:Show()
	end;

	HideRoundBorder = function(self)
		self.round_border_frame:Hide()
	end;

	-- ======================= HOVER ===============================

	SetHoverAlpha = function(self, alpha)
		self.hover_alpha = alpha
	end;

	ShowHover = function(self)
		self.hover_glow:SetAlpha(self.hover_alpha)
	end;

	HideHover = function(self)
		self.hover_glow:SetAlpha(0)
	end;

	-- ====================== COOLDOWN =============================

	SetCooldown = function(self, start, duration, enable)
		if (self.cooldown) then
			local cd_func = CooldownFrame_SetTimer or CooldownFrame_Set
			if (cd_func) then cd_func(self.cooldown, start, duration, enable) end
		end
	end;

	HideCooldown = function(self)
		if (self.cooldown) then self.cooldown:Hide() end
	end;

	-- ======================= STATE ===============================

	SetDesaturated = function(self, desaturated)
		if (self.icon.SetDesaturated) then
			self.icon:SetDesaturated(desaturated)
		elseif (desaturated) then
			self.icon:SetVertexColor(0.4, 0.4, 0.4)
		else
			self.icon:SetVertexColor(1, 1, 1)
		end
	end;

    SetDesaturatedBorder = function(self, desaturated)
    	self.border:SetDesaturated(desaturated)
        self.round_border:SetDesaturated(desaturated)
	end;
}

--==============================================================================
--====================== Class "CSpellBookIcon" ================================
--==============================================================================

--[[
	Extends CIcon with spellbook-specific components and logic:
	glows (new, available, active), badges (new, train),
	and methods that use spellInfo / ModernSpellBook_DB.
--]]

class "CSpellBookIcon"
:extends("CIcon")
{
	__init = function(self, parent)
		CIcon.__init(self, parent, DEFAULT_ICON_SIZE)

		-- Spellbook socket & border textures
		self:SetSocket("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
		self:SetBorder("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")
		self:SetRoundBorder("Interface\\AddOns\\ModernSpellBook\\Assets\\bluemenu-ring")

		-- Glow: shared for new/available highlights (changes color)
		self.glow_frame, self.glow_tex = MSB_CreateGlow(parent, 60, nil, 15)

		-- Badge: "New" for learned spells
		self.badge_new = MSB_CreateBadge(parent, "New", {1, 0.878, 0.078, 0.7}, {1, 0.9, 0.1, 0.8}, 12)
		self.badge_new:SetPoint("BOTTOM", parent, "TOP", 0, 2)

		-- Badge: "Train" for available spells
		self.badge_train = MSB_CreateBadge(parent, "Train", {0, 0.8, 0, 0.4}, {0.1, 0.8, 0.1, 0.8}, 7)
		self.badge_train:SetPoint("BOTTOM", self.icon, "TOP", 0, 2)

		-- Glow: stance active indicator
		self.glow_active_frame = CreateFrame("Frame", nil, parent)
		self.glow_active_frame:SetWidth(self.size + 2)
		self.glow_active_frame:SetHeight(self.size + 2)
		self.glow_active_frame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
		self.glow_active_frame:SetFrameLevel(parent:GetFrameLevel() + 5)
		self.glow_active = self.glow_active_frame:CreateTexture(nil, "OVERLAY")
		self.glow_active:SetWidth(self.size + 2)
		self.glow_active:SetHeight(self.size + 2)
		self.glow_active:SetAllPoints(self.glow_active_frame)
		self.glow_active:SetTexture("Interface\\Buttons\\CheckButtonHilight")
		self.glow_active:SetBlendMode("ADD")
		self.glow_active:SetAlpha(0)

		self.is_passive = false
	end;

	-- ========================= STYLE =============================

	SetStyle = function(self, spellInfo)
		if (spellInfo.isPassive) then
			self:SetPortrait(spellInfo.spellIcon)
			self:SetIconColor(1, 1, 1)
			self.socket:SetTexture("")
			self:SetSocketAlpha(0)
			self:HideBorder()
			self:ShowRoundBorder()
			self.hover_alpha = 0
		else
			self:SetIcon(spellInfo.spellIcon)
			self:SetIconCoords(0.04, 0.96, 0.04, 0.96)
			self:SetIconColor(1, 1, 1)
			self:SetSocketAlpha(1)
			self.socket:SetWidth(self.size + 22)
			self.socket:SetHeight(self.size + 22)
			self.socket:SetPoint("TOPLEFT", self.parent, "TOPLEFT", -3, 3)
			self:SetSocket("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
			self.socket:SetVertexColor(1, 1, 1, 1)
			self:HideRoundBorder()
			self:SetBorder("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")
			self.border:SetDrawLayer("OVERLAY", 1)
			self.border:SetVertexColor(1, 1, 1)
			self.hover_alpha = 0.5
		end
		self.is_passive = spellInfo.isPassive
	end;

	SetFancyFrame = function(self, spellInfo)
		local show = true
		if (ModernSpellBook_DB and ModernSpellBook_DB.iconFrame) then
			local is_other_tab = ModernSpellBookFrame.selectedTab and ModernSpellBookFrame.selectedTab > 2
			if (spellInfo.isUnlearned) then
				show = ModernSpellBook_DB.iconFrame.unlearned
			elseif (spellInfo.isPassive) then
				show = false
			elseif (is_other_tab) then
				show = ModernSpellBook_DB.iconFrame.other
			else
				show = ModernSpellBook_DB.iconFrame.spells
			end
		end
		if (show) then
			self:ShowBorder()
		else
			self:HideBorder()
		end
	end;

	-- ======================= HIGHLIGHTS ==========================

	SetHighlights = function(self, spellInfo, isNew)
		local hl = ModernSpellBook_DB.highlights

		-- Reset
		self.glow_frame:Hide()
		self.badge_new:Hide()
		self.badge_train:Hide()

		-- Learned spell glow/badge (yellow)
		if (isNew and not spellInfo.isPassive) then
			if (hl and hl.learnedGlow) then
				self.glow_tex:SetVertexColor(1, 1, 1)
				self.glow_frame:ClearAllPoints()
				self.glow_frame:SetPoint("CENTER", self.icon, "CENTER", 0.5, 0)
				self.glow_frame:Show()
			end
			if (hl and hl.learnedBadge) then
				self.badge_new:Show()
			end
			return
		end

		-- Available-to-learn glow/badge (light blue)
		if (spellInfo.isUnlearned and not spellInfo.isTalent and spellInfo.levelReq) then
			local player_level = UnitLevel("player")
			local key = MSB_SpellKey(spellInfo.spellName, spellInfo.spellRank)
			local entry = ModernSpellBook_DB.spells[key]
			local already_seen = entry and entry.seen_trainable
			if (spellInfo.levelReq <= player_level and not already_seen and not spellInfo.talentBlocked) then
				if (hl and hl.availableGlow) then
					self.glow_tex:SetVertexColor(0.204, 0.765, 0.922)
					self.glow_frame:ClearAllPoints()
					self.glow_frame:SetPoint("CENTER", self.icon, "CENTER", 0, 0)
					self.glow_frame:Show()
				end
				if (hl and hl.availableBadge) then
					self.badge_train:Show()
				end
			end
		end
	end;

	DismissNewHighlight = function(self)
		self.glow_frame:Hide()
		self.badge_new:Hide()
	end;

	DismissAvailableHighlight = function(self, spellInfo)
		if (self.glow_frame:IsShown()) then
			self.glow_frame:Hide()
			self.badge_train:Hide()
			local key = MSB_SpellKey(spellInfo.spellName, spellInfo.spellRank)
			local entry = ModernSpellBook_DB.spells[key]
			if (entry) then
				entry.seen_trainable = true
			end
		end
	end;

	-- ===================== LEARNED STATE =========================

	SetLearnedState = function(self, spellInfo)
		if (spellInfo.isUnlearned) then
			self:SetDesaturated(true)
			self:SetIconAlpha(0.5)
			local show_unlearned = ModernSpellBook_DB and ModernSpellBook_DB.iconFrame and ModernSpellBook_DB.iconFrame.unlearned
			if (not show_unlearned) then
				self:HideBorder()
			else
				if (self.border and self.border.SetDesaturated) then
					self.border:SetDesaturated(true)
				end
				self:SetBorderAlpha(0.5)
			end
			self:SetSocketAlpha(0.5)
			self.hover_alpha = 0
		else
			self:SetDesaturated(false)
			if (self.border and self.border.SetDesaturated) then
				self.border:SetDesaturated(false)
			end
			self:SetBorderAlpha(1)
			self:SetIconAlpha(1)
			self:SetSocketAlpha(1)
		end
	end;

	-- ======================== STANCE =============================

	SetStance = function(self, is_active)
		self.glow_active:SetAlpha(is_active and 1 or 0)
	end;
}
