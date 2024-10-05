
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)







function Addon:InitDB()
  local configVersion = self.SemVer(self:GetGlobalOption"version" or tostring(self.version))
  
  
  if not self:GetGlobalOption"version" then -- first run
  
  else -- upgrade data schema
    if configVersion <= self.SemVer"1.2.0" then
      -- separate rolls by guid
      local newRolls = {}
      
      local rolls = self.IndexedQueue(self:GetGlobalOptionQuiet"rolls")
      for i, rollString in rolls:iter() do
        local rollData = self:DeserializeRollData(rollString)
        
        local guid = rollData.guid
        rollData.guid = nil
        if not newRolls[guid] then
          newRolls[guid] = self.IndexedQueue()
        end
        
        newRolls[guid]:Add(self:SerializeRollData(rollData))
      end
      
      self:SetGlobalOptionConfigQuiet(newRolls, "rolls")
      
      -- reset filters setting
      self:ResetGlobalOptionConfigQuiet("filters")
    end
  end
  
  
  -- init roll db
  do
    for guid, rolls in pairs(self:GetGlobalOptionQuiet"rolls") do
      self:SetGlobalOptionConfigQuiet(self.IndexedQueue(rolls), "rolls", guid)
    end
  end
  
  if self:GetGlobalOption"version" ~= tostring(self.version) then
    self:SetGlobalOptionConfig(tostring(self.version), "version")
  end
end


function Addon:InitProfile()
  local configVersion = self.SemVer(self:GetOption"version" or tostring(self.version))
  
  
  if not self:GetOption"version" then -- first run
  
  else -- upgrade data schema
    
  end
  
  if self:GetOption"version" ~= tostring(self.version) then
    self:SetOptionConfig(tostring(self.version), "version")
  end
end


function Addon:OnInitialize()
  self.db        = self.AceDB:New(("%sDB"):format(ADDON_NAME), self:MakeDefaultOptions(), true)
  self.dbDefault = self.AceDB:New({}                         , self:MakeDefaultOptions(), true)
  
  self:RunInitializeCallbacks()
end

function Addon:OnEnable()
  self.version = self.SemVer(GetAddOnMetadata(ADDON_NAME, "Version"))
  self:InitDB()
  self:InitProfile()
  self:GetDB().RegisterCallback(self, "OnProfileChanged", "InitProfile")
  self:GetDB().RegisterCallback(self, "OnProfileCopied" , "InitProfile")
  self:GetDB().RegisterCallback(self, "OnProfileReset"  , "InitProfile")
  
  self:InitChatCommands("lucky", "lm", "lom", "lucko", "luck-o-meter", "luck-o-metre", "luckometre", ADDON_NAME:lower())
  
  self:RunEnableCallbacks()
end

function Addon:OnDisable()
end




