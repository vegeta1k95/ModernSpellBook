--[[
	Settings dropdown menu: font size, text color, highlights,
	icon frames, spell counter, remember page, show unlearned.
--]]

class "CSettingsMenu"
{
	__init = function(self, parent, onSettingChanged)
		self.on_setting_changed = onSettingChanged

		-- Initialize icon frame settings
		if (not ModernSpellBook_DB.iconFrame) then
			ModernSpellBook_DB.iconFrame = { spells = true, passives = true, other = true, unlearned = false }
		end
		if (ModernSpellBook_DB.iconFrame.unlearned == nil) then
			ModernSpellBook_DB.iconFrame.unlearned = false
		end

		-- Gear icon button
		self.button = CreateFrame("Button", nil, parent)
		self.button:SetWidth(20)
		self.button:SetHeight(20)
		self.button:SetPoint("RIGHT", ModernSpellBookFrame.searchBar.frame, "LEFT", -15, 0)
		self.button:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
		self.button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
		self.button:SetPushedTexture("Interface\\Icons\\INV_Misc_Gear_01")

		-- Dropdown frame
		self.dropdown = CreateFrame("Frame", "ModernSpellBookSettingsDropDown", parent)
		self.dropdown.displayMode = "MENU"

		local settings = self
		self.dropdown.initialize = function(level)
			settings:InitializeDropdown(level)
		end

		local dropdown = self.dropdown
		self.button:SetScript("OnClick", function()
			ToggleDropDownMenu(1, nil, dropdown, settings.button, 0, 0)
		end)

		-- Hide dropdown when spellbook closes
		parent:SetScript("OnHide", function()
			CloseDropDownMenus()
			ActionBarHelper:HideAllGrids()
		end)

		ModernSpellBookFrame.settingsButton = self.button
	end;

	-- =================== DROPDOWN ================================

	InitializeDropdown = function(self, level)
		level = level or 1
		local info = {}
		local onChanged = self.on_setting_changed

		if (level == 1) then
			-- Remember page
			info = {}
			info.text = "Remember page"
			info.checked = ModernSpellBook_DB.rememberPage
			info.keepShownOnClick = 1
			info.func = function()
				ModernSpellBook_DB.rememberPage = not ModernSpellBook_DB.rememberPage
			end
			UIDropDownMenu_AddButton(info, level)

			-- Spell counter
			info = {}
			info.text = "Spell counter"
			info.checked = ModernSpellBook_DB.showSpellCounter
			info.keepShownOnClick = 1
			info.func = function()
				ModernSpellBook_DB.showSpellCounter = not ModernSpellBook_DB.showSpellCounter
				SpellDataService:UpdateSpellCounter()
			end
			UIDropDownMenu_AddButton(info, level)

			-- Show unlearned spells
			info = {}
			info.text = "Show unlearned"
			info.checked = ModernSpellBook_DB.showUnlearned
			info.keepShownOnClick = 1
			info.func = function()
				ModernSpellBook_DB.showUnlearned = not ModernSpellBook_DB.showUnlearned
				onChanged()
			end
			UIDropDownMenu_AddButton(info, level)

			-- Show upcoming spells
			info = {}
			info.text = "Show upcoming"
			info.checked = ModernSpellBook_DB.showUpcoming
			info.keepShownOnClick = 1
			info.func = function()
				ModernSpellBook_DB.showUpcoming = not ModernSpellBook_DB.showUpcoming
				SpellBook:UpdateUpcomingSpells()
			end
			UIDropDownMenu_AddButton(info, level)

			-- Continuation headers
			info = {}
			info.text = "Continuation headers"
			info.checked = ModernSpellBook_DB.showContinuationHeaders
			info.keepShownOnClick = 1
			info.func = function()
				ModernSpellBook_DB.showContinuationHeaders = not ModernSpellBook_DB.showContinuationHeaders
				onChanged()
			end
			UIDropDownMenu_AddButton(info, level)

			-- Highlights submenu
			info = {}
			info.text = "Highlights"
			info.hasArrow = 1
			info.notCheckable = 1
			info.value = "highlights"
			UIDropDownMenu_AddButton(info, level)

			-- Font size submenu
			info = {}
			info.text = "Font size"
			info.hasArrow = 1
			info.notCheckable = 1
			info.value = "fontSize"
			UIDropDownMenu_AddButton(info, level)

			-- Spell Text Color submenu
			info = {}
			info.text = "Spell text color"
			info.hasArrow = 1
			info.notCheckable = 1
			info.value = "textColor"
			UIDropDownMenu_AddButton(info, level)

			-- Icon Frame submenu
			info = {}
			info.text = "Spell icon frame"
			info.hasArrow = 1
			info.notCheckable = 1
			info.value = "iconFrame"
			UIDropDownMenu_AddButton(info, level)

			-- Reset position
			info = {}
			info.text = "Reset position"
			info.notCheckable = 1
			info.func = function()
				ModernSpellBook_DB.position = nil
				ModernSpellBookFrame:ClearAllPoints()
				ModernSpellBookFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				CloseDropDownMenus()
			end
			UIDropDownMenu_AddButton(info, level)

		elseif (level == 2) then
			if (UIDROPDOWNMENU_MENU_VALUE == "textColor") then
				info = {}
				info.text = "Light"
				info.checked = ModernSpellBook_DB.textColorMode ~= "dark"
				info.func = function()
					ModernSpellBook_DB.textColorMode = "light"
					onChanged()
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Dark"
				info.checked = ModernSpellBook_DB.textColorMode == "dark"
				info.func = function()
					ModernSpellBook_DB.textColorMode = "dark"
					onChanged()
					CloseDropDownMenus()
				end
				UIDropDownMenu_AddButton(info, level)

			elseif (UIDROPDOWNMENU_MENU_VALUE == "fontSize") then
				local sizes = {9, 10, 10.5, 11, 11.5, 12, 13}
				for _, size in ipairs(sizes) do
					info = {}
					info.text = size
					info.value = size
					info.checked = (ModernSpellBook_DB.fontSize == size)
					info.func = function()
						ModernSpellBook_DB.fontSize = this.value
						onChanged()
						CloseDropDownMenus()
					end
					UIDropDownMenu_AddButton(info, level)
				end

			elseif (UIDROPDOWNMENU_MENU_VALUE == "highlights") then
				info = {}
				info.text = "Learned spells glow"
				info.checked = ModernSpellBook_DB.highlights.learnedGlow
				info.keepShownOnClick = 1
				info.func = function()
					ModernSpellBook_DB.highlights.learnedGlow = not ModernSpellBook_DB.highlights.learnedGlow
					onChanged()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Learned spells badge"
				info.checked = ModernSpellBook_DB.highlights.learnedBadge
				info.keepShownOnClick = 1
				info.func = function()
					ModernSpellBook_DB.highlights.learnedBadge = not ModernSpellBook_DB.highlights.learnedBadge
					onChanged()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Available spells glow"
				info.checked = ModernSpellBook_DB.highlights.availableGlow
				info.keepShownOnClick = 1
				info.func = function()
					ModernSpellBook_DB.highlights.availableGlow = not ModernSpellBook_DB.highlights.availableGlow
					onChanged()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Available spells badge"
				info.checked = ModernSpellBook_DB.highlights.availableBadge
				info.keepShownOnClick = 1
				info.func = function()
					ModernSpellBook_DB.highlights.availableBadge = not ModernSpellBook_DB.highlights.availableBadge
					onChanged()
				end
				UIDropDownMenu_AddButton(info, level)

			elseif (UIDROPDOWNMENU_MENU_VALUE == "iconFrame") then
				info = {}
				info.text = "Spells"
				info.checked = ModernSpellBook_DB.iconFrame.spells
				info.keepShownOnClick = 1
				info.func = function()
					ModernSpellBook_DB.iconFrame.spells = not ModernSpellBook_DB.iconFrame.spells
					onChanged()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Other"
				info.checked = ModernSpellBook_DB.iconFrame.other
				info.keepShownOnClick = 1
				info.func = function()
					ModernSpellBook_DB.iconFrame.other = not ModernSpellBook_DB.iconFrame.other
					onChanged()
				end
				UIDropDownMenu_AddButton(info, level)

				info = {}
				info.text = "Unlearned"
				info.checked = ModernSpellBook_DB.iconFrame.unlearned
				info.keepShownOnClick = 1
				info.func = function()
					ModernSpellBook_DB.iconFrame.unlearned = not ModernSpellBook_DB.iconFrame.unlearned
					onChanged()
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end;
}
