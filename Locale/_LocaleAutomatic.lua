
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)



local strLower = string.lower
local strFind  = string.find
local strMatch = string.match
local strGsub  = string.gsub

local tostring = tostring



local locale = GetLocale()



local actual = {}
local L = setmetatable({}, {
  __index = function(self, key)
    if not actual[key] then
      actual[key] = key
      Addon:Throwf("%s: Missing automatic translation for '%s'", ADDON_NAME, tostring(key))
    end
    return actual[key]
  end,
  __newindex = function(self, key, val)
    if actual[key] then
      Addon:Warnf(ADDON_NAME..": Automatic translation for '%s' has been overwritten", tostring(key))
    end
    if type(val) == "table" then
      -- get the largest key in table
      local max = 1
      for i in pairs(val) do
        if i > max then
          max = i
        end
      end
      -- try adding values from the table in order
      for i = 1, max do
        if val[i] then
          self[key] = val[i]
          if actual[key] then
            return
          else
            Addon:Warnf(ADDON_NAME..": Automatic translation #%d failed for '%s'", i, tostring(key))
          end
        else
          Addon:Warnf(ADDON_NAME..": Automatic translation #%d failed for '%s'", i, tostring(key))
        end
      end
    elseif type(val) == "function" then
      -- use the function return value unless it errors
      local success, result = Addon:xpcall(val)
      if not success then
        Addon:Throwf("%s: Automatic translation error for '%s'", ADDON_NAME, tostring(key))
        return
      end
      actual[key] = result
    else
      actual[key] = val
    end
  end,
})
Addon.L = L



if locale == "esES" then
  L["."] = "."
  L[","] = ","
else
  L["."] = DECIMAL_SEPERATOR
  L[","] = LARGE_NUMBER_SEPERATOR
end

L["[%d,%.]+"] = function() return "[%d%" .. L[","] .. "%" .. L["."] .. "]+" end



L["Options"] = OPTIONS

L["Enable"]  = ENABLE
L["Disable"] = DISABLE
L["Enabled"] = VIDEO_OPTIONS_ENABLED
-- L["Disabled"] = ADDON_DISABLED
L["Modifiers:"] = MODIFIERS_COLON

L["never"] = function() return strLower(CALENDAR_REPEAT_NEVER) end
L["any"]   = function() return strLower(SPELL_TARGET_TYPE1_DESC) end
L["all"]   = function() return strLower(SPELL_TARGET_TYPE12_DESC) end

L["SHIFT key"] = SHIFT_KEY
L["CTRL key"]  = CTRL_KEY
L["ALT key"]   = ALT_KEY

L["Features"] = FEATURES_LABEL

L["ERROR"] = ERROR_CAPS

L["Display Lua Errors"] = SHOW_LUA_ERRORS
L["Lua Warning"] = LUA_WARNING

L["Debug"] = BINDING_HEADER_DEBUG
L["Reload UI"] = RELOADUI
L["Hide messages like this one."] = COMBAT_LOG_MENU_SPELL_HIDE



L["Reset"]      = RESET
L["Custom"]     = CUSTOM
L["Hide"]       = HIDE
L["Show"]       = SHOW

L["Category"]          = CATEGORY
L["Settings"]          = SETTINGS
-- L["Other Options"]  = UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_OTHER
L["Other"]             = FACTION_OTHER
L["Miscellaneous"]     = MISCELLANEOUS
L["Minimum"]           = MINIMUM
L["Maximum"]           = MAXIMUM

L["Manual"]          = TRACKER_SORT_MANUAL

L["All"] = ALL

-- L["Delete"]                       = DELETE



L["Classes: %s"] = ITEM_CLASSES_ALLOWED


L["%s rolls %d (%d-%d)"] = RANDOM_ROLL_RESULT


L["Filters"]           = FILTERS
L["Group Loot"]        = function() return strMatch(LOOT_GROUP_LOOT, ": *(.+)") end
L["/roll"]             = SLASH_RANDOM7
L["Loot Rolls"]        = LOOT_ROLLS
L["Win"]               = WIN
L["Yes"]               = YES
L["No"]                = NO
L["Click to Research"] = ORDER_HALL_TALENT_RESEARCH
L["Processing..."]     = BLIZZARD_STORE_PROCESSING

L["Total"]   = TOTAL
L["Average"] = GMSURVEYRATING3
L["Score:"]  = PROVING_GROUNDS_SCORE

