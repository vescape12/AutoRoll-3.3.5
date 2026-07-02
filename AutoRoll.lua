
AutoRoll = {}
AutoRoll.Version = "1.0"
AutoRoll.Roll = {
	Pass = 0,
	Need = 1,
	Greed = 2,
	Disenchant = 3,
    Ignore = 4,
}
AutoRoll_Options = AutoRoll_Options or {}
AutoRoll_Autoroll = AutoRoll_Autoroll or {}
AutoRoll.Queue = {}
AutoRollOptionsFrame = nil

local function SL_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AutoRoll:|r " .. tostring(msg))
end

function AutoRoll.RollIgnore(name, quality)
	if name then
		AutoRoll_Autoroll[name] = { quality = quality or 0, roll = AutoRoll.Roll.Ignore }
		AutoRoll.RenderAutorollList()
	end
end

function AutoRoll.EnsureOptions()
		local o = AutoRoll_Options
		if o.Enabled == nil then o.Enabled = true end
	if o.HideDefaultFrames == nil then o.HideDefaultFrames = true end
	if o.AutoLoot == nil then o.AutoLoot = true end
	if o.AutoConfirm == nil then o.AutoConfirm = true end
	if o.ShowMinimapButton == nil then o.ShowMinimapButton = true end
	if o.MinimapButtonPosition == nil then o.MinimapButtonPosition = 281 end
	if o.MinimapButtonRadius == nil then o.MinimapButtonRadius = 80 end
	if o.AutoGreedGreens == nil then o.AutoGreedGreens = false end
	if o.AutoGreedGreensMinLevel == nil then o.AutoGreedGreensMinLevel = 60 end
	if o.AutoGreedRoll == nil then o.AutoGreedRoll = "disenchant" end   -- "greed", "disenchant", "pass"
	if o.AutoGreedQualities == nil then o.AutoGreedQualities = "green" end  -- "green", "greenblue
end

local function CreateOptionsFrame()
	if AutoRollOptionsFrame then return end

	local f = CreateFrame("Frame", "AutoRollOptionsFrame", UIParent)
	f:SetWidth(575)
	f:SetHeight(480)
	f:SetPoint("CENTER")
	f:Hide()

	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(f)
	bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText("AutoRoll")


	-- Enable/Disable AutoRoll checkbox
	local enableCheck = CreateFrame("CheckButton", "AutoRollOptionsFrame_Enable", f, "UICheckButtonTemplate")
	enableCheck:SetPoint("TOPLEFT", 10, -40)
	enableCheck:SetChecked(AutoRoll_Options.Enabled)
	enableCheck:SetScript("OnClick", function(self)
		AutoRoll_Options.Enabled = self:GetChecked() and true or false
	end)
	local enableLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	enableLabel:SetFontObject(GameFontNormal)
	enableLabel:SetPoint("LEFT", enableCheck, "RIGHT", 1, 1)
	enableLabel:SetText("Enable AutoRoll")


	-- Auto-roll by quality row
	local autoGreedCheck = CreateFrame("CheckButton", "AutoRollOptionsFrame_AutoGreedGreens", f, "UICheckButtonTemplate")
	autoGreedCheck:SetPoint("TOPLEFT", 10, -66)
	autoGreedCheck:SetChecked(AutoRoll_Options.AutoGreedGreens)
	autoGreedCheck:SetScript("OnClick", function(self)
		AutoRoll_Options.AutoGreedGreens = self:GetChecked() and true or false
	end)
	local autoGreedLabel1 = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	autoGreedLabel1:SetPoint("LEFT", autoGreedCheck, "RIGHT", 1, 1)
	autoGreedLabel1:SetText("Auto-")

	-- Roll dropdown (Greed / Disenchant / Pass)
	local rollBtn = CreateFrame("Button", "AutoRollOptionsFrame_AutoGreedRollBtn", f, "UIPanelButtonTemplate")
	rollBtn:SetHeight(20)
	rollBtn:SetPoint("LEFT", autoGreedLabel1, "RIGHT", 2, -1)
	local function UpdateRollBtnText()
		local t = AutoRoll_Options.AutoGreedRoll
		local label = t == "greed" and "Greed" or t == "pass" and "Pass" or "Disenchant"
		rollBtn:SetText(label)
		rollBtn:SetWidth(rollBtn:GetFontString():GetStringWidth() + 18)
	end
	UpdateRollBtnText()
	rollBtn:SetScript("OnClick", function(self)
		if not self.menu then
			self.menu = CreateFrame("Frame", "AutoRollRollDropMenu", UIParent, "UIDropDownMenuTemplate")
		end
		local opts = {
			{ text = "Greed",       val = "greed" },
			{ text = "Disenchant",  val = "disenchant" },
			{ text = "Pass",        val = "pass" },
		}
		local menuTable = {}
		for _, o in ipairs(opts) do
			local v = o.val
			table.insert(menuTable, {
				text = o.text,
				checked = (AutoRoll_Options.AutoGreedRoll == v),
				func = function()
					AutoRoll_Options.AutoGreedRoll = v
					UpdateRollBtnText()
				end,
			})
		end
		EasyMenu(menuTable, self.menu, self, 0, 20, "MENU")
	end)

	local autoGreedLabel2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	autoGreedLabel2:SetPoint("LEFT", rollBtn, "RIGHT", 4, 1)
	autoGreedLabel2:SetText("all")

	-- Quality dropdown (Green / Green+Blue)
	local qualBtn = CreateFrame("Button", "AutoRollOptionsFrame_AutoGreedQualBtn", f, "UIPanelButtonTemplate")
	qualBtn:SetHeight(20)
	qualBtn:SetPoint("LEFT", autoGreedLabel2, "RIGHT", 2, -1)
	local function UpdateQualBtnText()
		local t = AutoRoll_Options.AutoGreedQualities
		qualBtn:SetText(t == "greenblue" and "green & blue" or "green")
		qualBtn:SetWidth(qualBtn:GetFontString():GetStringWidth() + 18)
	end
	UpdateQualBtnText()
	qualBtn:SetScript("OnClick", function(self)
		if not self.menu then
			self.menu = CreateFrame("Frame", "AutoRollQualDropMenu", UIParent, "UIDropDownMenuTemplate")
		end
		local menuTable = {
			{
				text = "Green only",
				checked = (AutoRoll_Options.AutoGreedQualities == "green"),
				func = function()
					AutoRoll_Options.AutoGreedQualities = "green"
					UpdateQualBtnText()
				end,
			},
			{
				text = "Green & Blue",
				checked = (AutoRoll_Options.AutoGreedQualities == "greenblue"),
				func = function()
					AutoRoll_Options.AutoGreedQualities = "greenblue"
					UpdateQualBtnText()
				end,
			},
		}
		EasyMenu(menuTable, self.menu, self, 0, 20, "MENU")
	end)

	local autoGreedLabel3 = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	autoGreedLabel3:SetPoint("LEFT", qualBtn, "RIGHT", 4, 1)
	autoGreedLabel3:SetText("items at level")

	local levelBox = CreateFrame("EditBox", "AutoRollOptionsFrame_AutoGreedLevel", f, "InputBoxTemplate")
	levelBox:SetWidth(24)
	levelBox:SetHeight(18)
	levelBox:SetPoint("LEFT", autoGreedLabel3, "RIGHT", 8, -1)
	levelBox:SetAutoFocus(false)
	levelBox:SetNumeric(true)
	levelBox:SetMaxLetters(2)
	levelBox:SetText(tostring(AutoRoll_Options.AutoGreedGreensMinLevel))
	levelBox:SetScript("OnEnterPressed", function(self)
		local val = tonumber(self:GetText()) or 60
		val = math.max(1, math.min(99, val))
		AutoRoll_Options.AutoGreedGreensMinLevel = val
		self:SetText(tostring(val))
		self:ClearFocus()
	end)
	levelBox:SetScript("OnEditFocusLost", function(self)
		local val = tonumber(self:GetText()) or 60
		val = math.max(1, math.min(99, val))
		AutoRoll_Options.AutoGreedGreensMinLevel = val
		self:SetText(tostring(val))
	end)

	local levelLabel2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	levelLabel2:SetPoint("LEFT", levelBox, "RIGHT", 4, 0)
	levelLabel2:SetText("or above")

	-- Invisible tooltip trigger spanning the whole row
	local rowTip = CreateFrame("Frame", nil, f)
	rowTip:SetPoint("LEFT", autoGreedCheck, "LEFT", 0, 0)
	rowTip:SetPoint("RIGHT", levelLabel2, "RIGHT", 0, 0)
	rowTip:SetHeight(22)
	rowTip:SetFrameLevel(f:GetFrameLevel() + 1)
	rowTip:EnableMouse(true)
	rowTip:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText("Saved item rules take priority over this setting.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	rowTip:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOPLEFT", 16, -138)
	header:SetText("Saved auto-roll items")

	-- Search box
	local searchBox = CreateFrame("EditBox", "AutoRollOptionsFrame_Search", f, "InputBoxTemplate")
	searchBox:SetWidth(200)
	searchBox:SetHeight(20)
	searchBox:SetPoint("LEFT", header, "RIGHT", 12, 0)
	searchBox:SetAutoFocus(false)
	searchBox:SetMaxLetters(64)
	local searchHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	searchHint:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
	searchHint:SetText("Search...")
	searchBox:SetScript("OnTextChanged", function(self)
		local txt = self:GetText()
		if txt == "" then searchHint:Show() else searchHint:Hide() end
		AutoRoll.searchFilter = txt ~= "" and txt:lower() or nil
		AutoRoll.RenderAutorollList()
	end)
	searchBox:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
		AutoRoll.searchFilter = nil
		AutoRoll.RenderAutorollList()
	end)
	AutoRollOptionsFrame_Search = searchBox

	local scrollFrame = CreateFrame("ScrollFrame", "AutoRollOptionsFrame_AutorollScroll", f, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 12, -158)
	scrollFrame:SetWidth(527)
	scrollFrame:SetHeight(282)

	local content = CreateFrame("Frame", "AutoRollOptionsFrame_AutorollScrollContent", scrollFrame)
	content:SetWidth(520)
	content:SetHeight(1)
	content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
	content.rows = {}

	scrollFrame:SetScrollChild(content)

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -5, -5)

	AutoRollOptionsFrame = f
	AutoRollOptionsFrame_AutorollScroll = scrollFrame
	AutoRollOptionsFrame_AutorollScrollContent = content

	tinsert(UISpecialFrames, "AutoRollOptionsFrame")
end

function AutoRoll.UpdateAutorollScroll()
	if not AutoRollOptionsFrame_AutorollScrollContent then return end
	if not AutoRollOptionsFrame_AutorollScroll then return end

	local content = AutoRollOptionsFrame_AutorollScrollContent
	local rows = content.rows
	local totalHeight = math.max(1, (#rows * 20))
	content:SetHeight(totalHeight)
end

function AutoRoll.ToggleOptions()
	CreateOptionsFrame()
	AutoRoll.RenderAutorollList()
	if AutoRollOptionsFrame:IsShown() then
		AutoRollOptionsFrame:Hide()
	else
		AutoRollOptionsFrame:Show()
	end
end

function AutoRoll.ApplyOptionsFromUI()
		AutoRoll_Options.Enabled = AutoRollOptionsFrame_Enable:GetChecked() and true or false
end

local function DoHideRollFrame(rollId)
    -- Blizzard default GroupLootFrames (when ElvUI Loot Roll skin is OFF)
    for i = 1, (NUM_LOOT_ROLL_FRAMES or 4) do
        local frame = _G["GroupLootFrame" .. i]
        if frame and frame.rollID == rollId then
            frame:Hide()
        end
    end

    -- LootRollFrame legacy fallback
    if LootRollFrame and LootRollFrame:IsShown() then
        LootRollFrame:Hide()
    end

    -- ElvUI: access M.RollBars directly via the ElvUI addon table.
    -- ElvUI[1] is the Engine (E), ElvUI[2] is the second return from
    -- unpack(select(2, ...)) which is the Locale table -- the module
    -- system lives on E, so we use ElvUI[1].
    local E = ElvUI and ElvUI[1]
    local M = E and E.GetModule and E:GetModule('Misc')
    if M and M.RollBars then
        -- Hide and clear the matching frame
        for _, frame in ipairs(M.RollBars) do
            if frame.rollID == rollId then
                frame.rollID = nil
                frame.time = nil
                frame:Hide()
                frame:ClearAllPoints()
            end
        end

        -- Reanchor remaining active frames to close the gap
        local prev = nil
        for _, frame in ipairs(M.RollBars) do
            if frame.rollID then
                frame:ClearAllPoints()
                if prev then
                    frame:SetPoint("TOP", prev, "BOTTOM", 0, -4)
                else
                    frame:SetPoint("TOP", AlertFrameHolder, "BOTTOM", 0, -4)
                end
                prev = frame
            end
        end
    else
        -- ElvUI module not accessible: fall back to UIParent recursive scan
        local visited = {}
        local function scan(parent, depth)
            if depth > 8 then return end
            local ok, children = pcall(function() return {parent:GetChildren()} end)
            if not ok then return end
            for _, child in ipairs(children) do
                if not visited[child] then
                    visited[child] = true
                    if child.rollID == rollId or child.rollid == rollId then
                        child:Hide()
                        child:ClearAllPoints()
                    end
                    scan(child, depth + 1)
                end
            end
        end
        scan(UIParent, 0)
    end
end

-- Deferred by one OnUpdate tick so we always run after ALL other addons'
-- START_LOOT_ROLL handlers have finished (including ElvUI showing its frame).
local _hideQueue = {}
local _hidePump = CreateFrame("Frame")
_hidePump:Hide()
_hidePump:SetScript("OnUpdate", function(self)
    for rollId in pairs(_hideQueue) do
        DoHideRollFrame(rollId)
        _hideQueue[rollId] = nil
    end
    self:Hide()
end)

local function HideRollFrame(rollId)
    _hideQueue[rollId] = true
    _hidePump:Show()
end

-- Right-click autoroll hook system.
-- Called each time a loot roll starts. Finds the roll frame for this rollId
-- and hooks its buttons so right-clicking opens an "Always X" context menu.
local function HookRollFrameButtons(rollId, itemName, itemQuality, canDisenchant)
    if not itemName then return end

    -- Collect all frames that match this rollId
    local frames = {}

    -- Blizzard GroupLootFrames
    for i = 1, (NUM_LOOT_ROLL_FRAMES or 4) do
        local f = _G["GroupLootFrame" .. i]
        if f and f.rollID == rollId then
            table.insert(frames, f)
        end
    end

    -- Recursive scan for ElvUI frames (same approach as DoHideRollFrame)
    local visited = {}
    local function scan(parent, depth)
        if depth > 8 then return end
        local ok, children = pcall(function() return {parent:GetChildren()} end)
        if not ok then return end
        for _, child in ipairs(children) do
            if not visited[child] then
                visited[child] = true
                if child.rollID == rollId then
                    table.insert(frames, child)
                end
                scan(child, depth + 1)
            end
        end
    end
    scan(UIParent, 0)

    -- Map of button names to roll values - we try common naming patterns
    -- for both Blizzard and ElvUI button children
    local buttonRolls = {
        -- Blizzard button names (children of GroupLootFrame)
        ["NeedButton"]         = AutoRoll.Roll.Need,
        ["GreedButton"]        = AutoRoll.Roll.Greed,
        ["DisenchantButton"]   = AutoRoll.Roll.Disenchant,
        ["PassButton"]         = AutoRoll.Roll.Pass,
        -- ElvUI uses different child names - we detect by checking .rollType
        -- which ElvUI sets on each button, or fall back to position order
    }

    local rollLabels = {
        [AutoRoll.Roll.Need]        = "Always Need",
        [AutoRoll.Roll.Greed]       = "Always Greed",
        [AutoRoll.Roll.Disenchant]  = "Always Disenchant",
        [AutoRoll.Roll.Pass]        = "Always Pass",
    }

    local function ShowAutoRollMenu(anchorFrame, rollId, canDisenchant)
        local menuFrame = _G["AutoRoll_ContextMenu"]
        if not menuFrame then
            menuFrame = CreateFrame("Frame", "AutoRoll_ContextMenu", UIParent, "UIDropDownMenuTemplate")
        end
        local menuTable = {
            {
                text = "Always Need",
                checked = (AutoRoll_Autoroll[itemName] and AutoRoll_Autoroll[itemName].roll == AutoRoll.Roll.Need),
                func = function()
                    AutoRoll.RollNeed(itemName, rollId, itemQuality)
                    HideRollFrame(rollId)
                end,
            },
            {
                text = "Always Greed",
                checked = (AutoRoll_Autoroll[itemName] and AutoRoll_Autoroll[itemName].roll == AutoRoll.Roll.Greed),
                func = function()
                    AutoRoll.RollGreed(itemName, rollId, itemQuality)
                    HideRollFrame(rollId)
                end,
            },
            {
                text = "Always Disenchant",
                checked = (AutoRoll_Autoroll[itemName] and AutoRoll_Autoroll[itemName].roll == AutoRoll.Roll.Disenchant),
                func = function()
                    AutoRoll.RollDisenchant(itemName, rollId, itemQuality, canDisenchant)
                    HideRollFrame(rollId)
                end,
            },
            {
                text = "Always Pass",
                checked = (AutoRoll_Autoroll[itemName] and AutoRoll_Autoroll[itemName].roll == AutoRoll.Roll.Pass),
                func = function()
                    AutoRoll.Pass(itemName, rollId, itemQuality)
                    HideRollFrame(rollId)
                end,
            },
            {
                text = "Always Ignore",
                checked = (AutoRoll_Autoroll[itemName] and AutoRoll_Autoroll[itemName].roll == AutoRoll.Roll.Ignore),
                func = function()
                    AutoRoll.RollIgnore(itemName, itemQuality)
                    HideRollFrame(rollId)
                end,
            },
        }
        EasyMenu(menuTable, menuFrame, anchorFrame, 0, 32, "MENU")
    end

    local function HookButton(btn)
        if not btn or btn._autoRollHooked then return end
        btn._autoRollHooked = true

        local origOnEnter = btn:GetScript("OnEnter")
        btn:SetScript("OnEnter", function(self)
            if origOnEnter then origOnEnter(self) end
            if GameTooltip:IsShown() then
                GameTooltip:AddLine("Right-click to set as auto-roll", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            else
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Right-click to set as auto-roll", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end
        end)

        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local origOnClick = btn:GetScript("OnClick")
        btn:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                ShowAutoRollMenu(self, rollId, canDisenchant)
            elseif origOnClick then
                origOnClick(self, button)
            end
        end)
    end

    for _, frame in ipairs(frames) do
        -- Try named children (Blizzard)
        for btnName, _ in pairs(buttonRolls) do
            local btn = _G[frame:GetName() and (frame:GetName() .. btnName) or ""]
                     or frame[btnName]
            HookButton(btn)
        end

        for _, child in ipairs({frame:GetChildren()}) do
            if child.rollType ~= nil then
                HookButton(child)
            end
            local ok, grandchildren = pcall(function() return {child:GetChildren()} end)
            if ok then
                for _, gc in ipairs(grandchildren) do
                    if gc.rollType ~= nil then
                        HookButton(gc)
                    end
                end
            end
        end
    end
end

-- Hook pump: defer button hooking by one OnUpdate tick, same as HideRollFrame,
-- so ElvUI has finished setting up its frame and buttons before we touch them.
local _hookQueue = {}
local _hookPump = CreateFrame("Frame")
_hookPump:Hide()
_hookPump:SetScript("OnUpdate", function(self)
    for rollId, info in pairs(_hookQueue) do
        HookRollFrameButtons(rollId, info.name, info.quality, info.canDisenchant)
        _hookQueue[rollId] = nil
    end
    self:Hide()
end)

function AutoRoll.OnLoad(self)
    SLASH_AUTOROLL1 = "/aloot"
    SlashCmdList["AUTOROLL"] = function()
        AutoRoll.ToggleOptions()
    end

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("START_LOOT_ROLL")
	self:RegisterEvent("CANCEL_LOOT_ROLL")
	self:RegisterEvent("CONFIRM_LOOT_ROLL")
end

function AutoRoll.OnEvent(self, event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == "AutoRoll" then
		AutoRoll.EnsureOptions()
		AutoRoll.Initialize()
		return
	end

	if event == "START_LOOT_ROLL" then
		if not AutoRoll_Options.Enabled then return end
		local rollId = arg1
		local timeout = arg2 or 0
		local texture, name, count, quality, bindOnPickup, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(rollId)

		-- Auto-roll by quality: if enabled and item quality matches and player
		-- meets the level threshold, roll automatically. Saved item rules take
		-- priority and are checked below -- this only fires if no saved rule exists.
		local autoRolledByQuality = false
		if AutoRoll_Options.AutoGreedGreens then
			local playerLevel = UnitLevel("player") or 0
			local minLevel = AutoRoll_Options.AutoGreedGreensMinLevel or 60
			local quals = AutoRoll_Options.AutoGreedQualities or "green"
			local qualMatch = (quality == 2) or (quals == "greenblue" and quality == 3)
			if qualMatch and playerLevel >= minLevel then
				-- Only fire if there's no saved rule for this specific item
				if not (name and AutoRoll_Autoroll[name]) then
					local rollChoice = AutoRoll_Options.AutoGreedRoll or "disenchant"
					local effectiveRoll
					if rollChoice == "greed" then
						effectiveRoll = AutoRoll.Roll.Greed
					elseif rollChoice == "pass" then
						effectiveRoll = AutoRoll.Roll.Pass
					else
						-- disenchant, fall back to greed if not available
						effectiveRoll = canDisenchant and AutoRoll.Roll.Disenchant or AutoRoll.Roll.Greed
					end
					RollOnLoot(rollId, effectiveRoll)
					HideRollFrame(rollId)
					autoRolledByQuality = true
				end
			end
		end

		if not autoRolledByQuality then
			if AutoRoll_Options.AutoLoot and name and AutoRoll_Autoroll[name] then
				local savedRoll = AutoRoll_Autoroll[name].roll
				local effectiveRoll = savedRoll
				if savedRoll == AutoRoll.Roll.Disenchant and not canDisenchant then
					effectiveRoll = AutoRoll.Roll.Greed
				end
				RollOnLoot(rollId, effectiveRoll)
				HideRollFrame(rollId)
			else
				AutoRoll.QueueLoot(rollId, timeout, texture, name, quality, canDisenchant)
				-- Hook the roll frame buttons for right-click autoroll
				_hookQueue[rollId] = { name = name, quality = quality, canDisenchant = canDisenchant }
				_hookPump:Show()
			end
		end
		return
	end

	if event == "CANCEL_LOOT_ROLL" then
		AutoRoll.ClearLoot(arg1)
		return
	end

	if event == "CONFIRM_LOOT_ROLL" then
		if AutoRoll_Options.AutoConfirm then
			ConfirmLootRoll(arg1, arg2)
			StaticPopup_Hide("CONFIRM_LOOT_ROLL")
		end
		return
	end
end

function AutoRoll.Initialize()
	AutoRoll.CreateMinimapButton()
	AutoRoll.UpdateMinimapButtonPosition()
	SL_Print("loaded. Use /aloot to open options.")
end


function AutoRoll.CreateMinimapButton()
	if AutoRoll.MinimapButton then return end

	local b = CreateFrame("Button", "AutoRollMinimapButton", UIParent)
	b:SetWidth(22)
	b:SetHeight(22)
	b:SetFrameStrata("LOW")
	b:EnableMouse(true)
	b:SetMovable(true)
	b:RegisterForClicks("LeftButtonUp")
	b:RegisterForDrag("RightButton")

	local icon = b:CreateTexture(nil, "BACKGROUND")
	icon:SetAllPoints(b)
	icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon:SetVertexColor(1, 1, 1, 1)
	b.icon = icon
	b:SetFrameLevel(Minimap:GetFrameLevel() + 3)

	b:SetScript("OnClick", function(_, button)
		if button == "LeftButton" then
			AutoRoll.ToggleOptions()
		end
	end)

	b:SetScript("OnDragStart", function()
		if IsShiftKeyDown() then
			b:StartMoving()
		end
	end)

	b:SetScript("OnDragStop", function()
		b:StopMovingOrSizing()

		local centerX, centerY = Minimap:GetCenter()
		local buttonX, buttonY = b:GetCenter()
		local dx = buttonX - centerX
		local dy = buttonY - centerY

		AutoRoll_Options.MinimapButtonPosition = math.deg(math.atan2(dy, dx))
		AutoRoll_Options.MinimapButtonRadius = math.sqrt(dx * dx + dy * dy)
		AutoRoll.UpdateMinimapButtonPosition()
	end)

	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("AutoRoll")
		GameTooltip:AddLine("Left click to open options", 1, 1, 1)
		GameTooltip:AddLine("Shift + right drag to move", 1, 1, 1)
		GameTooltip:Show()
	end)

	b:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	b:Hide()
	AutoRoll.MinimapButton = b
end

function AutoRoll.UpdateMinimapButtonPosition()
	if not AutoRoll.MinimapButton then return end

	if AutoRoll_Options.ShowMinimapButton then
		local angle = AutoRoll_Options.MinimapButtonPosition or 281
		local radius = AutoRoll_Options.MinimapButtonRadius or 80
		local rad = math.rad(angle)
		local x = math.cos(rad) * radius
		local y = math.sin(rad) * radius
		AutoRoll.MinimapButton:Show()
		AutoRoll.MinimapButton:ClearAllPoints()
		AutoRoll.MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
	else
		AutoRoll.MinimapButton:Hide()
	end
end

function AutoRoll.ApplyAutoRoll(itemName, roll)
	for i, loot in ipairs(AutoRoll.Queue) do
		if loot.name == itemName then
			RollOnLoot(loot.rollId, roll)
		end
	end
end

function AutoRoll.RollDisenchant(name, rollId, quality, canDisenchant)
	if name and rollId then
		AutoRoll_Autoroll[name] = { quality = quality or 0, roll = AutoRoll.Roll.Disenchant }
		AutoRoll.RenderAutorollList()
		local effectiveRoll = canDisenchant and AutoRoll.Roll.Disenchant or AutoRoll.Roll.Greed
		RollOnLoot(rollId, effectiveRoll)
	end
end

function AutoRoll.QueueLoot(rollId, timeout, texture, name, quality, canDisenchant)
	table.insert(AutoRoll.Queue, {
		rollId = rollId, timeout = timeout, texture = texture,
		name = name, quality = quality,
		canDisenchant = canDisenchant and true or false,
	})
end

function AutoRoll.ClearLoot(rollId)
	for i, loot in ipairs(AutoRoll.Queue) do
		if loot.rollId == rollId then
			table.remove(AutoRoll.Queue, i)
			break
		end
	end
end

function AutoRoll.RollNeed(name, rollId, quality)
	if name and rollId then
		AutoRoll_Autoroll[name] = { quality = quality or 0, roll = AutoRoll.Roll.Need }
		AutoRoll.RenderAutorollList()
		RollOnLoot(rollId, AutoRoll.Roll.Need)
	end
end

function AutoRoll.RollGreed(name, rollId, quality)
	if name and rollId then
		AutoRoll_Autoroll[name] = { quality = quality or 0, roll = AutoRoll.Roll.Greed }
		AutoRoll.RenderAutorollList()
		RollOnLoot(rollId, AutoRoll.Roll.Greed)
	end
end

function AutoRoll.Pass(name, rollId, quality)
	if name and rollId then
		AutoRoll_Autoroll[name] = { quality = quality or 0, roll = AutoRoll.Roll.Pass }
		AutoRoll.RenderAutorollList()
		RollOnLoot(rollId, AutoRoll.Roll.Pass)
	end
end

function AutoRoll.GetAutorollListData()
	local result = {}
	for name, info in pairs(AutoRoll_Autoroll) do
		table.insert(result, {
			name = name,
			quality = info.quality or 0,
			roll = info.roll or AutoRoll.Roll.Greed,
		})
	end
	table.sort(result, function(a, b)
		return a.name < b.name
	end)
	return result
end

function AutoRoll.RollName(roll)
	if roll == AutoRoll.Roll.Need then
		return "Need"
	elseif roll == AutoRoll.Roll.Greed then
		return "Greed"
	elseif roll == AutoRoll.Roll.Pass then
		return "Pass"
	elseif roll == AutoRoll.Roll.Disenchant then
		return "Disenchant"
	end
	return "?"
end

function AutoRoll.AutorollListRemove(name)
	AutoRoll_Autoroll[name] = nil
	AutoRoll.RenderAutorollList()
end

function AutoRoll.RenderAutorollList()
	if not AutoRollOptionsFrame then return end
	if not AutoRollOptionsFrame_AutorollScrollContent then return end

	local content = AutoRollOptionsFrame_AutorollScrollContent
	local data = AutoRoll.GetAutorollListData()

	for i = 1, #content.rows do
		content.rows[i]:Hide()
	end

	-- Apply search filter
	local filtered = {}
	for _, info in ipairs(data) do
		if not AutoRoll.searchFilter or info.name:lower():find(AutoRoll.searchFilter, 1, true) then
			table.insert(filtered, info)
		end
	end
	data = filtered

	for i, info in ipairs(data) do
		local row = content.rows[i]
		if not row then
			row = CreateFrame("Frame", nil, content)
			row:SetHeight(20)
			row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((i - 1) * 20))
			row:SetPoint("RIGHT", content, "RIGHT", -10, 0)
			row:EnableMouse(true)

			local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			text:SetPoint("RIGHT", row, "RIGHT", -10, 0)
			text:SetJustifyH("LEFT")
			text:SetNonSpaceWrap(false)
			text:SetWordWrap(false)
			row.text = text

			-- Remove button - small text
			local remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
			remove:SetHeight(18)
			remove:SetText("Remove")
			remove:SetWidth(remove:GetTextWidth() + 6)
			remove:SetPoint("LEFT", row, "LEFT", 4, 0)
			remove:SetScript("OnClick", function(self)
				AutoRoll.AutorollListRemove(self:GetParent().itemName)
			end)
			-- Make text small
			local removeText = remove:GetFontString()
			if removeText then
				removeText:SetFont(removeText:GetFont(), 10)  -- small text
			end
			row.remove = remove

			-- Dropdown button - small text
			local dropdown = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
			dropdown:SetHeight(18)
			dropdown:SetText("Disenchant")
			dropdown:SetWidth(dropdown:GetTextWidth() + 8)
			dropdown:SetPoint("LEFT", remove, "RIGHT", 4, 0)
			row.dropdown = dropdown

			-- Make dropdown text small
			local ddText = dropdown:GetFontString()
			if ddText then
				ddText:SetFont(ddText:GetFont(), 10)
			end

			text:SetPoint("LEFT", dropdown, "RIGHT", 4, 0)

			-- Dropdown menu (unchanged)
			local dropdownMenu = {
				{ text = "Need", value = AutoRoll.Roll.Need },
				{ text = "Greed", value = AutoRoll.Roll.Greed },
				{ text = "Disenchant", value = AutoRoll.Roll.Disenchant },
				{ text = "Pass", value = AutoRoll.Roll.Pass },
				{ text = "Ignore", value = AutoRoll.Roll.Ignore },
			}

			dropdown:SetScript("OnClick", function(self)
				if not self.menu then
					self.menu = CreateFrame("Frame", "AutoRollDropdownMenu"..i, UIParent, "UIDropDownMenuTemplate")
				end
				local currentInfo = nil
				for _, d in ipairs(AutoRoll.GetAutorollListData()) do
					if d.name == row.itemName then 
						currentInfo = d 
						break 
					end
				end
				local selectedRoll = currentInfo and currentInfo.roll or info.roll
				local menuTable = {}
				for _, entry in ipairs(dropdownMenu) do
					table.insert(menuTable, {
						text = entry.text,
						arg1 = entry.value,
						func = function(_, arg1)
							AutoRoll.SetAutorollRoll(row.itemName, arg1)
						end,
						checked = (selectedRoll == entry.value),
					})
				end
				EasyMenu(menuTable, self.menu, self, 76, 0, "MENU")
			end)

			content.rows[i] = row
		end

		local c = ITEM_QUALITY_COLORS[info.quality or 0]
		row.itemName = info.name
		row.text:SetText(info.name)
		row.text:SetTextColor(c.r, c.g, c.b)

		-- Update dropdown text
		if row.dropdown then
			local textStr = "?"
			if info.roll == AutoRoll.Roll.Need then
				textStr = "Need"
			elseif info.roll == AutoRoll.Roll.Greed then
				textStr = "Greed"
			elseif info.roll == AutoRoll.Roll.Disenchant then
				textStr = "Disenchant"
			elseif info.roll == AutoRoll.Roll.Pass then
				textStr = "Pass"
			elseif info.roll == AutoRoll.Roll.Ignore then
				textStr = "Ignore"
			end
			row.dropdown:SetText(textStr)
		end

		row:Show()
	end

	for i = #data + 1, #content.rows do
		content.rows[i]:Hide()
	end

	AutoRoll.UpdateAutorollScroll()
end

function AutoRoll.SetAutorollRoll(name, roll)
	if not AutoRoll_Autoroll[name] then return end
	AutoRoll_Autoroll[name].roll = roll
	AutoRoll.RenderAutorollList()
end

function AutoRoll.RollNameShort(roll)
	if roll == AutoRoll.Roll.Need then
		return "N"
	elseif roll == AutoRoll.Roll.Greed then
		return "G"
	elseif roll == AutoRoll.Roll.Pass then
		return "P"
	elseif roll == AutoRoll.Roll.Disenchant then
		return "D"
	end
	return "?"
end

local e = CreateFrame("Frame")
e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("START_LOOT_ROLL")
e:RegisterEvent("CANCEL_LOOT_ROLL")
e:RegisterEvent("CONFIRM_LOOT_ROLL")
e:SetScript("OnEvent", AutoRoll.OnEvent)
AutoRoll.OnLoad(e)