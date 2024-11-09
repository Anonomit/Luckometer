
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)


local AceSerializer = Addon.AceSerializer


local strMatch = string.match

local tblSort   = table.sort
local tblConcat = table.concat

local mathFloor = math.floor




local function VerifyRollData(rollData)
  Addon:ThrowfAssert(rollData.min ~= rollData.max, "Roll contains no entropy. %s-%s", tostring(rollData.min), tostring(rollData.max))
  Addon:ThrowAssert(rollData.manual or rollData.itemLink, "Group Loot roll doesn't contain an itemlink")
  
  return rollData
end

do
  local meta = {
    __index = {
      min = 1,
      max = 100,
      -- luckyItems = {},
    },
    __lt = function(self, o)
      if self.datetime ~= o.datetime then
        return self.datetime < o.datetime
      else
        return self.index < o.index
      end
    end,
    __tostring = function(self)
      return Addon:DataToString{
        {"guid",   self.guid},
        {"player", self.guid and Addon:GetColoredNameRealmFromGUID(self.guid) or nil},
        {"index",  self.index},
        
        {"datetime",   self.datetime},
        {"date",       Addon:GetFriendlyDate(self.datetime)},
        {"level",      self.level},
        {"luckyItems", self.luckyItems and format("{%s}", tblConcat(self.luckyItems, ", "))},
        {"roll",       self.roll},
        
        {"type", self.manual and "manual" or "group"},
        
        {"min",  Addon:ShortCircuit(self.min == 1,   nil, self.min)},
        {"max",  Addon:ShortCircuit(self.max == 100, nil, self.max)},
        
        {"numPlayers", self.numPlayers},
        {"itemLink",   self.itemLink},
        {"won",        self.won},
        {"rollType",   self.rollType == 1 and "Need" or self.rollType == 2 and "Greed" or self.rollType == 3 and "Disenchant" or self.rollType},
      }
    end,
  }
  
  function Addon:SerializeRollData(rollData)
    setmetatable(rollData, meta)
    
    if rawget(rollData, "min") == 1 then
      rawset(rollData, "min", nil)
    end
    if rawget(rollData, "max") == 100 then
      rawset(rollData, "max", nil)
    end
    do
      local luckyItems = rawget(rollData, "luckyItems")
      if luckyItems and next(luckyItems) == nil then
        rawset(rollData, "luckyItems", nil)
      end
    end
    rawset(rollData, "index", nil)
    rawset(rollData, "guid",  nil)
    
    return AceSerializer:Serialize(VerifyRollData(rollData))
  end
  
  function Addon:DeserializeRollData(rollString, i, guid)
    local rollData = select(2, AceSerializer:Deserialize(rollString))
    setmetatable(rollData, meta)
    
    if i then
      rawset(rollData, "index", i)
    end
    if guid then
      rawset(rollData, "guid", guid)
    end
    
    return VerifyRollData(rollData)
  end
  
  function Addon:GetRollData(guid, i)
    self:Assert(guid, "Invalid guid: %s", tostring(guid))
    self:Assert(i, "Invalid index: %s", tostring(i))
    local rolls = self:GetGlobalOptionQuiet("rolls", guid)
    self:Assert(rolls, "Can't get rolls for guid: %s", tostring(guid))
    local rollString = rolls[i]
    self:Assert(rolls, "Roll %s doesn't exist for %s (%s)", i, self:GetColoredNameRealmFromGUID(guid), guid)
    
    local rollData = select(2, AceSerializer:Deserialize(rollString))
    setmetatable(rollData, meta)
    
    if i then
      rawset(rollData, "index", i)
    end
    if guid then
      rawset(rollData, "guid", guid)
    end
    
    return VerifyRollData(rollData)
  end
end

do
  local function MapRoll(guid, id, rollString)
    local rollData = Addon:DeserializeRollData(rollString, id, guid)
    return id, rollData
  end

  function Addon:IterRollData(rolls, guid)
    return Addon:MapIter(function(id, rollString) return MapRoll(guid, id, rollString) end, rolls:iter())
  end
end



function Addon:GetFriendlyDate(datetime)
  local d = C_DateAndTime.GetCalendarTimeFromEpoch(datetime*1e6)
  
  local weekDay = CALENDAR_WEEKDAY_NAMES[d.weekday]
  local month   = CALENDAR_FULLDATE_MONTH_NAMES[d.month]
  
  -- local text = format("%02d:%02d, %s, %d %s %d", d.hour, d.minute, weekDay, d.monthDay, month, d.year)
  local text = format("%d-%02d-%02d %02d:%02d", d.year, d.month, d.monthDay, d.hour, d.minute)
  
  return text
end




local function StoreCharacter()
  local self = Addon
  
  local realmID   = GetRealmID()
  local realmName = GetNormalizedRealmName()
  
  if self:ThrowfAssert(realmID and realmName, "Couldn't store realm name/id in db. name: %s, id: %s.", tostring(realmName), tostring(realmID)) then
    if self:GetGlobalOptionQuiet("realms", realmID) ~= realmName then
      self:SetGlobalOption(realmName, "realms", realmID)
    end
  end
  
  if self:ThrowfAssert(self.MY_GUID, "Couldn't store character in db. guid: %s.", tostring(guid)) then
    local characterData = self:GetGlobalOptionQuiet("characters", self.MY_GUID)
    local changed = false
    if not characterData then
      characterData = {}
      changed = true
    end
    for _, data in pairs{
      {"name",  self.MY_NAME},
      {"class", self.MY_CLASS},
      {"race",  self.MY_RACE},
      {"sex",   self.MY_SEX},
    } do
      local k, v = data[1], data[2]
      if characterData[k] ~= v then
        characterData[k] = v
        changed = true
      end
    end
    if changed then
      self:SetGlobalOption(characterData, "characters", self.MY_GUID)
    end
  end
end


function Addon:DeleteCharacter(guid)
  self:Assertf(guid, "Received invalid guid: %s", tostring(guid))
  
  local nameRealm = self:GetColoredNameRealmFromGUID(guid)
  
  local count = 0
  self:RestartFilteringAfter(function()
    self:ResetGlobalOptionQuiet("filters", "character", "guid", guid)
    self:ResetGlobalOptionQuiet("characters", guid)
    
    count = self:GetGlobalOptionQuiet("rolls", guid):GetCount()
    self:ResetGlobalOptionQuiet("rolls", guid)
  end)
  
  self:DebugfIfOutput("charDeleted", "Deleted %s and %d |4roll:rolls;", nameRealm, count)
  return count
end




function Addon:StoreRoll(rollData)
  if (rollData.max or 100) == (rollData.min or 1) then
    -- no entropy to record here
    return
  end
  
  StoreCharacter()
  
  rollData.level      = self.MY_LEVEL
  rollData.luckyItems = self:GetOwnedLuckyItems()
  
  local guid = self.MY_GUID
  
  local rollString = self:SerializeRollData(rollData)
  local rolls = self:GetGlobalOptionQuiet"rolls"
  if not rolls[guid] then
    rolls[guid] = self.IndexedQueue()
  end
  
  local globalCompliance, guidCompliance = true, true
  if self:GetGlobalOption("maxRollStorage", "character", "enable") then
    guidCompliance = rolls[guid]:GetCount() == self:GetGlobalOption("maxRollStorage", "character", "limit")
  end
  if guidCompliance and self:GetGlobalOption("maxRollStorage", "global", "enable") then
    globalCompliance = self:CountRolls() == self:GetGlobalOption("maxRollStorage", "global", "limit")
  end
  
  
  local id = rolls[guid]:Add(rollString)
  if self:GetGlobalOptionQuiet("debugOutput", "rollAdded") then
    self:Debugf("Roll stored for %s (%s)|n%s", self:GetColoredNameRealmFromGUID(guid), guid, tostring(self:DeserializeRollData(rollString, id, guid)))
  end
  
  local trimmed
  if guidCompliance then
    trimmed = self:TrimRolls(guid, 1)
  end
  if globalCompliance and not trimmed then
    self:TrimRolls(nil, 1)
  end
  
  
  self:FireAddonEvent"RESET_FILTER_CALCULATIONS"
  self:RefreshConfig()
end


function Addon:TrimRolls(guid, max)
  local key = guid and "character" or "global"
  if not self:GetGlobalOption("maxRollStorage", key, "enable") then return end
  local limit = self:GetGlobalOption("maxRollStorage", key, "limit")
  
  if guid then
    local rolls = self:GetGlobalOptionQuiet("rolls", guid)
    
    max = max or (rolls:GetCount() - limit)
    
    local count = 0
    while rolls:GetCount() > limit and count < max do
      local head = rolls:GetHead()
      local rollString = rolls:PopHead()
      self:DebugfIfOutput("rollRemoved", "Deleted roll:|n%s", tostring(self:DeserializeRollData(rollString, head, guid)))
      count = count + 1
    end
    
    if count > 0 then
      self:DebugfIfOutput("rollRemoved", "Trimmed %d rolls from %s", self:ToFormattedNumber(count), guid)
      -- rolls:Defrag()
      return true
    end
  else
    local total = self:CountRolls()
    
    max = max or (total - limit)
    
    local count = 0
    local guidRolls = {}
    for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
      guidRolls[#guidRolls+1] = {self:IterRollData(rolls, guid)}
    end
    local oldestRolls = Addon:MergeSorted(guidRolls, nil, max)
    
    for _, roll in ipairs(oldestRolls) do
      local rolls = self:GetGlobalOptionQuiet("rolls", roll.guid)
      rolls[roll.index] = nil
      self:DebugfIfOutput("rollRemoved", "Deleted roll:|n%s", tostring(roll))
      count = count + 1
    end
    
    if count > 0 then
      self:DebugfIfOutput("rollRemoved", "Trimmed %d rolls", self:ToFormattedNumber(count))
      for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
        -- rolls:Defrag()
      end
      return true
    end
  end
end



function Addon:CountRolls()
  local total = 0
  for guid, rolls in pairs(Addon:GetGlobalOptionQuiet"rolls") do
    total = total + rolls:GetCount()
  end
  return total
end



function Addon:GetEarliestRollAfter(datetime, guid)
  self:Assert(guid, "guid is %s", tostring(guid))
  local rolls = self:GetGlobalOptionQuiet("rolls", guid)
  self:Assert(rolls, "rolls is %s", tostring(rolls))
  self:Assert(not rolls:CanDefrag(), "rolls for %s (%s) are fragmented", self:GetColoredNameRealmFromGUID(guid), guid)
  
  local earliest
  local bottom, top = 1, rolls:GetCount()
  while bottom <= top do
    local mid = mathFloor((top + bottom) / 2)
    
    local rollData = self:DeserializeRollData(rolls[mid], mid, guid)
    if rollData.datetime < datetime then
      bottom = mid+1
    else
      earliest = mid
      top = mid-1
    end
  end
  return earliest
end



do
  local memo = {}
  
  function Addon:GetRaceFromGUID(guid)
    if not memo[guid] then
      local charData = self:GetGlobalOptionQuiet("characters", guid)
      self:Assertf(charData, "Could not find data for character with guid %s", tostring(guid))
      
      local race = charData.race
      self:Assertf(race, "Could not find race for character with guid %s", tostring(guid))
      
      memo[guid] = race
    end
    
    return memo[guid]
  end
end


do
  local memo = {}
  
  function Addon:GetLocalFactionFromGUID(guid)
    if not memo[guid] then
      local race = self:GetRaceFromGUID(guid)
      
      local faction = C_CreatureInfo.GetFactionInfo(race)
      if faction then
        faction = faction.name
      else
        faction = self.L["Unknown"]
      end
      if faction == "" then
        faction = self.L["Neutral"]
      end
      
      memo[guid] = faction
    end
    
    return memo[guid]
  end
end

do
  local memo = {}
  
  function Addon:GetFactionFromGUID(guid)
    if not memo[guid] then
      local race = self:GetRaceFromGUID(guid)
      
      local faction = C_CreatureInfo.GetFactionInfo(race)
      if faction then
        faction = faction.groupTag
      else
        faction = "Unknown"
      end
      
      memo[guid] = faction
    end
    
    return memo[guid]
  end
end




do
  local memo = {}
  
  function Addon:GetNameFromGUID(guid)
    if not memo[guid] then
      local charData = self:GetGlobalOptionQuiet("characters", guid)
      self:Assertf(charData, "Could not find data for character with guid %s", tostring(guid))
      
      local name = charData.name
      self:Assertf(name, "Could not find name for character with guid %s", tostring(guid))
      
      memo[guid] = name
    end
    
    return memo[guid]
  end
end

do
  local memo = {}
  
  function Addon:GetColoredNameFromGUID(guid)
    if not memo[guid] then
      local charData = self:GetGlobalOptionQuiet("characters", guid)
      self:Assertf(charData, "Could not find data for character with guid %s", tostring(guid))
      
      local name = charData.name
      self:Assertf(name, "Could not find name for character with guid %s", tostring(guid))
      
      local classID = charData.class
      self:Assertf(classID, "Could not find class for character with guid %s", tostring(guid))
      
      local classInfo = C_CreatureInfo.GetClassInfo(classID)
      local color = RAID_CLASS_COLORS[classInfo.classFile]
      
      memo[guid] = color:WrapTextInColorCode(name)
    end
    
    return memo[guid]
  end
end


do
  local memo = {}
  
  function Addon:GetRealmFromGUID(guid)
    if not memo[guid] then
      local realmID = tonumber(strMatch(guid, "Player%-([^%-]+)%-"))
      self:Assertf(realmID, "Could not get realm id from guid %s", tostring(guid))
      local realmName = self:GetGlobalOption("realms", realmID)
      self:Assertf(realmName, "Could not get realm name from guid %s", tostring(guid))
      memo[guid] = {realmID, realmName}
    end
    
    return unpack(memo[guid])
  end
end

do
  local memo = {}
  
  function Addon:GetColoredRealmFromGUID(guid)
    if not memo[guid] then
      local realmID, realmName = self:GetRealmFromGUID(guid)
      
      local faction = self:GetFactionFromGUID(guid)
      local hex = self:Switch(faction, {
        Alliance = "79b7fc",
        Horde    = "ff5f5b",
        Neutral  = "ffd706",
        Unknown  = "ffffff",
      })
      
      memo[guid] = Addon:MakeColorCode(hex, realmName)
    end
    
    return memo[guid]
  end
end


do
  local memo = {}
  
  function Addon:GetColoredNameRealmFromGUID(guid)
    if not memo[guid] then
      local coloredName  = self:GetColoredNameFromGUID(guid)
      local coloredRealm = self:GetColoredRealmFromGUID(guid)
      
      
      memo[guid] = format("%s-%s", coloredName, coloredRealm)
    end
    
    return memo[guid]
  end
end



