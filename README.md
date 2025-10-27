# Cursor shaders for ghostty
## WARNING: These are extremely customizable

## Demos

| Effect                              | Demo                                                                                                 |
| --------                            | ------                                                                                               |
| Cursor Warp<br>(Neovide-like)       | ![cursor_warp](https://github.com/user-attachments/assets/5323330c-e09d-4d80-963b-f0cb8413cac9)      |
| Cursor Sweep                        | ![cursor_sweep](https://github.com/user-attachments/assets/c8979569-e0fa-48f1-afd7-9eed36df7f0a)     |
| Cursor Tail<br>(Kitty-like)         | ![cursor_tail](https://github.com/user-attachments/assets/0c1ecd67-8ff4-4198-9e89-a4435289bfa0)      |
| Ripple Cursor                       | ![ripple_cursor](https://github.com/user-attachments/assets/e489f74e-620a-490a-b5c5-d3918a5077c1)    |
| Sonic Boom                          | ![sonic_boom](https://github.com/user-attachments/assets/91ac80e6-aa2b-41a3-8b49-d674ce287709)       |
| Ripple Rectangle                    | ![ripple_rectangle](https://github.com/user-attachments/assets/5c8028eb-6ffb-4e38-a5dd-e2c0ed6a4175) |
| Customized<br>(faded warp + ripple) | ![customized_warp](https://github.com/user-attachments/assets/3be0d82e-2bff-48ab-824e-3262cbb10d4d)  |

## Trails
- [cursor_warp.glsl](cursor_warp.glsl): Neovide-like cursor trail, most customizable shader
- [cursor_sweep.glsl](cursor_sweep.glsl): Animated trail that shrinks from previous to current cursor position
- [cursor_tail.glsl](cursor_tail.glsl): Comet-like trail, mimicing kitty terminal's cursor_trail effect

## Pulse/Boom effects
- These trigger on cursor mode changes (block to line or vice versa, looks cool on changing modes in vim)
- [sonic_boom_cursor.glsl](sonic_boom_cursor.glsl): expanding filled circle 
- [ripple_cursor.glsl](ripple_cursor.glsl): Expanding circular ring ripple effect
- [rectangle_boom_cursor.glsl](rectangle_boom_cursor.glsl): Same as boom_cursor but rectangular(cursor shape)
- [ripple_rectangle_cursor.glsl](ripple_rectangle_cursor.glsl): Same as ripple_cursor but rectangular(cursor shape)


## Usage

1. Clone the repo into your ghostty shaders directory:
```bash
git clone https://github.com/sahaj-b/ghostty-cursor-shaders ~/.config/ghostty/shaders
```

2. In your `~/.config/ghostty/config`, add:
```config
custom-shader = shaders/yourshader1.glsl
custom-shader = shaders/yourshader2.glsl
# ...
```
Replace `yourshader` with the name of any shader file (e.g., `cursor_sweep`, `ripple_cursor`, etc.)

## Customization
- All shaders has customizable parameters (like color, duration, size, thickness, etc) etc at the top of each file. You can adjust
- Also, all files has various **Easing Functions** to choose from.
  - these function control the animation curve of the effects, you can make them elasitcy, springy, smooth, linear, etc by changing the easing function
  - in trail shaders, you can comment/uncomment the easing functions in the code
  - in pulse/boom shaders, you can comment/uncomment the lines in the `ANIMATION` section
  - you can also add your own easing functions if you want

## Acknowledgements
Inspired by [Neovide](https://neovide.dev/) cursor animations and [KroneCorylus/ghostty-shader-playground](https://github.com/KroneCorylus/ghostty-shader-playground)

## License
MIT

## Why use branching(if/else) instead of branchless math
- coz we are dealing with **uniform branching** here, which has **NO DIVERGENCE**.
- ie, all fragments will take the same branch path, so no performance penalty on modern GPUs
- Branchless math would force GPU to calculate animations every single frame, even when there is no need
