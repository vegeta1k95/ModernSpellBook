--[[
	Centralized text color, shadow, and blend mode logic.
	Single source of truth for dark/light mode styling.
--]]

class "CTextStyle"
{
	__init = function(self)
	end;

	IsDark = function(self)
		return ModernSpellBook_DB and ModernSpellBook_DB.textColorMode == "dark"
	end;

	-- Apply colors to a spell name + rank pair + trail
	-- mode: "normal", "unlearned"
	ApplyToSpell = function(self, nameFS, subFS, lightBorder, mode)
		local isDark = self:IsDark()

		if (mode == "unlearned") then
			if (isDark) then
				nameFS:SetTextColor(0.4, 0.4, 0.4)
				subFS:SetTextColor(0.4, 0.4, 0.4)
				nameFS:SetShadowOffset(1, -1)
				nameFS:SetShadowColor(0, 0, 0, 0.7)
				subFS:SetShadowOffset(1, -1)
				subFS:SetShadowColor(0, 0, 0, 0.7)
			else
				nameFS:SetTextColor(0.6, 0.55, 0.35)
				subFS:SetTextColor(0.6, 0.6, 0.6)
				nameFS:SetShadowOffset(1, -1)
				nameFS:SetShadowColor(0, 0, 0, 0.7)
				subFS:SetShadowOffset(1, -1)
				subFS:SetShadowColor(0, 0, 0, 0.7)
			end
		else
			if (isDark) then
				nameFS:SetTextColor(0, 0, 0)
				subFS:SetTextColor(0.2, 0.2, 0.2)
				nameFS:SetShadowOffset(0, 0)
				subFS:SetShadowOffset(0, 0)
			else
				nameFS:SetTextColor(0.989, 0.857, 0.343)
				subFS:SetTextColor(1, 1, 1)
				nameFS:SetShadowOffset(1, -1)
				nameFS:SetShadowColor(0, 0, 0, 0.7)
				subFS:SetShadowOffset(1, -1)
				subFS:SetShadowColor(0, 0, 0, 0.7)
			end
		end

		if (lightBorder) then
			if (isDark) then
				lightBorder:SetBlendMode("ADD")
			else
				lightBorder:SetBlendMode("BLEND")
			end
		end
	end;
}

TextStyle = CTextStyle()
