-- Green's Dye Suite compatibility script.

wardrobeDs = {
  active = false
}

local vars = {
  tick = 0,
  changed = { head = 0, chest = 0, legs = 0, back = 0 }
}

function wardrobeDs.init()
  local version = root.assetJson("/wardrobe/wardrobe.config").dyeSuite
  if version == true then version = 1 end
  
  wardrobeDs.version = version
  if not wardrobeDs.version then return end

  wardrobeDs.active = true
  hook('update', wardrobeDs.update)
end

function wardrobeDs.update()
  -- Listen for dye updates
  vars.tick = vars.tick - 1
  if vars.tick <= 0 then
    vars.tick = 10
    wardrobeDs.tick()
  end

  wardrobeDs.updateBorder()
end

function wardrobeDs.tick()
  if wardrobeDs.version > 1 then
    wardrobeDs.updatePalettes()
  else
    wardrobeDs.updatePalette()
  end
end

--- Animates the border of the Dye Suite dye buttons.
function wardrobeDs.updateBorder()
  -- Animate border color. Modified version of Green's code
  local border = {60 + math.floor(math.sin(os.clock()) * 60), 236, 128, math.floor(math.sin(os.clock()) * 80) + 140}
  local borderHex = wardrobeUtil.getHex(border)
  local setColor = function(w, d)
    widget.setButtonImages(w, {
      base = "/interface/wardrobe/color.png?replace;000=" .. borderHex .. d,
      hover = "/interface/wardrobe/color.png?replace;000=" .. borderHex .. d
    })
  end
  setColor("head.color_ds", wardrobeDs.getDirectives("head") or "")
  setColor("chest.color_ds", wardrobeDs.getDirectives("chest") or "")
  setColor("legs.color_ds", wardrobeDs.getDirectives("legs") or "")
  setColor("back.color_ds", wardrobeDs.getDirectives("back") or "")
end

--- Updates the reserved Dye Suite dye from the current palette.
-- If the dye is selected, the new dye is automatically applied.
function wardrobeDs.updatePalette()
  local dye = status.statusProperty("dyeSuite_palette")
  wardrobeDs.dye = dye

  -- Skip unchanged dye.
  if not dye or dye.changed <= vars.changed.head then return end
  vars.changed.head = wardrobeDs.dye.changed

  wardrobeDs.updateSlot("head", dye)
  wardrobeDs.updateSlot("chest", dye)
  wardrobeDs.updateSlot("legs", dye)
  wardrobeDs.updateSlot("back", dye)
end

--- Updates the reserved Dye Suite dye from the current palette.
-- If the dye is selected, the new dye is automatically applied.
function wardrobeDs.updatePalettes()
  local dyes = status.statusProperty("dyeSuite_partPalettes")
  wardrobeDs.dyes = dyes
  if not dyes then return end

  if dyes.head and dyes.head.changed > vars.changed.head then
    vars.changed.head = dyes.head.changed
    wardrobeDs.updateSlot("head")
  end
  if dyes.chest and dyes.chest.changed > vars.changed.chest then
    vars.changed.chest = dyes.chest.changed
    wardrobeDs.updateSlot("chest")
  end
  if dyes.legs and dyes.legs.changed > vars.changed.legs then
    vars.changed.legs = dyes.legs.changed
    wardrobeDs.updateSlot("legs")
  end
  if dyes.back and dyes.back.changed > vars.changed.back then
    vars.changed.back = dyes.back.changed
    wardrobeDs.updateSlot("back")
  end
end

function wardrobeDs.updateSlot(slot)
  local item = wardrobe.selection[slot]
  -- Only update items with Dye Suite selected.
  if not item or not item.ds then return end

  -- Set directives
  item.directives = wardrobeDs.getDirectives(slot)
  item.colorIndex = -1

  -- Refresh preview
  wardrobe.showItemForCategory[slot](item)
  -- Refresh item slot
  local itemParams = wardrobe.util.itemParameters(item)
  widget.setItemSlotItem(wardrobe.widgets[slot .. "_icon"], item and {name = item.name, parameters = itemParams} or nil)
end

--- Gets the directives from the Dye Suite, or nil.
-- @return Item directives or nil.
function wardrobeDs.getDirectives(slot)
  if wardrobeDs.version > 1 then
    local dye = wardrobeDs.dyes and wardrobeDs.dyes[slot]
    return dye and dye.directives
  else
    return wardrobeDs.dye and wardrobeDs.dye.directives
  end
end
