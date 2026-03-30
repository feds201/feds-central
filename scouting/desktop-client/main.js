const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

let Store;

async function createWindow () {
    const win = new BrowserWindow({
        width: 800,
        height: 600,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'), // Use preload.js for context isolation
            nodeIntegration: false,
            contextIsolation: true
        }
    });
    
    await import('electron-store').then((module) => {
        Store = module.default;
    });
    
    const store = new Store();
    
    win.loadFile('./pages/index/index.html');
    
    // IPC handlers to save and get data
    ipcMain.handle('save-ip-port', (event, ip, port) => {
        store.set('server.ip', ip);
        store.set('server.port', port);
    });
    
    ipcMain.handle('get-ip-port', (event) => {
        return {
            ip: store.get('server.ip'),
            port: store.get('server.port')
        };
    });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});
