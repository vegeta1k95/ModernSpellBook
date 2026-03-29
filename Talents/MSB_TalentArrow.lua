--[[
	CTalentArrow: Single texture segment of a prereq connection line.
	CTalentConnection: Full L-shaped prereq path (owns multiple arrows).
--]]

local TALENT_ASSETS = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\"

local ARROW_TEXTURES = {
	v           = TALENT_ASSETS .. "arrow-v",
	h           = TALENT_ASSETS .. "arrow-h",
	head_down   = TALENT_ASSETS .. "arrowhead-down",
	head_left   = TALENT_ASSETS .. "arrowhead-left",
	head_right  = TALENT_ASSETS .. "arrowhead-right",
}

--==============================================================================
--========================= Class "CTalentArrow" ===============================
--==============================================================================

class "CTalentArrow"
{
	__init = function(self, parent)
		self.frame = CreateFrame("Frame", nil, parent)
		self.frame:SetFrameLevel(parent:GetFrameLevel() + 2)
		self.tex = self.frame:CreateTexture(nil, "ARTWORK")
		self.tex:SetAllPoints(self.frame)
		self.frame:Hide()
	end;

	SetSegment = function(self, seg_type, x, y, w, h)
		self.tex:SetTexture(ARROW_TEXTURES[seg_type])
		self.frame:SetWidth(w)
		self.frame:SetHeight(h)
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOPLEFT", self.frame:GetParent(), "TOPLEFT", x, -y)
		self.frame:Show()
	end;

	SetAlpha = function(self, a)
		self.tex:SetAlpha(a)
	end;

	SetColor = function(self, r, g, b)
		self.tex:SetVertexColor(r, g, b)
	end;

	Hide = function(self)
		self.frame:Hide()
	end;

	Show = function(self)
		self.frame:Show()
	end;
}

--==============================================================================
--====================== Class "CTalentConnection" ============================
--==============================================================================

--[[
	Owns a pool of CTalentArrow segments that form one prereq path.
	Routes: straight down, down-then-horizontal, or horizontal-then-down.
--]]

class "CTalentConnection"
{
	__init = function(self, parent)
		self.parent = parent
		self.arrows = {}
		self.arrow_count = 0
		self.is_met = false
	end;

	-- =================== ARROW POOL ==============================

	GetArrow = function(self, index)
		if (not self.arrows[index]) then
			self.arrows[index] = CTalentArrow(self.parent)
		end
		return self.arrows[index]
	end;

	Clear = function(self)
		for i = 1, self.arrow_count do
			self.arrows[i]:Hide()
		end
		self.arrow_count = 0
	end;

	-- =================== ROUTING =================================

	BuildRoute = function(self, src_row, src_col, dst_row, dst_col, cell_size, offset_x, offset_y, occupied)
		self:Clear()
		self.routed_cells = {}

		-- Center coordinates of source and destination cells
		local src_cx = offset_x + src_col * cell_size + cell_size / 2
		local src_cy = offset_y + src_row * cell_size + cell_size / 2
		local dst_cx = offset_x + dst_col * cell_size + cell_size / 2
		local dst_cy = offset_y + dst_row * cell_size + cell_size / 2

		local arrow_width = 4
		local head_size = 10
		local icon_radius = 15 -- half of icon, avoid overlapping

		if (src_row == dst_row and src_col ~= dst_col) then
			-- Same row: pure horizontal
			local going_right = dst_col > src_col
			if (going_right) then
				local h_start = src_cx + icon_radius
				local h_end = dst_cx - icon_radius - head_size
				if (h_end > h_start) then
					self:AddHorizontalSegment(h_start, src_cy, h_end - h_start, arrow_width)
				end
				self:AddArrowhead("head_right", dst_cx - icon_radius - head_size, dst_cy, head_size)
			else
				local h_start = dst_cx + icon_radius + head_size
				local h_end = src_cx - icon_radius
				if (h_end > h_start) then
					self:AddHorizontalSegment(h_start, src_cy, h_end - h_start, arrow_width)
				end
				self:AddArrowhead("head_left", dst_cx + icon_radius + head_size, dst_cy, head_size)
			end
			-- Record horizontal cells
			local cmn = math.min(src_col, dst_col)
			local cmx = math.max(src_col, dst_col)
			for c = cmn + 1, cmx - 1 do
				table.insert(self.routed_cells, {r = src_row, c = c})
			end
		elseif (src_col == dst_col) then
			-- Straight vertical
			self:AddVerticalSegment(src_cx, src_cy + icon_radius, dst_cy - icon_radius - head_size, arrow_width)
			self:AddArrowhead("head_down", dst_cx, dst_cy - icon_radius - head_size, head_size)
			-- Record vertical cells
			for r = src_row + 1, dst_row - 1 do
				table.insert(self.routed_cells, {r = r, c = src_col})
			end
		elseif (dst_row > src_row) then
			local going_right = dst_col > src_col

			-- Helper: is cell blocked? (occupied by talent other than src/dst)
			local function isBlocked(r, c)
				if (r == src_row and c == src_col) then return false end
				if (r == dst_row and c == dst_col) then return false end
				return occupied and occupied[r .. "," .. c]
			end

			-- Check if down-then-horizontal is blocked
			-- Path: (src_row,src_col) -> down to (dst_row,src_col) -> right/left to (dst_row,dst_col)
			local down_first_blocked = false
			-- Vertical: all rows from src+1 to dst at src_col (including turn point at dst_row)
			for r = src_row + 1, dst_row do
				if (isBlocked(r, src_col)) then
					down_first_blocked = true
					break
				end
			end
			-- Horizontal: all cols between src_col and dst_col at dst_row
			if (not down_first_blocked) then
				local mn = math.min(src_col, dst_col)
				local mx = math.max(src_col, dst_col)
				for c = mn + 1, mx - 1 do
					if (isBlocked(dst_row, c)) then
						down_first_blocked = true
						break
					end
				end
			end

			-- Check if horizontal-then-down is blocked
			-- Path: (src_row,src_col) -> right/left to (src_row,dst_col) -> down to (dst_row,dst_col)
			local horiz_first_blocked = false
			-- Horizontal: all cols between src_col and dst_col at src_row (including turn point)
			local mn = math.min(src_col, dst_col)
			local mx = math.max(src_col, dst_col)
			for c = mn + 1, mx do
				if (isBlocked(src_row, c)) then
					horiz_first_blocked = true
					break
				end
			end
			-- Vertical: all rows from src+1 to dst-1 at dst_col
			if (not horiz_first_blocked) then
				for r = src_row + 1, dst_row - 1 do
					if (isBlocked(r, dst_col)) then
						horiz_first_blocked = true
						break
					end
				end
			end

			-- Pick the unblocked option (prefer down-first)
			local use_down_first = not down_first_blocked
			if (down_first_blocked and not horiz_first_blocked) then
				use_down_first = false
			elseif (down_first_blocked and horiz_first_blocked) then
				-- Both blocked, try down-first anyway (some visual is better than none)
				use_down_first = true
			end

			if (use_down_first) then
				-- Down from src to dst row, then horizontal to dst
				local turn_y = offset_y + dst_row * cell_size + cell_size / 2

				self:AddVerticalSegment(src_cx, src_cy + icon_radius, turn_y, arrow_width)

				if (going_right) then
					local h_start = src_cx
					local h_end = dst_cx - icon_radius - head_size
					if (h_end > h_start) then
						self:AddHorizontalSegment(h_start, turn_y, h_end - h_start, arrow_width)
					end
					self:AddArrowhead("head_right", dst_cx - icon_radius - head_size, dst_cy, head_size)
				else
					local h_start = dst_cx + icon_radius + head_size
					local h_end = src_cx
					if (h_end > h_start) then
						self:AddHorizontalSegment(h_start, turn_y, h_end - h_start, arrow_width)
					end
					self:AddArrowhead("head_left", dst_cx + icon_radius + head_size, dst_cy, head_size)
				end
				-- Record routed cells (vertical + horizontal)
				for r = src_row + 1, dst_row do
					table.insert(self.routed_cells, {r = r, c = src_col})
				end
				local cmn = math.min(src_col, dst_col)
				local cmx = math.max(src_col, dst_col)
				for c = cmn + 1, cmx - 1 do
					table.insert(self.routed_cells, {r = dst_row, c = c})
				end
			else
				-- Horizontal from src to dst col, then down to dst
				local turn_x = dst_cx

				if (going_right) then
					local h_start = src_cx + icon_radius
					local h_end = turn_x
					if (h_end > h_start) then
						self:AddHorizontalSegment(h_start, src_cy, h_end - h_start, arrow_width)
					end
				else
					local h_start = turn_x
					local h_end = src_cx - icon_radius
					if (h_end > h_start) then
						self:AddHorizontalSegment(h_start, src_cy, h_end - h_start, arrow_width)
					end
				end

				self:AddVerticalSegment(turn_x, src_cy, dst_cy - icon_radius - head_size, arrow_width)
				self:AddArrowhead("head_down", dst_cx, dst_cy - icon_radius - head_size, head_size)
				-- Record routed cells (horizontal + vertical)
				local cmn = math.min(src_col, dst_col)
				local cmx = math.max(src_col, dst_col)
				for c = cmn + 1, cmx do
					table.insert(self.routed_cells, {r = src_row, c = c})
				end
				for r = src_row + 1, dst_row - 1 do
					table.insert(self.routed_cells, {r = r, c = dst_col})
				end
			end
		end
	end;

	-- ================= SEGMENT HELPERS ============================

	AddVerticalSegment = function(self, cx, top_y, bottom_y, width)
		if (bottom_y <= top_y) then return end
		self.arrow_count = self.arrow_count + 1
		local arrow = self:GetArrow(self.arrow_count)
		arrow:SetSegment("v", cx - width / 2, top_y, width, bottom_y - top_y)
	end;

	AddHorizontalSegment = function(self, left_x, cy, seg_width, height)
		if (seg_width <= 0) then return end
		self.arrow_count = self.arrow_count + 1
		local arrow = self:GetArrow(self.arrow_count)
		arrow:SetSegment("h", left_x, cy - height / 2, seg_width, height)
	end;

	AddArrowhead = function(self, head_type, x, y, size)
		self.arrow_count = self.arrow_count + 1
		local arrow = self:GetArrow(self.arrow_count)
		if (head_type == "head_down") then
			arrow:SetSegment(head_type, x - size / 2, y, size, size)
		elseif (head_type == "head_right") then
			arrow:SetSegment(head_type, x, y - size / 2, size, size)
		elseif (head_type == "head_left") then
			arrow:SetSegment(head_type, x - size, y - size / 2, size, size)
		end
	end;

	-- ================== VISUAL STATE =============================

	UpdateState = function(self, is_met)
		self.is_met = is_met
		for i = 1, self.arrow_count do
			if (is_met) then
				self.arrows[i]:SetColor(1, 0.82, 0)
				self.arrows[i]:SetAlpha(1.0)
			else
				self.arrows[i]:SetColor(1, 1, 1)
				self.arrows[i]:SetAlpha(0.4)
			end
		end
	end;
}
