
local _, AltManager = ...;

_G["AltManager"] = AltManager;

-- Made by: Qooning - Tarren Mill <Method>, 2017-2019
-- updates for Bfa by: Kabootzey - Tarren Mill <Ended Careers>, 2018
-- reworked for Mop (SoO): Darkpaladino - Ragnaros, 2019

local Dialog = LibStub("LibDialog-1.0")

local sizey = 280; 				-- +20 for one more row
local instances_y_add = 25; 	-- +20 for one more row
local xoffset = 0;
local yoffset = 150;
local alpha = 1;
local addon = "MethodAltManager";
local numel = table.getn;

local per_alt_x = 120;
local ilvl_text_size = 8;
local remove_button_size = 12;

local min_x_size = 300;

local min_level = 90;
local name_label = "" -- Name
--bonusroll
local lesser_charm_label = "Lesser Charm"
local elder_charm_label = "Elder Charm"
local mogu_rune_label = "Mogu Rune"
local seals_owned_label = "Warforged Seal"
local seals_bought_label = "Wf Seals quest"
local coin_chance_label = "BonusRoll chance"

local valor_label = "Valor"
local valor_weekly_label = "Valor Cap"
local conquest_label = "Conquest"
local conquest_weekly_label = "Conquest Cap"

local worldboss_label = "Worldboss"

local VERSION = "0.5.0"

local dungeons = {
	-- BFA
	[244] = "AD",
	[245] = "FH",
	[246] = "TD",
	[247] = "ML",
	[248] = "WCM",
	[249] = "KR",
	[250] = "Seth",
	[251] = "UR",
	[252] = "SotS",
	[353] = "SoB"
 };


SLASH_METHODALTMANAGER1 = "/mam";
SLASH_METHODALTMANAGER2 = "/alts";

local function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function true_numel(t)
	local c = 0
	for k, v in pairs(t) do c = c + 1 end
	return c
end

function SlashCmdList.METHODALTMANAGER(cmd, editbox)
	local rqst, arg = strsplit(' ', cmd)
	if rqst == "help" then
		print("Method Alt Manager help:")
		print("   \"/alts purge\" to remove all stored data.")
		print("   \"/alts remove name\" to remove characters by name.")
	elseif rqst == "purge" then
		AltManager:Purge();
	elseif rqst == "remove" then
		AltManager:RemoveCharactersByName(arg)
	else
		AltManager:ShowInterface();
	end
end

function list_items()
	a = {}
	for i = 1,200000 do
		local n = GetItemInfo(i)
		if n ~= nil  then
			print(n)
			table.insert(a, n)
		end
	end
end

do
	local main_frame = CreateFrame("frame", "AltManagerFrame", UIParent);
	AltManager.main_frame = main_frame;
	main_frame:SetFrameStrata("MEDIUM");
	main_frame.background = main_frame:CreateTexture(nil, "BACKGROUND");
	main_frame.background:SetAllPoints();
	main_frame.background:SetDrawLayer("ARTWORK", 1);
	main_frame.background:SetTexture(0,0,0,.7);
	
	main_frame.scan_tooltip = CreateFrame('GameTooltip', 'DepletedTooltipScan', UIParent, 'GameTooltipTemplate');
	

	-- Set frame position
	main_frame:ClearAllPoints();
	main_frame:SetPoint("CENTER", UIParent, "CENTER", xoffset, yoffset);
	
	main_frame:RegisterEvent("ADDON_LOADED");
	main_frame:RegisterEvent("PLAYER_LOGIN");
	main_frame:RegisterEvent("PLAYER_LOGOUT");
	main_frame:RegisterEvent("QUEST_TURNED_IN");
	main_frame:RegisterEvent("BAG_UPDATE_DELAYED");
	main_frame:RegisterEvent("CHAT_MSG_CURRENCY");
	main_frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE");
  	main_frame:RegisterEvent("PLAYER_LEAVING_WORLD");
	

	main_frame:SetScript("OnEvent", function(self, ...)
		local event, loaded = ...;
		if event == "ADDON_LOADED" then
			if addon == loaded then
      			AltManager:OnLoad();
			end
		end
		if event == "PLAYER_LOGIN" then
        	AltManager:OnLogin();
		end
		if event == "PLAYER_LEAVING_WORLD" or event == "ARTIFACT_XP_UPDATE" then
			local data = AltManager:CollectData(false);
			AltManager:StoreData(data);
		end
		if (event == "BAG_UPDATE_DELAYED" or event == "QUEST_TURNED_IN" or event == "CHAT_MSG_CURRENCY" or event == "CURRENCY_DISPLAY_UPDATE") and AltManager.addon_loaded then
			local data = AltManager:CollectData(false);
			AltManager:StoreData(data);
		end
		
	end)
	
	-- Show Frame
	main_frame:Hide();
end

--DB tábla inicializálása (alts, data)
function AltManager:InitDB()
	local t = {};
	t.alts = 0;
	t.data = {};
	return t;
end

function AltManager:CalculateXSizeNoGuidCheck()
	local alts = MethodAltManagerDB.alts;
	return max((alts + 1) * per_alt_x, min_x_size)
end

function AltManager:CalculateXSize()
	-- local alts = MethodAltManagerDB.alts;
	-- -- HACK: DUE TO THE LOGIN DATA GLITCH, I HAVE TO CHECK IF CURRENT ALT IS NEW
	-- local guid = UnitGUID('player');
	-- if MethodAltManagerDB.data[guid] == nil then alts = alts + 1 end
	-- return max((alts + 1) * per_alt_x, min_x_size)
	return self:CalculateXSizeNoGuidCheck()
end

-- because of guid...
function AltManager:OnLogin()
	self:ValidateReset();
	self:StoreData(self:CollectData());
  
	self.main_frame:SetSize(self:CalculateXSize(), sizey);
	self.main_frame.background:SetAllPoints();
	
	-- Create menus
	AltManager:CreateContent();
	AltManager:MakeTopBottomTextures(self.main_frame);
	AltManager:MakeBorder(self.main_frame, 5);
end


--ADDON_LOADED event unregister
--DB inicializálása, ha nincsen még
--vmi ellenőrzés
function AltManager:OnLoad()
	self.main_frame:UnregisterEvent("ADDON_LOADED");
	
	MethodAltManagerDB = MethodAltManagerDB or self:InitDB();

	if MethodAltManagerDB.alts ~= true_numel(MethodAltManagerDB.data) then
		print("Altcount inconsistent, using", true_numel(MethodAltManagerDB.data))
		MethodAltManagerDB.alts = true_numel(MethodAltManagerDB.data)
	end

	self.addon_loaded = true
end

function AltManager:CreateFontFrame(parent, x_size, height, relative_to, y_offset, label, justify)
	local f = CreateFrame("Button", nil, parent);
	f:SetSize(x_size, height);
	f:SetNormalFontObject(GameFontHighlightSmall)
	f:SetText(label)
	f:SetPoint("TOPLEFT", relative_to, "TOPLEFT", 0, y_offset);
	f:GetFontString():SetJustifyH(justify);
	f:GetFontString():SetJustifyV("CENTER");
	f:SetPushedTextOffset(0, 0);
	f:GetFontString():SetWidth(120)
	f:GetFontString():SetHeight(20)
	
	return f;
end

function AltManager:Keyset()
	local keyset = {}
	if MethodAltManagerDB and MethodAltManagerDB.data then
		for k in pairs(MethodAltManagerDB.data) do
			table.insert(keyset, k)
		end
	end
	return keyset
end

--Reset utáni adatok törlése
function AltManager:ValidateReset()
	local db = MethodAltManagerDB
	if not db then return end;
	if not db.data then return end;
	
	local keyset = {}
	for k in pairs(db.data) do
		table.insert(keyset, k)
	end
	
	for alt = 1, db.alts do
		local expiry = db.data[keyset[alt]].expires or 0;
		local char_table = db.data[keyset[alt]];
		if time() > expiry then
			-- reset this alt
			char_table.seals_bought = 0;
			char_table.expires = self:GetNextWeeklyResetTime();
			char_table.worldboss = "-";
			
			char_table.conquest_earned_this_week = 0;
			char_table.valor_earned_this_week = 0;
			char_table.soo_felx = 0;
			char_table.soo_normal = 0;
			char_table.soo_heroic = 0;
			



		end
	end
end

function AltManager:Purge()
	MethodAltManagerDB = self:InitDB();
end

function AltManager:RemoveCharactersByName(name)
	local db = MethodAltManagerDB;

	local indices = {};
	for guid, data in pairs(db.data) do
		if db.data[guid].name == name then
			indices[#indices+1] = guid
		end
	end

	db.alts = db.alts - #indices;
	for i = 1,#indices do
		db.data[indices[i]] = nil
	end

	print("Found " .. (#indices) .. " characters by the name of " .. name)
	print("Please reload ui to update the displayed info.")

	-- things wont be redrawn
end

function AltManager:RemoveCharacterByGuid(index)
	local db = MethodAltManagerDB;

	if db.data[index] == nil then return end

	local name = db.data[index].name
	Dialog:Register("AltManagerRemoveCharacterDialog", {
		text = "Are you sure you want to remove " .. name .. " from the list?",
		width = 500,
		on_show = function(self, data) 
		end,
		buttons = {
			{ text = "Delete", 
			  on_click = function()
					if db.data[index] == nil then return end
					db.alts = db.alts - 1;
					db.data[index] = nil
					-- print("Deleting character guid", index)
					self.main_frame:SetSize(self:CalculateXSizeNoGuidCheck(), sizey);
					if self.main_frame.alt_columns ~= nil then
						-- Hide the last col
						-- find the correct frame to hide
						local count = #self.main_frame.alt_columns
						for j = 0,count-1 do
							if self.main_frame.alt_columns[count-j]:IsShown() then
								self.main_frame.alt_columns[count-j]:Hide()
								-- also for instances
								if self.instances_unroll ~= nil and self.instances_unroll.alt_columns ~= nil and self.instances_unroll.alt_columns[count-j] ~= nil then
									self.instances_unroll.alt_columns[count-j]:Hide()
								end
								break
							end
						end
						
						-- and hide the remove button
						if self.main_frame.remove_buttons ~= nil and self.main_frame.remove_buttons[index] ~= nil then
							self.main_frame.remove_buttons[index]:Hide()
						end
					end
					self:UpdateStrings()
					-- it's not simple to update the instances text with current design, so hide it and let the click do update
					if self.instances_unroll ~= nil and self.instances_unroll.state == "open" then
						self:CloseInstancesUnroll()
						self.instances_unroll.state = "closed";
					end
				end},
			{ text = "Cancel", }
		},	
		show_while_dead = true,
		hide_on_escape = true,
	})
	if Dialog:ActiveDialog("AltManagerRemoveCharacterDialog") then
		Dialog:Dismiss("AltManagerRemoveCharacterDialog")
	end
	Dialog:Spawn("AltManagerRemoveCharacterDialog", {string = string})

end

local get_current_questline_quest = QuestUtils_GetCurrentQuestLineQuest

-- function QuestUtils_GetCurrentQuestLineQuest(questLineID)
-- 	local quests = C_QuestLine.GetQuestLineQuests(questLineID);
-- 	local currentQuestID = 0;
-- 	for i, questID in ipairs(quests) do
-- 		if C_QuestLog.IsOnQuest(questID) then
-- 			currentQuestID = questID;
-- 			break;
-- 		end
-- 	end
-- 	return currentQuestID;
-- end

function getConquestCap()
    --local CONQUEST_QUESTLINE_ID = 782;
    --local currentQuestID = get_current_questline_quest(CONQUEST_QUESTLINE_ID);

    -- if not on a current quest that means all caught up for this week
    --if currentQuestID == 0 then
    --    return 0, 0, 0;
    --end

    --if not HaveQuestData(currentQuestID) then
    --    return 0, 0, nil;
    --end

    --local objectives = C_QuestLog.GetQuestObjectives(currentQuestID);
    --if not objectives or not objectives[1] then
    --    return 0, 0, nil;
    --end

    --return objectives[1].numFulfilled, objectives[1].numRequired, currentQuestID;
	--TODO
	return 2872;
end

function AltManager:StoreData(data)

	if not self.addon_loaded then
		return
	end

	-- This can happen shortly after logging in, the game doesn't know the characters guid yet
	if not data or not data.guid then
		return
	end
	
	if UnitLevel('player') < min_level then return end;
	
	local db = MethodAltManagerDB;
	local guid = data.guid;
	
	db.data = db.data or {};
	
	local update = false;
	for k, v in pairs(db.data) do
		if k == guid then
			update = true;
		end
	end

	if not update then
		db.data[guid] = data;
		db.data[guid].coin_chance = 1;
		db.alts = db.alts + 1;
	else
		db.data[guid] = data;
	end
end


--Visszaadja a karakter táblát
function AltManager:CollectData(do_artifact)
	
	if UnitLevel('player') < min_level then return end;
	-- this is an awful hack that will probably have some unforeseen consequences,
	-- but Blizzard fucked something up with systems on logout, so let's see how it
	-- goes.
	_, i = GetAverageItemLevel()
	if i == 0 then return end;

	-- fix this when i'm not on a laptop at work
	do_artifact = false
	
	local name = UnitName('player')
	local _, class = UnitClass('player')
	local expire = nil;
	local seals = nil;
	local seals_bought = nil;
	
	local coin_chance = nil;
	
	local guid = UnitGUID('player');

	local mine_old = nil
	if MethodAltManagerDB and MethodAltManagerDB.data then
		mine_old = MethodAltManagerDB.data[guid];
	end
	if mine_old then
		coin_chance = mine_old.coin_chance;
	end
	
	-- find keystone (No keystone in Mop)
	--[[
	local keystone_found = false;
	for container=BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(container)
		for slot=1, slots do
			local _, _, _, _, _, _, slotLink, _, _, slotItemID = GetContainerItemInfo(container, slot)
			--if slotItemID then print(slotItemID, GetItemInfo(slotItemID)) end
			
			if slotItemID == 158923 then
				local itemString = slotLink:match("|Hkeystone:([0-9:]+)|h(%b[])|h")
				local info = { strsplit(":", itemString) }
        -- print(info[0], info[1], info[2], info[3], info[4])
				-- scan tooltip for depleted
				self.main_frame.scan_tooltip:SetOwner(UIParent, 'ANCHOR_NONE');
				self.main_frame.scan_tooltip:SetBagItem(container, slot);
				local regions = self.main_frame.scan_tooltip:GetRegions();
				self.main_frame.scan_tooltip:Hide();
				--local mapname = C_ChallengeMode.GetMapInfo(info[1]);
				dungeon = tonumber(info[2])
				if not dungeon then print("MethodAltManager - Parse Failure, please let Qoning know that this happened."); end
				level = tonumber(info[3])
				if not level then print("MethodAltManager - Parse Failure, please let Qoning know that this happened."); end
				expire = tonumber(info[4])
				keystone_found = true;
			end
		end
	end
	if not keystone_found then
		dungeon = "Unknown";
		level = "?"
	end]]--
	
	if do_artifact and HasArtifactEquipped() then
		if not ArtifactFrame then
			LoadAddOn("Blizzard_ArtifactUI");
		end
		-- open artifact
		local is_open = ArtifactFrame:IsShown();
		if (not ArtifactFrame or not ArtifactFrame:IsShown()) then
			SocketInventoryItem(INVSLOT_MAINHAND);
		end
		-- close artifact
		if not is_open and ArtifactFrame and ArtifactFrame:IsShown() and C_ArtifactUI.IsViewedArtifactEquipped() then
			C_ArtifactUI.Clear();
		end
	end

	local creation_time = nil
	local duration = nil
	local num_ready = nil
	local num_total = nil
	local found_research = false
	
	if found_research and num_ready == 0 then
		local remaining = (creation_time + duration) - time();
			if (remaining < 0) then		-- next shipment is ready
			num_ready = num_ready + 1
			if num_ready > num_total then	-- prevent overflow
				num_ready = num_total
			end
			remaining = 0
		end
		next_research = creation_time + duration
	else
		next_research = 0;
	end
	
	local _, lesser_charm = GetCurrencyInfo(738);
	local _, elder_charm = GetCurrencyInfo(697);
	local _, mogu_rune = GetCurrencyInfo(752);
	_, seals = GetCurrencyInfo(776);
	seals_bought = 0
	
	local bonusRoll = IsQuestFlaggedCompleted(33133)
	if bonusRoll then seals_bought = seals_bought + 3 end
	
	local soo_lfr, soo_flex, soo_normal, soo_heroic = 0;

	local saves = GetNumSavedInstances();
	for i = 1, saves do
		local name, _, reset, difficultyID, locked, extended, _, _, _, difficulty, bosses, killed_bosses = GetSavedInstanceInfo(i);

		-- check for raids
		if name == "Siege of Orgrimmar" and locked and not extended then
			if string.find(difficulty, "Flexible") then soo_flex = killed_bosses end
			if difficulty == "10 Player" or difficulty == "25 Player"  then soo_normal = killed_bosses end
			if string.find(difficulty, "Heroic")  then soo_heroic = killed_bosses end

		end
	end
	
	
	local worldbossquests = {
		[52181] = "T'zane", 
		[52169] = "Dunegorger Kraulok",
		[52166] = "Warbringer Yenajz",
		[52163] = "Azurethos",
		[52157] = "Hailstone Construct",
		[52196]  = "Ji'arak"
	}
	local worldboss = "-"
	for k,v in pairs(worldbossquests)do
		if IsQuestFlaggedCompleted(k) then
			
			worldboss = v 
		end
	end
	
	local conquest = getConquestCap()
	--DELETE
	
	local _, ilevel = GetAverageItemLevel();

	local _, valor, _, valor_earned_this_week = GetCurrencyInfo(396);
	local _, conquest, _, conquest_earned_this_week, conquest_weekly_max  = GetCurrencyInfo(390);


	-- store data into a table

	local char_table = {}
	
	char_table.guid = UnitGUID('player');
	char_table.name = name;
	char_table.class = class;
	char_table.ilevel = ilevel;
	
	char_table.lesser_charm = lesser_charm
	char_table.elder_charm = elder_charm;
	char_table.mogu_rune = mogu_rune;
	char_table.seals = seals;
	char_table.seals_bought = seals_bought;
	
	char_table.valor = valor;
	char_table.valor_earned_this_week = valor_earned_this_week;
	
	char_table.conquest = conquest;
	char_table.conquest_earned_this_week = conquest_earned_this_week;
	char_table.conquest_weekly_max = conquest_weekly_max;
	
	char_table.dungeon = dungeon;
	char_table.worldboss = worldboss;
	char_table.coin_chance = coin_chance;

	--Raid Siege of Orgrimmar
	char_table.soo_flex = soo_flex;
	char_table.soo_normal = soo_normal;
	char_table.soo_heroic = soo_heroic;


	char_table.expires = self:GetNextWeeklyResetTime();
	
	
	return char_table;
end

-- /script AltManager:IncreasCoinChance()
function AltManager:IncreasCoinChance()
	print("CoinInc")
	if UnitLevel('player') < min_level and not self.addon_loaded  then return end;
	
	local db = MethodAltManagerDB;
	local guid = UnitGUID('player');
	
	db.data = db.data or {};

	db.data[guid].coin_chance =  db.data[guid].coin_chance + 1;
end

function AltManager:ResetCoinChance()
	print("CoinDec")
	if UnitLevel('player') < min_level and not self.addon_loaded  then return end;
	
	local db = MethodAltManagerDB;
	local guid = UnitGUID('player');
	
	db.data = db.data or {};

	db.data[guid].coin_chance =  1;
end

function AltManager:UpdateStrings()
	local font_height = 20;
	local db = MethodAltManagerDB;
	
	local keyset = {}
	for k in pairs(db.data) do
		table.insert(keyset, k)
	end
	
	self.main_frame.alt_columns = self.main_frame.alt_columns or {};
	
	local alt = 0
	for alt_guid, alt_data in spairs(db.data, function(t, a, b) return t[a].ilevel > t[b].ilevel end) do
		alt = alt + 1
		-- create the frame to which all the fontstrings anchor
		local anchor_frame = self.main_frame.alt_columns[alt] or CreateFrame("Button", nil, self.main_frame);
		if not self.main_frame.alt_columns[alt] then
			self.main_frame.alt_columns[alt] = anchor_frame;
			self.main_frame.alt_columns[alt].guid = alt_guid
			anchor_frame:SetPoint("TOPLEFT", self.main_frame, "TOPLEFT", per_alt_x * alt, -1);
		end
		anchor_frame:SetSize(per_alt_x, sizey);
		-- init table for fontstring storage
		self.main_frame.alt_columns[alt].label_columns = self.main_frame.alt_columns[alt].label_columns or {};
		local label_columns = self.main_frame.alt_columns[alt].label_columns;
		-- create / fill fontstrings
		local i = 1;
		for column_iden, column in spairs(self.columns_table, function(t, a, b) return t[a].order < t[b].order end) do
			-- only display data with values
			if type(column.data) == "function" then
				local current_row = label_columns[i] or self:CreateFontFrame(anchor_frame, per_alt_x, column.font_height or font_height, anchor_frame, -(i - 1) * font_height, column.data(alt_data), "CENTER");
				-- insert it into storage if just created
				if not self.main_frame.alt_columns[alt].label_columns[i] then
					self.main_frame.alt_columns[alt].label_columns[i] = current_row;
				end
				if column.color then
					local color = column.color(alt_data)
					current_row:GetFontString():SetTextColor(color.r, color.g, color.b, 1);
				end
				current_row:SetText(column.data(alt_data))
				if column.font then
					current_row:GetFontString():SetFont(column.font, ilvl_text_size)
				else
					--current_row:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 14)
				end
				if column.justify then
					current_row:GetFontString():SetJustifyV(column.justify);
				end
				if column.remove_button ~= nil then
					self.main_frame.remove_buttons = self.main_frame.remove_buttons or {}
					local extra = self.main_frame.remove_buttons[alt_data.guid] or column.remove_button(alt_data)
					if self.main_frame.remove_buttons[alt_data.guid] == nil then 
						self.main_frame.remove_buttons[alt_data.guid] = extra
					end
					extra:SetParent(current_row)
					extra:SetPoint("TOPRIGHT", current_row, "TOPRIGHT", -18, 2 );
					extra:SetPoint("BOTTOMRIGHT", current_row, "TOPRIGHT", -18, -remove_button_size + 2);
					extra:SetFrameLevel(current_row:GetFrameLevel() + 1)
					extra:Show();
				end
			end
			i = i + 1
		end
		
	end
	
end

function AltManager:UpdateInstanceStrings(my_rows, font_height)
	self.instances_unroll.alt_columns = self.instances_unroll.alt_columns or {};
	local alt = 0
	local db = MethodAltManagerDB;
	for alt_guid, alt_data in spairs(db.data, function(t, a, b) return t[a].ilevel > t[b].ilevel end) do
		alt = alt + 1
		-- create the frame to which all the fontstrings anchor
		local anchor_frame = self.instances_unroll.alt_columns[alt] or CreateFrame("Button", nil, self.main_frame.alt_columns[alt]);
		if not self.instances_unroll.alt_columns[alt] then
			self.instances_unroll.alt_columns[alt] = anchor_frame;
		end
		anchor_frame:SetPoint("TOPLEFT", self.instances_unroll.unroll_frame, "TOPLEFT", per_alt_x * alt, -1);
		anchor_frame:SetSize(per_alt_x, instances_y_add);
		-- init table for fontstring storage
		self.instances_unroll.alt_columns[alt].label_columns = self.instances_unroll.alt_columns[alt].label_columns or {};
		local label_columns = self.instances_unroll.alt_columns[alt].label_columns;
		-- create / fill fontstrings
		local i = 1;
		for column_iden, column in spairs(my_rows, function(t, a, b) return t[a].order < t[b].order end) do
			local current_row = label_columns[i] or self:CreateFontFrame(anchor_frame, per_alt_x, column.font_height or font_height, anchor_frame, -(i - 1) * font_height, column.data(alt_data), "CENTER");
			-- insert it into storage if just created
			if not self.instances_unroll.alt_columns[alt].label_columns[i] then
				self.instances_unroll.alt_columns[alt].label_columns[i] = current_row;
			end
			current_row:SetText(column.data(alt_data)) -- fills data
			i = i + 1
		end
		-- hotfix visibility
		if anchor_frame:GetParent():IsShown() then anchor_frame:Show() else anchor_frame:Hide() end
	end
end

function AltManager:OpenInstancesUnroll(my_rows, button) 
	-- do unroll
	self.instances_unroll.unroll_frame = self.instances_unroll.unroll_frame or CreateFrame("Button", nil, self.main_frame);
	self.instances_unroll.unroll_frame:SetSize(per_alt_x, instances_y_add);
	self.instances_unroll.unroll_frame:SetPoint("TOPLEFT", self.main_frame, "TOPLEFT", 4, self.main_frame.lowest_point - 10);
	self.instances_unroll.unroll_frame:Show();

	local font_height = 20;
	-- create the rows for the unroll
	if not self.instances_unroll.labels then
		self.instances_unroll.labels = {};
		local i = 1
		for row_iden, row in spairs(my_rows, function(t, a, b) return t[a].order < t[b].order end) do
			if row.label then
				local label_row = self:CreateFontFrame(self.instances_unroll.unroll_frame, per_alt_x, font_height, self.instances_unroll.unroll_frame, -(i-1)*font_height, row.label..":", "RIGHT");
				table.insert(self.instances_unroll.labels, label_row)
			end
			i = i + 1
		end
	end

	-- populate it for alts
	self:UpdateInstanceStrings(my_rows, font_height)

	-- fixup the background
	self.main_frame:SetSize(self:CalculateXSizeNoGuidCheck(), sizey + instances_y_add);
	self.main_frame.background:SetAllPoints();

end

function AltManager:CloseInstancesUnroll()
	-- do rollup
	self.main_frame:SetSize(self:CalculateXSizeNoGuidCheck(), sizey);
	self.main_frame.background:SetAllPoints();
	self.instances_unroll.unroll_frame:Hide();
	for k, v in pairs(self.instances_unroll.alt_columns) do
		v:Hide()
	end
end

function AltManager:CreateContent()

	-- Close button
	self.main_frame.closeButton = CreateFrame("Button", "CloseButton", self.main_frame, "UIPanelCloseButton");
	self.main_frame.closeButton:ClearAllPoints()
	self.main_frame.closeButton:SetPoint("BOTTOMRIGHT", self.main_frame, "TOPRIGHT", -10, -2);
	self.main_frame.closeButton:SetScript("OnClick", function() AltManager:HideInterface(); end);
	--self.main_frame.closeButton:SetSize(32, h);

	local column_table = {
		name = {
			order = 1,
			label = name_label,
			data = function(alt_data) return alt_data.name end,
			color = function(alt_data) return RAID_CLASS_COLORS[alt_data.class] end,
		},
		ilevel = {
			order = 2,
			data = function(alt_data) return string.format("%.2f", alt_data.ilevel or 0) end,
			justify = "TOP",
			font = "Fonts\\FRIZQT__.TTF",
			remove_button = function(alt_data) return self:CreateRemoveButton(function() AltManager:RemoveCharacterByGuid(alt_data.guid) end) end
		},
		valor = {
			order = 3,
			label = valor_label,
			data = function(alt_data) return alt_data.valor and tostring(alt_data.valor) or "0" end,
		},
		valor_cap = {
			order = 4,
			label = valor_weekly_label,
			data = function(alt_data) return ((alt_data.valor_earned_this_week == 1000) and "Capped") or ((alt_data.valor_earned_this_week and tostring(alt_data.valor_earned_this_week)) or "?") .. "/1000"  end,
		},
		lesser_charm = {
			order = 5,
			label = lesser_charm_label,
			data = function(alt_data) return alt_data.lesser_charm and tostring(alt_data.lesser_charm) or "0" end,
		},
		elder_charm = {
			order = 6,
			label = elder_charm_label,
			data = function(alt_data) return alt_data.elder_charm and tostring(alt_data.elder_charm) or "0" end,
		},
		mogu_rune = {
			order = 7,
			label = mogu_rune_label,
			data = function(alt_data) return tostring(alt_data.mogu_rune) end, 
		},
		seals_bought = {
			order = 8,
			label = seals_bought_label,
			data = function(alt_data) 
						if (alt_data.seals_bought > 0) then
							return "Done";
						else
							return "Available";
						end
				   end,
		},
		seals_owned = {
			order = 9,
			label = seals_owned_label,
			data = function(alt_data) return tostring(alt_data.seals) .. "/10" end,
		},
		
		--CONQUEST
		--[[conquest = {
			order = 10,
			label = conquest_label,
			data = function(alt_data) return tostring(alt_data.conquest); end,
		},
		conquest_cap = {
			order = 11,
			label = conquest_weekly_label,
			data = function(alt_data) return (alt_data.conquest_earned_this_week and tostring(alt_data.conquest_earned_this_week) or "?")  .. "/" .. (alt_data.conquest_weekly_max and tostring(alt_data.conquest_weekly_max) or "?")  end,
		},]]--

		-- sort of became irrelevant for now
		-- worldbosses = {
		-- 	order = 10,
		-- 	label = worldboss_label,
		-- 	data = function(alt_data) return alt_data.worldboss or "?" end,
		-- },
		coin_chance= {
			order = 12,
			label = coin_chance_label,
			data = function(alt_data) 
				local zoneName = GetZoneText();
				local chance = 32;
				if zoneName == "Timeless Isle" or zoneName == "Siege of Orgrimmar" then
					chance = 16;
				end
				return tostring(alt_data.coin_chance * chance) .. "%" .. "("..tostring(alt_data.coin_chance-1) ..")";

			end,
		},
		dummy_line = {
			order = 13,
			label = " ",
			data = function(alt_data) return " " end,
		},
		raid_unroll = {
			order = 14,
			data = "unroll",
			name = "Instances >>",
			unroll_function = function(button, my_rows)
				self.instances_unroll = self.instances_unroll or {};
				self.instances_unroll.state = self.instances_unroll.state or "closed";
				if self.instances_unroll.state == "closed" then
					self:OpenInstancesUnroll(my_rows)
					-- update ui
					button:SetText("Instances <<");
					self.instances_unroll.state = "open";
				else
					self:CloseInstancesUnroll()
					-- update ui
					button:SetText("Instances >>");
					self.instances_unroll.state = "closed";
				end
			end,
			rows = {
				soo = {
					order = 1,
					label = "Siege of Orgrimmar",
					data = function(alt_data) return self:MakeRaidString(alt_data.soo_flex, alt_data.soo_normal, alt_data.soo_heroic) end
				}
			}
		}
	}
	self.columns_table = column_table;

	-- create labels and unrolls
	local font_height = 20;
	local label_column = self.main_frame.label_column or CreateFrame("Button", nil, self.main_frame);
	if not self.main_frame.label_column then self.main_frame.label_column = label_column; end
	label_column:SetSize(per_alt_x, sizey);
	label_column:SetPoint("TOPLEFT", self.main_frame, "TOPLEFT", 4, -1);

	local i = 1;
	for row_iden, row in spairs(self.columns_table, function(t, a, b) return t[a].order < t[b].order end) do
		if row.label then
			local label_row = self:CreateFontFrame(self.main_frame, per_alt_x, font_height, label_column, -(i-1)*font_height, row.label~="" and row.label..":" or " ", "RIGHT");
			self.main_frame.lowest_point = -(i-1)*font_height;
		end
		if row.data == "unroll" then
			-- create a button that will unroll it
			local unroll_button = CreateFrame("Button", "UnrollButton", self.main_frame, "UIPanelButtonTemplate");
			unroll_button:SetText(row.name);
			--unroll_button:SetFrameStrata("HIGH");
			unroll_button:SetFrameLevel(self.main_frame:GetFrameLevel() + 2)
			unroll_button:SetSize(unroll_button:GetTextWidth() + 20, 25);
			unroll_button:SetPoint("BOTTOMRIGHT", self.main_frame, "TOPLEFT", 4 + per_alt_x, -(i-1)*font_height-10);
			unroll_button:SetScript("OnClick", function() row.unroll_function(unroll_button, row.rows) end);
			self.main_frame.lowest_point = -(i-1)*font_height-10;
		end
		i = i + 1
	end

end

function AltManager:MakeRaidString(flexible, normal, heroic)
	if not flexible then flexible = 0 end
	if not normal then normal = 0 end
	if not heroic then heroic = 0 end
	

	local string = ""
	if heroic > 0 then string = string .. tostring(heroic) .. "H" end
	if normal > 0 and heroic > 0 then string = string .. "-" end
	if normal > 0 then string = string .. tostring(normal) .. "N" end
	if flexible > 0 and (heroic > 0 or normal > 0) then string = string .. "-" end
	if flexible > 0 then string = string .. tostring(flexible) .. "F" end
	return string == "" and "-" or string
end

function AltManager:HideInterface()
	self.main_frame:Hide();
end

function AltManager:ShowInterface()
	self.main_frame:Show();
	self:StoreData(self:CollectData())
	self:UpdateStrings();
end

function AltManager:CreateRemoveButton(func)
	local frame = CreateFrame("Button", nil, nil)
	frame:ClearAllPoints()
	frame:SetScript("OnClick", function() func() end);
	self:MakeRemoveTexture(frame)
	frame:SetWidth(remove_button_size)
	return frame
end

function AltManager:MakeRemoveTexture(frame)
	if frame.remove_tex == nil then
		frame.remove_tex = frame:CreateTexture(nil, "BACKGROUND")
		frame.remove_tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		frame.remove_tex:SetAllPoints()
		frame.remove_tex:Show();
	end
	return frame
end

function AltManager:MakeTopBottomTextures(frame)
	if frame.bottomPanel == nil then
		frame.bottomPanel = frame:CreateTexture(nil);
	end
	if frame.topPanel == nil then
		frame.topPanel = CreateFrame("Frame", "AltManagerTopPanel", frame);
		frame.topPanelTex = frame.topPanel:CreateTexture(nil, "BACKGROUND");
		--frame.topPanelTex:ClearAllPoints();
		frame.topPanelTex:SetAllPoints();
		--frame.topPanelTex:SetSize(frame:GetWidth(), 30);
		frame.topPanelTex:SetDrawLayer("ARTWORK", -5);
		frame.topPanelTex:SetTexture(0,0,0,.8);
		
		frame.topPanelString = frame.topPanel:CreateFontString("Method name");
		frame.topPanelString:SetFont("Fonts\\FRIZQT__.TTF", 20)
		frame.topPanelString:SetTextColor(1, 1, 1, 1);
		frame.topPanelString:SetJustifyH("CENTER")
		frame.topPanelString:SetJustifyV("CENTER")
		frame.topPanelString:SetWidth(260)
		frame.topPanelString:SetHeight(20)
		frame.topPanelString:SetText("Insane Alt Manager");
		frame.topPanelString:ClearAllPoints();
		frame.topPanelString:SetPoint("CENTER", frame.topPanel, "CENTER", 0, 0);
		frame.topPanelString:Show();
		
	end
	frame.bottomPanel:SetTexture(0,0,0,.8);
	frame.bottomPanel:ClearAllPoints();
	frame.bottomPanel:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0);
	frame.bottomPanel:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0);
	frame.bottomPanel:SetSize(frame:GetWidth(), 30);
	frame.bottomPanel:SetDrawLayer("ARTWORK", 7);

	frame.topPanel:ClearAllPoints();
	frame.topPanel:SetSize(frame:GetWidth(), 30);
	frame.topPanel:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0);
	frame.topPanel:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0);

	frame:SetMovable(true);
	frame.topPanel:EnableMouse(true);
	frame.topPanel:RegisterForDrag("LeftButton");
	frame.topPanel:SetScript("OnDragStart", function(self,button)
		frame:SetMovable(true);
        frame:StartMoving();
    end);
	frame.topPanel:SetScript("OnDragStop", function(self,button)
        frame:StopMovingOrSizing();
		frame:SetMovable(false);
    end);
end

function AltManager:MakeBorderPart(frame, x, y, xoff, yoff, part)
	if part == nil then
		part = frame:CreateTexture(nil);
	end
	part:SetTexture(0, 0, 0, 1);
	part:ClearAllPoints();
	part:SetPoint("TOPLEFT", frame, "TOPLEFT", xoff, yoff);
	part:SetSize(x, y);
	part:SetDrawLayer("ARTWORK", 7);
	return part;
end

function AltManager:MakeBorder(frame, size)
	if size == 0 then
		return;
	end
	frame.borderTop = self:MakeBorderPart(frame, frame:GetWidth(), size, 0, 0, frame.borderTop); -- top
	frame.borderLeft = self:MakeBorderPart(frame, size, frame:GetHeight(), 0, 0, frame.borderLeft); -- left
	frame.borderBottom = self:MakeBorderPart(frame, frame:GetWidth(), size, 0, -frame:GetHeight() + size, frame.borderBottom); -- bottom
	frame.borderRight = self:MakeBorderPart(frame, size, frame:GetHeight(), frame:GetWidth() - size, 0, frame.borderRight); -- right
end

-- shamelessly stolen from saved instances
function AltManager:GetNextWeeklyResetTime()
	if not self.resetDays then
		local region = self:GetRegion()
		if not region then return nil end
		self.resetDays = {}
		self.resetDays.DLHoffset = 0
		if region == "US" then
			self.resetDays["2"] = true -- tuesday
			-- ensure oceanic servers over the dateline still reset on tues UTC (wed 1/2 AM server)
			self.resetDays.DLHoffset = -3 
		elseif region == "EU" then
			self.resetDays["3"] = true -- wednesday
			self.resetDays.DLHoffset = 3
		elseif region == "CN" or region == "KR" or region == "TW" then -- XXX: codes unconfirmed
			self.resetDays["4"] = true -- thursday
		else
			self.resetDays["2"] = true -- tuesday?
		end
	end
	local offset = (self:GetServerOffset() + self.resetDays.DLHoffset) * 3600
	local nightlyReset = self:GetNextDailyResetTime()
	if not nightlyReset then return nil end
	while not self.resetDays[date("%w",nightlyReset+offset)] do
		nightlyReset = nightlyReset + 24 * 3600
	end
	return nightlyReset + offset
end

function AltManager:GetNextDailyResetTime()
	local resettime = GetQuestResetTime()
	if not resettime or resettime <= 0 or -- ticket 43: can fail during startup
		-- also right after a daylight savings rollover, when it returns negative values >.<
		resettime > 24*3600+30 then -- can also be wrong near reset in an instance
		return nil
	end
	if false then -- this should no longer be a problem after the 7.0 reset time changes
		-- ticket 177/191: GetQuestResetTime() is wrong for Oceanic+Brazilian characters in PST instances
		local serverHour, serverMinute = GetGameTime()
		local serverResetTime = (serverHour*3600 + serverMinute*60 + resettime) % 86400 -- GetGameTime of the reported reset
		local diff = serverResetTime - 10800 -- how far from 3AM server
		if math.abs(diff) > 3.5*3600  -- more than 3.5 hours - ignore TZ differences of US continental servers
			and self:GetRegion() == "US" then
			local diffhours = math.floor((diff + 1800)/3600)
			resettime = resettime - diffhours*3600
			if resettime < -900 then -- reset already passed, next reset
				resettime = resettime + 86400
				elseif resettime > 86400+900 then
				resettime = resettime - 86400
			end
		end
	end
	return time() + resettime
end

function AltManager:GetServerOffset()
	local serverDay, _, _, _ = CalendarGetDate();
		serverDay = serverDay - 1; -- 1-based starts on Sun
	local localDay = tonumber(date("%w")) -- 0-based starts on Sun
	local serverHour, serverMinute = GetGameTime()
	local localHour, localMinute = tonumber(date("%H")), tonumber(date("%M"))
	if serverDay == (localDay + 1)%7 then -- server is a day ahead
		serverHour = serverHour + 24
	elseif localDay == (serverDay + 1)%7 then -- local is a day ahead
		localHour = localHour + 24
	end
	local server = serverHour + serverMinute / 60
	local localT = localHour + localMinute / 60
	local offset = floor((server - localT) * 2 + 0.5) / 2
	return offset
end

function AltManager:GetRegion()
	if not self.region then
		local reg
		if string.find(GetCVar("realmList"),".hu") then
			self.region = "EU"
			return self.region
		end
		reg = GetCVar("portal")
		if reg == "public-test" then -- PTR uses US region resets, despite the misleading realm name suffix
			reg = "US"
		end
		if not reg or #reg ~= 2 then
			if (GetCurrentRegion ~= nil) then
				local gcr = GetCurrentRegion()
				reg = gcr and ({ "US", "KR", "EU", "TW", "CN" })[gcr]
			end
		end
		if not reg or #reg ~= 2 then
			reg = (GetCVar("realmList") or ""):match("^(%a+)%.")
		end
		if not reg or #reg ~= 2 then -- other test realms?
			reg = (GetRealmName() or ""):match("%((%a%a)%)")
		end
		reg = reg and reg:upper()
		if reg and #reg == 2 then
			self.region = reg
		end
	end
	return self.region
end

function AltManager:GetWoWDate()
	local hour = tonumber(date("%H"));
	local day, _, _, _ = CalendarGetDate();
	day = day - 1;
	return day, hour;
end

function AltManager:TimeString(length)
	if length == 0 then
		return "Now";
	end
	if length < 3600 then
		return string.format("%d mins", length / 60);
	end
	if length < 86400 then
		return string.format("%d hrs %d mins", length / 3600, (length % 3600) / 60);
	end
	return string.format("%d days %d hrs", length / 86400, (length % 86400) / 3600);
end
