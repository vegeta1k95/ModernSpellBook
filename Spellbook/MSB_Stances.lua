--[[
	Tracks active stances and updates SpellItem stance indicators
	in real-time via PLAYER_AURAS_CHANGED.
--]]

class "CStanceTracker"
{
	__init = function(self)
		self.frame = CreateFrame("Frame")
		self.frame:RegisterEvent("PLAYER_AURAS_CHANGED")

		self.frame:SetScript("OnEvent", function()
			if (not ModernSpellBookFrame:IsVisible()) then return end
			if (not ModernSpellBookFrame.stanceButtons) then return end

			local activeName = nil
			for i = 1, 20 do
				local texture, name, isActive, isCastable = GetShapeshiftFormInfo(i)
				if (not texture) then break end
				if (isActive) then
					activeName = name
					break
				end
			end

			for stanceName, stanceButton in pairs(ModernSpellBookFrame.stanceButtons) do
				stanceButton:SetStance(stanceName == activeName)
			end
		end)
	end;
}

StanceTracker = CStanceTracker()
