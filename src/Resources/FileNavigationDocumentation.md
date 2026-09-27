# File Navigation

This document explains the folder structure used in the Godot arcade project.

## Project Structure

```text
res://
├── core/
│   ├── scenes/
│   │   ├── Hub.tscn
│   │   ├── Start.tscn
│   │   ├── Win.tscn
│   │   ├── Lose.tscn
│   │   └── Player.tscn
│   │
│   ├── scripts/
│   │   ├── Hub.gd
│   │   ├── Start.gd
│   │   ├── Win.gd
│   │   ├── Lose.gd
│   │   └── Player.gd
│   │
│   └── assets/
│
├── games/
│   ├── game_a/
│   │   ├── scenes/
│   │   │   └── GameA.tscn
│   │   ├── scripts/
│   │   │   └── GameA.gd
│   │   └── assets/
│   │
│   ├── game_b/
│   │   ├── scenes/
│   │   │   └── GameB.tscn
│   │   ├── scripts/
│   │   │   └── GameB.gd
│   │   └── assets/
│   │
│   ├── game_c/
│   └── ...
│
├── managers/
│   ├── AudioManager.gd
│   └── GameManager.gd
│
└── project.godot
```

## Core

The `core` folder contains scenes and scripts used by the main arcade environment.

### core/scenes

Contains the main shared scenes.

- `HubScene.tscn`  
  Main arcade world where the player can move between games.

- `StartScreen.tscn`  
  Starting screen of the project.

- `WinScreen.tscn`  
  Screen shown after a game is won.

- `LoseScreen.tscn`  
  Screen shown after a game is lost.

- `PlayerScene.tscn`  
  Shared player scene used by the Hub and any games that require the main player.

### core/scripts

Contains scripts associated with the core scenes.

Each script should normally match the name of the scene it controls.

Example:

```text
HubScene.tscn
HubScript.gd
```

### core/assets

Contains assets used by the main arcade environment.

Examples:

- Hub backgrounds
- Player sprites
- Main menu graphics
- Shared arcade textures

## Games

The `games` folder contains all individual arcade games.

Each game should have its own folder.

Example:

```text
games/
├── game_a/
├── game_b/
├── game_c/
└── ...
```

This allows the project to support multiple games without mixing their files together.

Each game folder should normally contain:

```text
game_name/
├── scenes/
├── scripts/
└── assets/
```

### scenes

Contains scenes that belong only to that game.

Example:

```text
games/game_a/scenes/GameA.tscn
```

### scripts

Contains scripts used only by that game.

Example:

```text
games/game_a/scripts/GameA.gd
```

### assets

Contains assets used only by that game.

Examples:

- Sprites
- Backgrounds
- Sound effects
- Textures
- Animations

Game-specific assets should remain inside that game's folder whenever possible.

## Managers

The `managers` folder contains scripts that control systems used throughout the project.

### AudioManager.gd

Controls shared audio functionality such as:

- Music
- Sound effects
- Volume settings
- Audio buses

This script may be added as an Autoload.

### GameManager.gd

Controls shared game behavior when needed.

Possible responsibilities include:

- Switching between scenes
- Returning to the Hub
- Tracking the current game
- Handling general arcade state

## Adding a New Game

When adding a new arcade game, create a new folder inside `games`.

Example:

```text
games/game_d/
├── scenes/
│   └── GameD.tscn
├── scripts/
│   └── GameD.gd
└── assets/
```

Do not place files from one game inside another game's folder.

## File Naming

Use consistent names for scenes and scripts.

Example:

```text
GameA.tscn
GameA.gd
```





## General Rule

If a file is used only by one game, keep it inside that game's folder.

If a file belongs to the main arcade environment, keep it inside `core`.

If a script controls a system used across the whole project, keep it inside `managers`.
