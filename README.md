## Mousewindows

A simple hammerspoon/lua script for optimizing the efficiency of human-computer interaction, by eliminating the need for mouse input. It is not another "mouse keys" solution, but rather one that sacrifies such simplicity in favor of one-to-one mappings between keyboard keys and portions of the display. The obvious penalty is a significantly hard learning curve, as the correlation between individual keys and grid cells have to become second nature over a prolonged period of time. However, once learned, mouse input becomes blazingly fast due to a minimization of physical effort, which pays dividend over time.

## Usage

A customizable portion of the keyboard is used to divide the display into a grid. A modifier/hyperkey of choice enables the grid and allows for placing the cursor into the center of a particular grid using the keyboard. This is a recursive process for as long as the modifier is held down: whenever a particular grid cell is selected, it itself becomes the next grid. In this manner, any position on the display may be targeted with high precision using very few keystrokes. When the desired mouse position has been obtained, clicking is automatically invoked by releasing the modifier, or the operation cancelled using the spacebar (the logical choice, as at least one hand may easily invoke it at any time). 

## Configuration

Execution behaviour is parameterized through the variables provided. I personally am using Capslock as the modifier key, which I have mapped to the Escape key at a lower level using Karabiner Elements (hence, this is why Escape is the modifier in the default configuration).