// preload.js
const { contextBridge, ipcRenderer } = require('electron');
// All the Node.js APIs are available in the preload process.
// It has the same sandbox as a Chrome extension.
window.addEventListener('DOMContentLoaded', () => {
    const replaceText = (selector, text) => {
        const element = document.getElementById(selector)
        if (element) element.innerText = text
    }
    
    for (const dependency of ['chrome', 'node', 'electron']) {
        replaceText(`${dependency}-version`, process.versions[dependency])
    }
})

contextBridge.exposeInMainWorld('electron', {
    saveIpPort: (ip, port) => ipcRenderer.invoke('save-ip-port', ip, port),
    getIpPort: () => ipcRenderer.invoke('get-ip-port')
});