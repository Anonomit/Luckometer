
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



local strMatch  = string.match
local strGmatch = string.gmatch
local strGsub   = string.gsub
local strByte   = string.byte

local tinsert   = table.insert
local tblConcat = table.concat
local tblSort   = table.sort

local mathMin   = math.min
local mathMax   = math.max
local mathCeil  = math.ceil







local name, desc, disabled





local QUALITY_NAMES = {}
for i = 0, 5 do
  QUALITY_NAMES[i] = ITEM_QUALITY_COLORS[i].hex .. _G["ITEM_QUALITY" .. i .. "_DESC"]
end

local ROLL_TYPE_NAMES = {
  format("%s %s", Addon:MakeIcon"Interface\\Buttons\\UI-GroupLoot-Dice-Up", Addon.L["Need"]),
  format("%s %s", Addon:MakeIcon"Interface\\Buttons\\UI-GroupLoot-Coin-Up", Addon.L["Greed"]),
  format("%s %s", Addon:MakeIcon"Interface\\Buttons\\UI-GroupLoot-DE-Up",   Addon.L["Disenchant"]),
}








--   ██████╗ ███████╗███╗   ██╗███████╗██████╗  █████╗ ██╗          ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗██║         ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ██████╔╝███████║██║         ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██║██║         ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ╚██████╔╝███████╗██║ ╚████║███████╗██║  ██║██║  ██║███████╗    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--   ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

local function MakeGeneralOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  
  
  
  return opts
end






--  ███████╗██╗██╗  ████████╗███████╗██████╗ ███████╗
--  ██╔════╝██║██║  ╚══██╔══╝██╔════╝██╔══██╗██╔════╝
--  █████╗  ██║██║     ██║   █████╗  ██████╔╝███████╗
--  ██╔══╝  ██║██║     ██║   ██╔══╝  ██╔══██╗╚════██║
--  ██║     ██║███████╗██║   ███████╗██║  ██║███████║
--  ╚═╝     ╚═╝╚══════╝╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝

local function MakeFilterOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  GUI:SetDBType"Global"
  
  
  local hasRolls
  for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
    if rolls:GetCount() > 0 then
      hasRolls = true
      break
    end
  end
  
  -- show roll buttons
  if not hasRolls then
    GUI:CreateDivider(opts, 3)
    
    local width = 0.6
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Options"])
      
      GUI:CreateDescription(opts, self.L["Please select one of the following options:"], "medium")
      do
        for row = 1, 3 do
          GUI:CreateNewline(opts)
          for col = 1, 3 do
            GUI:CreateExecute(opts, "/roll", self.L["/roll"], desc, function()
              RandomRoll(1, 100)
            end).width = width
          end
        end
      end
    end
    
    GUI:CreateDivider(opts, 3)
    
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Advanced Options"])
      
      GUI:CreateDescription(opts, self.L["Please select one of the following options:"], "medium")
      do
        for row = 1, 5 do
          GUI:CreateNewline(opts)
          for col = 1, 5 do
            GUI:CreateExecute(opts, "/roll", self.L["/roll"], desc, function()
              RandomRoll(1, 100)
            end).width = width
          end
        end
      end
    end
    
    GUI:CreateDivider(opts, 3)
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Help"])
      
      GUI:CreateDescription(opts, self.L["These options can improve ease of access."], "medium")
      GUI:CreateNewline(opts)
      local option = GUI:CreateExecute(opts, "Tutorial", self.L["Show Tutorials"], nil, function()
        RandomRoll(1, 100)
      end)
      option.width = 1
      option.confirm = function() return self.L["/roll"] end
    end
  else
    -- roll results
    local threadData = self:GetThreadData"RollResults" or {}
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Loot Rolls"])
      
      
      local results = threadData.results
      
      local count    = "???"
      local avg      = "???"
      local luck     = "???"
      if results then
        local filtered = results.count or 0
        local total    = self:CountRolls()
        local percent  = self:Round(filtered / total * 100, 0.01)
        count = format("%s / %s (%s%%)", self:ToFormattedNumber(filtered, 0), self:ToFormattedNumber(total, 0), self:ToFormattedNumber(percent))
        if filtered > 0 then
          local avgRoll  = self:ToFormattedNumber(results.avgRoll,      1) .. " (1-100)"
          local avgScore = self:ToFormattedNumber(results.avgScore*100, 1) .. "%"
          
          avg  = format("%s (%s)", avgRoll, avgScore)
          luck = self:ToFormattedNumber(results.luck*100,     1) .. "%"
        else
          avg      = self.L["N/A"]
          luck     = self.L["N/A"]
        end
      end
      
      GUI:CreateDescription(opts, format("%s: %s", self.L["Loot Rolls"], count))
      GUI:CreateDescription(opts, format("%s: %s", self.L["Average"],    avg))
      GUI:CreateDescription(opts, format("%s %s",  self.L["Score:"],     luck))
      
      do
        local processing = not self:IsThreadDead"RollResults" and threadData.refreshWhenDone
        local disabled = not not (processing or results)
        
        GUI:CreateNewline(opts)
        GUI:CreateExecute(opts, "Search", processing and self.L["Processing..."] or disabled and self.L["Research Complete"] or self.L["Click to Research"], desc, function() Addon:StartRollCalculations(true) end, disabled)
      end
    end
    
    GUI:CreateDescription(opts, format(self.L["Filter %s"], self.L["Loot Rolls"])).width = 0.8
    GUI:CreateReset(opts, {"filters"}, function() self:ResetGlobalOptionQuiet("filters") end)
    
    -- filters
    do
      -- character filters
      do
        local opts = GUI:CreateGroup(opts, "Character", self.L["Character"], nil, "tab")
        
        GUI:CreateReset(opts, {"filters", "character"}, function() self:ResetGlobalOptionQuiet("filters", "character") end)
        
        -- character selection
        do
          local opts = GUI:CreateGroup(opts, "Character", self.L["Character"], nil, "tab")
          
          local totalRolls = 0
          for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
            if self:GetGlobalOption("filters", "character", "guid", guid) then
              totalRolls = totalRolls + rolls:GetCount()
            end
          end
          
          local sexes    = {}
          local factions = {}
          for guid, charData in pairs(self:GetGlobalOptionQuiet"characters") do
            sexes[charData.sex] = true
            factions[self:GetLocalFactionFromGUID(guid)] = true
          end
          
          do
            local opts = GUI:CreateGroupBox(opts, self.L["Select"])
            
            GUI:CreateExecute(opts, "All", self.L["All"], desc, function()
              self:ResetGlobalOptionQuiet("filters", "character", "guid")
            end, disabled).width = 0.5
            GUI:CreateExecute(opts, "None", self.L["None"], desc, function()
              self:RestartFilteringAfter(function()
                for guid in pairs(self:GetGlobalOptionQuiet"characters") do
                  self:SetGlobalOption(false, "filters", "character", "guid", guid)
                end
              end)
            end, disabled).width = 0.5
            GUI:CreateExecute(opts, "Me", self.L["Me"], desc, function()
              self:RestartFilteringAfter(function()
                for guid in pairs(self:GetGlobalOptionQuiet"characters") do
                  self:SetGlobalOption(guid == self.MY_GUID, "filters", "character", "guid", guid)
                end
              end)
            end, disabled).width = 0.5
            
            if self:CountKeys(factions) > 1 then
              GUI:CreateNewline(opts)
              for _, faction in ipairs{self.L["Alliance"], self.L["Horde"], self.L["Neutral"], self.L["Unknown"]} do
                if factions[faction] then
                  GUI:CreateExecute(opts, faction, self.L[faction], desc, function()
                    self:RestartFilteringAfter(function()
                      for guid, charData in pairs(self:GetGlobalOptionQuiet"characters") do
                        self:SetGlobalOption(self:GetFactionFromGUID(guid) == faction, "filters", "character", "guid", guid)
                      end
                    end)
                  end, disabled).width = 0.5
                end
              end
            end
            
            if self:CountKeys(sexes) > 1 then
              GUI:CreateNewline(opts)
              local SEX_IDS = {Male = 0, Female = 1}
              for _, sex in ipairs{"Male", "Female"} do
                GUI:CreateExecute(opts, sex, self.L[sex], desc, function()
                  self:RestartFilteringAfter(function()
                    for guid, charData in pairs(self:GetGlobalOptionQuiet"characters") do
                      self:SetGlobalOption(charData.sex == SEX_IDS[sex], "filters", "character", "guid", guid)
                    end
                  end)
                end, disabled).width = 0.5
              end
            end
            GUI:CreateNewline(opts)
            
            GUI:CreateDescription(opts, format("%s %s %s", self.L["Total:"], self:ToFormattedNumber(totalRolls), self.L["|4Loot Roll:Loot Rolls;"]))
          end
          
          GUI:CreateNewline(opts)
          
          local oldOpts = opts
          
          local realmIDs = {}
          for i, guid in ipairs(self:GetOrderedGUIDS()) do
            local realmID, realmName = self:GetRealmFromGUID(guid)
            local newRealmID = false
            if realmIDs[#realmIDs] ~= realmName then
              newRealmID = true
              realmIDs[#realmIDs+1] = realmName
            end
            
            if newRealmID then
              opts = GUI:CreateGroupBox(oldOpts, realmName)
            end
            
            if newRealmID then
              GUI:CreateExecute(opts, "Enable" .. realmID, self.L["Enable All"], desc, function()
                self:RestartFilteringAfter(function()
                  for guid in pairs(self:GetGlobalOptionQuiet"characters") do
                    if self:GetRealmFromGUID(guid) == realmID then
                      self:SetGlobalOption(true, "filters", "character", "guid", guid)
                    end
                  end
                end)
              end, disabled).width = 0.8
              GUI:CreateExecute(opts, "Disable" .. realmID, self.L["Disable All"], desc, function()
                self:RestartFilteringAfter(function()
                  for guid in pairs(self:GetGlobalOptionQuiet"characters") do
                    if self:GetRealmFromGUID(guid) == realmID then
                      self:SetGlobalOption(false, "filters", "character", "guid", guid)
                    end
                  end
                end)
              end, disabled).width = 0.8
            end
            
            local nameRealm
            if totalRolls ~= 0 then
              nameRealm = self:GetColoredNameRealmFromGUID(guid)
            else
              nameRealm = format("%s%s-%s", self:MakeColorCode"ff0000", self:GetNameFromGUID(guid), realmName)
            end
            
            GUI:CreateNewline(opts)
            local charRolls = self:GetGlobalOptionQuiet("rolls", guid):GetCount()
            GUI:CreateToggle(opts, {"filters", "character", "guid", guid}, nameRealm, nil, disabled).width = 1.2
            GUI:CreateDescription(opts, format("%s %s", self:ToFormattedNumber(charRolls), self.L["|4Loot Roll:Loot Rolls;"]), "medium").width = 1
          end
          opts = oldOpts
        end
        
        -- level filters
        do
          local opts = GUI:CreateGroup(opts, "Level", self.L["Level"], nil, "tab")
            
          local maxCharLevel = Addon.MAX_LEVEL
          
          do
            local opts = GUI:CreateGroupBox(opts, self.L["Select"])
            
            GUI:CreateExecute(opts, "Unlimited", self.L["Unlimited"], desc, function()
              self:RestartFilteringAfter(function()
                self:SetGlobalOption(false,       "filters", "character", "level", "enable")
                self:SetGlobalOption(1,           "filters", "character", "level", "min")
                self:SetGlobalOption(maxCharLevel,"filters", "character", "level", "max")
              end)
            end, disabled).width = 0.7
            GUI:CreateExecute(opts, "Max Level", self.L["Max Level"], desc, function()
              self:RestartFilteringAfter(function()
                self:SetGlobalOption(true,         "filters", "character", "level", "enable")
                self:SetGlobalOption(maxCharLevel, "filters", "character", "level", "min")
                self:SetGlobalOption(maxCharLevel, "filters", "character", "level", "max")
              end)
            end, disabled).width = 0.7
            GUI:CreateExecute(opts, "Below Max Level", format(self.L["%d-%d"], 1, maxCharLevel-1), desc, function()
              self:RestartFilteringAfter(function()
                self:SetGlobalOption(true,           "filters", "character", "level", "enable")
                self:SetGlobalOption(1,              "filters", "character", "level", "min")
                self:SetGlobalOption(maxCharLevel-1, "filters", "character", "level", "max")
              end)
            end, disabled).width = 0.7
            GUI:CreateNewline(opts)
            
            local minLevel, maxLevel
            if self:GetGlobalOption("filters", "character", "level", "enable") then
              minLevel = self:GetGlobalOption("filters", "character", "level", "min")
              maxLevel = self:GetGlobalOption("filters", "character", "level", "max")
            else
              minLevel = 1
              maxLevel = maxCharLevel
            end
            if minLevel == maxLevel then
              GUI:CreateDescription(opts, format(self.L["Level %d"], minLevel))
            else
              GUI:CreateDescription(opts, format("%s %s", self.L["Level Range:"], format(self.L["%d-%d"], minLevel, maxLevel)))
            end
          end
          
          GUI:CreateNewline(opts)
          
          do
            local opts = GUI:CreateGroupBox(opts, self.L["Level"])
            
            GUI:CreateReverseToggle(opts, {"filters", "character", "level", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
            do
              local disabled = disabled or not self:GetGlobalOption("filters", "character", "level", "enable")
              
              local option = GUI:CreateRange(opts, {"filters", "character", "level", "min"}, self.L["Minimum"], nil, 1, 120, 1, disabled)
              option.softMax = maxCharLevel
              option.set = function(info, val)
                self:SetGlobalOption(val, "filters", "character", "level", "min")
                self:SetGlobalOption(mathMax(val,   self:GetGlobalOption("filters", "character", "level", "max")), "filters", "character", "level", "max")
              end
              local option = GUI:CreateRange(opts, {"filters", "character", "level", "max"}, self.L["Maximum"], nil, 1, 120, 1, disabled)
              option.softMax = maxCharLevel
              option.set = function(info, val)
                self:SetGlobalOption(val, "filters", "character", "level", "max")
                self:SetGlobalOption(mathMin(val, self:GetGlobalOption("filters", "character", "level", "min")), "filters", "character", "level", "min")
              end
            end
          end
        end
        
        -- inventory filters
        do
          local opts = GUI:CreateGroup(opts, "Inventory", self.L["Inventory"], nil, "tab")
          
          if #self.orderedLuckyItems > 1 then
            GUI:CreateToggle(opts, {"filters", "character", "luckyItems", "enable"}, self.L["Required items:"]).width = 0.8
            do
              local disabled = not self:GetGlobalOption("filters", "character", "luckyItems", "enable")
              
              local validFilter = true
              if not disabled then
                local operator = self:GetGlobalOption("filters", "character", "luckyItems", "operator")
                if operator == "any" or operator == "all" then
                  validFilter = false
                  for id, required in pairs(self:GetGlobalOptionQuiet("filters", "character", "luckyItems", "items")) do
                    if required == true then
                      validFilter = true
                      break
                    end
                  end
                elseif operator == "none" then
                  validFilter = true
                end
              end
              
              local color = validFilter and "" or "|cffff0000"
              
              GUI:CreateDropdown(opts, {"filters", "character", "luckyItems", "operator"}, "", desc, {any = self.L["any"], all = self.L["all"], none = self.L["none"]}, {"any", "all", "none"}, disabled).width = 0.4
              GUI:CreateMultiDropdown(opts, {"filters", "character", "luckyItems", "items"}, color .. self.L["Items"], desc, self.luckyItemNames, disabled).width = 2
            end
          else
            local itemID = self.orderedLuckyItems[1]
            
            GUI:CreateToggle(opts, {"filters", "character", "luckyItems", "enable"}, format(self.L["Requires %s"], " " .. self.luckyItemNames[itemID])).width = 1.3
            do
              local disabled = not self:GetGlobalOption("filters", "character", "luckyItems", "enable")
              
              if self:GetGlobalOption("filters", "character", "luckyItems", "operator") == "all" then
                GUI:CreateDropdown(opts, {"filters", "character", "luckyItems", "operator"}, "", desc, {all = self.L["Yes"], none = self.L["No"]}, {"all", "none"}, disabled).width = 0.4
              else
                GUI:CreateDropdown(opts, {"filters", "character", "luckyItems", "operator"}, "", desc, {any = self.L["Yes"], none = self.L["No"]}, {"any", "none"}, disabled).width = 0.4
              end
              
            end
          end
        end
      end
      
      -- group loot filters
      do
        local opts = GUI:CreateGroup(opts, "Group Loot", self.L["Group Loot"], nil, "tab")
        
        do
          local opts = GUI:CreateGroupBox(opts, self.L["Group Loot"])
          
          local color = not self:GetGlobalOption("filters", "group", "enable") and not self:GetGlobalOption("filters", "manual", "enable") and "|cffff0000" or ""
          GUI:CreateToggle(opts, {"filters", "group", "enable"},  color .. self.L["Enable"], nil, disabled).width = 0.6
          GUI:CreateReset(opts, {"filters", "group"}, function() self:ResetGlobalOptionQuiet("filters", "group") end)
        end
        
        do
          local opts = GUI:CreateGroup(opts, "Loot Rolls", self.L["Loot Rolls"], nil, "tab")
          
          local disabled = not self:GetGlobalOption("filters", "group", "enable")
          
          do
            local validFilter = false
            for i in ipairs(ROLL_TYPE_NAMES) do
              validFilter = validFilter or self:GetGlobalOptionQuiet("filters", "group", "roll", "type", i)
              if validFilter then break end
            end
            
            local color = validFilter and "" or "|cffff0000"
            GUI:CreateMultiDropdown(opts, {"filters", "group", "roll", "type"}, color .. self.L["Type"], desc, ROLL_TYPE_NAMES, disabled).width = 1.5
          end
          
          GUI:CreateNewline(opts)
          
          do
            local opts = GUI:CreateGroupBox(opts, self.L["Win"])
            
            local color = not self:GetGlobalOption("filters", "group", "roll", "won", 0) and not self:GetGlobalOption("filters", "group", "roll", "won", 1) and "|cffff0000" or ""
            GUI:CreateToggle(opts, {"filters", "group", "roll", "won", 1}, color .. self.L["Yes"], nil, disabled)
            GUI:CreateToggle(opts, {"filters", "group", "roll", "won", 0}, color .. self.L["No"],  nil, disabled)
          end
          
          GUI:CreateNewline(opts)
          
          do
            local opts = GUI:CreateGroupBox(opts, self.L["Players"])
            
            GUI:CreateReverseToggle(opts, {"filters", "group", "roll", "numPlayers", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
            do
              local disabled = disabled or not self:GetGlobalOption("filters", "group", "roll", "numPlayers", "enable")
              
              local option = GUI:CreateRange(opts, {"filters", "group", "roll", "numPlayers", "min"}, self.L["Minimum"], nil, 1, 40, 1, disabled)
              option.set = function(info, val)
                self:SetGlobalOption(val, "filters", "group", "roll", "numPlayers", "min")
                self:SetGlobalOption(mathMax(val,   self:GetGlobalOption("filters", "group", "roll", "numPlayers", "max")), "filters", "group", "roll", "numPlayers", "max")
              end
              local option = GUI:CreateRange(opts, {"filters", "group", "roll", "numPlayers", "max"}, self.L["Maximum"], nil, 1, 40, 1, disabled)
              option.set = function(info, val)
                self:SetGlobalOption(val, "filters", "group", "roll", "numPlayers", "max")
                self:SetGlobalOption(mathMin(val, self:GetGlobalOption("filters", "group", "roll", "numPlayers", "min")), "filters", "group", "roll", "numPlayers", "min")
              end
            end
          end
        end
        
        do
          local opts = GUI:CreateGroup(opts, "Items", self.L["Items"], nil, "tab")
          
          do
            local validFilter = false
            for i in ipairs(QUALITY_NAMES) do
              validFilter = validFilter or self:GetGlobalOptionQuiet("filters", "group", "item", "quality", i)
              if validFilter then break end
            end
            
            local color = validFilter and "" or "|cffff0000"
            GUI:CreateMultiDropdown(opts, {"filters", "group", "item", "quality"}, color .. self.L["Item Quality"], desc, QUALITY_NAMES, disabled).width = 2
          end
          
          GUI:CreateNewline(opts)
          
          do
            local opts = GUI:CreateGroupBox(opts, self.L["Item Level"])
            
            local maxItemLevel = Addon.MAX_ITEM_LEVEL_SLIDER
            
            GUI:CreateReverseToggle(opts, {"filters", "group", "item", "level", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
            do
              local disabled = disabled or not self:GetGlobalOption("filters", "group", "item", "level", "enable")
              
              local option = GUI:CreateRange(opts, {"filters", "group", "item", "level", "min"}, self.L["Minimum"], nil, 1, 1000, 1, disabled)
              option.softMax = maxItemLevel
              option.set = function(info, val)
                self:SetGlobalOption(val, "filters", "group", "item", "level", "min")
                self:SetGlobalOption(mathMax(val,   self:GetGlobalOption("filters", "group", "item", "level", "max")), "filters", "group", "item", "level", "max")
              end
              local option = GUI:CreateRange(opts, {"filters", "group", "item", "level", "max"}, self.L["Maximum"], nil, 1, 1000, 1, disabled)
              option.softMax = maxItemLevel
              option.set = function(info, val)
                self:SetGlobalOption(val, "filters", "group", "item", "level", "max")
                self:SetGlobalOption(mathMin(val, self:GetGlobalOption("filters", "group", "item", "level", "min")), "filters", "group", "item", "level", "min")
              end
            end
          end
        end
      end
    
    
      -- manual filters
      do
        local opts = GUI:CreateGroup(opts, "/roll", self.L["/roll"], nil, "tab")
        
        do
          local opts = GUI:CreateGroupBox(opts, self.L["/roll"])
          
          local color = not self:GetGlobalOption("filters", "group", "enable") and not self:GetGlobalOption("filters", "manual", "enable") and "|cffff0000" or ""
          GUI:CreateToggle(opts, {"filters", "manual", "enable"},  color .. self.L["Enable"], nil, disabled).width = 0.6
          GUI:CreateReset(opts, {"filters", "manual"}, function() self:ResetGlobalOptionQuiet("filters", "manual") end)
        end
        
        
        local disabled = not self:GetGlobalOption("filters", "manual", "enable")
        
        GUI:CreateNewline(opts)
        
        do
          local opts = GUI:CreateGroupBox(opts, self.L["Select"])
          
          GUI:CreateExecute(opts, "Unlimited", self.L["Unlimited"], desc, function()
            self:RestartFilteringAfter(function()
              self:SetGlobalOption(false,     "filters", "manual", "roll", "limits", "min", "enable")
              self:SetGlobalOption(0,         "filters", "manual", "roll", "limits", "min", "min")
              self:SetGlobalOption(1000000-1, "filters", "manual", "roll", "limits", "min", "max")
              self:SetGlobalOption(false,     "filters", "manual", "roll", "limits", "max", "enable")
              self:SetGlobalOption(1,         "filters", "manual", "roll", "limits", "max", "min")
              self:SetGlobalOption(1000000,   "filters", "manual", "roll", "limits", "max", "max")
            end)
          end, disabled).width = 0.7
          GUI:CreateExecute(opts, "1-100", format(self.L["%d-%d"], 1, 100), desc, function()
            self:RestartFilteringAfter(function()
              self:SetGlobalOption(true, "filters", "manual", "roll", "limits", "min", "enable")
              self:SetGlobalOption(1,    "filters", "manual", "roll", "limits", "min", "min")
              self:SetGlobalOption(1,    "filters", "manual", "roll", "limits", "min", "max")
              self:SetGlobalOption(true, "filters", "manual", "roll", "limits", "max", "enable")
              self:SetGlobalOption(100,  "filters", "manual", "roll", "limits", "max", "min")
              self:SetGlobalOption(100,  "filters", "manual", "roll", "limits", "max", "max")
            end)
          end, disabled).width = 0.7
          GUI:CreateExecute(opts, "1-99", format("%s %s %s", format(self.L["%d-%d"], 1, 2), self.L["-->"], format(self.L["%d-%d"], 1, 99)), desc, function()
            self:RestartFilteringAfter(function()
              self:SetGlobalOption(true, "filters", "manual", "roll", "limits", "min", "enable")
              self:SetGlobalOption(1,    "filters", "manual", "roll", "limits", "min", "min")
              self:SetGlobalOption(1,    "filters", "manual", "roll", "limits", "min", "max")
              self:SetGlobalOption(true, "filters", "manual", "roll", "limits", "max", "enable")
              self:SetGlobalOption(2,    "filters", "manual", "roll", "limits", "max", "min")
              self:SetGlobalOption(99,   "filters", "manual", "roll", "limits", "max", "max")
            end)
          end, disabled).width = 0.7
          
          local minmin, minmax
          if self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "enable") then
            minmin = self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "min")
            minmax = self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "max")
          else
            minmin = 0
            minmax = 1000000-1
          end
          local maxmin, maxmax
          if self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "enable") then
            maxmin = self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "min")
            maxmax = self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "max")
          else
            maxmin = 1
            maxmax = 1000000
          end
          GUI:CreateNewline(opts)
          
          local minText
          if minmin == minmax then
            minText = self:ToFormattedNumber(minmin)
          elseif minmin == 0 and minmax == 1000000-1 then
            minText = self.L["Unlimited"]
          else
            minText = format("[%s]", format("%s-%s", self:ToFormattedNumber(minmin), self:ToFormattedNumber(minmax)))
          end
          local maxText
          if maxmin == maxmax then
            maxText = self:ToFormattedNumber(maxmin)
          elseif maxmin == 1 and maxmax == 1000000 then
            maxText = self.L["Unlimited"]
          else
            maxText = format("[%s]", format("%s-%s", self:ToFormattedNumber(maxmin), self:ToFormattedNumber(maxmax)))
          end
          
          local sampleText = format("%s - %s", minText, maxText)
          GUI:CreateDescription(opts, sampleText)
        end
        
        do
          local opts = GUI:CreateGroupBox(opts, self.L["Minimum"])
          
          GUI:CreateReverseToggle(opts, {"filters", "manual", "roll", "limits", "min", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
          do
            local disabled = disabled or not self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "enable")
            
            local option = GUI:CreateRange(opts, {"filters", "manual", "roll", "limits", "min", "min"}, self.L["Minimum"], nil, 0, 1000000-1, 1, disabled)
            option.softMax = 100
            option.set = function(info, val)
              self:SetGlobalOption(val, "filters", "manual", "roll", "limits", "min", "min")
              self:SetGlobalOption(mathMax(val,   self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "max")), "filters", "manual", "roll", "limits", "min", "max")
              self:SetGlobalOption(mathMax(val+1, self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "min")), "filters", "manual", "roll", "limits", "max", "min")
              self:SetGlobalOption(mathMax(val+1, self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "max")), "filters", "manual", "roll", "limits", "max", "max")
            end
            local option = GUI:CreateRange(opts, {"filters", "manual", "roll", "limits", "min", "max"}, self.L["Maximum"], nil, 0, 1000000-1, 1, disabled)
            option.softMax = 100
            option.set = function(info, val)
              self:SetGlobalOption(val, "filters", "manual", "roll", "limits", "min", "max")
              self:SetGlobalOption(mathMin(val, self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "min")), "filters", "manual", "roll", "limits", "min", "min")
            end
          end
        end
        
        do
          local opts = GUI:CreateGroupBox(opts, self.L["Maximum"])
          
          GUI:CreateReverseToggle(opts, {"filters", "manual", "roll", "limits", "max", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
          do
            local disabled = disabled or not self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "enable")
            
            local option = GUI:CreateRange(opts, {"filters", "manual", "roll", "limits", "max", "min"}, self.L["Minimum"], nil, 1, 1000000, 1, disabled)
            option.softMax = 200
            option.set = function(info, val)
              self:SetGlobalOption(val, "filters", "manual", "roll", "limits", "max", "min")
              self:SetGlobalOption(mathMax(val, self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "max")), "filters", "manual", "roll", "limits", "max", "max")
            end
            local option = GUI:CreateRange(opts, {"filters", "manual", "roll", "limits", "max", "max"}, self.L["Maximum"], nil, 1, 1000000, 1, disabled)
            option.softMax = 200
            option.set = function(info, val)
              self:SetGlobalOption(val, "filters", "manual", "roll", "limits", "max", "max")
              self:SetGlobalOption(mathMin(val,   self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "min")), "filters", "manual", "roll", "limits", "max", "min")
              self:SetGlobalOption(mathMin(val-1, self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "max")), "filters", "manual", "roll", "limits", "min", "max")
              self:SetGlobalOption(mathMin(val-1, self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "min")), "filters", "manual", "roll", "limits", "min", "min")
            end
            
          end
        end
        
        -- GUI:CreateNewline(opts)
        
        -- do
        --   local opts = GUI:CreateGroupBox(opts, self.L["Loot Rolls"])
          
        --   do
        --     local min = self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "enable") and self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "min") or 0
        --     local max = self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "enable") and self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "max") or 1000000
        --     GUI:CreateDescription(opts, format("(%d-%d)", min, max))
        --   end
          
        -- end
      end
    end
  end
  
  return opts
end





--  ██████╗  ██████╗ ██╗     ██╗         ██╗  ██╗██╗███████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
--  ██╔══██╗██╔═══██╗██║     ██║         ██║  ██║██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
--  ██████╔╝██║   ██║██║     ██║         ███████║██║███████╗   ██║   ██║   ██║██████╔╝ ╚████╔╝ 
--  ██╔══██╗██║   ██║██║     ██║         ██╔══██║██║╚════██║   ██║   ██║   ██║██╔══██╗  ╚██╔╝  
--  ██║  ██║╚██████╔╝███████╗███████╗    ██║  ██║██║███████║   ██║   ╚██████╔╝██║  ██║   ██║   
--  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝    ╚═╝  ╚═╝╚═╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   

local function MakeHistoryOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  GUI:SetDBType"Global"
  
  
  local threadData = self:GetThreadData"RollResults" or {}
  local results = threadData.results
  
  -- Calculations incomplete
  do
    do
      local processing = not self:IsThreadDead"RollResults" and threadData.refreshWhenDone
      local disabled = not not (processing or results)
      
      if not results then
        GUI:CreateExecute(opts, "Search", processing and self.L["Processing..."] or disabled and self.L["Research Complete"] or self.L["Click to Research"], desc, function() Addon:StartRollCalculations(true) end, disabled)
      end
    end
  end
  
  -- No rolls passed filters
  if results and results.count == 0 then
    
    GUI:CreateDivider(opts)
    GUI:CreateDescription(opts, format("%s: 0", self.L["Loot Rolls"]))
    GUI:CreateDivider(opts)
    GUI:CreateExecute(opts, "Filters", self.L["Filters"], desc, function() self:OpenConfig"Filters" end, disabled)
  
  -- calculations complete
  elseif results then
    local rollsPerPage = 5
    local rollCount = results.count
    local pageCount = mathCeil(rollCount / rollsPerPage)
    
    self.currentHistoryPage = mathMin(self.currentHistoryPage or 1, pageCount)
    
    if pageCount > 1 then
      local name = pageCount == 1 and format(self.L["Page %d"], self.currentHistoryPage) or format(self.L["Page %d / %d"], self.currentHistoryPage, pageCount)
      
      do
        local disabled = self.currentHistoryPage == 1
        
        if pageCount > 11 then
          GUI:CreateExecute(opts, "-100", "<<<", "-100", function() self.currentHistoryPage = self:Clamp(1, self.currentHistoryPage - 100, pageCount) end, disabled).width = 0.3
        end
        if pageCount > 2 then
          GUI:CreateExecute(opts, "-10", "<<", "-10", function() self.currentHistoryPage = self:Clamp(1, self.currentHistoryPage - 10, pageCount) end, disabled).width = 0.3
        end
        GUI:CreateExecute(opts, "-1", "<", "-1", function() self.currentHistoryPage = self:Clamp(1, self.currentHistoryPage - 1, pageCount) end, disabled).width = 0.3
      end
      
      do
        local option = GUI:CreateRange(opts, {"page"}, name, nil, 1, pageCount, 1, disabled)
        option.width = 1.5
        option.get = function(info)      return self.currentHistoryPage       end
        option.set = function(info, val)        self.currentHistoryPage = val end
      end
      
      do
        local disabled = self.currentHistoryPage == pageCount
        
        GUI:CreateExecute(opts, "+1", ">", "+1", function() self.currentHistoryPage = self:Clamp(1, self.currentHistoryPage + 1, pageCount) end, disabled).width = 0.3
        if pageCount > 2 then
          GUI:CreateExecute(opts, "+10", ">>", "+10", function() self.currentHistoryPage = self:Clamp(1, self.currentHistoryPage + 10, pageCount) end, disabled).width = 0.3
        end
        if pageCount > 11 then
          GUI:CreateExecute(opts, "+100", ">>>", "+100", function() self.currentHistoryPage = self:Clamp(1, self.currentHistoryPage + 100, pageCount) end, disabled).width = 0.3
        end
      end
    end
    
    do
      local opts = GUI:CreateGroupBox(opts, self.L["History"])
      
      local topRoll    = (self.currentHistoryPage-1) * rollsPerPage + 1
      local bottomRoll = mathMin(self.currentHistoryPage * rollsPerPage, rollCount)
      
      local fontSize = "medium"
      
      local youWonText = format(" - %s", self:MakeColorCode("00ff00", self.L["You Won!"]))
      local itemButtonTooltipText = format("|n|cffffd706%s:|r %s|n|cffffd706%s-%s:|r %s|n|cffffd706%s-%s:|r %s",
        self.L["Left-Click"], self.L["Check out this item!"],
        self.L["SHIFT"], self.L["Left-Click"], self.L["Link Item to Chat"],
        self.L["CTRL"], self.L["Left-Click"], self.L["View in Dressing Room"]
      )
      
      for i = topRoll, bottomRoll do
        local rollData = results.rolls[i]
        
        local opts = GUI:CreateGroupBox(opts, format("#%s: %s", self:ToFormattedNumber(i), self:GetFriendlyDate(rollData.datetime)))
        
        local charName  = self:GetColoredNameRealmFromGUID(rollData.guid)
        local rollScore = self:Round(self:GetRollScore(rollData.roll, rollData.min, rollData.max) * 100, 0.1)
        
        if rollData.manual then
          
          GUI:CreateDescription(opts, format(self.L["%s rolls %s (%s-%s)"], charName, self:ToFormattedNumber(rollData.roll), self:ToFormattedNumber(rollData.min), self:ToFormattedNumber(rollData.max)), fontSize)
        else
          local pattern = self.L["%s rolls %d (%s)"]
          if rollData.won then
            pattern = pattern .. youWonText
          end
          GUI:CreateDescription(opts, format(pattern, charName, rollData.roll, ROLL_TYPE_NAMES[rollData.rollType]), fontSize)
        end
        
        if not self:IsStandardRoll(rollData.min, rollData.max) then
          GUI:CreateDescription(opts, format("%s %s%%", self.L["Score:"], self:Round(self:GetRollScore(rollData.roll, rollData.min, rollData.max) * 100, 0.1)), fontSize)
        end
        
        if rollData.luckyItems then
          local itemNames = {}
          for itemID in self:Ordered(rollData.luckyItems) do
            itemNames[#itemNames+1] = self.luckyItemNames[itemID]
          end
          GUI:CreateDescription(opts, format(self.L["%d |4item:items; in inventory"] .. ":  %s", #itemNames, tblConcat(itemNames, " & ")), fontSize)
        end
        
        if not rollData.manual then
          
          GUI:CreateDescription(opts, format("%s: %d", self.L["Players"], rollData.numPlayers), fontSize)
          
          do
            local item      = self.ItemCache(rollData.itemLink)
            local colorCode = ITEM_QUALITY_COLORS[item:GetQuality()].hex
            local itemName  = format("%s %s%s", self:MakeIcon(item:GetIcon()), colorCode, item:GetName())
            
            local desc = itemButtonTooltipText
            
            GUI:CreateExecute(opts, "item", itemName, desc, function()
              if IsShiftKeyDown() or IsControlKeyDown() then
                HandleModifiedItemClick(item:GetLink())
              else
                ShowUIPanel(ItemRefTooltip)
                if not ItemRefTooltip:IsShown() then
                  ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
                end
                ItemRefTooltip:SetHyperlink(rollData.itemLink)
              end
            end, disabled).width = 2
          end
        end
      end
    end
  end
    
  
  return opts
end



--   ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ 
--  ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ 
--  ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
--  ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
--  ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
--   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ 

local function MakeConfigOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  GUI:SetDBType"Global"
  
  
  -- Display Options
  do
    local opts = GUI:CreateGroup(opts, "Display", self.L["Display"], nil, "tab")
    
    local d = {
      year     = 2004,
      month    = 11,
      monthDay = 23,
      weekday  = 6,
      hour     = 13,
      minute   = 30,
    }
    
    local weekDay = CALENDAR_WEEKDAY_NAMES[d.weekday]
    local month   = CALENDAR_FULLDATE_MONTH_NAMES[d.month]
    
    do
      local patterns = {
        "%5$s %4$s %3$d %1$d",
        "%4$s %3$d %1$d",
        "%5$s %1$d-%2$02d-%3$02d",
        "%1$d-%2$02d-%3$02d",
        "%3$02d-%2$02d-%1$d",
        "%2$02d-%3$02d-%1$d",
      }
      local values = {}
      for _, pattern in ipairs(patterns) do
        values[pattern] = format(pattern, d.year, d.month, d.monthDay, month, weekDay)
      end
      
      GUI:CreateDropdown(opts, {"display", "dateFormat"}, "", desc, values, patterns, disabled).width = 1.3
      
    end
    
    do
      local hour12 = d.hour
      local timeString
      if hour12 == 0 then
        hour12 = 12
        timeString = self.L["%d:%02d AM"]
      elseif hour12 > 12 then
        hour12 = hour12 - 12
        timeString = self.L["%d:%02d PM"]
      end
      
      GUI:CreateDropdown(opts, {"display", "use24hTime"}, "", desc, {[true] = format(self.L["%02d:%02d"], d.hour, d.minute), [false] = format(timeString, hour12, d.minute)}, {true, false}, disabled).width = 0.7
    end
    
  end
  
  -- Addon Memory
  do
    local opts = GUI:CreateGroup(opts, "AddOn Memory", self.L["AddOn Memory"], nil, "tab")
    
    -- Global Roll Limits
    do
      local text = format("%s %s (%s)", self.L["Maximum"], self.L["|4Loot Roll:Loot Rolls;"], self.L["Total"])
      local opts = GUI:CreateGroupBox(opts, text)
      
      GUI:CreateReverseToggle(opts, {"maxRollStorage", "global", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
      do
        local disabled = disabled or not self:GetGlobalOption("maxRollStorage", "global", "enable")
        
        local option = GUI:CreateRange(opts, {"maxRollStorage", "global", "limit"}, self.L["Maximum"], nil, 1000, 1000000, 1, disabled)
        option.width   = 1.3
        option.bigStep = 1000
        option.softMax = 100000
        GUI:CreateExecute(opts, {"maxRollStorage", "global", "limit"}, self.L["Reset"], desc, function()
          self:ResetGlobalOption("maxRollStorage", "global", "enable")
          self:ResetGlobalOption("maxRollStorage", "global", "limit")
        end).width = 0.6
        GUI:CreateNewline(opts)
        
        do
          local totalRolls = self:CountRolls()
          local limit = self:GetGlobalOption("maxRollStorage", "global", "limit")
          
          local disabled = not self:GetGlobalOption("maxRollStorage", "global", "enable") or totalRolls <= limit
          
          do
            local text
            if totalRolls < limit then
              if self:GetGlobalOption("maxRollStorage", "global", "enable") then
                text = format("%s / %s %s (%s%%)", self:ToFormattedNumber(totalRolls), self:ToFormattedNumber(limit), self.L["|4Loot Roll:Loot Rolls;"], self:ToFormattedNumber(totalRolls / limit * 100, 1))
              else
                text = format("%s %s", self:ToFormattedNumber(totalRolls), self.L["|4Loot Roll:Loot Rolls;"])
              end
            else
              text = format("%s / %s %s", self:ToFormattedNumber(totalRolls), self:ToFormattedNumber(limit), self.L["|4Loot Roll:Loot Rolls;"])
              text = format(self.L["%s (Full)"], text)
            end
            GUI:CreateDescription(opts, text).width = 1.3
          end
          
          if totalRolls > 0 then
            do
              local width = 0.7
              if disabled then
                GUI:CreateDescription(opts, " ").width = width
              else
                local text, desc
                if disabled then
                  text = self.L["Delete"]
                else
                  text = format("%s %s", self.L["Delete"], self:ToFormattedNumber(totalRolls - limit))
                  desc = format("%s %s %s", self.L["Delete"], self:ToFormattedNumber(totalRolls - limit), self.L["|4Loot Roll:Loot Rolls;"])
                end
                local option = GUI:CreateExecute(opts, "Trim", text, desc, function()
                  self:TrimRolls()
                  self:FireAddonEvent"RESET_FILTER_CALCULATIONS"
                end, disabled)
                option.width = width
                option.confirm = function() return format(self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], format("%s %s", self:ToFormattedNumber(totalRolls - limit), self.L["|4Loot Roll:Loot Rolls;"])) end
              end
            end
            
            do
              local disabled = false
              local option = GUI:CreateExecute(opts, "Obliterate", self.L["Obliterate"], desc, function()
                self:ResetGlobalOptionQuiet"rolls"
                self:ResetGlobalOptionQuiet"characters"
                self:ResetGlobalOptionQuiet"realms"
                self:FireAddonEvent"RESET_FILTER_CALCULATIONS"
              end, disabled)
              option.width = 0.6
              option.confirm = function() return format(self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], format("%s %s", self:ToFormattedNumber(totalRolls), self.L["|4Loot Roll:Loot Rolls;"])) end
            end
          end
        end
      end
    end
    
    GUI:CreateNewline(opts)
    
    -- Character Roll Limits
    do
      local text = format("%s %s (%s)", self.L["Maximum"], self.L["|4Loot Roll:Loot Rolls;"], self.L["Character"])
      local opts = GUI:CreateGroupBox(opts, text)
      
      GUI:CreateReverseToggle(opts, {"maxRollStorage", "character", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
      do
        local disabled = disabled or not self:GetGlobalOption("maxRollStorage", "character", "enable")
        
        local option = GUI:CreateRange(opts, {"maxRollStorage", "character", "limit"}, self.L["Maximum"], nil, 1000, 1000000, 1, disabled)
        option.width   = 1.3
        option.bigStep = 1000
        option.softMax = 100000
        GUI:CreateExecute(opts, {"maxRollStorage", "character", "limit"}, self.L["Reset"], desc, function()
          self:ResetGlobalOption("maxRollStorage", "character", "enable")
          self:ResetGlobalOption("maxRollStorage", "character", "limit")
        end).width = 0.6
        GUI:CreateNewline(opts)
        
        do
          local disabled = not self:GetGlobalOption("maxRollStorage", "character", "enable")
          
          local oldOpts = opts
          
          local realmIDs = {}
          for i, guid in ipairs(self:GetOrderedGUIDS()) do
            
            local limit = self:GetGlobalOption("maxRollStorage", "character", "limit")
            local totalRolls = self:GetGlobalOptionQuiet("rolls", guid):GetCount()
            local nameRealm = self:GetColoredNameRealmFromGUID(guid)
            local disabled = disabled or totalRolls <= limit
            
            local realmID, realmName = self:GetRealmFromGUID(guid)
            local newRealmID = false
            if realmIDs[#realmIDs] ~= realmName then
              newRealmID = true
              realmIDs[#realmIDs+1] = realmName
            end
            
            if newRealmID then
              opts = GUI:CreateGroupBox(oldOpts, realmName)
            else
              GUI:CreateNewline(opts)
            end
            
            GUI:CreateDescription(opts, nameRealm, "medium").width = 1
            
            do
              local text
              if totalRolls < limit then
                if self:GetGlobalOption("maxRollStorage", "character", "enable") then
                  text = format("%s / %s %s (%s%%)", self:ToFormattedNumber(totalRolls), self:ToFormattedNumber(limit), self.L["|4Loot Roll:Loot Rolls;"], self:ToFormattedNumber(totalRolls / limit * 100, 1))
                else
                  text = format("%s %s", self:ToFormattedNumber(totalRolls), self.L["|4Loot Roll:Loot Rolls;"])
                end
              else
                text = format("%s / %s %s", self:ToFormattedNumber(totalRolls), self:ToFormattedNumber(limit), self.L["|4Loot Roll:Loot Rolls;"])
                text = format(self.L["%s (Full)"], text)
              end
              GUI:CreateDescription(opts, text, "medium").width = 1.1
            end
            
            if totalRolls > 0 then
              do
                local width = 0.7
                if disabled then
                  GUI:CreateDescription(opts, " ").width = width
                else
                  local text, desc
                  if disabled then
                    text = self.L["Delete"]
                  else
                    text = format("%s %s", self.L["Delete"], self:ToFormattedNumber(totalRolls - limit))
                    desc = format("%s %s %s", self.L["Delete"], self:ToFormattedNumber(totalRolls - limit), self.L["|4Loot Roll:Loot Rolls;"])
                  end
                  local option = GUI:CreateExecute(opts, "Trim", text, desc, function()
                    self:TrimRolls(guid)
                    self:FireAddonEvent"RESET_FILTER_CALCULATIONS"
                  end, disabled)
                  option.width = width
                  option.confirm = function() return format(self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], format("%s %s", self:ToFormattedNumber(totalRolls - limit), self.L["|4Loot Roll:Loot Rolls;"])) end
                end
              end
              
              do
                local disabled = false
                local option = GUI:CreateExecute(opts, "Obliterate", self.L["Obliterate"], desc, function()
                  self:DeleteCharacter(guid)
                  self:FireAddonEvent"RESET_FILTER_CALCULATIONS"
                end, disabled)
                option.width = 0.6
                option.confirm = function() return format("%s|n|n%d %s", format(self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], "|n" .. nameRealm), totalRolls, self.L["|4Loot Roll:Loot Rolls;"]) end
              end
            end
          end
          opts = oldOpts
        end
      end
    end
    
    -- Defrag
    do
      local needsDefrag = false
      for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
        needsDefrag = rolls:CanDefrag()
        if needsDefrag then break end
      end
      
      if needsDefrag then
        GUI:CreateNewline(opts)
        
        local opts = GUI:CreateGroupBox(opts, self.L["AddOn Memory"])
        
        local option = GUI:CreateExecute(opts, "Defrag", self.L["Cleanup"], desc, function()
          for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
            rolls:Defrag()
          end
        end, disabled)
        option.width = 0.7
      end
    end
  end
  
  
  return opts
end





--  ██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗      ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝     ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗    ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║    ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝      ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

local function MakeDebugOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  if not self:IsDebugEnabled() then return end
  GUI:SetDBType"Global"
  
  
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  
  GUI:CreateExecute(opts, "reload", self.L["Reload UI"], nil, ReloadUI)
  
  -- Enable
  do
    local opts = GUI:CreateGroup(opts, "Enable", self.L["Enable"])
    
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Debug"])
      GUI:CreateToggle(opts, {"debug"}, self.L["Enable"])
      GUI:CreateNewline(opts)
      
      GUI:CreateToggle(opts, {"debugShowLuaErrors"}, self.L["Display Lua Errors"], nil, disabled).width = 2
      GUI:CreateNewline(opts)
      
      local disabled = not self:GetGlobalOption"debugShowLuaErrors"
      GUI:CreateToggle(opts, {"debugShowLuaWarnings"}, self.L["Lua Warning"], nil, disabled).width = 2
    end
  end
  
  -- Debug Output
  do
    local opts = GUI:CreateGroup(opts, "Output", "Output")
    
    local disabled = not self:GetGlobalOption"debug"
    
    do
      local opts = GUI:CreateGroupBox(opts, "Suppress All")
      
      GUI:CreateToggle(opts, {"debugOutput", "suppressAll"}, self.debugPrefix .. " " .. self.L["Hide messages like this one."], nil, disabled).width = 2
    end
    
    do
      local opts = GUI:CreateGroupBox(opts, "Addon Messages")
      
      local disabled = disabled or self:GetGlobalOption("debugOutput", "suppressAll")
      
      for i, data in ipairs{
        {"onEvent",       "WoW event"},
        {"onAddonEvent",  "Addon event"},
        {"optionSet",     "Option Set"},
        {"cvarSet",       "CVar Set"},
        {"configRefresh", "Config window refreshed"},
      } do
        if i ~= 1 then
          GUI:CreateNewline(opts)
        end
        GUI:CreateToggle(opts, {"debugOutput", data[1]}, format("%d: %s", i, data[2]), nil, disabled).width = 2
      end
    end
    
    do
      local opts = GUI:CreateGroupBox(opts, ADDON_NAME .. " Messages")
      
      local disabled = disabled or self:GetGlobalOption("debugOutput", "suppressAll")
      
      for i, data in ipairs{
        {"rollStarted", "Group Loot roll started"},
        {"rollEnded",   "Group Loot roll ended"},
        
        {"rollAdded",   "Roll stored"},
        {"rollRemoved", "Roll deleted"},
        
        {"rollsFilterReset",     "Rolls filtering reset"},
        {"rollsFilterStarted",   "Rolls filtering started"},
        {"rollFilterProgress",   "Rolls filtering progress"},
        {"countUncachedItems",   "Count uncached items"},
        {"rollItemsCached",      "Roll Items cached"},
        {"rollsFilterCompleted", "Rolls filtering complete"},
        
        {"charDeleted", "Character deleted"},
      } do
        if i ~= 1 then
          GUI:CreateNewline(opts)
        end
        GUI:CreateToggle(opts, {"debugOutput", data[1]}, format("%d: %s", i, data[2]), nil, disabled).width = 2
      end
    end
  end
  
  
  
  -- Filter
  do
    local opts = GUI:CreateGroup(opts, "Filter", "Filter")
    
    local option = GUI:CreateRange(opts, {"calculations", "filterSpeed"}, self.L["Speed"], nil, 1, 1000000, 1, disabled)
    option.width   = 2
    option.bigStep = 10
    option.softMin = 10
    option.softMax = 1000
    GUI:CreateReset(opts, {"calculations", "filterSpeed"})
    GUI:CreateNewline(opts)
    
    GUI:CreateToggle(opts, {"calculations", "refreshAfterFilter"}, "Refresh after filter")
    GUI:CreateReset(opts, {"calculations", "refreshAfterFilter"})
    GUI:CreateNewline(opts)
    
    GUI:CreateToggle(opts, {"calculations", "startImmediately"}, "Start immediately")
    GUI:CreateReset(opts, {"calculations", "startImmediately"})
  end
  
  
  return opts
end




--   █████╗ ██████╗ ██████╗  ██████╗ ███╗   ██╗     ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗████╗  ██║    ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ███████║██║  ██║██║  ██║██║   ██║██╔██╗ ██║    ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██╔══██║██║  ██║██║  ██║██║   ██║██║╚██╗██║    ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ██║  ██║██████╔╝██████╔╝╚██████╔╝██║ ╚████║    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--  ╚═╝  ╚═╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

function Addon:MakeAddonOptions(chatCmd)
  local title = format("%s %s v%s (/%s)", self:MakeIcon("Interface\\AddOns\\" .. ADDON_NAME .. "\\Assets\\Textures\\Addon Image.png"), ADDON_NAME, tostring(self:GetGlobalOption"version"), chatCmd)
  
  local sections = {}
  for _, data in ipairs{
    -- {MakeGeneralOptions, ADDON_NAME},
    {MakeFilterOptions,  self.L["Filters"], "filters"},
    {MakeHistoryOptions, self.L["History"], "history"},
    {MakeConfigOptions,  self.L["Options"], "options", "config"},
    
    -- {MakeProfileOptions, "Profiles",             "profiles"},
    {MakeDebugOptions,   self.L["Debug"],        "debug"},
  } do
    
    local func = data[1]
    local name = data[2]
    local args = {unpack(data, 3)}
    
    tinsert(sections, function(opts) return func(opts, name) end)
    
    local function OpenOptions() return self:OpenConfig(name) end
    if name == self.L["Debug"] then
      local OpenOptions_Old = OpenOptions
      OpenOptions = function(...)
        if not self:GetGlobalOption"debug" then
          self:SuspendConfigRefreshingWhile(function()
            self:SetGlobalOption(true, "debug")
            self:Debug"Debug mode enabled"
          end)
        end
        return OpenOptions_Old(...)
      end
    end
    
    for _, arg in ipairs(args) do
      self:RegisterChatArgAliases(arg, OpenOptions)
    end
  end
  
  self.AceConfig:RegisterOptionsTable(ADDON_NAME, function()
    self:DebugIfOutput("configRefresh", "Config refreshed")
    
    local GUI = self.GUI:ResetOrder()
    local opts = GUI:CreateOpts(title, "tab")
    
    for _, func in ipairs(sections) do
      GUI:ResetDBType()
      self:xpcall(function()
        func(opts)
      end)
      GUI:ResetDBType()
    end
    
    return opts
  end)
  
  self.AceConfigDialog:SetDefaultSize(ADDON_NAME, 700, 800) -- default is (700, 500)
end


function Addon:MakeBlizzardOptions(chatCmd)
  local title = format("%s %s v%s (/%s)", self:MakeIcon("Interface\\AddOns\\" .. ADDON_NAME .. "\\Assets\\Textures\\Addon Image.png"), ADDON_NAME, tostring(self:GetGlobalOption"version"), chatCmd)
  local panel = self:CreateBlizzardOptionsCategory(function()
    local GUI = self.GUI:ResetOrder()
    local opts = GUI:CreateOpts(title, "tab")
    
    GUI:CreateExecute(opts, "key", ADDON_NAME .. " " .. self.L["Options"], nil, function()
      self:CloseBlizzardConfig()
      self:OpenConfig()
    end)
    
    return opts
  end)
end


