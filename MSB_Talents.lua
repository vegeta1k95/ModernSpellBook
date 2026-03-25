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

		local key = MSB_SpellKey(spellInfo.spellName, spellInfo.spellRank)
		local entry = ModernSpellBook_DB.spells[key]

		if (entry and entry.keywords and not string.find(entry.keywords, talentKeyword)) then
			entry.keywords = entry.keywords .. talentKeyword
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

						SpellDataService:RegisterSpell(spellInfo)
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
		local keysToRemove = {}
		for spellKey, entry in pairs(ModernSpellBook_DB.spells) do
			for talentGroupName, talents in pairs(talentGridPositions) do
				for _, talentInfo in ipairs(talents) do
					if (string.find(spellKey, talentInfo.spellName, 1, true)) then
						table.insert(keysToRemove, spellKey)
					end
				end
			end
		end
		for _, key in ipairs(keysToRemove) do
			ModernSpellBook_DB.spells[key] = nil
		end
	end;
}

TalentService = CTalentService()
