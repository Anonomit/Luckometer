
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)





local RANDOM_ROLL_CAPTURE = Addon:ReversePattern(Addon.L["%s rolls %d (%d-%d)"])




Addon:RegisterAddonEventCallback("ENABLE", function(self)
  
  -- Group Loot rolls
  do
    local lootRolls = {}
    
    -- look for rolls already in progress
    for i = C_LootHistory.GetNumItems(), 1, -1 do
      local rollID, itemLink, numPlayers, isDone, winnerID, isMasterLoot = C_LootHistory.GetItem(i)
      if not lootRolls[rollID] and not isDone then
        if self:GetGlobalOptionQuiet("debugOutput", "rollStarted") then
          self.ItemCache(itemLink):OnCache(function()
            self:Debugf("Found loot roll #%d (rollID %d) is in progress for %s", i, rollID, itemLink)
          end)
        end
        lootRolls[rollID] = {
          datetime = GetServerTime(),
          isDone = false,
        }
      end
    end
    
    -- notice rolls that start
    self:RegisterEventCallback("START_LOOT_ROLL", function(self, e, rollID, rollTime, lootHandle)
      for i = 1, C_LootHistory.GetNumItems() do
        if C_LootHistory.GetItem(i) == rollID then
          local rollID, itemLink, numPlayers, isDone, winnerIdx, isMasterLoot = C_LootHistory.GetItem(i)
          if self:GetGlobalOptionQuiet("debugOutput", "rollStarted") then
            self.ItemCache(itemLink):OnCache(function()
              self:Debugf("Loot roll #%d (rollID %d) started for %s", i, rollID, itemLink)
            end)
          end
          lootRolls[rollID] = {
            datetime = GetServerTime(),
            isDone = false,
          }
        end
      end
    end)
    
    -- notice rolls that end
    self:RegisterEventCallback("LOOT_ROLLS_COMPLETE", function(self, e, lootHandle)
      
      for i = 1, C_LootHistory.GetNumItems() do
        local rollID, itemLink, numPlayers, isDone, winnerID, isMasterLoot = C_LootHistory.GetItem(i)
        if lootRolls[rollID] then
          if isDone and not lootRolls[rollID].isDone then
            if self:GetGlobalOptionQuiet("debugOutput", "rollEnded") then
              self.ItemCache(itemLink):OnCache(function()
                self:Debugf("Loot roll #%d (rollID %d) ended for %s", i, rollID, itemLink)
              end)
            end
            lootRolls[rollID].isDone = true
            lootRolls[rollID] = nil
            
            local rollData = {
              datetime   = GetServerTime(),
              numPlayers = 0,
            }
            
            if winnerID then
              for p = 1, numPlayers do
                local name, class, rollType, roll, isWinner, isMe = C_LootHistory.GetPlayerInfo(i, p)
                if roll then
                  rollData.numPlayers = rollData.numPlayers + 1
                  rollData.rollType = rollData.rollType or rollType
                  
                  if isMe then
                    rollData.roll     = roll
                    rollData.itemLink = itemLink
                    rollData.won      = isWinner
                  end
                end
              end
            end
            
            if rollData.numPlayers > 0 and rollData.roll then
              self:StoreRoll(rollData)
            end
          end
        end
      end
    end)
  end
  
  
  -- Manual rolls
  Addon:RegisterEventCallback("CHAT_MSG_SYSTEM", function(self, e, msg, ...) -- text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons
    if not msg then return end
    
    local source, roll, min, max = msg:match(RANDOM_ROLL_CAPTURE)
    if source ~= self.MY_NAME then return end
    
    roll = tonumber(roll)
    min  = tonumber(min)
    max  = tonumber(max)
    
    local rollData = {
      datetime = GetServerTime(),
      manual   = true,
      roll     = roll,
      min      = min,
      max      = max,
    }
    
    self:StoreRoll(rollData)
  end)
  
end)



