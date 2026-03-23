-- TrainerData.lua
-- Captures all class spells from the trainer window and caches them in SavedVariables.
-- This data is then used to show unlearned spells (greyed out) in the spellbook.

local trainerCaptureFrame = CreateFrame("Frame")
trainerCaptureFrame:RegisterEvent("TRAINER_SHOW")

trainerCaptureFrame:SetScript("OnEvent", function()
    -- Delay slightly to let trainer data populate
    C_Timer.After(0.3, function()
        ModernSpellBookFrame:CaptureTrainerData()
    end)
end)

function ModernSpellBookFrame:CaptureTrainerData()
    if not GetNumTrainerServices then return end

    local numServices = GetNumTrainerServices()
    if not numServices or numServices == 0 then return end

    -- Initialize storage
    if not ModernSpellBook_DB.trainerSpells then
        ModernSpellBook_DB.trainerSpells = {}
    end

    local _, englishClass = UnitClass("player")

    -- Count existing captured spells
    local existingCount = 0
    if ModernSpellBook_DB.trainerSpells[englishClass] then
        for _ in pairs(ModernSpellBook_DB.trainerSpells[englishClass]) do
            existingCount = existingCount + 1
        end
    end

    -- Only rescan if trainer has more services than we've captured
    if existingCount >= numServices then
        return
    end

    if not ModernSpellBook_DB.trainerSpells[englishClass] then
        ModernSpellBook_DB.trainerSpells[englishClass] = {}
    end
    local classSpells = ModernSpellBook_DB.trainerSpells[englishClass]

    -- We need to see ALL spells, including unavailable ones
    -- Enable all filters so we capture everything
    pcall(function()
        if SetTrainerServiceTypeFilter then
            SetTrainerServiceTypeFilter("available", 1, 0)
            SetTrainerServiceTypeFilter("unavailable", 1, 0)
            SetTrainerServiceTypeFilter("used", 1, 0)
        end
    end)

    -- Re-read count after filter change
    numServices = GetNumTrainerServices()

    local currentSpecHeader = GENERAL or "General"

    -- Trainer categories that should map to General
    local generalCategories = {
        ["Defense"] = true,
        ["Weapons"] = true,
        ["Armor"] = true,
        ["Plate Mail"] = true,
        ["Mail"] = true,
        ["Leather"] = true,
        ["Shield"] = true,
    }

    -- Spells to skip entirely (armor/weapon proficiencies that don't appear in spellbook when learned)
    local skipSpells = {
        ["Plate Mail"] = true, ["Mail"] = true, ["Leather"] = true,
        ["Shield"] = true, ["Block"] = true, ["Parry"] = true, ["Dodge"] = true,
        ["Dual Wield"] = true,
    }

    for i = 1, numServices do
        local name, rank, category, expanded
        local ok, r1, r2, r3, r4 = pcall(GetTrainerServiceInfo, i)
        if ok then
            name = r1 and string.gsub(r1, "^%s+", "") or nil
            name = name and string.gsub(name, "%s+$", "") or nil
            rank = r2 and string.gsub(r2, "^%s+", "") or ""
            rank = string.gsub(rank, "%s+$", "")
            category = r3 and string.gsub(r3, "^%s+", "") or ""
            category = string.gsub(category, "%s+$", "")
        end

        if name and name ~= "" then
            local icon = ""
            if GetTrainerServiceIcon then
                local iconOk, iconResult = pcall(GetTrainerServiceIcon, i)
                if iconOk then icon = iconResult or "" end
            end

            -- Skip armor/weapon proficiency spells
            if skipSpells[name] then
                -- do nothing
            elseif not icon or icon == "" or icon == 0 then
                if generalCategories[name] then
                    currentSpecHeader = GENERAL or "General"
                else
                    currentSpecHeader = name
                end
            else
                local levelReq = 0
                if GetTrainerServiceLevelReq then
                    local lvlOk, lvlResult = pcall(GetTrainerServiceLevelReq, i)
                    if lvlOk then levelReq = lvlResult or 0 end
                end

                -- Capture spell description for tooltip display
                local description = nil
                pcall(function()
                    if GetTrainerServiceDescription then
                        description = GetTrainerServiceDescription(i)
                        if description then
                            description = string.gsub(string.gsub(description, "^%s+", ""), "%s+$", "")
                        end
                    end
                end)

                -- Also capture cost
                local cost = nil
                pcall(function()
                    if GetTrainerServiceCost then
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

    -- No need to restore filters - trainer window handles its own state

    local count = 0
    for _ in pairs(classSpells) do count = count + 1 end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ModernSpellBook:|r Captured " .. count .. " spells from trainer.")

    -- Refresh the spellbook if visible
    if ModernSpellBookFrame:IsVisible() then
        ModernSpellBookFrame:DrawPage()
    end
end

-- Get unlearned spells from cached trainer data, grouped by category
function ModernSpellBookFrame:GetUnlearnedSpells()
    if not ModernSpellBook_DB.trainerSpells then return {} end

    local _, englishClass = UnitClass("player")
    local classSpells = ModernSpellBook_DB.trainerSpells[englishClass]
    if not classSpells then return {} end

    -- Build a set of currently known spell+rank combos
    local knownSet = {}
    local knownHighestRank = {}
    local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 4
    for i = 1, numTabs do
        local tabName, texture, offset, numSpells = GetSpellTabInfo(i)
        if not tabName then break end
        for s = offset + 1, offset + numSpells do
            local spellName, spellRank = GetSpellName(s, BOOKTYPE_SPELL)
            if spellName then
                knownSet[spellName .. (spellRank or "")] = true
                -- Track highest known rank per spell name
                local _, _, num = string.find(spellRank or "", "(%d+)")
                local rankNum = tonumber(num) or 0
                if not knownHighestRank[spellName] or rankNum > knownHighestRank[spellName] then
                    knownHighestRank[spellName] = rankNum
                end
            end
        end
    end

    -- Mark all lower ranks as known (replaced spells no longer in spellbook)
    for key, spellData in pairs(classSpells) do
        local _, _, num = string.find(spellData.rank or "", "(%d+)")
        local rankNum = tonumber(num) or 0
        local highest = knownHighestRank[spellData.name]
        if highest and rankNum <= highest then
            knownSet[key] = true
        end
    end

    -- Find spells whose Rank 1 comes from an unlearned talent
    -- Higher ranks of these spells should not show as "available to train"
    local talentBlockedSpells = {}
    for t = 1, GetNumTalentTabs() do
        local talentGroupName = GetTalentTabInfo(t)
        if talentGroupName then
            for i = 1, GetNumTalents(t) do
                local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(t, i)
                if nameTalent and currRank == 0 then
                    -- Check if trainer has higher ranks of this spell
                    local trainerHas = false
                    for key, spellData in pairs(classSpells) do
                        if spellData.name == nameTalent then
                            trainerHas = true
                            break
                        end
                    end
                    if trainerHas then
                        talentBlockedSpells[nameTalent] = true
                    end
                end
            end
        end
    end

    -- Find spells in trainer data that are NOT known
    local unlearnedByCategory = {}
    for key, spellData in pairs(classSpells) do
        if not knownSet[key] then
            local cat = spellData.category
            if cat == "" then cat = "Unknown" end
            if not unlearnedByCategory[cat] then
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
    -- If trainer has Rank 2+ of a talent name, it means the talent grants Rank 1
    -- Otherwise, it's a passive talent bonus
    local trainerSpellNames = {}
    if classSpells then
        for key, spellData in pairs(classSpells) do
            if not trainerSpellNames[spellData.name] then
                trainerSpellNames[spellData.name] = true
            end
        end
    end

    for t = 1, GetNumTalentTabs() do
        local talentGroupName = GetTalentTabInfo(t)
        if talentGroupName then
            for i = 1, GetNumTalents(t) do
                local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(t, i)
                if nameTalent and currRank == 0 then
                    -- Check if already known (as spell or talent)
                    local isKnown = false
                    for knownKey, _ in pairs(knownSet) do
                        if string.find(knownKey, nameTalent, 1, true) then
                            isKnown = true
                            break
                        end
                    end

                    if not isKnown then
                        -- Does the trainer have higher ranks of this spell?
                        local trainerHasRanks = trainerSpellNames[nameTalent]

                        if not unlearnedByCategory[talentGroupName] then
                            unlearnedByCategory[talentGroupName] = {}
                        end

                        -- Check not already added
                        local alreadyAdded = false
                        for _, s in ipairs(unlearnedByCategory[talentGroupName]) do
                            if s.spellName == nameTalent and (not trainerHasRanks or s.spellRank == "Rank 1") then
                                alreadyAdded = true
                                break
                            end
                        end

                        if not alreadyAdded then
                            -- Determine rank label:
                            -- - Trainer has higher ranks -> this is "Rank 1"
                            -- - Single rank talent (maxRank == 1) -> "Talent" (likely active spell)
                            -- - Multi-rank talent without trainer ranks -> passive buff
                            local rankLabel
                            local isPassiveTalent
                            if trainerHasRanks then
                                rankLabel = "Talent"
                                isPassiveTalent = false
                            elseif maxRank == 1 then
                                rankLabel = "Talent"
                                isPassiveTalent = false
                            else
                                -- Multi-rank passive talent - skip entirely
                                rankLabel = nil
                                isPassiveTalent = true
                            end

                            if rankLabel then
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

    -- Sort each category: group by spell name, order groups by their lowest levelReq,
    -- within a group sort by levelReq ascending
    for cat, spells in pairs(unlearnedByCategory) do
        -- Find the lowest levelReq for each spell name (defines group order)
        local groupMinLevel = {}
        for _, sp in ipairs(spells) do
            local lvl = sp.levelReq or 0
            if not groupMinLevel[sp.spellName] or lvl < groupMinLevel[sp.spellName] then
                groupMinLevel[sp.spellName] = lvl
            end
        end

        table.sort(spells, function(a, b)
            local aGroupLvl = groupMinLevel[a.spellName] or 0
            local bGroupLvl = groupMinLevel[b.spellName] or 0
            if aGroupLvl ~= bGroupLvl then
                return aGroupLvl < bGroupLvl
            end
            -- Same group level - keep same spell names together
            if a.spellName ~= b.spellName then
                return a.spellName < b.spellName
            end
            -- Same spell - sort by rank level
            return (a.levelReq or 0) < (b.levelReq or 0)
        end)
    end

    return unlearnedByCategory
end
