--[[
	Category header: spec icon + category name + separator.
--]]

local VERTICAL_SPACING = 50
local SECOND_PAGE_OFFSET = 510
local HORIZONTAL_OFFSET = 40

class "CCategoryItem"
{
	__init = function(self, parent)
		self.frame = CreateFrame("Frame", nil, parent)
		self.frame:SetWidth(450)
		self.frame:SetHeight(20)

		-- Spec icon next to category name
		self.specIconFrame = CreateFrame("Frame", nil, self.frame)
		self.specIconFrame:SetWidth(22)
		self.specIconFrame:SetHeight(22)
		self.specIconFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, 1)
		self.specIconFrame:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 8,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }
		})
		self.specIconFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

		self.specIcon = self.specIconFrame:CreateTexture(nil, "OVERLAY")
		self.specIcon:SetWidth(18)
		self.specIcon:SetHeight(18)
		self.specIcon:SetPoint("CENTER", self.specIconFrame, "CENTER", 0, 0)
		self.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		self.text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.text:SetPoint("LEFT", self.specIconFrame, "RIGHT", 5, 0)
		self.text:SetTextColor(0, 0, 0)
		self.text:SetShadowOffset(0, 0)
		self.text:SetFont("Fonts\\FRIZQT__.TTF", 17)

		self.lightBorder = self.frame:CreateTexture(nil, "OVERLAY")
		self.lightBorder:SetWidth(500)
		self.lightBorder:SetHeight(90)
		self.lightBorder:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -170, 35)
		self.lightBorder:SetTexture("Interface\\Glues\\Models\\UI_Tauren\\gradientcircle")
		self.lightBorder:SetBlendMode("ADD")
		self.lightBorder:SetDrawLayer("OVERLAY", -2)
		self.lightBorder:SetAlpha(0.15)

		self.separator = self.frame:CreateTexture(nil, "OVERLAY")
		self.separator:SetWidth(400)
		self.separator:SetHeight(10)
		self.separator:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -30)
		self.separator:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\separator")
	end;

	-- ========================= SET ===============================

	Set = function(self, categoryName, currentPageRows, page)
		self.text:SetText(categoryName)

		-- Look up spec icon from talent tabs or spell tabs
		local specIconFound = false
		for t = 1, GetNumTalentTabs() do
			local tabName, tabIcon = GetTalentTabInfo(t)
			if (tabName == categoryName) then
				self.specIcon:SetTexture(tabIcon)
				specIconFound = true
				break
			end
		end
		if (not specIconFound) then
			local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
			for t = 1, numTabs do
				local tabName, tabIcon = GetSpellTabInfo(t)
				if (tabName == categoryName and tabIcon) then
					self.specIcon:SetTexture(tabIcon)
					specIconFound = true
					break
				end
			end
		end
		if (not specIconFound) then
			self.specIconFrame:Hide()
			self.text:SetPoint("LEFT", self.specIconFrame, "LEFT", 0, 0)
		else
			self.specIconFrame:Show()
			self.text:SetPoint("LEFT", self.specIconFrame, "RIGHT", 5, 0)
		end

		self.frame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", HORIZONTAL_OFFSET +SECOND_PAGE_OFFSET*(page -1), -80 +currentPageRows *-VERTICAL_SPACING -5)
		self.frame:Show()
	end;

	-- ====================== DELEGATION ===========================

	Hide = function(self)
		self.frame:Hide()
	end;

	Show = function(self)
		self.frame:Show()
	end;
}

-- ============================================================
-- Pool factories
-- ============================================================

local totalSpellItems = 0
local totalCategoryItems = 0

function ModernSpellBookFrame:CleanPages()
	for i = 1, totalSpellItems do
		ModernSpellBookFrame["Spell".. i]:Hide()
	end
	for i = 1, totalCategoryItems do
		ModernSpellBookFrame["Category".. i]:Hide()
	end
end

function ModernSpellBookFrame:GetOrCreateCategory(i)
	local item = ModernSpellBookFrame["Category".. i]
	if (item ~= nil) then
		return item
	end
	totalCategoryItems = totalCategoryItems + 1
	item = CCategoryItem(ModernSpellBookFrame)
	ModernSpellBookFrame["Category".. i] = item
	return item
end

function ModernSpellBookFrame:GetOrCreateSpellItem(i)
	local item = ModernSpellBookFrame["Spell".. i]
	if (item ~= nil) then
		return item
	end
	totalSpellItems = totalSpellItems + 1
	item = CSpellItem(ModernSpellBookFrame, i)
	ModernSpellBookFrame["Spell".. i] = item
	return item
end
