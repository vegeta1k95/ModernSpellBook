--[[
	CTalentGrid: A self-contained talent icon grid for one spec tab.
	Creates its own CTalentIcon instances and CTalentConnection arrows.
	Can be instantiated multiple times (overview panels, expanded view, etc.)
--]]

local TALENT_ASSETS = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\"

class "CTalentGrid"
{
	__init = function(self, parent, tab_index, cell_size, offset_x, offset_y, haze_color, grid_rows)
		self.parent = parent
		self.tab_index = tab_index
		self.cell_size = cell_size
		self.offset_x = offset_x
		self.offset_y = offset_y
		self.grid_rows = grid_rows or 7

		-- Create talent icons
		self.icons = {}
		self.exceptional_talents = {}
		local numTalents = GetNumTalents(tab_index)

		for i = 1, numTalents do
			local name = GetTalentInfo(tab_index, i)
			if (name) then
				local talent = CTalentIcon(parent, cell_size)
				talent:SetTalentData(tab_index, i)
				talent:SetGridPosition(
					talent.tier - 1,
					talent.column - 1,
					offset_x, offset_y)
				if (haze_color) then
					talent:SetHazeColor(haze_color[1], haze_color[2], haze_color[3])
				end
				table.insert(self.icons, talent)
				if (talent.is_exceptional) then
					table.insert(self.exceptional_talents, talent)
				end
			end
		end

		-- Mark bottom-most talent as final
		local maxTier = 0
		for _, talent in ipairs(self.icons) do
			if (talent.tier > maxTier) then maxTier = talent.tier end
		end
		for _, talent in ipairs(self.icons) do
			if (talent.tier == maxTier) then
				talent.is_final = true
				talent:ApplyFrameShape()
			end
		end

		-- Build connections
		self.connections = {}
		self:RebuildConnections()

		-- Tier lock
		self.tier_lock = CreateFrame("Frame", nil, parent)
		self.tier_lock:SetWidth(138)
		self.tier_lock:SetHeight(16)
		self.tier_lock:SetFrameLevel(parent:GetFrameLevel() + 5)
		local tierLockTex = self.tier_lock:CreateTexture(nil, "OVERLAY")
		tierLockTex:SetAllPoints(self.tier_lock)
		tierLockTex:SetTexture(TALENT_ASSETS .. "tier-lock")
		self.tier_lock:Hide()

		self.tier_lock_text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.tier_lock_text:SetFont("Fonts\\FRIZQT__.TTF", 16)
		self.tier_lock_text:SetTextColor(190/255, 136/255, 121/255)
		self.tier_lock_text:SetPoint("RIGHT", self.tier_lock, "LEFT", -2, 0)
		self.tier_lock_text:Hide()
	end;

	RebuildConnections = function(self)
		-- Clear old
		for _, connData in ipairs(self.connections) do
			connData.connection:Clear()
		end

		-- Build occupied map
		local occupied = {}
		for _, talent in ipairs(self.icons) do
			occupied[(talent.tier - 1) .. "," .. (talent.column - 1)] = true
		end

		-- Sort edges: straight first, then L-shapes
		local edges = {}
		for _, talent in ipairs(self.icons) do
			if (talent.prereq_tier and talent.prereq_column) then
				table.insert(edges, talent)
			end
		end
		table.sort(edges, function(a, b)
			local a_straight = (a.prereq_column == a.column) and 0 or 1
			local b_straight = (b.prereq_column == b.column) and 0 or 1
			return a_straight < b_straight
		end)

		self.connections = {}
		for _, talent in ipairs(edges) do
			local conn = CTalentConnection(self.parent)
			conn:BuildRoute(
				talent.prereq_tier - 1,
				talent.prereq_column - 1,
				talent.tier - 1,
				talent.column - 1,
				self.cell_size,
				self.offset_x,
				self.offset_y,
				occupied)
			if (conn.routed_cells) then
				for _, cell in ipairs(conn.routed_cells) do
					occupied[cell.r .. "," .. cell.c] = true
				end
			end
			table.insert(self.connections, {
				connection = conn,
				prereq_tier = talent.prereq_tier,
				prereq_column = talent.prereq_column,
				target = talent,
			})
		end
	end;

	Refresh = function(self, pointsSpent, remaining)
		-- Prereq checker
		local function checkPrereq(tier, column)
			for _, talent in ipairs(self.icons) do
				if (talent.tier == tier and talent.column == column) then
					return talent.curr_rank == talent.max_rank
				end
			end
			return false
		end

		for _, talent in ipairs(self.icons) do
			talent:RefreshRank()
			talent:UpdateVisualState(pointsSpent, checkPrereq, remaining)
		end

		-- Arrow states
		for _, connData in ipairs(self.connections) do
			local prereq_maxed = checkPrereq(connData.prereq_tier, connData.prereq_column)
			local target_state = connData.target.visual_state
			local unlocked = prereq_maxed and (target_state ~= "locked_in_locked_tier" and target_state ~= "locked_in_unlocked_tier")
			connData.connection:UpdateState(unlocked)
		end

		-- Tier lock
		local firstLockedTier = nil
		local is_max_no_points = (UnitLevel("player") >= 60 and remaining <= 0)
		if (not is_max_no_points) then
			for tier = 1, self.grid_rows do
				if (pointsSpent < (tier - 1) * 5) then
					firstLockedTier = tier
					break
				end
			end
		end
		if (firstLockedTier) then
			local pointsNeeded = (firstLockedTier - 1) * 5 - pointsSpent
			self.tier_lock_text:ClearAllPoints()
			self.tier_lock_text:SetPoint("LEFT", self.parent, "TOPLEFT",
				self.offset_x - 90,
				-(self.offset_y + (firstLockedTier - 1) * self.cell_size + self.cell_size / 2))
			self.tier_lock_text:SetText(pointsNeeded)
			self.tier_lock_text:Show()
			self.tier_lock:ClearAllPoints()
			self.tier_lock:SetPoint("LEFT", self.tier_lock_text, "RIGHT", 5, 0)
			self.tier_lock:Show()
		else
			self.tier_lock:Hide()
			self.tier_lock_text:Hide()
		end
	end;

	Hide = function(self)
		for _, talent in ipairs(self.icons) do
			talent.frame:Hide()
		end
		for _, connData in ipairs(self.connections) do
			connData.connection:Clear()
		end
		self.tier_lock:Hide()
		self.tier_lock_text:Hide()
	end;

	Show = function(self)
		for _, talent in ipairs(self.icons) do
			talent.frame:Show()
		end
	end;
}
