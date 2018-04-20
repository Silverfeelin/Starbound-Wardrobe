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

local shown = {}

function wardrobe.cb.showHeadSelection()
  wutil.setVisible(widgets.left, true)
  wutil.setVisible(widgets.headSelection, true)
  wutil.setVisible(widgets.chestSelection, false)

  wutil.setVisible(widgets.left_show, false)

  if not shown.head then
    wardrobe.showHeadItems("vanilla")
    shown.head = true
  end
end

function wardrobe.cb.showChestSelection()
  wutil.setVisible(widgets.left, true)
  wutil.setVisible(widgets.chestSelection, true)
  wutil.setVisible(widgets.headSelection, false)

  wutil.setVisible(widgets.left_show, false)

  if not shown.chest then
    wardrobe.showChestItems("vanilla")
    shown.chest = true
  end
end

function wardrobe.cb.showLegsSelection()
  wutil.setVisible(widgets.right, true)
  wutil.setVisible(widgets.legsSelection, true)
  wutil.setVisible(widgets.backSelection, false)

  wutil.setVisible(widgets.right_show, false)

  if not shown.legs then
    wardrobe.showLegsItems("vanilla")
    shown.legs = true
  end
end

function wardrobe.cb.showBackSelection()
  wutil.setVisible(widgets.right, true)
  wutil.setVisible(widgets.backSelection, true)
  wutil.setVisible(widgets.legsSelection, false)

  wutil.setVisible(widgets.right_show, false)

  if not shown.back then
    wardrobe.showBackItems("vanilla")
    shown.back = true
  end
end

function wardrobe.cb.closeLeftSelection()
  wutil.setVisible(widgets.left, false)
  wutil.setVisible(widgets.headSelection, false)
  wutil.setVisible(widgets.chestSelection, false)
  wutil.setVisible(widgets.left_show, true)
end

function wardrobe.cb.closeRightSelection()
  wutil.setVisible(widgets.right, false)
  wutil.setVisible(widgets.legsSelection, false)
  wutil.setVisible(widgets.backSelection, false)
  wutil.setVisible(widgets.right_show, true)
end

-- #endregion

-- #region Select items

function wardrobe.cb.selectHead(_, data)
  wardrobe.selectItem(data, "head")
end

function wardrobe.cb.selectChest(_, data)
  wardrobe.selectItem(data, "chest")
end

function wardrobe.cb.selectLegs(_, data)
  wardrobe.selectItem(data, "legs")
end

function wardrobe.cb.selectBack(_, data)
  wardrobe.selectItem(data, "back")
end

-- #endregion

-- #region Select group

function wardrobe.cb.selectHeadGroup(_, data)
  wardrobe.showHeadItems(data)
end

function wardrobe.cb.selectChestGroup(_, data)
  wardrobe.showChestItems(data)
end

function wardrobe.cb.selectLegsGroup(_, data)
  wardrobe.showLegsItems(data)
end

function wardrobe.cb.selectBackGroup(_, data)
  wardrobe.showBackItems(data)
end

-- #endregion

-- #region Select color

function wardrobe.cb.selectHeadColor(_, index)
  wardrobe.selection["head"].colorIndex = index
  wardrobe.showHead(wardrobe.selection["head"], index)
end

function wardrobe.cb.selectChestColor(_, index)
  wardrobe.selection["chest"].colorIndex = index
  wardrobe.showChest(wardrobe.selection["chest"], index)
end

function wardrobe.cb.selectLegsColor(_, index)
  wardrobe.selection["legs"].colorIndex = index
  wardrobe.showLegs(wardrobe.selection["legs"], index)
end

function wardrobe.cb.selectBackColor(_, index)
  wardrobe.selection["back"].colorIndex = index
  wardrobe.showBack(wardrobe.selection["back"], index)
end

-- #endregion

-- #region Spawn itemslot

function wardrobe.cb.equip()
  wardrobe.equip()
end

function wardrobe.cb.spawn()
  wardrobe.spawn()
end

-- #endregion

-- #region Text filter

function wardrobe.cb.filterHead()
  wardrobe.search.changed = true
  wardrobe.search.head = true
  wardrobe.search.tick = wardrobe.search.delay
end

function wardrobe.cb.filterChest()
  wardrobe.search.changed = true
  wardrobe.search.chest = true
  wardrobe.search.tick = wardrobe.search.delay
end

function wardrobe.cb.filterLegs()
  wardrobe.search.changed = true
  wardrobe.search.legs = true
  wardrobe.search.tick = wardrobe.search.delay
end

function wardrobe.cb.filterBack()
  wardrobe.search.changed = true
  wardrobe.search.back = true
  wardrobe.search.tick = wardrobe.search.delay
end

-- #endregion
