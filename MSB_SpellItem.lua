--[[
	Spell list entry: CSpellIcon + name/rank text + trail background.
--]]

local ICON_SIZE = 28
local SPELL_HORIZONTAL_SPACING = 150
local VERTICAL_SPACING = 50
local SECOND_PAGE_OFFSET = 510
local HORIZONTAL_OFFSET = 40
local SPELL_INSET = 20

class "CSpellItem"
{
	__init = function(self, parent, index)
		-- Button frame (the interactive root)
		self.frame = CreateFrame("Button", "ModernSpellBookSpell"..index, parent)
		self.frame:SetWidth(ICON_SIZE)
		self.frame:SetHeight(ICON_SIZE)
		self.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		self.frame:SetMovable(true)
		self.frame:RegisterForDrag("LeftButton")

		-- Spell icon (all icon-area visuals)
		self.spellIcon = CSpellIcon(self.frame)

		-- OnLeave: hide tooltip and hover glow
		local glowChecked = self.spellIcon.glowChecked
		self.frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
			glowChecked:SetAlpha(0)
		end)

		-- Text container (positioned to the right of the icon)
		self.textGroup = CreateFrame("Frame", nil, self.frame)
		self.textGroup:SetWidth(98)
		self.textGroup:SetHeight(ICON_SIZE)
		self.textGroup:SetPoint("LEFT", self.frame, "LEFT", 36, 0)

		-- Spell name
		self.nameText = self.textGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.nameText:SetPoint("TOPLEFT", self.textGroup, "TOPLEFT", 0, 0)
		if (self.nameText.SetWordWrap) then self.nameText:SetWordWrap(true) end
		self.nameText:SetWidth(98)
		self.nameText:SetJustifyH("LEFT")
		self.nameText:SetFont("Fonts\\FRIZQT__.TTF", ModernSpellBook_DB and ModernSpellBook_DB.fontSize or 11.5)
		if (self.nameText.SetJustifyV) then self.nameText:SetJustifyV("TOP") end

		-- Trail background behind text
		self.trailBg = self.frame:CreateTexture(nil, "ARTWORK")
		self.trailBg:SetWidth(170)
		self.trailBg:SetHeight(40)
		self.trailBg:SetPoint("LEFT", self.frame, "CENTER", 0, 0)
		self.trailBg:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\spellbook-trail")
		self.trailBg:SetAlpha(1)

		-- Rank / subtitle text
		self.rankText = self.textGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.rankText:SetPoint("TOPLEFT", self.nameText, "BOTTOMLEFT", 0, -1)
		self.rankText:SetFont("Fonts\\FRIZQT__.TTF", 9.5)
		self.rankText:SetJustifyH("LEFT")
		if (self.rankText.SetWordWrap) then self.rankText:SetWordWrap(true) end
		self.rankText:SetWidth(80)
		self.rankText:SetHeight(10)

		-- Apply initial text style
		MSB_TextStyleInstance:ApplyToSpell(self.nameText, self.rankText, self.trailBg, "normal")

		self.spellID = nil
		self.bookType = nil
	end;

	-- ====================== DELEGATION ===========================

	Hide = function(self)
		self.frame:Hide()
	end;

	Show = function(self)
		self.frame:Show()
	end;

	SetStance = function(self, isActive)
		self.spellIcon:SetStance(isActive)
	end;

	-- ==================== CONFIGURATION ==========================

	SetClickHandler = function(self, spellInfo)
		local iconTex = self.spellIcon.icon
		self.frame:SetScript("OnClick", function()
			if (spellInfo.isUnlearned) then return end
			if (spellInfo.isPassive) then return end
			if (InCombatLockdown()) then return end
			if (spellInfo.isPetSpell) then
				if (spellInfo.castName) then
					CastPetAction(spellInfo.castName)
					C_Timer.After(0.2, function()
						if (spellInfo.castName == nil) then
							UIErrorsFrame:AddMessage("ModernSpellBook: Warning - Pet spell ".. spellInfo.spellName.. " cannot be cast outside the pet action bar. Please drag the spell there.", 1.0, 0.1, 0.1, 1.0)
							PlaySound("igQuestFailed")
							return
						end
						local name, texture = GetPetActionInfo(spellInfo.castName)
						iconTex:SetTexture(texture)
					end)
				else
					UIErrorsFrame:AddMessage("ModernSpellBook: Warning - Pet spell ".. spellInfo.spellName.. " cannot be cast outside the pet action bar. Please drag the spell there.", 1.0, 0.1, 0.1, 1.0)
					PlaySound("igQuestFailed")
				end
			else
				CastSpellByName(spellInfo.castName)
			end
		end)
	end;

	SetTextContent = function(self, spellInfo)
		self.nameText:SetFont("Fonts\\FRIZQT__.TTF", ModernSpellBook_DB and ModernSpellBook_DB.fontSize or 11.5)
		self.spellIcon.icon:SetTexture(spellInfo.spellIcon)
		self.nameText:SetText(spellInfo.spellName)
		if (spellInfo.isUnlearned and spellInfo.levelReq and spellInfo.levelReq > 0) then
			local rankText = spellInfo.spellRank or ""
			if (rankText ~= "") then
				self.rankText:SetText(rankText .. " (Lvl " .. spellInfo.levelReq .. ")")
			else
				self.rankText:SetText("Lvl " .. spellInfo.levelReq)
			end
		else
			self.rankText:SetText(spellInfo.spellRank)
		end
		self.spellID = spellInfo.spellID
		self.bookType = spellInfo.bookType
	end;

	SetTextPosition = function(self, spellInfo)
		local nameHeight = 13
		if (self.nameText.GetStringHeight) then
			nameHeight = self.nameText:GetStringHeight()
		elseif (self.nameText.GetHeight) then
			nameHeight = self.nameText:GetHeight()
		end
		local subHeight = 0
		local hasSubText = (spellInfo.spellRank and spellInfo.spellRank ~= "")
			or (spellInfo.isUnlearned and spellInfo.levelReq and spellInfo.levelReq > 0)
		if (hasSubText) then
			subHeight = 11
		end
		local totalHeight = nameHeight + subHeight
		local yOffset = (ICON_SIZE - totalHeight) / 2
		self.textGroup:ClearAllPoints()
		self.textGroup:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 36, -yOffset)
	end;

	SetChatLinkHandler = function(self, spellInfo)
		self.frame:SetScript("OnMouseDown", function()
			local button = arg1
			local isChatLink = IsModifiedClick and IsModifiedClick("CHATLINK") or IsShiftKeyDown()
			if (isChatLink) then
				if (MacroFrameText and MacroFrameText.HasFocus and MacroFrameText:HasFocus()) then
					if (spellInfo.isPassive) then return end
					if (spellInfo.spellRank == "") then
						ChatEdit_InsertLink(spellInfo.spellName)
					elseif (spellInfo.spellRank ~= "") then
						ChatEdit_InsertLink(spellInfo.spellName.. "(".. spellInfo.spellRank.. ")")
					end
				elseif (spellInfo.isTalent) then
					local chatlink = GetTalentLink(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
					if (chatlink) then
						ChatEdit_InsertLink(chatlink)
					else
						ChatEdit_InsertLink(spellInfo.spellName)
					end
				else
					local spellLink = "|cff71d5ff|Hspell:".. spellInfo.spellID .. "|h[".. spellInfo.spellName .."]|h|r"
					ChatEdit_InsertLink(spellLink)
				end
			end
			return;
		end)
	end;

	SetTooltipHandler = function(self, spellInfo, lookupString, isNew)
		local spellIcon = self.spellIcon
		local frame = self.frame
		frame:SetScript("OnEnter", function()
			spellIcon.glowChecked:SetAlpha(spellIcon.glowChecked.checkedAlpha)

			-- Dismiss available-to-learn highlight on hover
			spellIcon:DismissAvailableHighlight(spellInfo)

			-- Dismiss new-spell highlight on hover
			if (isNew) then
				ModernSpellBook_DB.knownSpells[lookupString] = string.gsub(ModernSpellBook_DB.knownSpells[lookupString], MSB_NEW_KEYWORD, "")
				isNew = false
			end
			spellIcon:DismissNewHighlight()

			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
			if (spellInfo.isUnlearned) then
				local shownFullTooltip = false
				if (spellInfo.isTalent and spellInfo.talentGrid and GameTooltip.SetTalent) then
					pcall(function()
						GameTooltip:SetTalent(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
						shownFullTooltip = true
					end)
				end
				if (not shownFullTooltip) then
					local rankText = spellInfo.spellRank or ""
					if (rankText ~= "") then
						GameTooltip:SetText(spellInfo.spellName .. " - " .. rankText, 1, 1, 1)
					else
						GameTooltip:SetText(spellInfo.spellName, 1, 1, 1)
					end
					if (spellInfo.description) then
						GameTooltip:AddLine(spellInfo.description, 1, 0.82, 0, true)
					end
				end
				if (spellInfo.levelReq and spellInfo.levelReq > 0) then
					GameTooltip:AddLine("Requires Level " .. spellInfo.levelReq, 1, 0.2, 0.2)
				end
				if (spellInfo.isTalent) then
					GameTooltip:AddLine("Requires talent point.", 1, 0.82, 0)
				else
					GameTooltip:AddLine("Visit a class trainer to learn.", 1, 0.82, 0)
				end
			elseif (not spellInfo.isTalent) then
				if (spellInfo.bookType) then
					GameTooltip:SetSpell(spellInfo.spellID, spellInfo.bookType)
				else
					GameTooltip:SetSpellByID(spellInfo.spellID)
				end
			else
				if (GameTooltip.SetTalent) then
					GameTooltip:SetTalent(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
				else
					local talentLink = GetTalentLink(spellInfo.talentGrid[1], spellInfo.talentGrid[2])
					if (talentLink) then
						GameTooltip:SetHyperlink(talentLink)
					else
						GameTooltip:SetText(spellInfo.spellName)
					end
				end
			end
			GameTooltip:Show()
		end)
	end;

	SetCooldownAndDrag = function(self, spellInfo)
		local frame = self.frame
		local cooldown = self.spellIcon.cooldown
		if (not spellInfo.isPassive and not spellInfo.isUnlearned) then
			frame:SetMovable(true)
			frame:SetScript("OnDragStart", function()
				if (InCombatLockdown()) then return end
				if (spellInfo.isPetSpell) then
					PickupSpell(spellInfo.spellID, BOOKTYPE_PET)
				else
					PickupSpell(spellInfo.spellID, BOOKTYPE_SPELL)
				end
			end)
			frame:SetScript("OnUpdate", function()
				local start, duration, enable
				if (spellInfo.bookType) then
					start, duration, enable = GetSpellCooldown(spellInfo.spellID, spellInfo.bookType)
				else
					start, duration, enable = GetSpellCooldown(spellInfo.spellName)
				end
				if (start and cooldown) then
					local cdFunc = CooldownFrame_SetTimer or CooldownFrame_Set
					if (cdFunc) then cdFunc(cooldown, start, duration, enable) end
				end
			end)
		else
			if (cooldown) then cooldown:Hide() end
			frame:SetMovable(false)
			frame:SetScript("OnUpdate", nil)
			frame:SetScript("OnDragStart", nil)
		end
	end;

	-- =================== LEARNED STATE ===========================

	SetLearnedState = function(self, spellInfo)
		-- Delegate icon-level visual changes
		self.spellIcon:SetLearnedState(spellInfo)
		-- Handle text-level styling and frame interactivity
		if (spellInfo.isUnlearned) then
			MSB_TextStyleInstance:ApplyToSpell(self.nameText, self.rankText, self.trailBg, "unlearned")
			self.frame:SetMovable(false)
			self.frame:SetScript("OnDragStart", nil)
			self.frame:SetScript("OnUpdate", nil)
		else
			MSB_TextStyleInstance:ApplyToSpell(self.nameText, self.rankText, self.trailBg, "normal")
		end
	end;

	-- =================== MAIN ENTRY POINT ========================

	Set = function(self, spellInfo, currentPageRows, page, grid_x)
		self:SetClickHandler(spellInfo)
		self:SetTextContent(spellInfo)

		-- Stance detection
		local stanceState = false
		if (spellInfo.stanceIndex ~= nil) then
			local _, _, isActive = GetShapeshiftFormInfo(spellInfo.stanceIndex)
			stanceState = isActive
			ModernSpellBookFrame.stanceButtons[spellInfo.spellName] = self
		end
		self.spellIcon:SetStance(stanceState)

		self:SetTextPosition(spellInfo)

		-- New spell detection
		local lookupString = spellInfo.spellName .. spellInfo.spellRank
		local knownSpell = ModernSpellBook_DB.knownSpells[lookupString]
		local isNew = knownSpell and string.find(knownSpell, MSB_NEW_KEYWORD) ~= nil

		self.spellIcon:SetHighlights(spellInfo, isNew)

		-- Position on page
		self.frame:SetPoint("TOPLEFT", ModernSpellBookFrame, "TOPLEFT",
			HORIZONTAL_OFFSET + SPELL_INSET + SECOND_PAGE_OFFSET*(page-1) + grid_x*SPELL_HORIZONTAL_SPACING,
			-80 + currentPageRows * -VERTICAL_SPACING)

		self:SetChatLinkHandler(spellInfo)
		self:SetTooltipHandler(spellInfo, lookupString, isNew)
		self:SetCooldownAndDrag(spellInfo)

		self.frame:Show()

		self.spellIcon:SetFancyFrame(spellInfo)
		self.spellIcon:SetStyle(spellInfo)
		self:SetLearnedState(spellInfo)
	end;
}
