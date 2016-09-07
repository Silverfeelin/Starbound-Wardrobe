require "/scripts/util.lua"

wardrobe = {}

wardrobe.widgets = {
  preview = "wardrobePreview",
  storage = "wardrobeStorage"
}

wardrobe.rarities = {
  common = "/interface/inventory/itembordercommon.png",
  uncommon = "/interface/inventory/itemborderuncommon.png",
  rare = "/interface/inventory/itemborderrare.png",
  legendary = "/interface/inventory/itemborderlegendary.png",
  essential = "/interface/inventory/itemborderessential.png"
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

  wardrobe.searching = false
  wardrobe.searchCategories = {}
  wardrobe.searchDelay, wardrobe.searchTick = 10, 10

  wardrobe.resetWidgets()
end

--[[
  Resets all widgets. Should be used when re-initializing the interface.
  Also alters relevent data, eg. reverting selection back to equipped items.
]]
function wardrobe.resetWidgets()
  widget.setText("wardrobeHeadName", "No selection")
  widget.setText("wardrobeChestName", "No selection")
  widget.setText("wardrobeLegsName", "No selection")
  widget.setText("wardrobeBackName", "No selection")
  wardrobe.setWidgetImage("wardrobeHeadRarity", wardrobe.rarities["common"])
  wardrobe.setWidgetImage("wardrobeChestRarity", wardrobe.rarities["common"])
  wardrobe.setWidgetImage("wardrobeLegsRarity", wardrobe.rarities["common"])
  wardrobe.setWidgetImage("wardrobeBackRarity", wardrobe.rarities["common"])
  wardrobe.setWidgetImage("wardrobeHeadIcon", "/assetMissing.png")
  wardrobe.setWidgetImage("wardrobeChestIcon", "/assetMissing.png")
  wardrobe.setWidgetImage("wardrobeLegsIcon", "/assetMissing.png")
  wardrobe.setWidgetImage("wardrobeBackIcon", "/assetMissing.png")

  wardrobe.loadPreview()
  wardrobe.showItems("wardrobeHeadScroll.list", "head", true)
  wardrobe.showItems("wardrobeChestScroll.list", "chest", true)
  wardrobe.showItems("wardrobeLegsScroll.list", "legs", true)
  wardrobe.showItems("wardrobeBackScroll.list", "back", true)
end

--[[
  Update function, called every game tick by MUI while the interface is opened.
  @param dt - Delay between this and the previous update tick.
]]
function wardrobe.update(dt)
  if wardrobe.searching then
    wardrobe.searchTick = wardrobe.searchTick - 1
    if wardrobe.searchTick <= 0 then
      for k,v in pairs(wardrobe.searchCategories) do
        wardrobe.showItems("wardrobe" .. k .. "Scroll.list", k:lower(), false, v)
      end
      wardrobe.searching = false
    end
  end
end

--[[
  Uninitializes the Wardrobe. Called by MUI when the interface is closed.
  May not be called properly when the MMU interface is closed directly.
]]
function wardrobe.uninit()
  wardrobe.closeLeftBar()
  wardrobe.closeRightBar()
  for i=1,16 do
    widget.setVisible("wardrobeHeadColor_" .. i, false)
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
  Shows or hides the left item selection bar.
  @param bool - Value indicating whether to show (true) or hide (false) the
    selection bar.
]]
function wardrobe.showLeftBar(bool)
  if type(bool) ~= "boolean" then bool = true end
  widget.setVisible("wardrobeHeadScroll", bool)
  widget.setVisible("wardrobeChestScroll", bool)
  widget.setVisible("wardrobeLeftBar", bool)
  widget.setVisible("wardrobeButtonCloseLeftBar", bool)
  widget.setVisible("wardrobeLeftBarTitle", bool)
  widget.setVisible("wardrobeHeadSearchImage", bool)
  widget.setVisible("wardrobeHeadSearchText", bool)
  widget.setVisible("wardrobeChestSearchImage", bool)
  widget.setVisible("wardrobeChestSearchText", bool)
end

--[[
  Shows or hides the right item selection bar.
  @param [bool=true] - Value indicating whether to show (true) or hide (false) the
    selection bar.
]]
function wardrobe.showRightBar(bool)
  if type(bool) ~= "boolean" then bool = true end
  widget.setVisible("wardrobeLegsScroll", bool)
  widget.setVisible("wardrobeBackScroll", bool)
  widget.setVisible("wardrobeRightBar", bool)
  widget.setVisible("wardrobeButtonCloseRightBar", bool)
  widget.setVisible("wardrobeRightBarTitle", bool)
  widget.setVisible("wardrobeLegsSearchImage", bool)
  widget.setVisible("wardrobeLegsSearchText", bool)
  widget.setVisible("wardrobeBackSearchImage", bool)
  widget.setVisible("wardrobeBackSearchText", bool)
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
  Widget callback function. Called when a head is selected from the list.
  Shows the selected item on the preview character.
]]
function wardrobe.headSelected()
  local sel = widget.getListSelected("wardrobeHeadScroll.list")
  if sel then
    wardrobe.selectItem(widget.getData("wardrobeHeadScroll.list." .. sel), "head")
  end
end

--[[
Widget callback function. Called when a chest piece is selected from the list.
Shows the selected item on the preview character.
]]
function wardrobe.chestSelected()
  local sel = widget.getListSelected("wardrobeChestScroll.list")
  if sel then
    wardrobe.selectItem(widget.getData("wardrobeChestScroll.list." .. sel), "chest")
  end
end

--[[
Widget callback function. Called when bottoms are selected from the list.
Shows the selected item on the preview character.
]]
function wardrobe.legsSelected()
  local sel = widget.getListSelected("wardrobeLegsScroll.list")
  if sel then
    wardrobe.selectItem(widget.getData("wardrobeLegsScroll.list." .. sel), "legs")
  end
end

--[[
Widget callback function. Called when a back item is selected from the list.
Shows the selected item on the preview character.
]]
function wardrobe.backSelected()
  local sel = widget.getListSelected("wardrobeBackScroll.list")
  if sel then
    wardrobe.selectItem(widget.getData("wardrobeBackScroll.list." .. sel), "back")
  end
end

--[[
  Widget callback function. Applies the selected color option to the selected
  head.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectHeadColor(_,d)
  wardrobe.showHead(wardrobe.selection["head"], d)
  wardrobe.selection["head"].selectedColor = d
end

--[[
  Widget callback function. Applies the selected color option to the selected
  chest piece.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectChestColor(_,d)
  wardrobe.showChest(wardrobe.selection["chest"], d)
  wardrobe.selection["chest"].selectedColor = d
end

--[[
  Widget callback function. Applies the selected color option to the selected
  bottoms.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectLegsColor(_,d)
  wardrobe.showLegs(wardrobe.selection["legs"], d)
  wardrobe.selection["legs"].selectedColor = d
end

--[[
  Widget callback function. Applies the selected color option to the selected
  back item.
  @param d - Widget data, contains selected color option index.
]]
function wardrobe.selectBackColor(_,d)
  wardrobe.showBack(wardrobe.selection["back"], d)
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

--[[
  Widget callback function.
  Sets the head category to be filtered when the user stops typing.
  @param w - Widget name, used to fetch the value to filter by.
]]
function wardrobe.filterHead(w)
  wardrobe.filter("Head", w)
end

--[[
  Widget callback function.
  Sets the chest category to be filtered when the user stops typing.
  @param w - Widget name, used to fetch the value to filter by.
]]
function wardrobe.filterChest(w)
  wardrobe.filter("Chest", w)
end

--[[
  Widget callback function.
  Sets the legs category to be filtered when the user stops typing.
  @param w - Widget name, used to fetch the value to filter by.
]]
function wardrobe.filterLegs(w)
  wardrobe.filter("Legs", w)
end

--[[
  Widget callback function.
  Sets the back category to be filtered when the user stops typing.
  @param w - Widget name, used to fetch the value to filter by.
]]
function wardrobe.filterBack(w)
  wardrobe.filter("Back", w)
end

----------------------------
--[[ Wardrobe Functions ]]--
----------------------------

--[[
  Sets the list for the given category to be filtered when the user stops typing
  for a set duration. This check can be found in the update function.
  Resets the search delay.
  @param category - Item category to filter.
  @param wid - Widget name, used to retrieve the value to filter by.
]]
function wardrobe.filter(category, wid)
  local text = widget.getText(wid)
  wardrobe.searchTick = wardrobe.searchDelay
  wardrobe.searching = true
  wardrobe.searchCategories[category] = text
end

--[[
  Loads the preview by adding layers to the preview widget.

  Custom layer order, fetched with wardrobe.preview.custom[n]:
  [1] backarm [2] [3] head emote hair body [4] [5] fluff beaks [6] frontarm [7]
  Regular use: [1] = Background, [2] = BackSleeve, [3] = BackItem, [4] = Pants,
  [5] = Shirt, [6] = Head, [7] = FrontSleeve

  Some data you're free to skip over:
  Human: backarm backsleeve backitem head emote hair body pants shirt head frontarm frontsleeve
  Avian: backarm backsleeve backitem head emote hair body pants shirt fluff beaks head frontarm frontsleeve
  Hylotl: backarm backsleeve backitem head emote hair body pants shirt head frontarm frontsleeve
  Glitch: backarm backsleeve backitem head emote hair body pants shirt head frontarm frontsleeve
  Novakid: backarm backsleeve backitem head emote hair body pants shirt brand head frontarm frontsleeve
  Apex: backarm backsleeve backitem head emote hair body pants shirt beard head frontarm frontsleeve
  # == 6 => backarm head emote hair body <empty> <empty> frontarm
  # == 7 => backarm head emote hair body brand <empty> frontarm
  # == 7 => backarm head emote hair body beard <empty> frontarm
  # == 8 => backarm head emote hair body fluff beaks frontarm

  Layers 4, 6 and 7 need their ?addmask removed (if existent). Likewise, these
  layers need a mask added when a head is selected with a valid mask.
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
      wardrobe.setWidgetImage(preview .. "." .. li .. ".image", layers[i])
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
function wardrobe.selectItem(item, category)
  category = category or item.category
  wardrobe.selection[category] = item
  if item then
    wardrobe.selection[category].selectedColor = 1
  end
  wardrobe.showItemForCategory[category](item)
  wardrobe.showColors(item, category)
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
function wardrobe.getParametersForShowing(item, colorIndex)
  if not colorIndex or item and colorIndex > #item.colorOptions then colorIndex = 1 end
  local name = item and (item.shortdescription or item.name or "Name missing") or "No selection"
  local dir = item and wardrobe.colorOptionToDirectives(item.colorOptions and item.colorOptions[colorIndex])
  local icon = "/assetMissing.png"
  if dir then icon = wardrobe.getIconForItem(item) .. dir
  else dir = "" end
  local rarity = item and item.rarity and wardrobe.rarities[item.rarity] or wardrobe.rarities["common"]
  return { name = name, colorIndex = colorIndex, icon = icon, dir = dir, rarity = rarity }
end

--[[
  Shows the given head item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the head item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showHead(item, colorIndex)
  local params = wardrobe.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[6]
  wardrobe.setWidgetImage(w .. ".image", image .. params.dir)

  if item and item.mask then
    local mask = "?addmask=" .. wardrobe.fixImagePath(item.path, item.mask)
    w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[4]
    wardrobe.setWidgetImage(w .. ".image", wardrobe.layers[4] .. mask)
    if wardrobe.layers[6] then
      w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[6]
      wardrobe.setWidgetImage(w .. ".image", wardrobe.layers[6])
    end
    if wardrobe.layers[7] then
      w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[7]
      wardrobe.setWidgetImage(w .. ".image", wardrobe.layers[7])
    end
  end

  wardrobe.setWidgetImage("wardrobeHeadIcon", params.icon)
  wardrobe.setWidgetImage("wardrobeHeadRarity", params.rarity)
  widget.setText("wardrobeHeadName", params.name)
end

--[[
  Shows the given chest item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the chest item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showChest(item, colorIndex)
  if not colorIndex or item and colorIndex > #item.colorOptions then colorIndex = 1 end
  local name = item and (item.shortdescription or item.name or "Name missing") or "No selection"
  local dir = item and wardrobe.colorOptionToDirectives(item.colorOptions and item.colorOptions[colorIndex])
  local icon = "/assetMissing.png"
  if dir then icon = wardrobe.getIconForItem(item) .. dir
  else dir = "" end
  local images = item and wardrobe.getDefaultImageForItem(item, true) or { "/assetMissing.png", "/assetMissing.png", "/assetMissing.png" }

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[2]
  wardrobe.setWidgetImage(w .. ".image", images[1] .. dir)
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[5]
  wardrobe.setWidgetImage(w .. ".image", images[2] .. dir)
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[7]
  wardrobe.setWidgetImage(w .. ".image", images[3] .. dir)

  wardrobe.setWidgetImage("wardrobeChestIcon", icon)
  wardrobe.setWidgetImage("wardrobeChestRarity", item and item.rarity and wardrobe.rarities[item.rarity] or wardrobe.rarities["common"])
  widget.setText("wardrobeChestName", name)
end

--[[
  Shows the given legs item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the legs item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showLegs(item, colorIndex)
  local params = wardrobe.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[4]
  wardrobe.setWidgetImage(w .. ".image", image .. params.dir)

  wardrobe.setWidgetImage("wardrobeLegsIcon", params.icon .. params.dir)
  wardrobe.setWidgetImage("wardrobeLegsRarity", params.rarity)
  widget.setText("wardrobeLegsName", params.name)
end

--[[
  Shows the given back item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the back item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showBack(item, colorIndex)
  local params = wardrobe.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[3]
  wardrobe.setWidgetImage(w .. ".image", image .. params.dir)

  wardrobe.setWidgetImage("wardrobeBackIcon", params.icon .. params.dir)
  wardrobe.setWidgetImage("wardrobeBackRarity", params.rarity)
  widget.setText("wardrobeBackName", params.name)
end

--[[
  Reference collection for all show<Category> functions.
  Accessing is done through wardrobe.showItemForCategory[category](item, colorIndex).
]]
wardrobe.showItemForCategory = {
  head = wardrobe.showHead,
  chest = wardrobe.showChest,
  legs = wardrobe.showLegs,
  back = wardrobe.showBack
}

--[[
  Populates the leftList and rightList of the given scroll area with items
  matching the given category. Clears existing entries in both lists before
  adding matches.
  @param w - Full widget reference (eg. list.scroll rather than list or scroll).
  @param category - Category used to filter items.
]]
function wardrobe.showItems(w, category, selectEquipped, filter)
  widget.clearListItems(w)

  -- Add blank item to clear selection.
  local clear = widget.addListItem(w)
  wardrobe.setWidgetImage(w .. "." .. clear .. ".imageFront", "/assetMissing.png?replace;ffffff00=ffffffff?crop;0;0;43;43?blendmult=/interface/wardrobe/x.png;-13;-13?replace;ffffffff=00000000")

  category = category:lower()
  if category == "head" then category = "head"
  elseif category == "top" or category == "shirt" then category = "chest"
  elseif category == "skirt" or category == "leg" then category = "legs"
  elseif category == "cape" or category == "enviroprotectionpack" then category = "back" end

  local equipped
  if selectEquipped then
    equipped = player.equippedItem(category)
  end

  local items = root.assetJson("/wardrobe/wearables.json")
  if not items or not items[category] then sb.logError("Wardrobe: Could not load items for category %s", category) return end
  items = items[category]

  items = wardrobe.filterList(items, filter)

  local itemCount = #items
  -- Add items in pairs of two
  for i=1,itemCount do
    local item = items[i]
    if equipped and item.name == equipped.name then wardrobe.selectItem(item, category) end
    wardrobe.addItem(w .. "." .. widget.addListItem(w), item)
  end
end

--[[
  Filters the given item collection on the given filter, and returns a new table
  containing references to the items matching the filter.
  @param items - List of items to filter.
  @param filter - String to filter items by. The item names and short descriptions
  are compared to the filter. The filter is case-insensitive.
  @return - Table containing items matching the given filter.
]]
function wardrobe.filterList(items, filter)
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
  Adds an item to the given list item widget.
  @param w - Full widget reference (eg. list.123 rather than list or 123).
  @param item - Item to add, as stored in the item dump.
]]
function wardrobe.addItem(w, item)
  widget.setData(w, item)
  local images = wardrobe.getDefaultImageForItem(item)
  local dir = wardrobe.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

  if item.category == "head" then
    wardrobe.setWidgetImage(w .. ".imageFront", images .. dir)
  elseif item.category == "chest" then
    wardrobe.setWidgetImage(w .. ".imageBack", images[1] .. dir)
    wardrobe.setWidgetImage(w .. ".image", images[2] .. dir)
    wardrobe.setWidgetImage(w .. ".imageFront", images[3] .. dir)
  elseif item.category == "legs" then
    wardrobe.setWidgetImage(w .. ".image", images .. dir)
  elseif item.category == "back" then
    wardrobe.setWidgetImage(w .. ".imageBack", images .. dir)
  end
end

--[[
  Updates and shows color option buttons relevant for the given item. Does this
  by checking the available color options for the given item.
  @param item - Item to show color options for.
]]
function wardrobe.showColors(item, category)
  local w
  category = category or item.category
  if not item then item = { colorOptions = {} } end

  if category == "head" then
    w = "wardrobeHeadColor_"
  elseif category == "chest" then
    w = "wardrobeChestColor_"
  elseif category == "legs" then
    w = "wardrobeLegsColor_"
  elseif category == "back" then
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

function wardrobe.setWidgetImage(w, p)
  if not pcall(root.imageSize, p) then p = "/assetMissing.png" end
  widget.setImage(w, p)
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
