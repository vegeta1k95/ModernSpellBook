--[[
	Tab button for the spellbook: class, general, pet, custom.
--]]

-- Tab colors
local disabledVertexColor = {0.5, 0.5, 0.5, 1}
local enabledVertexColor = {1, 1, 1, 1}
local normalFontColor = {1, 0.82, 0}
local highlightFontColor = {1, 1, 1}
local disabledFontColor = {0.5, 0.41, 0}

class "CTab"
{
	__init = function(self, parent, name, tabNumber, onClickCallback)
		self.tab_number = tabNumber
		self.name = name

		self.frame = CreateFrame("Button", "ModernSpellBookFrame_Tab".. tabNumber, parent)
		self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
		self.frame:SetHighlightTexture("Interface\\Spellbook\\UI-SpellBook-Tab1-Selected")

		local tabText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		tabText:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
		self.frame:SetFontString(tabText)

		self:SetName(name)

		if (tabNumber == 1) then
			self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
			self.frame:GetNormalTexture():SetVertexColor(unpack(enabledVertexColor))
			self.frame:GetFontString():SetTextColor(unpack(normalFontColor))
		else
			self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
			self.frame:GetNormalTexture():SetVertexColor(unpack(disabledVertexColor))
			self.frame:GetFontString():SetTextColor(unpack(disabledFontColor))
		end

		-- Click handler
		local tab = self
		self.frame:SetScript("OnClick", function()
			onClickCallback(tab)
		end)

		self.frame:SetScript("OnEnter", function()
			tab.frame:GetFontString():SetTextColor(unpack(highlightFontColor))
		end)

		self.frame:SetScript("OnLeave", function()
			tab:SetDefaultFontColor()
		end)
	end;

	-- ========================= METHODS ===========================

	SetName = function(self, name)
		self.name = name
		self.frame:GetFontString():SetText(name)
		local tw = 60
		if (self.frame:GetFontString().GetStringWidth) then
			tw = self.frame:GetFontString():GetStringWidth()
		end
		self.frame:SetWidth(tw + 40)
		self.frame:SetHeight(55)
	end;

	UpdatePosition = function(self, isMainFrameMinimized, tabgroups)
		self.frame:ClearAllPoints()

		if (self.tab_number == 1) then
			self.frame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 80, -8)
		else
			-- Find previous visible tab to anchor to
			local anchor = nil
			for j = self.tab_number - 1, 1, -1 do
				local prevTab = tabgroups[j]
				if (prevTab and prevTab:IsShown()) then
					anchor = prevTab
					break
				end
			end
			if (anchor) then
				self.frame:SetPoint("TOPLEFT", anchor.frame, "TOPRIGHT", -13, 0)
			else
				self.frame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT", 80, -8)
			end
		end
	end;

	SetMinmaxPosition = function(self, isMainFrameMinimized, tabgroups)
		if (isMainFrameMinimized) then
			self.frame:GetFontString():SetPoint("CENTER", self.frame, "CENTER", 0, 2.5)
			self.frame:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
			self.frame:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		else
			self.frame:GetFontString():SetPoint("CENTER", self.frame, "CENTER", 0, -2.5)
			self.frame:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
			self.frame:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
		end

		self:UpdatePosition(isMainFrameMinimized, tabgroups)
	end;

	SetDefaultFontColor = function(self)
		if (ModernSpellBookFrame.selectedTab == self.tab_number) then
			self.frame:GetFontString():SetTextColor(unpack(normalFontColor))
		else
			self.frame:GetFontString():SetTextColor(unpack(disabledFontColor))
		end
	end;

	UpdateAsPetTab = function(self)
		local petType = UnitCreatureType("pet")
		if (petType) then
			self:SetName(petType)
			self.frame:Show()
		else
			self.frame:Hide()
			if (ModernSpellBookFrame.selectedTab == self.tab_number) then
				ModernSpellBookFrame.selectedTab = 1
				ModernSpellBookFrame.Tabgroups[1].frame:Click()
				ModernSpellBookFrame.Tabgroups[1].frame:GetFontString():SetTextColor(unpack(normalFontColor))
			end
		end

		SpellBook:PositionAllTabs()
	end;

	-- ======================== VISUAL STATE =======================

	SetSelected = function(self)
		self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab3-Selected")
		self.frame:GetNormalTexture():SetVertexColor(unpack(enabledVertexColor))
		self.frame:GetFontString():SetTextColor(unpack(normalFontColor))
	end;

	SetDeselected = function(self)
		self.frame:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
		self.frame:GetNormalTexture():SetVertexColor(unpack(disabledVertexColor))
		self.frame:GetFontString():SetTextColor(unpack(disabledFontColor))
	end;

	-- ====================== DELEGATION ===========================

	Hide = function(self)
		self.frame:Hide()
	end;

	Show = function(self)
		self.frame:Show()
	end;

	IsShown = function(self)
		return self.frame:IsShown()
	end;

	GetRight = function(self)
		return self.frame:GetRight()
	end;
}