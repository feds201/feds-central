# 🚀 Scout Ops Server

The Scout Ops Server is the backbone of communication between the Scout Ops Android app and the Scout Ops Windows app. It utilizes SQL for data processing and storage and uses Python's requests library to communicate with devices. Additionally, it hosts all the necessary apps for download.

## 🔍 General Information

- **Name:** Scout Ops Server
- **Primary Purpose:** To facilitate communication and data exchange between the Scout Ops Android app and Scout Ops Windows app.
- **Intended Users:** Admins and developers working with the Scout Ops ecosystem.
- **Platforms Supported:** Server can be hosted on any platform that supports Python and SQL.

## ✨ Features and Functionality

- **Main Features:**
  - Facilitates communication between Scout Ops Android and Windows apps.
  - Hosts downloadable apps for easy access.
  - Stores and processes data using SQL.

- **Data Collection and Storage:**
  - Utilizes SQL for efficient data storage and processing.

- **Data Synchronization:**
  - Uses Python's requests library for communication with connected devices.

- **App Hosting:**
  - Provides endpoints to download necessary applications:
    - `/getApp` for downloading the Android app.
    - `/getDashboard` for downloading the Windows client.

## 🛠️ Technical Details

- **Technologies and Frameworks Used:**
  - Built with Python.
  - SQL for data storage.
  - Python's requests library for device communication.

- **Main Components:**
  - Python
  - SQL
  - Requests library

## 🚀 Setup and Usage

### 📋 Prerequisites

- Ensure you have Python and SQL installed on your server.

### 📥 Installation and Configuration

1. Clone the Scout Ops Server repository to your server.
2. Install the necessary Python packages using `pip install -r requirements.txt`.
3. Configure your SQL database connection in the server settings.
4. Start the server using `python server.py`.

### 🌐 Endpoints

- **Download Android App:**
  - `GET /getApp` - Downloads the Scout Ops Android app.
  
- **Download Windows Client:**
  - `GET /getDashboard` - Downloads the Scout Ops Windows client.

### 🚀 Starting the Server

- Run `python server.py server` to start the Scout Ops Server.
- Use `--headless` mode if running on a system without `curses` support.

### 🛠️ Maintenance and Support

### 🐛 Known Issues and Limitations

- Ensure the server is properly secured and configured for your environment.

### 📬 Reporting Bugs and Requesting Features

- Report bugs and request new features by raising an issue on GitHub.

### 🔮 Future Plans

- Implement additional security measures.
- Add more endpoints for enhanced functionality.

---

**Scout Ops Server** – Empowering FRC teams with seamless data management and communication.
