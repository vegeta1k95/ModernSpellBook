--[[
	Captures class spells from the trainer window and stores them
	in the unified DB.spells table with learned=false.
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

		-- Detect if this is a class trainer by checking if any
		-- service header matches a talent tab or class spell tab name
		local classCategories = {}
		for t = 1, GetNumTalentTabs() do
			local name = GetTalentTabInfo(t)
			if (name) then classCategories[name] = true end
		end
		local numSpellTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
		for i = 1, numSpellTabs do
			local name = GetSpellTabInfo(i)
			if (name) then classCategories[name] = true end
		end
		classCategories[GENERAL or "General"] = true

		local isClassTrainer = false
		for i = 1, numServices do
			local ok, name = pcall(GetTrainerServiceInfo, i)
			if (ok and name) then
				name = string.gsub(string.gsub(name, "^%s+", ""), "%s+$", "")
				if (classCategories[name]) then
					isClassTrainer = true
					break
				end
			end
		end

		if (not isClassTrainer) then return end

		-- Skip if we already scanned and trainer hasn't changed
		if (ModernSpellBook_DB.trainerScanned and ModernSpellBook_DB.trainerServiceCount) then
			if (numServices <= ModernSpellBook_DB.trainerServiceCount) then
				return
			end
		end

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
		local currentSpecIsValid = true

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

		local capturedCount = 0

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
					-- Category header
					if (generalCategories[name]) then
						currentSpecHeader = GENERAL or "General"
						currentSpecIsValid = true
					elseif (classCategories[name]) then
						currentSpecHeader = name
						currentSpecIsValid = true
					else
						currentSpecHeader = name
						currentSpecIsValid = false
					end
				elseif (not currentSpecIsValid) then
					-- Skip spells under non-class categories (e.g. Poisons)
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

					local key = MSB_SpellKey(name, rank or "")
					local entry = ModernSpellBook_DB.spells[key]

					if (not entry) then
						-- New spell from trainer, player doesn't know it yet
						ModernSpellBook_DB.spells[key] = {
							icon = icon,
							category = currentSpecHeader,
							desc = description,
							cost = cost,
							level_req = levelReq,
							keywords = string.lower(name .. ";" .. (rank or "") .. ";" .. currentSpecHeader .. ";"),
							learned = false,
							seen_new = true,
							seen_trainable = false,
						}
						capturedCount = capturedCount + 1
					elseif (not entry.learned) then
						-- Already registered as unlearned, update trainer data
						entry.icon = icon
						entry.category = currentSpecHeader
						entry.desc = description
						entry.cost = cost
						entry.level_req = levelReq
						capturedCount = capturedCount + 1
					else
						-- Already learned, just update metadata
						capturedCount = capturedCount + 1
					end
				end
			end
		end

		ModernSpellBook_DB.trainerScanned = true
		ModernSpellBook_DB.trainerServiceCount = numServices

		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ModernSpellBook:|r Captured " .. capturedCount .. " spells from trainer.")

		if (ModernSpellBookFrame:IsVisible()) then
			SpellBook:DrawPage()
		end
	end;

	-- ================= UNLEARNED SPELLS =======================

	GetUnlearnedSpells = function(self)
		-- Build a set of currently known spells from spellbook
		local knownSet = {}
		local knownHighestRank = {}
		local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
		for i = 1, numTabs do
			local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
			if (not tabName) then break end
			for s = offset + 1, offset + numSpells do
				local spellName, spellRank = GetSpellName(s, BOOKTYPE_SPELL)
				if (spellName) then
					knownSet[MSB_SpellKey(spellName, spellRank or "")] = true
					local _, _, num = string.find(spellRank or "", "(%d+)")
					local rankNum = tonumber(num) or 0
					if (not knownHighestRank[spellName] or rankNum > knownHighestRank[spellName]) then
						knownHighestRank[spellName] = rankNum
					end
				end
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
						for spellKey, entry in pairs(ModernSpellBook_DB.spells) do
							if (not entry.learned and string.find(spellKey, nameTalent, 1, true)) then
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

		local unlearnedByCategory = {}
		local trainerSpellNames = {}

		-- Collect unlearned spells from DB (trainer data)
		if (ModernSpellBook_DB.trainerScanned) then
			for spellKey, entry in pairs(ModernSpellBook_DB.spells) do
				if (not entry.learned) then
					local pipePos = string.find(spellKey, "|", 1, true)
					local name = string.sub(spellKey, 1, pipePos - 1)
					local rank = string.sub(spellKey, pipePos + 1)

					if (knownSet[spellKey]) then
						entry.learned = true
					else
						local _, _, num = string.find(rank or "", "(%d+)")
						local rankNum = tonumber(num) or 0
						local highest = knownHighestRank[name]
						if (highest and (rankNum <= highest or highest == 0)) then
							entry.learned = true
						else
							local cat = entry.category or "Unknown"
							if (not unlearnedByCategory[cat]) then
								unlearnedByCategory[cat] = {}
							end
							table.insert(unlearnedByCategory[cat], {
								spellName = name,
								spellRank = rank,
								spellIcon = entry.icon,
								spellID = nil,
								bookType = nil,
								description = entry.desc,
								cost = entry.cost,
								isPassive = (rank == "Passive" or rank == PET_PASSIVE),
								isTalent = false,
								isPetSpell = false,
								isUnlearned = true,
								talentBlocked = talentBlockedSpells[name] or false,
								levelReq = entry.level_req,
								castName = nil,
								category = cat,
							})
							trainerSpellNames[name] = true
						end
					end
				end
			end
		end

		-- Always add unlearned talents (doesn't require trainer data)
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
							end
							end
						end
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
