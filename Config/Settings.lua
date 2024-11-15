
local ADDON_NAME, Data = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)





function Addon:MakeDefaultOptions()
  
  local filters = {
    character = {
      guid = {
        ["**"] = true,
      },
      level = {
        enable = false,
        min    = 1,
        max    = Addon.MAX_LEVEL,
      },
      luckyItems = {
        enable   = false,
        operator = "any",
        items    = Addon:Copy(Addon.allLuckyItems),
      },
    },
    group = {
      enable = true,
      roll = {
        won = {
          [0] = true,
          [1] = true,
        },
        type = {
          true,
          true,
          true,
        },
        numPlayers = {
          enable = false,
          min    = 1,
          max    = 40,
        },
      },
      item = {
        quality = {
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
        level = {
          enable = false,
          min    = 1,
          max    = Addon.MAX_ITEM_LEVEL_SLIDER,
        },
        -- invSlot = {
        --   ["**"] = true,
        -- },
        -- class = {
        --   ["**"] = true,
        -- },
        -- subClass = {
        --   ["**"] = true,
        -- },
      },
    },
    
    manual = {
      enable = true,
      roll = {
        limits = {
          min = {
            enable = false,
            min    = 0,
            max    = 999999,
          },
          max = {
            enable = false,
            min    = 1,
            max    = 1000000,
          },
          -- span = {
          --   min = 1,
          --   max = 100,
          -- },
        },
      },
    },
  }
  -- local record = Addon:Copy(filters)
  
  
  local fakeAddon = {
    db = {
      global = {
        
        maxRollStorage = {
          global = {
            enable = false,
            limit  = 50000,
          },
          character = {
            enable = false,
            limit  = 50000,
          },
        },
        
        rolls = {},
        
        characters = {},
        realms     = {},
        
        filters = filters,
        -- record  = record,
        
        calculations = {
          filterSpeed = 100,
          refreshAfterFilter = false,
          startImmediately = true,
        },
        
        display = {
          use24hTime  = true,
          dateFormat = "%5$s %4$s %3$d %1$d",
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
