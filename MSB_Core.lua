--[[
	CSpellBook: main addon controller.
	Owns the ModernSpellBookFrame, manages page rendering,
	event handling, and UI setup.
--]]

local classColors = {{0.87,0.38,0.21}, {0.96,0.55,0.73}, {0.67,0.83,0.45}, {1.00,0.96,0.41}, {1, 1, 1}, {0.77,0.12,0.23}, {0.00,0.44,0.87}, {0.25,0.78,0.92}, {0.53,0.53,0.93}, {0.00,1.00,0.60}, {1.00,0.49,0.04}, {0.64,0.19,0.79}, {0.20,0.58,0.50}}

local maximumPages = 2
local spellUpdateRequired = true
local DB_VERSION = 4

local windowSettings = {
	posy = 0,
	height = 560,
	width1 = 550,
	width2 = 1058,
}

local totalSpellItems = 0
local totalCategoryItems = 0
local leftButtons = {"ShowPassiveSpellsCheckBox", "ShowAllSpellRanksCheckbox", "ModernSpellBookFrameSearchBar"}

class "CSpellBook"
{
	__init = function(self)
		-- Create the main frame
		self.frame = CreateFrame("Frame", "ModernSpellBookFrame", SpellBookFrame)
		self.frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		self.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
		self.frame.CloseButton = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
		self.frame.CloseButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)

		-- Event dispatch (vanilla calling convention)
		local spellBook = self
		self.frame.Tabgroups = {}

		self.frame.ADDON_LOADED = function()
			spellBook:OnAddonLoaded()
		end
		self.frame.SPELLS_CHANGED = function()
			spellBook:OnSpellsChanged()
		end

		self.frame:RegisterEvent("ADDON_LOADED")
		self.frame:RegisterEvent("SPELLS_CHANGED")
		self.frame:SetScript("OnEvent", function()
			local handler = self.frame[event]
			if (handler) then handler() end
		end)

		-- OnShow
		self.frame:SetScript("OnShow", function()
			spellBook:OnShow()
		end)

        _G.ModernSpellBookFrame = self.frame
	end;

	-- ========================= EVENTS ============================

	OnAddonLoaded = function(self)
		if (arg1 ~= "ModernSpellBook") then return end

		-- Wipe DB if schema version mismatch
		if (not ModernSpellBook_DB) then
			ModernSpellBook_DB = {}
		end
		if (ModernSpellBook_DB.dbVersion ~= DB_VERSION) then
			for k in pairs(ModernSpellBook_DB) do
				ModernSpellBook_DB[k] = nil
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ModernSpellBook:|r Settings reset (DB version " .. DB_VERSION .. ").")
		end

		-- Defaults
		if (ModernSpellBook_DB.showPassives == nil) then ModernSpellBook_DB.showPassives = true end
		if (ModernSpellBook_DB.showSpellCounter == nil) then ModernSpellBook_DB.showSpellCounter = true end
		if (ModernSpellBook_DB.rememberPage == nil) then ModernSpellBook_DB.rememberPage = true end
		if (ModernSpellBook_DB.showUnlearned == nil) then ModernSpellBook_DB.showUnlearned = true end
		if (ModernSpellBook_DB.showUpcoming == nil) then ModernSpellBook_DB.showUpcoming = true end
		if (not ModernSpellBook_DB.fontSize) then ModernSpellBook_DB.fontSize = 11.5 end
		if (not ModernSpellBook_DB.highlights) then
			ModernSpellBook_DB.highlights = { learnedGlow = true, learnedBadge = true, availableGlow = true, availableBadge = true }
		end
		if (not ModernSpellBook_DB.spells) then ModernSpellBook_DB.spells = {} end
		ModernSpellBook_DB.dbVersion = DB_VERSION

		self.frame.ClientLocale = Localization.current
		self.frame.currentPage = ModernSpellBook_DB.rememberPage and ModernSpellBook_DB.lastPage or 1
		self.frame.maxPages = 1
		self.frame.stanceButtons = {}
		self.frame.unlockedStances = {}
		self.frame.isFirstLoad = true

		self:SetupFrame()
		self:AddPassiveCheckBox()
		self:AddSearchBar()
		self:AddPageButtons()
		self:AddCancelButton()

		self.frame.settingsMenu = CSettingsMenu(
			self.frame,
			function() SpellBook:DrawPage() end
		)

		self:SetShape(ModernSpellBook_DB.isMinimized)
		self:DisableVanillaSpellBook()
		self:ForceLoad()

		self.frame:UnregisterEvent("ADDON_LOADED")
	end;

	OnSpellsChanged = function(self)
		if (self.frame.isFirstLoad) then return end

		if (self.frame:IsVisible()) then
			C_Timer.After(0.3, function()
				self.frame.tab3:UpdateAsPetTab()
				SpellBook:DrawPage()
			end)
		else
			spellUpdateRequired = true
		end
	end;

	OnShow = function(self)
		PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)
		ActionBarHelper:ShowAllGrids()

		if (self.frame.isFirstLoad) then
			self:AddAllRanksCheckBox()
			local className = UnitClass("player")

			local wasSearchBarShown = self.frame.searchBar:IsShown()
			self.frame.searchBar:Hide()
			self.frame.searchBar:SetPoint("RIGHT", self:GetRightmostLeftButton(), "LEFT", -10, 1)
			if (wasSearchBarShown) then self.frame.searchBar:Show() end

			self.frame.selectedTab = ModernSpellBook_DB.rememberPage and ModernSpellBook_DB.lastTab or 1
			self.frame.tab1 = self:NewTab(className)
			self.frame.tab2 = self:NewTab(GENERAL)
			self.frame.tab3 = self:NewTab("Pet")

			self.frame.customTabs = {}

			self.frame.tab3:UpdateAsPetTab()
			self:SetShape(ModernSpellBook_DB.isMinimized)
			self:PositionAllTabs()

			if (next(ModernSpellBook_DB.spells) == nil) then
				SpellDataService:SetupInitiallyKnownSpells()
			end

			-- Restore last selected tab visuals
			local lastTab = self.frame.selectedTab
			for _, tab in ipairs(self.frame.Tabgroups) do
				if (tab.tab_number == lastTab) then
					tab:SetSelected()
				else
					tab:SetDeselected()
				end
			end
		else
			self.frame.tab3:UpdateAsPetTab()
		end

		self:CreateCustomTabs()

		-- Reset to page 1 / tab 1 if "Remember page" is off
		if (not ModernSpellBook_DB.rememberPage) then
			self.frame.currentPage = 1
			if (self.frame.selectedTab ~= 1 and self.frame.Tabgroups[1]) then
				self.frame.selectedTab = 1
				for _, tab in ipairs(self.frame.Tabgroups) do
					tab:SetDeselected()
				end
				self.frame.Tabgroups[1]:SetSelected()
				self.frame.Tabgroups[1]:SetDefaultFontColor()
			end
			spellUpdateRequired = true
		end

		self:DrawPage()

		-- Show/hide trainer hint
		if (self.frame.trainerHint) then
			if (ModernSpellBook_DB.showUnlearned and not ModernSpellBook_DB.trainerScanned) then
				self.frame.trainerHint:Show()
			else
				self.frame.trainerHint:Hide()
			end
		end

		if (not self.frame.isFirstLoad) then return end
		self.frame.isFirstLoad = false

		if (ShowAllSpellRanksCheckbox and ShowAllSpellRanksCheckbox.HookScript) then
			HookScript(ShowAllSpellRanksCheckbox, "OnClick", function()
				SpellBook:DrawPage()
			end)
		end
	end;

	-- ========================= SETUP =============================

	ForceLoad = function(self)
		self.frame.isForceLoading = true
		ToggleSpellBook(BOOKTYPE_SPELL)
		ToggleSpellBook(BOOKTYPE_SPELL)
		C_Timer.After(0.5, function()
			if (SpellBookFrame:IsShown()) then
				ToggleSpellBook(BOOKTYPE_SPELL)
			end
			self.frame.isForceLoading = false
		end)
	end;

	AddSearchBar = function(self)
		self.frame.searchBar = CSearchBar(
			self.frame,
			self.frame.ClientLocale.SearchAbilities,
			function() SpellBook:RefreshPage() end
		)
	end;

	SetupFrame = function(self)
		local classID = MSB_GetClassIndex()
		self.frame:EnableMouse(true)
		self.frame:SetMovable(true)
		self.frame:RegisterForDrag("LeftButton")
		self.frame:SetScript("OnDragStart", function()
			this:StartMoving()
		end)
		self.frame:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			-- Save position
			local point, _, relPoint, x, y = this:GetPoint()
			ModernSpellBook_DB.position = { point = point, relPoint = relPoint, x = x, y = y }
		end)
		self.frame:SetWidth(windowSettings.width2)
		self.frame:SetHeight(windowSettings.height)

		-- Restore saved position or default to center
		if (ModernSpellBook_DB.position) then
			local pos = ModernSpellBook_DB.position
			self.frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
		else
			self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, windowSettings.posy)
		end
		self.frame:SetFrameStrata("HIGH")
		HideUIPanel(self.frame)

		self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.frame.title:SetPoint("TOP", self.frame, "TOP", 0, -24)
		self.frame.title:SetText(SPELLBOOK)

		-- Portrait frame
		self.frame.portraitBg = self.frame:CreateTexture(nil, "ARTWORK")
		self.frame.portraitBg:SetWidth(44)
		self.frame.portraitBg:SetHeight(44)
		self.frame.portraitBg:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -10, 10)
		self.frame.portraitBg:SetTexture(0, 0, 0, 1)

		self.frame.book = self.frame:CreateTexture(nil, "OVERLAY")
		self.frame.book:SetWidth(40)
		self.frame.book:SetHeight(40)
		self.frame.book:SetPoint("CENTER", self.frame.portraitBg, "CENTER", 0, 0)
		self.frame.book:SetTexture("Interface\\Spellbook\\Spellbook-Icon")
		self.frame.book:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		self.frame.portraitBorderFrame = CreateFrame("Frame", nil, self.frame)
		self.frame.portraitBorderFrame:SetWidth(76)
		self.frame.portraitBorderFrame:SetHeight(76)
		self.frame.portraitBorderFrame:SetPoint("CENTER", self.frame.portraitBg, "CENTER", 0, 0)
		self.frame.portraitBorderFrame:SetFrameLevel(self.frame:GetFrameLevel() + 5)
		self.frame.portraitBorder = self.frame.portraitBorderFrame:CreateTexture(nil, "OVERLAY")
		self.frame.portraitBorder:SetAllPoints(self.frame.portraitBorderFrame)
		self.frame.portraitBorder:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-frame")

		-- Background pages (top anchor positions, bottom anchor = frame bottom, height auto)
		self.frame.backgroundLeft = self.frame:CreateTexture(nil, "ARTWORK")
		self.frame.backgroundLeft:SetWidth(550)
		self.frame.backgroundLeft:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 15, -50)
		self.frame.backgroundLeft:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 15)
		self.frame.backgroundLeft:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-page-1")
		self.frame.backgroundLeft:SetTexCoord(1, 0, 0, 1)

		self.frame.backgroundRight = self.frame:CreateTexture(nil, "ARTWORK")
		self.frame.backgroundRight:SetWidth(510)
		self.frame.backgroundRight:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 535, -50)
		self.frame.backgroundRight:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -15, 15)
		self.frame.backgroundRight:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-page-1")
		self.frame.backgroundRight:SetTexCoord(0.123, 1, 0, 1)

		-- Bookmark
		self.frame.bookmark = self.frame:CreateTexture(nil, "OVERLAY")
		self.frame.bookmark:SetWidth(64)
		self.frame.bookmark:SetHeight(256)
		self.frame.bookmark:SetPoint("TOPLEFT", self.frame, "TOPLEFT", windowSettings.width1-65, -53)
		self.frame.bookmark:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\bookmark")
		self.frame.bookmark:SetTexCoord(1, 0, 0, 1)
		classColors = nil

		self.frame.noresultsText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.frame.noresultsText:SetPoint("CENTER", self.frame.backgroundLeft, "CENTER", 0, 0)
		self.frame.noresultsText:SetText(self.frame.ClientLocale.NoResults.. NEW.. ", ".. TALENT.. "'")
		self.frame.noresultsText:SetTextColor(0, 0, 0)
		self.frame.noresultsText:SetShadowOffset(0, 0)
		self.frame.noresultsText:Hide()

		self.frame.trainerHint = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.frame.trainerHint:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 60)
		self.frame.trainerHint:SetText("Visit a class trainer in a major city to fetch the FULL list of available spells.")
		self.frame.trainerHint:SetFont("Fonts\\FRIZQT__.TTF", 10)
		self.frame.trainerHint:SetTextColor(1, 1, 1)
		self.frame.trainerHint:Hide()

		self.frame.spellCounter = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.frame.spellCounter:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 60, 60)
		self.frame.spellCounter:SetFont("Fonts\\FRIZQT__.TTF", 10)
		self.frame.spellCounter:SetTextColor(1, 1, 1)

		-- Upcoming spells row (grows right-to-left from page TOPRIGHT, label centered above)
		local UPCOMING_ICON_SIZE = 24
		local UPCOMING_ICON_SPACING = 14

		self.frame.upcomingFrame = CreateFrame("Frame", nil, self.frame)
		self.frame.upcomingFrame:SetHeight(UPCOMING_ICON_SIZE)
		self.frame.upcomingFrame:SetWidth(400)
		self.frame.upcomingFrame:SetPoint("TOPRIGHT", self.frame.backgroundLeft, "TOPRIGHT", -100, -30)

		self.frame.upcomingLabel = self.frame.upcomingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.frame.upcomingLabel:SetFont("Fonts\\FRIZQT__.TTF", 10)
		self.frame.upcomingLabel:SetTextColor(1, 1, 1)

		self.frame.upcomingIcons = {}
		for i = 1, 10 do
			local parent = CreateFrame("Button", nil, self.frame.upcomingFrame)
			parent:SetWidth(UPCOMING_ICON_SIZE)
			parent:SetHeight(UPCOMING_ICON_SIZE)
			parent:SetPoint("TOPRIGHT", self.frame.upcomingFrame, "TOPRIGHT", -(i - 1) * (UPCOMING_ICON_SIZE + UPCOMING_ICON_SPACING), 0)
			parent:Hide()

			local icon = CIcon(parent, UPCOMING_ICON_SIZE)
			icon:SetBorder("Interface\\AddOns\\ModernSpellBook\\Assets\\spell_border_gray")
			icon:SetBorderSize(UPCOMING_ICON_SIZE + 4)
			icon:HideRoundBorder()
			icon:HideSocket()
			icon.hover_alpha = 0

			local glowFrame, glowTex = MSB_CreateGlow(parent, UPCOMING_ICON_SIZE + 34, {43/255, 100/255, 255/255}, 1)
			glowFrame:SetPoint("CENTER", icon.icon, "CENTER", 0, 0)
			glowFrame:Show()
			parent.glow = glowFrame

			parent:SetScript("OnEnter", function()
				if (parent.tipName) then
					GameTooltip:SetOwner(parent, "ANCHOR_TOP")
					local text = parent.tipName
					if (parent.tipRank and parent.tipRank ~= "") then
						text = text .. " (" .. parent.tipRank .. ")"
					end
					GameTooltip:SetText(text, 1, 1, 1)
					if (parent.tipDesc) then
						GameTooltip:AddLine(parent.tipDesc, 1, 0.82, 0, true)
					end
					GameTooltip:Show()
				end
			end)
			parent:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

			parent.icon = icon
			self.frame.upcomingIcons[i] = parent
		end

		if (SpellBookFrame.SetAttribute) then
			SpellBookFrame:SetAttribute("UIPanelLayout-defined", true)
			SpellBookFrame:SetAttribute("UIPanelLayout-enabled", true)
			SpellBookFrame:SetAttribute("UIPanelLayout-whileDead", nil)
			SpellBookFrame:SetAttribute("UIPanelLayout-pushable", 8)
		end
	end;

	AddPassiveCheckBox = function(self)
		self.frame.ShowPassiveSpellsCheckBox = CreateFrame("CheckButton", "ShowPassiveSpellsCheckBox", self.frame, "UICheckButtonTemplate")
		self.frame.ShowPassiveSpellsCheckBox:SetWidth(20)
		self.frame.ShowPassiveSpellsCheckBox:SetHeight(20)

		self.frame.ShowPassiveSpellsCheckBox.text = self.frame.ShowPassiveSpellsCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.frame.ShowPassiveSpellsCheckBox.text:SetPoint("TOPLEFT", self.frame.ShowPassiveSpellsCheckBox, "TOPLEFT", 20, -3.5)
		self.frame.ShowPassiveSpellsCheckBox.text:SetText(self.frame.ClientLocale.ShowPassive)
		self.frame.ShowPassiveSpellsCheckBox.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
		local passiveTextWidth = 80
		if (self.frame.ShowPassiveSpellsCheckBox.text.GetStringWidth) then
			passiveTextWidth = self.frame.ShowPassiveSpellsCheckBox.text:GetStringWidth()
		end
		self.frame.ShowPassiveSpellsCheckBox:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -passiveTextWidth -20, -28)
		self.frame.ShowPassiveSpellsCheckBox:SetChecked(ModernSpellBook_DB.showPassives)
		self.frame.ShowPassiveSpellsCheckBox:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			ModernSpellBook_DB.showPassives = this:GetChecked() and true or false
			SpellBook:DrawPage()
		end)
	end;

	AddAllRanksCheckBox = function(self)
		ShowAllSpellRanksCheckbox = CreateFrame("CheckButton", "ShowAllSpellRanksCheckbox", self.frame, "UICheckButtonTemplate")
		ShowAllSpellRanksCheckbox:SetWidth(20)
		ShowAllSpellRanksCheckbox:SetHeight(20)
		ShowAllSpellRanksCheckbox:SetChecked(ModernSpellBook_DB.showAllRanks or false)

		ShowAllSpellRanksCheckboxText = ShowAllSpellRanksCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ShowAllSpellRanksCheckboxText:SetPoint("TOPLEFT", ShowAllSpellRanksCheckbox, "TOPLEFT", 20, -3.5)
		ShowAllSpellRanksCheckboxText:SetText("All ranks")
		ShowAllSpellRanksCheckboxText:SetFont("Fonts\\FRIZQT__.TTF", 10)

		local labelWidth = 50
		if (ShowAllSpellRanksCheckboxText.GetStringWidth) then
			labelWidth = ShowAllSpellRanksCheckboxText:GetStringWidth()
		end
		ShowAllSpellRanksCheckbox:SetPoint("TOPRIGHT", self.frame.ShowPassiveSpellsCheckBox, "TOPLEFT", -labelWidth - 10, 0)

		ShowAllSpellRanksCheckbox:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			ModernSpellBook_DB.showAllRanks = this:GetChecked() and true or false
			SpellBook:DrawPage()
		end)
	end;

	AddPageButtons = function(self)
		self.frame.pageText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.frame.pageText:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -110, 60)
		self.frame.pageText:SetText("Page 1")
		self.frame.pageText:SetTextColor(1, 1, 1)

		self.frame.previousPage = CreateFrame("Button", nil, self.frame)
		self.frame.previousPage:SetWidth(25)
		self.frame.previousPage:SetHeight(25)
		self.frame.previousPage:SetPoint("TOPLEFT", self.frame.pageText, "TOPRIGHT", 10, 6.5)
		self.frame.previousPage:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
		self.frame.previousPage:SetHighlightTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
		self.frame.previousPage:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
		self.frame.previousPage:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
		self.frame.previousPage:Disable()
		self.frame.previousPage:SetScript("OnClick", function()
			if (self.frame.currentPage <= 1) then return end
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			self.frame.currentPage = math.max(1, self.frame.currentPage -1)
			ModernSpellBook_DB.lastPage = self.frame.currentPage
			SpellBook:RefreshPageElements()
		end)

		self.frame.nextPage = CreateFrame("Button", nil, self.frame)
		self.frame.nextPage:SetWidth(25)
		self.frame.nextPage:SetHeight(25)
		self.frame.nextPage:SetPoint("TOPLEFT", self.frame.previousPage, "TOPLEFT", 24, 0)
		self.frame.nextPage:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		self.frame.nextPage:SetHighlightTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
		self.frame.nextPage:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
		self.frame.nextPage:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
		self.frame.nextPage:SetScript("OnClick", function()
			if (self.frame.currentPage >= self.frame.maxPages) then return end
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			self.frame.currentPage = math.min(self.frame.currentPage +1, self.frame.maxPages)
			ModernSpellBook_DB.lastPage = self.frame.currentPage
			SpellBook:RefreshPageElements()
		end)

		local scrollDebounceTimer = 0
		self.frame:EnableMouseWheel(true)
		self.frame:SetScript("OnMouseWheel", function()
			if (GetTime() - scrollDebounceTimer < 0.2) then return end
			scrollDebounceTimer = GetTime()
			local delta = arg1
			if (delta > 0) then
				self.frame.previousPage:Click()
			else
				self.frame.nextPage:Click()
			end
		end)
	end;

	AddCancelButton = function(self)
		SpellBookCloseButton:ClearAllPoints()
		SpellBookCloseButton:SetPoint("CENTER", self.frame.CloseButton, "CENTER", 0, 0)
		SpellBookCloseButton:SetFrameStrata("DIALOG")
		self.frame.CloseButton:Disable()
		self.frame.CloseButton:Hide()
	end;

	-- ========================= SHAPE =============================

	SetShape = function(self, isMainFrameMinimized)
		if (IsAddOnLoaded and IsAddOnLoaded("WhatsTraining")) then
			if (WhatsTrainingFrame.wtbackgroundframe == nil) then
				WhatsTrainingFrame.wtbackgroundframe = CreateFrame("Frame", "wtbackgroundframe", WhatsTrainingFrame)
				WhatsTrainingFrame.wtbackgroundframe:SetWidth(335)
				WhatsTrainingFrame.wtbackgroundframe:SetHeight(430)
				WhatsTrainingFrame.wtbackgroundframe:SetPoint("TOPLEFT", WhatsTrainingFrame, "TOPLEFT", 15, -10)
				WhatsTrainingFrame.wtbackgroundframe:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
					tile = true, tileSize = 32, edgeSize = 32,
					insets = { left = 8, right = 8, top = 8, bottom = 8 }
				})

				local titleText = WhatsTrainingFrame.wtbackgroundframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				titleText:SetPoint("TOP", WhatsTrainingFrame.wtbackgroundframe, "TOP", 0, -10)
				titleText:SetText("What's Training")
				WhatsTrainingFrame.wtbackgroundframe.TitleText = titleText

				WhatsTrainingFrame.wtbutton = CreateFrame("Button", nil, self.frame)
				WhatsTrainingFrame.wtbutton:SetWidth(28)
				WhatsTrainingFrame.wtbutton:SetHeight(28)
				WhatsTrainingFrame.wtbutton:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 28, 20)
				WhatsTrainingFrame.wtbutton:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				WhatsTrainingFrame.wtbutton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
				WhatsTrainingFrame.wtbutton:SetScript("OnEnter", function()
					GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
					GameTooltip:SetText("Whats Training")
					GameTooltip:Show()
					this:SetScript("OnLeave", function()
						GameTooltip:Hide()
						this:SetScript("OnLeave", nil)
					end)
				end)

				local texture = WhatsTrainingFrame.wtbutton:CreateTexture(nil, "BACKGROUND")
				texture:SetTexture("Interface\\Spellbook\\Spellbook-SkillLineTab")
				texture:SetPoint("CENTER", WhatsTrainingFrame.wtbutton, "CENTER", 13, -4)
				texture:SetWidth(60)
				texture:SetHeight(60)

				WhatsTrainingFrame.wtbutton:SetScript("OnClick", function()
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
					ToggleFrame(WhatsTrainingFrame)
					HideUIPanel(self.frame)

					SpellBookCloseButton:ClearAllPoints()
					if (WhatsTrainingFrame.wtbackgroundframe.CloseButton) then
						SpellBookCloseButton:SetPoint("CENTER", WhatsTrainingFrame.wtbackgroundframe.CloseButton, "CENTER", 0, 0)
					else
						SpellBookCloseButton:SetPoint("TOPRIGHT", WhatsTrainingFrame.wtbackgroundframe, "TOPRIGHT", -5, -5)
					end

					SpellBookFrame:SetScript("OnShow", function()
						self.frame:Show()
						WhatsTrainingFrame:Hide()
						SpellBookCloseButton:ClearAllPoints()
						SpellBookCloseButton:SetPoint("CENTER", self.frame.CloseButton, "CENTER", 0, 0)
						SpellBookFrame:SetScript("OnShow", nil)
					end)
				end)
			end
			if (isMainFrameMinimized) then
				WhatsTrainingFrame.wtbutton:Show()
			else
				WhatsTrainingFrame.wtbutton:Hide()
			end
		end

		if (isMainFrameMinimized) then
			maximumPages = 1
			self.frame:SetWidth(windowSettings.width1)
			self.frame:SetHeight(windowSettings.height)
			if (SpellBookFrame.SetAttribute) then
				SpellBookFrame:SetAttribute("UIPanelLayout-area", "doublewide")
				SpellBookFrame:SetAttribute("UIPanelLayout-width", self.frame:GetWidth())
			end

			if (ModernSpellBook_DB.position) then
				local pos = ModernSpellBook_DB.position
				self.frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
			else
				self.frame:SetPoint("LEFT", UIParent, "LEFT", 15, windowSettings.posy)
			end
			self.frame.backgroundRight:Hide()
			self.frame.searchBar:Clear()
			self.frame.searchBar:Hide()
		else
			maximumPages = 2
			self.frame:SetWidth(windowSettings.width2)
			self.frame:SetHeight(windowSettings.height)
			if (SpellBookFrame.SetAttribute) then
				SpellBookFrame:SetAttribute("UIPanelLayout-area", "center")
				SpellBookFrame:SetAttribute("UIPanelLayout-width", self.frame:GetWidth())
			end

			self.frame:ClearAllPoints()
			if (ModernSpellBook_DB.position) then
				local pos = ModernSpellBook_DB.position
				self.frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
			else
				self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, windowSettings.posy)
			end

			self.frame.backgroundRight:Show()

			self.frame.searchBar:Show()
		end

		if (SpellBookSpellIconsFrame and SpellBookSpellIconsFrame:IsShown()) then
			SpellBookSpellIconsFrame:ClearAllPoints()
			SpellBookSpellIconsFrame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
			SpellBookSpellIconsFrame:Hide()
		end

		if (self.frame.isFirstLoad) then return end

		ToggleSpellBook(BOOKTYPE_SPELL)
		ToggleSpellBook(BOOKTYPE_SPELL)
	end;

	-- ==================== PAGE RENDERING =========================

	CalculateSpellPositions = function(self, AllSpells, isPetTab)
		local pageCollection = {}
		local spellPage = {}
		local currentPageRows = -2
		local totalSpells = 0; local totalCategories = 0
		local maxPagesPerView = ModernSpellBook_DB.isMinimized and 1 or 2
		local drawingPageNumber = 1

		local allSpellCategories = {}
		for category, _ in pairs(AllSpells) do
			table.insert(allSpellCategories, category)
		end
		table.sort(allSpellCategories, function(a, b) return a < b end)

		for _, category in ipairs(allSpellCategories) do
			if (AllSpells[category] ~= nil and table.getn(AllSpells[category]) > 0) then
				spells = AllSpells[category]
				if (currentPageRows +(table.getn(spells) < 3 and 3 or 4) > 7.5) then
					currentPageRows = -2
					drawingPageNumber = math.mod(drawingPageNumber, maxPagesPerView) +1
					if (drawingPageNumber == 1) then
						table.insert(pageCollection, spellPage)
						spellPage = {}
					end
				end
				currentPageRows = currentPageRows +2
				totalCategories = totalCategories +1

				table.insert(spellPage, {isCategory = true, category = category, currentPageRows = currentPageRows, drawingPageNumber = drawingPageNumber})

				local grid_x = -1
				local totalSpellsInCategory = table.getn(spells)
				for i, spellInfo in ipairs(spells) do
					totalSpells = totalSpells +1
					grid_x = math.mod(grid_x + 1, 3)
					if (grid_x == 0) then
						local isSpecialLeftPageCase = i +2 > totalSpellsInCategory and drawingPageNumber == 1
						local maxRowLength = isSpecialLeftPageCase and 8.5 or 7.75
						if (currentPageRows +1 > maxRowLength) then
							if (isSpecialLeftPageCase) then
								currentPageRows = currentPageRows -0.5
								for j = table.getn(spellPage), 1, -1 do
									spellPage[j].currentPageRows = spellPage[j].currentPageRows -0.5
									if (spellPage[j].isCategory) then break end
								end
							else
								currentPageRows = 0
								drawingPageNumber = math.mod(drawingPageNumber, maxPagesPerView) +1
								if (drawingPageNumber == 1) then
									table.insert(pageCollection, spellPage)
									spellPage = {}
								end
							end
						end
						currentPageRows = currentPageRows +1
					end

					table.insert(spellPage, {isCategory = false, spellInfo = spellInfo, currentPageRows = currentPageRows, drawingPageNumber = drawingPageNumber})
				end
			end
		end

		table.insert(pageCollection, spellPage)
		return pageCollection
	end;

	RefreshPage = function(self)

		local filterString = self.frame.searchBar:GetText() or ""
		local filteredSpells = SpellDataService:FilterSpells(filterString)

		if (next(filteredSpells) == nil) then
			self.frame.noresultsText:Show()
			self:CleanPages()
			return
		end

		self.frame.noresultsText:Hide()
		self.frame.pageCollection = self:CalculateSpellPositions(filteredSpells, self.frame.isPetTab)
		self:RefreshPageElements()
	end;

	DrawPage = function(self)

		spellUpdateRequired = false
		self.frame.stanceButtons = {}

		local AllSpells, isPetTab = SpellDataService:GetAvailableSpells()
		self.frame.AllSpells = AllSpells
		self.frame.isPetTab = isPetTab

		if (self.frame.isPetTab) then
			local totalSpells = 0
			for cat, spellList in pairs(AllSpells) do
				totalSpells = totalSpells + table.getn(spellList)
			end

			if (totalSpells == 0) then
				self:CleanPages()
				self.frame.noresultsText:SetText(self.frame.ClientLocale.NoPetSpells)
				self.frame.noresultsText:Show()
				return
			else
				self.frame.noresultsText:Hide()
			end
		end

		self:RefreshPage()
		SpellDataService:UpdateSpellCounter()
		self:UpdateUpcomingSpells()
	end;

	RefreshPageElements = function(self)
		self:CleanPages()

		local pageCollection = self.frame.pageCollection
		self.frame.currentPage = math.min(self.frame.currentPage, table.getn(pageCollection))
		local currentPage = self.frame.currentPage
		self.frame.maxPages = math.max(1, table.getn(pageCollection))

		if (self.frame.maxPages > 1) then
			self.frame.pageText:SetText(string.format(PRODUCT_CHOICE_PAGE_NUMBER, currentPage, self.frame.maxPages))
			self.frame.pageText:Show()
			self.frame.nextPage:Show()
			self.frame.previousPage:Show()
		else
			self.frame.pageText:Hide()
			self.frame.nextPage:Hide()
			self.frame.previousPage:Hide()
		end
		if (currentPage <= 1) then
			self.frame.previousPage:Disable()
		else
			self.frame.previousPage:Enable()
		end
		if (currentPage >= self.frame.maxPages) then
			self.frame.nextPage:Disable()
		else
			self.frame.nextPage:Enable()
		end

		local totalCategories = 0
		local totalSpells = 0
		local grid_x = -1

		if (pageCollection[currentPage] == nil) then return end
		for i, element in ipairs(pageCollection[currentPage]) do
			if (element.isCategory) then
				grid_x = -1
				totalCategories = totalCategories +1
				-- Find first spell icon in this category as fallback
				local fallbackIcon = nil
				for j = i + 1, table.getn(pageCollection[currentPage]) do
					local next = pageCollection[currentPage][j]
					if (next.isCategory) then break end
					if (next.spellInfo and next.spellInfo.spellIcon) then
						fallbackIcon = next.spellInfo.spellIcon
						break
					end
				end
				self:GetOrCreateCategory(totalCategories):Set(element.category, element.currentPageRows, element.drawingPageNumber, fallbackIcon)
			else
				grid_x = math.mod(grid_x + 1, 3)
				totalSpells = totalSpells +1
				self:GetOrCreateSpellItem(totalSpells):Set(element.spellInfo, element.currentPageRows, element.drawingPageNumber, grid_x)
			end
		end
	end;

	-- =================== CUSTOM TABS =============================

	CreateCustomTabs = function(self)
		if (self.frame.otherTabCreated) then return end

		-- Check if any custom spell tabs exist (Companions, Mounts, Toys)
		local customTabNames = {"Mounts", "Companions", "Toys"}
		local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
		local hasAny = false

		for _, customName in ipairs(customTabNames) do
			for i = 1, numTabs do
				local tabName = GetSpellTabInfo(i)
				if (tabName == customName) then
					hasAny = true
					break
				end
			end
			if (hasAny) then break end
		end

		if (hasAny) then
			self:NewTab("Other")
			self.frame.otherTabCreated = true
			self:PositionAllTabs()
		end
	end;

	-- ================ UPCOMING SPELLS ============================

	UpdateUpcomingSpells = function(self)
		-- Hide all icons first
		for i = 1, 10 do
			self.frame.upcomingIcons[i]:Hide()
		end
		self.frame.upcomingLabel:SetText("")

		if (not ModernSpellBook_DB.showUpcoming) then
			self.frame.upcomingFrame:Hide()
			return
		end

		if (self.frame.selectedTab ~= 1) then
			self.frame.upcomingFrame:Hide()
			return
		end

		if (not ModernSpellBook_DB.trainerScanned) then
			self.frame.upcomingFrame:Hide()
			return
		end

		local upcoming, nextLevel = SpellDataService:GetUpcomingSpells()
		if (not nextLevel or table.getn(upcoming) == 0) then
			self.frame.upcomingFrame:Hide()
			return
		end

		self.frame.upcomingLabel:SetText("New spells at ".. nextLevel ..":")
		self.frame.upcomingFrame:Show()

		local count = math.min(table.getn(upcoming), 10)
		for i = 1, count do
			local btn = self.frame.upcomingIcons[i]
			btn.icon:SetIcon(upcoming[i].icon)
            btn.icon:SetDesaturated(true)
			btn.icon:SetIconAlpha(0.7)
			btn.tipName = upcoming[i].name
			btn.tipRank = upcoming[i].rank
			btn.tipDesc = upcoming[i].desc
			btn:Show()
		end

		-- Center label horizontally above the row of icons
		local iconSize = self.frame.upcomingIcons[1]:GetWidth()
		local spacing = 14
		local rowWidth = count * iconSize + (count - 1) * spacing
		self.frame.upcomingLabel:ClearAllPoints()
		self.frame.upcomingLabel:SetPoint("BOTTOM", self.frame.upcomingFrame, "TOPRIGHT", -rowWidth / 2, 6)
	end;

	-- ================ HIDE OLD SPELLBOOK =========================

	DisableVanillaSpellBook = function(self)
		for i, region in ipairs( { SpellBookFrame:GetRegions() } ) do
			region:Hide()
		end
		for i, child in ipairs({SpellBookFrame:GetChildren()}) do
			local childName = child:GetName()
			if (childName ~= "ModernSpellBookFrame" and childName ~= "SpellBookCloseButton") then
				child:Hide()
			end
		end
	end;

	-- ==================== POOL FACTORIES =========================

	CleanPages = function(self)
		for i = 1, totalSpellItems do
			self.frame["Spell".. i]:Hide()
		end
		for i = 1, totalCategoryItems do
			self.frame["Category".. i]:Hide()
		end
	end;

	GetOrCreateCategory = function(self, i)
		local item = self.frame["Category".. i]
		if (item ~= nil) then
			return item
		end
		totalCategoryItems = totalCategoryItems + 1
		item = CCategoryItem(self.frame)
		self.frame["Category".. i] = item
		return item
	end;

	GetOrCreateSpellItem = function(self, i)
		local item = self.frame["Spell".. i]
		if (item ~= nil) then
			return item
		end
		totalSpellItems = totalSpellItems + 1
		item = CSpellItem(self.frame, i)
		self.frame["Spell".. i] = item
		return item
	end;

	-- =================== TAB MANAGEMENT ==========================

	NewTab = function(self, name)
		local tabNumber = table.getn(self.frame.Tabgroups) + 1

		local tab = CTab(self.frame, name, tabNumber, function(clickedTab)
			local wasPreviousSelectionDifferent = self.frame.selectedTab ~= clickedTab.tab_number
			if (not wasPreviousSelectionDifferent) then return end

			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self.frame.selectedTab = clickedTab.tab_number
			ModernSpellBook_DB.lastTab = clickedTab.tab_number

			clickedTab:SetSelected()

			for _, other_tab in ipairs(self.frame.Tabgroups) do
				if (other_tab ~= clickedTab) then
					other_tab:SetDeselected()
				end
			end

			self.frame.currentPage = 1
			ModernSpellBook_DB.lastPage = 1
			self.frame.previousPage:Disable()
			SpellBook:DrawPage()
		end)

		table.insert(self.frame.Tabgroups, tab)
		return tab
	end;

	GetFinalVisibleTab = function(self)
		local finalVisibleTab = 1
		for i = 1, table.getn(self.frame.Tabgroups) do
			if (self.frame.Tabgroups[i]:IsShown()) then
				finalVisibleTab = i
			end
		end
		return self.frame.Tabgroups[finalVisibleTab]
	end;

	GetRightmostLeftButton = function(self)
		local finalVisibleButton = _G[leftButtons[1]]

		for _, item in ipairs(leftButtons) do
			local button = _G[item]
			if (button == nil or not button:IsShown()) then
				return finalVisibleButton
			end
			finalVisibleButton = button
		end

		return ShowPassiveSpellsCheckBox
	end;

	PositionAllTabs = function(self)
		if (ModernSpellBook_DB.isMinimized) then
			for _, tab in ipairs(self.frame.Tabgroups) do
				tab:UpdatePosition(false, self.frame.Tabgroups)
			end

			local lastTab = self:GetFinalVisibleTab()
			local left = lastTab:GetRight()
			local right = self:GetRightmostLeftButton():GetLeft()

			for _, tab in ipairs(self.frame.Tabgroups) do
				tab:SetMinmaxPosition(left and right and left > right, self.frame.Tabgroups)
			end
		else
			for _, tab in ipairs(self.frame.Tabgroups) do
				tab:SetMinmaxPosition(false, self.frame.Tabgroups)
			end
		end
	end;
}

-- ============================================================
-- Instantiate
-- ============================================================

SpellBook = CSpellBook()

-- ============================================================
-- Replace vanilla SpellBookFrame behavior entirely.
-- Save original for toggle support.
-- ============================================================

MSB_OriginalSpellBookFrameOnShow = SpellBookFrame_OnShow

SpellBookFrame_OnShow = function()
	if (ModernSpellBookFrame.isForceLoading) then return end
	ModernSpellBookFrame:Show()
	SpellBookFrame:EnableMouse(false)
end

-- Reset seen-available list on level up
local levelTracker = CreateFrame("Frame")
levelTracker:RegisterEvent("PLAYER_LEVEL_UP")
levelTracker:SetScript("OnEvent", function()
	-- Reset seen_trainable flags so newly available spells glow again
	for key, entry in pairs(ModernSpellBook_DB.spells) do
		if (not entry.learned) then
			entry.seen_trainable = false
		end
	end
end)
