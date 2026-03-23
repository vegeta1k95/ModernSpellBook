--[[
	Talent data integration: marks talent-derived spells,
	collects talent grid positions, handles talent resets.
--]]

local talentKeyword = string.lower(TALENT.. ";")

class "CTalentService"
{
	__init = function(self)
		local service = self
		ModernSpellBookFrame.PLAYER_TALENT_UPDATE = function()
			if (service:GetAllTalentPointsSpent() == 0) then
				service:ResetKnownTalents()
			end
			ModernSpellBookFrame.SPELLS_CHANGED()
		end
		ModernSpellBookFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
	end;

	-- =================== MARK TALENT =============================

	MarkSpellAsTalent = function(self, spellInfo)
		spellInfo.isTalentAbility = true

		local lookupString = spellInfo.spellName.. spellInfo.spellRank
		local lookupContents = ModernSpellBook_DB.knownSpells[lookupString]

		if (lookupContents and not string.find(lookupContents, talentKeyword)) then
			ModernSpellBook_DB.knownSpells[lookupString] = lookupContents.. talentKeyword
		end
	end;

	-- =================== QUERY ===================================

	GetAllTalentPointsSpent = function(self)
		local totalTalentPointsSpent = 0
		for i = 1, GetNumTalentTabs() do
			local name, iconTexture, pointsSpent = GetTalentTabInfo(i)
			totalTalentPointsSpent = totalTalentPointsSpent + (pointsSpent or 0)
		end
		return totalTalentPointsSpent
	end;

	GetAllTalents = function(self, showOnlyKnown)
		local talentGridPositions = {}
		for t = 1, GetNumTalentTabs() do
			local talentGroupName, _, pointsSpent = GetTalentTabInfo(t)
			if (not talentGroupName) then break end

			if (pointsSpent > 0 or not showOnlyKnown) then
				talentGridPositions[talentGroupName] = {}

				for i = 1, GetNumTalents(t) do
					local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(t, i)
					if (nameTalent and (currRank > 0 or not showOnlyKnown)) then
						local spellInfo = {
							spellName = nameTalent,
							spellIcon = icon,
							spellRank = PET_PASSIVE,
							spellID = nil,
							isPassive = true,
							isTalent = true,
							talentGrid = {t, i},
							category = talentGroupName
						}

						local lookupString = spellInfo.spellName.. spellInfo.spellRank
						if (ModernSpellBook_DB.knownSpells[lookupString] == nil) then
							ModernSpellBook_DB.knownSpells[lookupString] = SpellDataService:BuildSpellLookupTable(spellInfo).. string.lower(SpellDataService:CreateLookup(NEW))
						end

						table.insert(talentGridPositions[talentGroupName], spellInfo)
					end
				end
			end
		end

		return talentGridPositions
	end;

	-- =================== RESET ===================================

	ResetKnownTalents = function(self)
		local talentGridPositions = self:GetAllTalents(false)
		for knownSpell, _ in pairs(ModernSpellBook_DB.knownSpells) do
			for talentGroupName, talents in pairs(talentGridPositions) do
				for _, talentInfo in ipairs(talents) do
					local lookupString = talentInfo.spellName
					if (string.find(knownSpell, lookupString)) then
						ModernSpellBook_DB.knownSpells[knownSpell] = nil
					end
				end
			end
		end
	end;
}

TalentService = CTalentService()
