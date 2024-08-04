async function connect(event) {
    event.preventDefault();
    let ipElement = document.querySelector('#serveraddress');
    let portElement = document.querySelector('#port');
    
    // Debugging statements
    console.log('IP Element:', ipElement);
    console.log('Port Element:', portElement);
    
    if (ipElement && portElement) {
        let ip = ipElement.value;
        let port = portElement.value;
        
        // Debugging statements
        console.log('IP:', ip);
        console.log('Port:', port);
        
        // Save the IP and port using ipcRenderer
        await window.electron.saveIpPort(ip, port);
        
        try {
            let response = await fetch(`http://${ip}:${port}/`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            
            if (response.status === 200) {
                console.log('Server is available');
                window.location.href = '../serversHeath/serverZHeath.html';
            } else {
                alert('Server is not available');
            }
        } catch (e) {
            alert('Server is not available');
        }
    } else {
        console.error('Could not find IP or Port input elements');
    }
}

// Function to load saved IP and port on page load
async function loadSavedIpPort() {
    const { ip, port } = await window.electron.getIpPort();
    
    let ipElement = document.querySelector('#serveraddress');
    let portElement = document.querySelector('#port');
    
    // Debugging statements
    console.log('IP Element on load:', ipElement);
    console.log('Port Element on load:', portElement);
    
    if (ipElement && portElement) {
        if (ip) {
            ipElement.value = ip;
        }
        if (port) {
            portElement.value = port;
        }
    } else {
        console.error('Could not find IP or Port input elements on load');
    }
}

window.onload = loadSavedIpPort;



// Call the function to create the nav bar

