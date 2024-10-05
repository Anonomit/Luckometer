
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
_G.Luckometer = Addon



Addon.AceSerializer = LibStub"AceSerializer-3.0"
Addon.ItemCache = LibStub"ItemCache"





do
  local roundedItemLevel = Addon:Round(Addon.MAX_ITEM_LEVEL, 50)
  if roundedItemLevel <= Addon.MAX_ITEM_LEVEL then
    roundedItemLevel = roundedItemLevel + 50
  end
  Addon.MAX_ITEM_LEVEL_SLIDER = roundedItemLevel
end






