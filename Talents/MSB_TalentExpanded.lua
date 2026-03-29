--[[
	CExpandedSpecFrame: Expanded spec detail view.
	Shows spec info (name, description, key abilities) on the left
	and the full talent grid on the right.
--]]

local TALENT_ASSETS = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\"

class "CExpandedSpecFrame"
{
	__init = function(self, parent, constants)
		self.parent_tree = nil -- set externally after creation
		self.constants = constants

		self.frame = CreateFrame("Frame", nil, parent)
		self.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
		self.frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
		self.frame:Hide()

		-- Right-click to go back
		self.frame:EnableMouse(true)
		self.frame:RegisterForDrag("LeftButton")
		self.frame:SetScript("OnDragStart", function()
			if (self.parent_tree) then
				self.parent_tree.frame:StartMoving()
			end
		end)
		self.frame:SetScript("OnDragStop", function()
			if (self.parent_tree) then
				self.parent_tree.frame:StopMovingOrSizing()
				local point, _, relPoint, x, y = self.parent_tree.frame:GetPoint()
				ModernSpellBook_DB.talentPosition = { point = point, relPoint = relPoint, x = x, y = y }
			end
		end)
		self.frame:SetScript("OnMouseUp", function()
			if (arg1 == "RightButton" and self.parent_tree) then
				self.parent_tree:CollapseSpec()
			end
		end)
	end;

	Show = function(self, spec, specIndex, haze_colors)
		local c = self.constants
		local _, englishClass = UnitClass("player")
		local expW = c.TOTAL_WIDTH - 16
		local expH = c.TOTAL_HEIGHT - 16

		-- Clear previous content
		local children = {self.frame:GetChildren()}
		for _, child in ipairs(children) do
			child:Hide()
		end
		local regions = {self.frame:GetRegions()}
		for _, region in ipairs(regions) do
			region:Hide()
		end

		-- Full background (two 512x512 halves)
		local bgBase = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\Backgrounds\\talentbg-" .. string.lower(englishClass) .. "-" .. specIndex
		local bgLeft = self.frame:CreateTexture(nil, "ARTWORK")
		bgLeft:SetTexture(bgBase .. "-left")
		bgLeft:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
		bgLeft:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
		bgLeft:SetWidth(expW / 2)
		bgLeft:Show()
		local bgRight = self.frame:CreateTexture(nil, "ARTWORK")
		bgRight:SetTexture(bgBase .. "-right")
		bgRight:SetPoint("TOPLEFT", bgLeft, "TOPRIGHT", 0, 0)
		bgRight:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
		bgRight:Show()

		-- Layout
		local gridW = c.GRID_COLS_DEFAULT * c.CELL_SIZE + 20
		local leftColW = c.EXPANDED_HORIZONTAL_PADDING * 2

		local leftCol = CreateFrame("Frame", nil, self.frame)
		leftCol:SetWidth(leftColW)
		leftCol:SetHeight(expH)
		leftCol:SetPoint("CENTER", self.frame, "LEFT", c.EXPANDED_HORIZONTAL_PADDING, 0)

		-- Spec name
		local specName = leftCol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		specName:SetPoint("TOP", leftCol, "TOP", 0, -40)
		specName:SetFont("Fonts\\FRIZQT__.TTF", 22)
		specName:SetText(string.upper(spec.tab_name))
		specName:SetTextColor(1, 1, 1)
		specName:SetJustifyH("CENTER")
		specName:Show()

		-- Spec description
		local descTable = c.SPEC_DESCRIPTIONS[englishClass]
		local descText = descTable and descTable[specIndex] or ""
		local specDesc = leftCol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		specDesc:SetPoint("TOP", specName, "BOTTOM", 0, -30)
		specDesc:SetFont("Fonts\\FRIZQT__.TTF", 16)
		specDesc:SetText(descText)
		specDesc:SetTextColor(1, 1, 1)
		specDesc:SetJustifyH("CENTER")
		specDesc:SetWidth(400)
		if (specDesc.SetWordWrap) then specDesc:SetWordWrap(true) end
		specDesc:Show()

		-- Create talent grid early so we can query its data for key abilities
		local _, _, pointsSpent = GetTalentTabInfo(spec.tab_index)
		local gridH = c.GRID_ROWS * c.CELL_SIZE + 20
		local gridContainer = CreateFrame("Frame", nil, self.frame)
		gridContainer:SetWidth(gridW)
		gridContainer:SetHeight(gridH)
		gridContainer:SetPoint("CENTER", self.frame, "RIGHT", -c.EXPANDED_HORIZONTAL_PADDING, 0)

		local hazeColor = (haze_colors and haze_colors[specIndex]) or {0.2, 0.2, 0.4}
		self.grid = CTalentGrid(gridContainer, spec.tab_index, c.CELL_SIZE, 10, 10, hazeColor, c.GRID_ROWS)

		-- Key Abilities header
		local abilitiesHeader = leftCol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		abilitiesHeader:SetPoint("TOP", specDesc, "BOTTOM", 0, -30)
		abilitiesHeader:SetFont("Fonts\\FRIZQT__.TTF", 18)
		abilitiesHeader:SetText("KEY ABILITIES")
		abilitiesHeader:SetTextColor(1, 1, 1)
		abilitiesHeader:SetJustifyH("CENTER")
		abilitiesHeader:Show()

		-- Select key abilities: last exceptional from rows 3, 5, 7
		-- Prefer outgoing arrows > incoming > none
		local hasOutgoing = {}
		local hasIncoming = {}
		for _, talent in ipairs(self.grid.icons) do
			if (talent.prereq_tier) then
				hasIncoming[talent.tier .. "," .. talent.column] = true
				hasOutgoing[talent.prereq_tier .. "," .. talent.prereq_column] = true
			end
		end
		local showcase = {}
		local showcaseRows = {3, 5, 7}
		for _, targetRow in ipairs(showcaseRows) do
			local pick = nil
			local pickScore = 0
			for _, talent in ipairs(self.grid.exceptional_talents) do
				if (talent.tier == targetRow) then
					local key = talent.tier .. "," .. talent.column
					local score = 1
					if (hasIncoming[key]) then score = 2 end
					if (hasOutgoing[key]) then score = 3 end
					if (score > pickScore) then
						pick = talent
						pickScore = score
					end
				end
			end
			if (not pick) then
				local bestRank = 999
				for _, talent in ipairs(self.grid.icons) do
					if (talent.tier == targetRow and talent.max_rank < bestRank) then
						bestRank = talent.max_rank
						pick = talent
					end
				end
			end
			if (pick) then
				table.insert(showcase, pick)
			end
		end

		-- Render key abilities
		local count = 0
		for _, talent in ipairs(showcase) do
			count = count + 1

			local row = CreateFrame("Frame", nil, leftCol)
			row:SetWidth(200)
			row:SetHeight(c.CELL_SIZE)
			row:SetPoint("TOP", abilitiesHeader, "BOTTOM", 0, -(count - 1) * (c.CELL_SIZE + 5) - 20)

			-- Tier lock indicator
			local tierReq = (talent.tier - 1) * 5
			local lockText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lockText:SetFont("Fonts\\FRIZQT__.TTF", 16)
			lockText:SetTextColor(190/255, 136/255, 121/255)
			lockText:SetWidth(40)
			lockText:SetJustifyH("RIGHT")
			lockText:SetPoint("LEFT", row, "LEFT", -130, 0)
			lockText:SetText(tierReq - pointsSpent)

			local lockTex = row:CreateTexture(nil, "OVERLAY")
			lockTex:SetWidth(138)
			lockTex:SetHeight(16)
			lockTex:SetTexture(TALENT_ASSETS .. "tier-lock")
			lockTex:SetPoint("LEFT", lockText, "RIGHT", 6, 0)

			if (pointsSpent >= tierReq) then
				lockText:SetAlpha(0)
				lockTex:SetAlpha(0)
			else
				lockText:SetAlpha(1)
				lockTex:SetAlpha(1)
			end

			-- Talent icon
			local icon = CTalentIcon(row, c.CELL_SIZE)
			icon:SetTalentData(talent.talent_tab, talent.talent_index)
			if (icon.curr_rank >= icon.max_rank) then
				if (icon.is_exceptional) then
					icon.border:SetTexture(TALENT_ASSETS .. "talent-frame-square-gold")
				else
					icon.border:SetTexture(TALENT_ASSETS .. "talent-frame-circle-gold")
				end
			end
			icon.frame:SetPoint("LEFT", lockTex, "RIGHT", -40, 0)
			icon.frame:RegisterForClicks()
			icon.frame:SetScript("OnClick", nil)
			local hazeColor = (haze_colors and haze_colors[specIndex]) or {0.2, 0.2, 0.4}
			icon:SetHazeColor(hazeColor[1], hazeColor[2], hazeColor[3])
			icon.haze_tex:SetAlpha(1.0)

			local abilName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			abilName:SetPoint("LEFT", icon.frame, "RIGHT", 8, 0)
			abilName:SetFont("Fonts\\FRIZQT__.TTF", 12)
			abilName:SetText(talent.talent_name)
			abilName:SetTextColor(1, 1, 1)
		end

		-- Points invested title
		local pointsTitle = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		pointsTitle:SetFont("Fonts\\FRIZQT__.TTF", 22)
		if (pointsSpent > 0) then
			pointsTitle:SetText("|cff00ff00" .. pointsSpent .. "|r TALENT POINTS INVESTED")
		else
			pointsTitle:SetText("|cff808080" .. pointsSpent .. "|r TALENT POINTS INVESTED")
		end
		pointsTitle:SetTextColor(1, 1, 1)
		pointsTitle:SetJustifyH("CENTER")

		-- Refresh grid state
		local totalAvailable = UnitLevel("player") - 9
		if (totalAvailable < 0) then totalAvailable = 0 end
		local totalSpent = 0
		for _, s in ipairs(self.parent_tree.specs) do
			local _, _, sp = GetTalentTabInfo(s.tab_index)
			totalSpent = totalSpent + sp
		end
		local remaining = totalAvailable - totalSpent
		self.grid:Refresh(pointsSpent, remaining)

		-- Align titles
		pointsTitle:SetPoint("TOP", gridContainer, "TOP", 0, 30)
		specName:ClearAllPoints()
		specName:SetPoint("TOP", pointsTitle, "TOP", 0, 0)
		specName:SetPoint("LEFT", leftCol, "LEFT", 0, 0)
		specName:SetPoint("RIGHT", leftCol, "RIGHT", 0, 0)

		self.frame:Show()
	end;

	Hide = function(self)
		if (self.grid) then
			self.grid:Hide()
			self.grid = nil
		end
		self.frame:Hide()
	end;
}
