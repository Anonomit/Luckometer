
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
  rollType = function(rollData)
    return GetOptionBool("group", "roll", "type", rollData.rollType)
  end,
  rollNumPlayers = function(rollData)
    if not GetOptionBool("group", "roll", "numPlayers", "enable") then return true end
    
    local numPlayers = rollData.numPlayers
    return numPlayers >= Addon:GetGlobalOption("filters", "group", "roll", "numPlayers", "min") and numPlayers <= Addon:GetGlobalOption("filters", "group", "roll", "numPlayers", "max")
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
  luckyItems = function(rollData)
    if not GetOptionBool("character", "luckyItems", "enable") then return true end
    
    local luckyItems    = rollData.luckyItems
    local operator      = Addon:GetGlobalOption("filters", "character", "luckyItems", "operator")
    local requiredItems = Addon:GetGlobalOptionQuiet("filters", "character", "luckyItems", "items")
    if operator == "any" then
      if not luckyItems then return false end
      for id, required in pairs(requiredItems) do
        if required and luckyItems[id] then
          return true
        end
      end
      return false
    elseif operator == "all" then
      if not luckyItems then return false end
      for id, required in pairs(requiredItems) do
        if required and not luckyItems[id] then
          return false
        end
      end
      return true
    elseif operator == "none" then
      if not luckyItems then return true end
      for id, required in pairs(requiredItems) do
        if required and luckyItems[id] then
          return false
        end
      end
      return true
    end
    
    self:Errorf("Invalid operator value: %s", tostring(operator))
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
  
  Addon:RegisterAddonEventCallback("OPTION_SET", function(self, event, val, ...)
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
  local cacheController
  
  local function generator(self, data)
    self:DebugIfOutput("rollsFilterStarted", "Rolls filtering started")
    
    local startTime = GetTimePreciseSec()
    local calculationSpeed = self:GetGlobalOption("calculations", "filterSpeed")
    
    data.filteredRolls = {}
    local filteredRolls = data.filteredRolls
    
    local ticker = self:MakeThreadTicker(calculationSpeed)
    local deserializedRolls = {}
    local itemsToCache = {}
    local itemsInCache = {}
    
    local store = deserializedRolls -- remove this line and uncomment the others when rolls need to be filtered in order
    
    -- gather rolls from db
    for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
      if self:GetGlobalOption("filters", "character", "guid", guid) then--[[
        local store = {}
        deserializedRolls[#deserializedRolls+1] = store]]
        
        for i, rollData in self:IterRollData(rolls, guid) do
          store[#store+1] = rollData
          
          if rollData.itemLink then
            rollData.item = self.ItemCache(rollData.itemLink)
          end
            
          if not CanFilter(rollData) then
            if not itemsInCache[rollData.item] then
              itemsInCache[rollData.item]   = true
              itemsToCache[#itemsToCache+1] = rollData.item
            end
          end
          
          ticker:Tick(1, function() self:DebugIfOutput("rollFilterProgress", "Roll filtering is collecting rolls") end)
        end--[[
        if #store == 0 then
          deserializedRolls[#deserializedRolls] = nil
        else
          deserializedRolls[#deserializedRolls] = {ipairs(store)}
        end]]
      end
    end
    
    --[[
    -- sort deserialized rolls
    ticker:SetCallback(function() self:DebugIfOutput("rollFilterProgress", "Roll filtering is sorting rolls") end)
    local deserializedRolls = self:MergeSorted(deserializedRolls, nil, nil, ticker)
    ticker:SetCallback()
    ]]
    
    -- cache missing items
    if #itemsToCache > 0 then
      self:DebugfIfOutput("countUncachedItems", "Items to cache: %d", #itemsToCache)
      cacheController = self.ItemCache:Cache(itemsToCache):SetSpeed(10)
      while not cacheController:IsComplete() do
        self:DebugIfOutput("rollFilterProgress", "Roll filtering is waiting for items to cache")
        ticker:Trigger()
      end
      self:DebugIfOutput("rollItemsCached", "Items cached")
    end
    
    
    -- do some math with the rolls
    local completed, totalRoll, totalScore = 0, 0, 0
    for _, rollData in ipairs(deserializedRolls) do
      if DoesRollPassFilter(rollData) then
        filteredRolls[#filteredRolls+1] = rollData
        
        local roll = rollData.roll
        local rollScore = self:GetRollScore(roll, rollData.min, rollData.max)
        if not self:IsStandardRoll(min, max) then
          roll = self:GetAdjustedRoll(rollScore)
        end
        
        totalRoll  = totalRoll  + roll
        totalScore = totalScore + rollScore
      end
      completed = completed + 1
      
      ticker:Tick(1, function() self:DebugIfOutput("rollFilterProgress", "Roll filtering is calculating final stats") end)
    end
    
    
    -- calculate the totals
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
      luck       = self:CalculateLuck(avgScore, #filteredRolls)
    }
    
    if self:GetGlobalOption("debugOutput", "rollsFilterCompleted") then
      local totalTime = self:GetThreadRealTime"RollResults"
      self:Debugf("Rolls filtering complete in %ss (worked %ss, %s%% load) with %s |4step:steps; over %s |4lap:laps;, resulting in %s average fps",
        self:Round(totalTime, 0.001),
        self:Round(self:GetThreadRunTime"RollResults", 0.001),
        self:Round(self:GetThreadRunTime"RollResults" / totalTime * 100, 0.1),
        self:ToFormattedNumber(ticker:GetSteps()),
        self:ToFormattedNumber(ticker:GetLaps()),
        self:Round(ticker:GetLaps() / totalTime, 0.1)
      )
    end
    
    if self:GetGlobalOption("calculations", "refreshAfterFilter") or data.refreshWhenDone then
      self:RefreshConfig()
    end
  end
  
  
  
  function Addon:StartRollCalculations(refreshWhenDone)
    Addon:DebugIfOutput("rollsFilterStarted", "Attempting to start/resume rolls filtering")
    local data = self:GetThreadData"RollResults"
    if data and refreshWhenDone then
      data.refreshWhenDone = true
    end
    
    if data and (data.results or not self:IsThreadDead"RollResults") then
      self:StartThread"RollResults"
    else
      self:StartNewThread("RollResults", generator, not self:GetGlobalOption("calculations", "startImmediately"))
    end
  end
  
  function Addon:StopRollCalculations()
    self:StopThread"RollResults"
  end
  
  
  function Addon:ResetRollCalculations()
    Addon:DebugIfOutput("rollsFilterReset", "Reseting rolls filtering")
    self:KillThread"RollResults"
    local data = self:GetThreadData"RollResults"
    if data then
      wipe(data)
    end
    if cacheController then
      cacheController:Cancel()
      cacheController = nil
    end
  end
  
  do
    local manualEditMode = false
    
    function Addon:RestartRollCalculations()
      self:AllowRecalculation()
      self:ResetRollCalculations()
      if self:IsConfigOpen() then
        self:StartRollCalculations()
      end
    end
    
    
    function Addon:AllowRecalculation()
      manualEditMode = false
    end
    function Addon:BlockRecalculation()
      manualEditMode = true
    end
    
    function Addon:RestartFilteringAfter(func)
      self:SuspendAddonEventWhile("RESET_FILTER_CALCULATIONS", func)
      self:FireAddonEvent"RESET_FILTER_CALCULATIONS"
    end
    
    
    
    Addon:RegisterAddonEventCallback("RESET_FILTER_CALCULATIONS", function(self, event, ...)
      self:RestartRollCalculations()
    end)
    
    
    Addon:RegisterAddonEventCallback("OPTION_SET", function(self, event, val, ...)
      if manualEditMode then return end
      
      local path = {...}
      if path[2] ~= "global" then return end
      if path[3] == "filters" then
        self:FireAddonEvent"RESET_FILTER_CALCULATIONS"
      end
    end)
  end
  
  
  Addon:RegisterAddonEventCallback("OPTIONS_OPENED_PRE", function(self)
    self:StartRollCalculations()
  end)
  Addon:RegisterAddonEventCallback("OPTIONS_CLOSED_POST", function(self)
    self:StopRollCalculations()
  end)
end








