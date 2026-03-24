-- Temporary debug: run /msbdebug in chat

SLASH_MSBDEBUG1 = "/msbdebug"
SlashCmdList["MSBDEBUG"] = function()
	local c = DEFAULT_CHAT_FRAME

	c:AddMessage("=== SPELL TABS ===")
	local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
	for i = 1, numTabs do
		local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
		if (not tabName) then break end
		c:AddMessage("  SpellTab " .. i .. ": name=" .. tostring(tabName) .. " icon=" .. tostring(texture) .. " offset=" .. tostring(offset) .. " numSpells=" .. tostring(numSpells))
	end

	c:AddMessage("=== TALENT TABS ===")
	for t = 1, GetNumTalentTabs() do
		local tabName, tabIcon, pointsSpent = GetTalentTabInfo(t)
		c:AddMessage("  TalentTab " .. t .. ": name=" .. tostring(tabName) .. " icon=" .. tostring(tabIcon) .. " points=" .. tostring(pointsSpent))
	end

	c:AddMessage("=== SELECTED TAB ===")
	c:AddMessage("  selectedTab=" .. tostring(ModernSpellBookFrame.selectedTab))

	c:AddMessage("=== AllSpells ===")
	if (ModernSpellBookFrame.AllSpells) then
		for cat, spells in pairs(ModernSpellBookFrame.AllSpells) do
			c:AddMessage("  Category: " .. tostring(cat) .. " (" .. table.getn(spells) .. " spells)")
		end
	else
		c:AddMessage("  AllSpells is NIL")
	end

	-- Phased debug for GetPlayerSpells(false)
	c:AddMessage("=== GetPlayerSpells(false) PHASED ===")
	local phases = ""
	local ok, err = pcall(function()
		local allSpellsDict = {}
		local passiveSpellsDict = {}
		local canShowPassives = ShowPassiveSpellsCheckBox:GetChecked()

		-- Phase 0: Collect spells from tabs
		local skipTabs = {}
		if (COMPANIONS) then skipTabs[COMPANIONS] = true end
		skipTabs["Companions"] = true
		skipTabs["Toys"] = true
		skipTabs["Mounts"] = true

		local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
		for i = 1, numTabs do
			local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
			if (not tabName) then break end
			if (not skipTabs[tabName] and not (tabName == GENERAL)) then
				allSpellsDict[tabName] = {}
				passiveSpellsDict[tabName] = {}
				for s = offset + 1, offset + numSpells do
					if (not IsSpellHidden(s, BOOKTYPE_SPELL)) then
						local spellInfo = SpellDataService:SpellInfoFromSpellBookItem(tabName, s)
						if (spellInfo.isPassive) then
							table.insert(passiveSpellsDict[tabName], spellInfo)
						else
							table.insert(allSpellsDict[tabName], spellInfo)
						end
					end
				end
			end
		end
		phases = phases .. "0"
		local catList = ""
		for cat, spells in pairs(allSpellsDict) do
			catList = catList .. cat .. "(" .. table.getn(spells) .. ") "
		end
		c:AddMessage("  Phase 0 (collect tabs): " .. catList)

		-- Phase 1: Collect talent categories
		local existingCategories = {}
		for cat, _ in pairs(allSpellsDict) do
			table.insert(existingCategories, cat)
		end
		phases = phases .. ",1"
		c:AddMessage("  Phase 1 (existing categories): " .. table.concat(existingCategories, ", "))

		-- Phase 2: Get talents
		local talentGridPositions = TalentService:GetAllTalents(true)
		phases = phases .. ",2"
		local talentCats = ""
		for cat, talents in pairs(talentGridPositions) do
			talentCats = talentCats .. cat .. "(" .. table.getn(talents) .. ") "
		end
		c:AddMessage("  Phase 2 (talent groups): " .. talentCats)

		-- Phase 3: Fuzzy match talents to spell categories
		local talentKeys = {}
		for k, _ in pairs(talentGridPositions) do
			table.insert(talentKeys, k)
		end
		for _, origTalentGroupName in ipairs(talentKeys) do
			local talents = talentGridPositions[origTalentGroupName]
			local talentGroupName = origTalentGroupName
			if (allSpellsDict[talentGroupName] == nil) then
				local matched = false
				for _, knownGroup in ipairs(existingCategories) do
					if (string.find(string.lower(knownGroup), string.lower(string.sub(talentGroupName, 1, 4)))) then
						c:AddMessage("  Phase 3: matched '" .. talentGroupName .. "' -> '" .. knownGroup .. "'")
						talentGroupName = knownGroup
						matched = true
						break
					end
				end
				if (not matched) then
					c:AddMessage("  Phase 3: NO MATCH for '" .. talentGroupName .. "', creating new category")
					allSpellsDict[talentGroupName] = {}
					table.insert(existingCategories, talentGroupName)
				end
			else
				c:AddMessage("  Phase 3: exact match '" .. talentGroupName .. "'")
			end
			if (passiveSpellsDict[talentGroupName] == nil) then
				passiveSpellsDict[talentGroupName] = {}
			end
			for i = 1, table.getn(talents) do
				table.insert(passiveSpellsDict[talentGroupName], talents[i])
			end
		end
		phases = phases .. ",3"

		-- Phase 4: Merge passives with actives
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
			for i = 1, table.getn(passiveSpells) do
				local isActiveTalent = namesDict[passiveSpells[i].spellName]
				if (isActiveTalent and allSpellsDict[tabName]) then
					-- mark as talent
				elseif (canShowPassives) then
					if (not allSpellsDict[tabName]) then
						allSpellsDict[tabName] = {}
					end
					table.insert(allSpellsDict[tabName], passiveSpells[i])
				end
			end
		end
		phases = phases .. ",4"

		-- Phase 5: Sort
		for tabName, spells in pairs(allSpellsDict) do
			table.sort(spells, function(a, b) return a.spellName < b.spellName end)
		end
		phases = phases .. ",5"

		-- Phase 6: Merge unlearned
		SpellDataService:MergeUnlearnedSpells(allSpellsDict, false)
		phases = phases .. ",6"

		-- Phase 7: Filter ranks
		if (not ShowAllSpellRanksCheckbox or not ShowAllSpellRanksCheckbox:GetChecked()) then
			for tabName, spells in pairs(allSpellsDict) do
				allSpellsDict[tabName] = SpellDataService:FilterHighestRanks(spells)
			end
		end
		phases = phases .. ",7"

		-- Final result
		local finalCats = ""
		for cat, spells in pairs(allSpellsDict) do
			finalCats = finalCats .. cat .. "(" .. table.getn(spells) .. ") "
		end
		c:AddMessage("  RESULT: " .. finalCats)
	end)

	if (ok) then
		c:AddMessage("  All phases passed: " .. phases)
	else
		c:AddMessage("  |cffff0000CRASHED|r after phases: " .. phases)
		c:AddMessage("  Error: " .. tostring(err))
	end
end
