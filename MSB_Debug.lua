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

	c:AddMessage("=== GetPlayerSpells(false) ===")
	local ok, result = pcall(function() return SpellDataService:GetPlayerSpells(false) end)
	if (ok) then
		for cat, spells in pairs(result) do
			c:AddMessage("  Category: " .. tostring(cat) .. " (" .. table.getn(spells) .. " spells)")
		end
	else
		c:AddMessage("  ERROR: " .. tostring(result))
	end

	c:AddMessage("=== GetPlayerSpells(true) ===")
	ok, result = pcall(function() return SpellDataService:GetPlayerSpells(true) end)
	if (ok) then
		for cat, spells in pairs(result) do
			c:AddMessage("  Category: " .. tostring(cat) .. " (" .. table.getn(spells) .. " spells)")
		end
	else
		c:AddMessage("  ERROR: " .. tostring(result))
	end
end
