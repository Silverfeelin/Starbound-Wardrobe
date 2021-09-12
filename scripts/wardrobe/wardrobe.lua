require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/wardrobe/wardrobe_util.lua"
require "/scripts/wardrobe/wardrobe_callbacks.lua"
require "/scripts/wardrobe/wardrobe_ds.lua"
require "/scripts/wardrobe/itemList.lua"

require "/scripts/wardrobe_tooltip/tooltip.lua"
wardrobe = {}

--- Collection of list items for the preview widget.
-- Separated in two categories, one for default images (character) and one for custom images (selected items).
wardrobe.preview = {
  default = {},
  custom = {}
}

--- Current item selection.
-- Keys represent item slot, value represent selected item.
-- Keys: 'head', 'chest', 'legs', 'back'.
wardrobe.selection = {}

--- The default palette for color options.
wardrobe.defaultColors = {
  ["ffca8a"] = true,
  ["e0975c"] = true,
  ["a85636"] = true,
  ["6f2919"] = true,
  [1] = "ffca8a",
  [2] = "e0975c",
  [3] = "a85636",
  [4] = "6f2919"
}

wardrobe.armFrames = {
  [1] = true,
  [8] = true
}
wardrobe.bodyFrames = {
  [5] = true
}

-- Current character selection.
wardrobe.character = {
  species = nil,
  gender = nil
}

-- #region Engine

--- Initializes the Wardrobe.
function wardrobe.init()
  -- Upgrade storage (#16)
  wardrobe.upgrade()

  -- Reference required scripts
  wardrobe.cb = wardrobeCallbacks
  wardrobe.util = wardrobeUtil
  wardrobe.ds = wardrobeDs

  -- Initialize callbacks
  wardrobe.cb.init()
  -- Initialize DyeSuite compatibility
  wardrobe.ds.init()

  -- Load some useful data
  wardrobe.slots = { "head", "chest", "legs", "back" }
  wardrobe.widgets = config.getParameter("widgetNames")
  wardrobe.idleFrames = wardrobe.util.getIdleFrames()
  wardrobe.gender = player.gender()
  wardrobe.character.gender = wardrobe.gender
  wardrobe.characters = root.assetJson("/scripts/wardrobe/characters.json")

  wardrobe.items = wardrobe.loadItems()

  wardrobe.setConfigParameters()

  -- Selection
  wardrobe.selection = {}
  wardrobe.preview.custom = {}
  wardrobe.preview.default = {}

  -- Search timer
  wardrobe.search = {
    slots = {},
    delay = 10,
    tick = 10
  }

  -- Item lists
  wardrobe.lists = {
    head = ItemList.new("headSelection.list", wardrobe.addHeadItem, 3),
    chest = ItemList.new("chestSelection.list", wardrobe.addChestItem, 3),
    legs = ItemList.new("legsSelection.list", wardrobe.addLegsItem, 3),
    back = ItemList.new("backSelection.list", wardrobe.addBackItem, 3),
    outfits = ItemList.new("outfitSelection.list", wardrobe.addOutfit, 3)
  }

  -- Load preview with equipped items
  wardrobe.initPreview()
  wardrobe.loadPreview()
  wardrobe.loadEquipped()

  -- Outfits
  wardrobe.trashing = false
  wardrobe.outfits = wardrobe.util.propertyList("wardrobeOutfits")
  wardrobe.outfitIcons = config.getParameter("outfitIcons", {})
  wardrobe.lists.outfits:show(wardrobe.outfits)
  wardrobe.updateIcon()
end

-- Hook
hook('init', wardrobe.init)

--- Updates the Wardrobe storage.
function wardrobe.upgrade()
  local cfg = status.statusProperty("wardrobeInterface")
  if cfg then
    player.setProperty("wardrobeInterface", cfg)
    status.setStatusProperty("wardrobeOutfits", nil)
  end

  local outfits = status.statusProperty("wardrobeOutfits")
  if outfits then
    player.setProperty("wardrobeOutfits", nil)
    status.setStatusProperty("wardrobeOutfits", nil)
  end
end

--- Loads all items from the config
-- Items are returned as {vanilla={},mod={},custom={}}.
-- Each table contains items under the keys head, chest, legs and back.
-- @return Items
function wardrobe.loadItems()
  local items = {
    vanilla = { head = {}, chest = {}, legs = {}, back = {} },
    mod = { head = {}, chest = {}, legs = {}, back = {} },
    custom = { head = {}, chest = {}, legs = {}, back = {} }
  }

  -- Add items.head/chest/legs/back to tbl.head/chest/legs/back
  local function addItems(tbl, items)
    for key,subItems in pairs(items) do
      for _,v in ipairs(subItems) do
        -- Fix improper categories. Makes the category param in the item files obsolete/unused.
        v.category = key

        table.insert(tbl[key], v)
      end
    end
  end

  -- Add items.head/chest/legs/back to tbl.head/chest/legs/back.
  -- Uses
  local function addCustom(tbl, items)
    for key,subItems in pairs(items) do
      for _,v in ipairs(subItems) do
        local cfg = root.itemConfig(v.name)
        if cfg then
          if not v.parameters then v.parameters = {} end

          local item = {
            name = v.name,
            category = key,
            icon = v.icon or v.parameters.icon or cfg.config.inventoryIcon,
            femaleFrames = v.femaleFrames or v.parameters.femaleFrames or cfg.config.femaleFrames,
            maleFrames = v.maleFrames or v.parameters.maleFrames or cfg.config.maleFrames,
            mask = v.mask or v.parameters.mask or cfg.config.mask,
            path = cfg.directory,
            -- fileName unknown
            shortdescription = v.shortdescription or v.parameters.shortdescription or cfg.config.shortdescription,
            directives = v.directives or v.parameters.directives or cfg.config.directives
          }

          table.insert(tbl[key], item)
        end
      end
    end
  end

  -- Validates if the first item for each slot exists.
  -- Not perfect since mods may remove certain items, but will let us know that an user doesn't have the mod in most cases.
  local function validateItems(items)
    for _,slot in ipairs(wardrobe.slots) do
      if items[slot] and #items[slot] > 0 then
        if not root.itemConfig(items[slot][1]) then return false end
      end
    end
    return true
  end

  -- Load files and add items to tbl
  local function loadFiles(files, tbl, addFunc)
    for _,v in ipairs(files) do
      if v:find("/") ~= 1 then
        v = "/wardrobe/" .. v
      end
      local f = root.assetJson(v)

      if type(f.head) ~= "table" and type(f.chest) ~= "table" and type(f.legs) ~= "table" and type(f.back) ~= "table" then
        sb.logWarn("Wardrobe: Skipping %s due to malformed JSON.\nWas this file made using the Wardrobe Item Fetcher?", v)
      elseif not validateItems(f) then
        sb.logWarn("Wardrobe: Skipping %s due to missing items.\nDid you install the mod this add-on is made for? If you did, the add-on might be outdated.", v)
      else
        addFunc(tbl, f)
      end
    end
  end

  local function loadScripts(scripts, tbl)
    for _,v in ipairs(scripts) do
      import = {}
      local status, err = pcall(function() require(v) end)
      if status then
        addItems(tbl, import)
      else
        sb.logError("Wardrobe: Failed to load script %s", v)
        sb.logError("%s", err)
      end
    end
  end

  local config = root.assetJson("/wardrobe/wardrobe.config")
  loadScripts(config.scripts.vanilla, items.vanilla)
  loadScripts(config.scripts.mod, items.mod)
  loadScripts(config.scripts.custom, items.custom)
  loadFiles(config.vanilla, items.vanilla, addItems)
  loadFiles(config.mod, items.mod, addItems)
  loadFiles(config.custom, items.custom, addCustom)

  return items
end

--- Update function, called every game update.
-- @param dt Time between this and the previous update tick.
function wardrobe.update(dt)
  -- Update item lists. This adds some items every update, until all items are shown.
  for _,v in pairs(wardrobe.lists) do
    v:update()
  end

  -- Filter items
  if wardrobe.search.changed then
    wardrobe.search.tick = wardrobe.search.tick - 1
    if wardrobe.search.tick <= 0 then
      for k in pairs(wardrobe.search.slots) do
        wardrobe.search.slots[k] = nil
        wardrobe.showItems(k, wardrobe.getCategory(k), wardrobe.getSearch(k))
      end
      wardrobe.search.changed = false
    end
  end

  -- Repopulate outfits
  if wardrobe.refreshOutfits then
    wardrobe.refreshOutfits = false
    wardrobe.lists.outfits:clear()
    wardrobe.lists.outfits:show(wardrobe.outfits)
  end
end

-- Hook
hook('update', wardrobe.update)

-- #endregion

-- #region Add List Items

--- Returns the selected category for a slot.
-- @param slot head/chest/legs/back
-- @return vanilla/mod/custom
function wardrobe.getCategory(slot)
  local slots = {
    head = wardrobe.widgets.head_group,
    chest = wardrobe.widgets.chest_group,
    legs = wardrobe.widgets.legs_group,
    back = wardrobe.widgets.back_group
  }
  local i = widget.getSelectedOption(slots[slot])
  return i == -1 and "vanilla" or i == 0 and "mod" or "custom"
end

--- Returns the search text for a slot.
-- @param slot head/chest/legs/back
-- @return Search text
function wardrobe.getSearch(slot)
  return widget.getText(wardrobe.widgets[slot .. "_search"])
end

--- Adds an option to the item list to remove clothing.
-- A dummy with an X is drawn as the list option.
-- @param slot Item slot (head/chest/legs/back)
-- @param list ItemList
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

--- Shows all slot items for a category.
-- Items are filted by item name and shortdescription.
-- @param slot head/chest/legs/back
-- @param category vanilla/mod/custom
-- @param [filter] Text filter
function wardrobe.showItems(slot, category, filter)
  local list = wardrobe.lists[slot]
  list:clear()
  wardrobe.addEmpty(slot, list)
  list:show(wardrobe.util.filterList(wardrobe.items[category][slot], filter))
end

--- Sets the item as the widget data for the item selection button.
-- @param li List item widget name.
-- @param item Item data to attach to the button
-- @param index Index of the selection button (1/2/3).
local function setListButtonData(li, item, index)
  -- Set button data
  local btn = li .. "." .. index
  widget.setData(btn, item)
end

--- ItemList addAction for head list.
-- Adds the item to the list, draws the preview character, binds button data.
-- @param li List item widget name.
-- @param item Item to add.
-- @param index Index for the item in the list item (1/2/3).
function wardrobe.addHeadItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local image = wardrobe.getDefaultImageForItem(item)
  local dir = item.directives ~= "" and item.directives or wardrobe.util.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

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
      mask = "?addmask=" .. wardrobe.util.fixImagePath(item.path, item.mask)
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

--- ItemList addAction for chest list.
-- Adds the item to the list, draws the preview character, binds button data.
-- @param li List item widget name.
-- @param item Item to add.
-- @param index Index for the item in the list item (1/2/3).
function wardrobe.addChestItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local images = wardrobe.getDefaultImageForItem(item, true)
  local dir = item.directives ~= "" and item.directives or wardrobe.util.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

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

--- ItemList addAction for legs list.
-- Adds the item to the list, draws the preview character, binds button data.
-- @param li List item widget name.
-- @param item Item to add.
-- @param index Index for the item in the list item (1/2/3).
function wardrobe.addLegsItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local image = wardrobe.getDefaultImageForItem(item, true)
  local dir = item.directives ~= "" and item.directives or wardrobe.util.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

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

--- ItemList addAction for back list.
-- Adds the item to the list, draws the preview character, binds button data.
-- @param li List item widget name.
-- @param item Item to add.
-- @param index Index for the item in the list item (1/2/3).
function wardrobe.addBackItem(li, item, index)
  setListButtonData(li, item, index)

  -- Draw
  local image = wardrobe.getDefaultImageForItem(item, true)
  local dir = item.directives ~= "" and item.directives or wardrobe.util.colorOptionToDirectives(item.colorOptions and item.colorOptions[1])

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

--- Spawns all selected items.
-- Items are not equipped.
function wardrobe.spawn()
  local suffix = wardrobe.getConfigParameter("useArmorSlot") and "" or "Cosmetic"

  wardrobe.giveItem(wardrobe.selection["head"], "head" .. suffix, false)
  wardrobe.giveItem(wardrobe.selection["chest"], "chest" .. suffix, false)
  wardrobe.giveItem(wardrobe.selection["legs"], "legs" .. suffix, false)
  wardrobe.giveItem(wardrobe.selection["back"], "back" .. suffix, false)
end

--- Equips all selected items.
-- Equipped items are swapped, and moved to the inventory.
function wardrobe.equip()
  local suffix = wardrobe.getConfigParameter("useArmorSlot") and "" or "Cosmetic"

  wardrobe.giveItem(wardrobe.selection["head"], "head" .. suffix, true)
  wardrobe.giveItem(wardrobe.selection["chest"], "chest" .. suffix, true)
  wardrobe.giveItem(wardrobe.selection["legs"], "legs" .. suffix, true)
  wardrobe.giveItem(wardrobe.selection["back"], "back" .. suffix, true)
end

--- Gives the player an item.
-- @param item Item to give. If nil and equip is true, unequips the current item.
-- @param category head/chest/legs/back/headCosmetic/chestCosmetic/legsCosmetic/backCosmetic
-- @param [equip=false] True to equip the item (placing old item in inventory), false to place item in inventory.
function wardrobe.giveItem(item, category, equip)
  local oppositeCategory = category:find("Cosmetic") and category:gsub("Cosmetic", "") or (category .. "Cosmetic")
  local equipped = player.equippedItem(category)
  local oppositeEquipped = player.equippedItem(oppositeCategory)

  local params = wardrobeUtil.itemParameters(item)

  if equip then
    -- Equip the item, add the previous to the inventory.
    if equipped then
      if not oppositeEquipped then player.setEquippedItem(oppositeCategory, wardrobeUtil.placeholders[category]) end
      -- Give equipped item back if it's not part of an outfit.
      if equipped.parameters and equipped.parameters.outfit ~= true then
        player.giveItem(equipped)
      end
      if not oppositeEquipped then player.setEquippedItem(oppositeCategory, nil) end
    end
    player.setEquippedItem(category, item and {name=item.name,parameters=params} or nil)
  elseif item then
    -- Add the item to the inventory; do not equip it.
    if not equipped then player.setEquippedItem(category, wardrobeUtil.placeholders[category]) end
    if not oppositeEquipped then player.setEquippedItem(oppositeCategory, wardrobeUtil.placeholders[category]) end
    player.giveItem({name=item.name,parameters=params})
    if not equipped then player.setEquippedItem(category, nil) end
    if not oppositeEquipped then player.setEquippedItem(oppositeCategory, nil) end
  end
end

-- #endregion

-- #region Preview

--- Initializes the preview by adding layers to the preview widget.
--  wardrobe.preview.custom: table with the below indices as image layers.
--  [1] backarm [2] [3] head emote hair body [4] [5] fluff beaks [6] frontarm [7]
--  [1] = Background  | [2] = BackSleeve | [3] = BackItem     | [4] = Pants
--  [5] = Shirt       | [6] = Head       | [7] = FrontSleeve
--
--  Layers are based on the following entityPortrait data. Layers marked in [] may not be present (making parsing pretty annoying).
--  Human: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] head frontarm [frontsleeve]
--  Avian: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] fluff beaks head frontarm [frontsleeve]
--  Hylotl: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] head frontarm [frontsleeve]
--  Glitch: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] head frontarm [frontsleeve]
--  Novakid: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] brand head frontarm [frontsleeve]
--  Apex: backarm [backsleeve] [backitem] head emote hair body [pants] [shirt] beard head frontarm [frontsleeve]
--
--  Humanoid layers are stored in a table with 8 values:
--  backarm head emote hair body <empty> <empty> frontarm
--  backarm head emote hair body brand <empty> frontarm
--  backarm head emote hair body beard <empty> frontarm
--  backarm head emote hair body fluff beaks frontarm
--
--  Layers 4, 6 and 7 need their ?addmask removed (if existent).
--  Likewise, these layers need a mask added when a head is selected with a mask.
function wardrobe.initPreview()
  local preview = wardrobe.widgets.preview

  local layers = {}

  -- Fetch portrait and remove item layers
  local portrait = wardrobe.util.getEntityPortrait()
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
  
  -- Set default character
  wardrobe.characters.default = layers

  -- Add the preview layers
  widget.clearListItems(preview)

  wardrobe.preview.default = {}
  wardrobe.preview.custom = {}

  table.insert(wardrobe.preview.custom, widget.addListItem(preview))
  
  for i=1,8 do
    -- Add default layer
    local li = widget.addListItem(preview)
    table.insert(wardrobe.preview.default, li)

    -- Add blank custom layer(s)
    local customLayers = (i == 1 or i == 5) and 2 or (i == 7 or i == 8) and 1 or 0
    for j=1,customLayers do
      table.insert(wardrobe.preview.custom, widget.addListItem(preview))
    end
  end
end

--- Loads the preview body layers.
-- Uses the current character selection if chosen.
function wardrobe.loadPreview()
  local wPreview = wardrobe.widgets.preview
  local species = wardrobe.character.species
  local layers = species
    and wardrobe.characters[species][wardrobe.character.gender]
    or wardrobe.characters.default
  local directives = species
    and wardrobe.characters[species][wardrobe.character.gender .. "Directives"]
    or ""

  local bodyFrame = wardrobe.getDefaultFrame("body", true)
  local armFrame = wardrobe.getDefaultFrame("arm", true)

  wardrobe.layers = species and {} or wardrobe.characters.default

  for i=1,8 do
    local li = wardrobe.preview.default[i]
    local liImage = wPreview .. "." .. li .. ".image"

    local image = layers[i]
    if image and species then
      if wardrobe.armFrames[i] then image = image .. ":" .. armFrame end
      if wardrobe.bodyFrames[i] then image = image .. ":" .. bodyFrame end
      image = image .. directives
      wardrobe.layers[i] = image
    end

    widget.setImage(liImage, image or "/assetMissing.png")
  end
end

--- Sets selected items based on equipped items.
-- Since wardrobe items aren't the same as item descriptors, some conversions must be done.
function wardrobe.loadEquipped()
  local suff = wardrobe.getConfigParameter("useArmorSlot") and "" or "Cosmetic"
  local head = player.equippedItem("head" .. suff)
  local chest = player.equippedItem("chest" .. suff)
  local legs = player.equippedItem("legs" .. suff)
  local back = player.equippedItem("back" .. suff)

  local function show(equippedItem, slot, showFunc)
    if not equippedItem then return end

    equippedItem.parameters = equippedItem.parameters or {}
    local itemConfig = root.itemConfig(equippedItem.name)
    local item = {
      name = equippedItem.name,
      shortdescription = equippedItem.parameters.shortdescription or itemConfig.config.shortdescription,
      description = equippedItem.parameters.description or nil,
      category = slot,
      path = itemConfig.directory,
      icon = equippedItem.parameters.inventoryIcon or itemConfig.config.inventoryIcon,
      -- fileName Unknown,
      maleFrames = equippedItem.parameters.maleFrames or itemConfig.config.maleFrames,
      femaleFrames = equippedItem.parameters.femaleFrames or itemConfig.config.femaleFrames,
      mask = equippedItem.parameters.mask or itemConfig.config.mask,
      colorOptions = equippedItem.parameters.colorOptions or itemConfig.config.colorOptions,
      colorIndex = equippedItem.parameters.colorIndex or 0,
      directives = equippedItem.parameters.directives,
      rarity = equippedItem.parameters.rarity or nil,
      ds = equippedItem.parameters.ds
    }

    -- Dye Suite uses -1 combined with item.directives
    if item.colorIndex ~= -1 then
      wardrobe.util.fixColorIndex(item)
    end

    wardrobe.selectItem(item, slot, false)
    showFunc(item, item.colorIndex or 0)
  end

  show(head, "head", wardrobe.showHead)
  show(chest, "chest", wardrobe.showChest)
  show(legs, "legs", wardrobe.showLegs)
  show(back, "back", wardrobe.showBack)
end


--- Selects the item.
-- The item selection is updated, and color options are displayed.
-- @param item Item to select.
-- @param [category=item.category] head/chest/legs/back
-- @param [updatePreview=false] Updates the preview image. If false, call it manually.
function wardrobe.selectItem(item, category, updatePreview)
  category = category or item.category
  local previous = wardrobe.selection[category]

  -- Retain Dye Suite dye.
  if item and previous and previous.colorIndex == -1 then
    item.colorIndex = -1
    item.ds = previous.ds
    item.directives = previous.directives
  elseif item and not item.colorIndex then
    item.colorIndex = 0
  end

  wardrobe.selection[category] = item

  if updatePreview then
    wardrobe.showItemForCategory[category](item, item and item.colorIndex)
  end
  wardrobe.showColors(category, item)
  wardrobe.setSelection(category, item)
end

--- Renders a head item on the preview character.
-- @param item Item to display on the preview character. Nil to remove the preview images for the item slot.
-- @param [colorIndex=item.colorIndex] Color options to apply. Ignored if the item has directives, which will be applied instead.
function wardrobe.showHead(item, colorIndex)
  -- Ignore faulty items.
  if item and not item.maleFrames and not item.femaleFrames then
    sb.logError("Wardrobe: Skipped showing item with no frames: %s.", item.name)
    return
  end

  -- Fix colorIndex out of bounds
  if not colorIndex then colorIndex = wardrobe.util.getColorIndex(item) end
  if colorIndex < 0 then colorIndex = 0 end
  if item and item.colorOptions and colorIndex >= #item.colorOptions then colorIndex = 0 end

  local params = wardrobe.util.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[6]
  local directives = wardrobe.util.getDirectives(item, params.dir)
  widget.setImage(w .. ".image", image .. directives)

  local mask = ""
  if item and item.mask then
    -- TODO: Better support for custom masks.
    -- This right here is for the Starbound Hatter output.
    if item.mask:find("%?submask=/items/armors/decorative/hats/eyepatch/mask.png") then
      mask = item.mask
    else
      mask = "?addmask=" .. wardrobe.util.fixImagePath(item.path, item.mask)
    end
  end
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[4]
  widget.setImage(w .. ".image", wardrobe.layers[4] .. mask)
  if wardrobe.layers[6] then
    w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[6]
    widget.setImage(w .. ".image", wardrobe.layers[6] .. mask)
  end
  if wardrobe.layers[7] then
    w = wardrobe.widgets.preview .. "." .. wardrobe.preview.default[7]
    widget.setImage(w .. ".image", wardrobe.layers[7] .. mask)
  end
end

--- Renders a chest item on the preview character.
-- @param item Item to display on the preview character. Nil to remove the preview images for the item slot.
-- @param [colorIndex=item.colorIndex] Color options to apply. Ignored if the item has directives, which will be applied instead.
function wardrobe.showChest(item, colorIndex)
  -- Ignore faulty items.
  if item and not item.maleFrames and not item.femaleFrames then
    sb.logError("Wardrobe: Skipped showing item with no frames: %s.", item.name)
    return
  end

  -- Fix colorIndex out of bounds
  if not colorIndex then colorIndex = wardrobe.util.getColorIndex(item) end
  if colorIndex < 0 then colorIndex = 0 end
  if item and item.colorOptions and colorIndex >= #item.colorOptions then colorIndex = 0 end

  local params = wardrobe.util.getParametersForShowing(item, colorIndex)
  local images = item and wardrobe.getDefaultImageForItem(item, true, true) or { "/assetMissing.png", "/assetMissing.png", "/assetMissing.png" }

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[2]
  local directives = wardrobe.util.getDirectives(item, params.dir)
  widget.setImage(w .. ".image", images[1] .. directives)
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[5]
  widget.setImage(w .. ".image", images[2] .. directives)
  w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[7]
  widget.setImage(w .. ".image", images[3] .. directives)
end

--- Renders a legs item on the preview character.
-- @param item Item to display on the preview character. Nil to remove the preview images for the item slot.
-- @param [colorIndex=item.colorIndex] Color options to apply. Ignored if the item has directives, which will be applied instead.
function wardrobe.showLegs(item, colorIndex, preserve)
  -- Ignore faulty items.
  if item and not item.maleFrames and not item.femaleFrames then
    sb.logError("Wardrobe: Skipped showing item with no frames: %s.", item.name)
    return
  end

  -- Fix colorIndex out of bounds
  if not colorIndex then colorIndex = wardrobe.util.getColorIndex(item) end
  if colorIndex < 0 then colorIndex = 0 end
  if item and item.colorOptions and colorIndex >= #item.colorOptions then colorIndex = 0 end

  local params = wardrobe.util.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[4]
  local directives = wardrobe.util.getDirectives(item, params.dir)
  widget.setImage(w .. ".image", image .. directives)
end

--- Renders a back item on the preview character.
-- @param item Item to display on the preview character. Nil to remove the preview images for the item slot.
-- @param [colorIndex=item.colorIndex] Color options to apply. Ignored if the item has directives, which will be applied instead.
function wardrobe.showBack(item, colorIndex, preserve)
  -- Ignore faulty items.
  if item and not item.maleFrames and not item.femaleFrames then
    sb.logError("Wardrobe: Skipped showing item with no frames: %s.", item.name)
    return
  end

  -- Fix colorIndex out of bounds
  if not colorIndex then colorIndex = wardrobe.util.getColorIndex(item) end
  if colorIndex < 0 then colorIndex = 0 end
  if item and item.colorOptions and colorIndex >= #item.colorOptions then colorIndex = 0 end

  local params = wardrobe.util.getParametersForShowing(item, colorIndex)
  local image = item and wardrobe.getDefaultImageForItem(item, true, true) or "/assetMissing.png"

  local w = wardrobe.widgets.preview .. "." .. wardrobe.preview.custom[3]
  local directives = wardrobe.util.getDirectives(item, params.dir)
  widget.setImage(w .. ".image", image .. directives)
end

--- Reference collection for all show<Category> functions.
-- Used to turn acces the showHead function from the slot (head).
wardrobe.showItemForCategory = {
  head = wardrobe.showHead,
  chest = wardrobe.showChest,
  legs = wardrobe.showLegs,
  back = wardrobe.showBack
}

-- #endregion

--- Hides the color options for a slot.
-- @param category head/chest/legs/back
-- @param [startIndex=1] First slot to hide.
function wardrobe.hideColors(category, startIndex)
  startIndex = type(startIndex) == number and startIndex or 1
  if startIndex < 1 then startIndex = 1 end

  local w = category .. ".color_"

  for i = startIndex, 16 do
    widget.setVisible(w .. i, false)
  end
  widget.setVisible(w .. "ds", false)
end

--- Updates and shows color option buttons for the item.
-- Available colors from the item are used.
-- @param [category=item.category] head/chest/legs/back
-- @param item Item to show color options for.
function wardrobe.showColors(category, item)
  local w = category .. ".color_"
  category = category or item.category
  if not item then item = { colorOptions = {} } end

  if not item.colorOptions then item.colorOptions = {} end
  for i=1,#item.colorOptions do
    widget.setVisible(w .. i, true)

    local option = item.colorOptions[i]
    local colors = wardrobe.util.orderColorOption(option)
    local newOption = {}
    for i=1,4 do
      local c = colors[i]
      if not c then break end
      newOption[wardrobe.defaultColors[i]] = c.to
    end
    local img = "/interface/wardrobe/color.png" .. wardrobe.util.colorOptionToDirectives(newOption)
    widget.setButtonImages(w .. i, {base=img, hover=img})
  end

  for i=#item.colorOptions+1,16 do
    widget.setVisible(w .. i, false)
  end
  widget.setVisible(w .. "ds", wardrobe.ds.active and not not item.name)
end

--- Sets the item selection text and icon.
-- @param category head/chest/legs/back
-- @param item Selected item.
function wardrobe.setSelection(category, item)
    local itemParams = wardrobe.util.itemParameters(item)
    widget.setItemSlotItem(wardrobe.widgets[category .. "_icon"], item and {name = item.name, parameters = itemParams} or nil)
    widget.setText(wardrobe.widgets[category .. "_name"], item and item.shortdescription or "No selection")
end

function wardrobe.getDefaultFrame(type, useCharacterFrames)
  return useCharacterFrames and wardrobe.idleFrames[type] or "idle.1"
end

--- Returns an image to display the item.
-- For chest items, a table with three images is returned.
-- The gender of the player is used to determine the frames to use.
-- @param item Item to fetch image for.
-- @param [useCharacterFrames=false] Character idle frames are used, instead of `idle.1`.
function wardrobe.getDefaultImageForItem(item, useCharacterFrames, useCharacterGender)
  local bodyFrame = wardrobe.getDefaultFrame("body", useCharacterFrames)
  local armFrame = wardrobe.getDefaultFrame("arm", useCharacterFrames)
  local gender = useCharacterGender and wardrobe.character.gender or wardrobe.gender
  
  if item.category == "head" then
    local image = wardrobe.util.fixImagePath(item.path, gender == "male" and item.maleFrames or item.femaleFrames) .. ":normal"
    return image
  elseif item.category == "chest" then
    local image = wardrobe.util.fixImagePath(item.path, gender == "male" and item.maleFrames.body or item.femaleFrames.body) .. ":" .. bodyFrame
    local imageBack = wardrobe.util.fixImagePath(item.path, gender == "male" and item.maleFrames.backSleeve or item.femaleFrames.backSleeve) .. ":" .. armFrame
    local imageFront = wardrobe.util.fixImagePath(item.path, gender == "male" and item.maleFrames.frontSleeve or item.femaleFrames.frontSleeve) .. ":" .. armFrame
    return {imageBack, image, imageFront}
  elseif item.category == "legs" then
    local image = wardrobe.util.fixImagePath(item.path, gender == "male" and item.maleFrames or item.femaleFrames) .. ":" .. bodyFrame
    return image
  elseif item.category == "back" then
    local image = wardrobe.util.fixImagePath(item.path, item.maleFrames) .. ":" .. bodyFrame
    return image
  end
end

--- Draws a dummy, adding the provided layered images.
-- @param canvas Canvas to draw on.
-- @param [layers] Layers to add between the dummy parts. Each value represents an image to draw.
--  Supported keys: back, backArm, legs, body, frontArm, head
--  For example, { "back": "/backimg.png:idle.1" }
-- @param [offset={0,0}] - Drawing offset from bottom left corner of canvas.
function wardrobe.drawDummy(canvas, layers, offset, mask)
  offset = offset or {0,0}
  local bodyPortrait = wardrobe.util.getBodyPortrait()

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

  -- Pants
  if (layers.legs) then
    canvas:drawImage(layers.legs, offset)
  end

  -- Chest
  if (layers.body) then
    canvas:drawImage(layers.body, offset)
  end

  -- Face
  if body[6] then
    canvas:drawImage(body[6] .. (mask or ""), offset)
  end

  if body[7] then
    canvas:drawImage(body[7] .. (mask or ""), offset)
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

--- Sets default config parameters.
-- Uses status properties for serialization.
-- useArmorSlot = false
-- @return Configuration
function wardrobe.setConfigParameters()
  local cfg = player.getProperty("wardrobeInterface")
  if not cfg then cfg = {} end
  if type(cfg.useArmorSlot) ~= "boolean" then
    cfg.useArmorSlot = false
    player.setProperty("wardrobeInterface", cfg)
  end
  return cfg
end

--- Gets the wardrobe config parameters.
-- @return Wardrobe parameters.
function wardrobe.getConfigParameters()
  return player.getProperty("wardrobeInterface")
end

--- Gets a wardrobe config parameter.
-- @param path Parameter key.
-- @return Parameter value.
function wardrobe.getConfigParameter(path)
  local cfg = player.getProperty("wardrobeInterface") or {}
  return path == nil and cfg or cfg[path]
end

-- #region Outfits

--- ItemList handler. Draws an outfit.
function wardrobe.addOutfit(li, items, index)
  -- Restore missing color options
  for _,slot in ipairs(wardrobe.slots) do
    local item = items[slot]
    if type(item) == "table" then
      -- Restore color options
      wardrobe.util.fixColorIndex(item)
      local cfg = root.itemConfig(item.name)
      item.colorOptions = cfg and cfg.config and cfg.config.colorOptions or {}
      -- Fix index
      wardrobe.util.fixColorIndex(item)
    end
  end

  -- Add outfit to button
  setListButtonData(li, items, index)

  -- Bind new canvas
  if index == 1  then
    wardrobe.outfitCanvas = widget.bindCanvas(li .. ".canvas")
  end

  local head, chest, legs, back = items.head, items.chest, items.legs, items.back
  local headImage, chestImages, legsImage, backImage
  local mask

  -- Head image
  if head then
    local headDir = head.directives ~= "" and head.directives
      or wardrobe.util.colorOptionToDirectives(head.colorOptions and head.colorOptions[head.colorIndex and (head.colorIndex + 1) or 1])

    headImage = wardrobe.getDefaultImageForItem(head, true) .. headDir

    if head.mask then
      -- TODO: Better custom masks.
      if head.mask:find("%?submask=/items/armors/decorative/hats/eyepatch/mask.png") then
        -- Fully mask hair
        mask = head.mask
      else
        mask = "?addmask=" .. wardrobe.util.fixImagePath(head.path, head.mask)
      end
    end
  end

  -- Chest image
  if chest then
    local dir = chest.directives ~= "" and chest.directives
      or wardrobe.util.colorOptionToDirectives(chest.colorOptions and chest.colorOptions[chest.colorIndex and (chest.colorIndex + 1) or 1])

    chestImages = wardrobe.getDefaultImageForItem(chest, true)
    chestImages[1] = chestImages[1] .. dir
    chestImages[2] = chestImages[2] .. dir
    chestImages[3] = chestImages[3] .. dir
  end

  -- Legs image
  if legs then
    local dir = legs.directives ~= "" and legs.directives
      or wardrobe.util.colorOptionToDirectives(legs.colorOptions and legs.colorOptions[legs.colorIndex and (legs.colorIndex + 1) or 1])

    legsImage = wardrobe.getDefaultImageForItem(legs, true) .. dir
  end

  -- Back image
  if back then
    local dir = back.directives ~= "" and back.directives
      or wardrobe.util.colorOptionToDirectives(back.colorOptions and back.colorOptions[back.colorIndex and (back.colorIndex + 1) or 1])

    backImage = wardrobe.getDefaultImageForItem(back, true) .. dir
  end

  -- Draw preview image
  wardrobe.drawDummy(
    wardrobe.outfitCanvas,
    {
      back = backImage,
      legs = legsImage,
      backArm = chestImages and chestImages[1],
      body = chestImages and chestImages[2],
      frontArm = chestImages and chestImages[3],
      head = headImage
    },
    {(index - 1) * 43, 0},
    mask
  )
end

--- Sets the given outfit as selected.
-- @param data stored outfit.
function wardrobe.selectOutfit(data)
  wardrobe.selection.outfit = data

  -- Set item selection
  wardrobe.selectItem(data.head, "head", false)
  wardrobe.showHead(data.head, nil)
  wardrobe.selectItem(data.chest, "chest", false)
  wardrobe.showChest(data.chest, nil)
  wardrobe.selectItem(data.legs, "legs", false)
  wardrobe.showLegs(data.legs, nil)
  wardrobe.selectItem(data.back, "back", false)
  wardrobe.showBack(data.back, nil)
end

-- Saves the current selection as a new outfit.
-- @return Outfit.
function wardrobe.saveOutfit()
  local outfit = {
    head = copy(wardrobe.selection.head),
    chest = copy(wardrobe.selection.chest),
    legs = copy(wardrobe.selection.legs),
    back = copy(wardrobe.selection.back),
    id = sb.makeUuid()
  }

  -- Optimize data
  if outfit.head then
    outfit.head.outfit = true
    outfit.head.colorOptions = nil
  end
  if outfit.chest then
    outfit.chest.outfit = true
    outfit.chest.colorOptions = nil
  end
  if outfit.legs then
    outfit.legs.outfit = true
    outfit.legs.colorOptions = nil
  end
  if outfit.back then
    outfit.back.outfit = true
    outfit.back.colorOptions = nil
  end

  table.insert(wardrobe.outfits, outfit)
  player.setProperty("wardrobeOutfits", wardrobe.outfits)
  wardrobe.lists.outfits:enqueue({outfit})
  wardrobe.updateIcon()
  return outfit
end

--- Updates the outfit icon based on the amount of stored outfits.
function wardrobe.updateIcon()
  local c = #wardrobe.outfits
  widget.setButtonOverlayImage("outfits_show", wardrobe.outfitIcons[(c+1)] or wardrobe.outfitIcons[#wardrobe.outfitIcons])
end

function wardrobe.trashOutfit(data)
  if not data then return end

  for i=1,#wardrobe.outfits do
    if wardrobe.outfits[i].id == data.id then
      table.remove(wardrobe.outfits, i)
      break;
    end
  end

  wardrobe.refreshOutfits = true -- Because clearing instantly seems to cause (in)frequent crashes.
  player.setProperty("wardrobeOutfits", wardrobe.outfits)
  wardrobe.updateIcon()
end

-- #endregion
