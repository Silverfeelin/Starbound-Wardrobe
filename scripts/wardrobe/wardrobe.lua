require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/wardrobe/wutil.lua"
require "/scripts/wardrobe/wardrobe_callbacks.lua"
require "/scripts/wardrobe/itemList.lua"

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

-- #region Engine

--[[
  Initializes the Wardrobe.
  This function is called every time the interface is opened from the MUI Main
  Menu.
]]
function init()
  wardrobe.cb.init()

  wardrobe.widgets = config.getParameter("widgetNames")
  wardrobe.idleFrames = wutil.getIdleFrames()

  wardrobe.items = {
    vanilla = root.assetJson("/wardrobe/vanilla.json"),
    mod = root.assetJson("/wardrobe/mod.json"),
    custom = root.assetJson("/wardrobe/custom.json")
  }

  --  Compatibility for older patches
  local wearables = root.assetJson("/wardrobe/wearables.json")
  for _,v in ipairs(wearables.head) do
    table.insert(wardrobe.items.mod.head, v)
  end
  for _,v in ipairs(wearables.chest) do
    table.insert(wardrobe.items.mod.chest, v)
  end
  for _,v in ipairs(wearables.legs) do
    table.insert(wardrobe.items.mod.legs, v)
  end
  for _,v in ipairs(wearables.back) do
    table.insert(wardrobe.items.mod.back, v)
  end

  wardrobe.setConfigParameters()

  wardrobe.selection = {}
  wardrobe.preview.custom = {}
  wardrobe.preview.default = {}

  wardrobe.search = {
    delay = 10,
    tick = 10
  }

  wardrobe.lists = {
    head = ItemList.new("headSelection.list", wardrobe.addHeadItem, 3),
    chest = ItemList.new("chestSelection.list", wardrobe.addChestItem, 3),
    legs = ItemList.new("legsSelection.list", wardrobe.addLegsItem, 3),
    back = ItemList.new("backSelection.list", wardrobe.addBackItem, 3)
  }

  wardrobe.loadPreview()
  wardrobe.loadEquipped()
end

--[[
  Update function, called every game tick by MUI while the interface is opened.
  @param dt - Delay between this and the previous update tick.
]]
function update(dt)
  for _,v in pairs(wardrobe.lists) do
    v:update()
  end

  if wardrobe.search.changed then
    wardrobe.search.tick = wardrobe.search.tick - 1
    if wardrobe.search.tick <= 0 then
      -- TODO: Only update changed ones.
      wardrobe.showHeadItems(wardrobe.getCategory("head"))
      wardrobe.showChestItems(wardrobe.getCategory("chest"))
      wardrobe.showLegsItems(wardrobe.getCategory("legs"))
      wardrobe.showBackItems(wardrobe.getCategory("back"))
      wardrobe.search.changed = false
    end
  end
end

-- #endregion

-- #region Add List Items

function wardrobe.getCategory(slot)
  local gw =
    slot == "head" and wardrobe.widgets.head_group
    or slot == "chest" and wardrobe.widgets.chest_group
    or slot == "legs" and wardrobe.widgets.legs_group
    or slot == "back" and wardrobe.widgets.back_group

  local i = widget.getSelectedOption(gw)
  return i == -1 and "vanilla" or i == 0 and "mod" or "custom"
end

--- Adds an item to remove clothing.
function wardrobe.addEmpty(slot, list)
  local li = list:addEmpty()
  local canvas = widget.bindCanvas(li .. ".canvas")
  wardrobe[slot .. "Canvas"] = canvas

  wardrobe.drawDummy(
    canvas,
    {
      head = "/assetMissing.png?replace;ffffff00=ffffffff?crop;0;0;43;43?blendmult=/interface/wardrobe/x.png;-13;-13?replace;ffffffff=00000000"
    }
  )
end

function wardrobe.showHeadItems(category)
  wardrobe.lists.head:clear()
  wardrobe.addEmpty("head", wardrobe.lists.head)

  local filter = widget.getText(wardrobe.widgets.head_search)
  wardrobe.lists.head:show(wutil.filterList(wardrobe.items[category].head, filter))
end

function wardrobe.showChestItems(category)
  wardrobe.lists.chest:clear()

  wardrobe.addEmpty("chest", wardrobe.lists.chest)

  local filter = widget.getText(wardrobe.widgets.chest_search)
  wardrobe.lists.chest:show(wutil.filterList(wardrobe.items[category].chest, filter))
end

function wardrobe.showLegsItems(category)
  wardrobe.lists.legs:clear()

  wardrobe.addEmpty("legs", wardrobe.lists.legs)

  local filter = widget.getText(wardrobe.widgets.legs_search)
  wardrobe.lists.legs:show(wutil.filterList(wardrobe.items[category].legs, filter))
end

function wardrobe.showBackItems(category)
  wardrobe.lists.back:clear()

  wardrobe.addEmpty("back", wardrobe.lists.back)

  local filter = widget.getText(wardrobe.widgets.back_search)
  wardrobe.lists.back:show(wutil.filterList(wardrobe.items[category].back, filter))
end

--- Gets the widget name of the list item button.
-- 1: ".first", 2: ".second", 3
local function getListButtonName(index)
  return "." .. index
end

local function setListButtonData(li, item, index)
  -- Set button data
  local btn = li .. getListButtonName(index)
  widget.setData(btn, item)
end

function wardrobe.addHeadItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local image = wardrobe.getDefaultImageForItem(item)
  local dir = item.directives or wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

  if index == 1 then
    wardrobe.headCanvas = widget.bindCanvas(li .. ".canvas")
  end

  local mask
  if item.mask then
    -- TODO: Better custom masks.
    if item.mask:find("%?submask=/items/armors/decorative/hats/eyepatch/mask.png") then
      -- Fully mask hair
      mask = item.mask
    else
      mask = "?addmask=" .. wutil.fixImagePath(item.path, item.mask)
    end
  end

  wardrobe.drawDummy(
    wardrobe.headCanvas,
    {
      head = image .. dir
    },
    {(index - 1) * 43, 0},
    mask
  )
end

function wardrobe.addChestItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local images = wardrobe.getDefaultImageForItem(item, true)
  local dir = item.directives or wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

  if index == 1  then
    wardrobe.chestCanvas = widget.bindCanvas(li .. ".canvas")
  end

  wardrobe.drawDummy(
    wardrobe.chestCanvas,
    {
      backArm = images[1] .. dir,
      body = images[2] .. dir,
      frontArm = images[3] .. dir
    },
    {(index -1) * 43, 0})
end

function wardrobe.addLegsItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local image = wardrobe.getDefaultImageForItem(item, true)
  local dir = item.directives or wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

  if index == 1  then
    wardrobe.legsCanvas = widget.bindCanvas(li .. ".canvas")
  end

  wardrobe.drawDummy(
    wardrobe.legsCanvas,
    {
      body = image .. dir
    },
    {(index -1) * 43, 0})
end

function wardrobe.addBackItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local image = wardrobe.getDefaultImageForItem(item, true)
  local dir = item.directives or wutil.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

  if index == 1  then
    wardrobe.backCanvas = widget.bindCanvas(li .. ".canvas")
  end

  wardrobe.drawDummy(
    wardrobe.backCanvas,
    {
      back = image .. dir
    },
    {(index -1) * 43, 0})
end

-- #endregion

-- #region Spawn

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

-- #endregion

-- #region Preview

--[[
  Loads the preview by adding layers to the preview widget.

  Custom layer order, fetched with wardrobe.preview.custom[n]:
  [1] backarm [2] [3] head emote hair body [4] [5] fluff beaks [6] frontarm [7]
  Regular use: [1] = Background, [2] = BackSleeve, [3] = BackItem, [4] = Pants,
  [5] = Shirt, [6] = Head, [7] = FrontSleeve

  Some data you're free to skip over:
  Human: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] head frontarm [frontsleeve]
  Avian: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] fluff beaks head frontarm [frontsleeve]
  Hylotl: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] head frontarm [frontsleeve]
  Glitch: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] head frontarm [frontsleeve]
  Novakid: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] brand head frontarm [frontsleeve]
  Apex: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] beard head frontarm [frontsleeve]
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

  if portraitFrames > 6 then layers[6] = portrait[6].image end
  if portraitFrames > 7 then layers[7] = portrait[7].image end
  layers[8] = portrait[#portrait].image

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

function wardrobe.loadEquipped()
  local suff = wardrobe.getConfigParameter("useArmorSlot") and "" or "Cosmetic"
  local head = player.equippedItem("head" .. suff)
  local chest = player.equippedItem("chest" .. suff)
  local legs = player.equippedItem("legs" .. suff)
  local back = player.equippedItem("back" .. suff)

 -- TODO: function to save some lines
  if head then
    head.parameters = head.parameters or {}

    local itemConfig = root.itemConfig(head.name)
    local item = {
      name = head.name,
      shortdescription = head.parameters.shortdescription or itemConfig.config.shortdescription,
      category = "head",
      path = itemConfig.directory,
      icon = head.parameters.inventoryIcon or itemConfig.config.inventoryIcon,
      -- fileName Unknown,
      maleFrames = head.parameters.maleFrames or itemConfig.config.maleFrames,
      femaleFrames = head.parameters.femaleFrames or itemConfig.config.femaleFrames,
      mask = head.parameters.mask or itemConfig.config.mask,
      colorOptions = head.parameters.colorOptions or itemConfig.config.colorOptions,
      directives = head.parameters.directives
    }

    wardrobe.selectItem(item, "head")
    wardrobe.showHead(item, head.parameters.colorIndex or 0)
  end

  if chest then
    chest.parameters = chest.parameters or {}

    local itemConfig = root.itemConfig(chest.name)
    local item = {
      name = chest.name,
      shortdescription = chest.parameters.shortdescription or itemConfig.config.shortdescription,
      category = "chest",
      path = itemConfig.directory,
      icon = chest.parameters.inventoryIcon or itemConfig.config.inventoryIcon,
      -- fileName Unknown,
      maleFrames = chest.parameters.maleFrames or itemConfig.config.maleFrames,
      femaleFrames = chest.parameters.femaleFrames or itemConfig.config.femaleFrames,
      colorOptions = chest.parameters.colorOptions or itemConfig.config.colorOptions,
      directives = chest.parameters.directives
    }

    wardrobe.selectItem(item, "chest")
    wardrobe.showChest(item, chest.parameters.colorIndex or 0)
  end

  if legs then
    legs.parameters = legs.parameters or {}

    local itemConfig = root.itemConfig(legs.name)
    local item = {
      name = legs.name,
      shortdescription = legs.parameters.shortdescription or itemConfig.config.shortdescription,
      category = "legs",
      path = itemConfig.directory,
      icon = legs.parameters.inventoryIcon or itemConfig.config.inventoryIcon,
      -- fileName Unknown,
      maleFrames = legs.parameters.maleFrames or itemConfig.config.maleFrames,
      femaleFrames = legs.parameters.femaleFrames or itemConfig.config.femaleFrames,
      colorOptions = legs.parameters.colorOptions or itemConfig.config.colorOptions,
      directives = legs.parameters.directives
    }

    wardrobe.selectItem(item, "legs")
    wardrobe.showLegs(item, legs.parameters.colorIndex or 0)
  end

  if back then
    back.parameters = back.parameters or {}

    local itemConfig = root.itemConfig(back.name)
    local item = {
      name = back.name,
      shortdescription = back.parameters.shortdescription or itemConfig.config.shortdescription,
      category = "back",
      path = itemConfig.directory,
      icon = back.parameters.inventoryIcon or itemConfig.config.inventoryIcon,
      -- fileName Unknown,
      maleFrames = back.parameters.maleFrames or itemConfig.config.maleFrames,
      femaleFrames = back.parameters.femaleFrames or itemConfig.config.femaleFrames,
      colorOptions = back.parameters.colorOptions or itemConfig.config.colorOptions,
      directives = back.parameters.directives
    }

    wardrobe.selectItem(item, "back")
    wardrobe.showBack(item, back.parameters.colorIndex or 0)
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
    wardrobe.selection[category].colorIndex = 0
  end
  wardrobe.showItemForCategory[category](item, colorIndex)

  if item.directives then
    wardrobe.hideColors(category)
  else
    wardrobe.showColors(item, category)
  end

  wardrobe.setSelection(item, category)
end

--[[
  Shows the given head item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the head item.
  @param [colorIndex=1] - Index of the color option to apply to the item.
]]
function wardrobe.showHead(item, colorIndex)
  if not colorIndex or item and colorIndex > #item.colorOptions then colorIndex = 0 end

  local params = wutil.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[6]
  wutil.setWidgetImage(w .. ".image", image .. (item and item.directives or params.dir))

  local mask = ""
  if item and item.mask then
    -- TODO: Better custom masks.
    if item.mask:find("%?submask=/items/armors/decorative/hats/eyepatch/mask.png") then
      -- Fully mask hair
      mask = item.mask
    else
      mask = "?addmask=" .. wutil.fixImagePath(item.path, item.mask)
    end
  end
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[4]
  wutil.setWidgetImage(w .. ".image", wardrobe.layers[4] .. mask)

  local itemParams = {}
  if item then
    itemParams.directives = item.directives
    itemParams.colorIndex = item.colorIndex
    itemParams.inventoryIcon = item.icon
  end

  local itemSlotItem = item and { name = item.name, parameters = itemParams } or nil
  widget.setItemSlotItem(wardrobe.widgets.head_icon, itemSlotItem)
  widget.setText(wardrobe.widgets.head_name, item and item.shortdescription or "No selection")
end

--[[
  Shows the given chest item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the chest item.
  @param [colorIndex=0] - Index of the color option to apply to the item.
]]
function wardrobe.showChest(item, colorIndex)
  if not colorIndex or item and colorIndex > #item.colorOptions then colorIndex = 0 end

  local params = wutil.getParametersForShowing(item, colorIndex)
  local images = item and wardrobe.getDefaultImageForItem(item, true) or { "/assetMissing.png", "/assetMissing.png", "/assetMissing.png" }

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[2]
  wutil.setWidgetImage(w .. ".image", images[1] .. (item and item.directives or params.dir))
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[5]
  wutil.setWidgetImage(w .. ".image", images[2] .. (item and item.directives or params.dir))
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[7]
  wutil.setWidgetImage(w .. ".image", images[3] .. (item and item.directives or params.dir))

  local itemParams = {}
  if item then
    itemParams.directives = item.directives
    itemParams.colorIndex = item.colorIndex
    itemParams.inventoryIcon = item.icon
  end

  widget.setItemSlotItem(wardrobe.widgets.chest_icon, item and { name = item.name, parameters = itemParams })
  widget.setText(wardrobe.widgets.chest_name, item and item.shortdescription or "No selection")
end

--[[
  Shows the given legs item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the legs item.
  @param [colorIndex=0] - Index of the color option to apply to the item.
]]
function wardrobe.showLegs(item, colorIndex)
  if not colorIndex or item and colorIndex > #item.colorOptions then colorIndex = 0 end

  local params = wutil.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[4]
  wutil.setWidgetImage(w .. ".image", image .. (item and item.directives or params.dir))

  local itemParams = {}
  if item then
    itemParams.directives = item.directives
    itemParams.colorIndex = item.colorIndex
    itemParams.inventoryIcon = item.icon
  end

  widget.setItemSlotItem(wardrobe.widgets.legs_icon, item and { name = item.name, parameters = itemParams })
  widget.setText(wardrobe.widgets.legs_name, item and item.shortdescription or "No selection")
end

--[[
  Shows the given back item on the preview character, optionally using the color option found at the given index.
  @param item - Item to display on the preview character. Category and layers
    are determined by the configuration of the item. A nil value will remove the back item.
  @param [colorIndex=0] - Index of the color option to apply to the item.
]]
function wardrobe.showBack(item, colorIndex)
  if not colorIndex or item and colorIndex > #item.colorOptions then colorIndex = 0 end

  local params = wutil.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[3]
  wutil.setWidgetImage(w .. ".image", image .. (item and item.directives or params.dir))

  local itemParams = {}
  if item then
    itemParams.directives = item.directives
    itemParams.colorIndex = item.colorIndex
    itemParams.inventoryIcon = item.icon
  end

  widget.setItemSlotItem(wardrobe.widgets.back_icon, item and { name = item.name, parameters = itemParams })
  widget.setText(wardrobe.widgets.back_name, item and item.shortdescription or "No selection")
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

-- #endregion

function wardrobe.hideColors(category, startIndex)
  startIndex = type(startIndex) == number and startIndex or 1
  if startIndex < 1 then startIndex = 1 end

  local w = category .. ".color_"

  for i = startIndex, 16 do
    widget.setVisible(w .. i, false)
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
    w = "head.color_"
  elseif category == "chest" then
    w = "chest.color_"
  elseif category == "legs" then
    w = "legs.color_"
  elseif category == "back" then
    w = "back.color_"
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

function wardrobe.setSelection(item, category)
    local params = {}
    if item then
      params.directives = item.directives
      params.colorIndex = item.colorIndex or 0
      params.inventoryIcon = item.icon
    end

    widget.setItemSlotItem(wardrobe.widgets[category .. "_icon"], item and {name = item.name, parameters = params} or nil)
    widget.setText(wardrobe.widgets[category .. "_name"], item and item.shortdescription or "No selection")
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
function wardrobe.drawDummy(canvas, layers, offset, mask)
  offset = offset or {0,0}
  local bodyPortrait = wutil.getBodyPortrait()

  --- `body`:
  -- backarm head emote hair body <empty> <empty> frontarm
  -- backarm head emote hair body brand   <empty> frontarm
  -- backarm head emote hair body beard   <empty> frontarm
  -- backarm head emote hair body fluff   beaks   frontarm
  local body = {
    bodyPortrait[1].image,
    bodyPortrait[2].image,
    bodyPortrait[3].image,
    bodyPortrait[4].image:gsub('%?addmask=[^%?]+',''),
    bodyPortrait[5].image
  }
  local c = #bodyPortrait
  if c > 6 then body[6] = bodyPortrait[6].image end
  if c > 7 then body[7] = bodyPortrait[7].image end
  body[8] = bodyPortrait[c].image

  -- BackArm
  canvas:drawImage(body[1], offset)
  if (layers.backArm) then
    canvas:drawImage(layers.backArm, offset)
  end

  -- Back
  if (layers.back) then
    canvas:drawImage(layers.back, offset)
  end

  -- Head
  canvas:drawImage(body[2], offset)
  canvas:drawImage(body[3], offset)
  canvas:drawImage(body[4] .. (mask or ""), offset)

  -- Body
  canvas:drawImage(body[5], offset)

  -- Chest/Pants
  if (layers.body) then
    canvas:drawImage(layers.body, offset)
  end

  -- Face
  if body[6] then
    canvas:drawImage(body[6], offset)
  end

  if body[7] then
    canvas:drawImage(body[7], offset)
  end

  -- FrontArm
  canvas:drawImage(body[8], offset)
  if (layers.frontArm) then
    canvas:drawImage(layers.frontArm, offset)
  end

  -- Hat
  if (layers.head) then
    canvas:drawImage(layers.head, offset)
  end
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
