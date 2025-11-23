# Bowbassigns

A modular World of Warcraft addon with clean architecture.

## Installation

1. Copy the `Bowbassigns` folder to your WoW addons directory:
   - Retail: `World of Warcraft\_retail_\Interface\AddOns\`
   - Classic: `World of Warcraft\_classic_\Interface\AddOns\`

2. Restart WoW or type `/reload` in-game

## Usage

### Slash Commands
- `/bass` - Open the main window (or toggle if already open)
- `/bass show` - Open the main window
- `/bass hide` - Close the main window
- `/bass help` - Show available commands
- `/bass debug` - Toggle debug mode
- `/bass version` - Show addon version
- `/bass reset` - Reset configuration to defaults

### Main Features

#### 1. Roster Import
- Paste your Master Roster Map Export into the Roster tab
- Format: `ROLE-PlayerName,ROLE-PlayerName,...`
- Click "Import Roster" to load the data

#### 2. Cooldown Assignments
- Paste your HoF Cooldown Export into the Cooldowns tab
- The addon will parse all boss assignments
- Boss buttons will appear - click any boss to post assignments to raid chat
- Use "Test Mode (Party)" checkbox to post to party chat instead

#### 3. Pheromones Assignments
- Paste player names (comma or newline separated) into the Pheromones tab
- Click "Import Pheromones" to load the data
- Click "Post to Chat" to send the assignments to raid/party chat

## Architecture

The addon follows a modular, object-oriented design:

### Core/
- **Namespace.lua** - Global namespace and utility print functions
- **Constants.lua** - Centralized constants and default values

### Utils/
- **TableUtils.lua** - Table manipulation utilities
- **StringUtils.lua** - String manipulation utilities

### Managers/
- **ConfigManager.lua** - Handles configuration and saved variables
- **EventManager.lua** - Event registration and dispatch system
- **DataParser.lua** - Parses spreadsheet exports (roster, cooldowns, pheromones)
- **AssignmentManager.lua** - Stores and manages assignment data
- **MacroManager.lua** - Generates and posts boss assignment macros

### UI/
- **MainFrame.lua** - Main tabbed UI window
- **BossSelector.lua** - Boss selection and posting interface

### Init.lua
Main initialization file that bootstraps the addon and sets up event handlers.

## Extending the Addon

### Adding a New Manager

1. Create a new file in `Managers/` (e.g., `MyManager.lua`)
2. Add it to `Bowbassigns.toc`
3. Follow the existing manager pattern with OOP structure

### Adding UI Components

1. Create a `UI/` directory
2. Add UI files to the `.toc` file
3. Use the EventManager to handle UI events

### Adding New Events

Register event handlers using the EventManager:

```lua
Bowbassigns.EventManager:RegisterHandler("EVENT_NAME", function(event, ...)
    -- Your handler code
end, "unique_key")
```

## File Size Guidelines

- Keep files under 500 lines (strict limit)
- Prefer breaking into smaller files at 400 lines
- Each file should have a single, clear responsibility

## Version History

- **1.0.0** (2025-11-23) - Initial release

