
local ADDON_NAME, Data = ...


local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)



local strLower = string.lower
local strFind  = string.find
local strMatch = string.match
local strGsub  = string.gsub

local tostring = tostring


local function TrimSpaces(text)
  return strMatch(strMatch(text, "^ *(.*)"), "^(.-) *$")
end


local locale = GetLocale()


--[[
L["key"] = value

value should be a string, but can also be a function that returns a string

value could also be a list of strings or functions that return strings. the first truthy value will be used
  a nil element will throw an error and continue to the next element
  a false element will fail silently and continue to the next element

a value of nil will throw an error and fail
a value of false will fail silently

accessing a key with no value will throw an error and return the key
]]


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
        elseif val[i] ~= false then
          Addon:Warnf(ADDON_NAME..": Automatic translation #%d failed for '%s'", i, tostring(key))
        end
      end
    elseif type(val) == "function" then
      -- use the function return value unless it errors
      if not Addon:xpcallSilent(val, function(err) Addon:Throwf("%s: Automatic translation error for '%s' : %s", ADDON_NAME, tostring(key), err) end) then
        return
      end
      local success, result = Addon:xpcall(val)
      if not success then
        Addon:Throwf("%s: Automatic translation error for '%s'", ADDON_NAME, tostring(key))
        return
      end
      self[key] = result
    elseif val ~= false then
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




L["Unknown"] = UNKNOWN

L["Enable"]      = ENABLE
L["Disable"]     = DISABLE
L["Enable All"]  = ENABLE_ALL_ADDONS
L["Disable All"] = DISABLE_ALL_ADDONS
L["Enabled"]     = VIDEO_OPTIONS_ENABLED
L["Disabled"]    = ADDON_DISABLED
L["Modifiers:"]  = MODIFIERS_COLON

L["Yes"] = YES
L["No"]  = NO

L["any"]   = function() return strLower(SPELL_TARGET_TYPE1_DESC) end
L["all"]   = function() return strLower(SPELL_TARGET_TYPE12_DESC) end
L["never"] = function() return strLower(CALENDAR_REPEAT_NEVER) end
L["none"]  = function() return strLower(NONE_CAPS) end

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



L["Reset"]  = RESET
L["Custom"] = CUSTOM
L["Hide"]   = HIDE
L["Show"]   = SHOW

L["Category"] = CATEGORY

L["Other"]         = FACTION_OTHER
L["Miscellaneous"] = MISCELLANEOUS
L["Minimum"]       = MINIMUM
L["Maximum"]       = MAXIMUM

L["Manual"] = TRACKER_SORT_MANUAL

L["All"] = ALL

L["Delete"] = DELETE
L["Are you sure you want to permanently delete |cffffffff%s|r?"] = CONFIRM_COMPACT_UNIT_FRAME_PROFILE_DELETION



L["Classes: %s"] = ITEM_CLASSES_ALLOWED


L["%s rolls %d (%d-%d)"] = RANDOM_ROLL_RESULT


L["Settings"]         = SETTINGS
L["Options"]          = OPTIONS
L["Other Options"]    = UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_OTHER
L["General Options"]  = COMPACT_UNIT_FRAME_PROFILE_SUBTYPE_ALL
L["Advanced Options"] = ADVANCED_OPTIONS
L["Display Options"]  = DISPLAY_OPTIONS
L["Chat Options"]     = CHAT_OPTIONS_LABEL
L["Loot Options"]     = UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_LOOT
L["Help"]             = HELP_LABEL
L["These options can improve ease of access."] = ACCESSIBILITY_SUBTEXT
L["Show Tutorials"]   = SHOW_TUTORIALS

L["Please select one of the following options:"] = HARASSMENT_TEXT



L["Loot Roll"]               = LOOT_ROLL
L["Loot Rolls"]              = LOOT_ROLLS
L["|4Loot Roll:Loot Rolls;"] = function() return format("|4%s:%s;", LOOT_ROLL, LOOT_ROLLS) end
L["Click to Research"]       = ORDER_HALL_TALENT_RESEARCH
L["Processing..."]           = BLIZZARD_STORE_PROCESSING
L["Research Complete"]       = GARRISON_TALENT_RESEARCH_COMPLETE
L["Total"]                   = TOTAL
L["Total:"]                  = FROM_TOTAL
L["Average"]                 = GMSURVEYRATING3
L["Score:"]                  = PROVING_GROUNDS_SCORE

L["Stats"]           = PET_BATTLE_STATS_LABEL
L["Filter"]          = FILTER
L["Filters"]         = FILTERS
L["Filter %s"]       = function() return strGsub(DEFAULT_COMBATLOG_FILTER_NAME, "%%d", "%%s") end
L["Character"]       = CHARACTER
L["Select"]          = LFG_LIST_SELECT
L["Alliance"]        = FACTION_ALLIANCE
L["Horde"]           = FACTION_HORDE
L["Neutral"]         = FACTION_STANDING_LABEL4
L["Male"]            = MALE
L["Female"]          = FEMALE
L["None"]            = NPC_NAMES_DROPDOWN_NONE
L["Me"]              = COMBATLOG_FILTER_STRING_ME
L["Any level"]       = GUILD_RECRUITMENT_ANYLEVEL
L["Level"]           = LEVEL
L["Level Range"]     = LEVEL_RANGE
L["Level Range:"]    = BATTLEFIELD_LEVEL
L["%d-%d"]           = PVP_RECORD_DESCRIPTION
L["Level %d"]        = UNIT_LEVEL_TEMPLATE
L["-->"]             = function() return strMatch(SELECT_CATEGORY, "^%S+") end
L["Max Level"]       = GUILD_RECRUITMENT_MAXLEVEL
L["Level %d-%d"]     = MEETINGSTONE_LEVEL
L["Inventory"]       = INVENTORY_TOOLTIP
L["Required items:"] = TURN_IN_ITEMS
L["Requires %s"]     = LOCKED_WITH_ITEM

L["Group Loot"]   = function() return strMatch(LOOT_GROUP_LOOT, ": *(.+)") end
L["/roll"]        = SLASH_RANDOM7
L["Win"]          = WIN
L["Players"]      = TUTORIAL_TITLE19
L["Type"]         = TYPE
L["Need"]         = NEED
L["Greed"]        = GREED
L["Disenchant"]   = ROLL_DISENCHANT
L["Items"]        = ITEMS
L["Item Quality"] = COLORBLIND_ITEM_QUALITY
L["Item Level"]   = LFG_LIST_ITEM_LEVEL_INSTR_SHORT
L["Limit to %s"]  = LFG_LIST_CROSS_FACTION
L["Unlimited"]    = UNLIMITED


L["History"]                       = HISTORY
L["Switch Page"]                   = LOOT_NEXT_PAGE
L["Page %d"]                       = PAGE_NUMBER
L["Page %d / %d"]                  = COLLECTION_PAGE_NUMBER
L["%d:%02d AM"]                    = TIME_TWELVEHOURAM
L["%d:%02d PM"]                    = TIME_TWELVEHOURPM
L["%02d:%02d"]                     = TIMEMANAGER_TICKER_24HOUR
L["Type:"]                         = CHOOSE_YOUR_DUNGEON
L["Item"]                          = HELPFRAME_ITEM_TITLE
L["You Won!"]                      = YOU_WON_LABEL
L["%d |4item:items; in inventory"] = ITEMS_IN_INVENTORY

L["Left-Click"] = function() return strMatch(NPE_TARGETFIRSTMOB, "^|c........(.-)|r") end
L["SHIFT"] = SHIFT_KEY_TEXT
L["CTRL"] = CTRL_KEY_TEXT
L["Check out this item!"] = SOCIAL_ITEM_PREFILL_TEXT_GENERIC
L["Link Item to Chat"] = GUILD_NEWS_LINK_ITEM
L["View in Dressing Room"] = VIEW_IN_DRESSUP_FRAME

do
  local rollPattern = Addon:ChainGsub(RANDOM_ROLL_RESULT, {"%%%d%$", "%%"})
  
  local groupLootRollPattern = Addon:ChainGsub(rollPattern, {"%(%%d%-%%d%)", "(%%s)"})
  local manualRollPattern    = Addon:ChainGsub(rollPattern, {"%%d", "%%s"})
  
  L["%s rolls %d (%s)"]    = groupLootRollPattern
  L["%s rolls %s (%s-%s)"] = manualRollPattern
end


L["Display"] = DISPLAY
L["Speed"] = SPEED
L["Research Time:"] = RESEARCH_TIME_LABEL

L["AddOn Memory"] = function() return TrimSpaces(strMatch(TOTAL_MEM_KB_ABBR, "[^:]+")) end
L["%s (Full)"   ] = BATTLEFIELD_FULL
L["Obliterate"]   = OBLITERATE_BUTTON
L["Cleanup"]      = BAG_FILTER_CLEANUP

L["N/A"] = NOT_APPLICABLE

