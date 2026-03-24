--[[
	Spell collection, filtering, lookup, and data logic.
--]]

MSB_NEW_KEYWORD = string.lower(";".. NEW.. ";")

local professionRanks = {
	["Apprentice"] = true, ["Journeyman"] = true, ["Expert"] = true,
	["Artisan"] = true, ["Master"] = true,
}
local professionSpells = {
	["Basic Campfire"] = true, ["Find Herbs"] = true, ["Find Minerals"] = true,
	["Find Fish"] = true, ["Find Trees"] = true, ["Smelting"] = true, ["Disenchant"] = true,
	["Pick Lock"] = true, ["Prospecting"] = true, ["Milling"] = true,
	["Survey"] = true, ["Cooking Fire"] = true,
	["Mining"] = true, ["Herbalism"] = true, ["Skinning"] = true,
	["Fishing"] = true, ["Cooking"] = true, ["First Aid"] = true,
	["Tailoring"] = true, ["Leatherworking"] = true, ["Blacksmithing"] = true,
	["Engineering"] = true, ["Enchanting"] = true, ["Alchemy"] = true,
	["Jewelcrafting"] = true, ["Inscription"] = true,
}

class "CSpellDataService"
{
	__init = function(self)
	end;

	-- ====================== LOOKUP ===============================

	CreateLookup = function(self, lookupWord)
		return lookupWord.. ";"
	end;

	BuildSpellLookupTable = function(self, spellInfo)
		local lookupString = ""
		lookupString = lookupString.. self:CreateLookup(spellInfo.spellName)
		if (spellInfo.spellRank ~= "") then
			lookupString = lookupString.. self:CreateLookup(spellInfo.spellRank)
		end
		lookupString = lookupString.. self:CreateLookup(spellInfo.category)
		if (spellInfo.isTalent or spellInfo.isTalentAbility) then
			lookupString = lookupString.. self:CreateLookup(TALENT)
		else
			local spellDescription = GetSpellDescription(spellInfo.spellID)
			if (spellDescription ~= nil) then
				lookupString = lookupString.. self:CreateLookup(spellDescription)
			end
		end
		return string.lower(lookupString)
	end;

	IsProfessionSpell = function(self, spellInfo)
		if (professionSpells[spellInfo.spellName]) then return true end
		if (spellInfo.spellRank and professionRanks[spellInfo.spellRank]) then return true end
		return false
	end;

	-- ====================== FILTERING ============================

	FilterHighestRanks = function(self, spellList)
		local function getRankNum(rankStr)
			if (not rankStr or rankStr == "") then return 0 end
			if (rankStr == "Talent") then return 1 end
			local _, _, num = string.find(rankStr, "(%d+)")
			return tonumber(num) or 0
		end

		local highestLearnedRank = {}
		for _, spellInfo in ipairs(spellList) do
			if (not spellInfo.isUnlearned) then
				local name = spellInfo.spellName
				local rankNum = getRankNum(spellInfo.spellRank)
				if (not highestLearnedRank[name] or rankNum > highestLearnedRank[name]) then
					highestLearnedRank[name] = rankNum
				end
			end
		end

		local nextUnlearnedRank = {}
		for _, spellInfo in ipairs(spellList) do
			if (spellInfo.isUnlearned) then
				local name = spellInfo.spellName
				local rankNum = getRankNum(spellInfo.spellRank)
				local learnedRank = highestLearnedRank[name] or 0
				if (rankNum > learnedRank) then
					if (not nextUnlearnedRank[name] or rankNum < nextUnlearnedRank[name]) then
						nextUnlearnedRank[name] = rankNum
					end
				end
			end
		end

		local filtered = {}
		for _, spellInfo in ipairs(spellList) do
			local name = spellInfo.spellName
			local rankNum = getRankNum(spellInfo.spellRank)
			if (spellInfo.isUnlearned) then
				if (nextUnlearnedRank[name] and rankNum == nextUnlearnedRank[name]) then
					table.insert(filtered, spellInfo)
				elseif (not highestLearnedRank[name] and rankNum == 0) then
					table.insert(filtered, spellInfo)
				end
			else
				if (rankNum == 0 or rankNum >= (highestLearnedRank[name] or 0)) then
					table.insert(filtered, spellInfo)
				end
			end
		end
		return filtered
	end;

	FilterSpells = function(self, filterString)
		local keywords = {}
		if (not filterString) then filterString = "" end
		filterString = string.lower(string.gsub(string.gsub(filterString, "%%", ""), "^", ""))
		for keyword in string.gmatch(filterString, "([^,; ]+)") do
			table.insert(keywords, keyword)
		end

		if (table.getn(keywords) == 0) then return ModernSpellBookFrame.AllSpells or {} end

		local filteredSpells = {}
		for category, spellList in pairs(ModernSpellBookFrame.AllSpells or {}) do
			for _, spellInfo in ipairs(spellList) do
				local lookupString = spellInfo.spellName.. spellInfo.spellRank
				local isMatch = true
				for _, keyword in ipairs(keywords) do
					local knownSpell = ModernSpellBook_DB.knownSpells[lookupString]
					if (knownSpell) then
						if (not string.find(knownSpell, keyword)) then
							isMatch = false
							break
						end
					elseif (spellInfo.isUnlearned) then
						local searchStr = string.lower(spellInfo.spellName .. ";" .. (spellInfo.spellRank or "") .. ";" .. (spellInfo.category or ""))
						if (not string.find(searchStr, keyword)) then
							isMatch = false
							break
						end
					else
						isMatch = false
						break
					end
				end

				if (isMatch) then
					if (filteredSpells[category] == nil) then
						filteredSpells[category] = {}
					end
					table.insert(filteredSpells[category], spellInfo)
				end
			end
		end

		return filteredSpells
	end;

	-- =================== SPELL COLLECTION ========================

	SpellInfoFromSpellBookItem = function(self, tabName, s)
		local spellNameFromBook, spellRank = GetSpellBookItemName(s, BOOKTYPE_SPELL)
		local spellIcon = GetSpellBookItemTexture(s, BOOKTYPE_SPELL)

		local spellID = s
		local castName = spellNameFromBook

		local spellInfo = {
			spellName = spellNameFromBook, spellIcon = spellIcon,
			spellID = spellID, castName = castName, category = tabName,
			bookType = BOOKTYPE_SPELL
		}

		if (ModernSpellBookFrame.unlockedStances[spellNameFromBook]) then
			spellInfo.stanceIndex = ModernSpellBookFrame.unlockedStances[spellNameFromBook]
		end

		local isPassive = IsPassiveSpell(s, BOOKTYPE_SPELL)
		if (isPassive) then
			spellRank = (spellRank and spellRank ~= "") and spellRank or PET_PASSIVE
		end

		spellInfo.castName = (spellRank and spellRank ~= "") and (spellNameFromBook.. "(".. spellRank.. ")") or spellNameFromBook
		spellInfo.spellRank = spellRank or ""
		spellInfo.isPassive = isPassive

		return spellInfo
	end;

	GetPetSpells = function(self)
		local petName = UnitName("pet")
		if (not petName) then return {} end

		local actionBarSpells = {}
		for i = 1, NUM_PET_ACTION_SLOTS do
			local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i)
			if (name == nil) then name = -1 end
			actionBarSpells[name] = i
		end

		local passiveSpells = {}
		local petSpells = {}
		petSpells[petName] = {}
		for i = 1, NUM_PET_ACTION_SLOTS do
			local spellName, spellSubName = GetSpellBookItemName(i, BOOKTYPE_PET)
			if (not spellName) then break end

			local spellIcon = GetSpellBookItemTexture(i, BOOKTYPE_PET)
			local spellInfo = {
				spellName = spellName,
				spellIcon = spellIcon,
				spellRank = spellSubName or "",
				spellID = i,
				bookType = BOOKTYPE_PET,
				isPassive = IsPassiveSpell(i, BOOKTYPE_PET),
				isTalent = false,
				isPetSpell = true,
				castName = actionBarSpells[spellName],
				category = petName
			}

			local lookupString = spellInfo.spellName.. spellInfo.spellRank
			if (ModernSpellBook_DB.knownSpells[lookupString] == nil) then
				ModernSpellBook_DB.knownSpells[lookupString] = self:BuildSpellLookupTable(spellInfo).. string.lower(self:CreateLookup(NEW))
			end

			if (not spellInfo.isPassive) then
				table.insert(petSpells[petName], spellInfo)
			else
				table.insert(passiveSpells, spellInfo)
			end
		end

		local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()
		if (canShowPassives) then
			for _, spellInfo in ipairs(passiveSpells) do
				table.insert(petSpells[petName], spellInfo)
			end
		end

		return petSpells
	end;

	GetCustomTabSpells = function(self, targetTabName)
		local spellsDict = {}
		local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()
		local activeSpells = {}
		local passiveSpells = {}

		local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
		for i = 1, numTabs do
			local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
			if (not tabName) then break end

			if (tabName == targetTabName) then
				for s = offset + 1, offset + numSpells do
					local spellInfo = self:SpellInfoFromSpellBookItem(tabName, s)

					local lookupString = spellInfo.spellName.. spellInfo.spellRank
					if (ModernSpellBook_DB.knownSpells[lookupString] == nil) then
						ModernSpellBook_DB.knownSpells[lookupString] = self:BuildSpellLookupTable(spellInfo).. string.lower(self:CreateLookup(NEW))
					end

					if (spellInfo.isPassive) then
						table.insert(passiveSpells, spellInfo)
					else
						table.insert(activeSpells, spellInfo)
					end
				end
				break
			end
		end

		spellsDict[targetTabName] = activeSpells
		if (canShowPassives) then
			for _, spellInfo in ipairs(passiveSpells) do
				table.insert(spellsDict[targetTabName], spellInfo)
			end
		end

		return spellsDict
	end;

	GetPlayerSpells = function(self, showGeneralTab)
		local allSpellsDict = {}
		local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()
		local passiveSpellsDict = {}

		-- Look through all the stances
		ModernSpellBookFrame.unlockedStances = {}
		local stanceBar = StanceBarFrame or StanceBar
		local NStances = (stanceBar and stanceBar.numForms) and stanceBar.numForms or 10
		for stanceIndex = 1, NStances do
			local texture, name, isActive, isCastable = GetShapeshiftFormInfo(stanceIndex)
			if (not texture) then break end
			if (name) then
				ModernSpellBookFrame.unlockedStances[name] = stanceIndex
			end
		end

		-- Turtle WoW custom tabs to skip
		local skipTabs = {}
		if (COMPANIONS) then skipTabs[COMPANIONS] = true end
		skipTabs["Companions"] = true
		skipTabs["Toys"] = true
		skipTabs["Mounts"] = true

		local numTabs = GetNumSpellTabs and GetNumSpellTabs() or MAX_SKILLLINE_TABS or 4
		for i = 1, numTabs do
			local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
			if (not tabName) then break end

			if (skipTabs[tabName]) then
				-- skip
			elseif (showGeneralTab == (tabName == GENERAL)) then
				allSpellsDict[tabName] = {}
				passiveSpellsDict[tabName] = {}

				for s = offset + 1, offset + numSpells do
					if (not IsSpellHidden(s, BOOKTYPE_SPELL)) then
						local spellInfo = self:SpellInfoFromSpellBookItem(tabName, s)

						local lookupString = spellInfo.spellName.. spellInfo.spellRank
						if (ModernSpellBook_DB.knownSpells[lookupString] == nil) then
							ModernSpellBook_DB.knownSpells[lookupString] = self:BuildSpellLookupTable(spellInfo).. string.lower(self:CreateLookup(NEW))
						end

						if (spellInfo.isPassive) then
							table.insert(passiveSpellsDict[tabName], spellInfo)
						else
							table.insert(allSpellsDict[tabName], spellInfo)
						end
					end
				end
			end
		end

		if (showGeneralTab) then
			if (canShowPassives) then
				for tabName, passiveSpells in pairs(passiveSpellsDict) do
					for i = 1, table.getn(passiveSpells) do
						table.insert(allSpellsDict[tabName], passiveSpells[i])
					end
				end
			end
			for tabName, spells in pairs(allSpellsDict) do
				table.sort(spells, function(a, b) return a.spellName < b.spellName end)
			end
			if (allSpellsDict[GENERAL]) then
				local profSpells = {}
				local generalSpells = {}
				for _, spellInfo in ipairs(allSpellsDict[GENERAL]) do
					if (self:IsProfessionSpell(spellInfo)) then
						spellInfo.category = "Professions"
						table.insert(profSpells, spellInfo)
					else
						table.insert(generalSpells, spellInfo)
					end
				end
				allSpellsDict[GENERAL] = generalSpells
				if (table.getn(profSpells) > 0) then
					allSpellsDict["Professions"] = profSpells
				end
			end

			self:MergeUnlearnedSpells(allSpellsDict, true)
			if (not ShowAllSpellRanksCheckbox or not ShowAllSpellRanksCheckbox:GetChecked()) then
				for tabName, spells in pairs(allSpellsDict) do
					allSpellsDict[tabName] = self:FilterHighestRanks(spells)
				end
			end
			return allSpellsDict
		end

		-- Merge talents with spells
		local talentGridPositions = TalentService:GetAllTalents(true)
		for talentGroupName, talents in pairs(talentGridPositions) do
			if (allSpellsDict[talentGroupName] == nil) then
				for knownGroups, _ in pairs(allSpellsDict) do
					if (string.find(string.lower(knownGroups), string.lower(string.sub(talentGroupName, 1, 4)))) then
						talentGroupName = knownGroups
						for _, spellInfo in ipairs(talents) do
							spellInfo.category = talentGroupName
						end
						break
					end
					allSpellsDict[talentGroupName] = {}
				end
			end
			if (passiveSpellsDict[talentGroupName] == nil) then
				passiveSpellsDict[talentGroupName] = {}
			end
			for i = 1, table.getn(talents) do
				table.insert(passiveSpellsDict[talentGroupName], talents[i])
			end
		end

		for tabName, passiveSpells in pairs(passiveSpellsDict) do
			local namesDict = {}
			if (allSpellsDict[tabName]) then
				for listIndex, spellinfo in ipairs(allSpellsDict[tabName]) do
					if (namesDict[spellinfo.spellName] == nil) then
						namesDict[spellinfo.spellName] = {}
					end
					table.insert(namesDict[spellinfo.spellName], listIndex)
				end
			end

			if (canShowPassives) then
				table.sort(passiveSpells, function(a, b) return a.spellName < b.spellName end)
			end

			for i = 1, table.getn(passiveSpells) do
				local isActiveTalent = namesDict[passiveSpells[i].spellName]
				if (isActiveTalent and allSpellsDict[tabName]) then
					for _, alreadyActiveSpellListIndex in ipairs(isActiveTalent) do
						local spellInfo = allSpellsDict[tabName][alreadyActiveSpellListIndex]
						TalentService:MarkSpellAsTalent(spellInfo)
					end
				elseif (canShowPassives) then
					if (not allSpellsDict[tabName]) then
						allSpellsDict[tabName] = {}
					end
					table.insert(allSpellsDict[tabName], passiveSpells[i])
				end
			end
		end

		for tabName, spells in pairs(allSpellsDict) do
			table.sort(spells, function(a, b) return a.spellName < b.spellName end)
		end

		self:MergeUnlearnedSpells(allSpellsDict, false)

		if (not ShowAllSpellRanksCheckbox or not ShowAllSpellRanksCheckbox:GetChecked()) then
			for tabName, spells in pairs(allSpellsDict) do
				allSpellsDict[tabName] = self:FilterHighestRanks(spells)
			end
		end

		return allSpellsDict
	end;

	GetOtherTabSpells = function(self)
		local spellsDict = {}
		local customTabNames = {"Companions", "Mounts", "Toys"}

		for _, tabName in ipairs(customTabNames) do
			local tabSpells = self:GetCustomTabSpells(tabName)
			if (tabSpells[tabName] and table.getn(tabSpells[tabName]) > 0) then
				spellsDict[tabName] = tabSpells[tabName]
			end
		end

		return spellsDict
	end;

	GetAvailableSpells = function(self)
		if (ModernSpellBookFrame.selectedTab == 1) then
			return self:GetPlayerSpells(false), false
		elseif (ModernSpellBookFrame.selectedTab == 2) then
			return self:GetPlayerSpells(true), false
		elseif (ModernSpellBookFrame.selectedTab == 3) then
			return self:GetPetSpells(), true
		elseif (ModernSpellBookFrame.selectedTab == 4) then
			return self:GetOtherTabSpells(), false
		else
			return {}, false
		end
	end;

	SetupInitiallyKnownSpells = function(self)
		ModernSpellBook_DB.knownSpells = {}
		ShowPassiveSpellsCheckBox:SetChecked(true)

		local allInitialSpells = {}
		table.insert(allInitialSpells, self:GetPlayerSpells(false))
		table.insert(allInitialSpells, self:GetPlayerSpells(true))
		table.insert(allInitialSpells, self:GetPetSpells())

		for i = 1, 3 do
			for cat, spellList in pairs(allInitialSpells[i]) do
				for _, spellInfo in ipairs(spellList) do
					local lookupString = spellInfo.spellName.. spellInfo.spellRank
					if (ModernSpellBook_DB.knownSpells[lookupString]) then
						ModernSpellBook_DB.knownSpells[lookupString] = string.gsub(ModernSpellBook_DB.knownSpells[lookupString], MSB_NEW_KEYWORD, "")
					end
				end
			end
		end

		ShowPassiveSpellsCheckBox:SetChecked(ModernSpellBook_DB.showPassives)
	end;

	MergeUnlearnedSpells = function(self, allSpellsDict, showGeneralTab)
		if (not ModernSpellBook_DB.showUnlearned) then return end
		if (not TrainerDataService) then return end
		local unlearned = TrainerDataService:GetUnlearnedSpells()
		if (not unlearned) then return end

		local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()

		for category, spells in pairs(unlearned) do
			local isGeneral = (category == GENERAL)
			if (showGeneralTab == isGeneral) then
				local targetCat = category
				local found = false
				for existingCat, _ in pairs(allSpellsDict) do
					if (existingCat == category) then
						found = true
						break
					end
					if (string.find(string.lower(existingCat), string.lower(string.sub(category, 1, 4)))) then
						targetCat = existingCat
						found = true
						break
					end
				end

				if (not allSpellsDict[targetCat]) then
					allSpellsDict[targetCat] = {}
				end

				for _, spellInfo in ipairs(spells) do
					if (not spellInfo.isPassive or canShowPassives) then
						table.insert(allSpellsDict[targetCat], spellInfo)
					end
				end
			end
		end
	end;

	UpdateSpellCounter = function(self)
		if (not ModernSpellBookFrame.spellCounter) then return end
		if (not ModernSpellBook_DB.showSpellCounter) then
			ModernSpellBookFrame.spellCounter:Hide()
			return
		end

		local learned = 0
		local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
		for i = 1, numTabs do
			local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
			if (not tabName) then break end
			learned = learned + (numSpells or 0)
		end

		local unlearned = 0
		if (TrainerDataService) then
			local unlearnedSpells = TrainerDataService:GetUnlearnedSpells()
			if (unlearnedSpells) then
				for _, spells in pairs(unlearnedSpells) do
					unlearned = unlearned + table.getn(spells)
				end
			end
		end

		local _, englishClass = UnitClass("player")
		local hasTrainerData = ModernSpellBook_DB.trainerSpells and ModernSpellBook_DB.trainerSpells[englishClass]
		if (hasTrainerData and unlearned > 0) then
			ModernSpellBookFrame.spellCounter:SetText(learned .. "/" .. (learned + unlearned) .. " learned")
		elseif (hasTrainerData) then
			ModernSpellBookFrame.spellCounter:SetText(learned .. " learned")
		else
			ModernSpellBookFrame.spellCounter:SetText(learned .. "/? learned")
		end
		ModernSpellBookFrame.spellCounter:Show()
	end;
}

SpellDataService = CSpellDataService()
