--[[
	CSpellBookIcon: Extends CIcon with spellbook-specific components and logic:
	glows (new, available, active), badges (new, train),
	and methods that use spellInfo / ModernSpellBook_DB.
--]]

local SPELLBOOK_ASSETS = "Interface\\AddOns\\ModernSpellBook\\Assets\\Spellbook\\"
local DEFAULT_ICON_SIZE = 28
local DEFAULT_SOCKET_SIZE = 22

class "CSpellBookIcon"
:extends("CIcon")
{
	__init = function(self, parent)
		CIcon.__init(self, parent, DEFAULT_ICON_SIZE)

		-- Spellbook socket & border textures
		self.socket:SetTexture(SPELLBOOK_ASSETS .. "spell-socket")
		self.socket:SetHeight(self.size + DEFAULT_SOCKET_SIZE)
		self.socket:SetWidth(self.size + DEFAULT_SOCKET_SIZE)

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

	end;

	-- ========================= STYLE =============================

	SetSpell = function(self, spellInfo)

		local showBorder = true

		if (ModernSpellBook_DB and ModernSpellBook_DB.iconFrame) then
			local is_other_tab = ModernSpellBookFrame.selectedTab and ModernSpellBookFrame.selectedTab > 2
			if (spellInfo.isUnlearned) then
				showBorder = ModernSpellBook_DB.iconFrame.unlearned
			elseif (is_other_tab) then
				showBorder = ModernSpellBook_DB.iconFrame.other
			else
				showBorder = ModernSpellBook_DB.iconFrame.spells
			end
		end

		if (showBorder) then
			self.border_frame:Show()
			self.socket:Hide()
		else
			self.border_frame:Hide()
			self.socket:Show()
		end


		if (spellInfo.isPassive) then
			SetPortraitToTexture(self.icon, spellInfo.spellIcon)
			SetPortraitToTexture(self.hover_glow, "Interface\\Buttons\\CheckButtonHilight")
			self.border:SetTexture(SPELLBOOK_ASSETS .. "bluemenu-ring")
			self.border_frame:SetWidth(self.size + 8)
			self.border_frame:SetHeight(self.size + 8)
			self.socket:Hide()
		else
			self.icon:SetTexture(spellInfo.spellIcon)
			self.hover_glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
			self.border:SetTexture(SPELLBOOK_ASSETS .. "spellbook-frame")
			self.border_frame:SetWidth(self.size + 18)
			self.border_frame:SetHeight(self.size + 18)
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
			self.socket:SetAlpha(0.5)
			self.icon:SetAlpha(0.5)
			self.border:SetAlpha(0.5)

			local show_unlearned = ModernSpellBook_DB and ModernSpellBook_DB.iconFrame and ModernSpellBook_DB.iconFrame.unlearned
			if (not show_unlearned) then
				self.border_frame:Hide()
			end

			self.hover_glow:Hide()
		else
			self:SetDesaturated(false)
			self.socket:SetAlpha(1.0)
			self.icon:SetAlpha(1.0)
			self.border:SetAlpha(1.0)
		end
	end;

	-- ======================== STANCE =============================

	SetStance = function(self, is_active)
		self.glow_active:SetAlpha(is_active and 1 or 0)
	end;
}
