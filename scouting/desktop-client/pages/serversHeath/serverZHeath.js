document.addEventListener("DOMContentLoaded", () => {
  loadSavedIpPort().then(() => {
    fetchAndUpdateDevices();
    fetchAndUpdateData();
    fetchServerInfo();
  });
});

var EventKey;
var Server_ip;
var Server_ip_port;
Data = [];

async function loadSavedIpPort() {
  const { ip, port } = await window.electron.getIpPort();
  Server_ip = ip;
  Server_ip_port = port;
}

function fetchAndUpdateDevices() {
  if (!Server_ip || !Server_ip_port) {
    console.error("IP or Port is missing");
    return;
  }

  fetch(`http://${Server_ip}:${Server_ip_port}/api/devices`)
    .then((response) => response.json())
    .then((data) => {
      const deviceListsContainer = document.getElementById(
        "device-lists-container",
      );
      deviceListsContainer.innerHTML = "";

      data.forEach((device, index) => {
        const deviceList = document.createElement("ul");
        deviceList.className =
          "list-none pl-5 space-y-2 bg-gray-100 p-2 rounded-md";

        const listItem = document.createElement("li");
        listItem.className = "flex justify-between items-center";
        listItem.textContent = `${device[1]} - ${device[2]}`;

        const deleteButton = document.createElement("button");
        deleteButton.textContent = "Delete";
        deleteButton.className =
          "bg-red-500 text-white p-1 rounded-md ml-4 hover:bg-red-600";

        deleteButton.addEventListener("click", () => {
          const deviceId = device[0];
          fetch(
            `http://${Server_ip}:${Server_ip_port}/api/delete_device/${deviceId}`,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
            },
          )
            .then((response) => {
              if (response.status === 200) {
                listItem.remove();
                window.location.reload();
              } else {
                alert("Failed to delete the device");
              }
            })
            .catch((error) => console.error("Error deleting device:", error));
        });

        listItem.appendChild(deleteButton);
        deviceList.appendChild(listItem);
        deviceListsContainer.appendChild(deviceList);
      });
    })
    .catch((error) => console.error("Error fetching device data:", error));
}

function fetchAndUpdateData() {
  if (!Server_ip || !Server_ip_port) {
    console.error("IP or Port is missing");
    return;
  }

  fetch(`http://${Server_ip}:${Server_ip_port}/api/get_data`)
    .then((response) => response.json())
    .then((data) => {
      console.log("Fetched data:", data);

      const dataListsContainer = document.getElementById(
        "data-lists-container",
      );
      dataListsContainer.innerHTML = "";

      data.forEach((item) => {
        let matchData;
        let actualData;

        try {
          let jsonString = item[1]
            .replace(/'/g, '"')
            .replace(/\\"/g, '"')
            .replace(/"""/g, '\\"')
            .replace(/,cm:"$/, ',cm:""}');
        
          // Ensure keys and values are properly quoted
          jsonString = jsonString.replace(/(\w+):/g, '"$1":').replace(/:(\s*)([^,\{\}\[\]\s]+)/g, (match, p1, p2) => {
            if (p2.match(/^(true|false|null|\d+(\.\d+)?|\{|\[|\]|\})$/)) {
              return `:${p1}${p2}`;
            } else {
              return `:${p1}"${p2}"`;
            }
          });
        
          matchData = JSON.parse(jsonString);
        } catch (e) {
          console.error("Error parsing JSON:", e);
          console.error("Problematic JSON string:", item[1]);
          return;
        }
        
        try {
          let jsonString = matchData['data']
            .replace(/'/g, '"')
            .replace(/\\"/g, '"')
            .replace(/"""/g, '\\"')
            .replace(/,cm:"$/, ',cm:""}');
        
          // Ensure keys and values are properly quoted
          jsonString = jsonString.replace(/(\w+):/g, '"$1":').replace(/:(\s*)([^,\{\}\[\]\s]+)/g, (match, p1, p2) => {
            if (p2.match(/^(true|false|null|\d+(\.\d+)?|\{|\[|\]|\})$/)) {
              return `:${p1}${p2}`;
            } else {
              return `:${p1}"${p2}"`;
            }
          });
        
          actualData = JSON.parse(jsonString);
        } catch (e) {
          console.error("Error parsing JSON:", e);
          console.error("Problematic JSON string:", matchData['data']);
          return;
        }
        
        // Create rounded rectangle element
        const roundedRect = document.createElement("div");
        roundedRect.className = "device-rect";
        roundedRect.textContent = matchData['TypesselectedStation'];
        console.log(matchData['data']);
        
        roundedRect.style.borderRadius = "10px";
        roundedRect.style.height = "50px";
        roundedRect.style.width = "70px";
        
        // Set background color based on matchData.TypesallianceColor
        const allianceColor = matchData.TypesallianceColor;
        if (allianceColor === "Red") {
          roundedRect.style.backgroundColor = "red";
        } else if (allianceColor === "Blue") {
          roundedRect.style.backgroundColor = "blue";
        } else {
          roundedRect.style.backgroundColor = "gray"; // Default color
        }
        
        // Add click event to show popup
        roundedRect.addEventListener("click", () => showPopup(name, matchData));
        
        // Append the rounded rectangle to the container
        dataListsContainer.appendChild(roundedRect);
      });
    });

  // Function to show popup with device data
  function showPopup(name, matchData) {
    const popup = document.createElement("div");
    popup.className = "popup";
    popup.innerHTML = `
    <div class="popup-content">
      <h2>${name}</h2>
      <p><strong>Match Data:</strong></p>
      <p>${JSON.stringify(matchData.data, null, 0)}</p>
      <button onclick="closePopup()">Close</button>
    </div>
  `;
    document.body.appendChild(popup);
  }

  // Function to close the popup
}

function fetchServerInfo() {
  if (!Server_ip || !Server_ip_port) {
    console.error("IP or Port is missing");
    return;
  }

  fetch(`http://${Server_ip}:${Server_ip_port}/api/get_health`)
    .then((response) => response.json())
    .then((data) => {
      console.log("Fetched data:", data);
      document.getElementById("server1-ip").textContent = Server_ip;
      document.getElementById("server1-port").textContent = Server_ip_port;
      document.getElementById("server1-status").textContent = data.ServerStatus;
      document.getElementById("server1-battery").textContent =
        data.ServerBattery;
      document.getElementById("server1-cpu").textContent = data.ServerCPUUsage;
      document.getElementById("server1-memory").textContent =
        data.ServerMemoryUsage;
    })
    .catch((error) => console.error("Error fetching server info:", error));
}

function openLogs() {
  window.open(`http://${Server_ip}:${Server_ip_port}/`, "_blank");
}

function uploadEvent() {
  const formdata = new FormData();
  const eventFileInput = document.getElementById("event-file");
  const eventKeyInput = document.getElementById("new-match-file");
  const eventFile = eventFileInput.files[0];
  const eventKey = eventKeyInput.value;

  if (eventFile) {
    formdata.append("Event", eventFile);

    sendFormData(formdata);
  } else if (eventKey) {
    fetch(`https://thebluealliance.com/api/v3/event/${eventKey}/matches`, {
      method: "GET",
      headers: {
        "X-TBA-Auth-Key":
          "2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W",
      },
    })
      .then((response) => response.json())
      .catch((error) => {
        console.error("Error fetching event data:", error);
        showNotification("Failed to fetch event data");
      })
      .then((data) => {
        const eventFileBlob = new Blob([JSON.stringify(data)], {
          type: "application/json",
        });
        formdata.append("Event", eventFileBlob);
        formdata.append("EventKey", eventKey);
        console.log("Event data:", data);
        sendFormData(formdata);
      })
      .catch((error) => {
        console.error("Error fetching event data:", error);
        showNotification("Failed to fetch event data");
      });
  } else {
    console.error("No file uploaded or event key provided");
    showNotification("No file uploaded or event key provided");
  }
}

function sendFormData(formdata) {
  const requestOptions = {
    method: "POST",
    body: formdata,
    redirect: "follow",
  };

  fetch(`http://${Server_ip}:${Server_ip_port}/post_event_file`, requestOptions)
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.text();
    })
    .then((result) => {
      console.log(result);
      showNotification("Event uploaded successfully");
    })
    .catch((error) => {
      console.error("Error:", error);
      showNotification("Failed to upload event");
    });
}

function clearEvent() {
  const requestOptions = {
    method: "POST",
    redirect: "follow",
  };

  fetch(
    `http://${Server_ip}:${Server_ip_port}/clear_event_file`,
    requestOptions,
  )
    .then((response) => response.text())
    .then((result) => {
      console.log(result);
      showNotification("Event cleared successfully");
    })
    .catch((error) => {
      console.error(error);
      showNotification("Failed to clear event");
    });
}

function showNotification(message, color = "green") {
  const notification = document.getElementById("notification");
  notification.textContent = message;
  notification.classList.add("show");
  notification.style.backgroundColor = color;
  setTimeout(() => {
    notification.classList.remove("show");
  }, 201);
}

function deleteAllDevices() {
  fetch(`http://${Server_ip}:${Server_ip_port}/api/clear_devices`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
  })
    .then((response) => {
      if (response.status === 200) {
        showNotification("All devices deleted successfully");
        window.location.reload();
      } else {
        alert("Failed to delete all devices");
      }
    })
    .catch((error) => console.error("Error deleting all devices:", error));
}

function downloadCSV() {
  fetch(`http://${Server_ip}:${Server_ip_port}/api/get_data`)
    .then((response) => response.json())
    .then((data) => {
      console.log("Fetched data:", data);

      const dataListsContainer = document.getElementById(
        "data-lists-container",
      );
      dataListsContainer.innerHTML = "";

      data.forEach((item) => {
        const name = item[0];
        let matchData;

        try {
          let jsonString = item[1]
            .replace(/'/g, '"')
            .replace(/\\"/g, '"')
            .replace(/"""/g, '\\"')
            .replace(/,cm:"$/, ',cm:""}');

          matchData = JSON.parse(jsonString);
          datapoints = matchData.data;
          const output = addQuotesToKeysAndValues(datapoints);
          // console.log(JSON.parse(output));
          Data.push(JSON.parse(output));
        } catch (e) {
          console.error("Error parsing JSON:", e);
          console.error("Problematic JSON string:", item[1]);
        }
      });
      jsonToCSV(Data);
    });
}

function addQuotesToKeysAndValues(input) {
  // Add double quotes around keys
  let quotedString = input.replace(/(\w+):/g, '"$1":');

  // Add double quotes around values if they are not already quoted or boolean/null
  quotedString = quotedString.replace(
    /:(\s*)([^,\{\}\[\]\s]+)/g,
    (match, p1, p2) => {
      if (p2.match(/^(true|false|null|\d+(\.\d+)?|\{|\[|\]|\})$/)) {
        return `:${p1}${p2}`;
      } else {
        return `:${p1}"${p2}"`;
      }
    },
  );

  return quotedString;
}

function jsonToCSV(jsonArray) {
  const csvRows = [];

  // Function to flatten the object
  function flattenObject(ob) {
    let result = {};
    for (const i in ob) {
      if (
        typeof ob[i] === "object" &&
        ob[i] !== null &&
        !Array.isArray(ob[i])
      ) {
        const flatObject = flattenObject(ob[i]);
        for (const x in flatObject) {
          result[i + "_" + x] = flatObject[x];
        }
      } else {
        result[i] = ob[i];
      }
    }
    return result;
  }

  // Flatten the first object to extract headers
  const flattenedFirstObj = flattenObject(jsonArray[0]);
  const headers = Object.keys(flattenedFirstObj);
  csvRows.push(headers.join(",")); // Use comma as a separator

  // Map each JSON object to a CSV row
  jsonArray.forEach((obj) => {
    const flattenedObj = flattenObject(obj);
    const values = headers.map((header) => {
      return JSON.stringify(flattenedObj[header] || ""); // Use empty string if value doesn't exist
    });
    csvRows.push(values.join(","));
  });

  // Join all rows into a single CSV string
  const csvContent = csvRows.join("\n");

  // Create a blob from the CSV string and trigger the download
  const blob = new Blob([csvContent], { type: "text/csv" });
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.style.display = "none";
  a.href = url;
  a.download = "data.csv";
  document.body.appendChild(a);
  a.click();
  window.URL.revokeObjectURL(url);
  Data = [];
}


function checkScouters()
{


  
}
// Make a function call every 5 seconds
setInterval(fetchAndUpdateData, 201);
setInterval(fetchAndUpdateDevices, 201);
setInterval(fetchServerInfo, 201);
