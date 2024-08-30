document.addEventListener("DOMContentLoaded", () => {
  loadSavedIpPort().then(() => {
    fetchAndUpdateDevices();
    fetchAndUpdateData();
    fetchServerInfo()
  });
});

var EventKey;
var Server_ip;
var Server_ip_port;

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
        const name = item[0];
        let matchData;

        try {
          let jsonString = item[1]
            .replace(/'/g, '"')
            .replace(/\\"/g, '"')
            .replace(/"""/g, '\\"')
            .replace(/,cm:"$/, ',cm:""}');

          matchData = JSON.parse(jsonString);
        } catch (e) {
          console.error("Error parsing JSON:", e);
          console.error("Problematic JSON string:", item[1]);
          return;
        }

        // Create circle element
        const circle = document.createElement("div");
        circle.className = "device-circle";
        circle.textContent = name;
        circle.addEventListener("click", () => showPopup(name, matchData));

        dataListsContainer.appendChild(circle);
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
            document.getElementById("server1-battery").textContent = data.ServerBattery;
            document.getElementById("server1-cpu").textContent = data.ServerCPUUsage;
            document.getElementById("server1-memory").textContent = data.ServerMemoryUsage;
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

  fetch("http://10.0.0.30:5000/post_event_file", requestOptions)
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
  }, 5000);
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
