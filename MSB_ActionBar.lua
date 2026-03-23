--[[
	Action bar grid management: shows/hides grid overlays
	on action buttons while the spellbook is open.
--]]

class "CActionBarHelper"
{
	__init = function(self)
	end;

	ShowButtonGrid = function(self, button)
		if (ActionButton_ShowGrid == nil) then return end
		if (button.GetAttribute and button:GetAttribute("showgrid")) then
			button:SetAttribute("showgrid", button:GetAttribute("showgrid") + 1)
		end
		ActionButton_ShowGrid(button)
	end;

	HideButtonGrid = function(self, button)
		if (ActionButton_ShowGrid == nil) then return end
		if (button.GetAttribute and button:GetAttribute("showgrid")) then
			local showgrid = button:GetAttribute("showgrid")
			if (showgrid > 0) then
				button:SetAttribute("showgrid", showgrid - 1)
			end
		end
		ActionButton_HideGrid(button)
	end;

	UpdateBarGrid = function(self, barName, show)
		local numButtons = NUM_MULTIBAR_BUTTONS or 12
		for i = 1, numButtons do
			local button = _G[barName.."Button"..i]
			if (button) then
				if (show and not button.noGrid) then
					self:ShowButtonGrid(button)
				else
					self:HideButtonGrid(button)
				end
			end
		end
	end;

	ShowAllGrids = function(self)
		self:UpdateBarGrid("MultiBarBottomLeft", true)
		self:UpdateBarGrid("MultiBarBottomRight", true)
		self:UpdateBarGrid("MultiBarRight", true)
		self:UpdateBarGrid("MultiBarLeft", true)
	end;

	HideAllGrids = function(self)
		self:UpdateBarGrid("MultiBarBottomLeft", false)
		self:UpdateBarGrid("MultiBarBottomRight", false)
		self:UpdateBarGrid("MultiBarRight", false)
		self:UpdateBarGrid("MultiBarLeft", false)
	end;
}

ActionBarHelper = CActionBarHelper()
