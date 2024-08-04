document.addEventListener("DOMContentLoaded", () => {
    fetchAndUpdateDevices();
    fetchAndUpdateData();
});

var deviceName;
var EventKey;
var AllianceColor;
var MatchKey;
var TeamNumber;
var AutoAmpPlacement;
var AutoSpeaker;
var data_collected;

function fetchAndUpdateDevices() {
    fetch("http://10.0.0.12:5000/api/devices")
        .then(response => response.json())
        .then(data => {
            // console.log("Fetched data:", data); // Debugging statement to inspect the data

            const deviceListsContainer = document.getElementById("device-lists-container");

            // Clear the current device list
            deviceListsContainer.innerHTML = '';

            // Each item in the data array is a device info array
            data.forEach((device, index) => {
                // console.log(`Device ${index}:`, device); // Debugging statement for each device

                const deviceList = document.createElement("ul");
                deviceList.className = "list-none pl-5 space-y-2 bg-gray-100 p-2 rounded-md";

                const listItem = document.createElement("li");
                listItem.className = "flex justify-between items-center";
                listItem.textContent = `${device[1]} - ${device[2]}`;

                // Create delete button
                const deleteButton = document.createElement("button");
                deleteButton.textContent = "Delete";
                deleteButton.className = "bg-red-500 text-white p-1 rounded-md ml-4 hover:bg-red-600";

                // Attach event listener to the delete button
                deleteButton.addEventListener("click", () => {
                    const deviceId = device[0]; // Extract the device ID
                    fetch(`http://10.0.0.12:5000/api/delete_device/${deviceId}`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        }
                    })
                        .then(response => {
                            if (response.status === 200) {
                                // Remove the list item from the DOM
                                listItem.remove();
                                // Reload the browser window
                                window.location.reload();
                            } else {
                                alert('Failed to delete the device');
                            }
                        })
                        .catch(error => console.error("Error deleting device:", error));
                });

                // Append delete button to list item
                listItem.appendChild(deleteButton);
                deviceList.appendChild(listItem);
                deviceListsContainer.appendChild(deviceList);
            });
        })
        .catch(error => console.error("Error fetching device data:", error));
}

function deleteAllDevices() {
    fetch("http://10.0.0.250:5000/api/clear_devices", { method: 'POST' })
        .then(response => {
            if (response.status === 200) {
                window.location.reload();
            } else {
                alert('Failed to clear devices');
            }
        })
        .catch(error => console.error("Error clearing devices:", error));
}

// function fetchAndUpdateData() {
//     fetch("http://10.0.0.12:5000/api/get_data")
//         .then(response => response.json())
//         .then(data => {
//             console.log("Fetched data:", data); // Debugging statement to inspect the data
//             var dataa = jsons.stringify(data[0][1]);
//             console.log(dataa);
//         })
//
//         .catch(error => console.error("Error fetching match data:", error));
// }

function fetchAndUpdateData() {
    fetch("http://10.0.0.12:5000/api/get_data")
        .then(response => response.json())
        .then(data => {
            console.log("Fetched data:", data); // Debugging statement to inspect the data

            const dataListsContainer = document.getElementById("data-lists-container");
            dataListsContainer.innerHTML = '';

            data.forEach((item) => {
                const name = item[0];
                let matchData;

                try {
                    // Replace single quotes with double quotes and fix inner quotes
                    let jsonString = item[1]
                        .replace(/'/g, '"') // Replace single quotes with double quotes
                        .replace(/\\"/g, '"') // Replace escaped double quotes with a single double quote
                        .replace(/"""/g, '\\"') // Fix triple quotes
                        .replace(/,cm:"$/, ',cm:""}'); // Fix the unterminated string


                    // Now parse the JSON string
                    matchData = JSON.parse(jsonString);
                } catch (e) {
                    console.error("Error parsing JSON:", e);
                    console.error("Problematic JSON string:", item[1]); // Log the problematic JSON string
                    return; // Skip this item if JSON parsing fails
                }

                // Create section for each item
                const section = document.createElement("div");
                section.className = "event-details mb-4"; // Added margin for spacing

                // Create heading with the name
                const heading = document.createElement("div");
                heading.className = "heading text-xl font-bold mb-2"; // Styling for heading
                heading.textContent = name;
                section.appendChild(heading);

                // Create event details
                const eventDetails = document.createElement("div");
                eventDetails.className = "event-details";
                eventDetails.innerHTML = `
                    <p><strong>Match Data:</strong></p>
                    <pre>${matchData.data}</pre>
                `; // Display match data in a <pre> tag for better formatting
                section.appendChild(eventDetails);

                // Additional details (if available)
                const additionalDetails = document.createElement("div");
                additionalDetails.className = "additional-details mt-2";
                additionalDetails.innerHTML = `
                    <p><strong>Alliance Color:</strong> ${matchData.alliance_color || 'N/A'}</p>
                    <p><strong>Station:</strong> ${matchData.station || 'N/A'}</p>
                `;
                section.appendChild(additionalDetails);

                // Append the section to the container
                dataListsContainer.appendChild(section);
            });
        })
        .catch(error => console.error("Error fetching match data:", error));
}

function uploadMatch() {
    const myHeaders = new Headers();
    myHeaders.append("X-TBA-Auth-Key", "2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W");
    
    const requestOptions = {
        method: "GET",
        headers: myHeaders,
        redirect: "follow"
    };
    
    fetch("https://www.thebluealliance.com/api/v3/event/2024cmptx/matches", requestOptions)
        .then(response => {
            if (!response.ok) {
                throw new Error(`Failed to fetch data from The Blue Alliance API. Status code: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            const payload = { data: data };
            console.log(payload); // Debugging information
            
            return fetch("http://10.0.0.12:5000/post_match", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(payload)
            });
        })
        .then(response => {
            console.log("Status Code:", response.status);
            return response.json().catch(() => {
                console.log("Failed to decode JSON response.");
                return null;
            });
        })
        .then(result => {
            if (result) {
                console.log(result);
            }
        })
        .catch(error => {
            console.error("Error:", error);
        });
}
function ClearMatch() {
    const requestOptions = {
        method: "POST",
        redirect: "follow"
    };
    
    fetch("http://10.0.0.12:5000/clear_event_data", requestOptions)
        .then((response) => response.text())
        .then((result) => {console.log(result); alert("Match Data Cleared"); window.location.reload()})
        .catch((error) => console.error(error));
}

// setInterval(fetchAndUpdateDevices, 6000);
// setInterval(fetchAndUpdateData, 6000);