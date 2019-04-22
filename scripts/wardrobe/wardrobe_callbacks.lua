local cb = {}
wardrobeCallbacks = cb

local widgets

--- Register list item callbacks
function cb.init()
  widgets = config.getParameter("widgetNames")

  widget.registerMemberCallback("headSelection.list", "wardrobeCallbacks.selectHead", cb.selectHead)
  widget.registerMemberCallback("chestSelection.list", "wardrobeCallbacks.selectChest", cb.selectChest)
  widget.registerMemberCallback("legsSelection.list", "wardrobeCallbacks.selectLegs", cb.selectLegs)
  widget.registerMemberCallback("backSelection.list", "wardrobeCallbacks.selectBack", cb.selectBack)
  widget.registerMemberCallback("outfitSelection.list", "wardrobeCallbacks.selectOutfit", cb.selectOutfit)
end

-- #region Show Selection

local shown = {}

function cb.showHeadSelection()
  wardrobeUtil.setVisible(widgets.left, true)
  wardrobeUtil.setVisible(widgets.headSelection, true)
  wardrobeUtil.setVisible(widgets.chestSelection, false)

  wardrobeUtil.setVisible(widgets.left_show, false)

  widget.focus(widgets.head_search)

  -- First load
  if not shown.head then
    wardrobe.showItems("head", "vanilla", wardrobe.getSearch("head"))
    shown.head = true
  end
end

function cb.showChestSelection()
  wardrobeUtil.setVisible(widgets.left, true)
  wardrobeUtil.setVisible(widgets.chestSelection, true)
  wardrobeUtil.setVisible(widgets.headSelection, false)

  wardrobeUtil.setVisible(widgets.left_show, false)

  widget.focus(widgets.chest_search)

  -- First load
  if not shown.chest then
    wardrobe.showItems("chest", "vanilla", wardrobe.getSearch("chest"))
    shown.chest = true
  end
end

function cb.showLegsSelection()
  wardrobeUtil.setVisible(widgets.right, true)
  wardrobeUtil.setVisible(widgets.legsSelection, true)
  wardrobeUtil.setVisible(widgets.backSelection, false)

  wardrobeUtil.setVisible(widgets.right_show, false)

  widget.focus(widgets.legs_search)

  -- First load
  if not shown.legs then
    wardrobe.showItems("legs", "vanilla", wardrobe.getSearch("legs"))
    shown.legs = true
  end
end

function cb.showBackSelection()
  wardrobeUtil.setVisible(widgets.right, true)
  wardrobeUtil.setVisible(widgets.backSelection, true)
  wardrobeUtil.setVisible(widgets.legsSelection, false)

  wardrobeUtil.setVisible(widgets.right_show, false)

  widget.focus(widgets.back_search)

  -- First load
  if not shown.back then
    wardrobe.showItems("back", "vanilla", wardrobe.getSearch("back"))
    shown.back = true
  end
end

function cb.closeLeftSelection()
  wardrobeUtil.setVisible(widgets.left, false)
  wardrobeUtil.setVisible(widgets.headSelection, false)
  wardrobeUtil.setVisible(widgets.chestSelection, false)
  wardrobeUtil.setVisible(widgets.left_show, true)

  widget.blur(widgets.head_search)
  widget.blur(widgets.chest_search)
end

function cb.closeRightSelection()
  wardrobeUtil.setVisible(widgets.right, false)
  wardrobeUtil.setVisible(widgets.legsSelection, false)
  wardrobeUtil.setVisible(widgets.backSelection, false)
  wardrobeUtil.setVisible(widgets.right_show, true)

  widget.blur(widgets.legs_search)
  widget.blur(widgets.back_search)
end

-- #endregion

-- #region Select items

function cb.selectHead(_, data)
  wardrobe.selectItem(data, "head", true)
end

function cb.selectChest(_, data)
  wardrobe.selectItem(data, "chest", true)
end

function cb.selectLegs(_, data)
  wardrobe.selectItem(data, "legs", true)
end

function cb.selectBack(_, data)
  wardrobe.selectItem(data, "back", true)
end

-- #endregion

-- #region Select group

function cb.selectHeadGroup(_, data)
  wardrobe.showItems("head", data, widget.getText(widgets.head_search))
end

function cb.selectChestGroup(_, data)
  wardrobe.showItems("chest", data, widget.getText(widgets.chest_search))
end

function cb.selectLegsGroup(_, data)
  wardrobe.showItems("legs", data, widget.getText(widgets.legs_search))
end

function cb.selectBackGroup(_, data)
  wardrobe.showItems("back", data, widget.getText(widgets.back_search))
end

-- #endregion

-- #region Select color

function cb.selectHeadColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["head"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives()
  wardrobe.showHead(wardrobe.selection["head"], index)
  wardrobe.setSelection("head", wardrobe.selection["head"])
end

function cb.selectChestColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["chest"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives()
  wardrobe.showChest(wardrobe.selection["chest"], index)
  wardrobe.setSelection("chest", wardrobe.selection["chest"])
end

function cb.selectLegsColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["legs"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives()
  wardrobe.showLegs(wardrobe.selection["legs"], index)
  wardrobe.setSelection("legs", wardrobe.selection["legs"])
end

function cb.selectBackColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["back"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives()
  wardrobe.showBack(wardrobe.selection["back"], index)
  wardrobe.setSelection("back", wardrobe.selection["back"])
end

-- #endregion

-- #region Spawn itemslot

function cb.equip()
  wardrobe.equip()
end

function cb.spawn()
  wardrobe.spawn()
end

-- #endregion

-- #region Text filter

function cb.filterHead()
  wardrobe.search.changed = true
  wardrobe.search.slots.head = true
  wardrobe.search.tick = wardrobe.search.delay
end

function cb.filterChest()
  wardrobe.search.changed = true
  wardrobe.search.slots.chest = true
  wardrobe.search.tick = wardrobe.search.delay
end

function cb.filterLegs()
  wardrobe.search.changed = true
  wardrobe.search.slots.legs = true
  wardrobe.search.tick = wardrobe.search.delay
end

function cb.filterBack()
  wardrobe.search.changed = true
  wardrobe.search.slots.back = true
  wardrobe.search.tick = wardrobe.search.delay
end

function cb.clearFilter(_, slot)
  local w = slot .. "_search"
  widget.setText(w, "")
  widget.focus(w)
end

-- #endregion

-- #region Outfits

function cb.showOutfits()
  wardrobeUtil.setVisible(widgets.right_show, false)
  wardrobe.util.setVisible(wardrobe.widgets.outfitSelection, true)
end

function cb.hideOutfits()
  wardrobeUtil.setVisible(widgets.right_show, true)
  wardrobe.util.setVisible(wardrobe.widgets.outfitSelection, false)
end

function cb.saveOutfit()
  wardrobe.saveOutfit()
end

function cb.trashOutfit(data)
  wardrobe.trashing = not wardrobe.trashing
  widget.setButtonOverlayImage("outfits_trash", wardrobe.trashing and "/interface/wardrobe/outfitselection.png" or "/assetmissing.png")
end

function cb.selectOutfit(_, data)
  if not data then return end

  if wardrobe.trashing then
    wardrobe.trashOutfit(data)
  else
    wardrobe.selectOutfit(data)
  end
end

-- #endregion
