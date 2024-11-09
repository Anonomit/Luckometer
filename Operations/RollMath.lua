
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)





local mathAbs  = math.abs
local mathSqrt = math.sqrt
local mathExp  = math.exp








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






do
  -- erf function from Picomath: https://hewgill.com/picomath/index.html
  local function erf(x)
    -- constants
    a1 =  0.254829592
    a2 = -0.284496736
    a3 =  1.421413741
    a4 = -1.453152027
    a5 =  1.061405429
    p  =  0.3275911
    
    -- Save the sign of x
    sign = 1
    if x < 0 then
        sign = -1
    end
    x = mathAbs(x)
    
    -- A&S formula 7.1.26
    t = 1.0/(1.0 + p*x)
    y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*mathExp(-x*x)
    
    return sign*y
  end
  
  
  local lower, upper = 0, 1
  
  local mu = (lower + upper) / 2
  local std = mathSqrt((upper - lower)^2 / 12)
  local root2 = mathSqrt(2)
  
  function Addon:CalculateLuck(rollScore, totalRolls)
    -- Calculate the standard error
    local standardError = std / mathSqrt(totalRolls)
    
    -- Calculate the z-score
    local zScore = (rollScore - mu) / standardError
    
    -- Calculate the p-value using a standard normal distribution
    local pValue = 1 - erf(mathAbs(zScore) / root2)
    
    local luck = pValue / 2
    if rollScore > mu then
      luck = 1 - luck
    end
    return luck
  end
end




