/**
 * ANSI Parser for Terminal Color Codes
 * Converts ANSI escape sequences to xterm.js compatible format
 */

class AnsiParser {
    constructor() {
        // Standard ANSI color map
        this.colorMap = {
            // Standard colors
            30: '#000000', // Black
            31: '#cd3131', // Red
            32: '#0dbc79', // Green
            33: '#e5e510', // Yellow
            34: '#2472c8', // Blue
            35: '#bc3fbc', // Magenta
            36: '#11a8cd', // Cyan
            37: '#e5e5e5', // White
            
            // Bright colors
            90: '#666666', // Bright Black (Gray)
            91: '#f14c4c', // Bright Red
            92: '#23d18b', // Bright Green
            93: '#f5f543', // Bright Yellow
            94: '#3b8eea', // Bright Blue
            95: '#d670d6', // Bright Magenta
            96: '#29b8db', // Bright Cyan
            97: '#ffffff', // Bright White
            
            // Background colors
            40: '#000000',
            41: '#cd3131',
            42: '#0dbc79',
            43: '#e5e510',
            44: '#2472c8',
            45: '#bc3fbc',
            46: '#11a8cd',
            47: '#e5e5e5',
            
            // Bright background colors
            100: '#666666',
            101: '#f14c4c',
            102: '#23d18b',
            103: '#f5f543',
            104: '#3b8eea',
            105: '#d670d6',
            106: '#29b8db',
            107: '#ffffff'
        };
        
        // 256 color palette
        this.colors256 = this.generate256ColorPalette();
    }
    
    /**
     * Generate 256-color palette
     */
    generate256ColorPalette() {
        const colors = [];
        
        // First 16 colors (standard + bright)
        const base16 = [
            '#000000', '#cd3131', '#0dbc79', '#e5e510', '#2472c8', '#bc3fbc', '#11a8cd', '#e5e5e5',
            '#666666', '#f14c4c', '#23d18b', '#f5f543', '#3b8eea', '#d670d6', '#29b8db', '#ffffff'
        ];
        colors.push(...base16);
        
        // 216 colors (6x6x6 cube)
        for (let r = 0; r < 6; r++) {
            for (let g = 0; g < 6; g++) {
                for (let b = 0; b < 6; b++) {
                    const value = (n) => n === 0 ? 0 : 55 + n * 40;
                    const hex = `#${value(r).toString(16).padStart(2, '0')}${value(g).toString(16).padStart(2, '0')}${value(b).toString(16).padStart(2, '0')}`;
                    colors.push(hex);
                }
            }
        }
        
        // 24 grayscale colors
        for (let i = 0; i < 24; i++) {
            const gray = 8 + i * 10;
            const hex = `#${gray.toString(16).padStart(2, '0')}`.repeat(3);
            colors.push(hex);
        }
        
        return colors;
    }
    
    /**
     * Convert hex color to RGB values
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
     * Convert RGB to hex color
     */
    rgbToHex(r, g, b) {
        return '#' + [r, g, b].map(x => {
            const hex = x.toString(16);
            return hex.length === 1 ? '0' + hex : hex;
        }).join('');
    }
    
    /**
     * Parse ANSI escape codes from text
     */
    parse(text) {
        const segments = [];
        const regex = /\x1b\[([0-9;]+)m/g;
        let lastIndex = 0;
        let currentStyle = {
            foreground: null,
            background: null,
            bold: false,
            italic: false,
            underline: false
        };
        
        let match;
        while ((match = regex.exec(text)) !== null) {
            // Add text before this escape code
            if (match.index > lastIndex) {
                const content = text.substring(lastIndex, match.index);
                if (content) {
                    segments.push({
                        content,
                        style: { ...currentStyle }
                    });
                }
            }
            
            // Parse the escape code
            const codes = match[1].split(';').map(c => parseInt(c));
            this.applyCodes(codes, currentStyle);
            
            lastIndex = match.index + match[0].length;
        }
        
        // Add remaining text
        if (lastIndex < text.length) {
            segments.push({
                content: text.substring(lastIndex),
                style: { ...currentStyle }
            });
        }
        
        return segments;
    }
    
    /**
     * Apply ANSI codes to style object
     */
    applyCodes(codes, style) {
        let i = 0;
        while (i < codes.length) {
            const code = codes[i];
            
            switch (code) {
                case 0: // Reset
                    style.foreground = null;
                    style.background = null;
                    style.bold = false;
                    style.italic = false;
                    style.underline = false;
                    break;
                    
                case 1: // Bold
                    style.bold = true;
                    break;
                    
                case 3: // Italic
                    style.italic = true;
                    break;
                    
                case 4: // Underline
                    style.underline = true;
                    break;
                    
                case 22: // Normal intensity
                    style.bold = false;
                    break;
                    
                case 23: // Not italic
                    style.italic = false;
                    break;
                    
                case 24: // Not underlined
                    style.underline = false;
                    break;
                    
                case 38: // Set foreground color
                    if (codes[i + 1] === 5 && codes[i + 2] !== undefined) {
                        // 256 color
                        style.foreground = this.colors256[codes[i + 2]];
                        i += 2;
                    } else if (codes[i + 1] === 2 && codes[i + 4] !== undefined) {
                        // RGB color
                        style.foreground = this.rgbToHex(codes[i + 2], codes[i + 3], codes[i + 4]);
                        i += 4;
                    }
                    break;
                    
                case 48: // Set background color
                    if (codes[i + 1] === 5 && codes[i + 2] !== undefined) {
                        // 256 color
                        style.background = this.colors256[codes[i + 2]];
                        i += 2;
                    } else if (codes[i + 1] === 2 && codes[i + 4] !== undefined) {
                        // RGB color
                        style.background = this.rgbToHex(codes[i + 2], codes[i + 3], codes[i + 4]);
                        i += 4;
                    }
                    break;
                    
                case 39: // Default foreground
                    style.foreground = null;
                    break;
                    
                case 49: // Default background
                    style.background = null;
                    break;
                    
                default:
                    // Standard foreground colors (30-37, 90-97)
                    if ((code >= 30 && code <= 37) || (code >= 90 && code <= 97)) {
                        style.foreground = this.colorMap[code];
                    }
                    // Standard background colors (40-47, 100-107)
                    else if ((code >= 40 && code <= 47) || (code >= 100 && code <= 107)) {
                        style.background = this.colorMap[code];
                    }
                    break;
            }
            
            i++;
        }
    }
    
    /**
     * Convert parsed segments to styled HTML
     */
    toHtml(segments) {
        return segments.map(segment => {
            let style = '';
            
            if (segment.style.foreground) {
                style += `color: ${segment.style.foreground};`;
            }
            if (segment.style.background) {
                style += `background-color: ${segment.style.background};`;
            }
            if (segment.style.bold) {
                style += 'font-weight: bold;';
            }
            if (segment.style.italic) {
                style += 'font-style: italic;';
            }
            if (segment.style.underline) {
                style += 'text-decoration: underline;';
            }
            
            return style ? `<span style="${style}">${this.escapeHtml(segment.content)}</span>` : this.escapeHtml(segment.content);
        }).join('');
    }
    
    /**
     * Escape HTML special characters
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AnsiParser;
}
