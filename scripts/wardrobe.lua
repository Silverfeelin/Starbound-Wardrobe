require "/scripts/util.lua"

wardrobe = {}

wardrobe.widgets = {
  preview = "wardrobePreview",
  storage = "wardrobeStorage"
}

wardrobe.rarities = {
  common = "/interface/inventory/grayborder.png",
  uncommon = "/interface/inventory/greenborder.png",
  rare = "/interface/inventory/blueborder.png",
  legendary = "/interface/inventory/purpleborder.png",
}

--[[
  Collection of list items for the preview widget.
  Separated in two categories, one for default images (dummy or character) and
  one for custom images (selected items).
]]
wardrobe.preview = {
  default = {},
  custom = {}
}

--[[
  Current item selection. Keys representing item slot, value representing
  selected item. Valid keys: 'head', 'chest', 'legs', 'back'.
]]
wardrobe.selection = {}

--[[
  Idle frames. Used to display selected items in the "character" preview mode.
  Overwritten in wardrobe.loadPreview.
]]
wardrobe.idleFrames = {
  arm = "idle.1",
  body = "idle.1"
}

------------------------------
--[[ Engine/MUI Callbacks ]]--
------------------------------

--[[
  Initializes the Wardrobe.
  This function is called every time the interface is opened from the MUI Main
  Menu.
]]
function wardrobe.init()

  --logENV()

  mui.setTitle("Wardrobe", "It's time to dress up!")
  mui.setIcon("/interface/wardrobe/icon.png")

  wardrobe.selection = {}
  wardrobe.preview.custom = {}
  wardrobe.preview.default = {}

  wardrobe.resetWidgets()
end

--[[
  Resets all widgets. Should be used when re-initializing the interface.
  Also alters relevent data, eg. reverting selection back to equipped items.
]]
function wardrobe.resetWidgets()
  widget.setText("wardrobeHatName", "No selection")
  widget.setText("wardrobeChestName", "No selection")
  widget.setText("wardrobeLegsName", "No selection")
  widget.setText("wardrobeBackName", "No selection")
  widget.setImage("wardrobeHatRarity", wardrobe.rarities["common"])
  widget.setImage("wardrobeChestRarity", wardrobe.rarities["common"])
  widget.setImage("wardrobeLegsRarity", wardrobe.rarities["common"])
  widget.setImage("wardrobeBackRarity", wardrobe.rarities["common"])
  widget.setImage("wardrobeHatIcon", "/assetMissing.png")
  widget.setImage("wardrobeChestIcon", "/assetMissing.png")
  widget.setImage("wardrobeLegsIcon", "/assetMissing.png")
  widget.setImage("wardrobeBackIcon", "/assetMissing.png")

  wardrobe.loadPreview()
  wardrobe.showItems("wardrobeHatScroll.list", "head")
  wardrobe.showItems("wardrobeChestScroll.list", "chest")
  wardrobe.showItems("wardrobeLegsScroll.list", "legs")
  wardrobe.showItems("wardrobeBackScroll.list", "back")
end

--[[
  Update function, called every game tick by MUI while the interface is opened.
  @param dt - Delay between this and the previous update tick.
]]
function wardrobe.update(dt)

end

--[[
  Uninitializes the Wardrobe. Called by MUI when the interface is closed.
  May not be called properly when the MMU interface is closed directly.
]]
function wardrobe.uninit()
  wardrobe.closeLeftBar()
  wardrobe.closeRightBar()
  for i=1,16 do
    widget.setVisible("wardrobeHatColor_" .. i, false)
    widget.setVisible("wardrobeChestColor_" .. i, false)
    widget.setVisible("wardrobeLegsColor_" .. i, false)
    widget.setVisible("wardrobeBackColor_" .. i, false)
  end
end

-----------------------
--[[ MUI Callbacks ]]--
-----------------------

--[[
  MUI Callback function. Called when the settings menu is opened.
  (Currently) not in use.
]]
function wardrobe.settingsOpened()

end

--[[
  MUI Callback function. Called when the settings menu is closed.
  (Currently) not in use.
]]
function wardrobe.settingsClosed()

end

--------------------------
--[[ Widget Callbacks ]]--
--------------------------

--[[
  Widget callback function. Shows the left bar and available hats.
]]
function wardrobe.showHats()
  wardrobe.showLeftBar(true)
end

--[[
  Widget callback function. Shows the left bar and available chest pieces.
]]
function wardrobe.showChests()
  wardrobe.showLeftBar(true)
end

--[[
  Widget callback function. Shows the right bar and available bottoms.
]]
function wardrobe.showLegs()
  wardrobe.showRightBar(true)
end

--[[
  Widget callback function. Shows the right bar and available back items.
]]
function wardrobe.showBacks()
  wardrobe.showRightBar(true)
end

--[[
  Widget callback function. Hides the left item selection bar bar.
]]
function wardrobe.closeLeftBar()
  wardrobe.showLeftBar(false)
end

--[[
  Widget callback function. Hides the right item selection bar bar.
]]
function wardrobe.closeRightBar()
  wardrobe.showRightBar(false)
end

--[[
  Widget callback function. Called when a hat is selected from the list.
  Shows the selected item on the preview character.
]]
function wardrobe.hatSelected()
  local sel = widget.getListSelected("wardrobeHatScroll.list")
  if sel then
    wardrobe.itemSelected(widget.getData("wardrobeHatScroll.list." .. sel))
  end
end

--[[
Widget callback function. Called when a chest piece is selected from the list.
Shows the selected item on the preview character.
]]
function wardrobe.chestSelected()
  local sel = widget.getListSelected("wardrobeChestScroll.list")
  if sel then
    wardrobe.itemSelected(widget.getData("wardrobeChestScroll.list." .. sel))
  end
end

--[[
Widget callback function. Called when bottoms are selected from the list.
Shows the selected item on the preview character.
]]
function wardrobe.legsSelected()
  local sel = widget.getListSelected("wardrobeLegsScroll.list")
  if sel then
    wardrobe.itemSelected(widget.getData("wardrobeLegsScroll.list." .. sel))
  end
end

--[[
Widget callback function. Called when a back item is selected from the list.
Shows the selected item on the preview character.
]]
function wardrobe.backSelected()
  local sel = widget.getListSelected("wardrobeBackScroll.list")
  if sel then
    wardrobe.itemSelected(widget.getData("wardrobeBackScroll.list." .. sel))
  end
end

--[[
  Widget callback function. Applies the selected color option to the selected
  hat.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectHatColor(_,d)
  wardrobe.showItem(wardrobe.selection["head"], d)
  wardrobe.selection["head"].selectedColor = d
end

--[[
  Widget callback function. Applies the selected color option to the selected
  chest piece.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectChestColor(_,d)
  wardrobe.showItem(wardrobe.selection["chest"], d)
  wardrobe.selection["chest"].selectedColor = d
end

--[[
  Widget callback function. Applies the selected color option to the selected
  bottoms.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectLegsColor(_,d)
  wardrobe.showItem(wardrobe.selection["legs"], d)
  wardrobe.selection["legs"].selectedColor = d
end

--[[
  Widget callback function. Applies the selected color option to the selected
  back item.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectBackColor(_,d)
  wardrobe.showItem(wardrobe.selection["back"], d)
  wardrobe.selection["back"].selectedColor = d
end

--[[
  Widget callback function. Gives the player all selected items in the given
  color option. Color options are applied through directives rather than the
  'colorIndex' parameter. I have no clue how to determine this value as it does
  not match the index.
]]
function wardrobe.spawn()
  if wardrobe.selection["head"] then
    local item = wardrobe.selection["head"]
    player.giveItem({name=item.name,parameters={colorIndex=(item.selectedColor - 1)}})
  end
  if wardrobe.selection["chest"] then
    local item = wardrobe.selection["chest"]
    player.giveItem({name=item.name,parameters={colorIndex=(item.selectedColor - 1)}})
  end
  if wardrobe.selection["legs"] then
    local item = wardrobe.selection["legs"]
    player.giveItem({name=item.name,parameters={colorIndex=(item.selectedColor - 1)}})
  end
  if wardrobe.selection["back"] then
    local item = wardrobe.selection["back"]
    player.giveItem({name=item.name,parameters={colorIndex=(item.selectedColor - 1)}})
  end
end

----------------------------
--[[ Wardrobe Functions ]]--
----------------------------

--[[
  Shows or hides the left item selection bar.
  @param bool - Value indicating whether to show (true) or hide (false) the
    selection bar.
]]
function wardrobe.showLeftBar(bool)
  widget.setVisible("wardrobeHatScroll", bool)
  widget.setVisible("wardrobeChestScroll", bool)
  widget.setVisible("wardrobeLeftBar", bool)
  widget.setVisible("wardrobeButtonCloseLeftBar", bool)
  widget.setVisible("wardrobeLeftBarTitle", bool)
end

--[[
  Shows or hides the right item selection bar.
  @param bool - Value indicating whether to show (true) or hide (false) the
    selection bar.
]]
function wardrobe.showRightBar(bool)
  widget.setVisible("wardrobeLegsScroll", bool)
  widget.setVisible("wardrobeBackScroll", bool)
  widget.setVisible("wardrobeRightBar", bool)
  widget.setVisible("wardrobeButtonCloseRightBar", bool)
  widget.setVisible("wardrobeRightBarTitle", bool)
end

--[[
  Loads the preview by adding layers to the preview widget.

  Custom layer order, fetched with wardrobe.preview.custom[n]:
  [1] backarm [2] [3] head emote hair body [4] [5] fluff beaks [6] frontarm [7]
  Regular use: [1] = Background, [2] = BackSleeve, [3] = BackItem, [4] = Pants,
  [5] = Shirt, [6] = Hat, [7] = FrontSleeve

  Some data you're free to skip over:
  Human: backarm backsleeve backitem head emote hair body pants shirt hat frontarm frontsleeve
  Avian: backarm backsleeve backitem head emote hair body pants shirt fluff beaks hat frontarm frontsleeve
  Hylotl: backarm backsleeve backitem head emote hair body pants shirt hat frontarm frontsleeve
  Glitch: backarm backsleeve backitem head emote hair body pants shirt hat frontarm frontsleeve
  Novakid: backarm backsleeve backitem head emote hair body pants shirt brand hat frontarm frontsleeve
  Apex: backarm backsleeve backitem head emote hair body pants shirt beard hat frontarm frontsleeve
  # == 6 => backarm head emote hair body <empty> <empty> frontarm
  # == 7 => backarm head emote hair body brand <empty> frontarm
  # == 7 => backarm head emote hair body beard <empty> frontarm
  # == 8 => backarm head emote hair body fluff beaks frontarm

  Layers 4, 6 and 7 need their ?addmask removed (if existent). Likewise, these
  layers need a mask added when a hat is selected with a valid mask.
]]
function wardrobe.loadPreview()
  sb.logInfo("Wardrobe: Loading preview.")
  local preview = wardrobe.widgets.preview

  local layers = {}

  local playerID = player.id()
  if not playerID then
    sb.logInfo("Wardrobe: Displaying the character failed; the player ID could not be found.")
    return
  else
    -- Fetch portrait and remove item layers
    local portrait = wardrobe.getEntityPortrait()
    portrait = util.filter(portrait, function(item)
      return not item.image:find("^/items")
    end)

    -- Set the layer table, using the amount of layers found in the entity portrait as a guideline.
    local portraitFrames = #portrait
    layers = {
      portrait[1].image,
      portrait[2].image,
      portrait[3].image,
      portrait[4].image:gsub('%?addmask=[^%?]+',''),
      portrait[5].image
    }

    wardrobe.idleFrames = {
      arm = layers[1]:match('/%w+%.png:([%w%.]+)') or "idle.1",
      body = layers[5]:match('/%w+%.png:([%w%.]+)') or "idle.1"
    }

    if portraitFrames > 6 then layers[6] = portrait[6].image end
    if portraitFrames > 7 then layers[7] = portrait[7].image end
    layers[8] = portrait[#portrait].image
  end

  -- Add the preview layers
  widget.clearListItems(preview)

  wardrobe.preview.default = {}
  wardrobe.preview.custom = {}

  table.insert(wardrobe.preview.custom, widget.addListItem(preview))
  wardrobe.layers = layers
  for i=1,8 do
    -- Add default layer
    local li = widget.addListItem(preview)
    if layers[i] then
      widget.setImage(preview .. "." .. li .. ".image", layers[i])
    end
    table.insert(wardrobe.preview.default, li)

    -- Add blank custom layer(s)
    local customLayers = (i == 1 or i == 5) and 2 or (i == 7 or i == 8) and 1 or 0
    for j=1,customLayers do
      table.insert(wardrobe.preview.custom, widget.addListItem(preview))
    end
  end
end

--[[
  Sets the selection for the category of the item to this item, resets the
  selected color option and displays the item.
  @param - The item selected, as stored in the item dump.
]]
function wardrobe.itemSelected(item)
  if item then
    wardrobe.selection[item.category] = item
    wardrobe.selection[item.category].selectedColor = 1
    wardrobe.showItem(item)
    wardrobe.showColors(item)
  end
end

--[[
  Shows the given item on the preview character, optionally using the
  color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showItem(item, colorIndex)
  if not item then return end
  if not colorIndex or colorIndex > #item.colorOptions then colorIndex = 1 end
  local name = item.shortdescription or item.name or "Name missing"
  local dir = wardrobe.colorOptionToDirectives(item.colorOptions and item.colorOptions[colorIndex])
  sb.logInfo("%s", dir)
  if item.category == "head" then
    local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[6]
    widget.setImage(w .. ".image", wardrobe.getDefaultImageForItem(item) .. dir)
    if item.mask then
      local mask = "?addmask=" .. wardrobe.fixImagePath(item.path, item.mask)
      w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[4]
      widget.setImage(w .. ".image", wardrobe.layers[4] .. mask)
      if wardrobe.layers[6] then
        w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[6]
        widget.setImage(w .. ".image", wardrobe.layers[6])
      end
      if wardrobe.layers[7] then
        w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[7]
        widget.setImage(w .. ".image", wardrobe.layers[7])
      end
    end

    widget.setImage("wardrobeHatIcon", wardrobe.getIconForItem(item) .. dir)
    widget.setImage("wardrobeHatRarity", wardrobe.rarities[item.rarity] or wardrobe.rarities["common"])
    widget.setText("wardrobeHatName", name)
  elseif item.category == "chest" then
    local images = wardrobe.getDefaultImageForItem(item, true)
    local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[2]
    widget.setImage(w .. ".image", images[1] .. dir)
    w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[5]
    widget.setImage(w .. ".image", images[2] .. dir)
    w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[7]
    widget.setImage(w .. ".image", images[3] .. dir)

    widget.setImage("wardrobeChestIcon", wardrobe.getIconForItem(item) .. dir)
    widget.setImage("wardrobeChestRarity", wardrobe.rarities[item.rarity] or wardrobe.rarities["common"])
    widget.setText("wardrobeChestName", name)
  elseif item.category == "legs" then
    local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[4]
    widget.setImage(w .. ".image", wardrobe.getDefaultImageForItem(item, true) .. dir)

    widget.setImage("wardrobeLegsIcon", wardrobe.getIconForItem(item) .. dir)
    widget.setImage("wardrobeLegsRarity", wardrobe.rarities[item.rarity] or wardrobe.rarities["common"])
    widget.setText("wardrobeLegsName", name)
  elseif item.category == "back" then
    local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[3]
    widget.setImage(w .. ".image", wardrobe.getDefaultImageForItem(item, true) .. dir)

    widget.setImage("wardrobeBackIcon", wardrobe.getIconForItem(item) .. dir)
    widget.setImage("wardrobeBackRarity", wardrobe.rarities[item.rarity] or wardrobe.rarities["common"])
    widget.setText("wardrobeBackName", name)
  end
end

--[[
  Populates the leftList and rightList of the given scroll area with items
  matching the given category. Clears existing entries in both lists before
  adding matches.
  @param w - Full widget reference (eg. list.scroll rather than list or scroll).
  @param category - Category used to filter items.
]]
function wardrobe.showItems(w, category)
  widget.clearListItems(w)

  local equipped = player.equippedItem(category)

  local items = root.assetJson("/wardrobe/wearables.json")
  if not items or not items[category] then sb.logError("Wardrobe: Could not load items for category %s", category) return end
  items = items[category]
  local itemCount = #items
  -- Add items in pairs of two
  for i=1,itemCount do
    local item = items[i]
    if equipped and item.name == equipped.name then wardrobe.itemSelected(item) end
    wardrobe.addItem(w .. "." .. widget.addListItem(w), item)
  end
end

--[[
  Adds an item to the given list item widget.
  @param w - Full widget reference (eg. list.123 rather than list or 123).
  @param item - Item to add, as stored in the item dump.
]]
function wardrobe.addItem(w, item)
  widget.setData(w, item)
  local images = wardrobe.getDefaultImageForItem(item)
  local dir = wardrobe.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

  if item.category == "head" then
    widget.setImage(w .. ".imageFront", images .. dir)
  elseif item.category == "chest" then
    widget.setImage(w .. ".imageBack", images[1] .. dir)
    widget.setImage(w .. ".image", images[2] .. dir)
    widget.setImage(w .. ".imageFront", images[3] .. dir)
  elseif item.category == "legs" then
    widget.setImage(w .. ".image", images .. dir)
  elseif item.category == "back" then
    widget.setImage(w .. ".imageBack", images .. dir)
  end
end

--[[
  Updates and shows color option buttons relevant for the given item. Does this
  by checking the available color options for the given item.
  @param item - Item to show color options for.
]]
function wardrobe.showColors(item)
  local w
  if item.category == "head" then
    w = "wardrobeHatColor_"
  elseif item.category == "chest" then
    w = "wardrobeChestColor_"
  elseif item.category == "legs" then
    w = "wardrobeLegsColor_"
  elseif item.category == "back" then
    w = "wardrobeBackColor_"
  end
  if w then
    for i=1,#item.colorOptions do
      widget.setVisible(w .. i, true)
      local img = "/interface/wardrobe/color.png" .. wardrobe.colorOptionToDirectives(item.colorOptions and item.colorOptions[i])
      widget.setButtonImages(w .. i, {base=img, hover=img})
    end

    for i=#item.colorOptions+1,16 do
      widget.setVisible(w .. i, false)
    end
  end
end

--[[
  Attempts to return the full entity portrait of the user's character.
  @return - Entity portrait, or nil.
]]
function wardrobe.getEntityPortrait()
  local id = player.id()
  if id then return world.entityPortrait(id, "full") end
end

--[[
  Returns an image to display the item, or a table with three images for chest
  pieces. If useCharacterFrames is true, the wardrobe.idleFrames are used to
  determine which frames are returned. The default frame is "idle.1".
  Uses player.gender() to determine whether male or female frames should be
  used.
  @param item - Item to fetch image for. Category is determined from the
    configuration of the item.
  @param [useCharacterFrames=false] - Value indicating whether to use
    wardrobe.idleFrames (true) or idle.1 (false).
]]
function wardrobe.getDefaultImageForItem(item, useCharacterFrames)
  local bodyFrame = useCharacterFrames and wardrobe.idleFrames.body or "idle.1"
  local armFrame = useCharacterFrames and wardrobe.idleFrames.arm or "idle.1"

  if item.category == "head" then
    local image = wardrobe.fixImagePath(item.path, item.maleFrames) .. ":normal"
    return image
  elseif item.category == "chest" then
    local image = wardrobe.fixImagePath(item.path, player.gender() == "male" and item.maleFrames.body or item.femaleFrames.body) .. ":" .. bodyFrame
    local imageBack = wardrobe.fixImagePath(item.path, player.gender() == "male" and item.maleFrames.backSleeve or item.femaleFrames.backSleeve) .. ":" .. armFrame
    local imageFront = wardrobe.fixImagePath(item.path, player.gender() == "male" and item.maleFrames.frontSleeve or item.femaleFrames.frontSleeve) .. ":" .. armFrame
    return {imageBack, image, imageFront}
  elseif item.category == "legs" then
    local image = wardrobe.fixImagePath(item.path, player.gender() == "male" and item.maleFrames or item.femaleFrames) .. ":" .. bodyFrame
    return image
  elseif item.category == "back" then
    local image = wardrobe.fixImagePath(item.path, item.maleFrames) .. ":" .. bodyFrame
    return image
  end
end

--[[
  Returns the icon for the given item. Does not apply any color option.
  @return - Absolute asset path to image.
]]
function wardrobe.getIconForItem(item)
  return wardrobe.fixImagePath(item.path, item.icon)
end

--[[
  Returns a fixed absolute path to the given image.
  If the image itself starts with a forward slash, it is interpreted as an absolute
  path. If the image doesn't, concatenate the path and image and remove any
  potentional duplicate forward slashes. If path is nil, just the image is
  returned.
  @param [path] - Asset path.
  @param image - Absolute or relative image path.
]]
function wardrobe.fixImagePath(path, image)
  return not path and image or image:find("^/") and image or (path .. image):gsub("//", "/")
end

--[[
  Converts a color option to a replace directive.
  @param colorOption - Color option table, as stored in item configurations.
  @return - Formatted directive string for the color option.
]]
function wardrobe.colorOptionToDirectives(colorOption)
  if not colorOption then return "" end
  local dir = "?replace"
  for k,v in pairs(colorOption) do
    dir = dir .. ";" .. k .. "=" .. v
  end
  return dir
end

--[[
  Returns data stored in a widget dedicated to passing information between
  script lifetimes. This due to the script resetting each time the interface
  is re-opened, while widgets remain as they were until the game session is
  reloaded.
  @return - Stored data.
]]
function wardrobe.getInterfaceData()
  return widget.getData(wardrobe.widgets.storage)
end

--[[
  Sets data on a widget dedicated to passing information between script
  lifetimes. This due to the script resetting each time the interface is
  re-opened, while widgets remain as they were until the game session is
  reloaded.
  It is highly recommended to retrieve the interface data before setting it
  (see wardrobe.getInterfaceData), as the data will be overwritten.
  @param data - Data to set on the widget. Overwrites existing data.
]]
function wardrobe.setInterfaceData(data)
  widget.setData(wardrobe.widgets.storage, data)
end

--------------------------
--[[ Useful functions ]]--
--------------------------

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

--[[
  Returns the player's entity ID. Works around the limitations of Starbound's
  API, but may be unreliable.
  @return - Player's entity ID, or nil.
]]
function player.id()
  local id = nil
  pcall(function()
    local uid = player.ownShipWorldId():match":(.+)"
    local pos =  world.findUniqueEntity(uid):result()
    id = world.entityQuery(pos,3,{order = "nearest",includedTypes = {"player"}})[1]
  end)
  return id
end
