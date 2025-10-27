# Cursor shaders for ghostty
## WARNING: These are extremely customizable

## Trails
- [cursor_sweep.glsl](cursor_sweep.glsl): Animated trail that shrinks from previous to current cursor position
- [cursor_tail.glsl](cursor_tail.glsl): Comet-like trail, mimicing kitty terminal's cursor_trail effect
- [cursor_warp.glsl](cursor_warp.glsl): Neovide-like cursor trail, smooth af

## Pulse/Boom effects
- These trigger on cursor mode changes (block to line or vice versa, looks cool on changing modes in vim)
- [sonic_boom_cursor.glsl](sonic_boom_cursor.glsl): expanding filled circle 
- [ripple_cursor.glsl](ripple_cursor.glsl): Expanding circular ring ripple effect
- [rectangle_boom_cursor.glsl](rectangle_boom_cursor.glsl): Same as boom_cursor but rectangular(cursor shape)
- [ripple_rectangle_cursor.glsl](ripple_rectangle_cursor.glsl): Same as ripple_cursor but rectangular(cursor shape)

## Customization
- All shaders has customizable parameters (like color, duration, size, blur, etc) etc at the top of each file. You can adjust
- Also, all files has various **Easing Functions** to choose from.
  - in trail shaders, you can comment/uncomment the easing functions in the code
  - in pulse/boom shaders, you can comment/uncomment the lines in the `ANIMATION` section

# Acknowledgements
Inspired by [KroneCorylus/ghostty-shader-playground](https://github.com/KroneCorylus/ghostty-shader-playground)
