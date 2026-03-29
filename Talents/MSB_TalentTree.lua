--[[
	CTalentTree: Top-level talent tree window.
	Standalone test window opened via /msbt.
	Shows 3 spec panels side by side with CTalentIcon grid.
--]]

local CELL_SIZE = 60
local GRID_COLS_DEFAULT = 4
local GRID_COLS_MAX = 7
local GRID_ROWS = 7
local PANEL_PADDING = 20
local HEADER_HEIGHT = 40
local PANEL_INNER_PAD = 10
local FRAME_PAD = PANEL_PADDING + 10
local PANEL_WIDTH = GRID_COLS_MAX * CELL_SIZE + PANEL_INNER_PAD * 2
local GRID_VERT_PAD = 10
local PANEL_HEIGHT = GRID_ROWS * CELL_SIZE + HEADER_HEIGHT + GRID_VERT_PAD * 2 + 20
local TOTAL_WIDTH = 3 * PANEL_WIDTH + 4 * PANEL_PADDING + 20
local TOTAL_HEIGHT = PANEL_HEIGHT + 120
local VERT_OFFSET = (TOTAL_HEIGHT - PANEL_HEIGHT) / 2

local EXPANDED_HORIZONTAL_PADDING = 350

local TALENT_ASSETS = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\"

-- Shared constants for CExpandedSpecFrame
MSB_TALENT_CONSTANTS = {
	CELL_SIZE = CELL_SIZE,
	GRID_COLS_DEFAULT = GRID_COLS_DEFAULT,
	GRID_COLS_MAX = GRID_COLS_MAX,
	GRID_ROWS = GRID_ROWS,
	PANEL_INNER_PAD = PANEL_INNER_PAD,
	HEADER_HEIGHT = HEADER_HEIGHT,
	GRID_VERT_PAD = GRID_VERT_PAD,
	TOTAL_WIDTH = TOTAL_WIDTH,
	TOTAL_HEIGHT = TOTAL_HEIGHT,
	EXPANDED_HORIZONTAL_PADDING = EXPANDED_HORIZONTAL_PADDING,
	SPEC_DESCRIPTIONS = nil, -- set below after table is defined
}

-- Indexed by english class name then specIndex (1-3)
local SPEC_HAZE_COLORS = {
	WARRIOR = {{0.000, 0.800, 1.000}, {1.000, 0.600, 0.000}, {1.000, 0.240, 0.000}},  -- Arms, Fury, Protection
	PALADIN = {{1.000, 1.000, 0.000}, {1.000, 0.230, 0.000}, {1.000, 0.800, 0.000}},  -- Holy, Protection, Retribution
	HUNTER  = {{0.000, 0.500, 1.000}, {1.000, 1.000, 0.000}, {1.000, 0.300, 0.000}},  -- Beast Mastery, Marksmanship, Survival
	ROGUE   = {{0.400, 1.000, 0.000}, {0.000, 0.800, 1.000}, {0.540, 0.000, 1.000}},  -- Assassination, Combat, Subtlety
	PRIEST  = {{0.000, 0.750, 1.000}, {1.000, 1.000, 0.000}, {0.637, 0.000, 1.000}},  -- Discipline, Holy, Shadow
	SHAMAN  = {{1.000, 0.500, 0.000}, {0.300, 0.170, 1.000}, {0.000, 1.000, 0.600}},  -- Elemental, Enhancement, Restoration
	MAGE    = {{0.850, 0.545, 1.000}, {1.000, 0.350, 0.000}, {0.000, 0.350, 1.000}},  -- Arcane, Fire, Frost
	WARLOCK = {{0.620, 0.420, 1.000}, {0.860, 0.170, 0.110}, {1.000, 0.700, 0.000}},  -- Affliction, Demonology, Destruction
	DRUID   = {{0.350, 0.000, 1.000}, {1.000, 0.100, 0.150}, {0.000, 1.000, 0.000}},  -- Balance, Feral Combat, Restoration
}
local DEFAULT_HAZE_COLOR = {0.2, 0.2, 0.4}

-- Indexed by english class name then specIndex (1-3)
local SPEC_DESCRIPTIONS = {
	WARRIOR = {
		"The disciplined master of the battlefield. Wielding a massive two-handed weapon, this warrior relies on strict martial training and adaptive combat stances to outmaneuver their opponent. Every swing is deliberate, waiting for the perfect opening to deliver a devastating, precision strike that severely cripples the target's ability to heal and bleeds them out through deep, calculated wounds.",
		"A reckless engine of momentum and pure wrath. Abandoning defense for sheer offensive output, this combatant wields twin blades to maximize strikes and keep their blood boiling. Thriving in the thick of melee, they willingly embrace a death wish, sacrificing their own armor and safety to fuel an unrelenting flurry of vicious attacks, overwhelming the enemy before their own vitality runs dry.",
		"The iron bulwark holding the front line. Defined by heavy plate, a scarred shield, and absolute defiance, they control the flow of combat through demoralizing roars and bone-crushing shield bashes. They project a massive, threatening presence to keep the enemy's attention fixed entirely on them, weathering earth-shattering blows by bracing themselves behind steel, standing firm so the rest of the group can survive."
	},
	PALADIN = {
		"The stalwart anchor of the vanguard. Wearing heavy plate armor while channeling divine light, they possess an unmatched physical resilience among those who mend the wounded. Through rigid devotion and spiritual efficiency, they sustain an endless stream of quick, radiant mending, keeping their allies standing through grueling wars of attrition while projecting unyielding, righteous auras of protection.",
		"The devoted bastion against the undead and demonic hordes. Relying on searing the very earth beneath their foes' feet and reacting to incoming strikes with radiant barriers, they wear down multiple adversaries through holy retaliation. They are masters of endurance, absorbing physical punishment and reflecting it back as blinding light, turning their own armor into an instrument of absolute attrition.",
		"The zealous inquisitor. A slow, methodical crusader who relies on heavy two-handed swings and the unpredictable, explosive power of divine judgment. They break their enemies' defenses through holy condemnation, capitalizing on fleeting moments of weakness to deliver crushing, deliberate blows of wrath, punishing those who thought they could outlast the light."
	},
	HUNTER = {
		"A bonded survivalist fighting in perfect synchronization with an apex predator. This tracker channels their primal focus entirely into their tamed companion. Through shared instinct and roaring commands, the beast becomes a frenzied, unstoppable force, tearing through flesh and bone while the archer provides covering fire, ensuring any threat is mauled before it can close the distance.",
		"The patient, lethal sniper. Operating at the absolute limits of physical range, they control the pacing of the skirmish with concussive blasts and disorienting volleys. They meticulously time their bowstring draws, waiting for the perfect moment to unleash a heavy, armor-piercing arrow, delivering calculated bursts of physical damage that drop a target before they even realize they are being hunted.",
		"The rugged, tactical frontiersman. When the enemy inevitably closes in, they are already prepared. Relying on heightened agility and an arsenal of hidden, explosive traps, they excel at controlling the very earth of the battlefield. They punish melee attackers with debilitating counterattacks and venomous stings, proving that a tracker is just as dangerous in the dense brush as they are from a watchtower."
	},
	ROGUE = {
		"The quiet executioner. Relying on potent, lingering venoms and pinpoint strikes to vital organs, this killer waits in the shadows for the singular, perfect opening. By exploiting moments of vulnerability and striking rapidly with twin daggers, they ensure their target’s lifeblood evaporates in a lethal, toxic instant, slipping away before the body even hits the ground.",
		"The pragmatic frontline duelist. Forsaking the shadows for sheer martial prowess, this fighter stands toe-to-toe with their prey. Armed with swords or heavy maces, they maintain a relentless offensive pressure, weaving their blades in a blur of steel. When overwhelmed, they tap into reserves of pure adrenaline, matching multiple opponents blow for blow with blinding attack speed and unmatched parries.",
		"The unseen manipulator of the battlefield. Dictating exactly when and how a fight begins, they are a phantom in the dark. Utilizing unparalleled camouflage and premeditated tactics, they cripple their target from the first strike, chaining precise, stunning blows that completely lock down the enemy's ability to react. If the odds ever turn against them, they vanish into thin air, resetting the board on their own terms."
	},
	PRIEST = {
		"The ascetic channeler of absolute willpower. Rather than merely mending broken flesh, this cleric anticipates incoming trauma, mitigating fatal blows by wrapping their allies in shimmering, unbreakable barriers of pure faith. They bolster the minds and magical reserves of their comrades, acting as a tactical anchor who manages the momentum of the battle and prevents disasters before blood is even spilled.",
		"The devout conduit of mending miracles. Commanding the most versatile restorative magic in the realm, they weave potent, deep healing with wide-reaching prayers that mend the entire vanguard at once. Deeply attuned to the spiritual plane, they are capable of pulling groups back from the absolute brink of death, offering a transcendent wave of salvation to those whose physical strength has entirely failed.",
		"The orthodox outcast wielding forbidden magic. Slipping into a dark, ethereal form, they systematically tear apart the minds of their enemies. They layer agonizing, lingering curses and channel void energy to hobble their target’s very thoughts. They thrive on suffering, siphoning the fading life force of their adversaries to mend their own allies, turning the enemy's vitality into a weapon of survival."
	},
	SHAMAN = {
		"The destructive channeler of the earth and sky. Calling upon the raw, violent forces of nature, they plant carved wards into the soil to anchor their power. They bypass armor entirely with sudden tremors and hurl chaining lightning through enemy ranks. By mastering the volatile elements, they guarantee devastating, localized storms that end skirmishes in a sudden burst of primal fury.",
		"The tribal warrior imbued with the fury of the storm. Wielding a heavy, two-handed weapon, they enter the fray trusting in the ancestral spirits to guide their strikes. Every swing carries the potential of a sudden, violent tempest—a magically empowered flurry of extra, blindingly fast attacks capable of executing an opponent in a single, terrifying burst of physical force.",
		"The spiritual mender. Calling upon the soothing properties of living water and resilient earth, they sustain the battle lines with ancestral grace. They are unmatched in group stabilization, weaving fluid waves of restorative magic that jump intelligently from one wounded ally to the next. By placing wards of deep renewal, they ensure the group's mental and magical reserves long outlast the enemy's stamina."
	},
	MAGE = {
		"The master of raw, unfettered magical essence. Tapping directly into the world's leylines, they sacrifice all efficiency for overwhelming cosmic superiority. By manipulating the very fabric of time and intellect, they can instantly unleash energies of immense destructive force. When their mental reserves run dry, they draw the ambient magic of the air back into their mind, ready to strike again.",
		"The volatile pyromancer. Focused entirely on maximizing sheer, destructive throughput, they weave molten embers and searing blasts to build up terrifying layers of heat. They chain critical, explosive strikes together, leaving deep, burning wounds on the target. It is a dangerous, reckless dance of power, pushing their fiery output to the absolute limit to incinerate the enemy before they can even draw near.",
		"The pragmatic controller of the battlefield. Dictating the pace of every engagement, they rely on chilling magic to slow their charging enemies to a frozen crawl. Shielded by an impenetrable barrier of ice, they lock down groups with localized blizzards and shattering cold, taking advantage of immobilized targets to deliver lethal, piercing strikes. If caught, they encase themselves in solid frost to survive otherwise fatal blows."
	},
	WARLOCK = {
		"The harbinger of inevitable decay. Layering their target in dark hexes and vile corruptions, they rely on debilitating, lingering magic to secure victory. Through dark siphoning and soul-draining rituals, they slowly and methodically extract the vitality from their enemy. It is a terrifying war of attrition where the opponent slowly rots away from the inside, unable to halt their own fading strength.",
		"The dark summoner. Drawing their power from the chaotic nether, they treat their summoned horrors not just as servants, but as a source of dark survival. Through forbidden bonds, they share physical pain with their abyssal minions, making the spellcaster incredibly difficult to kill. They are entirely willing to sacrifice their own creations at a moment's notice to absorb raw, demonic power into their own veins.",
		"The reckless caster of fel-fire. Channeling the chaotic, burning energy of the abyss, they are a dark reflection of traditional spellcasters. They utilize harvested soul fragments to hurl massive, chaotic infernos, executing fleeing enemies with sudden bursts of dark flame. Their magic is highly volatile and destructive, focused on overwhelming, scorching force that leaves nothing behind but cursed ash."
	},
	DRUID = {
		"The warden of nature's cosmic equilibrium. Commanding the astral energies of the moon and the blinding wrath of the sun, they take on the heavily armored form of a mystical avian beast. Standing at range, they weave thorny roots and celestial light to weaken targets before calling down heavy, methodical columns of astral fire, punishing interlopers with the raw, untamed power of the night sky.",
		"The primal shapeshifter. Abandoning the incantations of a spellcaster, they adapt perfectly to the physical demands of raw combat. Taking the form of a great jungle cat, they prowl unseen, shredding armor and bleeding targets with precise, ferocious strikes. When the battle requires a vanguard, they shift into a massive, thick-hided bear, generating furious resilience to act as an impenetrable wall of fur and muscle.",
		"The cultivator of wild life. Excelling at sustaining their allies through layered, blooming magic, they create a buffer of constant mending that allows their group to push through heavy, sustained damage. They coax the very flora of the battlefield to wrap around their comrades, and in moments of dire crisis, they instantly breathe the restorative tranquility of the deep forest back into a fallen ally."
	}
}
local DEFAULT_SPEC_DESCRIPTION = ""
MSB_TALENT_CONSTANTS.SPEC_DESCRIPTIONS = SPEC_DESCRIPTIONS

class "CTalentTree"
{
	__init = function(self)
		local tree = self
		local panel_width = PANEL_WIDTH
		local total_width = TOTAL_WIDTH
		local total_height = TOTAL_HEIGHT

		-- Main frame
		self.frame = CreateFrame("Frame", "ModernTalentTreeFrame", UIParent)
		self.frame:SetWidth(total_width)
		self.frame:SetHeight(total_height)
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		self.frame:SetFrameStrata("HIGH")
		self.frame:SetFrameLevel(5)
		self.frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		self.frame:SetBackdropColor(0.03, 0.03, 0.06, 0.97)
		self.frame:EnableMouse(true)
		self.frame:SetMovable(true)
		self.frame:RegisterForDrag("LeftButton")
		self.frame:SetScript("OnDragStart", function() this:StartMoving() end)
		self.frame:SetScript("OnDragStop", function()
			this:StopMovingOrSizing()
			local point, _, relPoint, x, y = this:GetPoint()
			ModernSpellBook_DB.talentPosition = { point = point, relPoint = relPoint, x = x, y = y }
		end)
		self.frame:Hide()
		table.insert(UISpecialFrames, "ModernTalentTreeFrame")

		-- Restore saved position and scale
		if (ModernSpellBook_DB and ModernSpellBook_DB.talentPosition) then
			local pos = ModernSpellBook_DB.talentPosition
			self.frame:ClearAllPoints()
			self.frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
		end
		if (ModernSpellBook_DB and ModernSpellBook_DB.talentScale) then
			self.frame:SetScale(ModernSpellBook_DB.talentScale)
		end

		-- Close button (high frame level so it stays above expanded view)
		local close = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)
		close:SetFrameLevel(self.frame:GetFrameLevel() + 20)

		-- Settings button (top-right, left of close button)
		local settingsBtn = CreateFrame("Button", nil, self.frame)
		settingsBtn:SetWidth(20)
		settingsBtn:SetHeight(20)
		settingsBtn:SetPoint("RIGHT", close, "LEFT", -2, 0)
		settingsBtn:SetFrameLevel(self.frame:GetFrameLevel() + 20)
		settingsBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
		settingsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
		settingsBtn:SetPushedTexture("Interface\\Icons\\INV_Misc_Gear_01")
		local talentSettingsDropdown = CreateFrame("Frame", "ModernTalentSettingsDropDown", self.frame)
		talentSettingsDropdown.displayMode = "MENU"
		talentSettingsDropdown.initialize = function(level)
			local info = {}
			info.text = "Reset position & scale"
			info.notCheckable = 1
			info.func = function()
				ModernSpellBook_DB.talentPosition = nil
				ModernSpellBook_DB.talentScale = nil
				self.frame:SetScale(1)
				self.frame:ClearAllPoints()
				self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				CloseDropDownMenus()
			end
			UIDropDownMenu_AddButton(info, level)
		end
		settingsBtn:SetScript("OnClick", function()
			ToggleDropDownMenu(1, nil, talentSettingsDropdown, settingsBtn, 0, 0)
		end)

		-- Resize handle (bottom-right corner)
		local resizeHandle = CreateFrame("Button", nil, self.frame)
		resizeHandle:SetWidth(16)
		resizeHandle:SetHeight(16)
		resizeHandle:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, 4)
		resizeHandle:SetFrameLevel(self.frame:GetFrameLevel() + 20)
		local resizeTex = resizeHandle:CreateTexture(nil, "OVERLAY")
		resizeTex:SetAllPoints(resizeHandle)
		resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		resizeHandle:SetScript("OnEnter", function()
			resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		end)
		resizeHandle:SetScript("OnLeave", function()
			resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		end)
		resizeHandle:SetScript("OnMouseDown", function()
			resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
			local startX, startY = GetCursorPosition()
			local startScale = self.frame:GetScale()
			local left, top = self.frame:GetLeft(), self.frame:GetTop()
			local es = self.frame:GetEffectiveScale()
			local screenLeft = left * es
			local screenTop = top * es
			resizeHandle:SetScript("OnUpdate", function()
				local curX, curY = GetCursorPosition()
				local dx = curX - startX
				local dy = startY - curY
				local delta = (dx + dy) / 2
				local newScale = math.max(0.5, math.min(1.2, startScale + delta / 500))
				self.frame:SetScale(newScale)
				local nes = self.frame:GetEffectiveScale()
				self.frame:ClearAllPoints()
				self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", screenLeft / nes, screenTop / nes)
			end)
		end)
		resizeHandle:SetScript("OnMouseUp", function()
			resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
			resizeHandle:SetScript("OnUpdate", nil)
			ModernSpellBook_DB.talentScale = self.frame:GetScale()
			local point, _, relPoint, x, y = self.frame:GetPoint()
			ModernSpellBook_DB.talentPosition = { point = point, relPoint = relPoint, x = x, y = y }
		end)

		-- Title
		self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.title:SetPoint("TOP", self.frame, "TOP", 12, -24)
		self.title:SetFont("Fonts\\MORPHEUS.TTF", 16)
		self.title:SetTextColor(1, 0.82, 0)

		-- Points display
		self.points_text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.points_text:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 30)
		self.points_text:SetFont("Fonts\\FRIZQT__.TTF", 14)
		self.points_text:SetTextColor(1.0, 1.0, 1.0)

		-- Slash command: toggle custom talent UI on/off
		self.enabled = true
		SLASH_MSBT1 = "/msbt"
		SlashCmdList["MSBT"] = function()
			tree.enabled = not tree.enabled
			if (tree.enabled) then
				DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ModernSpellBook:|r Custom talent tree |cff00ff00enabled|r")
				if (tree.frame:IsVisible()) then return end
				tree.frame:Hide()
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ModernSpellBook:|r Custom talent tree |cffff4444disabled|r (using vanilla)")
				tree.frame:Hide()
			end
		end

		-- Event handling
		self.event_frame = CreateFrame("Frame")
		self.event_frame:RegisterEvent("PLAYER_TALENT_UPDATE")
		self.event_frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
		self.event_frame:SetScript("OnEvent", function()
			if (tree.frame:IsVisible()) then
				tree:Refresh()
			end
		end)

		self.specs = {}
		self.built = false
		self.expanded_spec = nil

		-- Expanded detail view
		self.expanded_view = CExpandedSpecFrame(self.frame, MSB_TALENT_CONSTANTS)
		self.expanded_view.parent_tree = self

		-- Back button (high frame level so it stays above expanded view)
		self.back_btn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
		self.back_btn:SetWidth(60)
		self.back_btn:SetHeight(22)
		self.back_btn:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -12)
		self.back_btn:SetText("Back")
		self.back_btn:SetFrameLevel(self.frame:GetFrameLevel() + 20)
		self.back_btn:Hide()
		self.back_btn:SetScript("OnClick", function()
			tree:CollapseSpec()
		end)

	end;

	-- ======================== TOGGLE =============================

	Toggle = function(self)
		if (self.frame:IsVisible()) then
			self.frame:Hide()
		else
			if (not self.built) then
				self:BuildSpecs()
				self.built = true
			end
			self:Refresh()
			self.frame:Show()
		end
	end;

	-- ===================== BUILD SPECS ===========================

	BuildSpecs = function(self)
		local className, englishClass = UnitClass("player")
		self.title:SetText(className .. " Talents")

		-- Class icon before title
		local titleIconFrame = CreateFrame("Frame", nil, self.frame)
		titleIconFrame:SetWidth(24)
		titleIconFrame:SetHeight(24)
		titleIconFrame:SetFrameLevel(self.frame:GetFrameLevel() + 20)
		titleIconFrame:SetPoint("RIGHT", self.title, "LEFT", -4, 0)
		self.title_icon_frame = titleIconFrame
		local titleIcon = titleIconFrame:CreateTexture(nil, "OVERLAY")
		titleIcon:SetAllPoints(titleIconFrame)
		titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		titleIcon:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\classicon-" .. string.lower(englishClass))

		local numTabs = GetNumTalentTabs()
		-- Offset to center 4-col layout within 7-col panel
		local col_offset = (GRID_COLS_MAX - GRID_COLS_DEFAULT) * CELL_SIZE / 2

		for t = 1, numTabs do
			local tabName, tabIcon, pointsSpent = GetTalentTabInfo(t)
			local numTalents = GetNumTalents(t)

			-- Spec panel container
			-- Anchor by CENTER so SetScale scales from center naturally
			local centerX = FRAME_PAD + (t - 1) * (PANEL_WIDTH + PANEL_PADDING) + PANEL_WIDTH / 2
			local centerY = -VERT_OFFSET - PANEL_HEIGHT / 2

			local panel = CreateFrame("Frame", nil, self.frame)
			panel:SetWidth(PANEL_WIDTH)
			panel:SetHeight(PANEL_HEIGHT)
			panel:SetPoint("CENTER", self.frame, "TOPLEFT", centerX, centerY)
			panel:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 12,
				insets = { left = 3, right = 3, top = 3, bottom = 3 }
			})
			panel:SetBackdropColor(0.06, 0.06, 0.1, 0.9)


			-- Spec background texture (two 512x512 halves, right-cropped to fit panel)
			local bgBase = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\Backgrounds\\talentbg-" .. string.lower(englishClass) .. "-" .. t
			-- Original image is 1024x512 (2:1). Scale to fit panel height, crop left.
			local scaledWidth = PANEL_HEIGHT * 2
			local visibleFraction = PANEL_WIDTH / scaledWidth
			local leftCrop = 1 - visibleFraction
			-- leftCrop is in 0..1 of the full 1024 image
			-- Left half covers 0..0.5, right half covers 0.5..1.0
			local bgTexLeft = panel:CreateTexture(nil, "ARTWORK")
			local bgTexRight = panel:CreateTexture(nil, "ARTWORK")
			bgTexLeft:SetTexture(bgBase .. "-left")
			bgTexRight:SetTexture(bgBase .. "-right")
			bgTexLeft:SetAlpha(0.6)
			bgTexRight:SetAlpha(0.6)
			if (leftCrop >= 0.5) then
				-- Entire visible area is in the right half
				local rightStart = (leftCrop - 0.5) * 2
				bgTexRight:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
				bgTexRight:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
				bgTexRight:SetTexCoord(rightStart, 1, 0, 1)
				bgTexLeft:Hide()
			else
				-- Visible area spans both halves
				local leftStart = leftCrop * 2
				local leftVisibleFrac = (0.5 - leftCrop) / (1 - leftCrop)
				local splitX = PANEL_WIDTH * leftVisibleFrac
				bgTexLeft:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
				bgTexLeft:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 4)
				bgTexLeft:SetWidth(splitX)
				bgTexLeft:SetTexCoord(leftStart, 1, 0, 1)
				bgTexRight:SetPoint("TOPLEFT", bgTexLeft, "TOPRIGHT", 0, 0)
				bgTexRight:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
				bgTexRight:SetTexCoord(0, 1, 0, 1)
			end


			-- Spec header
			local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			header:SetPoint("TOP", panel, "TOP", 0, -12)
			header:SetFont("Fonts\\FRIZQT__.TTF", 14)
			header:SetText(string.upper(tabName))
			header:SetTextColor(1, 1, 1)

			-- Points counter
			local ptsText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			ptsText:SetPoint("TOP", header, "BOTTOM", 0, -4)
			ptsText:SetFont("Fonts\\FRIZQT__.TTF", 12)
            if (pointsSpent == 0) then
			    ptsText:SetTextColor(0.6, 0.6, 0.6)
            else
                ptsText:SetTextColor(1.0, 1.0, 1.0)
            end

			-- Talent grid
			local classColors = SPEC_HAZE_COLORS[englishClass]
			local haze_color = (classColors and classColors[t]) or DEFAULT_HAZE_COLOR
			local grid = CTalentGrid(panel, t, CELL_SIZE,
				PANEL_INNER_PAD + col_offset, HEADER_HEIGHT + GRID_VERT_PAD,
				haze_color, GRID_ROWS)

			-- Click panel to expand
			local specIndex = t
			panel:EnableMouse(true)
			panel:SetScript("OnMouseUp", function()
				if (arg1 == "LeftButton") then
					TalentTree:ExpandSpec(specIndex)
				end
			end)

			table.insert(self.specs, {
				panel = panel,
				header = header,
				points_text = ptsText,
				grid = grid,
				tab_index = t,
				tab_name = tabName,
				tab_icon = tabIcon,
			})
		end
	end;

	-- ==================== EXPAND / COLLAPSE =======================

	ExpandSpec = function(self, specIndex)
		self.expanded_spec = specIndex
		local spec = self.specs[specIndex]
		local _, englishClass = UnitClass("player")

		-- Hide overview
		for _, s in ipairs(self.specs) do
			s.panel:Hide()
		end
		self.title:Hide()
		if (self.title_icon_frame) then
			self.title_icon_frame:Hide()
		end

		-- Show expanded view
		local classColors = SPEC_HAZE_COLORS[englishClass]
		self.expanded_view:Show(spec, specIndex, classColors)
		self.back_btn:Show()
		self:Refresh()
	end;

	CollapseSpec = function(self)
		self.expanded_spec = nil
		self.expanded_view:Hide()
		self.back_btn:Hide()

		for _, spec in ipairs(self.specs) do
			spec.panel:Show()
		end

		self.title:Show()
		if (self.title_icon_frame) then
			self.title_icon_frame:Show()
		end
		self:Refresh()
	end;

	-- ====================== REFRESH ==============================

	Refresh = function(self)
		local totalSpent = 0
		local totalAvailable = UnitLevel("player") - 9
		if (totalAvailable < 0) then totalAvailable = 0 end

		for _, spec in ipairs(self.specs) do
			local _, _, pointsSpent = GetTalentTabInfo(spec.tab_index)
			spec.points_text:SetText(pointsSpent .. " points")
			totalSpent = totalSpent + pointsSpent
		end

		local remaining = totalAvailable - totalSpent

		for _, spec in ipairs(self.specs) do
			local _, _, pointsSpent = GetTalentTabInfo(spec.tab_index)
			spec.grid:Refresh(pointsSpent, remaining)
		end

		if (remaining > 0) then
			self.points_text:SetText("|cff00ff00" .. remaining .. "|r TALENT POINT AVAILABLE")
		else
			self.points_text:SetText("NO TALENT POINTS AVAILABLE")
		end
	end;
}

TalentTree = CTalentTree()

-- ============================================================
-- Hook default talent window: open our UI instead
-- ============================================================

local function MSB_HookTalentFrame()
	local orig = ToggleTalentFrame
	ToggleTalentFrame = function()
		if (TalentTree.enabled) then
			TalentTree:Toggle()
		else
			orig()
		end
	end
end

if (ToggleTalentFrame) then
	MSB_HookTalentFrame()
else
	local hookFrame = CreateFrame("Frame")
	hookFrame:RegisterEvent("ADDON_LOADED")
	hookFrame:SetScript("OnEvent", function()
		if (arg1 == "Blizzard_TalentUI" and ToggleTalentFrame) then
			MSB_HookTalentFrame()
			hookFrame:UnregisterEvent("ADDON_LOADED")
		end
	end)
end
