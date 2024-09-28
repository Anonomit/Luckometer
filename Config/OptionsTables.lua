
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



local function GetOrderedGUIDS()
  local orderedGUIDs = {}
  local guidData     = {}
  for guid, charData in pairs(Addon:GetGlobalOptionQuiet("characters")) do
    orderedGUIDs[#orderedGUIDs+1] = guid
    guidData[guid] = {charData.name, Addon:GetRealmFromGUID(guid)}
  end
  
  tblSort(orderedGUIDs, function(a, b)
    local nameA, realmA, realmNameA = unpack(guidData[a])
    local nameB, realmB, realmNameB = unpack(guidData[b])
    
    if realmA ~= realmB then
      if realmB == GetRealmID() then
        return false
      else
        return realmA == GetRealmID() or realmNameA < realmNameB
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

local function MakeGeneralOptions(opts)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, ADDON_NAME, ADDON_NAME, nil, "tab")
  GUI:SetDBType"Global"
  
  
  local rollResults = self.rollResults
  
  do
    local opts = GUI:CreateGroupBox(opts, self.L["Loot Rolls"])
    
    
    local results = rollResults.results
    
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
      local processing = rollResults.progress and rollResults.notify
      local disabled = not not (processing or rollResults.results)
      
      GUI:CreateNewline(opts)
      GUI:CreateExecute(opts, "Search", processing and self.L["Processing..."] or self.L["Click to Research"], desc, function() Addon:StartRollCalculations(true) Addon:NotifyChange() end, disabled)
    end
    
  end
  
  
  do
    local opts = GUI:CreateGroupBox(opts, self.L["Loot Rolls"])
    
    do
      local color = not self:GetGlobalOption("filters", "rollType", "group") and not self:GetGlobalOption("filters", "rollType", "manual") and "|cffff0000" or ""
      GUI:CreateToggle(opts, {"filters", "rollType", "group"},  color .. self.L["Group Loot"], nil, disabled)
      GUI:CreateToggle(opts, {"filters", "rollType", "manual"}, color .. self.L["/roll"],      nil, disabled)
      GUI:CreateNewline(opts)
    end
    
    
  end
  
  do
    local opts = GUI:CreateGroup(opts, "Character", self.L["Character"], nil, "tab")
    
    local realmIDs   = {}
    local orderedGUIDs = GetOrderedGUIDS()
    local validFilter = false
    for i, guid in ipairs(orderedGUIDs) do
      validFilter = validFilter or self:GetGlobalOptionQuiet("filters", "character", guid)
      if validFilter then break end
    end
    for i, guid in ipairs(orderedGUIDs) do
      local realmID, realmName = self:GetRealmFromGUID(guid)
      local newRealmID = false
      if realmIDs[#realmIDs] ~= realmName then
        newRealmID = true
        realmIDs[#realmIDs+1] = realmName
      end
      
      if newRealmID then
        GUI:CreateExecute(opts, "Enable" .. realmID, format("%s %s", self.L["Enable"], realmName), desc, function()
          for guid in pairs(self:GetGlobalOptionQuiet"characters") do
            if self:GetRealmFromGUID(guid) == realmID then
              self:SetGlobalOption(true, "filters", "character", guid)
            end
          end
        end, disabled).width = 1.3
        GUI:CreateExecute(opts, "Disable" .. realmID, format("%s %s", self.L["Disable"], realmName), desc, function()
          for guid in pairs(self:GetGlobalOptionQuiet"characters") do
            if self:GetRealmFromGUID(guid) == realmID then
              self:SetGlobalOption(false, "filters", "character", guid)
            end
          end
        end, disabled).width = 1.3
        GUI:CreateNewline(opts)
      end
      
      local nameRealm
      if validFilter then
        local coloredRealm = format("|cff%s%s|r", #realmIDs % 2 == 1 and "ffffff" or "eba5ff", realmName)
        nameRealm = format("%s-%s", self:GetColoredNameFromGUID(guid), coloredRealm)
      else
        nameRealm = format("|cffff0000%s-%s|r", self:GetNameFromGUID(guid), realmName)
      end
      
      if i ~= 1 then
        GUI:CreateNewline(opts)
      end
      GUI:CreateToggle(opts, {"filters", "character", guid}, nameRealm, nil, disabled).width = 2
    end
  end
  
  do
    local opts = GUI:CreateGroup(opts, "Group Loot", self.L["Group Loot"], nil, "tab")
    
    local disabled = not self:GetGlobalOption("filters", "rollType", "group")
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Win"])
      
      local color = not self:GetGlobalOption("filters", "rollWon", 0) and not self:GetGlobalOption("filters", "rollWon", 1) and "|cffff0000" or ""
      GUI:CreateToggle(opts, {"filters", "rollWon", 1}, color .. self.L["Yes"], nil, disabled)
      GUI:CreateToggle(opts, {"filters", "rollWon", 0}, color .. self.L["No"],  nil, disabled)
      GUI:CreateNewline(opts)
    end
    
    do
      local validFilter = false
      for i in ipairs(QUALITY_NAMES) do
        validFilter = validFilter or self:GetGlobalOptionQuiet("filters", "itemQuality", i)
        if validFilter then break end
      end
      
      local color = validFilter and "" or "|cffff0000"
      GUI:CreateMultiDropdown(opts, {"filters", "itemQuality"}, color .. self.L["Item Quality"], desc, QUALITY_NAMES, disabled).width = 2
    end
  end
  
  do
    local opts = GUI:CreateGroup(opts, "/roll", self.L["/roll"], nil, "tab")
    
    local disabled = not self:GetGlobalOption("filters", "rollType", "manual")
    
    do
      GUI:CreateExecute(opts, "Unlimited", self.L["Unlimited"], desc, function()
        self:SetGlobalOption(false,   "filters", "rollLimits", "min", "enable")
        self:SetGlobalOption(0,       "filters", "rollLimits", "min", "min")
        self:SetGlobalOption(1000000, "filters", "rollLimits", "min", "max")
        self:SetGlobalOption(false,   "filters", "rollLimits", "max", "enable")
        self:SetGlobalOption(0,       "filters", "rollLimits", "max", "min")
        self:SetGlobalOption(1000000, "filters", "rollLimits", "max", "max")
      end, disabled).width = 0.7
      GUI:CreateExecute(opts, "1-100", "1-100", desc, function()
        self:SetGlobalOption(true, "filters", "rollLimits", "min", "enable")
        self:SetGlobalOption(1,    "filters", "rollLimits", "min", "min")
        self:SetGlobalOption(1,    "filters", "rollLimits", "min", "max")
        self:SetGlobalOption(true, "filters", "rollLimits", "max", "enable")
        self:SetGlobalOption(100,  "filters", "rollLimits", "max", "min")
        self:SetGlobalOption(100,  "filters", "rollLimits", "max", "max")
      end, disabled).width = 0.7
      GUI:CreateExecute(opts, "1-99", "1-2 -> 1-99", desc, function()
        self:SetGlobalOption(true, "filters", "rollLimits", "min", "enable")
        self:SetGlobalOption(1,    "filters", "rollLimits", "min", "min")
        self:SetGlobalOption(1,    "filters", "rollLimits", "min", "max")
        self:SetGlobalOption(true, "filters", "rollLimits", "max", "enable")
        self:SetGlobalOption(2,    "filters", "rollLimits", "max", "min")
        self:SetGlobalOption(99,   "filters", "rollLimits", "max", "max")
      end, disabled).width = 0.7
    end
    
    GUI:CreateNewline(opts)
    
    do
      GUI:CreateReverseToggle(opts, {"filters", "rollLimits", "min", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
      do
        local disabled = disabled or not self:GetGlobalOption("filters", "rollLimits", "min", "enable")
        
        local option = GUI:CreateRange(opts, {"filters", "rollLimits", "min", "min"}, self.L["Minimum"], nil, 0, 1000000, 1, disabled)
        option.softMax = 100
        option.set = function(info, val) self:SetGlobalOptionConfig(val, "filters", "rollLimits", "min", "min") self:SetGlobalOptionConfig(mathMax(val, self:GetGlobalOption("filters", "rollLimits", "min", "max")), "filters", "rollLimits", "min", "max") end
        local option = GUI:CreateRange(opts, {"filters", "rollLimits", "min", "max"}, self.L["Maximum"], nil, 0, 1000000, 1, disabled)
        option.softMax = 100
        option.set = function(info, val) self:SetGlobalOptionConfig(val, "filters", "rollLimits", "min", "max") self:SetGlobalOptionConfig(mathMin(val, self:GetGlobalOption("filters", "rollLimits", "min", "min")), "filters", "rollLimits", "min", "min") end
      end
    end
    
    GUI:CreateNewline(opts)
    
    do
      GUI:CreateReverseToggle(opts, {"filters", "rollLimits", "max", "enable"}, self.L["Unlimited"], nil, disabled).width = 0.7
      do
        local disabled = disabled or not self:GetGlobalOption("filters", "rollLimits", "max", "enable")
        
        local option = GUI:CreateRange(opts, {"filters", "rollLimits", "max", "min"}, self.L["Minimum"], nil, 0, 1000000, 1, disabled)
        option.softMax = 200
        local option = GUI:CreateRange(opts, {"filters", "rollLimits", "max", "max"}, self.L["Maximum"], nil, 0, 1000000, 1, disabled)
        option.softMax = 200
      end
    end
    
    -- GUI:CreateDivider(opts, 3)
    
    -- do
    --   local opts = GUI:CreateGroupBox(opts, self.L["Loot Rolls"])
      
    --   GUI:CreateDescription(opts, )
      
    -- end
    
    
  end
  
  
  GUI:ResetDBType()
  return opts
end


local function MakeFilterOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  GUI:SetDBType"Global"
  
  
  
  
  GUI:ResetDBType()
  return opts
end



local function MakeConfigOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  
  
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
        {"countUncachedRolls", "Count uncached rolls"},
        {"rollsCached",        "Rolls cached"},
        
        {"optionsOpenedPre",  "Options Window Opened (Pre)"},
        {"optionsOpenedPost", "Options Window Opened (Post)"},
        {"optionsClosedPost", "Options Window Closed (Post)"},
        {"optionSet",         "Option Set"},
        {"cvarSet",           "CVar Set"},
      } do
        if i ~= 1 then
          GUI:CreateNewline(opts)
        end
        GUI:CreateToggle(opts, {"debugOutput", data[1]}, data[2], nil, disabled).width = 2
      end
    end
  end
  
  GUI:ResetDBType()
  
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
    {MakeGeneralOptions, nil},
    -- {MakeFilterOptions,  self.L["Filters"], "filters"},
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
          self:SetGlobalOption(true, "debug")
          self:Debug("Debug mode enabled")
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


