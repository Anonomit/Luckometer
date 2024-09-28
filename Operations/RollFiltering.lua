
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



-- Can remove this once AceDB fixes the short circuit evaluation bug
local function GetOptionBool(...)
  return Addon:GetGlobalOption("filters", ...) or false
end



local groupLootFilters = {
  rollWon = function(rollData)
    return GetOptionBool("rollWon", rollData.won and 1 or 0)
  end,
  itemQuality = function(rollData)
    if Addon:ThrowAssert(rollData.item, "Can't filter for quality because the roll has no item") then
      Addon:ThrowfAssert(rollData.item:IsCached(), "Can't filter for quality because item is not cached: %s", tostring(rollData.item))
    end
    
    local quality = rollData.item:GetQuality()
    return GetOptionBool("itemQuality", quality)
  end,
}

local manualFilters = {
  rollMin = function(rollData)
    Addon:ThrowAssert(rollData.min, "Can't filter for roll minimum because the roll has no minimum")
    
    if not GetOptionBool("rollLimits", "min", "enable") then return true end
    
    return rollData.min >= GetOptionBool("rollLimits", "min", "min") and rollData.min <= GetOptionBool("rollLimits", "min", "max")
  end,
  rollMax = function(rollData)
    Addon:ThrowAssert(rollData.max, "Can't filter for roll minimum because the roll has no minimum")
    
    if not GetOptionBool("rollLimits", "max", "enable") then return true end
    
    return rollData.max >= GetOptionBool("rollLimits", "max", "min") and rollData.max <= GetOptionBool("rollLimits", "max", "max")
  end,
}

local filters = {
  rollType = function(rollData)
    if rollData.manual then
      return GetOptionBool("rollType", "manual")
    else
      return GetOptionBool("rollType", "group")
    end
  end,
  character = function(rollData)
    return GetOptionBool("character", rollData.guid)
  end,
}


function Addon:DoesRollPassFilter(rollData)
  for filterName, filt in pairs(filters) do
    if not filt(rollData) then
      return false
    end
  end
  
  for filterName, filt in pairs(rollData.manual and manualFilters or groupLootFilters) do
    if not filt(rollData) then
      return false
    end
  end
  
  return true
end



local requiresCache

local function DoFiltersRequireCache_Helper()
  if GetOptionBool("rollType", "group") then
    -- I could test each type of filter to see if any of them actually exclude anything
    return true
  end
  
  return false
end
function DoFiltersRequireCache()
  if requiresCache == nil then
    requiresCache = DoFiltersRequireCache_Helper()
  end
  
  return requiresCache
end

Addon:RegisterOptionSetHandler(function(self, val, ...)
  local path = {...}
  if path[2] ~= "global" then return end
  if path[3] == "filters" then
    requiresCache = nil
  end
end)




function Addon:CanFilter(rollData)
  if rollData.itemLink and DoFiltersRequireCache() then
    return rollData.item:IsCached()
  end
  
  return true
end








