# Starbound Wardrobe

Starbound Wardrobe is a mod that uses [Quickbar Mini][qbm] to add a wardrobe interface to the matter manipulator upgrade panel, for easy access. It focusses on making it easy for users to dress up their character by selecting items, and immediately showing a preview of what these items look like on their character.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
 - [Opening the interface](#opening-the-interface)
 - [Using the interface](#using-the-interface)
- [Potential issues](#potential-issues)
- [Add-ons](#add-ons)
- [Contributing](#contributing)

## Installation

* [Download](https://github.com/Silverfeelin/Starbound-Wardrobe/releases) the release for the current version of Starbound.
* Unpack the archive.
* Place the `Wardrobe.pak` file in your mods folder (eg. `C:\Steam\steamapps\common\Starbound\mods\`).
* Optionally, place the `QuickbarMini.pak` in the same mods folder. This step is necessary if you don't have this mod or StardustLib yet.
  * If this version is older than the current version of the [Quickbar Mini][qbmRelease] mod, it is recommended to download and use that release instead.

## Usage

##### Opening the interface

* Open the matter manipulator upgrade panel.
* Select 'Open Wardrobe' from the available options.

Don't worry, the bundled [Quickbar Mini][qbm] mod ensures you still have access to the original functionality of the upgrade panel! This menu is used for the mod as it's multiplayer-friendly and can be accessed anywhere.

![Open MMU](https://raw.githubusercontent.com/Silverfeelin/Starbound-Wardrobe/master/readme/openInterface.png "Open the matter manipulator upgrade panel")

##### Using the interface

After opening the interface, you will be presented with a preview of your character. Note that the interface may take a second or two to load, as the item lists are being populated once you open the Wardrobe.

The functionality of the interface is shown in the below images.
![Wardrobe](https://raw.githubusercontent.com/Silverfeelin/Starbound-Wardrobe/master/readme/wardrobe.png "Wardrobe interface")
![Wardrobe Selecting](https://raw.githubusercontent.com/Silverfeelin/Starbound-Wardrobe/master/readme/wardrobeSelecting.png "Selecting items")

## Potential issues

* Items are fetched from an item dump bundled with the mod. Game updates that remove items may cause issues (but shouldn't), and items added in updates to the game will not appear in the Wardrobe until the mod is updated.

## Add-ons

The [Starbound-Wardrobe-Addons](https://github.com/Silverfeelin/Starbound-Wardrobe-Addons) repository houses various add-ons that can be used to add clothing from mods to the Wardrobe. These add-ons can be installed like any other mod.

The repository also contains information on how to create patches for the Wardrobe, if you're interested in creating or updating add-ons.

More information can be found on the repository itself.

## Contributing

I love suggestions! If you can think of anything to improve this mod feel free to leave a suggestion by opening a new [Issue](https://github.com/Silverfeelin/Starbound-Wardrobe/issues).
If you're really dedicated, you can also create a pull request and directly contribute to the mod!

[qbm]:https://github.com/Silverfeelin/Starbound-Quickbar-Mini
[qbmRelease]:https://github.com/Silverfeelin/Starbound-Quickbar-Mini/releases
