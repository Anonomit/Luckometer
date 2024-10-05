
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)





function Addon:MakeDefaultOptions()
  local fakeAddon = {
    db = {
      profile = {
        
        enabled = true,
        
        
      },
      
      global = {
        
        rolls = {},
        
        characters = {},
        realms     = {},
        
        filters = {
          character = {
            ["**"] = true,
          },
          characterLevel = {
            enable = false,
            min    = 1,
            max    = Addon.MAX_LEVEL,
          },
          rollMethod = {
            group  = true,
            manual = true,
          },
          -- rollType = {
          --   true,
          --   true,
          --   true,
          -- },
          rollWon = {
            [0] = true,
            [1] = true,
          },
          itemQuality = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
          },
          itemLevel = {
            enable = false,
            min    = 1,
            max    = Addon.MAX_ITEM_LEVEL_SLIDER,
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
          rollLimits = {
            min = {
              enable = false,
              min    = 1,
              max    = 1,
            },
            max = {
              enable = false,
              min    = 100,
              max    = 100,
            },
            -- span = {
            --   min = 1,
            --   max = 100,
            -- },
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
