
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)



-- Can remove this once AceDB fixes the short circuit evaluation bug
local function GetOptionBool(...)
  return Addon:GetGlobalOption("filters", ...) or false
end



local groupLootFilters = {
  rollWon = function(rollData)
    return GetOptionBool("group", "roll", "won", rollData.won and 1 or 0)
  end,
  itemQuality = function(rollData)
    if Addon:ThrowAssert(rollData.item, "Can't filter for quality because the roll has no item") then
      Addon:ThrowfAssert(rollData.item:IsCached(), "Can't filter for quality because item is not cached: %s", tostring(rollData.item))
    end
    
    local quality = rollData.item:GetQuality()
    return GetOptionBool("group", "item", "quality", quality)
  end,
  itemLevel = function(rollData)
    if Addon:ThrowAssert(rollData.item, "Can't filter for item level because the roll has no item") then
      Addon:ThrowfAssert(rollData.item:IsCached(), "Can't filter for item level because item is not cached: %s", tostring(rollData.item))
    end
    
    if not GetOptionBool("group", "item", "level", "enable") then return true end
    
    local itemLevel = rollData.item:GetLevel()
    return itemLevel >= Addon:GetGlobalOption("filters", "group", "item", "level", "min") and itemLevel <= Addon:GetGlobalOption("filters", "group", "item", "level", "max")
  end,
}

local manualFilters = {
  rollMin = function(rollData)
    Addon:ThrowAssert(rollData.min, "Can't filter for roll minimum because the roll has no minimum")
    
    if not GetOptionBool("manual", "roll", "limits", "min", "enable") then return true end
    
    return rollData.min >= GetOptionBool("manual", "roll", "limits", "min", "min") and rollData.min <= GetOptionBool("manual", "roll", "limits", "min", "max")
  end,
  rollMax = function(rollData)
    Addon:ThrowAssert(rollData.max, "Can't filter for roll minimum because the roll has no minimum")
    
    if not GetOptionBool("manual", "roll", "limits", "max", "enable") then return true end
    
    return rollData.max >= GetOptionBool("manual", "roll", "limits", "max", "min") and rollData.max <= GetOptionBool("manual", "roll", "limits", "max", "max")
  end,
}

local filters = {
  rollMethod = function(rollData)
    if rollData.manual then
      return GetOptionBool("manual", "enable")
    else
      return GetOptionBool("group", "enable")
    end
  end,
  -- character = function(rollData)
  --   return GetOptionBool("character", rollData.guid)
  -- end,
  characterLevel = function(rollData)
    if not GetOptionBool("character", "level", "enable") then return true end
    
    local characterLevel = rollData.level
    return characterLevel >= Addon:GetGlobalOption("filters", "character", "level", "min") and characterLevel <= Addon:GetGlobalOption("filters", "character", "level", "max")
  end,
}


local function DoesRollPassFilter(rollData)
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



local CanFilter

do
  local requiresCache
  
  local function DoFiltersRequireCache_Helper()
    if GetOptionBool("group", "enable") then
      -- I could test each type of filter to see if any of them actually exclude anything
      return true
    end
    
    return false
  end
  local function DoFiltersRequireCache()
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
  
  CanFilter = function(rollData)
    if rollData.itemLink and DoFiltersRequireCache() then
      return rollData.item:IsCached()
    end
    
    return true
  end
end
















do
  -- how many steps to perform at a time
  local CALCULATION_SPEED = 100
  
  -- whether to refresh options menu when roll filtering is complete
  local AUTO_NOTIFY = false
  
  
  local cacheController
  
  local function generator(self, data)
    Addon:DebugIfOutput("rollsFilterStarted", "Rolls filtering started")
    
    local startTime = GetTime()
    
    if not calculationSpeed then
      calculationSpeed = CALCULATION_SPEED
    end
    
    data.filteredRolls = {}
    local filteredRolls = data.filteredRolls
    
    local count = 0
    local deserializedRolls = {}
    local itemsToCache = {}
    local itemsInCache = {}
    
    -- gather rolls from db
    for guid, rolls in pairs(Addon:GetGlobalOptionQuiet"rolls") do
      if Addon:GetGlobalOption("filters", "character", "guid", guid) then
        for i, rollString in rolls:iter() do
          count = count + 1
          
          local rollData = Addon:DeserializeRollData(rollString, guid)
          deserializedRolls[#deserializedRolls+1] = rollData
          
          if rollData.itemLink then
            rollData.item = Addon.ItemCache(rollData.itemLink)
          end
            
          if not CanFilter(rollData) then
            if not itemsInCache[rollData.item] then
              itemsInCache[rollData.item]   = true
              itemsToCache[#itemsToCache+1] = rollData.item
            end
          end
          
          if count % calculationSpeed == 0 then
            Addon:DebugIfOutput("rollFilterProgress", "Roll filtering is collecting rolls")
            coroutine.yield()
            count = 0
          end
        end
      end
    end
    
    -- cache missing items
    if #itemsToCache > 0 then
      Addon:DebugfIfOutput("countUncachedItems", "Items to cache: %d", #itemsToCache)
      cacheController = Addon.ItemCache:Cache(itemsToCache):SetSpeed(10)
      while not cacheController:IsComplete() do
        Addon:DebugIfOutput("rollFilterProgress", "Roll filtering is waiting for items to cache")
        coroutine.yield()
        count = 0
      end
      Addon:DebugIfOutput("rollItemsCached", "Items cached")
    end
    
    -- do some math with the rolls
    local completed, totalRoll, totalScore = 0, 0, 0
    for _, rollData in ipairs(deserializedRolls) do
      count = count + 1
      
      if DoesRollPassFilter(rollData) then
        filteredRolls[#filteredRolls+1] = rollData
        
        local roll = rollData.roll
        local rollScore = Addon:GetRollScore(roll, rollData.min, rollData.max)
        if not Addon:IsStandardRoll(min, max) then
          roll = Addon:GetAdjustedRoll(rollScore)
        end
        
        totalRoll  = totalRoll  + roll
        totalScore = totalScore + rollScore
      end
      completed = completed + 1
      
      if count % calculationSpeed == 0 then
        Addon:DebugIfOutput("rollFilterProgress", "Roll filtering is calculating final stats")
        coroutine.yield()
        count = 0
      end
    end
    
    local avgRoll, avgScore = 0, 0
    if #filteredRolls > 0 then
      avgRoll  = totalRoll  / #filteredRolls
      avgScore = totalScore / #filteredRolls
    end
    
    data.results = {
      count      = #filteredRolls,
      totalRoll  = totalRoll,
      totalScore = totalScore,
      avgRoll    = avgRoll,
      avgScore   = avgScore,
    }
    
    Addon:DebugfIfOutput("rollsFilterCompleted", "Rolls filtering complete in %ss", self:Round(GetTime() - startTime, 0.001))
    
    if AUTO_NOTIFY or data.notify then
      Addon:NotifyChange()
    end
  end
  
  
  
  function Addon:StartRollCalculations(notify)
    local data = self:GetThreadData"RollResults"
    if data and notify then
      data.notify = true
    end
    
    if data and (data.results or not self:IsThreadDead"RollResults") then
      self:StartThread"RollResults"
    else
      self:StartNewThread("RollResults", generator)
    end
  end
  
  function Addon:StopRollCalculations()
    self:StopThread"RollResults"
  end
  
  
  function Addon:ResetRollCalculations()
    self:StopThread"RollResults"
    local data = self:GetThreadData"RollResults"
    if data then
      wipe(data)
    end
    if cacheController then
      cacheController:Cancel()
      cacheController = nil
    end
  end
  
  function Addon:RestartRollCalculations()
    self:ResetRollCalculations()
    if self:IsConfigOpen() then
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
      self:RestartRollCalculations()
      
      if path[3] == "rolls" then
        self:NotifyChange() -- making sure the research button is visible
      end
    end
  end)
end








