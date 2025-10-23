/**
 * Main Application
 * Manages the Oh My Posh Theme Visualizer application
 */

class ThemeVisualizerApp {
    constructor() {
        this.terminal = null;
        this.fitAddon = null;
        this.themeEngine = null;
        this.terminalSimulator = null;
        this.themes = [];
        this.currentTheme = null;
        
        // Default settings
        this.settings = {
            username: 'user',
            hostname: 'localhost',
            shell: 'pwsh',
            fontSize: 14,
            fontFamily: "'Cascadia Code', 'Courier New', monospace",
            backgroundColor: '#1e1e1e',
            opacity: 1
        };
        
        this.init();
    }
    
    /**
     * Initialize the application
     */
    async init() {
        try {
            this.setupTerminal();
            this.setupControls();
            await this.loadThemes();
            this.updateStatus('Ready');
        } catch (error) {
            console.error('Initialization error:', error);
            this.updateStatus('Error: ' + error.message, true);
        }
    }
    
    /**
     * Setup xterm.js terminal
     */
    setupTerminal() {
        // Create terminal instance
        this.terminal = new Terminal({
            cursorBlink: true,
            fontSize: this.settings.fontSize,
            fontFamily: this.settings.fontFamily,
            theme: {
                background: this.settings.backgroundColor,
                foreground: '#ffffff',
                cursor: '#ffffff',
                cursorAccent: '#000000',
                selection: 'rgba(255, 255, 255, 0.3)',
                black: '#000000',
                red: '#cd3131',
                green: '#0dbc79',
                yellow: '#e5e510',
                blue: '#2472c8',
                magenta: '#bc3fbc',
                cyan: '#11a8cd',
                white: '#e5e5e5',
                brightBlack: '#666666',
                brightRed: '#f14c4c',
                brightGreen: '#23d18b',
                brightYellow: '#f5f543',
                brightBlue: '#3b8eea',
                brightMagenta: '#d670d6',
                brightCyan: '#29b8db',
                brightWhite: '#ffffff'
            },
            allowProposedApi: true
        });
        
        // Load addons
        this.fitAddon = new FitAddon.FitAddon();
        this.terminal.loadAddon(this.fitAddon);
        this.terminal.loadAddon(new WebLinksAddon.WebLinksAddon());
        
        // Open terminal
        const terminalElement = document.getElementById('terminal');
        this.terminal.open(terminalElement);
        this.fitAddon.fit();
        
        // Initialize theme engine and simulator
        this.themeEngine = new ThemeEngine();
        this.terminalSimulator = new TerminalSimulator(this.terminal, this.themeEngine);
        
        // Update context with settings
        this.updateThemeContext();
        
        // Show welcome message
        this.terminalSimulator.initialize();
        
        // Handle resize
        window.addEventListener('resize', () => {
            this.fitAddon.fit();
        });
    }
    
    /**
     * Setup UI controls
     */
    setupControls() {
        // Theme search
        const searchInput = document.getElementById('theme-search');
        searchInput?.addEventListener('input', (e) => {
            this.filterThemes(e.target.value);
        });
        
        // Customization controls
        document.getElementById('username')?.addEventListener('change', (e) => {
            this.settings.username = e.target.value;
            this.updateThemeContext();
        });
        
        document.getElementById('hostname')?.addEventListener('change', (e) => {
            this.settings.hostname = e.target.value;
            this.updateThemeContext();
        });
        
        document.getElementById('shell-type')?.addEventListener('change', (e) => {
            this.settings.shell = e.target.value;
            this.updateThemeContext();
        });
        
        document.getElementById('font-size')?.addEventListener('input', (e) => {
            this.settings.fontSize = parseInt(e.target.value);
            document.getElementById('font-size-value').textContent = `${this.settings.fontSize}px`;
            this.terminal.options.fontSize = this.settings.fontSize;
            this.fitAddon.fit();
        });
        
        document.getElementById('font-family')?.addEventListener('change', (e) => {
            this.settings.fontFamily = e.target.value;
            this.terminal.options.fontFamily = this.settings.fontFamily;
        });
        
        document.getElementById('bg-color')?.addEventListener('input', (e) => {
            this.settings.backgroundColor = e.target.value;
            document.getElementById('bg-color-text').value = e.target.value;
            this.updateTerminalBackground();
        });
        
        document.getElementById('bg-color-text')?.addEventListener('change', (e) => {
            const color = e.target.value;
            if (/^#[0-9A-F]{6}$/i.test(color)) {
                this.settings.backgroundColor = color;
                document.getElementById('bg-color').value = color;
                this.updateTerminalBackground();
            }
        });
        
        document.getElementById('opacity')?.addEventListener('input', (e) => {
            this.settings.opacity = parseFloat(e.target.value);
            document.getElementById('opacity-value').textContent = `${Math.round(this.settings.opacity * 100)}%`;
            this.updateTerminalBackground();
        });
        
        // Reset settings
        document.getElementById('reset-settings')?.addEventListener('click', () => {
            this.resetSettings();
        });
        
        // Quick command buttons
        document.querySelectorAll('.cmd-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const cmd = btn.dataset.cmd;
                if (cmd) {
                    this.terminalSimulator.executeCommand(cmd);
                }
            });
        });
        
        // Fullscreen button
        document.getElementById('fullscreen-btn')?.addEventListener('click', () => {
            this.toggleFullscreen();
        });
        
        // Copy config button
        document.getElementById('copy-config-btn')?.addEventListener('click', () => {
            this.copyThemeConfig();
        });
    }
    
    /**
     * Load Oh My Posh themes
     */
    async loadThemes() {
        try {
            this.updateStatus('Loading themes...');
            
            // Load theme list - we'll scan for available themes
            const themeFiles = [
                // Custom themes
                { name: 'Atomic Enhanced (Custom)', path: '../OhMyPosh-Atomic-Custom.json' },
                { name: 'Dracula', path: '../OhMyPosh-Dracula.json' },
                
                // Sample official themes
                { name: 'Gruvbox', path: '../ohmyposh-official-themes/themes/gruvbox.omp.json' },
                { name: 'Fish', path: '../ohmyposh-official-themes/themes/fish.omp.json' },
                { name: 'Darkblood', path: '../ohmyposh-official-themes/themes/darkblood.omp.json' },
                { name: 'Blue Owl', path: '../ohmyposh-official-themes/themes/blue-owl.omp.json' },
                { name: 'Cobalt2', path: '../ohmyposh-official-themes/themes/cobalt2.omp.json' },
                { name: 'Paradox', path: '../ohmyposh-official-themes/themes/paradox.omp.json' },
                { name: 'Sorin', path: '../ohmyposh-official-themes/themes/sorin.omp.json' },
                { name: 'Velvet', path: '../ohmyposh-official-themes/themes/velvet.omp.json' }
            ];
            
            this.themes = themeFiles;
            this.renderThemeList();
            
            this.updateStatus('Themes loaded');
        } catch (error) {
            console.error('Error loading themes:', error);
            this.updateStatus('Error loading themes', true);
        }
    }
    
    /**
     * Render theme list
     */
    renderThemeList() {
        const themeList = document.getElementById('theme-list');
        if (!themeList) return;
        
        themeList.innerHTML = '';
        
        this.themes.forEach((theme, index) => {
            const item = document.createElement('div');
            item.className = 'theme-item';
            item.innerHTML = `
                <div class="theme-name">${theme.name}</div>
                <div class="theme-path">${theme.path}</div>
            `;
            
            item.addEventListener('click', () => {
                this.loadTheme(theme);
                
                // Update active state
                document.querySelectorAll('.theme-item').forEach(el => el.classList.remove('active'));
                item.classList.add('active');
            });
            
            themeList.appendChild(item);
        });
    }
    
    /**
     * Filter themes based on search
     */
    filterThemes(query) {
        const filtered = query.trim() === '' ? this.themes : 
            this.themes.filter(theme => 
                theme.name.toLowerCase().includes(query.toLowerCase())
            );
        
        const themeList = document.getElementById('theme-list');
        if (!themeList) return;
        
        themeList.innerHTML = '';
        
        if (filtered.length === 0) {
            themeList.innerHTML = '<div class="loading">No themes found</div>';
            return;
        }
        
        filtered.forEach(theme => {
            const item = document.createElement('div');
            item.className = 'theme-item';
            if (this.currentTheme && this.currentTheme.name === theme.name) {
                item.classList.add('active');
            }
            item.innerHTML = `
                <div class="theme-name">${theme.name}</div>
                <div class="theme-path">${theme.path}</div>
            `;
            
            item.addEventListener('click', () => {
                this.loadTheme(theme);
                document.querySelectorAll('.theme-item').forEach(el => el.classList.remove('active'));
                item.classList.add('active');
            });
            
            themeList.appendChild(item);
        });
    }
    
    /**
     * Load a specific theme
     */
    async loadTheme(theme) {
        try {
            this.updateStatus(`Loading ${theme.name}...`);
            
            const response = await fetch(theme.path);
            if (!response.ok) {
                throw new Error(`Failed to load theme: ${response.statusText}`);
            }
            
            const themeConfig = await response.json();
            
            if (this.themeEngine.loadTheme(themeConfig)) {
                this.currentTheme = theme;
                document.getElementById('current-theme-name').textContent = theme.name;
                
                // Show theme info
                const info = this.themeEngine.getThemeInfo();
                if (info) {
                    document.getElementById('theme-info').textContent = 
                        `v${info.version} | ${info.blocks} blocks | ${info.segments} segments`;
                }
                
                // Refresh terminal with new theme
                this.terminal.clear();
                this.terminalSimulator.initialize();
                
                this.updateStatus(`Theme loaded: ${theme.name}`);
            } else {
                throw new Error('Failed to parse theme configuration');
            }
        } catch (error) {
            console.error('Error loading theme:', error);
            this.updateStatus(`Error: ${error.message}`, true);
        }
    }
    
    /**
     * Update theme context with current settings
     */
    updateThemeContext() {
        this.themeEngine.updateContext({
            UserName: this.settings.username,
            HostName: this.settings.hostname,
            Shell: this.settings.shell
        });
    }
    
    /**
     * Update terminal background
     */
    updateTerminalBackground() {
        const theme = this.terminal.options.theme;
        theme.background = this.settings.backgroundColor;
        this.terminal.options.theme = theme;
        
        // Update opacity
        const terminalElement = document.getElementById('terminal');
        if (terminalElement) {
            terminalElement.style.opacity = this.settings.opacity;
        }
    }
    
    /**
     * Reset settings to defaults
     */
    resetSettings() {
        this.settings = {
            username: 'user',
            hostname: 'localhost',
            shell: 'pwsh',
            fontSize: 14,
            fontFamily: "'Cascadia Code', 'Courier New', monospace",
            backgroundColor: '#1e1e1e',
            opacity: 1
        };
        
        // Update UI
        document.getElementById('username').value = this.settings.username;
        document.getElementById('hostname').value = this.settings.hostname;
        document.getElementById('shell-type').value = this.settings.shell;
        document.getElementById('font-size').value = this.settings.fontSize;
        document.getElementById('font-size-value').textContent = `${this.settings.fontSize}px`;
        document.getElementById('font-family').value = this.settings.fontFamily;
        document.getElementById('bg-color').value = this.settings.backgroundColor;
        document.getElementById('bg-color-text').value = this.settings.backgroundColor;
        document.getElementById('opacity').value = this.settings.opacity;
        document.getElementById('opacity-value').textContent = '100%';
        
        // Apply settings
        this.terminal.options.fontSize = this.settings.fontSize;
        this.terminal.options.fontFamily = this.settings.fontFamily;
        this.updateTerminalBackground();
        this.updateThemeContext();
        this.fitAddon.fit();
        
        this.updateStatus('Settings reset to defaults');
    }
    
    /**
     * Toggle fullscreen mode
     */
    toggleFullscreen() {
        const terminalArea = document.querySelector('.terminal-area');
        if (terminalArea) {
            terminalArea.classList.toggle('fullscreen');
            setTimeout(() => {
                this.fitAddon.fit();
            }, 100);
        }
    }
    
    /**
     * Copy theme configuration to clipboard
     */
    async copyThemeConfig() {
        if (!this.currentTheme) {
            this.updateStatus('No theme selected', true);
            return;
        }
        
        try {
            const response = await fetch(this.currentTheme.path);
            const config = await response.text();
            
            await navigator.clipboard.writeText(config);
            this.updateStatus('Theme configuration copied to clipboard');
        } catch (error) {
            console.error('Error copying config:', error);
            this.updateStatus('Failed to copy configuration', true);
        }
    }
    
    /**
     * Update status bar
     */
    updateStatus(message, isError = false) {
        const statusText = document.getElementById('status-text');
        if (statusText) {
            statusText.textContent = message;
            statusText.style.color = isError ? '#ef4444' : '#a1a1aa';
        }
    }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        new ThemeVisualizerApp();
    });
} else {
    new ThemeVisualizerApp();
}
