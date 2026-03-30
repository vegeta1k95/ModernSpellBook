--[[
	CTalentSettings: Settings dropdown for the talent tree window.
	Grid line toggles, coloring, visibility, reset position/scale.
--]]

class "CTalentSettings"
{
	__init = function(self, parent, talentTree)
		self.talent_tree = talentTree

		-- Gear button
		self.button = CreateFrame("Button", nil, parent)
		self.button:SetWidth(20)
		self.button:SetHeight(20)
		self.button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -22)
		self.button:SetFrameLevel(parent:GetFrameLevel() + 20)
		self.button:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
		self.button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
		self.button:SetPushedTexture("Interface\\Icons\\INV_Misc_Gear_01")

		-- Dropdown
		local dropdown = CreateFrame("Frame", "ModernTalentSettingsDropDown", parent)
		dropdown.displayMode = "MENU"
		local settings = self
		dropdown.initialize = function(level)
			settings:InitializeDropdown(level)
		end

		local btn = self.button
		self.button:SetScript("OnClick", function()
			ToggleDropDownMenu(1, nil, dropdown, btn, 0, 0)
		end)
	end;

	Anchor = function(self, anchorFrame)
		self.button:ClearAllPoints()
		self.button:SetPoint("LEFT", anchorFrame, "RIGHT", 8, 0)
	end;

	InitializeDropdown = function(self, level)
		level = level or 1
		local tree = self.talent_tree

		if (level == 1) then
			-- Grid lines submenu
			local info = {}
			info.text = "Grid lines"
			info.hasArrow = 1
			info.notCheckable = 1
			info.value = "gridLines"
			UIDropDownMenu_AddButton(info, level)

			-- Reset position & scale
			info = {}
			info.text = "Reset position & scale"
			info.notCheckable = 1
			info.func = function()
				ModernSpellBook_DB.talentPosition = nil
				ModernSpellBook_DB.talentScale = nil
				tree.frame:SetScale(1)
				tree.frame:ClearAllPoints()
				tree.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				CloseDropDownMenus()
			end
			UIDropDownMenu_AddButton(info, level)

		elseif (level == 2) then
			if (UIDROPDOWNMENU_MENU_VALUE == "gridLines") then
				if (not ModernSpellBook_DB.talentGridLines) then
					ModernSpellBook_DB.talentGridLines = { vertical = true, diagonal = true, horizontal = true }
				end
				local gl = ModernSpellBook_DB.talentGridLines

				local info = {}
				info.text = "Vertical"
				info.checked = gl.vertical
				info.keepShownOnClick = 1
				info.func = function()
					gl.vertical = not gl.vertical
					tree:RebuildAllGrids()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Diagonal"
				info.checked = gl.diagonal
				info.keepShownOnClick = 1
				info.func = function()
					gl.diagonal = not gl.diagonal
					tree:RebuildAllGrids()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Horizontal"
				info.checked = gl.horizontal
				info.keepShownOnClick = 1
				info.func = function()
					gl.horizontal = not gl.horizontal
					tree:RebuildAllGrids()
				end
				UIDropDownMenu_AddButton(info, level)

				-- Coloring submenu
				info = {}
				info.text = "Coloring"
				info.hasArrow = 1
				info.notCheckable = 1
				info.value = "gridLineColoring"
				UIDropDownMenu_AddButton(info, level)

				-- Visibility submenu
				info = {}
				info.text = "Visibility"
				info.hasArrow = 1
				info.notCheckable = 1
				info.value = "gridLineVisibility"
				UIDropDownMenu_AddButton(info, level)
			end

		elseif (level == 3) then
			if (UIDROPDOWNMENU_MENU_VALUE == "gridLineVisibility") then
				if (not ModernSpellBook_DB.talentGridLines) then
					ModernSpellBook_DB.talentGridLines = { vertical = true, diagonal = true, horizontal = true }
				end
				local gl = ModernSpellBook_DB.talentGridLines
				local visibility = gl.visibility or "unlocked"

				local info = {}
				info.text = "Always"
				info.checked = (visibility == "always")
				info.func = function()
					gl.visibility = "always"
					tree:Refresh()
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Only unlocked"
				info.checked = (visibility == "unlocked")
				info.func = function()
					gl.visibility = "unlocked"
					tree:Refresh()
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)

			elseif (UIDROPDOWNMENU_MENU_VALUE == "gridLineColoring") then
				if (not ModernSpellBook_DB.talentGridLines) then
					ModernSpellBook_DB.talentGridLines = { vertical = true, diagonal = true, horizontal = true }
				end
				local gl = ModernSpellBook_DB.talentGridLines
				local coloring = gl.coloring or "unlocked"

				local info = {}
				info.text = "Always"
				info.checked = (coloring == "always")
				info.func = function()
					gl.coloring = "always"
					tree:Refresh()
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Only unlocked"
				info.checked = (coloring == "unlocked")
				info.func = function()
					gl.coloring = "unlocked"
					tree:Refresh()
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Never"
				info.checked = (coloring == "never")
				info.func = function()
					gl.coloring = "never"
					tree:Refresh()
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end;
}
