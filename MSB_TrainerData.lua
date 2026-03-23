--[[
	Captures class spells from the trainer window and caches them
	in SavedVariables. Used to show unlearned spells (greyed out).
--]]

class "CTrainerDataService"
{
	__init = function(self)
		self.frame = CreateFrame("Frame")
		self.frame:RegisterEvent("TRAINER_SHOW")

		local service = self
		self.frame:SetScript("OnEvent", function()
			C_Timer.After(0.3, function()
				service:CaptureTrainerData()
			end)
		end)
	end;

	-- =================== CAPTURE =============================

	CaptureTrainerData = function(self)
		if (not GetNumTrainerServices) then return end

		local numServices = GetNumTrainerServices()
		if (not numServices or numServices == 0) then return end

		if (not ModernSpellBook_DB.trainerSpells) then
			ModernSpellBook_DB.trainerSpells = {}
		end

		local _, englishClass = UnitClass("player")

		-- Count existing captured spells
		local existingCount = 0
		if (ModernSpellBook_DB.trainerSpells[englishClass]) then
			for _ in pairs(ModernSpellBook_DB.trainerSpells[englishClass]) do
				existingCount = existingCount + 1
			end
		end

		-- Only rescan if trainer has more services than we've captured
		if (existingCount >= numServices) then
			return
		end

		if (not ModernSpellBook_DB.trainerSpells[englishClass]) then
			ModernSpellBook_DB.trainerSpells[englishClass] = {}
		end
		local classSpells = ModernSpellBook_DB.trainerSpells[englishClass]

		-- Enable all filters so we capture everything
		pcall(function()
			if (SetTrainerServiceTypeFilter) then
				SetTrainerServiceTypeFilter("available", 1, 0)
				SetTrainerServiceTypeFilter("unavailable", 1, 0)
				SetTrainerServiceTypeFilter("used", 1, 0)
			end
		end)

		numServices = GetNumTrainerServices()

		local currentSpecHeader = GENERAL or "General"

		local generalCategories = {
			["Defense"] = true,
			["Weapons"] = true,
			["Armor"] = true,
			["Plate Mail"] = true,
			["Mail"] = true,
			["Leather"] = true,
			["Shield"] = true,
		}

		local skipSpells = {
			["Plate Mail"] = true, ["Mail"] = true, ["Leather"] = true,
			["Shield"] = true, ["Block"] = true, ["Parry"] = true, ["Dodge"] = true,
			["Dual Wield"] = true,
		}

		for i = 1, numServices do
			local name, rank, category, expanded
			local ok, r1, r2, r3, r4 = pcall(GetTrainerServiceInfo, i)
			if (ok) then
				name = r1 and string.gsub(r1, "^%s+", "") or nil
				name = name and string.gsub(name, "%s+$", "") or nil
				rank = r2 and string.gsub(r2, "^%s+", "") or ""
				rank = string.gsub(rank, "%s+$", "")
				category = r3 and string.gsub(r3, "^%s+", "") or ""
				category = string.gsub(category, "%s+$", "")
			end

			if (name and name ~= "") then
				local icon = ""
				if (GetTrainerServiceIcon) then
					local iconOk, iconResult = pcall(GetTrainerServiceIcon, i)
					if (iconOk) then icon = iconResult or "" end
				end

				if (skipSpells[name]) then
					-- do nothing
				elseif (not icon or icon == "" or icon == 0) then
					if (generalCategories[name]) then
						currentSpecHeader = GENERAL or "General"
					else
						currentSpecHeader = name
					end
				else
					local levelReq = 0
					if (GetTrainerServiceLevelReq) then
						local lvlOk, lvlResult = pcall(GetTrainerServiceLevelReq, i)
						if (lvlOk) then levelReq = lvlResult or 0 end
					end

					local description = nil
					pcall(function()
						if (GetTrainerServiceDescription) then
							description = GetTrainerServiceDescription(i)
							if (description) then
								description = string.gsub(string.gsub(description, "^%s+", ""), "%s+$", "")
							end
						end
					end)

					local cost = nil
					pcall(function()
						if (GetTrainerServiceCost) then
							cost = GetTrainerServiceCost(i)
						end
					end)

					local key = name .. (rank or "")
					classSpells[key] = {
						name = name,
						rank = rank or "",
						icon = icon,
						levelReq = levelReq,
						serviceType = category or "",
						category = currentSpecHeader,
						description = description,
						cost = cost,
					}
				end
			end
		end

		local count = 0
		for _ in pairs(classSpells) do count = count + 1 end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ModernSpellBook:|r Captured " .. count .. " spells from trainer.")

		if (ModernSpellBookFrame:IsVisible()) then
			ModernSpellBookFrame:DrawPage()
		end
	end;

	-- ================= UNLEARNED SPELLS =======================

	GetUnlearnedSpells = function(self)
		if (not ModernSpellBook_DB.trainerSpells) then return {} end

		local _, englishClass = UnitClass("player")
		local classSpells = ModernSpellBook_DB.trainerSpells[englishClass]
		if (not classSpells) then return {} end

		-- Build a set of currently known spell+rank combos
		local knownSet = {}
		local knownHighestRank = {}
		local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
		for i = 1, numTabs do
			local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
			if (not tabName) then break end
			for s = offset + 1, offset + numSpells do
				local spellName, spellRank = GetSpellName(s, BOOKTYPE_SPELL)
				if (spellName) then
					knownSet[spellName .. (spellRank or "")] = true
					local _, _, num = string.find(spellRank or "", "(%d+)")
					local rankNum = tonumber(num) or 0
					if (not knownHighestRank[spellName] or rankNum > knownHighestRank[spellName]) then
						knownHighestRank[spellName] = rankNum
					end
				end
			end
		end

		-- Mark all lower ranks as known
		for key, spellData in pairs(classSpells) do
			local _, _, num = string.find(spellData.rank or "", "(%d+)")
			local rankNum = tonumber(num) or 0
			local highest = knownHighestRank[spellData.name]
			if (highest and rankNum <= highest) then
				knownSet[key] = true
			end
		end

		-- Find spells whose Rank 1 comes from an unlearned talent
		local talentBlockedSpells = {}
		for t = 1, GetNumTalentTabs() do
			local talentGroupName = GetTalentTabInfo(t)
			if (talentGroupName) then
				for i = 1, GetNumTalents(t) do
					local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(t, i)
					if (nameTalent and currRank == 0) then
						local trainerHas = false
						for key, spellData in pairs(classSpells) do
							if (spellData.name == nameTalent) then
								trainerHas = true
								break
							end
						end
						if (trainerHas) then
							talentBlockedSpells[nameTalent] = true
						end
					end
				end
			end
		end

		-- Find spells in trainer data that are NOT known
		local unlearnedByCategory = {}
		for key, spellData in pairs(classSpells) do
			if (not knownSet[key]) then
				local cat = spellData.category
				if (cat == "") then cat = "Unknown" end
				if (not unlearnedByCategory[cat]) then
					unlearnedByCategory[cat] = {}
				end
				table.insert(unlearnedByCategory[cat], {
					spellName = spellData.name,
					spellRank = spellData.rank,
					spellIcon = spellData.icon,
					spellID = nil,
					bookType = nil,
					description = spellData.description,
					cost = spellData.cost,
					isPassive = (spellData.rank == "Passive" or spellData.rank == PET_PASSIVE),
					isTalent = false,
					isPetSpell = false,
					isUnlearned = true,
					talentBlocked = talentBlockedSpells[spellData.name] or false,
					levelReq = spellData.levelReq,
					castName = nil,
					category = cat,
				})
			end
		end

		-- Also add unlearned talents
		local trainerSpellNames = {}
		if (classSpells) then
			for key, spellData in pairs(classSpells) do
				if (not trainerSpellNames[spellData.name]) then
					trainerSpellNames[spellData.name] = true
				end
			end
		end

		for t = 1, GetNumTalentTabs() do
			local talentGroupName = GetTalentTabInfo(t)
			if (talentGroupName) then
				for i = 1, GetNumTalents(t) do
					local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(t, i)
					if (nameTalent and currRank == 0) then
						local isKnown = false
						for knownKey, _ in pairs(knownSet) do
							if (string.find(knownKey, nameTalent, 1, true)) then
								isKnown = true
								break
							end
						end

						if (not isKnown) then
							local trainerHasRanks = trainerSpellNames[nameTalent]

							if (not unlearnedByCategory[talentGroupName]) then
								unlearnedByCategory[talentGroupName] = {}
							end

							local alreadyAdded = false
							for _, s in ipairs(unlearnedByCategory[talentGroupName]) do
								if (s.spellName == nameTalent and (not trainerHasRanks or s.spellRank == "Rank 1")) then
									alreadyAdded = true
									break
								end
							end

							if (not alreadyAdded) then
								local rankLabel
								local isPassiveTalent
								if (trainerHasRanks) then
									rankLabel = "Talent"
									isPassiveTalent = false
								elseif (maxRank == 1) then
									rankLabel = "Talent"
									isPassiveTalent = false
								else
									rankLabel = nil
									isPassiveTalent = true
								end

								if (rankLabel) then
								table.insert(unlearnedByCategory[talentGroupName], {
									spellName = nameTalent,
									spellRank = rankLabel,
									spellIcon = icon,
									spellID = nil,
									bookType = nil,
									isPassive = isPassiveTalent,
									isTalent = true,
									talentGrid = {t, i},
									isPetSpell = false,
									isUnlearned = true,
									levelReq = 10 + (tier - 1) * 5,
									castName = nil,
									category = talentGroupName,
								})
							end -- rankLabel check
							end -- alreadyAdded check
						end -- isKnown check
					end
				end
			end
		end

		-- Sort each category
		for cat, spells in pairs(unlearnedByCategory) do
			local groupMinLevel = {}
			for _, sp in ipairs(spells) do
				local lvl = sp.levelReq or 0
				if (not groupMinLevel[sp.spellName] or lvl < groupMinLevel[sp.spellName]) then
					groupMinLevel[sp.spellName] = lvl
				end
			end

			table.sort(spells, function(a, b)
				local aGroupLvl = groupMinLevel[a.spellName] or 0
				local bGroupLvl = groupMinLevel[b.spellName] or 0
				if (aGroupLvl ~= bGroupLvl) then
					return aGroupLvl < bGroupLvl
				end
				if (a.spellName ~= b.spellName) then
					return a.spellName < b.spellName
				end
				return (a.levelReq or 0) < (b.levelReq or 0)
			end)
		end

		return unlearnedByCategory
	end;
}

TrainerDataService = CTrainerDataService()
