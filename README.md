# MissionAccomplished

**A comprehensive Hardcore add-on with various enhancements to improve gameplay.**

![WoW Classic](https://img.shields.io/badge/WoW-Classic-blue) ![Version](https://img.shields.io/badge/Version-1.2-green)  
**Developer:** RoxyKovu  
**Compatible with:** World of Warcraft Classic 

---

## 🚀 Overview

MissionAccomplished enhances gameplay by tracking key statistics, providing real-time notifications, and offering quality-of-life features for Hardcore mode. Whether you're monitoring your XP efficiency, tracking key combat stats, or receiving critical alerts, MissionAccomplished ensures you stay informed and prepared on your journey to level 60.

---

## 🔥 Key Features

- **Advanced XP Tracking**  
  - Monitor XP progress, XP/hour, and total XP gained.  
  - Estimate time to level 60 based on your progression rate.  
  - Centralized calculations via the Core module ensure consistency across all features.

- **Movable XP Bar**  
  - A custom XP bar positioned near the PlayerFrame displaying precise XP percentage and remaining XP.  
  - Easily reposition via **SHIFT+Drag**.  
  - Click the Gavrial icon to open settings.

- **Gavrial’s Call Notifications**  
  - Custom notification frame with fade-in/fade-out animations and a message queue to display alerts sequentially.  
  - **New in 1.2:**  
    - **Static Gavicon:** Permanently fixed in the upper left corner of the notification frame (click it to open settings).  
    - **Dynamic Event Icon:** Displays within the frame and updates based on the current event.  
    - Improved tooltip now reads: *"Click the icon in the top left corner to open settings."*

- **Naglet’s Toolkit (Utility Panel)**  
  - In-Game Tools: Ready Check, Roll, 10s Timer, Clear Marks.  
  - MissionAccomplished Tools: Reset Combat Data, Test Event Functions.  
  - System Tools: Reload UI, Clear Cache, Show FPS, and Take Screenshot.  
  - **Note:** Combat data is continuously updated in the background so that the Armory & Stats Panel always shows current values.

- **Armory & Stats Panel**  
  - Displays detailed character statistics and combat performance through Mahler’s Armory.  
  - Continuously updated combat data—even when the panel was previously closed.

- **Customizable Notifications**  
  - Guild-wide alerts for low HP warnings, player deaths, dungeon entries/exits, and level-ups.  
  - Uses a hidden chat channel for secure event syncing.  
  - All UI elements are repositionable via **SHIFT+Drag**.

- **Centralized Calculations**  
  - All core calculations (XP, combat stats, time played, etc.) are handled in one central Core module, ensuring consistent data across the add-on.

---

## 📥 Installation

1. **Download** the latest release from GitHub.
2. **Extract** the `MissionAccomplished` folder into:  
   `World of Warcraft/_classic_/Interface/AddOns/`
3. **Restart WoW** or type `/reload` in-game.

---

## 🔧 Features & Usage

### 1. XP & Level Tracking
- Calculates total XP gained and XP required to reach level 60.
- Displays XP per hour and estimated time remaining to level 60.
- Tracks combat XP per hour and enemies killed per hour.
- Shows total playtime and projected grind time.

### 2. Gavrial’s Call (Notification System)
- Custom notification frame with fade-in, display, and fade-out animations.
- Alerts for low HP warnings, level-ups, XP progress updates, dungeon entry/exit, and guild-wide notifications.
- Uses a **hidden chat channel ("GavrialcallsHCeventscodes")** for event syncing.
- **SHIFT+Drag** to reposition the notification frame.
- **New in 1.2:**  
  - A **static gavicon** fixed in the upper left corner (click it to open settings).  
  - A **dynamic event icon** that updates within the frame based on the event.  
  - Improved message queue handling to ensure no notification is skipped.

### 3. XP Bar
- Custom XP bar positioned near the PlayerFrame.
- **SHIFT+Drag** to reposition.
- Displays percentage completion and remaining XP.
- Click the **Gavrial icon** to open settings.

### 4. Naglet’s Toolkit
A settings tab containing useful tools:
- **In-Game Tools:** Ready Check, Roll, 10s Timer, Clear Marks.
- **MissionAccomplished Tools:** Reset Combat Data, Test Event Functions.
- **System Tools:** Reload UI, Clear Cache, Show FPS, Take Screenshot.

### 5. Armory & Stats Panel
- Displays detailed character statistics and combat performance.
- Integrated **Mahler's Armory** view that always shows the latest data.

### 6. Customizable Notifications
- Guild-wide alerts for low HP warnings, player deaths, dungeon transitions, and level-ups.
- Uses a hidden chat channel for secure event syncing.
- Fully repositionable via **SHIFT+Drag**.
- Quick access to settings via slash commands or by clicking dedicated icons.

---

## ⌨️ Commands

| Command                  | Function                                         |
|--------------------------|--------------------------------------------------|
| `/maopts`                | Opens the add-on settings panel                  |
| `/macomp`                | Opens the MissionAccomplished settings window    |           

---

## 🎯 Moving UI Elements

- **Gavrial’s Call Notification:**  
  Use **SHIFT+Drag** to reposition the notification frame.
  
- **XP Bar:**  
  Use **SHIFT+Drag** to reposition the XP bar.
  
- **Settings Panel:**  
  Access via the **Minimap Icon**, **Nameplate Icon**, or type **/maopts**.

---

## 📌 Development Notes

**Developer:** RoxyKovu

### Version 1.2 Enhancements:
- **Static Gavicon:** Fixed in the upper left corner of the notification frame (click to open settings).
- **Dynamic Event Icon:** Updates within the notification frame based on events.
- **Improved Text Layout:** Message text is now offset so it isn’t covered by the icons.
- **Updated Tooltip:** Now instructs "Click the icon in the top left corner to open settings."
- Enhanced message queue handling ensures all notifications are displayed sequentially.
- XP Bar UI positioning and tooltips have been improved.
- Combat data now updates continuously in the background, ensuring the Armory & Stats Panel always shows current values.
- All core calculations (XP tracking, combat stats, time played, etc.) are centralized for consistency.

### Version 1.1 Enhancements (Legacy):
- Added a hidden channel system for event notifications.
- Improved XP and progress tracking.
- Overhauled Naglet’s Toolkit with combat reset and test functions.
- Introduced new UI elements: XP Bar, Notification Panel, and Armory View.

---

## 🔮 Planned Features
- Player BankAlt Features.
- Advanced Guild Notifications (more robust event tracking).
- Additional Customization Options (frame positions, sound alerts, etc.).

---

## 🤝 Support & Feedback

Found a bug or have an idea for improvement?  
Reach out to **RoxyKovu** in the Hardcore community or submit an issue on the project's [GitHub page](https://github.com/RoxyKovu).

---

Enhance your Hardcore WoW Classic experience—Download MissionAccomplished 1.2 today!
