
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)






local dbInitFuncs

do
  local self = Addon
  
  local shared = {}
  
  dbInitFuncs = {
    global = {
      FirstRun = nil,
      upgrades = {
        ["1.3.0"] = function()
          -- separate rolls by guid
          local newRolls = {}
          
          local rolls = self:GetGlobalOptionQuiet"rolls"
          rolls.next = nil -- update IndexedQueue schema
          
          for i, rollString in self.IndexedQueue.iter(rolls) do
            local rollData = self:DeserializeRollData(rollString, i)
            
            local guid = rollData.guid
            rollData.guid = nil
            if not newRolls[guid] then
              newRolls[guid] = self.IndexedQueue()
            end
            
            newRolls[guid]:Add(self:SerializeRollData(rollData))
          end
          self:SetGlobalOption(newRolls, "rolls")
          
          
          -- reset filters setting
          self:ResetGlobalOptionQuiet"filters"
        end,
        ["1.4.0"] = function()
          -- remove profile storage
          local sv = self:GetDB().sv
          if sv then
            sv.profiles = nil
          end
          
          -- track lucky items by key instead of as a list
          local datetime = 1728532800 -- Thu Oct 10 2024 04:00:00 GMT+0000
          for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
            self.IndexedQueue(rolls)
            local first = self:GetEarliestRollAfter(datetime, guid)
            if first then
              self:Debugf("Upgrading lucky items format for %s (%s) starting at roll %d", self:GetColoredNameRealmFromGUID(guid), guid, first)
              for i, rollString in rolls:iter(first) do
                local rollData = self:DeserializeRollData(rollString, first, guid)
                local luckyItems = rollData.luckyItems
                if luckyItems then
                  self:Debugf("Upgrading lucky items format for roll %d", i)
                  rollData.luckyItems = self:MakeLookupTable(luckyItems)
                  rolls[i] = self:SerializeRollData(rollData)
                end
              end
            end
          end
        end,
        ["1.4.1"] = function()
          -- Delete any characters that have never rolled
          local toDelete = {}
          for guid, charData in pairs(Addon:GetGlobalOptionQuiet"characters") do
            if not self:GetGlobalOptionQuiet("rolls", guid) then
              toDelete[#toDelete+1] = guid
            end
          end
          for _, guid in ipairs(toDelete) do
            self:SetGlobalOption(nil, "characters", guid)
          end
        end,
      },
      AlwaysRun = function()
        -- Create IndexedQueue objects from rolls table
        for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
          self.IndexedQueue(rolls)
        end
        
        -- Update character metadata if the character is already in db
        if self:GetGlobalOptionQuiet("characters", self.MY_GUID) then
          self:StoreCharacter()
        end
        
        -- if only one lucky item exists in this game version, make sure it isn't disabled
        if #self.orderedLuckyItems == 1 then
          if not self:GetGlobalOption("filters", "character", "luckyItems", "items", self.orderedLuckyItems[1]) then
            self:SetGlobalOption(true, "filters", "character", "luckyItems", "items", self.orderedLuckyItems[1])
          end
        end
      end,
    },
  }
end



function Addon:OnInitialize()
  self.db        = self.AceDB:New(("%sDB"):format(ADDON_NAME), self:MakeDefaultOptions(), true)
  self.dbDefault = self.AceDB:New({}                         , self:MakeDefaultOptions(), true)
  
  self:FireAddonEvent"INITIALIZE"
end

function Addon:OnEnable()
  self.version = self.SemVer(C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"))
  self:InitDB(dbInitFuncs)
  self:GetDB().RegisterCallback(self, "OnProfileChanged", function() self:InitDB(dbInitFuncs, "profile") end)
  self:GetDB().RegisterCallback(self, "OnProfileCopied" , function() self:InitDB(dbInitFuncs, "profile") end)
  self:GetDB().RegisterCallback(self, "OnProfileReset"  , function() self:InitDB(dbInitFuncs, "profile") end)
  
  self:InitChatCommands("lucky", "lm", "lom", "l-o-m", "lucko", "luck-o", "luck-o-meter", "luck-o-metre", "luckometre", ADDON_NAME:lower())
  
  self:FireAddonEvent"ENABLE"
end

function Addon:OnDisable()
end




