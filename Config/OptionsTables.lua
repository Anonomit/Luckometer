
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



local strGmatch = string.gmatch
local strGsub   = string.gsub
local strByte   = string.byte

local tinsert   = table.insert
local tblConcat = table.concat

local mathMin   = math.min
local mathMax   = math.max












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
  local disabled
  
  do
    local opts = GUI:CreateGroupBox(opts, self.L["Filters"])
    
    do
      GUI:CreateToggle(opts, {"filters", "rollType", "group"}, self.L["Group Loot"], nil, disabled or not self:GetGlobalOption("filters", "rollType", "manual"))
      GUI:CreateToggle(opts, {"filters", "rollType", "manual"}, self.L["/roll"],     nil, disabled or not self:GetGlobalOption("filters", "rollType", "group"))
      GUI:CreateNewline(opts)
    end
    
    do
      local opts = GUI:CreateGroupBox(opts, self.L["Win"])
      
      local disabled = not self:GetGlobalOption("filters", "rollType", "group")
      GUI:CreateToggle(opts, {"filters", "rollWon", 1}, self.L["Yes"], nil, disabled or not self:GetGlobalOption("filters", "rollWon", 0))
      GUI:CreateToggle(opts, {"filters", "rollWon", 0}, self.L["No"],  nil, disabled or not self:GetGlobalOption("filters", "rollWon", 1))
      GUI:CreateNewline(opts)
    end
    
    
    -- local characterInfo = {
    --   realms  = {},
    --   names   = {},
    --   classes = {},
    --   races   = {},
    --   sexes   = {},
    -- }
    -- for guid in pairs(self:GetGlobalOptionQuiet("characters")) do
    --   local realmID, realmName = Addon:GetRealmFromGUID(guid)
    --   local className, classFilename, raceName, raceFilename, sex, characterName = GetPlayerInfoByGUID(guid)
      
    -- end
    
    
    
  end
  
  
  do
    GUI:CreateExecute(opts, "Search", self.L["Search"], desc, function() Addon:StartRollCalculations() Addon:NotifyChange() end, self.rollResults.progress)
  end
  
  
  
  
  if self.rollResults.results or self.rollResults.progress then
    local opts = GUI:CreateGroupBox(opts, self.L["Loot Rolls"])
    
    
    local results = self.rollResults.results
    
    if results then
      GUI:CreateDescription(opts, format("%s: %s",  self.L["Loot Rolls"], self:ToFormattedNumber(results.count,        0)))
      GUI:CreateDescription(opts, format("%s: %s",  self.L["Total"],      self:ToFormattedNumber(results.totalRoll,    0)))
      GUI:CreateDescription(opts, format("%s: %s",  self.L["Average"],    self:ToFormattedNumber(results.avgRoll,      1)))
      GUI:CreateDescription(opts, format("%s %s%%", self.L["Score:"],     self:ToFormattedNumber(results.avgScore*100, 1)))
      
      -- if #rolls > 0 then
      --   local d = C_DateAndTime.GetCalendarTimeFromEpoch(rolls[#rolls].datetime*1e6)
        
      --   local weekDay = CALENDAR_WEEKDAY_NAMES[d.weekday]
      --   local month   = CALENDAR_FULLDATE_MONTH_NAMES[d.month]
        
      --   local text = format("The last roll was at %02d:%02d, %s, %d %s %d", d.hour, d.minute, weekDay, d.monthDay, month, d.year)
      --   GUI:CreateDescription(opts, text)
        
      -- end
    elseif self.rollResults.progress then
      -- GUI:CreateDescription(opts, format("%s%%", self:ToFormattedNumber(self.rollResults.progress*100, 0)))
      GUI:CreateDescription(opts, self.L["Searching..."])
    end
    
    
  end
  
  
  
  GUI:ResetDBType()
  return opts
end





local function MakeConfigOptions(opts, categoryName)
  local self = Addon
  local GUI = self.GUI
  local opts = GUI:CreateGroup(opts, categoryName, categoryName, nil, "tab")
  
  
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
    local opts = GUI:CreateGroup(opts, GUI:Order(), self.L["Enable"])
    
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
    local opts = GUI:CreateGroup(opts, GUI:Order(), "Output")
    
    local disabled = not self:GetGlobalOption"debug"
    
    do
      local opts = GUI:CreateGroupBox(opts, "Suppress All")
      
      GUI:CreateToggle(opts, {"debugOutput", "suppressAll"}, self.debugPrefix .. " " .. self.L["Hide messages like this one."], nil, disabled).width = 2
    end
    
    do
      local opts = GUI:CreateGroupBox(opts, "Message Types")
      
      local disabled = disabled or self:GetGlobalOption("debugOutput", "suppressAll")
      
      for i, data in ipairs{
        {"optionSet",                 "Option Set"},
        {"cvarSet",                   "CVar Set"},
        {"InterfaceOptionsFrameFix",  "Interface Options Patch"},
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


