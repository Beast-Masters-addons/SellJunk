SellJunk = LibStub("AceAddon-3.0"):NewAddon("SellJunk", "AceConsole-3.0","AceEvent-3.0")
local addon	= LibStub("AceAddon-3.0"):GetAddon("SellJunk")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog 	= LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("SellJunk", true)

addon.optionsFrame = {}
local options = nil

addon.sellButton = CreateFrame("Button", nil, MerchantFrame, "OptionsButtonTemplate")
addon.sellButton:SetPoint("TOPRIGHT", -41, -40)
addon.sellButton:SetText(L["SELLJUNK"])
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
			max12 = true
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

function addon:IsMax12()
  return addon.db.char.max12
end


-------------------------------------------------------------
-- Sells items:                                            --
--   - grey quality, unless it's in exception list         --
--   - better than grey quality, if it's in exception list --
-------------------------------------------------------------
function addon:Sell()
	local limit = 0

  for bag = 0,4 do
    for slot = 1,GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag,slot)
      if item then
				-- is it grey quality item?
        local found = string_find(item,"|cff9d9d9d")

        if ((found) and (not addon:isException(item))) or ((not found) and (addon:isException(item))) then
          PickupContainerItem(bag,slot)
          PickupMerchantItem()
          self:Print(L["SOLD"].." "..item)
					
					if addon:IsMax12() then
						limit = limit + 1
						if limit == 12 then
							return
						end
					end
        end
      end
    end
  end
end


-----------------------------------------
-- Prints all exceptions to chat frame --
-----------------------------------------
function addon:List()
  if self.db.global.exceptions then
    self:Print(L["GLOBAL_EXC"]..":")
    for k,v in pairs(self.db.global.exceptions) do
      self:Print(v)
    end
  end

  if self.db.char.exceptions then
    self:Print(L["CHAR_EXC"]..":")
    for k,v in pairs(self.db.char.exceptions) do
      self:Print(v)
    end
  end
end

function addon:Add(link, global)

	-- remove all trailing whitespace
	link = strtrim(link)

	-- extract name from an itemlink
  local found, _, name = string_find(link, "^|c%x+|H.+|h.(.*)\].+")
	
	-- if it's not an itemlink, guess it's name of an item
	if not found then
		name = link
	end
  
  if global then
		-- append name of the item to global exception list
    self.db.global.exceptions[#(self.db.global.exceptions) + 1] = name
    self:Print(L["ADDED"] .. " " .. link .. L["TO"].." "..L["GLOBAL_EXC"])
  else
		-- append name of the item to character specific exception list
    self.db.char.exceptions[#(self.db.char.exceptions) + 1] = name
    self:Print(L["ADDED"] .. " " .. link .. L["TO"].." "..L["CHAR_EXC"])
  end		
end

function addon:Rem(link, global)
	local found = false
	local exception = nil
	
	-- remove all trailing whitespace
	link = strtrim(link)

	-- extract name from an itemlink
  local isLink, _, name = string_find(link, "^|c%x+|H.+|h.(.*)\].+")
	
	-- if it's not an itemlink, guess it's name of an item
	if not isLink then
		name = link
	end
	
	if global then
	
		-- looping through global exceptions
		for k,v in pairs(self.db.global.exceptions) do
			-- comparing exception list entry with given name
			if v:lower() == name:lower() then
				found = true
			end
			
			-- extract name from itemlink (only for compatibility with old saved variables)
			isLink, _, exception = string_find(v, "^|c%x+|H.+|h.(.*)\].+")
			if isLink then
				-- comparing exception list entry with given name
				if exception:lower() == name:lower() then
					found = true
				end
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
			self:Print(L["REMOVED"].." "..link.." "..L["FROM"].." "..L["GLOBAL_EXC"])
		end
	else
	
		-- looping through character specific exceptions
		for k,v in pairs(self.db.char.exceptions) do
			-- comparing exception list entry with given name
			if v:lower() == name:lower() then
				found = true
			end
			
			-- extract name from itemlink (only for compatibility with old saved variables)
			isLink, _, exception = string_find(v, "^|c%x+|H.+|h.(.*)\].+")
			if isLink then
				-- comparing exception list entry with given name
				if exception:lower() == name:lower() then
					found = true
				end
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
			self:Print(L["REMOVED"].." "..link..L["FROM"].." "..L["CHAR_EXC"])
		end
	end
end

function addon:isException(link)
	local exception = nil

	-- extracting name of an item from the itemlink
	local isLink, _, name = string_find(link, "^|c%x+|H.+|h.(.*)\].+")

	-- it's not an itemlink, so guess it's name of the item
	if not isLink then
		name = link
	end

	if self.db.global.exceptions then

		-- looping through global exceptions
		for k,v in pairs(self.db.global.exceptions) do

			-- comparing exception list entry with given name
			if v:lower() == name:lower() then
				return true
			end

			-- extract name from itemlink (only for compatibility with old saved variables)
			isLink, _, exception = string_find(v, "^|c%x+|H.+|h.(.*)\].+")
			if isLink then
				-- comparing exception list entry with given name
				if exception:lower() == name:lower() then
					return true
				end
			end
		end
	end


	if self.db.char.exceptions then

		-- looping through character specific eceptions
		for k,v in pairs(self.db.char.exceptions) do

			-- comparing exception list entry with given name
			if v:lower() == name:lower() then
        return true
      end

			-- extract name from itemlink (only for compatibility with old saved variables)
			isLink, _, exception = string_find(v, "^|c%x+|H.+|h.(.*)\].+")
			if isLink then
				-- comparing exception list entry with given name
				if exception:lower() == name:lower() then
					return true
				end
			end
		end
	end

	-- item not found in any exception list
	return false
end

function addon:OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(addon.optionsFrame)
end

function addon:PopulateOptions()
	if not options then
		options = {
			order = 1,
			type  = "group",
			name  = "SellJunk",
			args  = {
				general = {
					order	= 1,
					type	= "group",
					name	= "global",
					args	= {
						header1 = {
							order	= 1,
							type	= "description",
							name	= "",
						},
						auto = {
							order	= 2,
							type 	= "toggle",
							name 	= L["AUTO_SELL"],
							desc 	= L["AUTO_SELL_DESC"],
							get 	= function() return addon.db.char.auto end,
							set 	= function() self.db.char.auto = not self.db.char.auto end,
						},
						header2 = {
							order	= 3,
							type	= "description",
							name	= "",
						},

						max12 = {
							order = 4,
							type  = "toggle",
							name  = L["MAX12"],
							desc  = L["MAX12_DESC"],
							get 	= function() return addon.db.char.max12 end,
							set 	= function() self.db.char.max12 = not self.db.char.max12 end,
						},
						header3 = {
							order	= 5,
							type	= "description",
							name	= "",
						},
						list = {
							order	= 6,
							type 	= "execute",
							name 	= L["LIST_ALL"],
							func 	= function() addon:List() end,
						},
						header4 = {
							order	= 7,
							type	= "description",
							name	= "",
						},
						header5 = {
							order	= 8,
							type	= "header",
							name	= L["GLOBAL_EXC"],
						},
						header6 = {
							order = 9,
							type 	= "description",
							name	= L["DRAG_ITEM_DESC"],
						},
						add = {
							order	= 10,
							type 	= "input",
							name 	= L["ADD_ITEM"],
							desc 	= L["ADD"].." "..L["ALL_CHARS"],
							usage = L["ITEMLINK"],
							get 	= false,
							set 	= function(info, v) addon:Add(v, true) end,
						},
						rem = {
							order	= 11,
							type 	= "input",
							name 	= L["REM_ITEM"],
							desc 	= L["REM"].." "..L["ALL_CHARS"],
							usage 	= L["ITEMLINK"],
							get 	= false,
							set 	= function(info, v) addon:Rem(v, true) end,
						},
						header7 = {
							order	= 12,
							type	= "header",
							name	= L["CHAR_EXC"],
						},
						addMe = {
							order	= 13,
							type 	= "input",
							name 	= L["ADD_ITEM"],
							desc 	= L["ADD"].." "..L["THIS_CHAR"],
							usage 	= L["ITEMLINK"],
							get 	= false,
							set 	= function(info, v) addon:Add(v, false) end,
						},
						remMe = {
							order	= 14,
							type 	= "input",
							name 	= L["REM_ITEM"],
							desc 	= L["REM"].." "..L["THIS_CHAR"],
							usage 	= L["ITEMLINK"],
							get 	= false,
							set 	= function(info, v) addon:Rem(v, false) end,
						},
					}
				}
			}
		}
	end
end
