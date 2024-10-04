
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
_G.Luckometer = Addon



Addon.AceSerializer = LibStub"AceSerializer-3.0"
Addon.ItemCache = LibStub"ItemCache"



Addon:RegisterInitializeCallback(function(self)
  self:InitPopup("CONFIRM_DELETE_CHARACTER", {
    text         = self.L["Are you sure you want to permanently delete |cffffffff%s|r?"],
    -- text         = format("%s|n|n%%d |4%s:%s;", self.L["Are you sure you want to permanently delete |cffffffff%s|r?"], self.L["Loot Roll"], self.L["Loot Rolls"]),
    button1      = YES,
    button2      = NO,
    acceptDelay  = 1,
    timeout      = 0,
    whileDead    = 1,
    hideOnEscape = 1,
    OnAccept = function(self)
      local guid      = self.data.guid
      local nameRealm = self.data.coloredNameRealm
      local numRolls  = self.data.numRolls
      local filt      = self.data.filt
      
      local count = Addon:DeleteCharacter(guid)
      
      -- Addon:ThrowfAssert(count == numRolls, "Expected to delete %d rolls, but actually deleted %d rolls", numRolls, count)
      
      if count == 0 then -- if anything was actually deleted then the window was already refreshed
        Addon:NotifyChange()
      end
    end,
    
    OnShow = function(self)
      Addon:CloseConfig()
    end,
    OnHide = function(self)
      Addon:OpenConfig()
    end,
  })
  
  
  do
    local UPDATE_STATICPOPUPS_DYNAMICALLY = false
    
    Addon:RegisterOptionSetHandler(function(self, val, ...)
      if not UPDATE_STATICPOPUPS_DYNAMICALLY then return end
      local path = {...}
      if path[2] ~= "global" then return end
      if path[3] == "rolls" then
        self:NotifyChange()
        if Addon:IsPopupShown"CONFIRM_DELETE_CHARACTER" then
          local data = Addon:GetPopupData"CONFIRM_DELETE_CHARACTER"
          local count = self:CountRolls(data.filt)
          if count ~= data.numRolls then
            data.numRolls = count
            Addon:EditPopupText("CONFIRM_DELETE_CHARACTER", data.nameRealm, count)
          end
        end
      end
    end)
  end
end)








do
  local roundedItemLevel = Addon:Round(Addon.MAX_ITEM_LEVEL, 50)
  if roundedItemLevel <= Addon.MAX_ITEM_LEVEL then
    roundedItemLevel = roundedItemLevel + 50
  end
  Addon.MAX_ITEM_LEVEL_SLIDER = roundedItemLevel
end






