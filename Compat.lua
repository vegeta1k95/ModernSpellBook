-- Compatibility layer for Turtle WoW (1.12.1 client, Interface 11200)
-- Provides polyfills for APIs that exist in Classic SoD but not in vanilla.

MSB_COMPAT_LOADED = true

-- Global string fallbacks (some don't exist in vanilla 1.12.1)
if not TALENT then TALENT = "Talent" end
if not NEW then NEW = "New" end
if not SPELLBOOK then SPELLBOOK = "Spellbook" end
if not PET_PASSIVE then PET_PASSIVE = "Passive" end
if not GENERAL then GENERAL = "General" end


-- Lua 5.0 compat: string.gmatch might not exist
if not string.gmatch then
    string.gmatch = string.gfind
end

-- C_Timer.After polyfill using OnUpdate
if not C_Timer then
    C_Timer = {}
end
if not C_Timer.After then
    local timerFrame = CreateFrame("Frame")
    timerFrame.timers = {}
    timerFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        local i = 1
        while i <= table.getn(timerFrame.timers) do
            local timer = timerFrame.timers[i]
            if now >= timer.endTime then
                table.remove(timerFrame.timers, i)
                timer.func()
            else
                i = i + 1
            end
        end
        if table.getn(timerFrame.timers) == 0 then
            timerFrame:Hide()
        end
    end)
    timerFrame:Hide()

    C_Timer.After = function(delay, func)
        table.insert(timerFrame.timers, {
            endTime = GetTime() + delay,
            func = func
        })
        timerFrame:Show()
    end
end

-- SOUNDKIT polyfill (vanilla uses string sound names, not numeric IDs)
if not SOUNDKIT then
    SOUNDKIT = {
        IG_MAINMENU_OPTION_CHECKBOX_ON = "igMainMenuOptionCheckBoxOn",
        IG_ABILITY_PAGE_TURN = "igAbilityPageTurn",
        IG_SPELLBOOK_OPEN = "igSpellBookOpen",
        IG_SPELLBOOK_CLOSE = "igSpellBookClose",
    }
end

-- InCombatLockdown polyfill
if not InCombatLockdown then
    InCombatLockdown = function()
        return UnitAffectingCombat("player")
    end
end

-- GetSpellBookItemName polyfill (vanilla uses GetSpellName)
if not GetSpellBookItemName then
    GetSpellBookItemName = function(index, bookType)
        return GetSpellName(index, bookType)
    end
end

-- GetSpellBookItemTexture polyfill (vanilla uses GetSpellTexture)
if not GetSpellBookItemTexture then
    GetSpellBookItemTexture = function(index, bookType)
        return GetSpellTexture(index, bookType)
    end
end

-- GetSpellBookItemInfo polyfill
-- In vanilla, returns "SPELL", slotIndex (we use slotIndex as the "spellID")
if not GetSpellBookItemInfo then
    GetSpellBookItemInfo = function(index, bookType)
        local name = GetSpellName(index, bookType)
        if name then
            return "SPELL", index
        end
        return nil, nil
    end
end

-- GetSpellInfo polyfill for vanilla
-- When called with (index, bookType), returns spell data from the spellbook
-- When called with just (index), treats it as a spellbook slot in BOOKTYPE_SPELL
if not GetSpellInfo then
    GetSpellInfo = function(index, bookType)
        if not index then return nil end
        bookType = bookType or BOOKTYPE_SPELL
        local name, rank = GetSpellName(index, bookType)
        if not name then return nil end
        local icon = GetSpellTexture(index, bookType)
        -- Return: name, rank, icon, castTime, minRange, maxRange, spellID
        return name, rank, icon, 0, 0, 0, index
    end
end

-- IsPassiveSpell polyfill (may not exist in Turtle WoW)
if not IsPassiveSpell then
    IsPassiveSpell = function(index, bookType)
        bookType = bookType or BOOKTYPE_SPELL
        local _, rank = GetSpellName(index, bookType)
        if rank and (rank == PASSIVE or rank == "Passive") then
            return true
        end
        return false
    end
end

-- IsSpellHidden polyfill (no hidden spells in vanilla)
if not IsSpellHidden then
    IsSpellHidden = function()
        return false
    end
end

-- GetSpellDescription polyfill (not available in vanilla)
if not GetSpellDescription then
    GetSpellDescription = function()
        return nil
    end
end

-- PRODUCT_CHOICE_PAGE_NUMBER polyfill
if not PRODUCT_CHOICE_PAGE_NUMBER then
    PRODUCT_CHOICE_PAGE_NUMBER = "Page %d / %d"
end

-- CooldownFrame_Set polyfill (vanilla uses CooldownFrame_SetTimer)
if not CooldownFrame_Set then
    if CooldownFrame_SetTimer then
        CooldownFrame_Set = CooldownFrame_SetTimer
    else
        CooldownFrame_Set = function(cooldown, start, duration, enable)
            if cooldown then
                if start and start > 0 and duration and duration > 0 and enable and enable > 0 then
                    cooldown:SetCooldown(start, duration)
                    cooldown:Show()
                else
                    cooldown:Hide()
                end
            end
        end
    end
end

-- RUNES constant (SoD feature, define as empty string to prevent nil errors)
if not RUNES then
    RUNES = "Runes"
end

-- C_Engraving stub (SoD feature, stub out to prevent errors)
if not C_Engraving then
    C_Engraving = {
        RefreshRunesList = function() end,
        ClearExclusiveCategoryFilter = function() end,
        EnableEquippedFilter = function() end,
        GetRuneCategories = function() return {} end,
        GetRunesForCategory = function() return {} end,
        IsRuneEquipped = function() return false end,
    }
end

-- GameTooltip:SetSpellByID polyfill
-- In vanilla, we use GameTooltip:SetSpell(slot, bookType) instead
if not GameTooltip.SetSpellByID then
    GameTooltip.SetSpellByID = function(self, spellID, bookType)
        -- spellID here is actually the spellbook slot index in our compat layer
        if spellID and type(spellID) == "number" then
            GameTooltip:SetSpell(spellID, bookType or BOOKTYPE_SPELL)
        end
    end
end

-- GetTalentLink polyfill (talent links don't exist in vanilla)
if not GetTalentLink then
    GetTalentLink = function(tab, index)
        local name = GetTalentInfo(tab, index)
        if name then
            return "|cff71d5ff[" .. name .. "]|r"
        end
        return nil
    end
end

-- PickupSpellBookItem polyfill (vanilla uses PickupSpell with slot+bookType)
if not PickupSpellBookItem then
    PickupSpellBookItem = function(slot, bookType)
        PickupSpell(slot, bookType or BOOKTYPE_SPELL)
    end
end

-- Polyfill for frame:HookScript method if it doesn't exist
-- Vanilla has global HookScript(frame, script, handler) but not always the method form
do
    local needsPolyfill = false
    local ok, result = pcall(function()
        local testFrame = CreateFrame("Frame")
        local mt = getmetatable(testFrame)
        if not mt or not mt.__index or not mt.__index.HookScript then
            return true
        end
        return false
    end)
    needsPolyfill = ok and result

    if needsPolyfill then
        local testFrame = CreateFrame("Frame")
        local mt = getmetatable(testFrame)
        if mt and mt.__index and type(mt.__index) == "table" then
            mt.__index.HookScript = function(frame, script, func)
                local prev = frame:GetScript(script)
                if prev then
                    frame:SetScript(script, function(a1,a2,a3,a4,a5,a6,a7,a8,a9)
                        prev(a1,a2,a3,a4,a5,a6,a7,a8,a9)
                        func(a1,a2,a3,a4,a5,a6,a7,a8,a9)
                    end)
                else
                    frame:SetScript(script, func)
                end
            end
        end
    end
end

-- UnitClass classID polyfill
-- In vanilla, UnitClass returns (localizedName, englishName) - no classID
-- We provide a helper to get the class color index
MSB_ClassIndices = {
    ["WARRIOR"] = 1,
    ["PALADIN"] = 2,
    ["HUNTER"] = 3,
    ["ROGUE"] = 4,
    ["PRIEST"] = 5,
    ["DEATHKNIGHT"] = 6,
    ["SHAMAN"] = 7,
    ["MAGE"] = 8,
    ["WARLOCK"] = 9,
    ["MONK"] = 10,
    ["DRUID"] = 11,
    ["DEMONHUNTER"] = 12,
}
-- GetShapeshiftForm polyfill (may not exist in Turtle WoW)
if not GetShapeshiftForm then
    GetShapeshiftForm = function()
        for i = 1, 20 do
            local texture, name, isActive = GetShapeshiftFormInfo(i)
            if not texture then return 0 end
            if isActive then return i end
        end
        return 0
    end
end

function MSB_GetClassIndex()
    local _, englishClass = UnitClass("player")
    return MSB_ClassIndices[englishClass] or 1
end

-- GetShapeshiftFormInfo compatibility
-- Vanilla returns: texture, name, isActive, isCastable
-- Modern returns:  icon, active, castable, spellID
-- We wrap it to return modern-style values
local originalGetShapeshiftFormInfo = GetShapeshiftFormInfo
MSB_GetShapeshiftFormInfo = function(index)
    local texture, name, isActive, isCastable = originalGetShapeshiftFormInfo(index)
    if not texture then return nil end
    -- Return in modern order: icon, isActive, isCastable, spellID(nil in vanilla)
    return texture, isActive, isCastable, nil
end

-- Numeric texture ID to path mappings (FileDataIDs don't work in vanilla)
MSB_Textures = {
    -- Minimize/Maximize button textures
    [335575] = "Interface\\Buttons\\UI-Panel-SmallerButton-Up",      -- maximize normal
    [335574] = "Interface\\Buttons\\UI-Panel-SmallerButton-Down",    -- maximize pushed
    [335578] = "Interface\\Buttons\\UI-Panel-CollapseButton-Up",     -- minimize normal
    [335577] = "Interface\\Buttons\\UI-Panel-CollapseButton-Down",   -- minimize pushed
    [130831] = "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", -- highlight
}

-- Helper to resolve texture IDs to paths
function MSB_ResolveTexture(textureIDOrPath)
    if type(textureIDOrPath) == "number" then
        return MSB_Textures[textureIDOrPath] or ""
    end
    return textureIDOrPath
end

-- ShowAllSpellRanksCheckbox - will be created properly by ModernSpellBook
-- Just ensure globals exist so references don't error during loading
if not ShowAllSpellRanksCheckbox then
    ShowAllSpellRanksCheckbox = nil
end
if not ShowAllSpellRanksCheckboxText then
    ShowAllSpellRanksCheckboxText = nil
end

-- SpellBookSpellIconsFrame stub (might not exist in vanilla)
if not SpellBookSpellIconsFrame then
    SpellBookSpellIconsFrame = CreateFrame("Frame", "SpellBookSpellIconsFrame", UIParent)
    SpellBookSpellIconsFrame:SetWidth(1)
    SpellBookSpellIconsFrame:SetHeight(1)
    SpellBookSpellIconsFrame:Hide()
end

-- StanceBarFrame / ShapeshiftBarFrame compatibility
if not StanceBarFrame and not StanceBar then
    if ShapeshiftBarFrame then
        StanceBarFrame = ShapeshiftBarFrame
    else
        -- Create a stub
        StanceBarFrame = CreateFrame("Frame")
        StanceBarFrame.numForms = 0
    end
end
