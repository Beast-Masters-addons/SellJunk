SellJunk = LibStub("AceAddon-3.0"):NewAddon("SellJunk", "AceConsole-3.0","AceEvent-3.0")
local addon	= LibStub("AceAddon-3.0"):GetAddon("SellJunk")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog 	= LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("SellJunk", true)

addon.optionsFrame = {}
local options = nil

addon.sellButton = CreateFrame("Button", nil, MerchantFrame, "OptionsButtonTemplate")
addon.sellButton:SetPoint("TOPRIGHT", -41, -40)
addon.sellButton:SetText("Sell Junk")
addon.sellButton:SetScript("OnClick", function() SellJunk:Sell() end)

local string_find = string.find
local pairs = pairs
local PickupContainerItem = PickupContainerItem
local PickupMerchantItem = PickupMerchantItem


function addon:OnInitialize()
	self:RegisterChatCommand("selljunk", "OpenOptions")
	self:RegisterChatCommand("sj", "OpenOptions")

	self.db = LibStub("AceDB-3.0"):New("SellJunkDB")
	self.db:RegisterDefaults({
		char = {
			exceptions = {},
			auto = false,
		},
		global = {
			exceptions = {},
		}
	})

	self:PopulateOptions()
	AceConfigRegistry:RegisterOptionsTable("SellJunk", options)
	addon.optionsFrame = AceConfigDialog:AddToBlizOptions("SellJunk", nil, nil, "general")
end

function addon:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
end

function addon:MERCHANT_SHOW()
	if addon.db.char.auto then
		self:Sell()
	end
end

function addon:IsAuto()
	return addon.db.char.auto
end

function addon:ToggleAuto()
	self.db.char.auto = not self.db.char.auto
end

function addon:Sell()
	for bag = 0,4 do
		for slot = 1,GetContainerNumSlots(bag) do
			local item = GetContainerItemLink(bag,slot)
			if item then
				local found = string_find(item,"|cff9d9d9d")
				if ((found) and (not addon:isException(item))) or ((not found) and (addon:isException(item))) then
					PickupContainerItem(bag,slot)
					PickupMerchantItem()
					self:Print(L["Sold: "] .. item)
				end
			end
		end
	end
end

function addon:List()
	local test
	if self.db.global.exceptions then
		self:Print(L["Global exception list:"])
		for k,v in pairs(self.db.global.exceptions) do
			self:Print(v)
		end
	end

	if self.db.char.exceptions then
		self:Print(L["Character exception list:"])
		for k,v in pairs(self.db.char.exceptions) do
			self:Print(v)
		end
	end
end

function addon:Add(link, global)
	if global then
		self.db.global.exceptions[#(self.db.global.exceptions) + 1] = link
		self:Print(L["Added "] .. link .. L[" to global exception list."])
	else
		self.db.char.exceptions[#(self.db.char.exceptions) + 1] = link
		self:Print(L["Added "] .. link .. L[" to character exception list."])
	end		
end

function addon:Rem(link, global)
	local found = false
	local exception
	local _, _, linkID = string_find(link,"item:(%d+)")
	
	if global then
		for k,v in pairs(self.db.global.exceptions) do
			_, _, exception = string.find(v,"item:(%d+)")
			if (exception == linkID) then
				found = true
			end
			if found then
				if self.db.global.exceptions[k+1] then
					self.db.global.exceptions[k] = self.db.global.exceptions[k+1]
				else
					self.db.global.exceptions[k] = nil
				end
			end
		end
		if found then
			self:Print(L["Removed "] .. link .. L[" from global exception list."])
		end
	else
		for k,v in pairs(self.db.char.exceptions) do
			_, _, exception = string_find(v,"item:(%d+)")
			if (exception == linkID) then
				found = true
			end
			if found then
				if self.db.char.exceptions[k+1] then
					self.db.char.exceptions[k] = self.db.char.exceptions[k+1]
				else
					self.db.char.exceptions[k] = nil
				end
			end
		end
		if found then
			self:Print(L["Removed "] .. link .. L[" from character's exception list."])
		end
	end
end

function addon:isException(link)
	local exception
	_, _, link = string_find(link,"item:(%d+)")
	if self.db.global.exceptions then
		for k,v in pairs(self.db.global.exceptions) do
			_, _, exception = string_find(v,"item:(%d+)")
			if exception == link then
				return true
			end
		end
	end
	if self.db.char.exceptions then
		for k,v in pairs(self.db.char.exceptions) do
			_, _, exception = string_find(v,"item:(%d+)")
			if exception == link then
				return true
			end
		end
	end
	return false
end

function addon:OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(addon.optionsFrame)
end

function addon:PopulateOptions()
	if not options then
		options = {
			type = "group",
			name = "SellJunk",
			args = {
				general = {
					order	= 1,
					type	= "group",
					name	= "global",
					args	= {
						header1 = {
							order	= 10,
							type	= "description",
							name	= "",
						},
						auto = {
							order	= 11,
							type 	= "toggle",
							name 	= L["Automatically sell junk at vendor?"],
							desc 	= L["Toggles the automatic selling of junk when the merchant window is opened."],
							get 	= function() return addon.db.char.auto end,
							set 	= function() self.db.char.auto = not self.db.char.auto end,
						},
						header2 = {
							order	= 12,
							type	= "description",
							name	= "",
						},
						list = {
							order	= 13,
							type 	= "execute",
							name 	= L["List all exceptions"],
							desc 	= L["Lists all exceptions"],
							func 	= function() addon:List() end,
						},
						header3 = {
							order	= 14,
							type	= "description",
							name	= "",
						},
						header4 = {
							order	= 15,
							type	= "header",
							name	= L["Global Exceptions"],
						},
						header5 = {
							order 	= 16,
							type 	= "description",
							name	= L["Drag item into this window to add/remove it from exception list"],
						},
						add = {
							order	= 17,
							type 	= "input",
							name 	= L["Add item:"],
							desc 	= L["Add an exception for all characters."],
							usage 	= L["<Item Link>"],
							get 	= false,
							set 	= function(info, v) addon:Add(v, true) end,
						},
						rem = {
							order	= 18,
							type 	= "input",
							name 	= L["Remove item:"],
							desc 	= L["Remove an exception for all characters."],
							usage 	= L["<Item Link>"],
							get 	= false,
							set 	= function(info, v) addon:Rem(v, true) end,
						},
						header5 = {
							order	= 19,
							type	= "header",
							name	= L["Character Specific Exceptions"],
						},
						addMe = {
							order	= 20,
							type 	= "input",
							name 	= L["Add item:"],
							desc 	= L["Add an exception for this characters."],
							usage 	= L["<Item Link>"],
							get 	= false,
							set 	= function(info, v) addon:Add(v, false) end,
						},
						remMe = {
							order	= 21,
							type 	= "input",
							name 	= L["Remove item:"],
							desc 	= L["Remove an exception for this characters."],
							usage 	= L["<Item Link>"],
							get 	= false,
							set 	= function(info, v) addon:Rem(v, false) end,
						},
					}
				}
			}
		}
	end
end
