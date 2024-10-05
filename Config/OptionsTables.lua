
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



local strGmatch = string.gmatch
local strGsub   = string.gsub
local strByte   = string.byte

local tinsert   = table.insert
local tblConcat = table.concat
local tblSort   = table.sort

local mathMin   = math.min
local mathMax   = math.max







local name, desc, disabled





local QUALITY_NAMES = {}
for i = 0, 5 do
  QUALITY_NAMES[i] = ITEM_QUALITY_COLORS[i].hex .. _G["ITEM_QUALITY" .. i .. "_DESC"]
end


local FACTION_SORT = Addon:MakeLookupTable{"Alliance", "Horde", "Neutral", "Unknown"}

local function GetOrderedGUIDS()
  local orderedGUIDs = {}
  local guidData     = {}
  for guid, charData in pairs(Addon:GetGlobalOptionQuiet("characters")) do
    orderedGUIDs[#orderedGUIDs+1] = guid
    guidData[guid] = {charData.name, FACTION_SORT[Addon:GetFactionFromGUID(guid)], Addon:GetRealmFromGUID(guid)}
  end
  
  tblSort(orderedGUIDs, function(a, b)
    local nameA, factionA, realmA, realmNameA = unpack(guidData[a])
    local nameB, factionB, realmB, realmNameB = unpack(guidData[b])
    
    if realmA ~= realmB then
      if realmB == GetRealmID() then
        return false
      else
        return realmA == GetRealmID() or realmNameA < realmNameB
      end
    elseif factionA ~= factionB then
      if factionB == Addon.MY_FACTION then
        return false
      else
        return factionA == Addon.MY_FACTION or factionA < factionB
      end
    elseif nameA ~= nameB then
      if nameB == Addon.MY_NAME then
        return false
      else
        return nameA == Addon.MY_NAME or nameA < nameB
      end
    else
      if b == Addon.MY_GUID then
        return false
      else
        return a == Addon.MY_GUID or a < b
      end
    end
  end)
  
  return orderedGUIDs
end





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






--  ███████╗████████╗ █████╗ ████████╗███████╗     ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝    ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ███████╗   ██║   ███████║   ██║   ███████╗    ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ╚════██║   ██║   ██╔══██║   ██║   ╚════██║    ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ███████║   ██║   ██║  ██║   ██║   ███████║    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--  ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

local function MakeStatsOptions(opts, categoryName)
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
  
  
  local threadData = self:GetThreadData"RollResults" or {}
  
  -- roll results
  do
    local opts = GUI:CreateGroupBox(opts, self.L["Loot Rolls"])
    
    
    local results = threadData.results
    
    local count    = "???"
    local avgRoll  = "???"
    local avgScore = "???"
    if results then
      count = self:ToFormattedNumber(results.count, 0)
      if results.count > 0 then
        avgRoll  = self:ToFormattedNumber(results.avgRoll,      1) .. " (1-100)"
        avgScore = self:ToFormattedNumber(results.avgScore*100, 1) .. "%"
      else
        avgRoll  = self.L["N/A"]
        avgScore = self.L["N/A"]
      end
    end
    
    
    GUI:CreateDescription(opts, format("%s: %s", self.L["Loot Rolls"], count))
    GUI:CreateDescription(opts, format("%s: %s", self.L["Average"],    avgRoll))
    GUI:CreateDescription(opts, format("%s %s",  self.L["Score:"],     avgScore))
    
    do
      local processing = not self:IsThreadDead"RollResults" and threadData.notify
      local disabled = not not (processing or threadData.results)
      
      GUI:CreateNewline(opts)
      GUI:CreateExecute(opts, "Search", processing and self.L["Processing..."] or disabled and self.L["Research Complete"] or self.L["Click to Research"], desc, function() Addon:StartRollCalculations(true) Addon:NotifyChange() end, disabled)
    end
  end
  
  -- filters
  if hasRolls then
    -- character filters
    do
      local opts = GUI:CreateGroup(opts, "Character", self.L["Character"], nil, "tab")
      
      -- character selection
      do
        local opts = GUI:CreateGroup(opts, self.L["Select"], self.L["Select"], nil, "tab")
        
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
            self:ResetGlobalOptionConfigQuiet("filters", "character", "guid")
            self:NotifyChange()
          end, disabled).width = 0.5
          GUI:CreateExecute(opts, "None", self.L["None"], desc, function()
            for guid in pairs(self:GetGlobalOptionQuiet"characters") do
              self:SetGlobalOptionConfig(false, "filters", "character", "guid", guid)
            end
            self:NotifyChange()
          end, disabled).width = 0.5
          GUI:CreateExecute(opts, "Me", self.L["Me"], desc, function()
            for guid in pairs(self:GetGlobalOptionQuiet"characters") do
              self:SetGlobalOptionConfig(guid == self.MY_GUID, "filters", "character", "guid", guid)
            end
            self:NotifyChange()
          end, disabled).width = 0.5
          
          if self:CountKeys(factions) > 1 then
            GUI:CreateNewline(opts)
            for _, faction in ipairs{self.L["Alliance"], self.L["Horde"], self.L["Neutral"], self.L["Unknown"]} do
              if factions[faction] then
                GUI:CreateExecute(opts, faction, self.L[faction], desc, function()
                  for guid, charData in pairs(self:GetGlobalOptionQuiet"characters") do
                    self:SetGlobalOptionConfig(self:GetFactionFromGUID(guid) == faction, "filters", "character", "guid", guid)
                  end
                  self:NotifyChange()
                end, disabled).width = 0.5
              end
            end
          end
          
          if self:CountKeys(sexes) > 1 then
            GUI:CreateNewline(opts)
            local SEX_IDS = {Male = 0, Female = 1}
            for _, sex in ipairs{"Male", "Female"} do
              GUI:CreateExecute(opts, sex, self.L[sex], desc, function()
                for guid, charData in pairs(self:GetGlobalOptionQuiet"characters") do
                  self:SetGlobalOptionConfig(charData.sex == SEX_IDS[sex], "filters", "character", "guid", guid)
                end
                self:NotifyChange()
              end, disabled).width = 0.5
            end
          end
          
          GUI:CreateDescription(opts, format("%d %s", totalRolls, self.L["|4Loot Roll:Loot Rolls;"]))
        end
        
        GUI:CreateNewline(opts)
        
        local oldOpts = opts
        
        local realmIDs = {}
        for i, guid in ipairs(GetOrderedGUIDS()) do
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
            -- GUI:CreateDescription(opts, format("%s:", realmName))
            GUI:CreateExecute(opts, "Enable" .. realmID, self.L["Enable All"], desc, function()
              for guid in pairs(self:GetGlobalOptionQuiet"characters") do
                if self:GetRealmFromGUID(guid) == realmID then
                  self:SetGlobalOptionConfig(true, "filters", "character", "guid", guid)
                end
              end
              self:NotifyChange()
            end, disabled).width = 0.8
            GUI:CreateExecute(opts, "Disable" .. realmID, self.L["Disable All"], desc, function()
              for guid in pairs(self:GetGlobalOptionQuiet"characters") do
                if self:GetRealmFromGUID(guid) == realmID then
                  self:SetGlobalOptionConfig(false, "filters", "character", "guid", guid)
                end
              end
              self:NotifyChange()
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
          GUI:CreateToggle(opts, {"filters", "character", "guid", guid}, format("%s  (%d %s)", nameRealm, charRolls, self.L["|4Loot Roll:Loot Rolls;"]), nil, disabled).width = 1.8
          local option = GUI:CreateExecute(opts, "Obliterate", self.L["Obliterate"], desc, function() self:DeleteCharacter(guid) end, disabled)
          option.width = 0.7
          option.confirm = function() return format("%s|n|n%d %s", format(self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], self:GetColoredNameRealmFromGUID(guid)), charRolls, self.L["|4Loot Roll:Loot Rolls;"]) end
        end
        opts = oldOpts
      end
      
      -- level filters
      do
        local opts = GUI:CreateGroup(opts, self.L["Level"], self.L["Level"], nil, "tab")
          
        local maxCharLevel = Addon.MAX_LEVEL
        
        do
          local opts = GUI:CreateGroupBox(opts, self.L["Select"])
          
          GUI:CreateExecute(opts, "Unlimited", self.L["Unlimited"], desc, function()
            self:SetGlobalOptionConfig(false,       "filters", "character", "level", "enable")
            self:SetGlobalOptionConfig(1,           "filters", "character", "level", "min")
            self:SetGlobalOptionConfig(maxCharLevel,"filters", "character", "level", "max")
            self:NotifyChange()
          end, disabled).width = 0.7
          GUI:CreateExecute(opts, "Max Level", self.L["Max Level"], desc, function()
            self:SetGlobalOptionConfig(true,         "filters", "character", "level", "enable")
            self:SetGlobalOptionConfig(maxCharLevel, "filters", "character", "level", "min")
            self:SetGlobalOptionConfig(maxCharLevel, "filters", "character", "level", "max")
            self:NotifyChange()
          end, disabled).width = 0.7
          GUI:CreateExecute(opts, "Below Max Level", format(self.L["%d-%d"], 1, maxCharLevel-1), desc, function()
            self:SetGlobalOptionConfig(true,           "filters", "character", "level", "enable")
            self:SetGlobalOptionConfig(1,              "filters", "character", "level", "min")
            self:SetGlobalOptionConfig(maxCharLevel-1, "filters", "character", "level", "max")
            self:NotifyChange()
          end, disabled).width = 0.7
          
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
              self:SetGlobalOptionConfig(val, "filters", "character", "level", "min")
              self:SetGlobalOptionConfig(mathMax(val,   self:GetGlobalOption("filters", "character", "level", "max")), "filters", "character", "level", "max")
            end
            local option = GUI:CreateRange(opts, {"filters", "character", "level", "max"}, self.L["Maximum"], nil, 1, 120, 1, disabled)
            option.softMax = maxCharLevel
            option.set = function(info, val)
              self:SetGlobalOptionConfig(val, "filters", "character", "level", "max")
              self:SetGlobalOptionConfig(mathMin(val, self:GetGlobalOption("filters", "character", "level", "min")), "filters", "character", "level", "min")
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
        GUI:CreateToggle(opts, {"filters", "group", "enable"},  color .. self.L["Enable"], nil, disabled)
      end
      
      local disabled = not self:GetGlobalOption("filters", "group", "enable")
      do
        local opts = GUI:CreateGroupBox(opts, self.L["Win"])
        
        local color = not self:GetGlobalOption("filters", "group", "roll", "won", 0) and not self:GetGlobalOption("filters", "group", "roll", "won", 1) and "|cffff0000" or ""
        GUI:CreateToggle(opts, {"filters", "group", "roll", "won", 1}, color .. self.L["Yes"], nil, disabled)
        GUI:CreateToggle(opts, {"filters", "group", "roll", "won", 0}, color .. self.L["No"],  nil, disabled)
      end
      
      GUI:CreateNewline(opts)
      
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
          
          local option = GUI:CreateRange(opts, {"filters", "group", "item", "level", "min"}, self.L["Minimum"], nil, 0, 999, 1, disabled)
          option.softMax = maxItemLevel - 1
          option.set = function(info, val)
            self:SetGlobalOptionConfig(val, "filters", "group", "item", "level", "min")
            self:SetGlobalOptionConfig(mathMax(val,   self:GetGlobalOption("filters", "group", "item", "level", "max")), "filters", "group", "item", "level", "max")
          end
          local option = GUI:CreateRange(opts, {"filters", "group", "item", "level", "max"}, self.L["Maximum"], nil, 1, 1000, 1, disabled)
          option.softMax = maxItemLevel
          option.set = function(info, val)
            self:SetGlobalOptionConfig(val, "filters", "group", "item", "level", "max")
            self:SetGlobalOptionConfig(mathMin(val, self:GetGlobalOption("filters", "group", "item", "level", "min")), "filters", "group", "item", "level", "min")
          end
        end
      end
    end
    
    -- roll filters
    do
      local opts = GUI:CreateGroup(opts, "/roll", self.L["/roll"], nil, "tab")
      
      do
        local opts = GUI:CreateGroupBox(opts, self.L["/roll"])
        
        local color = not self:GetGlobalOption("filters", "group", "enable") and not self:GetGlobalOption("filters", "manual", "enable") and "|cffff0000" or ""
        GUI:CreateToggle(opts, {"filters", "manual", "enable"},  color .. self.L["Enable"], nil, disabled)
      end
      
      local disabled = not self:GetGlobalOption("filters", "manual", "enable")
      
      do
        local opts = GUI:CreateGroupBox(opts, self.L["Select"])
        
        GUI:CreateExecute(opts, "Unlimited", self.L["Unlimited"], desc, function()
          self:SetGlobalOptionConfig(false,     "filters", "manual", "roll", "limits", "min", "enable")
          self:SetGlobalOptionConfig(0,         "filters", "manual", "roll", "limits", "min", "min")
          self:SetGlobalOptionConfig(1000000-1, "filters", "manual", "roll", "limits", "min", "max")
          self:SetGlobalOptionConfig(false,     "filters", "manual", "roll", "limits", "max", "enable")
          self:SetGlobalOptionConfig(1,         "filters", "manual", "roll", "limits", "max", "min")
          self:SetGlobalOptionConfig(1000000,   "filters", "manual", "roll", "limits", "max", "max")
          self:NotifyChange()
        end, disabled).width = 0.7
        GUI:CreateExecute(opts, "1-100", format(self.L["%d-%d"], 1, 100), desc, function()
          self:SetGlobalOptionConfig(true, "filters", "manual", "roll", "limits", "min", "enable")
          self:SetGlobalOptionConfig(1,    "filters", "manual", "roll", "limits", "min", "min")
          self:SetGlobalOptionConfig(1,    "filters", "manual", "roll", "limits", "min", "max")
          self:SetGlobalOptionConfig(true, "filters", "manual", "roll", "limits", "max", "enable")
          self:SetGlobalOptionConfig(100,  "filters", "manual", "roll", "limits", "max", "min")
          self:SetGlobalOptionConfig(100,  "filters", "manual", "roll", "limits", "max", "max")
          self:NotifyChange()
        end, disabled).width = 0.7
        GUI:CreateExecute(opts, "1-99", format("%s %s %s", format(self.L["%d-%d"], 1, 2), self.L["-->"], format(self.L["%d-%d"], 1, 99)), desc, function()
          self:SetGlobalOptionConfig(true, "filters", "manual", "roll", "limits", "min", "enable")
          self:SetGlobalOptionConfig(1,    "filters", "manual", "roll", "limits", "min", "min")
          self:SetGlobalOptionConfig(1,    "filters", "manual", "roll", "limits", "min", "max")
          self:SetGlobalOptionConfig(true, "filters", "manual", "roll", "limits", "max", "enable")
          self:SetGlobalOptionConfig(2,    "filters", "manual", "roll", "limits", "max", "min")
          self:SetGlobalOptionConfig(99,   "filters", "manual", "roll", "limits", "max", "max")
          self:NotifyChange()
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
      
      GUI:CreateNewline(opts)
      
      do
        local opts = GUI:CreateGroupBox(opts, self.L["Minimum"])
        
        GUI:CreateReverseToggle(opts, {"filters", "manual", "roll", "limits", "min", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
        do
          local disabled = disabled or not self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "enable")
          
          local option = GUI:CreateRange(opts, {"filters", "manual", "roll", "limits", "min", "min"}, self.L["Minimum"], nil, 0, 1000000-1, 1, disabled)
          option.softMax = 100
          option.set = function(info, val)
            self:SetGlobalOptionConfig(val, "filters", "manual", "roll", "limits", "min", "min")
            self:SetGlobalOptionConfig(mathMax(val,   self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "max")), "filters", "manual", "roll", "limits", "min", "max")
            self:SetGlobalOptionConfig(mathMax(val+1, self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "min")), "filters", "manual", "roll", "limits", "max", "min")
            self:SetGlobalOptionConfig(mathMax(val+1, self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "max")), "filters", "manual", "roll", "limits", "max", "max")
          end
          local option = GUI:CreateRange(opts, {"filters", "manual", "roll", "limits", "min", "max"}, self.L["Maximum"], nil, 0, 1000000-1, 1, disabled)
          option.softMax = 100
          option.set = function(info, val)
            self:SetGlobalOptionConfig(val, "filters", "manual", "roll", "limits", "min", "max")
            self:SetGlobalOptionConfig(mathMin(val, self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "min")), "filters", "manual", "roll", "limits", "min", "min")
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
            self:SetGlobalOptionConfig(val, "filters", "manual", "roll", "limits", "max", "min")
            self:SetGlobalOptionConfig(mathMax(val, self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "max")), "filters", "manual", "roll", "limits", "max", "max")
          end
          local option = GUI:CreateRange(opts, {"filters", "manual", "roll", "limits", "max", "max"}, self.L["Maximum"], nil, 1, 1000000, 1, disabled)
          option.softMax = 200
          option.set = function(info, val)
            self:SetGlobalOptionConfig(val, "filters", "manual", "roll", "limits", "max", "max")
            self:SetGlobalOptionConfig(mathMin(val,   self:GetGlobalOption("filters", "manual", "roll", "limits", "max", "min")), "filters", "manual", "roll", "limits", "max", "min")
            self:SetGlobalOptionConfig(mathMin(val-1, self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "max")), "filters", "manual", "roll", "limits", "min", "max")
            self:SetGlobalOptionConfig(mathMin(val-1, self:GetGlobalOption("filters", "manual", "roll", "limits", "min", "min")), "filters", "manual", "roll", "limits", "min", "min")
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
  
  return opts
end





local function MakeConfigOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  
  -- GUI:CreateToggle(opts, )
  
  return opts
end





--  ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗     ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
--  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝    ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
--  ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗      ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗
--  ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝      ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║
--  ██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗    ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║
--  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

local function MakeProfileOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  
  local profileOptions = self.AceDBOptions:GetOptionsTable(self:GetDB())
  profileOptions.order = GUI:Order()
  opts.args[categoryName] = profileOptions
  
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
      local opts = GUI:CreateGroupBox(opts, "Message Types")
      
      local disabled = disabled or self:GetGlobalOption("debugOutput", "suppressAll")
      
      for i, data in ipairs{
        {"rollAdded", "Roll added"},
        
        {"rollsFilterStarted",   "Rolls filtering started"},
        {"rollFilterProgress",   "Rolls filtering progress"},
        {"countUncachedItems",   "Count uncached items"},
        {"rollItemsCached",      "Roll Items cached"},
        {"rollsFilterCompleted", "Rolls filtering complete"},
        
        {"charDeleted", "Character deleted"},
        
        {"optionsOpenedPre",  "Options Window Opened (Pre)"},
        {"optionsOpenedPost", "Options Window Opened (Post)"},
        {"optionsClosedPost", "Options Window Closed (Post)"},
        {"optionSet",         "Option Set"},
        {"cvarSet",           "CVar Set"},
      } do
        if i ~= 1 then
          GUI:CreateNewline(opts)
        end
        GUI:CreateToggle(opts, {"debugOutput", data[1]}, format("%d: %s", i, data[2]), nil, disabled).width = 2
      end
    end
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
  local title = format("%s v%s  (/%s)", ADDON_NAME, tostring(self:GetOption"version"), chatCmd)
  
  local sections = {}
  for _, data in ipairs{
    -- {MakeGeneralOptions, ADDON_NAME},
    {MakeStatsOptions, self.L["Stats"], "stats"},
    
    -- {MakeConfigOptions,  self.L["Options"], "options"},
    -- {MakeProfileOptions, "Profiles",        "profiles"},
    {MakeDebugOptions,   self.L["Debug"],   "debug"},
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
          self:SetGlobalOptionConfig(true, "debug")
          self:Debug"Debug mode enabled"
          self:NotifyChange()
        end
        return OpenOptions_Old(...)
      end
    end
    
    for _, arg in ipairs(args) do
      self:RegisterChatArgAliases(arg, OpenOptions)
    end
  end
  
  self.AceConfig:RegisterOptionsTable(ADDON_NAME, function()
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
  local title = format("%s v%s  (/%s)", ADDON_NAME, tostring(self:GetOption"version"), chatCmd)
  local panel = self:CreateBlizzardOptionsCategory(function()
    local GUI = self.GUI:ResetOrder()
    local opts = GUI:CreateOpts(title, "tab")
    
    GUI:CreateExecute(opts, "key", ADDON_NAME .. " " .. self.L["Options"], nil, function()
      self:OpenConfig(ADDON_NAME)
      self:CloseBlizzardConfig()
    end)
    
    return opts
  end)
end


