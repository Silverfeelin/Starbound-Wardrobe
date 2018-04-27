require "/scripts/util.lua"

--[[
  Script containing utility functions for the Wardrobe Interface mod.
  Generally, functions in this script are expected to work with only the arguments
  passed to the function.
]]

wardrobeUtil = {}

wardrobeUtil.rarities = {
  common = "/interface/inventory/itembordercommon.png",
  uncommon = "/interface/inventory/itemborderuncommon.png",
  rare = "/interface/inventory/itemborderrare.png",
  legendary = "/interface/inventory/itemborderlegendary.png",
  essential = "/interface/inventory/itemborderessential.png"
}

--[[
  Returns a fixed absolute path to the given image.
  If the image itself starts with a forward slash, it is interpreted as an absolute
  path. If the image doesn't, concatenate the path and image and remove any
  potentional duplicate forward slashes. If path is nil, just the image is
  returned.
  @param [path] - Asset path.
  @param image - Absolute or relative image path.
]]
function wardrobeUtil.fixImagePath(path, image)
  return not path and image or image:find("^/") and image or (path .. image):gsub("//", "/")
end

--[[
  Returns the icon for the given item. Does not apply any color option.
  @return - Absolute asset path to image.
]]
function wardrobeUtil.getIconForItem(item)
  return wardrobeUtil.fixImagePath(item.path, item.icon or item.inventoryIcon)
end

--[[
  Returns a table containing parameters useful for showing the given item.
  Uses default values such as 'No selection' and "/assetMissing.png" if no item is passed.
  The actual image is not returned, as the default value for this varies between item categories (table with three images for chest, unlike the other categories).
  @param item - Item to retrieve parameters for. A nil value will return parameters indicating that no item was selected.
  @param [colorIndex=1] - Preferred color index. Defaults to 1 if no value is given or the value falls outside of the available color options.
  @return - Table containing the most befitting:
    'name' (string), 'colorIndex' (number), 'icon' (path), 'dir' (string), 'rarity' (string).
]]
function wardrobeUtil.getParametersForShowing(item, colorIndex)
  if
    not colorIndex
    or (item and item.colorOptions and colorIndex > #item.colorOptions)
  then
    colorIndex = item.colorIndex or 0
  end
  local name = item and (item.shortdescription or item.name or "Name missing") or "No selection"
  local dir = item and wardrobeUtil.colorOptionToDirectives(item.colorOptions and item.colorOptions[colorIndex + 1] or nil)
  local icon = "/assetMissing.png"
  if dir then icon = wardrobeUtil.getIconForItem(item) .. dir
  else dir = "" end
  local rarity = item and item.rarity and wardrobeUtil.rarities[item.rarity] or wardrobeUtil.rarities["common"]
  return { name = name, colorIndex = colorIndex, icon = icon, dir = dir, rarity = rarity }
end

--[[
  Alternate function that calls widget.setImage. Uses "/assetMissing.png" if the
  given image path is invalid.
  @param w - Widget to set the image on.
  @param p - Absolute asset path to the image to set.
]]
function wardrobeUtil.setWidgetImage(w, p)
  if not pcall(root.imageSize, p) then p = "/assetMissing.png" end
  widget.setImage(w, p)
end

--[[
  Filters the given item collection on the given filter, and returns a new table
  containing references to the items matching the filter.
  @param items - List of items to filter.
  @param filter - String to filter items by. The item names and short descriptions
  are compared to the filter. The filter is case-insensitive.
  @return - Table containing items matching the given filter.
]]
function wardrobeUtil.filterList(items, filter)
  if type(filter) ~= "string" then return items end
  if filter == "" then return items end

  filter = filter:lower()

  local results = {}
  for _,v in pairs(items) do
    if v.shortdescription:lower():find(filter) or v.name:lower():find(filter) then
      table.insert(results, v)
    end
  end

  return results
end

--[[
  Attempts to return the full entity portrait of the user's character.
  @return - Entity portrait, or nil.
]]
function wardrobeUtil.getEntityPortrait()
  return world.entityPortrait(player.id(), "full")
end

function wardrobeUtil.getBodyPortrait()
  return util.filter(
    wardrobeUtil.getEntityPortrait(),
    function(item) return not item.image:find("^/items") end
  )
end

function wardrobeUtil.getIdleFrames()
  local portrait = wardrobeUtil.getBodyPortrait()

  return {
    arm = portrait[1].image:match('/%w+%.png:([%w%.]+)') or "idle.1",
    body = portrait[5].image:match('/%w+%.png:([%w%.]+)') or "idle.1"
  }
end

function wardrobeUtil.getColorIndex(item, fallback)
  fallback = fallback or 0
  return item and item.colorIndex or fallback
end

--[[
  Converts a color option to a replace directive.
  @param colorOption - Color option table, as stored in item configurations.
  @return - Formatted directive string for the color option.
]]
function wardrobeUtil.colorOptionToDirectives(colorOption)
  if not colorOption then return "" end
  local dir = "?replace"
  for k,v in pairs(colorOption) do
    dir = dir .. ";" .. k .. "=" .. v
  end
  return dir
end

local itemTypes = {
  headarmour = "head",
  headwear = "head",
  head = "head",
  chestarmour = "chest",
  chestwear = "chest",
  chest = "chest",
  legarmour = "legs",
  legwear = "legs",
  legs = "legs",
  backarmour = "back",
  backwear = "back",
  back = "back",
  enviroprotectionpack = "back"
}

--- Guesses item type from item category.
-- Unsafe (especially for mods) as item categories are not strict.
function wardrobeUtil.getItemType(category)
  if not category then return end
  return itemTypes[category:lower()]
end

function wardrobeUtil.getItemFromName(name)
  local cfg = root.itemConfig(name)
  local item = {
    name = name,
    path = cfg.directory,
    -- fileName unknown
    category = wardrobe.util.getItemType(cfg.config.category),
    shortdescription = cfg.config.shortdescription,
    icon = cfg.config.inventoryIcon,
    maleFrames = cfg.config.maleFrames,
    femaleFrames = cfg.config.femaleFrames,
    mask = cfg.config.mask,
    rarity = cfg.config.rarity,
    colorOptions = cfg.config.colorOptions
  }
  return item
end

--- Hex to {r,g,b} [0-255].
-- Thanks Magicks love ya.
function wardrobeUtil.getColor(hex)
    local len = #hex
    local out = {}
    for i = 1,len,2 do
        table.insert(out, tonumber(hex:sub(i,i+1), 16))
    end
    return out
end

--- Calculates the luminance from {r,g,b} [0-255].
function wardrobeUtil.getLuminance(color)
  local r, g, b = color[1], color[2], color[3]
  return (r*0.299 + g*0.587 + b*0.114) / 255;
end

--- Orders color options by luminance (based on resulting color).
-- {
--   [1] = { from = "aaaaaa", to = "ffffff", lum = 1},
--   [2] = { from = "dddddd", to = "000000", lum = 0}
-- }
-- Uses https://stackoverflow.com/a/1754281
function wardrobeUtil.orderColorOption(colorOption)
  local res = {}
  for from, to in pairs(colorOption) do
    local c = wardrobeUtil.getColor(to)
    local l = wardrobeUtil.getLuminance(c)
    table.insert(res, { from = from:lower(), to = to:lower(), lum = l})
  end

  table.sort(res, function(a,b) return a.lum > b.lum end)
  return res
end

wardrobeUtil.placeholders = {
  head = { name = "cupidshead", count = 1 },
  chest = { name = "cupidschest", count = 1 },
  legs = { name = "cupidslegs", count = 1 },
  back = { name = "cupidsback", count = 1 }
}
wardrobeUtil.placeholders.headCosmetic = wardrobeUtil.placeholders.head
wardrobeUtil.placeholders.chestCosmetic = wardrobeUtil.placeholders.chest
wardrobeUtil.placeholders.legsCosmetic = wardrobeUtil.placeholders.legs
wardrobeUtil.placeholders.backCosmetic = wardrobeUtil.placeholders.back

function wardrobeUtil.itemParameters(item)
  if not item then return {} end
  local params = {}
  params.directives = item.directives
  params.colorIndex = item.colorIndex
  params.shortdescription = item.shortdescription
  params.inventoryIcon = item.icon or item.inventoryIcon
  params.mask = item.mask
  return params
end

function wardrobeUtil.setVisible(widgetNames, bool)
  if type(widgetNames) == "string" then
    widget.setVisible(widgetNames, bool)
  elseif type(widgetNames) == "table" then
    for _,w in ipairs(widgetNames) do
      widget.setVisible(w, bool)
    end
  else
    error("Can't convert " .. type(widgetNames) .. " to string or table.")
  end
end

--[[
  Logs environmental functions, tables and nested functions.
]]
function logENV()
  for i,v in pairs(_ENV) do
    if type(v) == "function" then
      sb.logInfo("%s", i)
    elseif type(v) == "table" then
      for j,k in pairs(v) do
        sb.logInfo("%s.%s (%s)", i, j, type(k))
      end
    end
  end
end
