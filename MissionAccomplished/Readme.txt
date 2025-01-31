# MissionAccomplished
A comprehensive Hardcore add-on with various enhancements to improve gameplay.

Version: 1.1  
Developer: RoxyKovu  
Game Version Compatibility: 11403 (Classic Era)  

---

## Overview
MissionAccomplished enhances gameplay by tracking key statistics, providing real-time notifications, and offering quality-of-life features for Hardcore mode.

Features include:
- XP Tracking (Progress to level 60, XP per hour, estimated time to 60)
- Gavrial's Call (Custom notification system for key events)
- Custom XP Bar (Movable, toggleable, with progress tracking)
- Health & Combat Tracking (Lowest HP recorded, total damage, enemies per hour)
- Naglet's Toolkit (Utilities like Ready Check, Timers, Reload UI, and more)
- Armory & Stats Panel (Detailed character stats and inventory)
- Customizable Notifications (Guild alerts, instance tracking, death warnings)

---

## Installation
1. Download the latest release.
2. Extract the `MissionAccomplished` folder into: World of Warcraft/classic/Interface/AddOns/
3. Restart WoW or type `/reload` in-game.

---

## Features

### 1. XP & Level Tracking
- Calculates total XP gained and XP required to reach level 60.
- Displays XP per hour and estimated time remaining to level 60.
- Tracks combat XP per hour and enemies killed per hour.
- Displays total playtime and projected grind time.

### 2. Gavrial's Call (Notification System)
- Custom notification frame with fade-in/fade-out animation.
- Alerts for:
- Low HP warnings
- Level-ups
- XP progress updates
- Dungeon entry
- Guild-wide notifications
- Uses a **hidden chat channel ("GavrialcallsHCeventscodes")** for secure event syncing.
- **SHIFT+Drag** to reposition the notification frame.

### 3. XP Bar
- Custom XP bar positioned near the PlayerFrame.
- **SHIFT+Drag** to reposition.
- Displays percentage completion and XP remaining.
- Click the **Gavrial icon** to open settings.

### 4. Naglet's Toolkit
A settings tab containing useful tools:
- **In-Game Tools:** Ready Check, Roll, 10s Timer, Clear Marks.
- **MissionAccomplished Tools:** Reset Combat Data, Test Event Functions.
- **System Tools:** Reload UI, Clear Cache, Show FPS, Take Screenshot.

### 5. Armory & Stats Panel
- Displays detailed character statistics.
- Integrated **Mahler's Armory** view.

### 6. Customizable Notifications
- **Guild-wide alerts** for:
- Low HP warnings
- Player deaths
- Dungeon entry
- Level-ups
- Uses a hidden chat channel to ensure only add-on users receive alerts.

---

## Commands
| Command                  | Function |
|--------------------------|----------------------------------|
| `/maopts`                | Opens the add-on settings panel |
| `/macomp`                | Opens the MissionAccomplished settings window |
| `/gcall testhealth`      | Simulates a low HP alert |
| `/gcall testlevel`       | Simulates a level-up notification |
| `/gcall testprogress`    | Simulates a progress update |
| `/gcall testdungeon`     | Simulates a dungeon entry alert |

---

## How to Move UI Elements
- **Gavrial's Call Notification** → SHIFT + Drag to move.
- **XP Bar** → SHIFT + Drag to reposition.
- **Settings Panel** → Click the **Minimap Icon** or use `/maopts`.

---

## Development Notes
- **Developer:** RoxyKovu  
- **Version 1.1 Enhancements:**
- Added a hidden channel system for event notifications.
- Improved XP and Progress tracking.
- Overhauled Naglet’s Toolkit with combat reset and test functions.
- New UI elements: XP Bar, Notification Panel, Armory View.

---

## Planned Features
- Player BankAlt Features.
- Advanced Guild Notifications (More robust event tracking).
- More Customization (Frame positions, sound alerts, etc.).

---

## Support & Feedback
- Found a bug? Have an idea for improvement?
- Reach out to **RoxyKovu** in the Hardcore community or submit an issue on the project's **GitHub** page at https://github.com/RoxyKovu.
