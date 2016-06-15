# Starbound Wardrobe
**Currently built for nightly only!**  
Starbound Wardrobe is a mod that uses [Manipulated UI][mui] to add a wardrobe interface to the matter manipulator upgrade panel, for easy access. It focusses on making it easy for users to dress up their character by selecting items, and immediately showing a preview of what these items look like on their character.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
 - [Opening the interface](#opening-the-interface)
 - [Using the interface](#using-the-interface)
- [Planned](#planned)
- [Potential issues](#potential-issues)
- [Contributing](#contributing)

## Installation
* [Download](https://github.com/Silverfeelin/Starbound-Wardrobe/releases) the release for the current version of Starbound.
* Unpack the archive.
* Place the `Wardrobe.modpak` file in your mods folder (eg. `D:\Steam\steamapps\common\Starbound\mods\`).
* Optionally, place the `ManipulatedUI.modpak` in the same mods folder if you don't have this mod yet.
  * If this version is older than the current version of [Manipulated UI][muiRelease], it is recommended to download and use that release instead.

## Usage
##### Opening the interface
* Open the matter manipulator upgrade panel.
* Select 'Open Wardrobe' from the available options.

Don't worry, the bundled [Manipulated UI][mui] mod ensures you still have access to the original functionality of the upgrade panel! This menu is used for the mod as it's multiplayer-friendly and can be accessed anywhere.

![Open MMU](https://raw.githubusercontent.com/Silverfeelin/Starbound-Wardrobe/master/readme/openInterface.png "Open the matter manipulator upgrade panel")

##### Using the interface
After opening the interface, you will be presented with a preview of your character. Note that the interface may take a second or two to load, as the item lists are being populated once you open the Wardrobe.

The functionality of the interface is shown in the below images.
![Wardrobe](https://raw.githubusercontent.com/Silverfeelin/Starbound-Wardrobe/master/readme/wardrobe.png "Wardrobe interface")
![Wardrobe Selecting](https://raw.githubusercontent.com/Silverfeelin/Starbound-Wardrobe/master/readme/wardrobeSelecting.png "Selecting items")

## Planned
* Storage: a set amount of slots you can use to store and load outfits in.

## Potential issues
* Items are fetched from an item dump bundled with the mod. Game updates that remove items may cause issues (but shouldn't), and items added in game updates will not appear in the Wardrobe until the mod is updated.
* Item selection and color options are not shown on the screen at the same time. Solution would be to make the item selection *even* smaller, which in turn makes selecting items rather annoying.
* Something you most likely won't notice, but color options are applied through `directives` rather than the `colorIndex` parameter of the item. This is due to the seemingly ambiguous numbers used by the game.

## Contributing
I love suggestions! If you can think of anything to improve this mod feel free to leave a suggestion on the discussion thread over at PlayStarbound (link pending).  
If you're really dedicated, you can also create a pull request and directly contribute to the mod!
[mui]:(https://github.com/Silverfeelin/Starbound-ManipulatedUI)
[muiRelease]:(https://github.com/Silverfeelin/Starbound-ManipulatedUI/releases)
