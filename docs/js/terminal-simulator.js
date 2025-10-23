/**
 * Terminal Simulator
 * Simulates a terminal with command execution and Oh My Posh prompts
 */

class TerminalSimulator {
    constructor(terminal, themeEngine) {
        this.term = terminal;
        this.themeEngine = themeEngine;
        this.commandHistory = [];
        this.historyIndex = -1;
        this.currentLine = '';
        this.cursorPosition = 0;
        
        // File system simulation
        this.fileSystem = {
            '/home/user': {
                '.config': {},
                'projects': {
                    'my-app': {
                        'package.json': '{"name": "my-app", "version": "1.0.0"}',
                        'src': {
                            'index.js': 'console.log("Hello World");'
                        },
                        '.git': {}
                    },
                    'website': {
                        'index.html': '<html>...</html>',
                        '.git': {}
                    }
                },
                'documents': {},
                'downloads': {}
            }
        };
        
        this.currentPath = '/home/user';
        this.lastExitCode = 0;
        
        // Command definitions
        this.commands = {
            help: this.cmdHelp.bind(this),
            clear: this.cmdClear.bind(this),
            ls: this.cmdLs.bind(this),
            dir: this.cmdLs.bind(this),
            cd: this.cmdCd.bind(this),
            pwd: this.cmdPwd.bind(this),
            echo: this.cmdEcho.bind(this),
            git: this.cmdGit.bind(this),
            npm: this.cmdNpm.bind(this),
            python: this.cmdPython.bind(this),
            node: this.cmdNode.bind(this),
            cat: this.cmdCat.bind(this),
            whoami: this.cmdWhoami.bind(this),
            hostname: this.cmdHostname.bind(this),
            date: this.cmdDate.bind(this),
            uname: this.cmdUname.bind(this)
        };
        
        this.setupInputHandling();
    }
    
    /**
     * Setup input handling for the terminal
     */
    setupInputHandling() {
        this.term.onData(data => {
            this.handleInput(data);
        });
    }
    
    /**
     * Handle terminal input
     */
    handleInput(data) {
        const code = data.charCodeAt(0);
        
        // Enter key
        if (code === 13) {
            this.term.write('\r\n');
            this.executeCommand(this.currentLine.trim());
            this.currentLine = '';
            this.cursorPosition = 0;
            this.historyIndex = -1;
            return;
        }
        
        // Backspace
        if (code === 127 || code === 8) {
            if (this.cursorPosition > 0) {
                this.currentLine = this.currentLine.slice(0, this.cursorPosition - 1) + 
                                  this.currentLine.slice(this.cursorPosition);
                this.cursorPosition--;
                this.term.write('\b \b');
            }
            return;
        }
        
        // Arrow keys
        if (data === '\x1b[A') { // Up
            this.navigateHistory(-1);
            return;
        }
        if (data === '\x1b[B') { // Down
            this.navigateHistory(1);
            return;
        }
        if (data === '\x1b[D') { // Left
            if (this.cursorPosition > 0) {
                this.cursorPosition--;
                this.term.write(data);
            }
            return;
        }
        if (data === '\x1b[C') { // Right
            if (this.cursorPosition < this.currentLine.length) {
                this.cursorPosition++;
                this.term.write(data);
            }
            return;
        }
        
        // Ctrl+C
        if (code === 3) {
            this.term.write('^C\r\n');
            this.currentLine = '';
            this.cursorPosition = 0;
            this.showPrompt();
            return;
        }
        
        // Ctrl+L
        if (code === 12) {
            this.cmdClear();
            return;
        }
        
        // Regular characters
        if (code >= 32 && code <= 126) {
            this.currentLine = this.currentLine.slice(0, this.cursorPosition) + 
                              data + 
                              this.currentLine.slice(this.cursorPosition);
            this.cursorPosition++;
            this.term.write(data);
        }
    }
    
    /**
     * Navigate command history
     */
    navigateHistory(direction) {
        if (this.commandHistory.length === 0) return;
        
        const newIndex = this.historyIndex + direction;
        
        if (newIndex >= -1 && newIndex < this.commandHistory.length) {
            this.historyIndex = newIndex;
            
            // Clear current line
            this.term.write('\r\x1b[K');
            this.showPrompt();
            
            // Show history command
            if (this.historyIndex >= 0) {
                this.currentLine = this.commandHistory[this.commandHistory.length - 1 - this.historyIndex];
                this.term.write(this.currentLine);
                this.cursorPosition = this.currentLine.length;
            } else {
                this.currentLine = '';
                this.cursorPosition = 0;
            }
        }
    }
    
    /**
     * Show prompt
     */
    showPrompt() {
        // Update context
        this.themeEngine.updateContext({
            PWD: this.currentPath,
            Code: this.lastExitCode
        });
        
        // Render and display prompt
        const result = this.themeEngine.renderPrompt();
        this.term.write(result.prompt);
    }
    
    /**
     * Execute a command
     */
    executeCommand(cmdLine) {
        if (!cmdLine) {
            this.showPrompt();
            return;
        }
        
        // Add to history
        this.commandHistory.push(cmdLine);
        
        // Parse command
        const parts = cmdLine.match(/(?:[^\s"]+|"[^"]*")+/g) || [];
        const cmd = parts[0]?.toLowerCase();
        const args = parts.slice(1).map(arg => arg.replace(/^"|"$/g, ''));
        
        // Execute command
        if (this.commands[cmd]) {
            try {
                this.commands[cmd](args);
                this.lastExitCode = 0;
            } catch (error) {
                this.writeError(`Error: ${error.message}`);
                this.lastExitCode = 1;
            }
        } else {
            this.writeError(`Command not found: ${cmd}`);
            this.writeOutput(`Type 'help' for a list of available commands.`);
            this.lastExitCode = 127;
        }
        
        this.showPrompt();
    }
    
    /**
     * Write output to terminal
     */
    writeOutput(text) {
        this.term.write(text + '\r\n');
    }
    
    /**
     * Write error to terminal
     */
    writeError(text) {
        this.term.write(`\x1b[31m${text}\x1b[0m\r\n`);
    }
    
    /**
     * Write colored output
     */
    writeColored(text, color) {
        const colors = {
            red: 31, green: 32, yellow: 33, blue: 34,
            magenta: 35, cyan: 36, white: 37
        };
        const code = colors[color] || 37;
        this.term.write(`\x1b[${code}m${text}\x1b[0m\r\n`);
    }
    
    // Command implementations
    
    cmdHelp(args) {
        this.writeOutput('Available commands:\r\n');
        this.writeColored('  help          ', 'cyan') + this.writeOutput('Show this help message');
        this.writeColored('  clear         ', 'cyan') + this.writeOutput('Clear the terminal');
        this.writeColored('  ls [-la]      ', 'cyan') + this.writeOutput('List directory contents');
        this.writeColored('  cd <path>     ', 'cyan') + this.writeOutput('Change directory');
        this.writeColored('  pwd           ', 'cyan') + this.writeOutput('Print working directory');
        this.writeColored('  cat <file>    ', 'cyan') + this.writeOutput('Display file contents');
        this.writeColored('  echo <text>   ', 'cyan') + this.writeOutput('Echo text to output');
        this.writeColored('  git <command> ', 'cyan') + this.writeOutput('Simulate git commands');
        this.writeColored('  npm <command> ', 'cyan') + this.writeOutput('Simulate npm commands');
        this.writeColored('  python        ', 'cyan') + this.writeOutput('Show Python version');
        this.writeColored('  node          ', 'cyan') + this.writeOutput('Show Node.js version');
        this.writeColored('  whoami        ', 'cyan') + this.writeOutput('Display username');
        this.writeColored('  hostname      ', 'cyan') + this.writeOutput('Display hostname');
        this.writeColored('  date          ', 'cyan') + this.writeOutput('Display current date/time');
        this.writeColored('  uname         ', 'cyan') + this.writeOutput('Display system information');
    }
    
    cmdClear(args) {
        this.term.clear();
    }
    
    cmdLs(args) {
        const showHidden = args.includes('-a') || args.includes('-la');
        const longFormat = args.includes('-l') || args.includes('-la');
        
        const dir = this.getDirectoryContents(this.currentPath);
        
        if (!dir) {
            this.writeError(`Cannot access '${this.currentPath}': No such directory`);
            return;
        }
        
        const entries = Object.keys(dir).filter(name => showHidden || !name.startsWith('.'));
        
        if (longFormat) {
            this.writeOutput(`total ${entries.length}`);
            entries.forEach(name => {
                const isDir = typeof dir[name] === 'object' && !Array.isArray(dir[name]);
                const type = isDir ? 'd' : '-';
                const perms = isDir ? 'rwxr-xr-x' : 'rw-r--r--';
                const size = isDir ? '4096' : '1234';
                const date = new Date().toLocaleDateString('en-US', { month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' });
                
                const color = isDir ? '\x1b[34m' : '\x1b[0m';
                this.writeOutput(`${type}${perms}  1 user user ${size.padStart(8)} ${date} ${color}${name}\x1b[0m`);
            });
        } else {
            entries.forEach(name => {
                const isDir = typeof dir[name] === 'object';
                const color = isDir ? '\x1b[34m' : '\x1b[0m';
                this.term.write(`${color}${name}\x1b[0m  `);
            });
            this.term.write('\r\n');
        }
    }
    
    cmdCd(args) {
        if (args.length === 0 || args[0] === '~') {
            this.currentPath = '/home/user';
            return;
        }
        
        let newPath = args[0];
        
        if (newPath === '..') {
            const parts = this.currentPath.split('/').filter(p => p);
            parts.pop();
            this.currentPath = '/' + parts.join('/');
            if (this.currentPath === '/') this.currentPath = '/home/user';
            return;
        }
        
        if (!newPath.startsWith('/')) {
            newPath = this.currentPath + '/' + newPath;
        }
        
        const dir = this.getDirectoryContents(newPath);
        if (dir && typeof dir === 'object') {
            this.currentPath = newPath;
        } else {
            this.writeError(`cd: ${args[0]}: No such file or directory`);
            throw new Error('Directory not found');
        }
    }
    
    cmdPwd(args) {
        this.writeOutput(this.currentPath);
    }
    
    cmdEcho(args) {
        this.writeOutput(args.join(' '));
    }
    
    cmdGit(args) {
        if (args.length === 0) {
            this.writeOutput("usage: git <command> [<args>]");
            return;
        }
        
        const cmd = args[0].toLowerCase();
        
        switch (cmd) {
            case 'status':
                this.writeColored('On branch main', 'green');
                this.writeOutput("Your branch is up to date with 'origin/main'.\r\n");
                this.writeOutput('nothing to commit, working tree clean');
                break;
                
            case 'log':
                this.writeColored('commit a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0', 'yellow');
                this.writeOutput('Author: User <user@example.com>');
                this.writeOutput('Date:   ' + new Date().toDateString() + '\r\n');
                this.writeOutput('    Initial commit\r\n');
                break;
                
            case 'branch':
                this.writeColored('* main', 'green');
                this.writeOutput('  develop');
                break;
                
            default:
                this.writeOutput(`Simulated: git ${args.join(' ')}`);
        }
    }
    
    cmdNpm(args) {
        if (args.length === 0) {
            this.writeOutput("npm <command>");
            return;
        }
        
        const cmd = args[0].toLowerCase();
        
        switch (cmd) {
            case 'install':
            case 'i':
                this.writeOutput('npm WARN deprecated package@1.0.0');
                this.writeOutput('\r\nadded 234 packages, and audited 235 packages in 3s\r\n');
                this.writeOutput('42 packages are looking for funding');
                this.writeColored('found 0 vulnerabilities', 'green');
                break;
                
            case 'start':
                this.writeOutput('> my-app@1.0.0 start');
                this.writeOutput('> node index.js\r\n');
                this.writeColored('Server running on http://localhost:3000', 'green');
                break;
                
            case 'test':
                this.writeColored('PASS', 'green') + this.writeOutput(' tests/app.test.js');
                this.writeOutput('\r\nTest Suites: 1 passed, 1 total');
                this.writeOutput('Tests:       5 passed, 5 total');
                break;
                
            default:
                this.writeOutput(`Simulated: npm ${args.join(' ')}`);
        }
    }
    
    cmdPython(args) {
        if (args.includes('--version') || args.includes('-V')) {
            this.writeOutput('Python 3.11.4');
        } else {
            this.writeOutput('Python 3.11.4 [GCC 11.4.0] on linux');
            this.writeOutput('Type "help", "copyright", "credits" or "license" for more information.');
        }
    }
    
    cmdNode(args) {
        if (args.includes('--version') || args.includes('-v')) {
            this.writeOutput('v20.9.0');
        } else {
            this.writeOutput('Welcome to Node.js v20.9.0.');
            this.writeOutput('Type ".help" for more information.');
        }
    }
    
    cmdCat(args) {
        if (args.length === 0) {
            this.writeError('cat: missing file operand');
            throw new Error('Missing operand');
        }
        
        const file = this.getDirectoryContents(this.currentPath + '/' + args[0]);
        if (typeof file === 'string') {
            this.writeOutput(file);
        } else {
            this.writeError(`cat: ${args[0]}: No such file or directory`);
            throw new Error('File not found');
        }
    }
    
    cmdWhoami(args) {
        this.writeOutput(this.themeEngine.context.UserName);
    }
    
    cmdHostname(args) {
        this.writeOutput(this.themeEngine.context.HostName);
    }
    
    cmdDate(args) {
        this.writeOutput(new Date().toString());
    }
    
    cmdUname(args) {
        if (args.includes('-a')) {
            this.writeOutput('Linux localhost 5.15.0-1234-generic #1234 SMP x86_64 GNU/Linux');
        } else {
            this.writeOutput('Linux');
        }
    }
    
    /**
     * Get directory contents by path
     */
    getDirectoryContents(path) {
        const parts = path.split('/').filter(p => p);
        let current = this.fileSystem;
        
        for (const part of parts) {
            if (current[part] === undefined) {
                return null;
            }
            current = current[part];
        }
        
        return current;
    }
    
    /**
     * Initialize terminal with welcome message
     */
    initialize() {
        this.term.write('\x1b[1;36m');
        this.term.write('╔════════════════════════════════════════════════════════════════╗\r\n');
        this.term.write('║       Welcome to Oh My Posh Theme Visualizer Terminal         ║\r\n');
        this.term.write('╚════════════════════════════════════════════════════════════════╝\r\n');
        this.term.write('\x1b[0m\r\n');
        this.writeOutput('This is a simulated terminal for previewing Oh My Posh themes.');
        this.writeOutput('Type \'help\' for available commands.\r\n');
        this.showPrompt();
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TerminalSimulator;
}
