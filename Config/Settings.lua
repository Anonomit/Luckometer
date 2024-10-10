
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
      -- luckyItems = {
      --   enable   = true,
      --   operator = "any",
      --   items    = Addon.allLuckyItems,
      -- },
    },
    group = {
      enable = true,
      roll = {
        won = {
          [0] = true,
          [1] = true,
        },
        -- type = {
        --   true,
        --   true,
        --   true,
        -- },
        -- numPlayers = {
        --   enable = false,
        --   min    = 1,
        --   max    = 40,
        -- },
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
    },
  }
  local record = Addon:Copy(filters)
  
  
  local fakeAddon = {
    db = {
      profile = {
        
        enabled = true,
        
        
      },
      
      global = {
        
        rolls = {},
        
        characters = {
          -- ["**"] = {},
        },
        realms     = {},
        
        filters = filters,
        record  = record,
        
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
