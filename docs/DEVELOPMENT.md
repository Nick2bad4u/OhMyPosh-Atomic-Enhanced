# Development Guide

This guide explains how to develop and test the Oh My Posh Theme Visualizer locally.

## Prerequisites

- Node.js 18+ (for generating theme index)
- Python 3 or any HTTP server
- Modern web browser

## Local Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced.git
cd OhMyPosh-Atomic-Enhanced
```

### 2. Generate Theme Index

The theme index must be generated before running the site:

```bash
node .github/scripts/generate-theme-index.js
```

This scans all Oh My Posh theme files and creates `docs/themes/index.json`.

### 3. Start Local Server

You can use any HTTP server. Examples:

**Python:**
```bash
cd docs
python3 -m http.server 8080
```

**Node.js (using npx):**
```bash
cd docs
npx http-server -p 8080
```

**PHP:**
```bash
cd docs
php -S localhost:8080
```

### 4. Open in Browser

Navigate to `http://localhost:8080` in your browser.

## Important Notes

### CDN Dependencies

The application loads xterm.js and related libraries from CDN:
- xterm.js v5.3.0
- xterm-addon-fit v0.8.0
- xterm-addon-web-links v0.9.0

**For local development:**
- Ensure you have internet connectivity to access CDN resources
- Some ad blockers or content blockers may prevent CDN loading
- If you see "Terminal Library Not Loaded", temporarily disable content blockers

**For production (GitHub Pages):**
- CDN links work reliably
- No additional setup needed

### Offline Development

To work completely offline, you can download the libraries:

```bash
cd docs
mkdir -p lib/xterm
cd lib/xterm

# Download xterm.js files
curl -O https://cdn.jsdelivr.net/npm/xterm@5.3.0/css/xterm.min.css
curl -O https://cdn.jsdelivr.net/npm/xterm@5.3.0/lib/xterm.min.js
curl -O https://cdn.jsdelivr.net/npm/xterm-addon-fit@0.8.0/lib/xterm-addon-fit.min.js
curl -O https://cdn.jsdelivr.net/npm/xterm-addon-web-links@0.9.0/lib/xterm-addon-web-links.min.js
```

Then update `index.html` to use local paths instead of CDN URLs.

## Project Structure

```
docs/
├── index.html              # Main HTML page
├── css/
│   └── styles.css          # Application styles
├── js/
│   ├── app.js              # Main application
│   ├── ansi-parser.js      # ANSI color parser
│   ├── theme-engine.js     # Oh My Posh theme renderer
│   └── terminal-simulator.js  # Terminal command simulator
├── themes/
│   └── index.json          # Generated theme index
└── lib/                    # (Optional) Local library files
    └── xterm/
```

## Adding New Themes

Themes are automatically discovered. To add new themes:

1. Add your `.json` theme file to the repository root (for custom themes) or `ohmyposh-official-themes/themes/` (for official themes)
2. Run the theme index generator:
   ```bash
   node .github/scripts/generate-theme-index.js
   ```
3. The new theme will appear in the visualizer

## Modifying the Theme Engine

The theme engine (`theme-engine.js`) parses Oh My Posh JSON configurations. Key methods:

- `loadTheme(config)` - Load a theme configuration
- `renderPrompt()` - Render the complete prompt
- `renderSegment(segment)` - Render individual segments
- `renderTemplate(template, data)` - Process Go templates

## Extending Command Simulation

Add new commands in `terminal-simulator.js`:

```javascript
// Add to commands object
this.commands = {
    mycommand: this.cmdMyCommand.bind(this),
    // ...
};

// Implement command handler
cmdMyCommand(args) {
    this.writeOutput('Command output');
    // Use this.writeError() for errors
    // Use this.writeColored() for colored output
}
```

## Testing

### Manual Testing Checklist

- [ ] Theme list loads and displays correctly
- [ ] Themes can be selected and applied
- [ ] Terminal displays themed prompts
- [ ] Commands execute and produce output
- [ ] Customization controls update display
- [ ] Search filters theme list
- [ ] Quick command buttons work
- [ ] Responsive design on mobile
- [ ] Fullscreen mode works
- [ ] Copy theme config works

### Browser Testing

Test in multiple browsers:
- Chrome/Edge (recommended)
- Firefox
- Safari
- Mobile browsers

## GitHub Pages Deployment

The site automatically deploys via GitHub Actions when changes are pushed to `main`:

1. Workflow runs: `.github/workflows/github-pages.yml`
2. Theme index is generated
3. `docs/` folder is deployed to GitHub Pages
4. Site is available at: `https://nick2bad4u.github.io/OhMyPosh-Atomic-Enhanced/`

## Common Issues

### Terminal Not Loading

**Symptom:** "Terminal Library Not Loaded" error

**Solutions:**
1. Check browser console for CDN errors
2. Disable ad/content blockers
3. Verify internet connectivity
4. Try a different browser

### Themes Not Loading

**Symptom:** Theme list shows "Loading themes..." indefinitely

**Solutions:**
1. Verify `themes/index.json` exists
2. Check browser console for fetch errors
3. Ensure local server is running
4. Regenerate theme index

### Commands Not Working

**Symptom:** Commands don't execute or produce errors

**Solutions:**
1. Check browser console for JavaScript errors
2. Verify terminal is properly initialized
3. Check command implementation in `terminal-simulator.js`

## Contributing

When contributing:

1. Test locally before submitting PR
2. Regenerate theme index if adding themes
3. Follow existing code style
4. Update documentation if needed
5. Test in multiple browsers

## Resources

- [xterm.js Documentation](https://xtermjs.org/)
- [Oh My Posh Documentation](https://ohmyposh.dev/docs)
- [GitHub Pages Documentation](https://docs.github.com/pages)
