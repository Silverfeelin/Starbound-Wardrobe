require "/scripts/util.lua"

--[[
  Script containing utility functions for the Wardrobe Interface mod.
  Generally, functions in this script are expected to work with only the arguments
  passed to the function.
]]

wutil = {}

wutil.rarities = {
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
function wutil.fixImagePath(path, image)
  return not path and image or image:find("^/") and image or (path .. image):gsub("//", "/")
end

--[[
  Returns the icon for the given item. Does not apply any color option.
  @return - Absolute asset path to image.
]]
function wutil.getIconForItem(item)
  return wutil.fixImagePath(item.path, item.icon)
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
function wutil.getParametersForShowing(item, colorIndex)
  if
    not colorIndex
    or (item and item.colorOptions and colorIndex > #item.colorOptions)
  then
    colorIndex = 0
  end
  local name = item and (item.shortdescription or item.name or "Name missing") or "No selection"
  local dir = item and wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[colorIndex + 1] or nil)
  local icon = "/assetMissing.png"
  if dir then icon = wutil.getIconForItem(item) .. dir
  else dir = "" end
  local rarity = item and item.rarity and wutil.rarities[item.rarity] or wutil.rarities["common"]
  return { name = name, colorIndex = colorIndex, icon = icon, dir = dir, rarity = rarity }
end

--[[
  Alternate function that calls widget.setImage. Uses "/assetMissing.png" if the
  given image path is invalid.
  @param w - Widget to set the image on.
  @param p - Absolute asset path to the image to set.
]]
function wutil.setWidgetImage(w, p)
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
function wutil.filterList(items, filter)
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
function wutil.getEntityPortrait()
  return world.entityPortrait(player.id(), "full")
end

function wutil.getBodyPortrait()
  return util.filter(
    wutil.getEntityPortrait(),
    function(item) return not item.image:find("^/items") end
  )
end

function wutil.getIdleFrames()
  local portrait = wutil.getBodyPortrait()

  return {
    arm = portrait[1].image:match('/%w+%.png:([%w%.]+)') or "idle.1",
    body = portrait[5].image:match('/%w+%.png:([%w%.]+)') or "idle.1"
  }
end

--[[
  Converts a color option to a replace directive.
  @param colorOption - Color option table, as stored in item configurations.
  @return - Formatted directive string for the color option.
]]
function wutil.colorOptionToDirectives(colorOption)
  if not colorOption then return "" end
  local dir = "?replace"
  for k,v in pairs(colorOption) do
    dir = dir .. ";" .. k .. "=" .. v
  end
  return dir
end

wutil.placeholders = {
  head = { name = "cupidshead", count = 1 },
  chest = { name = "cupidschest", count = 1 },
  legs = { name = "cupidslegs", count = 1 },
  back = { name = "cupidsback", count = 1 }
}
wutil.placeholders.headCosmetic = wutil.placeholders.head
wutil.placeholders.chestCosmetic = wutil.placeholders.chest
wutil.placeholders.legsCosmetic = wutil.placeholders.legs
wutil.placeholders.backCosmetic = wutil.placeholders.back

function wutil.giveItem(item, category, equip)
  local oppositeCategory = category:find("Cosmetic") and category:gsub("Cosmetic", "") or (category .. "Cosmetic")
  local equipped = player.equippedItem(category)
  local oppositeEquipped = player.equippedItem(oppositeCategory)

-- TODO: Helper method for this cuz I've used it multiple times.
  local params = {}
  if item then
    params.directives = item.directives
    params.colorIndex = item.colorIndex
    params.shortdescription = item.shortdescription
    params.inventoryIcon = item.icon
  end

  if equip then
    -- Equip the item, add the previous to the inventory.
    if equipped then
      if not oppositeEquipped then player.setEquippedItem(oppositeCategory, wutil.placeholders[category]) end
      player.giveItem(equipped)
      if not oppositeEquipped then player.setEquippedItem(oppositeCategory, nil) end
    end
    player.setEquippedItem(category, item and {name=item.name,parameters=params} or nil)
  elseif item then
    -- Add the item to the inventory; do not equip it.
    if not equipped then player.setEquippedItem(category, wutil.placeholders[category]) end
    if not oppositeEquipped then player.setEquippedItem(oppositeCategory, wutil.placeholders[category]) end
    player.giveItem({name=item.name,parameters=params})
    if not equipped then player.setEquippedItem(category, nil) end
    if not oppositeEquipped then player.setEquippedItem(oppositeCategory, nil) end
  end
end

function wutil.setVisible(widgetNames, bool)
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
