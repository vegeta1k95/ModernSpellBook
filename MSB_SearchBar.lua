--[[
	Search bar: EditBox with placeholder text, search icon, clear button.
--]]

class "CSearchBar"
{
	__init = function(self, parent, placeholderText, onTextChanged)
		self.frame = CreateFrame("EditBox", "ModernSpellBookFrameSearchBar", parent)
		self.frame:SetWidth(200)
		self.frame:SetHeight(20)
		self.frame:SetAutoFocus(false)
		self.frame:SetFontObject(ChatFontNormal)
		self.frame:SetTextInsets(16, 20, 0, 0)

		-- Background
		local left = self.frame:CreateTexture(nil, "BACKGROUND")
		left:SetTexture("Interface\\Common\\Common-Input-Border")
		left:SetWidth(8)
		left:SetHeight(20)
		left:SetPoint("LEFT", self.frame, "LEFT", -5, 0)
		left:SetTexCoord(0, 0.0625, 0, 0.625)

		local right = self.frame:CreateTexture(nil, "BACKGROUND")
		right:SetTexture("Interface\\Common\\Common-Input-Border")
		right:SetWidth(8)
		right:SetHeight(20)
		right:SetPoint("RIGHT", self.frame, "RIGHT", 5, 0)
		right:SetTexCoord(0.9375, 1, 0, 0.625)

		local mid = self.frame:CreateTexture(nil, "BACKGROUND")
		mid:SetTexture("Interface\\Common\\Common-Input-Border")
		mid:SetWidth(10)
		mid:SetHeight(20)
		mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
		mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
		mid:SetTexCoord(0.0625, 0.9375, 0, 0.625)

		-- Search icon
		self.searchIcon = self.frame:CreateTexture(nil, "OVERLAY")
		self.searchIcon:SetWidth(14)
		self.searchIcon:SetHeight(14)
		self.searchIcon:SetPoint("LEFT", self.frame, "LEFT", 2, 0)
		self.searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
		self.searchIcon:SetVertexColor(0.6, 0.6, 0.6)

		-- Placeholder text
		self.instructions = self.frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		self.instructions:SetPoint("LEFT", self.frame, "LEFT", 16, 0)
		self.instructions:SetPoint("RIGHT", self.frame, "RIGHT", -20, 0)
		self.instructions:SetJustifyH("LEFT")
		self.instructions:SetText(placeholderText)

		-- Clear button
		self.clearButton = CreateFrame("Button", nil, self.frame)
		self.clearButton:SetWidth(14)
		self.clearButton:SetHeight(14)
		self.clearButton:SetPoint("RIGHT", self.frame, "RIGHT", -3, 0)
		self.clearButton:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
		self.clearButton:Hide()

		-- ====================== SCRIPTS ==========================

		local instructions = self.instructions
		local clearBtn = self.clearButton
		local editBox = self.frame

		clearBtn:SetScript("OnClick", function()
			editBox:SetText("")
			instructions:Show()
			clearBtn:Hide()
			onTextChanged()
		end)

		editBox:SetScript("OnTextChanged", function()
			onTextChanged()
			local inputText = this:GetText()
			if (inputText == "") then
				clearBtn:Hide()
				return
			end
			clearBtn:Show()
		end)

		editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
		editBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)

		editBox:SetScript("OnEditFocusLost", function()
			local inputText = this:GetText()
			if (inputText == "" or string.find(inputText, "^%s*$")) then
				instructions:Show()
				this:SetText("")
			end
			this:HighlightText(0, 0)
			onTextChanged()
		end)

		editBox:SetScript("OnEditFocusGained", function()
			this:HighlightText()
			instructions:Hide()
		end)

		-- Click outside to defocus
		parent:SetScript("OnMouseDown", function()
			if (editBox.HasFocus and not editBox:HasFocus()) then return end
			if (editBox.IsCurrentFocusEditBox and not editBox:IsCurrentFocusEditBox()) then return end
			editBox:ClearFocus()
		end)
	end;

	-- ====================== DELEGATION ===========================

	Hide = function(self)
		self.frame:Hide()
	end;

	Show = function(self)
		self.frame:Show()
	end;

	IsShown = function(self)
		return self.frame:IsShown()
	end;

	GetText = function(self)
		return self.frame:GetText()
	end;

	SetText = function(self, text)
		self.frame:SetText(text)
	end;

	ClearFocus = function(self)
		self.frame:ClearFocus()
	end;

	SetPoint = function(self, ...)
		self.frame:SetPoint(unpack(arg))
	end;

	Clear = function(self)
		self.frame:SetText("")
		self.instructions:Show()
		self.frame:ClearFocus()
	end;
}
