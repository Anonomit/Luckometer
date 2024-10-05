
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)


local AceSerializer = Addon.AceSerializer


local strMatch = string.match





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
    },
    __lt = function(self, o)
      if self.datetime ~= o.datetime then
        return self.datetime < o.datetime
      else
        return self.index < o.index
      end
    end
  }
  
  function Addon:SerializeRollData(rollData)
    setmetatable(rollData, meta)
    
    if rawget(rollData, "min") == 1 then
      rawset(rollData, "min", nil)
    end
    if rawget(rollData, "max") == 100 then
      rawset(rollData, "max", nil)
    end
    rawset(rollData, "guid", nil)
    
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
      self:SetGlobalOptionQuiet(characterData, "characters", self.MY_GUID)
    end
  end
end


function Addon:DeleteCharacter(guid)
  self:Assertf(guid, "Received invalid guid: %s", tostring(guid))
  
  local nameRealm = self:GetColoredNameRealmFromGUID(guid)
  
  self:ResetGlobalOptionConfigQuiet("filters", "character", "guid", guid)
  self:ResetGlobalOptionConfigQuiet("characters", guid)
  
  local count = self:GetGlobalOptionQuiet("rolls", guid):GetCount()
  self:ResetGlobalOptionConfigQuiet("rolls", guid)
  
  self:DebugfIfOutput("charDeleted", "Deleted %s and %d |4roll:rolls;", nameRealm, count)
  
  if count > 0 then
    self:NotifyChange()
  end
  return count
end




function Addon:StoreRoll(rollData)
  if (rollData.max or 100) == (rollData.min or 1) then
    -- no entropy to record here
    return
  end
  
  StoreCharacter()
  
  -- rollData.guid  = self.MY_GUID
  rollData.level = self.MY_LEVEL
  
  local guid = self.MY_GUID
  
  local rollString = self:SerializeRollData(rollData)
  local rolls = self:GetGlobalOptionQuiet("rolls")
  if not rolls[guid] then
    rolls[guid] = self.IndexedQueue()
  end
  rolls[guid]:Add(rollString)
  self:SetGlobalOptionConfigQuiet(rolls[guid], "rolls", guid) -- run callbacks
  
  self:DebugfIfOutput("rollAdded", "Roll added: %d (%d-%d)", rollData.roll, rollData.min or 1, rollData.max or 100)
  
  self:NotifyChange()
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



