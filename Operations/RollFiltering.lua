
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)




local filters = {
  rollType = function(rollData)
    if rollData.manual then
      return Addon:GetGlobalOption("filters", "rollType", "manual")
    else
      return Addon:GetGlobalOption("filters", "rollType", "group")
    end
  end,
  rollWon = function(rollData)
    if rollData.manual then return true end
    
    return Addon:GetGlobalOption("filters", "rollWon", rollData.won and 1 or 0)
  end,
}


function Addon:DoesRollPassFilter(rollData)
  for filterName, filt in pairs(filters) do
    if not filt(rollData) then
      return false
    end
  end
  return true
end





Addon:RegisterOptionSetHandler(function(self, val, ...)
  local path = {...}
  if path[2] == "global" and path[3] == "filters" then
    Addon:StopRollCalculations()
  end
end)



