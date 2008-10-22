SellJunk = LibStub("AceAddon-3.0"):NewAddon("SellJunk", "AceConsole-3.0","AceEvent-3.0")
local addon	= LibStub("AceAddon-3.0"):GetAddon("SellJunk")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog 	= LibStub("AceConfigDialog-3.0")

addon.optionsFrame = {}
local options = nil

addon.sellButton = CreateFrame("Button", nil, MerchantFrame, "OptionsButtonTemplate")
addon.sellButton:SetPoint("TOPRIGHT", -41, -40)
addon.sellButton:SetText("Sell Junk")
addon.sellButton:SetScript("OnClick", function() SellJunk:Sell() end)

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
				local found = string.find(item,"|cff9d9d9d")
				if ((found) and (not addon:isException(item))) or ((not found) and (addon:isException(item))) then
					PickupContainerItem(bag,slot)
					PickupMerchantItem()
					self:Print("Sold " .. item)
				end
			end
		end
	end
end

function addon:List()
	self:Print("listing:")
	local test
	if self.db.global.exceptions then
		self:Print("Global exception list:")
		for k,v in pairs(self.db.global.exceptions) do
			self:Print(v)
		end
	end

	if self.db.char.exceptions then
		self:Print("Character exception list:")
		for k,v in pairs(self.db.char.exceptions) do
			self:Print(v)
		end
	end
end

function addon:Add(link, global)
	if global then
		self.db.global.exceptions[table.getn(self.db.global.exceptions) + 1] = link
		self:Print(link .. " added to global exception list.")
	else
		self.db.char.exceptions[table.getn(self.db.char.exceptions) + 1] = link
		self:Print(link .. " added to character exception list.")
	end		
end

function addon:Rem(link, global)
	local found = false
	local exception
	local _, _, linkID = string.find(link,"item:(%d+)")
	
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
			self:Print("Removed " .. link .. " from global exception list.")
		end
	else
		for k,v in pairs(self.db.char.exceptions) do
			_, _, exception = string.find(v,"item:(%d+)")
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
			self:Print("Removed " .. link .. " from character's exception list.")
		end
	end
end

function addon:isException(link)
	local exception
	_, _, link = string.find(link,"item:(%d+)")
	if self.db.global.exceptions then
		for k,v in pairs(self.db.global.exceptions) do
			_, _, exception = string.find(v,"item:(%d+)")
			if exception == link then
				return true
			end
		end
	end
	if self.db.char.exceptions then
		for k,v in pairs(self.db.char.exceptions) do
			_, _, exception = string.find(v,"item:(%d+)")
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
					desc	= "Global settings",
					args	= {
						header1 = {
							order	= 10,
							type	= "description",
							name	= "",
						},
						auto = {
							order	= 11,
							type = "toggle",
							name = "Automatically sell junk at vendor?",
							desc = "Toggles the automatic selling of junk when the merchant window is opened.",
							get = function() return addon.db.char.auto end,
							set = function() self.db.char.auto = not self.db.char.auto end,
						},
						header2 = {
							order	= 12,
							type	= "description",
							name	= "",
						},
						list = {
							order	= 13,
							type = "execute",
							name = "list all exceptions",
							desc = "Lists all exceptions",
							func = function() addon:List() end,
						},
						header3 = {
							order	= 14,
							type	= "description",
							name	= "",
						},
						header4 = {
							order	= 15,
							type	= "header",
							name	= "Global Exceptions",
						},
						add = {
							order	= 16,
							type = "input",
							name = "Add item:",
							desc = "Add an exception for all characters.",
							usage = "<Item Link>",
							get = false,
							set = function(info, v) addon:Add(v, true) end,
						},
						rem = {
							order	= 17,
							type = "input",
							name = "Remove item:",
							desc = "Remove an exception for all characters.",
							usage = "<Item Link>",
							get = false,
							set = function(info, v) addon:Rem(v, true) end,
						},
						header5 = {
							order	= 18,
							type	= "header",
							name	= "Character Specific Exceptions",
						},
						addMe = {
							order	= 19,
							type = "input",
							name = "Add item:",
							desc = "Add an exception for this characters.",
							usage = "<Item Link>",
							get = false,
							set = function(info, v) addon:Add(v, false) end,
						},
						remMe = {
							order	= 20,
							type = "input",
							name = "Remove item:",
							desc = "Remove an exception for this characters.",
							usage = "<Item Link>",
							get = false,
							set = function(info, v) addon:Rem(v, false) end,
						},
					}
				}
			}
		}
	end
end
