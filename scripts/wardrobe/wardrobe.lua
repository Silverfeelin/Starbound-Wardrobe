require "/scripts/util.lua"
require "/scripts/wardrobe/wutil.lua"
require "/scripts/wardrobe/wardrobe_callbacks.lua"
require "/scripts/vec2.lua"

if not wardrobe then
  wardrobe  = {}
end

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

------------------------------
--[[ Engine Callbacks ]]--
------------------------------

--[[
  Initializes the Wardrobe.
  This function is called every time the interface is opened from the MUI Main
  Menu.
]]
function init()
  wardrobe.cb.init()

  wardrobe.widgets = config.getParameter("widgetNames")
  wardrobe.idleFrames = config.getParameter("idleFrames")

  wardrobe.setConfigParameters()

  wardrobe.selection = {}
  wardrobe.preview.custom = {}
  wardrobe.preview.default = {}

  wardrobe.searching = false
  wardrobe.searchCategories = {}
  wardrobe.searchDelay, wardrobe.searchTick = 10, 10

  wardrobe.resetWidgets()

  -- TEST
  for i=1,300 do
    -- body...
    local li = widget.addListItem("legsSelection.list")
    local c = widget.bindCanvas("legsSelection.list." .. li .. ".canvas")
    wardrobe.drawDummy(c, {body="/items/armors/human/human-tier1/chestm.png:idle.1"})
    widget.setData("legsSelection.list." .. li .. ".first", i * 3)
    wardrobe.drawDummy(c, {
      body="/items/armors/human/human-tier1/chestm.png:idle.1",
      backArm="/items/armors/human/human-tier1/bsleeve.png:idle.1",
      frontArm="/items/armors/human/human-tier1/fsleeve.png:idle.1"
    }, {43,0})
    widget.setData("legsSelection.list." .. li .. ".second", "s" .. i * 3 + 1)
    wardrobe.drawDummy(c, {body="/items/armors/human/human-tier1/chestm.png:idle.1"}, {86, 0})
    widget.setData("legsSelection.list." .. li .. ".third", i * 3 + 2)
  end
end

--[[
  Resets all widgets. Should be used when re-initializing the interface.
  Also alters relevent data, eg. reverting selection back to equipped items.
]]
function wardrobe.resetWidgets()
  widget.setText("head.name", "No selection")
  widget.setText("chest.name", "No selection")
  widget.setText("legs.name", "No selection")
  widget.setText("back.name", "No selection")

  wardrobe.loadPreview()
end

--[[
  Update function, called every game tick by MUI while the interface is opened.
  @param dt - Delay between this and the previous update tick.
]]
function update(dt)
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
function uninit()
  wardrobe.closeLeftBar()
  wardrobe.closeRightBar()
  for i=1,16 do
    widget.setVisible("wardrobeHeadColor_" .. i, false)
    widget.setVisible("wardrobeChestColor_" .. i, false)
    widget.setVisible("wardrobeLegsColor_" .. i, false)
    widget.setVisible("wardrobeBackColor_" .. i, false)
  end
end

--------------------------
--[[ Widget Callbacks ]]--
--------------------------

--[[
  Shows or hides the left item selection bar.
  @param bool - Value indicating whether to show (true) or hide (false) the selection bar.
  @param category - head or chest.
]]
function wardrobe.showLeftBar(bool, category)
  bool = not not bool
  wutil.setVisible(wardrobe.widgets.left, bool)

  if category == "head" or category == "chest" then
    wutil.setVisible(wardrobe.widgets[category .. "Selection"], bool)
  end
end

--[[
  Shows or hides the right item selection bar.
  @param bool - Value indicating whether to show (true) or hide (false) the selection bar.
  @param category - legs or back.
]]
function wardrobe.showRightBar(bool, category)
  bool = not not bool
  wutil.setVisible(wardrobe.widgets.right, bool)

  if category == "legs" or category == "back" then
    wutil.setVisible(wardrobe.widgets[category .. "Selection"], bool)
  end
end

--[[
  Widget callback function. Hides the left item selection bar.
]]
function wardrobe.closeLeftBar()
  wardrobe.showLeftBar(false)
  wutil.setVisible(wardrobe.widgets.headSelection, false)
  wutil.setVisible(wardrobe.widgets.chestSelection, false)
end

--[[
  Widget callback function. Hides the right item selection bar.
]]
function wardrobe.closeRightBar()
  wardrobe.showRightBar(false)
  wutil.setVisible(wardrobe.widgets.legsSelection, false)
  wutil.setVisible(wardrobe.widgets.backSelection, false)
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
function wardrobe.legsSelected(w, d)
  local sel = "legsSelection.list." .. widget.getListSelected("legsSelection.list") .. "." .. w
  local data = widget.getData(sel)
  sb.logInfo("Widget: %s | Param: %s | Data Widget: %s | Data: %s", w, d, sel, data)

  --[[
  local sel = widget.getListSelected("wardrobeLegsScroll.list")
  if sel then
    wardrobe.selectItem(widget.getData("wardrobeLegsScroll.list." .. sel), "legs")
  end
  ]]
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
  Reference collection for all select<Category>Color functions.
  Accessing is done through wardrobe.selectColorForCategory[category](_, colorIndex).
]]
wardrobe.selectColorForCategory = {
  head = wardrobe.selectHeadColor,
  chest = wardrobe.selectChestColor,
  legs = wardrobe.selectLegsColor,
  back = wardrobe.selectBackColor
}

--[[
  Widget callback function. Gives the player all selected items in the given
  color options.
]]
function wardrobe.spawn()
  local suffix = wardrobe.getConfigParameter("useArmorSlot") and "" or "Cosmetic"

  wutil.giveItem(wardrobe.selection["head"], "head" .. suffix, false)
  wutil.giveItem(wardrobe.selection["chest"], "chest" .. suffix, false)
  wutil.giveItem(wardrobe.selection["legs"], "legs" .. suffix, false)
  wutil.giveItem(wardrobe.selection["back"], "back" .. suffix, false)
end

--[[
  Widget callback function. Equips all selected items using the given
  color options.
]]
function wardrobe.equip()
  local suffix = wardrobe.getConfigParameter("useArmorSlot") and "" or "Cosmetic"

  wutil.giveItem(wardrobe.selection["head"], "head" .. suffix, true)
  wutil.giveItem(wardrobe.selection["chest"], "chest" .. suffix, true)
  wutil.giveItem(wardrobe.selection["legs"], "legs" .. suffix, true)
  wutil.giveItem(wardrobe.selection["back"], "back" .. suffix, true)
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
    local portrait = wutil.getEntityPortrait()
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
      wutil.setWidgetImage(preview .. "." .. li .. ".image", layers[i])
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
  @param item - The item to select, as stored in the item dump.
  @param [category=item.category] - The category of the item.
]]
function wardrobe.selectItem(item, category)
  category = category or item.category
  wardrobe.selection[category] = item
  if item then
    wardrobe.selection[category].selectedColor = 1
  end
  wardrobe.showItemForCategory[category](item, colorIndex)
  wardrobe.showColors(item, category)
end

--[[
  Shows the given head item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the head item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showHead(item, colorIndex)
  local params = wutil.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[6]
  wutil.setWidgetImage(w .. ".image", image .. params.dir)

  local mask = ""
  if item and item.mask then
    mask = "?addmask=" .. wutil.fixImagePath(item.path, item.mask)
  end
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[4]
  wutil.setWidgetImage(w .. ".image", wardrobe.layers[4] .. mask)

  wutil.setWidgetImage("wardrobeHeadIcon", params.icon)
  wutil.setWidgetImage("wardrobeHeadRarity", params.rarity)
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
  local dir = item and wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[colorIndex])
  local icon = "/assetMissing.png"
  if dir then icon = wutil.getIconForItem(item) .. dir
  else dir = "" end
  local images = item and wardrobe.getDefaultImageForItem(item, true) or { "/assetMissing.png", "/assetMissing.png", "/assetMissing.png" }

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[2]
  wutil.setWidgetImage(w .. ".image", images[1] .. dir)
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[5]
  wutil.setWidgetImage(w .. ".image", images[2] .. dir)
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[7]
  wutil.setWidgetImage(w .. ".image", images[3] .. dir)

  wutil.setWidgetImage("wardrobeChestIcon", icon)
  wutil.setWidgetImage("wardrobeChestRarity", item and item.rarity and wutil.rarities[item.rarity] or wutil.rarities["common"])
  widget.setText("wardrobeChestName", name)
end

--[[
  Shows the given legs item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the legs item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showLegs(item, colorIndex)
  local params = wutil.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[4]
  wutil.setWidgetImage(w .. ".image", image .. params.dir)

  wutil.setWidgetImage("wardrobeLegsIcon", params.icon .. params.dir)
  wutil.setWidgetImage("wardrobeLegsRarity", params.rarity)
  widget.setText("wardrobeLegsName", params.name)
end

--[[
  Shows the given back item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the back item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showBack(item, colorIndex)
  local params = wutil.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[3]
  wutil.setWidgetImage(w .. ".image", image .. params.dir)

  wutil.setWidgetImage("wardrobeBackIcon", params.icon .. params.dir)
  wutil.setWidgetImage("wardrobeBackRarity", params.rarity)
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
  wutil.setWidgetImage(w .. "." .. clear .. ".imageFront", "/assetMissing.png?replace;ffffff00=ffffffff?crop;0;0;43;43?blendmult=/interface/wardrobe/x.png;-13;-13?replace;ffffffff=00000000")

  category = category:lower()
  if category == "head" then category = "head"
  elseif category == "top" or category == "shirt" then category = "chest"
  elseif category == "skirt" or category == "leg" then category = "legs"
  elseif category == "cape" or category == "enviroprotectionpack" then category = "back" end

  local equipped
  if selectEquipped then
    local c = category
    if not wardrobe.getConfigParameter("useArmorSlot") then c = c .. "Cosmetic" end
    equipped = player.equippedItem(c)
  end

  local items = root.assetJson("/wardrobe/wearables.json")
  if not items or not items[category] then sb.logError("Wardrobe: Could not load items for category %s", category) return end
  items = items[category]

  items = wutil.filterList(items, filter)

  local itemCount = #items
  -- Add items
  for i=1,itemCount do
    local item = items[i]
    if equipped and item.name == equipped.name then
      local index = equipped.parameters.colorIndex or 1
      local cfg = root.itemConfig(item.name).config
      local colors = cfg.colorOptions and #cfg.colorOptions or 12
      index = index - 1
      -- This should automatically select the color options of the equipped item.
      index = (index % colors) + 2
      wardrobe.selectItem(item, category)
      wardrobe.selectColorForCategory[category](_, index)
    end
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
  local dir = wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

  if item.category == "head" then
    wutil.setWidgetImage(w .. ".imageFront", images .. dir)
  elseif item.category == "chest" then
    wutil.setWidgetImage(w .. ".imageBack", images[1] .. dir)
    wutil.setWidgetImage(w .. ".image", images[2] .. dir)
    wutil.setWidgetImage(w .. ".imageFront", images[3] .. dir)
  elseif item.category == "legs" then
    wutil.setWidgetImage(w .. ".image", images .. dir)
  elseif item.category == "back" then
    wutil.setWidgetImage(w .. ".imageBack", images .. dir)
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
    if not item.colorOptions then item.colorOptions = {} end
    for i=1,#item.colorOptions do
      widget.setVisible(w .. i, true)
      local img = "/interface/wardrobe/color.png" .. wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[i])
      widget.setButtonImages(w .. i, {base=img, hover=img})
    end

    for i=#item.colorOptions+1,16 do
      widget.setVisible(w .. i, false)
    end
  end
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
    local image = wutil.fixImagePath(item.path, player.gender() == "male" and item.maleFrames or item.femaleFrames) .. ":normal"
    return image
  elseif item.category == "chest" then
    local image = wutil.fixImagePath(item.path, player.gender() == "male" and item.maleFrames.body or item.femaleFrames.body) .. ":" .. bodyFrame
    local imageBack = wutil.fixImagePath(item.path, player.gender() == "male" and item.maleFrames.backSleeve or item.femaleFrames.backSleeve) .. ":" .. armFrame
    local imageFront = wutil.fixImagePath(item.path, player.gender() == "male" and item.maleFrames.frontSleeve or item.femaleFrames.frontSleeve) .. ":" .. armFrame
    return {imageBack, image, imageFront}
  elseif item.category == "legs" then
    local image = wutil.fixImagePath(item.path, player.gender() == "male" and item.maleFrames or item.femaleFrames) .. ":" .. bodyFrame
    return image
  elseif item.category == "back" then
    local image = wutil.fixImagePath(item.path, item.maleFrames) .. ":" .. bodyFrame
    return image
  end
end

--[[
  Draws a dummy, adding the provided layered images.
  @param canvas - Bound canvas to draw on.
  @param [layers] - Layers to add between the dummy parts. Each value represents an image to draw.
    Supported keys: back, backArm, body, frontArm, head
    For example, { "back": "/backimg.png:idle.1" }
  @param [offset={0,0}] - Drawing offset from bottom left corner of canvas.
]]
function wardrobe.drawDummy(canvas, layers, offset)
  offset = offset or {0,0}

  -- Back layer (back items)
  if (layers.back) then
    canvas:drawImage(layers.back, offset)
  end

  -- BackArm layer (sleeves)
  canvas:drawImage("/humanoid/any/dummybackarm.png", offset)
  if (layers.backArm) then
    canvas:drawImage(layers.backArm, offset)
  end

  -- Middle layer (chest/legs)
  canvas:drawImage("/humanoid/any/dummybody.png", offset)
  if (layers.body) then
    canvas:drawImage(layers.body, offset)
  end

-- FrontArm layer (sleeves)
  canvas:drawImage("/humanoid/any/dummyfrontarm.png", offset)
  if (layers.frontArm) then
    canvas:drawImage(layers.frontArm, offset)
  end

  -- Front layer (head)
  canvas:drawImage("/humanoid/any/dummyhead.png", offset)
  if (layers.head) then
    canvas:drawImage(layers.head, offset)
  end
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

function wardrobe.setConfigParameters()
  local cfg = status.statusProperty("wardrobeInterface")
  if not cfg then
    cfg = {}
  end
  if type(cfg.useArmorSlot) ~= "boolean" then
    cfg.useArmorSlot = false
    status.setStatusProperty("wardrobeInterface", cfg)
  end
  return cfg
end

function wardrobe.getConfigParameters()
  return status.statusProperty("wardrobeInterface")
end

function wardrobe.getConfigParameter(path)
  local cfg = status.statusProperty("wardrobeInterface") or {}
  return path == nil and cfg or cfg[path]
end
