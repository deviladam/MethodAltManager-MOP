local GlobalAddonName, ExRT = ...

local module = ExRT.mod:New("Coins",ExRT.L.Coins)

local VExRT = nil

module.db.spellsCoins = {
	[145923] = ExRT.L.sooitemssooboss1,	-- T16x1
	[145924] = ExRT.L.sooitemssooboss2,	-- T16x2
	[145925] = ExRT.L.sooitemssooboss3,	-- T16x3
	[145926] = ExRT.L.sooitemssooboss4,	-- T16x4
	[145927] = ExRT.L.sooitemssooboss5,	-- T16x5
	[145928] = ExRT.L.sooitemssooboss6,	-- T16x6
	[145929] = ExRT.L.sooitemssooboss7,	-- T16x7
	[145930] = ExRT.L.sooitemssooboss8,	-- T16x8
	[145931] = ExRT.L.sooitemssooboss9,	-- T16x9
	[145932] = ExRT.L.sooitemssooboss12,	-- T16x10
	[145933] = ExRT.L.sooitemssooboss10,	-- T16x11
	[145934] = ExRT.L.sooitemssooboss11,	-- T16x12
	[145935] = ExRT.L.sooitemssooboss13,	-- T16x13
	[145936] = ExRT.L.sooitemssooboss14,	-- T16x14
	
	[139673] = ExRT.L.sooitemstotboss1,	-- T15x1
	[139659] = ExRT.L.sooitemstotboss2,	-- T15x2
	[139661] = ExRT.L.sooitemstotboss3,	-- T15x3
	[139662] = ExRT.L.sooitemstotboss4,	-- T15x4
	[139663] = ExRT.L.sooitemstotboss5,	-- T15x5
	[139664] = ExRT.L.sooitemstotboss6,	-- T15x6
	[139665] = ExRT.L.sooitemstotboss7,	-- T15x7
	[139666] = ExRT.L.sooitemstotboss8,	-- T15x8
	[139667] = ExRT.L.sooitemstotboss9,	-- T15x9
	[139669] = ExRT.L.sooitemstotboss10,	-- T15x10
	[139670] = ExRT.L.sooitemstotboss11,	-- T15x11
	[139671] = ExRT.L.sooitemstotboss12,	-- T15x12
	[139668] = ExRT.L.sooitemstotboss13,	-- T15x13
	
	[125145] = true,	-- T14x1x1
	[132171] = true,	-- T14x1x2
	[132172] = true,	-- T14x1x3
	[132173] = true,	-- T14x1x4
	[132174] = true,	-- T14x1x5
	[132175] = true,	-- T14x1x6

	[132176] = true,	-- T14x2x1
	[132177] = true,	-- T14x2x2
	[132178] = true,	-- T14x2x3
	[132179] = true,	-- T14x2x4
	[132180] = true,	-- T14x2x5
	[132181] = true,	-- T14x2x6
	
	[132182] = true,	-- T14x3x1x1
	[132186] = true,	-- T14x3x1x2
	[132183] = true,	-- T14x3x2
	[132184] = true,	-- T14x3x3
	[132185] = true,	-- T14x3x4
	
	[132188] = true,	-- Galleon
	[132187] = true,	-- Sha of Anger
	[139694] = true,	-- Oondasta
	[139693] = true,	-- Nalak
	[148314] = true,	-- Ordos
	[148320] = true,	-- Celestials (Xuen, Nizuao, Chi-Ji, Yu'lon)
}
module.db.endCoinTimer = nil
module.db.bonusLootChat = LOOT_ITEM_BONUS_ROLL
module.db.bonusLootChatSelf = LOOT_ITEM_BONUS_ROLL_SELF
module.db.classNames = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","MONK","DRUID"}

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.Coins = VExRT.Coins or {}
	VExRT.Coins.list = VExRT.Coins.list or {}
	
	module:RegisterEvents('ENCOUNTER_END','ENCOUNTER_START')
	
	module.db.bonusLootChat = string.match(module.db.bonusLootChat,"([^:]+:)")
	module.db.bonusLootChat = string.gsub(module.db.bonusLootChat,'%%s ','')
	
	if not module.db.bonusLootChat then
		module.db.bonusLootChat = LOOT_ITEM_BONUS_ROLL
	end
	
	module.db.bonusLootChatSelf = string.match(module.db.bonusLootChatSelf,"([^:]+:)")
	if not module.db.bonusLootChatSelf then
		module.db.bonusLootChatSelf = LOOT_ITEM_BONUS_ROLL_SELF
	end
end

function module.main:ENCOUNTER_END(encounterID,encounterName,difficultyID,groupSize,success)
	if success == 1 then
		module:RegisterEvents('UNIT_SPELLCAST_SUCCEEDED','CHAT_MSG_LOOT')
		if module.db.endCoinTimer then
			ExRT.mds.CancelTimer(module.db.endCoinTimer)
			module.db.endCoinTimer = nil
		end
		module.db.endCoinTimer = ExRT.mds.ScheduleTimer(function ()
			module.db.endCoinTimer = nil
			module:UnregisterEvents('UNIT_SPELLCAST_SUCCEEDED','CHAT_MSG_LOOT')
		end,180)
	end
	if encounterID == 1594 then
		module:UnregisterEvents('CHAT_MSG_MONSTER_YELL')
	end	
end

function module.main:CHAT_MSG_LOOT(msg, ...)
	if msg:find(module.db.bonusLootChatSelf) then
		local unitName = UnitName("player")
		local itemID = string.match(msg,"|Hitem:(%d+)")
		local class = select(3,UnitClass("player"))
		if itemID then
			VExRT.Coins.list[#VExRT.Coins.list + 1] = "!"..ExRT.mds.tohex(class or 0,1)..itemID..unitName..time()
			if AltManager then
				AltManager:ResetCoinChance()
			end
		end	
	elseif msg:find(module.db.bonusLootChat) then
		-- saját karakter logoljon
		--
		--local unitName = string.match(msg,"^([^ ]+) ")
		--local itemID = string.match(msg,"|Hitem:(%d+)")
		--local class
		--if unitName and itemID then
		--	if UnitName(unitName) then
		--		class = select(3,UnitClass(unitName))
		--	end
		--	VExRT.Coins.list[#VExRT.Coins.list + 1] = "!"..ExRT.mds.tohex(class or 0,1)..itemID..unitName..time()
		--end
	end	
end

function module.main:ENCOUNTER_START(encounterID,encounterName,difficultyID,groupSize)
	if encounterID == 1594 then
		module:RegisterEvents('CHAT_MSG_MONSTER_YELL')
	end
end

function module.main:CHAT_MSG_MONSTER_YELL(msg, ...)
	if msg:find(ExRT.L.CoinsSpoilsOfPandariaWinTrigger) then
		module.main:ENCOUNTER_END(1594,nil,nil,nil,1)
	end	
end

do
	local module_db_spellsCoins = module.db.spellsCoins
	function module.main:UNIT_SPELLCAST_SUCCEEDED(unitID,_,_,_,spellID)
		if module_db_spellsCoins[spellID] then
			local name = ExRT.mds.UnitCombatlogname(unitID)
			local player = UnitName("player") --csak saját karakter logoljon
			if name == player then
				if ExRT.mds.AntiSpam("Coins"..name,10) then
					local class = select(3,UnitClass(unitID))
					VExRT.Coins.list[#VExRT.Coins.list + 1] = ExRT.mds.tohex(class or 0,1)..spellID..name..time()
					if AltManager then
						AltManager:IncreasCoinChance()
					end
				end
			end
		end
	end
end

function module.options:Load()
	local historyBoxUpdate

	self.clearButton = CreateFrame("Button",self:GetName().."ButtonRemove",self,"UIPanelCloseButton") 
	self.clearButton:SetSize(18,18) 
	self.clearButton:SetPoint("TOPRIGHT",-40,-5) 
	self.clearButton.tooltipText = ExRT.L.CoinsClear
	self.clearButton:SetScript("OnClick", function() 
		StaticPopupDialogs["EXRT_COINS_CLEAR"] = {
			text = ExRT.L.CoinsClearPopUp,
			button1 = ExRT.L.YesText,
			button2 = ExRT.L.NoText,
			OnAccept = function()
				table.wipe(VExRT.Coins.list)
				if module.options.historyBox.ScrollBar:GetValue() == 1 then
					historyBoxUpdate(1)
				else
					module.options.historyBox.ScrollBar:SetValue(1)
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_COINS_CLEAR")
	end) 
	self.clearButton:SetScript("OnEnter",ExRT.lib.OnEnterTooltip)
	self.clearButton:SetScript("OnLeave",ExRT.lib.OnLeaveTooltip)

	local historyBoxUpdateTable = {}
	function historyBoxUpdate(val)
		ExRT.mds.table_wipe(historyBoxUpdateTable)
		module.options:RegisterEvent("GET_ITEM_INFO_RECEIVED")
		if module.options.GET_ITEM_INFO_RECEIVED_cancel then
			ExRT.mds.CancelTimer(module.options.GET_ITEM_INFO_RECEIVED_cancel)
		end
		module.options.GET_ITEM_INFO_RECEIVED_cancel = ExRT.mds.ScheduleTimer(function ()
			module.options.GET_ITEM_INFO_RECEIVED_cancel = nil
			module.options:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		end, 2)
		for i=(#VExRT.Coins.list-val+1),1,-1 do
			local unitClass,spellID,unitName,timestamp = string.match(VExRT.Coins.list[i],"^([^!])(%d+)([^0-9]+)(%d+)")
			if spellID and unitClass and unitName and timestamp then
				local spellName = module.db.spellsCoins[tonumber(spellID) or 0]
				if type(spellName) ~= "string" then
					spellName = GetSpellInfo(spellID)
				end
				local classColor = ExRT.mds.classColor( module.db.classNames[ tonumber(unitClass,16) ] or "?")
				historyBoxUpdateTable [#historyBoxUpdateTable + 1] = date("%d/%m/%y %H:%M:%S ",timestamp).."|c"..classColor..unitName.."|r: "..(spellName or "???")
			else
				unitClass,spellID,unitName,timestamp = string.match(VExRT.Coins.list[i],"^!(.)(%d+)([^0-9]+)(%d+)")
				if spellID and unitClass and unitName and timestamp then
					local spellName = select(2,GetItemInfo(spellID))
					local classColor = ExRT.mds.classColor( module.db.classNames[ tonumber(unitClass,16) ] or "?")
					historyBoxUpdateTable [#historyBoxUpdateTable + 1] = date("%d/%m/%y %H:%M:%S ",timestamp).."|c"..classColor..unitName.."|r: "..(spellName or "???")
				end
			end
			if #historyBoxUpdateTable > 40 then
				break
			end
		end
		if #historyBoxUpdateTable == 0 then
			module.options.historyBox.EditBox:SetText(ExRT.L.CoinsEmpty)
		else
			module.options.historyBox.EditBox:SetText(strjoin("\n",unpack(historyBoxUpdateTable)))
		end
	end
	
	self:SetScript("OnEvent",function ()
		if not self.GET_ITEM_INFO_RECEIVED then
			self.GET_ITEM_INFO_RECEIVED = ExRT.mds.ScheduleTimer(function() 
				self.GET_ITEM_INFO_RECEIVED = nil
				historyBoxUpdate( ExRT.mds.Round( module.options.historyBox.ScrollBar:GetValue() ) ) 
			end, 0.1)
		end
	end)
	
	local function historyBoxShow(self)
		module.options.historyBox.ScrollBar:SetMinMaxValues(1,max(#VExRT.Coins.list - 30,1))
		if module.options.historyBox.ScrollBar:GetValue() == 1 then
			historyBoxUpdate(1)
		else
			module.options.historyBox.ScrollBar:SetValue(1)
		end
	end

	self.historyBox = ExRT.lib.CreateMultiEditBox2(self:GetName().."HistoryBox",self,595,525,"TOP",0,-30)
	self.historyBox.EditBox:SetScript("OnShow",historyBoxShow)
	self.historyBox.ScrollBar:SetScript("OnValueChanged",function (self,val)
		val = ExRT.mds.Round(val)
		historyBoxUpdate(val)
	end)
	self.historyBox.EditBox:SetHyperlinksEnabled(true)
	self.historyBox.EditBox:SetScript("OnHyperlinkEnter",ExRT.lib.EditBoxOnEnterHyperLinkTooltip)
	self.historyBox.EditBox:SetScript("OnHyperlinkLeave",ExRT.lib.EditBoxOnLeaveHyperLinkTooltip)
	
	historyBoxShow()
	
	self.HelpPlate = {
		FramePos = { x = 0, y = 0 },FrameSize = { width = 623, height = 568 },
		[1] = { ButtonPos = { x = 260,	y = -35 },  	HighLightBox = { x = 5, y = -15, width = 613, height = 544 },		ToolTipDir = "DOWN",	ToolTipText = ExRT.L.CoinsHelp },		
	}
	self.HELPButton = ExRT.lib.CreateHelpButton(self,self.HelpPlate)	
end