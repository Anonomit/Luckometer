
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
_G.Luckometer = Addon



Addon.AceSerializer = LibStub"AceSerializer-3.0"
Addon.ItemCache = LibStub"ItemCache"





local tblSort = table.sort



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
  local luckyItemNames    = {}
  
  Addon.allLuckyItems     = allLuckyItems
  Addon.orderedLuckyItems = orderedLuckyItems
  Addon.luckyItemNames    = luckyItemNames
  
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
        orderedLuckyItems[#orderedLuckyItems+1] = id
        
        Addon.ItemCache(id):OnCache(function(item)
          local icon = Addon:MakeIcon(item:GetIcon())
          local quality = item:GetQuality()
          local name = ITEM_QUALITY_COLORS[quality].color:WrapTextInColorCode(item:GetName())
          luckyItemNames[id] = format("%s %s", icon, name)
        end)
      end
    end
  end
  
  function Addon:GetOwnedLuckyItems()
    local luckyItems = {}
    
    for _, id in ipairs(orderedLuckyItems) do
      if GetItemCount(id) > 0 then
        luckyItems[id] = true
      end
    end
    
    return luckyItems
  end
end



function Addon:GetFriendlyDate(datetime)
  local d = C_DateAndTime.GetCalendarTimeFromEpoch(datetime*1e6)
  
  local weekDay = CALENDAR_WEEKDAY_NAMES[d.weekday]
  local month   = CALENDAR_FULLDATE_MONTH_NAMES[d.month]
  
  local dateFormat = self:GetGlobalOption("display", "dateFormat")
  local dateString = format(dateFormat, d.year, d.month, d.monthDay, month, weekDay)
  
  local timeString
  if self:GetGlobalOption("display", "use24hTime") then
    timeString = self.L["%02d:%02d"]
  else
    if d.hour <= 12 then
      if d.hour == 0 then
        d.hour = 12
      end
      timeString = self.L["%d:%02d AM"]
    else
      d.hour = d.hour - 12
      timeString = self.L["%d:%02d PM"]
    end
  end
  timeString = format(timeString, d.hour, d.minute)
  
  
  local text = format("%s %s", dateString, timeString)
  
  return text
end



do
  local FACTION_SORT = Addon:MakeLookupTable{"Alliance", "Horde", "Neutral", "Unknown"}
  
  function Addon:GetOrderedGUIDS()
    local orderedGUIDs = {}
    local guidData     = {}
    for guid, charData in pairs(Addon:GetGlobalOptionQuiet"characters") do
      orderedGUIDs[#orderedGUIDs+1] = guid
      guidData[guid] = {charData.name, FACTION_SORT[Addon:GetFactionFromGUID(guid)], Addon:GetRealmFromGUID(guid)}
    end
    
    tblSort(orderedGUIDs, function(a, b)
      local nameA, factionA, realmA, realmNameA = unpack(guidData[a])
      local nameB, factionB, realmB, realmNameB = unpack(guidData[b])
      
      if realmA ~= realmB then
        if realmB == GetRealmID() then
          return false
        else
          return realmA == GetRealmID() or realmNameA < realmNameB
        end
      elseif factionA ~= factionB then
        if factionB == Addon.MY_FACTION then
          return false
        else
          return factionA == Addon.MY_FACTION or factionA < factionB
        end
      elseif nameA ~= nameB then
        if nameB == Addon.MY_NAME then
          return false
        else
          return nameA == Addon.MY_NAME or nameA < nameB
        end
      else
        if b == Addon.MY_GUID then
          return false
        else
          return a == Addon.MY_GUID or a < b
        end
      end
    end)
    
    return orderedGUIDs
  end
end

