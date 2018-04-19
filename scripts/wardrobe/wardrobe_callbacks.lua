require "/scripts/wardrobe/wutil.lua"

if not wardrobe then wardrobe = {} end
if not wardrobe.cb then wardrobe.cb = {} end

local widgets

function wardrobe.cb.init()
  widgets = config.getParameter("widgetNames")

  widget.registerMemberCallback("headSelection.list", "wardrobe.cb.selectHead", wardrobe.cb.selectHead)
  widget.registerMemberCallback("chestSelection.list", "wardrobe.cb.selectChest", wardrobe.cb.selectChest)
  widget.registerMemberCallback("legsSelection.list", "wardrobe.cb.selectLegs", wardrobe.cb.selectLegs)
  widget.registerMemberCallback("backSelection.list", "wardrobe.cb.selectBack", wardrobe.cb.selectBack)
end

-- #region Show Selection

function wardrobe.cb.showHeadSelection()
  wutil.setVisible(widgets.left, true)
  wutil.setVisible(widgets.headSelection, true)
  wutil.setVisible(widgets.chestSelection, false)
end

function wardrobe.cb.showChestSelection()
  wutil.setVisible(widgets.left, true)
  wutil.setVisible(widgets.chestSelection, true)
  wutil.setVisible(widgets.headSelection, false)
end

function wardrobe.cb.showLegsSelection()
  wutil.setVisible(widgets.right, true)
  wutil.setVisible(widgets.legsSelection, true)
  wutil.setVisible(widgets.backSelection, false)
end

function wardrobe.cb.showBackSelection()
  wutil.setVisible(widgets.right, true)
  wutil.setVisible(widgets.backSelection, true)
  wutil.setVisible(widgets.legsSelection, false)
end

function wardrobe.cb.closeLeftSelection()
  wutil.setVisible(widgets.left, false)
  wutil.setVisible(widgets.headSelection, false)
  wutil.setVisible(widgets.chestSelection, false)
end

function wardrobe.cb.closeRightSelection()
  wutil.setVisible(widgets.right, false)
  wutil.setVisible(widgets.legsSelection, false)
  wutil.setVisible(widgets.backSelection, false)
end

-- #endregion

-- #region Select items

function wardrobe.cb.selectHead(_, data)

end

function wardrobe.cb.selectChest(_, data)

end

function wardrobe.cb.selectLegs(_, data)

end

function wardrobe.cb.selectBack(_, data)

end

-- #endregion

-- #region Select group

function wardrobe.cb.selectLeftGroup(_, data)

end

function wardrobe.cb.selectRightGroup(_, data)

end

-- #endregion

-- #region Select color

function wardrobe.cb.selectHeadColor(_, index)

end

function wardrobe.cb.selectChestColor(_, index)

end

function wardrobe.cb.selectLegsColor(_, index)

end

function wardrobe.cb.selectBackColor(_, index)

end

-- #endregion

-- #region Spawn itemslot

function wardrobe.cb.equip()

end

function wardrobe.cb.spawn()

end

-- #endregion

-- #region Text filter

function wardrobe.cb.filterHead()

end

function wardrobe.cb.filterChest()

end

function wardrobe.cb.filterLegs()

end

function wardrobe.cb.filterBack()

end

-- #endregion
