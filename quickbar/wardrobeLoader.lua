local config = root.assetJson("/interface/wardrobe/wardrobe.config")
local gui = config.gui

local characters = root.assetJson("/scripts/wardrobe/characters.json")
local characterButtons = gui.characters_group.buttons;

local sortedCharacters = {}
for k, v in pairs(characters) do
  v.species = k
  table.insert(sortedCharacters, v)
end

table.sort(sortedCharacters, function(a, b)
  return (a.order or 9999) < (b.order or 9999)
end)

local x, dx, dy = 0, 25, 25
local xOffset = #sortedCharacters > 7 and 10 or 0
local xMax = dx * 7
local visible = true

if #sortedCharacters > 7 then
  gui.characters_background.file = "/interface/wardrobe/characters/backgroundWide.png"
end

for _, v in ipairs(sortedCharacters) do
  local buttonMale = {
    baseImage = v.maleButtons.baseImage,
    hoverImage = v.maleButtons.hoverImage,
    baseImageChecked = v.maleButtons.baseImageChecked,
    hoverImageChecked = v.maleButtons.hoverImageChecked,
    position = {xOffset + x, 0},
    text = "",
    visible = visible,
    data = { species = v.species, gender = "male" }
  }

  buttonMale.hoverImage = buttonMale.hoverImage or buttonMale.baseImage .. "?brightness=20"
  buttonMale.hoverImageChecked = buttonMale.hoverImageChecked or buttonMale.baseImageChecked .. "?brightness=20"

  local buttonFemale = {
    baseImage = v.femaleButtons.baseImage,
    hoverImage = v.femaleButtons.hoverImage,
    baseImageChecked = v.femaleButtons.baseImageChecked,
    hoverImageChecked = v.femaleButtons.hoverImageChecked,
    position = {xOffset + x, dy},
    text = "",
    visible = visible,
    data = { species = v.species, gender = "female" }
  }

  buttonFemale.hoverImage = buttonFemale.hoverImage or buttonFemale.baseImage .. "?brightness=20"
  buttonFemale.hoverImageChecked = buttonFemale.hoverImageChecked or buttonFemale.baseImageChecked .. "?brightness=20"

  table.insert(characterButtons, buttonMale)
  table.insert(characterButtons, buttonFemale)

  x = x + dx
  -- Next page
  if x >= xMax then
    x = 0
    visible = false
  end
end

-- Open interface
player.interact("ScriptPane", config)