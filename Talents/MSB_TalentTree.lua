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

class "CTalentTree"
{
	__init = function(self)
		local panel_width = PANEL_WIDTH
		local total_width = TOTAL_WIDTH
		local total_height = TOTAL_HEIGHT

		-- Main frame
		self.frame = CreateFrame("Frame", "ModernTalentTreeFrame", UIParent)
		self.frame:SetWidth(total_width)
		self.frame:SetHeight(total_height)
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		self.frame:SetFrameStrata("MEDIUM")
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
		self.frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
		self.frame:Hide()
		table.insert(UISpecialFrames, "ModernTalentTreeFrame")

		-- Close button (high frame level so it stays above expanded view)
		local close = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)
		close:SetFrameLevel(self.frame:GetFrameLevel() + 20)

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

		-- Slash command
		SLASH_MSBT1 = "/msbt"
		local tree = self
		SlashCmdList["MSBT"] = function()
			tree:Toggle()
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
		self.expanded_spec = nil -- index of currently expanded spec, or nil for overview

		-- Expanded view container (hidden by default)
		self.expanded = CreateFrame("Frame", nil, self.frame)
		self.expanded:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, -8)
		self.expanded:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 8)
		self.expanded:Hide()

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

			-- Tier lock icon (shown at first locked tier, updated in Refresh)
			local tierLock = CreateFrame("Frame", nil, panel)
			tierLock:SetWidth(138)
			tierLock:SetHeight(16)
			tierLock:SetFrameLevel(panel:GetFrameLevel() + 5)
			local tierLockTex = tierLock:CreateTexture(nil, "OVERLAY")
			tierLockTex:SetAllPoints(tierLock)
			tierLockTex:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\tier-lock")
			tierLock:Hide()

			local tierLockText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			tierLockText:SetFont("Fonts\\FRIZQT__.TTF", 16)
			tierLockText:SetTextColor(190/255, 136/255, 121/255)
			tierLockText:SetPoint("RIGHT", tierLock, "LEFT", -2, 0)
			tierLockText:Hide()

			-- Create talent icons
			local icons = {}
			local classColors = SPEC_HAZE_COLORS[englishClass]
			local haze_color = (classColors and classColors[t]) or DEFAULT_HAZE_COLOR

			for i = 1, numTalents do
				local name = GetTalentInfo(t, i)
				if (name) then
					local talent = CTalentIcon(panel, CELL_SIZE)
					talent:SetTalentData(t, i)
					talent:SetGridPosition(
						talent.tier - 1,
						talent.column - 1,
						PANEL_INNER_PAD + col_offset,
						HEADER_HEIGHT + GRID_VERT_PAD)
					talent:SetHazeColor(haze_color[1], haze_color[2], haze_color[3])

					table.insert(icons, talent)
				end
			end

			-- Mark the bottom-most talent as final (fancy frame)
			local maxTier = 0
			for _, talent in ipairs(icons) do
				if (talent.tier > maxTier) then maxTier = talent.tier end
			end
			for _, talent in ipairs(icons) do
				if (talent.tier == maxTier) then
					talent.is_final = true
					talent:ApplyFrameShape()
				end
			end

			-- Build occupied cell map for routing
			local occupied = {}
			for _, talent in ipairs(icons) do
				occupied[(talent.tier - 1) .. "," .. (talent.column - 1)] = true
			end

			-- Collect prereq edges, sorted: straight (same col) first, then L-shapes
			local edges = {}
			for _, talent in ipairs(icons) do
				if (talent.prereq_tier and talent.prereq_column) then
					table.insert(edges, talent)
				end
			end
			table.sort(edges, function(a, b)
				local a_straight = (a.prereq_column == a.column) and 0 or 1
				local b_straight = (b.prereq_column == b.column) and 0 or 1
				return a_straight < b_straight
			end)

			-- Build connections: straight first so L-shapes can avoid them
			local connections = {}
			for _, talent in ipairs(edges) do
				local conn = CTalentConnection(panel)
				conn:BuildRoute(
					talent.prereq_tier - 1,
					talent.prereq_column - 1,
					talent.tier - 1,
					talent.column - 1,
					CELL_SIZE,
					PANEL_INNER_PAD + col_offset,
					HEADER_HEIGHT + GRID_VERT_PAD,
					occupied)
				-- Add routed cells to occupied so later connections avoid them
				if (conn.routed_cells) then
					for _, cell in ipairs(conn.routed_cells) do
						occupied[cell.r .. "," .. cell.c] = true
					end
				end
				table.insert(connections, {
					connection = conn,
					prereq_tier = talent.prereq_tier,
					prereq_column = talent.prereq_column,
					target = talent,
				})
			end

			-- Find exceptional talent icons for showcase
			local exceptionalTalents = {}
			for _, talent in ipairs(icons) do
				if (talent.is_exceptional) then
					table.insert(exceptionalTalents, talent)
				end
			end

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
				icons = icons,
				connections = connections,
				tier_lock = tierLock,
				tier_lock_text = tierLockText,
				tab_index = t,
				tab_name = tabName,
				tab_icon = tabIcon,
				exceptional_talents = exceptionalTalents,
			})
		end
	end;

	-- ==================== EXPAND / COLLAPSE =======================

	ExpandSpec = function(self, specIndex)
		self.expanded_spec = specIndex
		local spec = self.specs[specIndex]
		local _, englishClass = UnitClass("player")

		-- Hide all overview panels
		for _, s in ipairs(self.specs) do
			s.panel:Hide()
		end
		self.title:Hide()
		if (self.title_icon_frame) then
			self.title_icon_frame:Hide()
		end

		-- Clear previous expanded content
		local children = {self.expanded:GetChildren()}
		for _, child in ipairs(children) do
			child:Hide()
		end
		local regions = {self.expanded:GetRegions()}
		for _, region in ipairs(regions) do
			region:Hide()
		end

		local expW = TOTAL_WIDTH - 16
		local expH = TOTAL_HEIGHT - 16

		-- Full background (two 512x512 halves stitched together)
		local bgBase = "Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\Backgrounds\\talentbg-" .. string.lower(englishClass) .. "-" .. specIndex
		local bgLeft = self.expanded:CreateTexture(nil, "ARTWORK")
		bgLeft:SetTexture(bgBase .. "-left")
		bgLeft:SetPoint("TOPLEFT", self.expanded, "TOPLEFT", 0, 0)
		bgLeft:SetPoint("BOTTOMLEFT", self.expanded, "BOTTOMLEFT", 0, 0)
		bgLeft:SetWidth(expW / 2)
		bgLeft:Show()
		local bgRight = self.expanded:CreateTexture(nil, "ARTWORK")
		bgRight:SetTexture(bgBase .. "-right")
		bgRight:SetPoint("TOPLEFT", bgLeft, "TOPRIGHT", 0, 0)
		bgRight:SetPoint("BOTTOMRIGHT", self.expanded, "BOTTOMRIGHT", 0, 0)
		bgRight:Show()

		-- Right-click background to go back
		self.expanded:EnableMouse(true)
		self.expanded:SetScript("OnMouseUp", function()
			if (arg1 == "RightButton") then
				TalentTree:CollapseSpec()
			end
		end)

		-- Symmetric layout: left column centered on X=PAD, grid centered on X=expW-PAD
		local gridW = GRID_COLS_DEFAULT * CELL_SIZE + 20
		local leftColW = EXPANDED_HORIZONTAL_PADDING * 2

		local leftCol = CreateFrame("Frame", nil, self.expanded)
		leftCol:SetWidth(leftColW)
		leftCol:SetHeight(expH)
		leftCol:SetPoint("CENTER", self.expanded, "LEFT", EXPANDED_HORIZONTAL_PADDING, 0)

		-- Spec name (centered at top)
		local specName = leftCol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		specName:SetPoint("TOP", leftCol, "TOP", 0, -40) -- re-anchored below after pointsTitle is created
		specName:SetFont("Fonts\\FRIZQT__.TTF", 22)
		specName:SetText(string.upper(spec.tab_name))
		specName:SetTextColor(1, 1, 1)
		specName:SetJustifyH("CENTER")
		specName:Show()

		-- Spec description (centered below name)
		local descTable = SPEC_DESCRIPTIONS[englishClass]
		local descText = descTable and descTable[specIndex] or DEFAULT_SPEC_DESCRIPTION
		local specDesc = leftCol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		specDesc:SetPoint("TOP", specName, "BOTTOM", 0, -30)
		specDesc:SetFont("Fonts\\FRIZQT__.TTF", 16)
		specDesc:SetText(descText)
		specDesc:SetTextColor(1, 1, 1)
		specDesc:SetJustifyH("CENTER")
		specDesc:SetWidth(400)
		--specDesc:SetWidth(leftColW - 40)
		if (specDesc.SetWordWrap) then specDesc:SetWordWrap(true) end
		specDesc:Show()

		-- Key Abilities header (centered below description)
		local _, _, pointsSpent = GetTalentTabInfo(spec.tab_index)
		local abilitiesHeader = leftCol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		abilitiesHeader:SetPoint("TOP", specDesc, "BOTTOM", 0, -30)
		abilitiesHeader:SetFont("Fonts\\FRIZQT__.TTF", 18)
		abilitiesHeader:SetText("KEY ABILITIES")
		abilitiesHeader:SetTextColor(1, 1, 1)
		abilitiesHeader:SetJustifyH("CENTER")
		abilitiesHeader:Show()

		-- Exceptional ability showcase: last exceptional from rows 3, 5, 7
		-- Prefer talents with arrows (outgoing > incoming > none)
		local hasOutgoing = {}
		local hasIncoming = {}
		for _, talent in ipairs(spec.icons) do
			if (talent.prereq_tier) then
				hasIncoming[talent.tier .. "," .. talent.column] = true
				hasOutgoing[talent.prereq_tier .. "," .. talent.prereq_column] = true
			end
		end
		local showcase = {}
		local showcaseRows = {3, 5, 7}
		for _, targetRow in ipairs(showcaseRows) do
			local pick = nil
			local pickScore = 0
			for _, talent in ipairs(spec.exceptional_talents) do
				if (talent.tier == targetRow) then
					local key = talent.tier .. "," .. talent.column
					local score = 1
					if (hasIncoming[key]) then score = 2 end
					if (hasOutgoing[key]) then score = 3 end
					if (score > pickScore) then
						pick = talent
						pickScore = score
					end
				end
			end
			-- Fallback: if no exceptional talent in this row, pick the one with smallest max rank
			if (not pick) then
				local bestRank = 999
				for _, talent in ipairs(spec.icons) do
					if (talent.tier == targetRow and talent.max_rank < bestRank) then
						bestRank = talent.max_rank
						pick = talent
					end
				end
			end
			if (pick) then
				table.insert(showcase, pick)
			end
		end
		local count = 0
		for _, talent in ipairs(showcase) do
			count = count + 1

			local row = CreateFrame("Frame", nil, leftCol)
			row:SetWidth(200)
			row:SetHeight(CELL_SIZE)
			row:SetPoint("TOP", abilitiesHeader, "BOTTOM", 0, -(count - 1) * (CELL_SIZE + 5) - 20)

			-- Tier unlock requirement (lock icon + points needed, left of talent)
			local tierReq = (talent.tier - 1) * 5
			local lockText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lockText:SetFont("Fonts\\FRIZQT__.TTF", 16)
			lockText:SetTextColor(190/255, 136/255, 121/255)
			lockText:SetWidth(40)
			lockText:SetJustifyH("RIGHT")
			lockText:SetPoint("LEFT", row, "LEFT", -130, 0)
			lockText:SetText(tierReq - pointsSpent)

			local lockTex = row:CreateTexture(nil, "OVERLAY")
			lockTex:SetWidth(138)
			lockTex:SetHeight(16)
			lockTex:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\tier-lock")
			lockTex:SetPoint("LEFT", lockText, "RIGHT", 6, 0)

			if (pointsSpent >= tierReq) then
				lockText:SetAlpha(0)
				lockTex:SetAlpha(0)
			else
				lockText:SetAlpha(1)
				lockTex:SetAlpha(1)
			end

			local icon = CTalentIcon(row, CELL_SIZE)
			icon:SetTalentData(talent.talent_tab, talent.talent_index)
			if (icon.curr_rank >= icon.max_rank) then
				if (icon.is_exceptional) then
					icon.border:SetTexture(TALENT_ASSETS .. "talent-frame-square-gold")
				else
					icon.border:SetTexture(TALENT_ASSETS .. "talent-frame-circle-gold")
				end
			end
			icon.frame:SetPoint("LEFT", lockTex, "RIGHT", -40, 0)
			icon.frame:RegisterForClicks()
			icon.frame:SetScript("OnClick", nil)
			local classColors = SPEC_HAZE_COLORS[englishClass]
			local hazeColor = (classColors and classColors[specIndex]) or DEFAULT_HAZE_COLOR
			icon:SetHazeColor(hazeColor[1], hazeColor[2], hazeColor[3])
			icon.haze_tex:SetAlpha(1.0)

			local abilName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			abilName:SetPoint("LEFT", icon.frame, "RIGHT", 8, 0)
			abilName:SetFont("Fonts\\FRIZQT__.TTF", 12)
			abilName:SetText(talent.talent_name)
			abilName:SetTextColor(1, 1, 1)
		end

		-- Points invested title (above grid, same level as spec name)
		local pointsTitle = self.expanded:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		pointsTitle:SetFont("Fonts\\FRIZQT__.TTF", 22)
		if (pointsSpent > 0) then
			pointsTitle:SetText("|cff00ff00" .. pointsSpent .. "|r TALENT POINTS INVESTED")
		else
			pointsTitle:SetText("|cff808080" .. pointsSpent .. "|r TALENT POINTS INVESTED")
		end
		pointsTitle:SetTextColor(1, 1, 1)
		pointsTitle:SetJustifyH("CENTER")

		-- Talent grid (right side, vertically centered)
		local gridH = GRID_ROWS * CELL_SIZE + 20
		local gridContainer = CreateFrame("Frame", nil, self.expanded)
		gridContainer:SetWidth(gridW)
		gridContainer:SetHeight(gridH)
		gridContainer:SetPoint("CENTER", self.expanded, "RIGHT", -EXPANDED_HORIZONTAL_PADDING, 0)

		-- Align points title above grid, then align spec name to same vertical position
		pointsTitle:SetPoint("TOP", gridContainer, "TOP", 0, 30)
		specName:ClearAllPoints()
		specName:SetPoint("TOP", pointsTitle, "TOP", 0, 0)
		specName:SetPoint("LEFT", leftCol, "LEFT", 0, 0)
		specName:SetPoint("RIGHT", leftCol, "RIGHT", 0, 0)

		-- Tier lock for expanded grid
		local expTierLock = CreateFrame("Frame", nil, gridContainer)
		expTierLock:SetWidth(138)
		expTierLock:SetHeight(16)
		expTierLock:SetFrameLevel(gridContainer:GetFrameLevel() + 5)
		local expTierLockTex = expTierLock:CreateTexture(nil, "OVERLAY")
		expTierLockTex:SetAllPoints(expTierLock)
		expTierLockTex:SetTexture("Interface\\AddOns\\ModernSpellBook\\Assets\\Talents\\tier-lock")
		expTierLock:Hide()

		local expTierLockText = gridContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		expTierLockText:SetFont("Fonts\\FRIZQT__.TTF", 16)
		expTierLockText:SetTextColor(190/255, 136/255, 121/255)
		expTierLockText:Hide()

		local firstLockedTier = nil
		local totalAvailable = UnitLevel("player") - 9
		if (totalAvailable < 0) then totalAvailable = 0 end
		local totalSpent = 0
		for _, s in ipairs(self.specs) do
			local _, _, sp = GetTalentTabInfo(s.tab_index)
			totalSpent = totalSpent + sp
		end
		local remaining = totalAvailable - totalSpent
		local is_max_no_points = (UnitLevel("player") >= 60 and remaining <= 0)
		if (not is_max_no_points) then
			for tier = 1, GRID_ROWS do
				if (pointsSpent < (tier - 1) * 5) then
					firstLockedTier = tier
					break
				end
			end
		end
		if (firstLockedTier) then
			local pointsNeeded = (firstLockedTier - 1) * 5 - pointsSpent
			expTierLock:SetPoint("RIGHT", gridContainer, "TOPLEFT",
				60, -(10 + (firstLockedTier - 1) * CELL_SIZE + CELL_SIZE / 2))
			expTierLock:Show()
			expTierLockText:SetPoint("RIGHT", expTierLock, "LEFT", -4, 0)
			expTierLockText:SetText(pointsNeeded)
			expTierLockText:Show()
		end

		-- Move talent icons into expanded grid
		for _, talent in ipairs(spec.icons) do
			talent.frame:SetParent(gridContainer)
			talent:SetGridPosition(
				talent.tier - 1,
				talent.column - 1,
				10, 10)
			talent.frame:Show()
		end

		-- Rebuild connections in the new container
		local occupied = {}
		for _, talent in ipairs(spec.icons) do
			occupied[(talent.tier - 1) .. "," .. (talent.column - 1)] = true
		end

		-- Clear old arrows
		for _, connData in ipairs(spec.connections) do
			connData.connection:Clear()
		end

		-- Rebuild with new parent
		local edges = {}
		for _, talent in ipairs(spec.icons) do
			if (talent.prereq_tier and talent.prereq_column) then
				table.insert(edges, talent)
			end
		end
		table.sort(edges, function(a, b)
			local a_straight = (a.prereq_column == a.column) and 0 or 1
			local b_straight = (b.prereq_column == b.column) and 0 or 1
			return a_straight < b_straight
		end)

		spec.connections = {}
		for _, talent in ipairs(edges) do
			local conn = CTalentConnection(gridContainer)
			conn:BuildRoute(
				talent.prereq_tier - 1,
				talent.prereq_column - 1,
				talent.tier - 1,
				talent.column - 1,
				CELL_SIZE,
				10,
				10,
				occupied)
			if (conn.routed_cells) then
				for _, cell in ipairs(conn.routed_cells) do
					occupied[cell.r .. "," .. cell.c] = true
				end
			end
			table.insert(spec.connections, {
				connection = conn,
				prereq_tier = talent.prereq_tier,
				prereq_column = talent.prereq_column,
				target = talent,
			})
		end

		self.expanded:Show()
		self.back_btn:Show()
		self:Refresh()
	end;

	CollapseSpec = function(self)
		self.expanded_spec = nil
		self.expanded:Hide()
		self.back_btn:Hide()

		-- Reparent icons back to spec panels and rebuild connections
		local col_offset = (GRID_COLS_MAX - GRID_COLS_DEFAULT) * CELL_SIZE / 2
		for _, spec in ipairs(self.specs) do
			for _, talent in ipairs(spec.icons) do
				talent.frame:SetParent(spec.panel)
				talent:SetGridPosition(
					talent.tier - 1,
					talent.column - 1,
					PANEL_INNER_PAD + col_offset,
					HEADER_HEIGHT + GRID_VERT_PAD)
				talent.frame:Show()
			end

			-- Rebuild connections in spec panel
			local occupied = {}
			for _, talent in ipairs(spec.icons) do
				occupied[(talent.tier - 1) .. "," .. (talent.column - 1)] = true
			end

			for _, connData in ipairs(spec.connections) do
				connData.connection:Clear()
			end

			local edges = {}
			for _, talent in ipairs(spec.icons) do
				if (talent.prereq_tier and talent.prereq_column) then
					table.insert(edges, talent)
				end
			end
			table.sort(edges, function(a, b)
				local a_straight = (a.prereq_column == a.column) and 0 or 1
				local b_straight = (b.prereq_column == b.column) and 0 or 1
				return a_straight < b_straight
			end)

			spec.connections = {}
			for _, talent in ipairs(edges) do
				local conn = CTalentConnection(spec.panel)
				conn:BuildRoute(
					talent.prereq_tier - 1,
					talent.prereq_column - 1,
					talent.tier - 1,
					talent.column - 1,
					CELL_SIZE,
					PANEL_INNER_PAD + col_offset,
					HEADER_HEIGHT + GRID_VERT_PAD,
					occupied)
				if (conn.routed_cells) then
					for _, cell in ipairs(conn.routed_cells) do
						occupied[cell.r .. "," .. cell.c] = true
					end
				end
				table.insert(spec.connections, {
					connection = conn,
					prereq_tier = talent.prereq_tier,
					prereq_column = talent.prereq_column,
					target = talent,
				})
			end

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

			-- Build prereq checker: returns true if talent at (tier, column) is maxed
			local function checkPrereq(tier, column)
				for _, talent in ipairs(spec.icons) do
					if (talent.tier == tier and talent.column == column) then
						return talent.curr_rank == talent.max_rank
					end
				end
				return false
			end

			for _, talent in ipairs(spec.icons) do
				talent:RefreshRank()
				talent:UpdateVisualState(pointsSpent, checkPrereq, remaining)
			end

			-- Update connection arrow states
			-- Golden only when prereq is maxed AND target is invested or investable
			for _, connData in ipairs(spec.connections) do
				local prereq_maxed = checkPrereq(connData.prereq_tier, connData.prereq_column)
				local target_state = connData.target.visual_state
				local unlocked = prereq_maxed and (target_state ~= "locked_in_locked_tier" and target_state ~= "locked_in_unlocked_tier")
				connData.connection:UpdateState(unlocked)
			end

			-- Position tier lock at first locked tier
			-- Hide lock entirely at max level with no points remaining
			local col_offset = (GRID_COLS_MAX - GRID_COLS_DEFAULT) * CELL_SIZE / 2
			local firstLockedTier = nil
			local is_max_no_points = (UnitLevel("player") >= 60 and remaining <= 0)
			if (not is_max_no_points) then
				for tier = 1, GRID_ROWS do
					if (pointsSpent < (tier - 1) * 5) then
						firstLockedTier = tier
						break
					end
				end
			end
			if (firstLockedTier) then
				local pointsNeeded = (firstLockedTier - 1) * 5 - pointsSpent
				spec.tier_lock_text:ClearAllPoints()
				spec.tier_lock_text:SetPoint("LEFT", spec.panel, "TOPLEFT",
					PANEL_INNER_PAD,
					-(HEADER_HEIGHT + GRID_VERT_PAD + (firstLockedTier - 1) * CELL_SIZE + CELL_SIZE / 2))
				spec.tier_lock_text:SetText(pointsNeeded)
				spec.tier_lock_text:Show()
				spec.tier_lock:ClearAllPoints()
				spec.tier_lock:SetPoint("LEFT", spec.tier_lock_text, "RIGHT", 4, 0)
				spec.tier_lock:Show()
			else
				spec.tier_lock:Hide()
				spec.tier_lock_text:Hide()
			end
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

if (ToggleTalentFrame) then
	local orig_ToggleTalentFrame = ToggleTalentFrame
	ToggleTalentFrame = function()
		TalentTree:Toggle()
	end
else
	-- Blizzard_TalentUI might not be loaded yet — hook when it loads
	local hookFrame = CreateFrame("Frame")
	hookFrame:RegisterEvent("ADDON_LOADED")
	hookFrame:SetScript("OnEvent", function()
		if (arg1 == "Blizzard_TalentUI" and ToggleTalentFrame) then
			local orig = ToggleTalentFrame
			ToggleTalentFrame = function()
				TalentTree:Toggle()
			end
			hookFrame:UnregisterEvent("ADDON_LOADED")
		end
	end)
end
