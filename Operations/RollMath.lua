
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
  local CALCULATION_SPEED = 500
  
  -- whether to begin calculations immediately
  local INSTANT_RUN = false
  
  -- how many rolls to check instantly
  local INSTANT_SPEED = 100
  
  -- whether to refresh options menu when roll filtering is complete
  local AUTO_NOTIFY = false
  
  
  local rollResults = {
    timer      = nil,
    co         = nil,
    controller = nil,
    progress   = nil,
    results    = nil,
  }
  Addon.rollResults = rollResults
  
  local function generator(calculationSpeed)
    if not calculationSpeed then
      calculationSpeed = CALCULATION_SPEED
    end
    
    local rolls = Addon:GetGlobalOptionQuiet"rolls"
    rollResults.filteredRolls = {}
    local filteredRolls = rollResults.filteredRolls
    
    local count = 0
    local deserializedRolls = {}
    local itemsToCache = {}
    
    -- gather rolls from db
    for i, rollString in rolls:iter() do
      count = count + 1
      
      local rollData = Addon:DeserializeRollData(rollString)
      deserializedRolls[#deserializedRolls+1] = rollData
      
      if rollData.itemLink then
        rollData.item = Addon.ItemCache(rollData.itemLink)
      end
        
      if not Addon:CanFilter(rollData) then
        itemsToCache[#itemsToCache+1] = rollData.item
      end
      
      if count % calculationSpeed == 0 then
        calculationSpeed = coroutine.yield() or CALCULATION_SPEED
        count = 0
      end
    end
    
    -- cache missing items
    if #itemsToCache > 0 then
      Addon:DebugfIfOutput("countUncachedRolls", "Rolls to cache: %d", #itemsToCache)
      rollResults.controller = Addon.ItemCache:Cache(itemsToCache)
      while not rollResults.controller:IsComplete() do
        calculationSpeed = coroutine.yield() or CALCULATION_SPEED
        count = 0
      end
      Addon:DebugIfOutput("rollsCached", "Rolls cached")
    end
    
    -- do some math with the rolls
    local completed, totalRoll, totalScore = 0, 0, 0
    for _, rollData in ipairs(deserializedRolls) do
      count = count + 1
      
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
      completed = completed + 1
      
      if count % calculationSpeed == 0 then
        calculationSpeed = coroutine.yield() or CALCULATION_SPEED
        count = 0
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
    if rollResults.controller then
      rollResults.controller:Cancel()
      rollResults.controller = nil
    end
    
    rollResults.co = coroutine.create(generator)
    local function generate(timer, calculationSpeed)
      if rollResults.co and coroutine.status(rollResults.co) == "suspended" then
        local success, err = coroutine.resume(rollResults.co, calculationSpeed)
        self:ThrowAssert(success, err)
      else
        rollResults.co = nil
        if rollResults.timer then
          rollResults.timer:Cancel()
          rollResults.timer = nil
        end
      end
    end
    if INSTANT_RUN then
      generate(nil, INSTANT_SPEED)
    end
    
    if coroutine.status(rollResults.co) ~= "dead" then
      rollResults.timer = C_Timer.NewTicker(CALCULATION_INTERVAL, generate)
    end
  end
  
  function Addon:StopRollCalculations()
    if rollResults.results then return end
    self:ResetRollCalculations()
  end
  
  
  function Addon:ResetRollCalculations()
    if rollResults.timer then
      rollResults.timer:Cancel()
      rollResults.timer = nil
    end
    rollResults.co = nil
    if rollResults.controller then
      rollResults.controller:Cancel()
      rollResults.controller = nil
    end
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
    if path[3] == "rolls" then
      self:NotifyChange() -- making sure the research button is visible
    end
  end
end)







