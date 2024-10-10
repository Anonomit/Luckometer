
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)






local dbInitFuncs

do
  local self = Addon
  
  local shared = {}
  
  dbInitFuncs = {
    profile = {
      FirstRun = nil,
      upgrades = {
        
      },
      AlwaysRun = nil,
    },
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
          self:SetGlobalOptionConfigQuiet(newRolls, "rolls")
          
          
          -- reset filters setting
          self:ResetGlobalOptionConfigQuiet"filters"
        end,
      },
      AlwaysRun = function()
        self:DelayCalculationCallbacks(function()
          for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
            self:SetGlobalOptionConfigQuiet(self.IndexedQueue(rolls), "rolls", guid)
          end
        end)
      end,
    },
  }
end



function Addon:OnInitialize()
  self.db        = self.AceDB:New(("%sDB"):format(ADDON_NAME), self:MakeDefaultOptions(), true)
  self.dbDefault = self.AceDB:New({}                         , self:MakeDefaultOptions(), true)
  
  self:RunInitializeCallbacks()
end

function Addon:OnEnable()
  self.version = self.SemVer(GetAddOnMetadata(ADDON_NAME, "Version"))
  self:InitDB(dbInitFuncs, "global")
  self:InitDB(dbInitFuncs, "profile")
  self:GetDB().RegisterCallback(self, "OnProfileChanged", function() self:InitDB(dbInitFuncs, "profile") end)
  self:GetDB().RegisterCallback(self, "OnProfileCopied" , function() self:InitDB(dbInitFuncs, "profile") end)
  self:GetDB().RegisterCallback(self, "OnProfileReset"  , function() self:InitDB(dbInitFuncs, "profile") end)
  
  self:InitChatCommands("lucky", "lm", "lom", "l-o-m", "lucko", "luck-o", "luck-o-meter", "luck-o-metre", "luckometre", ADDON_NAME:lower())
  
  self:RunEnableCallbacks()
end

function Addon:OnDisable()
end




