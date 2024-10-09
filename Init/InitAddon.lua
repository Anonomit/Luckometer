
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


do
  local allLuckyItems     = {}
  local orderedLuckyItems = {}
  local luckyItemLinks    = {}
  
  Addon.allLuckyItems     = allLuckyItems
  Addon.orderedLuckyItems = orderedLuckyItems
  Addon.luckyItemLinks    = luckyItemLinks
  
  for expansion, items in Addon:Ordered{
    [Addon.expansions.era] = {
      -- 1832,
      -- 4616,
      5373,
      -- 12721,
      -- 12722,
      -- 12723,
      -- 13473,
      -- 19972,
      -- 21744,
      -- 21746,
    },
    [Addon.expansions.tbc] = {
      -- 25212,
      -- 25542,
      -- 28528,
      30507,
      -- 38289,
    },
    [Addon.expansions.wrath] = {
      -- 45858,
      -- 49783,
      -- 50452,
      -- 198647,
    },
    [Addon.expansions.cata] = {
      -- 63216,
      63317,
      -- 63742,
      -- 63745,
      -- 63772,
    },
  } do
    if expansion <= Addon.expansionLevel then
      for _, id in ipairs(items) do
        allLuckyItems[id] = true
        orderedLuckyItems[#orderedLuckyItems+1] =id
        
        Addon.ItemCache(id):OnCache(function(item)
          local icon = format("|T%s:16|t", item:GetIcon())
          local quality = item:GetQuality()
          local name = ITEM_QUALITY_COLORS[quality].color:WrapTextInColorCode(item:GetName())
          luckyItemLinks[id] = format("%s %s", icon, name)
        end)
      end
    end
  end
  
  function Addon:GetOwnedLuckyItems()
    local luckyItems = {}
    
    for _, id in ipairs(orderedLuckyItems) do
      if GetItemCount(id) > 0 then
        luckyItems[#luckyItems+1] = id
      end
    end
    
    return luckyItems
  end
  
end



