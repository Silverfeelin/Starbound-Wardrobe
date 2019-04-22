-- Green's Dye Suite compatibility script.

wardrobeDs = {
  active = false
}

local vars = {
  tick = 0,
  changed = 0
}

function wardrobeDs.init()
  if root.assetJson("/wardrobe/wardrobe.config").dyeSuite then
    wardrobeDs.active = true
    hook('update', wardrobeDs.update)
  end
end

function wardrobeDs.update()
  -- Listen for dye updates
  vars.tick = vars.tick - 1
  if vars.tick <= 0 then
    vars.tick = 10
    wardrobeDs.updateDye()
  end

  wardrobeDs.updateBorder()
end

--- Animates the border of the Dye Suite dye buttons.
function wardrobeDs.updateBorder()
  -- Animate border color. Modified version of Green's code
  local border = {60 + math.floor(math.sin(os.clock()) * 60), 236, 128, math.floor(math.sin(os.clock()) * 80) + 140}
  local borderHex = wardrobeUtil.getHex(border)
  local dye = wardrobeDs.dye and wardrobeDs.dye.directives or ""
  local setColor = function(w)
    widget.setButtonImages(w, {
      base = "/interface/wardrobe/color.png?replace;000=" .. borderHex .. dye,
      hover = "/interface/wardrobe/color.png?replace;000=" .. borderHex .. dye
    })
  end
  setColor("head.color_ds")
  setColor("chest.color_ds")
  setColor("legs.color_ds")
  setColor("back.color_ds")
end

--- Updates the reserved Dye Suite dye from the current palette.
-- If the dye is selected, the new dye is automatically applied.
function wardrobeDs.updateDye()
  wardrobeDs.dye = status.statusProperty("dyeSuite_palette")

  -- Skip unchanged dye.
  if not wardrobeDs.dye or wardrobeDs.dye.changed <= vars.changed then return end
  vars.changed = wardrobeDs.dye.changed

  wardrobeDs.updateSlot("head")
  wardrobeDs.updateSlot("chest")
  wardrobeDs.updateSlot("legs")
  wardrobeDs.updateSlot("back")
end

function wardrobeDs.updateSlot(slot)
  local item = wardrobe.selection[slot]
  -- Only update items with Dye Suite selected.
  if not item or not item.ds then return end

  -- Set directives
  item.directives = wardrobeDs.getDirectives()
  item.colorIndex = -1

  -- Refresh preview
  wardrobe.showItemForCategory[slot](item)
  -- Refresh item slot
  local itemParams = wardrobe.util.itemParameters(item)
  widget.setItemSlotItem(wardrobe.widgets[slot .. "_icon"], item and {name = item.name, parameters = itemParams} or nil)
end

--- Gets the directives from the Dye Suite, or nil.
-- @return Item directives or nil.
function wardrobeDs.getDirectives()
  return wardrobeDs.active and wardrobeDs.dye and wardrobeDs.dye.directives
end
