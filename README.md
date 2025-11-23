# BowbAssigns

A comprehensive raid assignment manager for World of Warcraft (Mists of Pandaria), featuring a modern UI, flexible assignment management, and automated chat posting.

## Installation

1. Copy the `BowbAssigns` folder to your WoW addons directory:
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

#### 1. Roster Management
- Import Master Roster Map with class-colored player names
- View and manage all players and their roles
- Enable/disable individual players
- Persistent across game sessions

#### 2. Assignment Management
- Import HoF Cooldown Export for multiple raids (MSV, HoF, TOES, TOT, SOO)
- Modern collapsible UI with alternating row colors
- Enable/disable entire abilities or individual assignments
- Disabled sections auto-collapse for cleaner view
- Class-colored player names with spell links
- Persistent enable/disable states across sessions

#### 3. Pheromones Management (Garalon)
- Dedicated pheromones order management view
- Drag-and-drop reordering with up/down arrows
- Type position numbers to quickly reorder
- Remove players from rotation
- Auto-saves order changes

#### 4. Smart Chat Posting
- Batched message sending (20 messages per batch with delays)
- Rate-limited to avoid disconnects
- Only posts enabled assignments
- Grouped by ability and cast/health percentage
- Formatted with spell links and timing information

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
2. Add it to `BowbAssigns.toc`
3. Follow the existing manager pattern with OOP structure

### Adding UI Components

1. Create a `UI/` directory
2. Add UI files to the `.toc` file
3. Use the EventManager to handle UI events

### Adding New Events

Register event handlers using the EventManager:

```lua
BowbAssigns.EventManager:RegisterHandler("EVENT_NAME", function(event, ...)
    -- Your handler code
end, "unique_key")
```

## File Size Guidelines

- Keep files under 500 lines (strict limit)
- Prefer breaking into smaller files at 400 lines
- Each file should have a single, clear responsibility

## Development

### Releasing

See [RELEASE.md](RELEASE.md) for instructions on creating releases and publishing to CurseForge.

## Version History

- **1.0.0** (2025-11-23) - Initial release

