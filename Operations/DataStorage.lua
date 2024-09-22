
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)


local AceSerializer = Addon.AceSerializer


local strMatch = string.match





local function VerifyRollData(rollData)
  Addon:ThrowfAssert((rollData.max or 100) ~= (rollData.min or 1), "Roll contains no entropy. %s-%s", tostring(rollData.max or 100), tostring(rollData.min or 1))
  
  return rollData
end
function Addon:SerializeRollData(rollData)
  return AceSerializer:Serialize(VerifyRollData(rollData))
end
function Addon:DeserializeRollData(rollString)
  local rollData = VerifyRollData(select(2, AceSerializer:Deserialize(rollString)))
  Addon:StoreDefault(rollData, "min", 1)
  Addon:StoreDefault(rollData, "max", 100)
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





function Addon:StoreRoll(rollData)
  if (rollData.max or 100) == (rollData.min or 1) then
    -- no entropy to record here
    return
  end
  
  StoreCharacter()
  
  rollData.guid  = Addon.MY_GUID
  rollData.level = Addon.MY_LEVEL
  
  if rollData.min == 1 then
    rollData.min = nil
  end
  if rollData.max == 100 then
    rollData.max = nil
  end
  
  local rollString = self:SerializeRollData(rollData)
  Addon:GetGlobalOptionQuiet("rolls"):Add(rollString)
  self:NotifyChange()
end






function Addon:ClearRolls()
  Addon:GetGlobalOptionQuiet("rolls"):Wipe()
  self:NotifyChange()
end






function Addon:GetRealmFromGUID(guid)
  local realmID = tonumber(strMatch(guid, "Player%-([^%-]+)%-"))
  self:Assert(realmID)
  local realmName = self:GetGlobalOption("realms", realmID)
  self:Assert(realmName)
  
  return realmID, realmName
end




