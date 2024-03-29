wardrobeCallbacks = {}

local widgets

--- Register list item callbacks
function wardrobeCallbacks.init()
  widgets = config.getParameter("widgetNames")

  widget.registerMemberCallback("headSelection.list", "wardrobeCallbacks.selectHead", wardrobeCallbacks.selectHead)
  widget.registerMemberCallback("chestSelection.list", "wardrobeCallbacks.selectChest", wardrobeCallbacks.selectChest)
  widget.registerMemberCallback("legsSelection.list", "wardrobeCallbacks.selectLegs", wardrobeCallbacks.selectLegs)
  widget.registerMemberCallback("backSelection.list", "wardrobeCallbacks.selectBack", wardrobeCallbacks.selectBack)
  widget.registerMemberCallback("outfitSelection.list", "wardrobeCallbacks.selectOutfit", wardrobeCallbacks.selectOutfit)
end

-- #region Show Selection

local shown = {}

function wardrobeCallbacks.showHeadSelection()
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

function wardrobeCallbacks.showChestSelection()
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

function wardrobeCallbacks.showLegsSelection()
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

function wardrobeCallbacks.showBackSelection()
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

function wardrobeCallbacks.closeLeftSelection()
  wardrobeUtil.setVisible(widgets.left, false)
  wardrobeUtil.setVisible(widgets.headSelection, false)
  wardrobeUtil.setVisible(widgets.chestSelection, false)
  wardrobeUtil.setVisible(widgets.left_show, true)

  widget.blur(widgets.head_search)
  widget.blur(widgets.chest_search)
end

function wardrobeCallbacks.closeRightSelection()
  wardrobeUtil.setVisible(widgets.right, false)
  wardrobeUtil.setVisible(widgets.legsSelection, false)
  wardrobeUtil.setVisible(widgets.backSelection, false)
  wardrobeUtil.setVisible(widgets.right_show, true)

  widget.blur(widgets.legs_search)
  widget.blur(widgets.back_search)
end

-- #endregion

-- #region Select items

function wardrobeCallbacks.selectHead(_, data)
  wardrobe.selectItem(data, "head", true)
end

function wardrobeCallbacks.selectChest(_, data)
  wardrobe.selectItem(data, "chest", true)
end

function wardrobeCallbacks.selectLegs(_, data)
  wardrobe.selectItem(data, "legs", true)
end

function wardrobeCallbacks.selectBack(_, data)
  wardrobe.selectItem(data, "back", true)
end

-- #endregion

-- #region Select group

function wardrobeCallbacks.selectHeadGroup(_, data)
  wardrobe.showItems("head", data, widget.getText(widgets.head_search))
end

function wardrobeCallbacks.selectChestGroup(_, data)
  wardrobe.showItems("chest", data, widget.getText(widgets.chest_search))
end

function wardrobeCallbacks.selectLegsGroup(_, data)
  wardrobe.showItems("legs", data, widget.getText(widgets.legs_search))
end

function wardrobeCallbacks.selectBackGroup(_, data)
  wardrobe.showItems("back", data, widget.getText(widgets.back_search))
end

-- #endregion

-- #region Select color

function wardrobeCallbacks.selectHeadColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["head"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives("head")
  wardrobe.showHead(wardrobe.selection["head"], index)
  wardrobe.setSelection("head", wardrobe.selection["head"])
end

function wardrobeCallbacks.selectChestColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["chest"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives("chest")
  wardrobe.showChest(wardrobe.selection["chest"], index)
  wardrobe.setSelection("chest", wardrobe.selection["chest"])
end

function wardrobeCallbacks.selectLegsColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["legs"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives("legs")
  wardrobe.showLegs(wardrobe.selection["legs"], index)
  wardrobe.setSelection("legs", wardrobe.selection["legs"])
end

function wardrobeCallbacks.selectBackColor(_, index)
  if type(index) == "table" then index = index.index end
  local item = wardrobe.selection["back"]
  item.colorIndex = index
  item.ds = index == -1 or nil
  item.directives = item.ds and wardrobe.ds.getDirectives("back")
  wardrobe.showBack(wardrobe.selection["back"], index)
  wardrobe.setSelection("back", wardrobe.selection["back"])
end

-- #endregion

-- #region Select character

function wardrobeCallbacks.showCharacters()
  wardrobeCallbacks.closeLeftSelection()
  wardrobeUtil.setVisible(widgets.left_show, false)
  wardrobeUtil.setVisible(widgets.spawn, false)
  wardrobeUtil.setVisible(wardrobe.widgets.characterSelection, true)
  wardrobeUtil.setVisible(wardrobe.widgets.characterPaging, wardrobe.characterPages > 1)
  wardrobe.showCharacterPage(wardrobe.characterPage)
end

function wardrobeCallbacks.hideCharacters()
  wardrobeUtil.setVisible(widgets.left_show, true)
  wardrobeUtil.setVisible(widgets.spawn, true)
  wardrobeUtil.setVisible(wardrobe.widgets.characterSelection, false)
  wardrobeUtil.setVisible(wardrobe.widgets.characterPaging, false)

  for i = 1, wardrobe.characterCount do
    widget.setVisible("characters_buttons_" .. (i-1) * 2, false)
    widget.setVisible("characters_buttons_" .. (i-1) * 2 + 1, false)
  end
end

function wardrobeCallbacks.selectCharacter(_, data)
  local selectedIndex = widget.getSelectedOption("characters_group")
  local selected = widget.getSelectedOption("characters_group") > -1
  data = data or widget.getSelectedData("characters_group")

  local img = "/interface/wardrobe/characters/blank.png"
  local imgSel = "/interface/wardrobe/characters/blankselected.png"
  for i = 1, wardrobe.characterCount do
    local maleSelected = selectedIndex == (i - 1) * 2
    local femaleSelected = selectedIndex == (i - 1) * 2 + 1
    widget.setImage("characters_buttons_" .. (i-1) * 2, maleSelected and imgSel or img)
    widget.setImage("characters_buttons_" .. (i-1) * 2 + 1, femaleSelected and imgSel or img)
  end

  wardrobe.character.species = selected and data.species or nil
  wardrobe.character.gender = selected and data.gender or player.gender()
  wardrobe.loadPreview()
  wardrobe.showHead(wardrobe.selection.head)
  wardrobe.showChest(wardrobe.selection.chest)
  wardrobe.showLegs(wardrobe.selection.legs)
  wardrobe.showBack(wardrobe.selection.back)
end

function wardrobeCallbacks.nextCharacters()
  wardrobe.showCharacterPage(wardrobe.characterPage + 1)
end

function wardrobeCallbacks.prevCharacters()
  wardrobe.showCharacterPage(wardrobe.characterPage - 1)
end

-- #endregion

-- #region Spawn itemslot

function wardrobeCallbacks.equip()
  wardrobe.equip()
end

function wardrobeCallbacks.spawn()
  wardrobe.spawn()
end

-- #endregion

-- #region Text filter

function wardrobeCallbacks.filterHead()
  wardrobe.search.changed = true
  wardrobe.search.slots.head = true
  wardrobe.search.tick = wardrobe.search.delay
end

function wardrobeCallbacks.filterChest()
  wardrobe.search.changed = true
  wardrobe.search.slots.chest = true
  wardrobe.search.tick = wardrobe.search.delay
end

function wardrobeCallbacks.filterLegs()
  wardrobe.search.changed = true
  wardrobe.search.slots.legs = true
  wardrobe.search.tick = wardrobe.search.delay
end

function wardrobeCallbacks.filterBack()
  wardrobe.search.changed = true
  wardrobe.search.slots.back = true
  wardrobe.search.tick = wardrobe.search.delay
end

function wardrobeCallbacks.clearFilter(_, slot)
  local w = slot .. "_search"
  widget.setText(w, "")
  widget.focus(w)
end

-- #endregion

-- #region Outfits

function wardrobeCallbacks.showOutfits()
  wardrobeUtil.setVisible(widgets.right_show, false)
  wardrobe.util.setVisible(wardrobe.widgets.outfitSelection, true)
end

function wardrobeCallbacks.hideOutfits()
  wardrobeUtil.setVisible(widgets.right_show, true)
  wardrobe.util.setVisible(wardrobe.widgets.outfitSelection, false)
end

function wardrobeCallbacks.saveOutfit()
  wardrobe.saveOutfit()
end

function wardrobeCallbacks.trashOutfit(data)
  wardrobe.trashing = not wardrobe.trashing
  widget.setButtonOverlayImage("outfits_trash", wardrobe.trashing and "/interface/wardrobe/outfitselection.png" or "/assetmissing.png")
end

function wardrobeCallbacks.selectOutfit(_, data)
  if not data then return end

  if wardrobe.trashing then
    wardrobe.trashOutfit(data)
  else
    wardrobe.selectOutfit(data)
  end
end

-- #endregion
