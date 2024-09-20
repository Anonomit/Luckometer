
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)


local tblConcat = table.concat


function Addon:MakeDefaultOptions()
  local fakeAddon = {
    db = {
      profile = {
        
        enabled = true,
        
        
      },
      
      global = {
        
        realms     = {},
        characters = {},
        rolls      = {},
        
        filters = {
          -- character = {
          --   ["**"] = true,
          -- },
          -- class = {
          --   ["**"] = true,
          -- },
          -- race = {
          --   ["**"] = true,
          -- },
          -- sex = {
          --   [2] = true,
          --   [3] = true,
          -- },
          -- characterLevel = {
          --   min = 1,
          --   max = Addon.MAX_LEVEL,
          -- },
          rollType = {
            group  = true,
            manual = true,
          },
          -- invSlot = {
          --   ["**"] = true,
          -- },
          -- itemClass = {
          --   ["**"] = true,
          -- },
          -- itemSubclass = {
          --   ["**"] = true,
          -- },
          -- itemQuality = {
          --   ["**"] = true,
          -- },
          rollWon = {
            [0] = true,
            [1] = true,
          },
        },
        
        -- Debug options
        debug = false,
        
        debugShowLuaErrors   = true,
        debugShowLuaWarnings = true,
          
        debugOutput = {
          ["*"] = false,
        },
      },
    },
  }
  return fakeAddon.db
end
