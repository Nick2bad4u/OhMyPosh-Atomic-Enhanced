/**
 * Oh My Posh Theme Engine
 * Parses and renders Oh My Posh theme configurations
 */

class ThemeEngine {
    constructor() {
        this.theme = null;
        this.ansiParser = new AnsiParser();
        
        // Icon mappings for various segments
        this.icons = {
            shell: '🐚',
            path: '📁',
            git: '🌿',
            time: '🕒',
            user: '👤',
            root: '⚡',
            os: '💻',
            battery: '🔋',
            python: '🐍',
            node: '⬢',
            go: '🐹',
            rust: '🦀',
            java: '☕',
            dotnet: '●',
            success: '✓',
            error: '✗',
            folder: '',
            home: '~',
            arrow: '',
            powerline: ''
        };
        
        // Default context for template rendering
        this.context = {
            UserName: 'user',
            HostName: 'localhost',
            Shell: 'pwsh',
            PWD: '/home/user',
            HOME: '/home/user',
            OS: 'linux',
            WSL: false,
            Root: false,
            Code: 0
        };
    }
    
    /**
     * Load and parse a theme
     */
    loadTheme(themeConfig) {
        try {
            this.theme = typeof themeConfig === 'string' ? JSON.parse(themeConfig) : themeConfig;
            return true;
        } catch (error) {
            console.error('Failed to load theme:', error);
            return false;
        }
    }
    
    /**
     * Update rendering context
     */
    updateContext(updates) {
        this.context = { ...this.context, ...updates };
    }
    
    /**
     * Render the theme prompt
     */
    renderPrompt() {
        if (!this.theme || !this.theme.blocks) {
            return { prompt: '$ ', parts: [] };
        }
        
        const parts = [];
        let promptText = '';
        
        // Process each block
        for (const block of this.theme.blocks) {
            if (block.type === 'prompt') {
                const blockResult = this.renderBlock(block);
                parts.push(...blockResult.parts);
                promptText += blockResult.text;
                
                // Add newline if block has newline alignment
                if (block.newline || block.alignment === 'newline') {
                    promptText += '\n';
                }
            }
        }
        
        return { prompt: promptText, parts };
    }
    
    /**
     * Render a block
     */
    renderBlock(block) {
        const parts = [];
        let text = '';
        
        if (!block.segments) {
            return { text, parts };
        }
        
        // Process each segment
        for (let i = 0; i < block.segments.length; i++) {
            const segment = block.segments[i];
            const segmentResult = this.renderSegment(segment, block);
            
            if (segmentResult.text) {
                parts.push({
                    type: segment.type,
                    text: segmentResult.text,
                    style: segmentResult.style
                });
                text += segmentResult.text;
            }
        }
        
        return { text, parts };
    }
    
    /**
     * Render a segment
     */
    renderSegment(segment, block) {
        let text = '';
        const style = {
            foreground: this.resolveColor(segment.foreground),
            background: this.resolveColor(segment.background)
        };
        
        // Get segment content based on type
        const content = this.getSegmentContent(segment);
        
        if (!content) {
            return { text: '', style };
        }
        
        // Apply leading diamond
        if (segment.leading_diamond) {
            text += this.colorize(segment.leading_diamond, style.foreground, style.background);
        }
        
        // Apply powerline symbol from previous segment
        if (segment.powerline_symbol && block.alignment !== 'right') {
            text += this.colorize(segment.powerline_symbol || '', style.foreground, style.background);
        }
        
        // Apply the content
        text += this.colorize(content, style.foreground, style.background);
        
        // Apply trailing diamond
        if (segment.trailing_diamond) {
            text += this.colorize(segment.trailing_diamond, style.foreground, style.background);
        }
        
        return { text, style };
    }
    
    /**
     * Get content for a segment based on its type
     */
    getSegmentContent(segment) {
        const template = segment.template || this.getDefaultTemplate(segment.type);
        
        switch (segment.type) {
            case 'shell':
                return this.renderTemplate(template, {
                    Name: this.context.Shell.toUpperCase(),
                    Version: '7.4.0'
                });
                
            case 'path':
                const path = this.context.PWD;
                const displayPath = path.replace(this.context.HOME, '~');
                return this.renderTemplate(template, {
                    Path: displayPath,
                    PWD: path
                });
                
            case 'git':
                // Simulate git info
                return this.renderTemplate(template, {
                    HEAD: 'main',
                    Branch: 'main',
                    Working: { Changed: false },
                    Staging: { Changed: false }
                });
                
            case 'time':
                const now = new Date();
                return this.renderTemplate(template, {
                    currentDate: now.toLocaleDateString(),
                    currentTime: now.toLocaleTimeString()
                });
                
            case 'session':
            case 'user':
                return this.renderTemplate(template, {
                    UserName: this.context.UserName,
                    HostName: this.context.HostName
                });
                
            case 'root':
                return this.context.Root ? this.renderTemplate(template, {}) : '';
                
            case 'status':
            case 'exit':
                return this.renderTemplate(template, {
                    Code: this.context.Code,
                    Error: this.context.Code !== 0
                });
                
            case 'text':
                return this.renderTemplate(template, {});
                
            case 'os':
                return this.renderTemplate(template, {
                    Icon: this.icons.os,
                    WSL: this.context.WSL
                });
                
            default:
                // For unknown segment types, return template or empty
                return this.renderTemplate(template, {});
        }
    }
    
    /**
     * Get default template for segment type
     */
    getDefaultTemplate(type) {
        const templates = {
            shell: ' {{ .Name }} ',
            path: ' {{ .Path }} ',
            git: ' {{ .HEAD }} ',
            time: ' {{ .currentTime }} ',
            session: ' {{ .UserName }}@{{ .HostName }} ',
            user: ' {{ .UserName }} ',
            root: ' ⚡ ',
            status: ' {{ if .Error }}✗{{ else }}✓{{ end }} ',
            text: ' ',
            os: ' {{ .Icon }} '
        };
        
        return templates[type] || ' ';
    }
    
    /**
     * Simple template renderer (supports basic Go template syntax)
     */
    renderTemplate(template, data) {
        if (!template) return '';
        
        let result = template;
        
        // Handle {{ .Variable }} syntax
        result = result.replace(/\{\{\s*\.(\w+)\s*\}\}/g, (match, key) => {
            return data[key] !== undefined ? data[key] : '';
        });
        
        // Handle {{ if .Variable }}...{{ end }} syntax
        result = result.replace(/\{\{\s*if\s+\.(\w+)\s*\}\}(.*?)\{\{\s*end\s*\}\}/g, (match, key, content) => {
            return data[key] ? content : '';
        });
        
        // Handle {{ if .Variable }}...{{ else }}...{{ end }} syntax
        result = result.replace(/\{\{\s*if\s+\.(\w+)\s*\}\}(.*?)\{\{\s*else\s*\}\}(.*?)\{\{\s*end\s*\}\}/g, 
            (match, key, trueContent, falseContent) => {
                return data[key] ? trueContent : falseContent;
            }
        );
        
        // Handle nested properties like .Working.Changed
        result = result.replace(/\{\{\s*\.(\w+)\.(\w+)\s*\}\}/g, (match, obj, key) => {
            return data[obj] && data[obj][key] !== undefined ? data[obj][key] : '';
        });
        
        return result.trim();
    }
    
    /**
     * Resolve color value (handles palette references)
     */
    resolveColor(color) {
        if (!color) return null;
        
        // Handle palette references (p:color_name)
        if (typeof color === 'string' && color.startsWith('p:')) {
            const paletteKey = color.substring(2);
            if (this.theme.palette && this.theme.palette[paletteKey]) {
                return this.theme.palette[paletteKey];
            }
            // Fallback to default colors
            return null;
        }
        
        return color;
    }
    
    /**
     * Colorize text with ANSI codes
     */
    colorize(text, foreground, background) {
        if (!text) return '';
        
        let result = '';
        
        if (background) {
            result += this.getAnsiColor(background, true);
        }
        if (foreground) {
            result += this.getAnsiColor(foreground, false);
        }
        
        result += text;
        
        if (foreground || background) {
            result += '\x1b[0m'; // Reset
        }
        
        return result;
    }
    
    /**
     * Convert hex color to ANSI escape code
     */
    getAnsiColor(color, isBackground) {
        if (!color || !color.startsWith('#')) return '';
        
        // Convert hex to RGB
        const rgb = this.hexToRgb(color);
        if (!rgb) return '';
        
        // Use 24-bit RGB ANSI codes
        const prefix = isBackground ? 48 : 38;
        return `\x1b[${prefix};2;${rgb.r};${rgb.g};${rgb.b}m`;
    }
    
    /**
     * Convert hex to RGB
     */
    hexToRgb(hex) {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null;
    }
    
    /**
     * Get theme metadata
     */
    getThemeInfo() {
        if (!this.theme) return null;
        
        return {
            version: this.theme.version || 'unknown',
            blocks: this.theme.blocks ? this.theme.blocks.length : 0,
            segments: this.theme.blocks ? 
                this.theme.blocks.reduce((sum, block) => 
                    sum + (block.segments ? block.segments.length : 0), 0) : 0,
            hasPalette: !!this.theme.palette
        };
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ThemeEngine;
}
