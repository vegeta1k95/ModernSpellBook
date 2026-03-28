--[[
	CTalentIcon: Single talent cell extending CIcon.
	Icon + frame (square/circle) + rank text + haze glow.
	Manages visual states: locked, available, partial, maxed.

	Frame shape determined by isExceptional from GetTalentInfo:
	  Exceptional → square frame (spec-defining talents)
	  Normal      → round frame + circular icon mask
--]]

local TALENT_ASSETS = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\"
local TALENT_ICON_SIZE = 30
local TALENT_ICON_SIZE_EXCEPTIONAL = 34

class "CTalentIcon"
:extends("CIcon")
{
	__init = function(self, parent, cell_size)
		self.cell_size = cell_size or 40

		-- Button frame (clickable)
		self.frame = CreateFrame("Button", nil, parent)
		self.frame:SetWidth(self.cell_size)
		self.frame:SetHeight(self.cell_size)

		CIcon.__init(self, self.frame, TALENT_ICON_SIZE)

		-- Default to square frame
		self:SetBorder(TALENT_ASSETS .. "talent-frame-square")
		self:SetBorderSize(TALENT_ICON_SIZE + 3.3)
		self:HideRoundBorder()
		self:HideCooldown()

		-- Haze glow behind the icon (spec-colored, below everything)
		self.haze_frame = CreateFrame("Frame", nil, self.frame)
		self.haze_frame:SetWidth(self.cell_size * 1.7)
		self.haze_frame:SetHeight(self.cell_size * 1.7)
		self.haze_frame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
		self.haze_frame:SetFrameLevel(self.frame:GetFrameLevel())
		self.haze_tex = self.haze_frame:CreateTexture(nil, "BACKGROUND")
		self.haze_tex:SetAllPoints(self.haze_frame)
		self.haze_tex:SetTexture(TALENT_ASSETS .. "talent-glow")
		self.haze_tex:SetBlendMode("ADD")
		self.haze_tex:SetAlpha(0)

		-- Rank text (bottom-right)
		self.rank_text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.rank_text:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, 4)
		self.rank_text:SetFont("Fonts\\FRIZQT__.TTF", 9)
		self.rank_text:SetTextColor(0.5, 0.5, 0.5)

		-- Talent data
		self.talent_tab = 0
		self.talent_index = 0
		self.tier = 0
		self.column = 0
		self.curr_rank = 0
		self.max_rank = 0
		self.is_exceptional = false
		self.visual_state = "locked"
		self.talent_name = ""
		self.prereq_tier = nil
		self.prereq_column = nil
		self.prereq_met = true

		-- Event handlers
		local talent_icon = self
		self.frame:SetScript("OnEnter", function()
			talent_icon:ShowHover()
			GameTooltip:SetOwner(talent_icon.frame, "ANCHOR_RIGHT")
			if (GameTooltip.SetTalent) then
				GameTooltip:SetTalent(talent_icon.talent_tab, talent_icon.talent_index)
			else
				GameTooltip:SetText(talent_icon.talent_name)
			end
			GameTooltip:Show()
		end)

		self.frame:SetScript("OnLeave", function()
			talent_icon:HideHover()
			GameTooltip:Hide()
		end)

		self.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		self.frame:SetScript("OnClick", function()
			if (arg1 == "LeftButton") then
				if (talent_icon.visual_state ~= "available" and talent_icon.visual_state ~= "partial") then
					return
				end
				if (LearnTalent) then
					LearnTalent(talent_icon.talent_tab, talent_icon.talent_index)
					if (TalentTree and TalentTree.frame:IsVisible()) then
						TalentTree:Refresh()
					end
				end
			end
		end)
	end;

	-- ==================== DATA ===================================

	SetTalentData = function(self, tab, index)
		self.talent_tab = tab
		self.talent_index = index

		local name, iconTexture, tier, column, currRank, maxRank, isExceptional = GetTalentInfo(tab, index)
		if (not name) then return end

		self.talent_name = name
		self.tier = tier
		self.column = column
		self.curr_rank = currRank
		self.max_rank = maxRank
		self.is_exceptional = (isExceptional and isExceptional == 1)
		self.icon_texture = iconTexture

		-- Icon shape: exceptional → square + bigger, normal → circular mask
		if (self.is_exceptional) then
			self.icon:SetWidth(TALENT_ICON_SIZE_EXCEPTIONAL)
			self.icon:SetHeight(TALENT_ICON_SIZE_EXCEPTIONAL)
			self.hover_frame:SetWidth(TALENT_ICON_SIZE_EXCEPTIONAL)
			self.hover_frame:SetHeight(TALENT_ICON_SIZE_EXCEPTIONAL)
			self:SetIcon(self.icon_texture)
			self:SetIconCoords(0.08, 0.92, 0.08, 0.92)
			self.hover_glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")

			if (maxRank == 1) then
				self.rank_text:Hide()
			end

		else
			self:SetPortrait(self.icon_texture)
			-- Circular mask on hover glow too
			if (SetPortraitToTexture) then
				SetPortraitToTexture(self.hover_glow, "Interface\\Buttons\\CheckButtonHilight")
			end
		end

		-- Query prerequisites
		self.prereq_tier = nil
		self.prereq_column = nil
		if (GetTalentPrereqs) then
			pcall(function()
				local pTier, pCol = GetTalentPrereqs(tab, index)
				if (pTier and pTier > 0) then
					self.prereq_tier = pTier
					self.prereq_column = pCol
				end
			end)
		end

		self:ApplyFrameShape()
		self.rank_text:SetText(currRank .. "/" .. maxRank)
	end;

	RefreshRank = function(self)
		local _, _, _, _, currRank, maxRank = GetTalentInfo(self.talent_tab, self.talent_index)
		if (currRank) then
			self.curr_rank = currRank
			self.max_rank = maxRank
			self.rank_text:SetText(currRank .. "/" .. maxRank)
		end
	end;

	-- =================== FRAME SHAPE =============================

	ApplyFrameShape = function(self)
		if (self.is_exceptional) then
			self:SetBorder(TALENT_ASSETS .. "talent-frame-square")
            self:SetSocket(TALENT_ASSETS .. "talent-socket-square")
			self:SetBorderSize(TALENT_ICON_SIZE_EXCEPTIONAL + 3.3)
			self.socket:SetWidth(self.size + 2)
			self.socket:SetHeight(self.size + 2)
		else
			self:SetBorder(TALENT_ASSETS .. "talent-frame-circle")
			self:SetSocket(TALENT_ASSETS .. "talent-socket-circle")
            self.socket:SetWidth(self.size + 4)
			self.socket:SetHeight(self.size + 4)
		end
		self:ShowSocket()
	end;

	-- ================== VISUAL STATE =============================

	UpdateVisualState = function(self, points_spent, prereq_checker, points_remaining)
		local required_points = (self.tier - 1) * 5

		-- Check if prerequisite talent is maxed
		self.prereq_met = true
		if (self.prereq_tier and prereq_checker) then
			self.prereq_met = prereq_checker(self.prereq_tier, self.prereq_column)
		end

		self.tier_unlocked = (points_spent >= required_points)

		if (self.curr_rank == self.max_rank) then
			self.visual_state = "maxed"
		elseif (self.curr_rank > 0) then
			self.visual_state = "partial"
		elseif (self.tier_unlocked and self.prereq_met and points_remaining and points_remaining > 0) then
			self.visual_state = "available"
		elseif (self.tier_unlocked and not (UnitLevel("player") >= 60 and (not points_remaining or points_remaining <= 0))) then
			self.visual_state = "locked_in_unlocked_tier"
		else
			self.visual_state = "locked_in_locked_tier"
		end

		self:ApplyVisualState()
	end;

	ApplyVisualState = function(self)
		local state = self.visual_state

		if (state == "locked_in_locked_tier") then
			self:SetDesaturated(true)
			self:SetDesaturatedBorder(true)
			self.socket:SetDesaturated(true)
	
            if (self.is_exceptional) then
                self:SetIconAlpha(0.5)
                self:SetBorderAlpha(0.6)
            else
                self:SetIconAlpha(0.3)
    			self:SetBorderAlpha(0.4)
            end
			self:SetSocketAlpha(0.9)
			self.rank_text:SetTextColor(0.5, 0.5, 0.5)
			self.haze_tex:SetAlpha(0)
			self.hover_alpha = 0
			self:ApplyFrameShape()
		elseif (state == "locked_in_unlocked_tier") then
			self:SetDesaturated(true)
			self:SetDesaturatedBorder(true)
			self.socket:SetDesaturated(true)
			self:SetIconAlpha(1.0)
			self:SetBorderAlpha(1)
			self:SetSocketAlpha(0.9)
			self.rank_text:SetTextColor(1, 1, 1)
			self.haze_tex:SetAlpha(0)
			self.hover_alpha = 0
			self:ApplyFrameShape()
		elseif (state == "available") then
   			self:SetDesaturated(false)
            self:SetDesaturatedBorder(false)
            self.socket:SetDesaturated(false)
			self:SetIconAlpha(1)
			self:SetBorderAlpha(1)
			self:SetSocketAlpha(1)
			self.rank_text:SetTextColor(1, 1, 1)
			self.haze_tex:SetAlpha(0.9)
			self.hover_alpha = 0.5
			if (self.is_exceptional) then
				self:SetBorder(TALENT_ASSETS .. "talent-frame-square-green")
			else
				self:SetBorder(TALENT_ASSETS .. "talent-frame-circle-green")
			end
        elseif (state == "partial") then
			self:SetDesaturated(false)
            self:SetDesaturatedBorder(false)
            self.socket:SetDesaturated(false)
			self:SetIconAlpha(1)
			self:SetBorderAlpha(1)
			self:SetSocketAlpha(1)
			self.rank_text:SetTextColor(1, 1, 1)
			self.haze_tex:SetAlpha(0.5)
			self.hover_alpha = 0.5
			if (self.is_exceptional) then
				self:SetBorder(TALENT_ASSETS .. "talent-frame-square-green")
			else
				self:SetBorder(TALENT_ASSETS .. "talent-frame-circle-green")
			end
		elseif (state == "maxed") then
			self:SetDesaturated(false)
            self:SetDesaturatedBorder(false)
            self.socket:SetDesaturated(false)
			self:SetIconAlpha(1)
			self:SetBorderAlpha(1)
			self:SetSocketAlpha(1)
			self.rank_text:SetTextColor(1, 1, 1)
			self.haze_tex:SetAlpha(0.5)
			self.hover_alpha = 0.5
			if (self.is_exceptional) then
				self:SetBorder(TALENT_ASSETS .. "talent-frame-square-gold")
			else
				self:SetBorder(TALENT_ASSETS .. "talent-frame-circle-gold")
			end
		end
	end;

	-- ================== POSITIONING ==============================

	SetGridPosition = function(self, row, col, offset_x, offset_y)
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT", self.frame:GetParent(), "TOPLEFT",
			offset_x + col * self.cell_size,
			-(offset_y + row * self.cell_size))
	end;

	-- =================== HAZE ====================================

	SetHazeColor = function(self, r, g, b)
		self.haze_tex:SetVertexColor(r, g, b)
	end;

	-- ===================== DELEGATION ============================

	Hide = function(self)
		self.frame:Hide()
	end;

	Show = function(self)
		self.frame:Show()
	end;
}
