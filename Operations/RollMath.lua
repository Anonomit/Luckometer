
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



-- roll limit is 0-1000000


function Addon:IsStandardRoll(min, max)
  return min == 1 and max == 100
end


function Addon:GetRollScore(roll, min, max)
  local span = max - min
  if not Addon:ThrowfAssert(span > 0, "Roll score cannot be computed: roll: %s, min: %s, max: %s", tostring(roll), tostring(min), tostring(max)) then
    return nil
  end
  
  roll = (roll - min) / span
  
  return roll
end

function Addon:GetAdjustedRoll(rollScore)
  return (rollScore * 99) + 1
end










