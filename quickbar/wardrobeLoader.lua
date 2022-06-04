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

if #sortedCharacters > 7 then
  gui.characters_background.file = "/interface/wardrobe/characters/backgroundWide.png"
end

local bg =  {
  type = "image",  
  file = "/interface/wardrobe/characters/blank.png",
  zlevel = 201,
  visible = false
}

for i, v in ipairs(sortedCharacters) do
  local titleName = v.titleName or v.species

  local buttonMale = {
    baseImage = "/interface/title/" .. titleName .. "male.png?crop=0;0;24;24",
    hoverImage = "/interface/title/" .. titleName .. "male.png?crop=0;0;24;24?brightness=30",
    baseImageChecked = "/interface/title/" .. titleName .. "male.png?crop=0;0;24;24",
    hoverImageChecked = "/interface/title/" .. titleName .. "male.png?crop=0;0;24;24?brightness=30",
    position = {xOffset + x, 0},
    text = "",
    visible = false,
    data = { species = v.species, gender = "male" }
  }
  buttonMale.hoverImage = buttonMale.hoverImage or buttonMale.baseImage .. "?brightness=20"
  buttonMale.hoverImageChecked = buttonMale.hoverImageChecked or buttonMale.baseImageChecked .. "?brightness=20"

  local buttonFemale = {
    baseImage = "/interface/title/" .. titleName .. "female.png?crop=0;0;24;24",
    hoverImage = "/interface/title/" .. titleName .. "female.png?crop=0;0;24;24?brightness=30",
    baseImageChecked = "/interface/title/" .. titleName .. "female.png?crop=0;0;24;24",
    hoverImageChecked = "/interface/title/" .. titleName .. "female.png?crop=0;0;24;24?brightness=30",
    position = {xOffset + x, dy},
    text = "",
    visible = false,
    data = { species = v.species, gender = "female" }
  }
  buttonFemale.hoverImage = buttonFemale.hoverImage or buttonFemale.baseImage .. "?brightness=20"
  buttonFemale.hoverImageChecked = buttonFemale.hoverImageChecked or buttonFemale.baseImageChecked .. "?brightness=20"

  table.insert(characterButtons, buttonMale)
  table.insert(characterButtons, buttonFemale)

  local bgMale, bgFemale = copy(bg), copy(bg)
  bgMale.position = { xOffset + x + 27, 0 + 30 }
  bgFemale.position = { xOffset + x + 27, dy + 30 }

  gui["characters_buttons_" .. (i-1) * 2] = bgMale
  gui["characters_buttons_" .. (i-1) * 2 + 1] = bgFemale

  x = x + dx
  -- Next page
  if x >= xMax then
    x = 0
  end
end

-- Open interface
player.interact("ScriptPane", config)