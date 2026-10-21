# AR/VR 3D Scene Reconstructions: Godot 4 + OpenXR

Part of the Augmented & Virtual Reality course (M.Sc. IPCVai, Université de Bordeaux, 2026). Built in Godot 4 with OpenXR, tested on Meta Quest. Each lab is on its own branch, and `main` holds the final game.

| Branch | What it contains |
|---|---|
| `basic-xr-scene` | Minimal XR scene: XROrigin3D, XRCamera3D, tracked controllers, OpenXR action map |
| `test_environment_manipulation` | selection and manipulation: per-hand ray casting with a hit pointer, button activation by ray, **Go-Go** style grab (the object stays on the ray at constant depth; the joystick moves it along the ray, clamped 0.3–10 m) |
| `navigation_environment_manipulation` | navigation: joystick locomotion in the view direction, **snap turn** (30° steps) or smooth turn, **vignette for vection reduction** while moving, and **teleportation** to the ray hit point on the ground layer |
| `main` (`beat_the_creeps`) | *Beat the Creeps (VR)*: Godot's "Squash the Creeps" ported to VR. The player grabs a bat with the OpenXR grip pose and hits incoming mobs, with a score label and a restart button that appears in front of the head |

## Design notes
- **Shared hand logic** lives in `hand.gd` (`class_name Hand`). The left and right hands extend it, so one hand navigates and the other manipulates.
- **Grip pose**: the bat is re-oriented −90° about X so it comes out of the fist along the OpenXR grip axis.
- **VR-specific changes from the flat game**: mob speed drops from 10–18 to 3–6 m/s so mobs can be hit with a bat, the spawn spread narrows from ±45° to ±5° because the player stands still, and mobs are freed on leaving the arena rather than on leaving the screen, because the player can turn their head.
- **Interaction safety**: the restart button has an arming delay, so a hand that happens to be there cannot press it by accident. Collision layers separate the ground, interactables and enemies, so each ray only hits what it should.
- **No headset?** The XR Input Simulator addon loads automatically when OpenXR fails to initialise. This only works in the editor.

## Run
Open `project.godot` in Godot 4 with OpenXR enabled. Deploy to Quest through the Android export, or run in the editor with the simulator.
