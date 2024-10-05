
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)


local AceSerializer = Addon.AceSerializer


local strMatch = string.match





local function VerifyRollData(rollData)
  Addon:ThrowfAssert((rollData.max or 100) ~= (rollData.min or 1), "Roll contains no entropy. %s-%s", tostring(rollData.max or 100), tostring(rollData.min or 1))
  Addon:ThrowAssert(rollData.manual or rollData.itemLink, "Group Loot roll doesn't contain an itemlink")
  
  return rollData
end
function Addon:SerializeRollData(rollData)
  if rollData.min == 1 then
    rollData.min = nil
  end
  if rollData.max == 100 then
    rollData.max = nil
  end
  
  return AceSerializer:Serialize(VerifyRollData(rollData))
end
function Addon:DeserializeRollData(rollString, guid)
  local rollData = VerifyRollData(select(2, AceSerializer:Deserialize(rollString)))
  Addon:StoreDefault(rollData, "min",  1)
  Addon:StoreDefault(rollData, "max",  100)
  Addon:StoreDefault(rollData, "guid", guid) -- don't overwrite if guid already exists due to old db
  return rollData
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



-- function Addon:DeleteRolls(filt)
--   local rolls = Addon:GetGlobalOptionQuiet("rolls")
  
--   local count = 0
--   for i, rollString in rolls:iter() do
--     local rollData = Addon:DeserializeRollData(rollString)
--     if filt(rollData) then
--       count = count + 1
--       rolls:Remove(i)
--     end
--   end
--   if count > 0 then
--     rolls:Defrag()
--     Addon:SetGlobalOptionConfigQuiet(rolls, "rolls") -- run callbacks
--   end
  
--   return count
-- end

-- function Addon:CountRolls(filt)
--   local rolls = Addon:GetGlobalOptionQuiet("rolls")
  
--   local count = 0
--   for i, rollString in rolls:iter() do
--     local rollData = Addon:DeserializeRollData(rollString)
--     if filt(rollData) then
--       count = count + 1
--     end
--   end
  
--   return count
-- end








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



