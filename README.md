# Foxhole

Built on [Starling](http://gamua.com/starling/) for Adobe AIR and Flash Player, Foxhole consists of various UI controls designed for mobile, developed by [Josh Tynjala](http://twitter.com/joshtynjala). The author develops Foxhole to support real-world mobile applications that he develops--mostly games.

To get started, you might want to check out the [API Documentation](http://www.flashtoolbox.com/foxhole-starling/documentation/) and the [Foxhole for Starling Examples](https://github.com/joshtynjala/foxhole-starling-examples).

## Available Components

Foxhole includes the following UI controls (in alphabetical order):

### Button
A typical button control, with optional toggle support. Includes a label and an icon, both optional.

### Label
A non-interactive text control. Uses bitmap fonts. A simplified replacement for `starling.text.TextField` that is built on `FoxholeControl`.

### List
A touch-based, list control. Has elastic edges and you can "throw" it. Supports custom layouts (vertical by default) and custom item renderers (with a robust default renderer that can customize the label, icon, and an "accessory" view based on the item data).

### PickerList
A control similar to a combo box. Appears as a button when closed. The list is displayed as a fullscreen overlay on top of the stage.

### Progress Bar
Displays the progress of a task over time. Non-interactive.

### Screen
An abstract class for implementing a single screen within a menu developed with `ScreenNavigator`. Includes common helper functionality, including back/menu/search hardware key callbacks, calculating scale from original resolution to current stage size, and template functions for initialize, layout and destroy.

### ScreenHeader
A header that displays a title along with a horizontal regions on the sides for additional UI controls. The left side is typically for navigation (to display a back button, for example) and the right for additional actions.

### ScreenNavigator
A state machine for menu systems. Uses events (or as3-signals) to trigger navigation between screens or to call functions. Includes very simple dependency injection.

### ScrollContainer
A container that supports scrolling and custom layouts.

### Slider
A typical horizontal or vertical slider control.

### TabBar
A line of tabs, where one may be selected at a time.

### TextInput
A text entry control that allows users to enter and edit a single line of uniformly-formatted text. Uses StageText to get the best text editing integration with the operating system.

### ToggleSwitch
A sliding on/off switch. A common alternative to a checkbox in mobile environments.

## Dependencies

The following external libraries are required. Other versions of the same library may work, but the version displayed below is the one currently recommended by the author.

* [Starling](http://gamua.com/starling/) v1.1
* [GTween](http://gskinner.com/libraries/gtween/) v2.01
* [as3-signals](https://github.com/robertpenner/as3-signals) v0.9 BETA

## Quick Links

* [Foxhole for Starling Examples](https://github.com/joshtynjala/foxhole-starling-examples)
* [API Documentation](http://www.flashtoolbox.com/foxhole-starling/documentation/)
* [Getting Started Article](https://github.com/joshtynjala/foxhole-starling/wiki/Getting-Started)
* [Official Foxhole Q&A thread on the Starling Forums](http://forum.starling-framework.org/topic/official-foxhole-components-qa)
* [Foxhole Community Extensions](https://github.com/joshtynjala/foxhole-starling/wiki/Foxhole-Community-Extensions)

## Important Note

The core architecture and non-private APIs of Foxhole for Starling are still under active design and development. Basically, for the time being, absolutely everything is subject to change, and updating to a new revision is often likely to result in broken content. If something breaks after you update to the latest revision, and you can't figure out the new way to do what you were doing before, please ask in the [Q&A thread](http://forum.starling-framework.org/topic/official-foxhole-components-qa) that I started in the Starling Forum.

## Tips

* The components do not have default skins. However, feel free to try out one of the themes included with the [Foxhole for Starling Examples](https://github.com/joshtynjala/foxhole-starling-examples).

* An Ant build script is included. Add a file called `sdk.local.properties` to override the location of the Flex SDK and `build.local.properties` to override the locations of the required third-party libraries.