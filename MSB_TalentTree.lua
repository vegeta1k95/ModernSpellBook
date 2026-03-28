--[[
	CTalentTree: Top-level talent tree window.
	Standalone test window opened via /msbt.
	Shows 3 spec panels side by side with CTalentIcon grid.
--]]

local CELL_SIZE = 60
local GRID_COLS_DEFAULT = 4
local GRID_COLS_MAX = 7
local GRID_ROWS = 7
local PANEL_PADDING = 20
local HEADER_HEIGHT = 40
local PANEL_INNER_PAD = 10
local FRAME_PAD = PANEL_PADDING + 10
local PANEL_WIDTH = GRID_COLS_MAX * CELL_SIZE + PANEL_INNER_PAD * 2
local GRID_VERT_PAD = 10
local PANEL_HEIGHT = GRID_ROWS * CELL_SIZE + HEADER_HEIGHT + GRID_VERT_PAD * 2 + 20
local TOTAL_WIDTH = 3 * PANEL_WIDTH + 4 * PANEL_PADDING + 20
local TOTAL_HEIGHT = PANEL_HEIGHT + 120
local VERT_OFFSET = (TOTAL_HEIGHT - PANEL_HEIGHT) / 2

-- Indexed by english class name then specIndex (1-3)
local SPEC_HAZE_COLORS = {
	WARRIOR = {{0.959, 0.959, 0.967}, {1.0, 0.458, 0.010}, {0.208, 0.543, 0.835}},  -- Arms, Fury, Protection
	PALADIN = {{0.994, 0.914, 0.076}, {0.365, 0.580, 1.0}, {0.563, 0.255, 0.902}},  -- Holy, Protection, Retribution
	HUNTER  = {{0.441, 0.845, 0.249}, {0.110, 0.600, 0.800}, {0.996, 0.796, 0.196}},  -- Beast Mastery, Marksmanship, Survival
	ROGUE   = {{0.288, 1.0, 0.237}, {0.886, 0.382, 0.371}, {0.547, 0.657, 1.0}},  -- Assassination, Combat, Subtlety
	PRIEST  = {{1.0, 1.0, 1.0}, {0.949, 0.976, 0.235}, {0.537, 0.322, 1.000}},  -- Discipline, Holy, Shadow
	SHAMAN  = {{0.416, 0.569, 1.0}, {1.0, 0.534, 0.150}, {0.414, 1.0, 0.471}},  -- Elemental, Enhancement, Restoration
	MAGE    = {{0.853, 0.545, 1.0}, {1.0, 0.620, 0.069}, {0.035, 0.580, 1.0}},  -- Arcane, Fire, Frost
	WARLOCK = {{0.306, 0.925, 0.153}, {0.925, 0.608, 0.978}, {0.914, 0.347, 0.173}},  -- Affliction, Demonology, Destruction
	DRUID   = {{0.767, 0.508, 0.857}, {0.110, 0.878, 0.922}, {0.249, 0.996, 0.288}},  -- Balance, Feral Combat, Restoration
}
local DEFAULT_HAZE_COLOR = {0.2, 0.2, 0.4}

class "CTalentTree"
{
	__init = function(self)
		local panel_width = PANEL_WIDTH
		local total_width = TOTAL_WIDTH
		local total_height = TOTAL_HEIGHT

		-- Main frame
		self.frame = CreateFrame("Frame", "ModernTalentTreeFrame", UIParent)
		self.frame:SetWidth(total_width)
		self.frame:SetHeight(total_height)
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		self.frame:SetFrameStrata("HIGH")
		self.frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		self.frame:SetBackdropColor(0.03, 0.03, 0.06, 0.97)
		self.frame:EnableMouse(true)
		self.frame:SetMovable(true)
		self.frame:RegisterForDrag("LeftButton")
		self.frame:SetScript("OnDragStart", function() this:StartMoving() end)
		self.frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
		self.frame:Hide()
		table.insert(UISpecialFrames, "ModernTalentTreeFrame")

		-- Close button
		local close = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)

		-- Title
		self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.title:SetPoint("TOP", self.frame, "TOP", 0, -24)
		self.title:SetFont("Fonts\\MORPHEUS.TTF", 16)
		self.title:SetTextColor(1, 0.82, 0)

		-- Points display
		self.points_text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.points_text:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 30)
		self.points_text:SetFont("Fonts\\FRIZQT__.TTF", 14)
		self.points_text:SetTextColor(1.0, 1.0, 1.0)

		-- Slash command
		SLASH_MSBT1 = "/msbt"
		local tree = self
		SlashCmdList["MSBT"] = function()
			tree:Toggle()
		end

		-- Event handling
		self.event_frame = CreateFrame("Frame")
		self.event_frame:RegisterEvent("PLAYER_TALENT_UPDATE")
		self.event_frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
		self.event_frame:SetScript("OnEvent", function()
			if (tree.frame:IsVisible()) then
				tree:Refresh()
			end
		end)

		self.specs = {}
		self.built = false
	end;

	-- ======================== TOGGLE =============================

	Toggle = function(self)
		if (self.frame:IsVisible()) then
			self.frame:Hide()
		else
			if (not self.built) then
				self:BuildSpecs()
				self.built = true
			end
			self:Refresh()
			self.frame:Show()
		end
	end;

	-- ===================== BUILD SPECS ===========================

	BuildSpecs = function(self)
		local className = UnitClass("player")
		self.title:SetText(className .. " Talents")

		local numTabs = GetNumTalentTabs()
		-- Offset to center 4-col layout within 7-col panel
		local col_offset = (GRID_COLS_MAX - GRID_COLS_DEFAULT) * CELL_SIZE / 2

		for t = 1, numTabs do
			local tabName, tabIcon, pointsSpent = GetTalentTabInfo(t)
			local numTalents = GetNumTalents(t)

			-- Spec panel container
			local panel = CreateFrame("Frame", nil, self.frame)
			panel:SetWidth(PANEL_WIDTH)
			panel:SetHeight(PANEL_HEIGHT)
			panel:SetPoint("TOPLEFT", self.frame, "TOPLEFT",
				FRAME_PAD + (t - 1) * (PANEL_WIDTH + PANEL_PADDING), -VERT_OFFSET)
			panel:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 12,
				insets = { left = 3, right = 3, top = 3, bottom = 3 }
			})
			panel:SetBackdropColor(0.06, 0.06, 0.1, 0.9)

			-- Spec background texture (right-cropped to fit panel)
			local _, englishClass = UnitClass("player")
			local bgPath = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\Backgrounds\\talentbg-" .. string.lower(englishClass) .. "-" .. t
			local bgTex = panel:CreateTexture(nil, "ARTWORK")
			bgTex:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
			bgTex:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
			bgTex:SetTexture(bgPath)
            bgTex:SetAlpha(0.6)
			-- Texture is 1024x512 (2:1). Scale to fit panel height, crop left.
			local scaledWidth = PANEL_HEIGHT * 2
			local visibleFraction = PANEL_WIDTH / scaledWidth
			local leftCrop = 1 - visibleFraction
			bgTex:SetTexCoord(leftCrop, 1, 0, 1)


			-- Spec header
			local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			header:SetPoint("TOP", panel, "TOP", 0, -12)
			header:SetFont("Fonts\\FRIZQT__.TTF", 14)
			header:SetText(string.upper(tabName))
			header:SetTextColor(1, 1, 1)

			-- Points counter
			local ptsText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			ptsText:SetPoint("TOP", header, "BOTTOM", 0, -4)
			ptsText:SetFont("Fonts\\FRIZQT__.TTF", 12)
			ptsText:SetTextColor(0.6, 0.6, 0.6)

			-- Tier lock icon (shown at first locked tier, updated in Refresh)
			local tierLock = CreateFrame("Frame", nil, panel)
			tierLock:SetWidth(138)
			tierLock:SetHeight(16)
			tierLock:SetFrameLevel(panel:GetFrameLevel() + 5)
			local tierLockTex = tierLock:CreateTexture(nil, "OVERLAY")
			tierLockTex:SetAllPoints(tierLock)
			tierLockTex:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\tier-lock")
			tierLock:Hide()

			local tierLockText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			tierLockText:SetFont("Fonts\\FRIZQT__.TTF", 16)
			tierLockText:SetTextColor(190/255, 136/255, 121/255)
			tierLockText:SetPoint("RIGHT", tierLock, "LEFT", -2, 0)
			tierLockText:Hide()

			-- Create talent icons
			local icons = {}
			local _, englishClass = UnitClass("player")
			local classColors = SPEC_HAZE_COLORS[englishClass]
			local haze_color = (classColors and classColors[t]) or DEFAULT_HAZE_COLOR

			for i = 1, numTalents do
				local name = GetTalentInfo(t, i)
				if (name) then
					local talent = CTalentIcon(panel, CELL_SIZE)
					talent:SetTalentData(t, i)
					talent:SetGridPosition(
						talent.tier - 1,
						talent.column - 1,
						PANEL_INNER_PAD + col_offset,
						HEADER_HEIGHT + GRID_VERT_PAD)
					talent:SetHazeColor(haze_color[1], haze_color[2], haze_color[3])

					table.insert(icons, talent)
				end
			end

			-- Build occupied cell map for routing
			local occupied = {}
			for _, talent in ipairs(icons) do
				occupied[(talent.tier - 1) .. "," .. (talent.column - 1)] = true
			end

			-- Build prereq connections
			local connections = {}
			for _, talent in ipairs(icons) do
				if (talent.prereq_tier and talent.prereq_column) then
					local conn = CTalentConnection(panel)
					conn:BuildRoute(
						talent.prereq_tier - 1,
						talent.prereq_column - 1,
						talent.tier - 1,
						talent.column - 1,
						CELL_SIZE,
						PANEL_INNER_PAD + col_offset,
						HEADER_HEIGHT + GRID_VERT_PAD,
						occupied)
					table.insert(connections, {
						connection = conn,
						prereq_tier = talent.prereq_tier,
						prereq_column = talent.prereq_column,
						target = talent,
					})
				end
			end

			table.insert(self.specs, {
				panel = panel,
				header = header,
				points_text = ptsText,
				icons = icons,
				connections = connections,
				tier_lock = tierLock,
				tier_lock_text = tierLockText,
				tab_index = t,
			})
		end
	end;

	-- ====================== REFRESH ==============================

	Refresh = function(self)
		local totalSpent = 0
		local totalAvailable = UnitLevel("player") - 9
		if (totalAvailable < 0) then totalAvailable = 0 end

		for _, spec in ipairs(self.specs) do
			local _, _, pointsSpent = GetTalentTabInfo(spec.tab_index)
			spec.points_text:SetText(pointsSpent .. " points")
			totalSpent = totalSpent + pointsSpent
		end

		local remaining = totalAvailable - totalSpent

		for _, spec in ipairs(self.specs) do
			local _, _, pointsSpent = GetTalentTabInfo(spec.tab_index)

			-- Build prereq checker: returns true if talent at (tier, column) is maxed
			local function checkPrereq(tier, column)
				for _, talent in ipairs(spec.icons) do
					if (talent.tier == tier and talent.column == column) then
						return talent.curr_rank == talent.max_rank
					end
				end
				return false
			end

			for _, talent in ipairs(spec.icons) do
				talent:RefreshRank()
				talent:UpdateVisualState(pointsSpent, checkPrereq, remaining)
			end

			-- Update connection arrow states
			-- Golden only when prereq is maxed AND target is invested or investable
			for _, connData in ipairs(spec.connections) do
				local prereq_maxed = checkPrereq(connData.prereq_tier, connData.prereq_column)
				local target_state = connData.target.visual_state
				local unlocked = prereq_maxed and (target_state ~= "locked_in_locked_tier" and target_state ~= "locked_in_unlocked_tier")
				connData.connection:UpdateState(unlocked)
			end

			-- Position tier lock at first locked tier
			-- Hide lock entirely at max level with no points remaining
			local col_offset = (GRID_COLS_MAX - GRID_COLS_DEFAULT) * CELL_SIZE / 2
			local firstLockedTier = nil
			local is_max_no_points = (UnitLevel("player") >= 60 and remaining <= 0)
			if (not is_max_no_points) then
				for tier = 1, GRID_ROWS do
					if (pointsSpent < (tier - 1) * 5) then
						firstLockedTier = tier
						break
					end
				end
			end
			if (firstLockedTier) then
				local pointsNeeded = (firstLockedTier - 1) * 5 - pointsSpent
				spec.tier_lock_text:ClearAllPoints()
				spec.tier_lock_text:SetPoint("LEFT", spec.panel, "TOPLEFT",
					PANEL_INNER_PAD,
					-(HEADER_HEIGHT + GRID_VERT_PAD + (firstLockedTier - 1) * CELL_SIZE + CELL_SIZE / 2))
				spec.tier_lock_text:SetText(pointsNeeded)
				spec.tier_lock_text:Show()
				spec.tier_lock:ClearAllPoints()
				spec.tier_lock:SetPoint("LEFT", spec.tier_lock_text, "RIGHT", 4, 0)
				spec.tier_lock:Show()
			else
				spec.tier_lock:Hide()
				spec.tier_lock_text:Hide()
			end
		end

		if (remaining > 0) then
			self.points_text:SetText("|cff00ff00" .. remaining .. "|r TALENT POINT AVAILABLE")
		else
			self.points_text:SetText("NO TALENT POINTS AVAILABLE")
		end
	end;
}

TalentTree = CTalentTree()
