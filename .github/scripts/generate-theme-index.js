#!/usr/bin/env node

/**
 * Generate theme index for the Oh My Posh Theme Visualizer
 * This script scans for all .json theme files and creates an index
 */

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.join(__dirname, '../..');
const OUTPUT_FILE = path.join(REPO_ROOT, 'docs/themes/index.json');
const THEME_DIRS = [
    { dir: '.', category: 'custom', pattern: /^OhMyPosh-.+\.json$/ },
    { dir: 'ohmyposh-official-themes/themes', category: 'official', pattern: /\.omp\.json$/ }
];

function scanThemes() {
    const themes = [];
    
    for (const { dir, category, pattern } of THEME_DIRS) {
        const fullPath = path.join(REPO_ROOT, dir);
        
        if (!fs.existsSync(fullPath)) {
            console.warn(`Directory not found: ${fullPath}`);
            continue;
        }
        
        const files = fs.readdirSync(fullPath);
        
        for (const file of files) {
            if (pattern.test(file)) {
                const filePath = path.join(fullPath, file);
                const stats = fs.statSync(filePath);
                
                if (stats.isFile()) {
                    // Extract theme name from filename
                    let name = file
                        .replace(/^OhMyPosh-/, '')
                        .replace(/\.omp\.json$/, '')
                        .replace(/\.json$/, '')
                        .replace(/-/g, ' ')
                        .replace(/\b\w/g, l => l.toUpperCase());
                    
                    // Determine relative path from docs directory
                    const relativePath = path.relative(path.join(REPO_ROOT, 'docs'), filePath)
                        .replace(/\\/g, '/');
                    
                    themes.push({
                        name,
                        path: relativePath.startsWith('../') ? relativePath : '../' + relativePath,
                        category,
                        featured: category === 'custom' && file.includes('Atomic')
                    });
                }
            }
        }
    }
    
    return themes;
}

function generateIndex() {
    console.log('Scanning for Oh My Posh themes...');
    
    const themes = scanThemes();
    
    console.log(`Found ${themes.length} themes`);
    
    // Sort themes: featured first, then by category, then alphabetically
    themes.sort((a, b) => {
        if (a.featured !== b.featured) return b.featured ? 1 : -1;
        if (a.category !== b.category) return a.category.localeCompare(b.category);
        return a.name.localeCompare(b.name);
    });
    
    const index = {
        generated: new Date().toISOString(),
        count: themes.length,
        themes
    };
    
    // Ensure output directory exists
    const outputDir = path.dirname(OUTPUT_FILE);
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }
    
    // Write index file
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(index, null, 2));
    
    console.log(`Theme index written to: ${OUTPUT_FILE}`);
    console.log(`\nCategories:`);
    const categories = {};
    themes.forEach(t => {
        categories[t.category] = (categories[t.category] || 0) + 1;
    });
    Object.entries(categories).forEach(([cat, count]) => {
        console.log(`  ${cat}: ${count} themes`);
    });
}

// Run the generator
try {
    generateIndex();
} catch (error) {
    console.error('Error generating theme index:', error);
    process.exit(1);
}
