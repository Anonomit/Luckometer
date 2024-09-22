
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



-- roll limit is 0-1000000


local function IsStandardRoll(min, max)
  return min == 1 and max == 100
end


local function GetRollScore(roll, min, max)
  local span = max - min
  if not Addon:ThrowfAssert(span > 0, "Roll score cannot be computed: roll: %s, min: %s, max: %s", tostring(roll), tostring(min), tostring(max)) then
    return nil
  end
  
  roll = (roll - min) / span
  
  return roll
end

local function GetAdjustedRoll(rollScore)
  return (rollScore * 99) + 1
end



do
  -- how often in seconds to work on filtering rolls
  local CALCULATION_INTERVAL = 0.1
  
  -- how many rolls to check at a time
  local CALCULATION_SPEED = 100
  
  -- whether to refresh options menu when roll filtering is complete
  local AUTO_NOTIFY = false
  
  
  local rollResults = {
    timer    = nil,
    co       = nil,
    progress = nil,
    results  = nil,
  }
  Addon.rollResults = rollResults

  local function generator()
    local rolls = Addon:GetGlobalOptionQuiet"rolls"
    rollResults.filteredRolls = {}
    local filteredRolls = rollResults.filteredRolls
    
    local count = 0
    local totalRoll, totalScore = 0, 0
    for i, rollString in rolls:iter() do
      count = count + 1
      
      local rollData = Addon:DeserializeRollData(rollString)
      if Addon:DoesRollPassFilter(rollData) then
        filteredRolls[#filteredRolls+1] = rollData
        
        local roll = rollData.roll
        local rollScore = GetRollScore(roll, rollData.min, rollData.max)
        if not IsStandardRoll(min, max) then
          roll = GetAdjustedRoll(rollScore)
        end
        
        totalRoll  = totalRoll  + roll
        totalScore = totalScore + rollScore
      end
      
      if count % CALCULATION_SPEED == 0 then
        -- rollResults.progress = count / rolls:GetCount()
        -- Addon:NotifyChange()
        coroutine.yield()
      end
    end
    
    local avgRoll, avgScore = 0, 0
    if #filteredRolls > 0 then
      avgRoll  = totalRoll  / #filteredRolls
      avgScore = totalScore / #filteredRolls
    end
    
    rollResults.results = {
      count      = #filteredRolls,
      totalRoll  = totalRoll,
      totalScore = totalScore,
      avgRoll    = avgRoll,
      avgScore   = avgScore,
    }
    
    rollResults.progress = nil
    if AUTO_NOTIFY or rollResults.notify then
      Addon:NotifyChange()
    end
  end



  function Addon:StartRollCalculations(notify)
    rollResults.notify = rollResults.notify or notify
    if rollResults.progress or rollResults.results then return end
    
    rollResults.progress = 0
    rollResults.results = nil
    rollResults.co = coroutine.create(generator)
    
    rollResults.timer = C_Timer.NewTicker(CALCULATION_INTERVAL, function()
      if rollResults.co and coroutine.status(rollResults.co) == "suspended" then
        local success, err = coroutine.resume(rollResults.co)
        self:ThrowAssert(success, err)
      else
        rollResults.co = nil
        rollResults.timer:Cancel()
        rollResults.timer = nil
      end
    end)
  end

  function Addon:StopRollCalculations()
    if rollResults.results then return end
    self:ResetRollCalculations()
  end


  function Addon:ResetRollCalculations()
    if rollResults.timer then
      rollResults.timer:Cancel()
    end
    rollResults.timer    = nil
    rollResults.co       = nil
    rollResults.progress = nil
    rollResults.notify   = nil
    rollResults.results  = nil
  end

  function Addon:RestartRollCalculations()
    self:ResetRollCalculations()
    self:StartRollCalculations()
  end
end




Addon:RegisterOptionsOpenPreCallback(function(self)
  Addon:StartRollCalculations()
end)
Addon:RegisterOptionsClosePostCallback(function(self)
  Addon:StopRollCalculations()
end)

Addon:RegisterOptionSetHandler(function(self, val, ...)
  local path = {...}
  if path[2] ~= "global" then return end
  if path[3] == "filters" or path[3] == "rolls" then
    self:ResetRollCalculations()
    if self:IsConfigOpen() then
      self:StartRollCalculations()
    end
  end
end)







