
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
          character = {
            ["**"] = true,
          },
          -- characterLevel = {
          --   min = 1,
          --   max = Addon.MAX_LEVEL,
          -- },
          rollType = {
            group  = true,
            manual = true,
          },
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
          -- invSlot = {
          --   ["**"] = true,
          -- },
          -- itemClass = {
          --   ["**"] = true,
          -- },
          -- itemSubclass = {
          --   ["**"] = true,
          -- },
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
