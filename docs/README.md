# Oh My Posh Theme Visualizer

An interactive web-based terminal simulator for previewing and testing Oh My Posh themes in a realistic terminal environment.

## Features

### 🎨 Theme Preview
- Browse and preview all Oh My Posh themes from the repository
- Real-time theme switching
- See themes in a simulated terminal with realistic colors and formatting

### 💻 Terminal Simulation
- Full xterm.js-powered terminal emulator
- Support for common shell commands:
  - `ls`, `cd`, `pwd` - File system navigation
  - `git status`, `git log`, `git branch` - Git commands
  - `npm install`, `npm start`, `npm test` - NPM commands
  - `python`, `node` - Language version checks
  - `clear`, `help`, and more

### ⚙️ Customization Options
- **Shell Type**: PowerShell, Bash, Zsh, Fish, CMD
- **Username & Hostname**: Customize prompt identity
- **Font Settings**: Size and family (Cascadia Code, Fira Code, JetBrains Mono, etc.)
- **Terminal Appearance**: Background color and opacity
- **Quick Commands**: One-click command execution buttons

### 🚀 Features
- **Responsive Design**: Works on desktop and mobile devices
- **Fullscreen Mode**: Immersive terminal experience
- **Theme Search**: Quickly find themes by name
- **Copy Configuration**: One-click theme config copying
- **Professional UI**: Modern, dark-themed interface

## Technology Stack

- **xterm.js**: Professional terminal emulator
- **Vanilla JavaScript**: No framework dependencies
- **GitHub Pages**: Static site hosting
- **GitHub Actions**: Automated deployment

## How It Works

### Theme Rendering
The application parses Oh My Posh JSON theme configurations and renders them in real-time:

1. **Theme Parser**: Reads JSON theme files and extracts configuration
2. **ANSI Color Engine**: Converts theme colors to ANSI escape codes
3. **Template Renderer**: Processes Go template syntax from theme files
4. **Terminal Display**: Renders colored prompts using xterm.js

### Command Simulation
The terminal includes a command processor that simulates common shell commands:

- File system is simulated in-memory
- Commands produce realistic output
- Git, npm, and language commands are mocked
- Command history and navigation (↑/↓ arrows) supported

## Usage

### Selecting Themes
1. Browse the theme list in the left sidebar
2. Use the search box to filter themes
3. Click any theme to preview it
4. The terminal will update with the new theme

### Customizing Display
1. Adjust username, hostname, and shell type
2. Change font size and family
3. Modify background color and opacity
4. Click "Reset to Defaults" to restore settings

### Running Commands
- Type commands directly in the terminal
- Use quick command buttons for common operations
- Press ↑/↓ to navigate command history
- Press Ctrl+C to cancel current input
- Press Ctrl+L or type `clear` to clear terminal

### Sharing Themes
- Click the copy button (📋) to copy theme configuration
- Share the GitHub Pages URL with others
- All themes load directly from the repository

## Development

### File Structure
```
docs/
├── index.html          # Main HTML page
├── css/
│   └── styles.css      # Application styling
├── js/
│   ├── app.js          # Main application logic
│   ├── theme-engine.js # Oh My Posh theme parser
│   ├── terminal-simulator.js # Command simulation
│   └── ansi-parser.js  # ANSI color processing
└── themes/             # (Optional) Additional themes
```

### Adding Themes
To add more themes to the visualizer, update the `themeFiles` array in `js/app.js`:

```javascript
const themeFiles = [
    { name: 'My Theme', path: '../path/to/theme.json' },
    // ... more themes
];
```

### Customizing Commands
Add new commands in `terminal-simulator.js`:

```javascript
this.commands = {
    mycommand: this.cmdMyCommand.bind(this),
    // ... more commands
};

cmdMyCommand(args) {
    this.writeOutput('Command output here');
}
```

## Browser Support

- Chrome/Edge (recommended)
- Firefox
- Safari
- Opera

Requires modern browser with ES6+ support.

## License

This project follows the same license as the parent repository (UnLicense).

## Credits

- **Oh My Posh**: Theme engine by Jan De Dobbeleer
- **xterm.js**: Terminal emulator library
- **Theme Collection**: Community-contributed Oh My Posh themes
