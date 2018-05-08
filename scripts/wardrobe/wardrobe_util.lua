require "/scripts/util.lua"

--- Script containing utility functions for the Wardrobe Interface mod.
-- Generally, functions in this script are expected to work with only the arguments passed to the function.
wardrobeUtil = {}

--- Placeholder items that can be used when spawning items without equipping them.
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

--- Lookup table for item slot based on item category.
-- Keys are all lowercase.
wardrobeUtil.itemTypes = {
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

--- Returns an absolute path to the given image.
-- If path is nil, just the image is returned.
-- If the image itself starts with a forward slash, it is interpreted as an absolute path.
-- If the image doesn't, concatenate the path and image.
-- @param path Asset path. Can be nil.
-- @param image Absolute or relative image path.
-- @return Absolute image path.
function wardrobeUtil.fixImagePath(path, image)
  if type(image) == "table" then
    error(string.format("Unexpected table value for image. path: %s image: %s", path, sb.print(image)))
  end

  return not path and image or image:find("^/") and image or (path .. image):gsub("//", "/")
end

--- Returns the icon for the given wardrobe item. Does not apply any color option.
-- @param item Wardrobe item.
-- @return - Absolute asset path to image.
function wardrobeUtil.getIconForItem(item)
  return wardrobeUtil.fixImagePath(item.path, item.icon or item.inventoryIcon)
end

--- Returns a table containing parameters useful for showing the given item.
-- Uses default values such as 'No selection' and "/assetMissing.png" if no item is passed.
-- The actual image is not returned, as the default value for this varies between item categories (table with three images for chest, unlike the other categories).
-- @param item Item to retrieve parameters for. A nil value will return parameters indicating that no item was selected.
-- @param [colorIndex=0] Preferred color index. Defaults to 1 if no value is given or the value falls outside of the available color options.
-- @return Table containing the most befitting:
--  'name' (string), 'colorIndex' (number), 'icon' (path), 'dir' (string).
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
  return { name = name, colorIndex = colorIndex, icon = icon, dir = dir }
end

--- Returns a filtered collection of the given items.
-- @param items List of items to filter.
-- @param filter String to filter items by (case-insensitive).
--  The item names and short descriptions are compared to the filter.
-- @return Table containing items matching the given filter.
function wardrobeUtil.filterList(items, filter)
  if type(filter) ~= "string" then return items end
  if filter == "" then return items end

  filter = filter:lower()

  local warned = false -- Because I know this will happen and spam the logs.
  return util.filter(items, function(item)
    if type(item) == "table" then
      return item.name and item.name:lower():find(filter)
        or item.shortdescription and item.shortdescription:lower():find(filter)
    else -- String
      if not warned then warned = true; sb.logError("Wardrobe: Can't filter item names. Well we can but then people could only search for the item names and not descriptions.") end
      return true
    end
  end)
end

--- Returns the full entity portrait of the user's character.
-- This contains both body and clothing layers.
-- @return Entity portrait
function wardrobeUtil.getEntityPortrait()
  return world.entityPortrait(player.id(), "full")
end

--- Returns the fully entity portrait, minus the clothing layers.
-- There can be 6 to 8 layers, depending on the species (i.e. beard/fluff).
-- @return Entity portrait without clothing.
function wardrobeUtil.getBodyPortrait()
  return util.filter(
    wardrobeUtil.getEntityPortrait(),
    function(item) return not item.image:find("^/items") end
  )
end

--- Returns the idle frames used by the given body portrait (no clothing layers).
-- @param [portrait=wardrobeUtil.getBodyPortrait()] Entity portrait with only body layers.
-- @return { arm = "idle.x", body = "idle.y" }.  Defaults to "idle.1" if the value could not be determined.
-- @see wardrobeUtil.getBodyPortrait
function wardrobeUtil.getIdleFrames()
  local portrait = wardrobeUtil.getBodyPortrait()

  return {
    arm = portrait[1].image:match('/%w+%.png:([%w%.]+)') or "idle.1",
    body = portrait[5].image:match('/%w+%.png:([%w%.]+)') or "idle.1"
  }
end

--- Returns the color index from the item.
-- @param item Wardrobe item.
-- @param [fallback=0] Fallback value if item is nil or no colorIndex is set.
function wardrobeUtil.getColorIndex(item, fallback)
  fallback = fallback or 0
  return item and item.colorIndex or fallback
end

--- Brings the color index down from a generated number down to 0 <= index < #colorOptions.
-- @param item Wardrobe item.
function wardrobeUtil.fixColorIndex(item)
  if not item then return end
  if not item.colorIndex then item.colorIndex = 0 return end

  local colorOptions = item.colorOptions or root.itemConfig(item.name).config.colorOptions or {}
  local c = #colorOptions
  item.colorIndex = (c == 0 and 0) or (item.colorIndex and item.colorIndex % c) or 0
end

--- Converts a color option to a replace directive.
-- @param colorOption Color option dictionary.
-- @return - ?replace directive.
function wardrobeUtil.colorOptionToDirectives(colorOption)
  if not colorOption then return "" end
  local dir = "?replace"
  for k,v in pairs(colorOption) do
    dir = dir .. ";" .. k .. "=" .. v
  end
  return dir
end

--- Guesses item type from item category.
-- Unsafe (especially for mods) as item categories are not strict.
function wardrobeUtil.getItemType(category)
  return wardrobeUtil.itemTypes[category:lower()]
end

--- Returns a wardrobe item config for the given item name
-- Everything but the fileName is present.
-- @param name Item name.
-- @return Wardrobe item.
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
-- @param hex ffffff
-- @return {255, 255, 255}
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
-- @param colorOption Color option dictionary.
-- @return Ordered colors. See description for format.
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

--- Turns a wardrobe item into item parameters (not descriptor).
-- @param item Wardrobe item.
-- @return Item parameters.
function wardrobeUtil.itemParameters(item)
  if not item then return {} end
  local params = {}
  params.directives = item.directives
  params.colorIndex = item.colorIndex
  params.shortdescription = item.shortdescription
  params.inventoryIcon = item.icon or item.inventoryIcon
  params.mask = item.mask
  params.outfit = item.outfit
  return params
end

--- String iterator for strings and tables of strings.
-- @param ... One or more strings or tables of strings.
-- @return Iterator used to iterate over all strings.
function wardrobeUtil.iterateStrings(...)
  local ws = {...}
  local strs = {}
  for _,v in ipairs(ws) do
    if type(v) == "string" then
      table.insert(strs, v)
    elseif type(v) == "table" then
      for _,w in ipairs(v) do
        table.insert(strs, w)
      end
    end
  end

  local i = 0
  local c = #strs
  return function()
    i = i + 1
    if i <= c then return strs[i] end
  end
end

--- Sets one or more widgets (in)visible.
-- Widget names prefixed with a ! are set to the opposite value.
-- @param widgetNames widget name (string) or widget names (table).
-- @param bool Show (true) or hide (false).
function wardrobeUtil.setVisible(widgetNames, bool)
  if type(widgetNames) == "string" then
    if widgetNames:find("!") == 1 then bool = not bool end
    widget.setVisible(widgetNames, bool)
  elseif type(widgetNames) == "table" then
    for _,w in ipairs(widgetNames) do
      if w:find("!") ~= 1 then
        widget.setVisible(w, bool)
      else
        widget.setVisible(w, not bool)
      end
    end
  else
    error("Can't convert " .. type(widgetNames) .. " to string or table.")
  end
end

--- Calls status.statusProperty and turns it into a list.
-- Accounts for [n] and ["n"] keys.
-- @param str Status property.
-- @return Lua table.
function wardrobeUtil.statusList(str)
  local items = status.statusProperty(str, {}) or {}
  local results = {}
  local i = 1

  while true do
    local item = items[tostring(i)] or items[i]
    if not item then break end
    table.insert(results, item)
    i = i + 1
  end
  return results
end

--- Logs environmental functions, tables and nested functions.
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
