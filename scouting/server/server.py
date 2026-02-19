import threading
import curses
import logging
import os
import shutil
import signal
import socket
import sqlite3
import sys
import time
import warnings
from datetime import datetime
from gevent.pywsgi import WSGIServer
from flask import Flask, request, jsonify, send_file, render_template
import json
import psutil

app = Flask(__name__)


# Function to take input and save it
def process_json_input():
    count = 1
    while True:
        # Input for a JSON object
        input_data = input(f"Enter JSON object {count} (or type 'exit' to stop): ")

        if input_data.lower() == 'exit':
            print("Exiting...")
            break

        try:
            # Parse the input string into a Python dictionary
            json_data = json.loads(input_data)

            # Define the output file name
            output_filename = f"output_{count}.json"

            # Write the JSON data to a file
            with open(output_filename, "w") as f:
                json.dump(json_data, f, indent=4)

            print(f"Processed and saved JSON object {count} as {output_filename}")
            count += 1
        except json.JSONDecodeError as e:
            print(f"Error processing JSON input: {e}. Please check the format.")

# Create output directory if not exists
if not os.path.exists("output_jsons"):
    os.makedirs("output_jsons")

# Change to the directory where outputs will be saved
os.chdir("output_jsons")


def log_message(message):
    with open('log.txt', 'a') as file:
        file.write(f"{datetime.now()}: {message}\n")
        file.close()


def get_server_info():
    # Get server IP address
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        server_ip = s.getsockname()[0]
        s.close()
    except Exception as e:
        server_ip = "Unable to get IP Address"

    # Get server status
    server_status = "Running"  # Example, replace with actual status if available

    # Get server health
    battery = psutil.sensors_battery()
    plugged = battery.power_plugged
    percent = str(battery.percent)
    plugged = "Plugged In" if plugged else "Not Plugged In"
    server_battery = percent + '% | ' + plugged
    # Get server CPU usage
    server_cpu_usage = psutil.cpu_percent(interval=1)

    # Get server memory usage
    memory_info = psutil.virtual_memory()
    server_memory_usage = memory_info.percent

    # Get server storage usage
    storage_info = psutil.disk_usage('/')
    server_storage_usage = storage_info.percent

    # Create a dictionary with all the information
    server_info = {
        "ServerIP": server_ip,
        "ServerStatus": server_status,
        "ServerBattery": server_battery,
        "ServerCPUUsage": server_cpu_usage,
        "ServerMemoryUsage": server_memory_usage,
        "ServerStorageUsage": server_storage_usage
    }

    # Return the information as a JSON string
    return json.dumps(server_info, indent=4)


# Initialize SQLite database
def init_db():
    clear_log_file()

    Devicesconn = sqlite3.connect('devices.db')
    Devicescursor = Devicesconn.cursor()
    Devicescursor.execute('''
        CREATE TABLE IF NOT EXISTS devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_name TEXT NOT NULL,
            ip_address TEXT NOT NULL
        )
    ''')
    Devicescursor.execute('''
        CREATE TABLE IF NOT EXISTS device_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id INTEGER,
            data TEXT,
            FOREIGN KEY(device_id) REFERENCES devices(id)
        )
    ''')
    Devicesconn.commit()
    Devicesconn.close()
    log_message("Device database initialized")

    Matchconn = sqlite3.connect('match.db')
    Matchcursor = Matchconn.cursor()
    Matchcursor.execute('''
        CREATE TABLE IF NOT EXISTS event (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            match_id TEXT NOT NULL,
            match_data TEXT NOT NULL
        )
    ''')
    Matchconn.commit()
    Matchconn.close()
    log_message("Match database initialized")


# Signal handler to stop the server
def create_log_folder():
    log_dir = 'log'
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    backup_dir = os.path.join(log_dir, timestamp)
    os.makedirs(backup_dir)

    shutil.move('devices.db', os.path.join(backup_dir, 'devices.db'))
    shutil.move('match.db', os.path.join(backup_dir, 'match.db'))
    shutil.move('log.txt', os.path.join(backup_dir, 'log.txt'))
    print(f"Moved databases to {backup_dir}")


def signal_handler(sig, frame):
    log_message("")
    log_message("Gracefully stopping the server...")
    log_message("\nServer stopped.")
    create_log_folder()
    curses.endwin()  # Restore terminal to original state
    sys.exit(0)


# Function to run the Flask app in a separate thread
def run_flask_app():
    http_server = WSGIServer(('0.0.0.0', 201), app)
    http_server.serve_forever()


def read_log_file():
    with open('log.txt', 'r') as file:
        return file.readlines()


def clear_log_file():
    with open('log.txt', 'w') as file:
        file.write('')
        file.close()


# Curses-based interface
def curses_interface(stdscr):
    signal.signal(signal.SIGINT, signal_handler)  # Handle Ctrl+C

    curses.curs_set(0)  # Hide cursor
    stdscr.nodelay(1)  # Non-blocking input
    height, width = stdscr.getmaxyx()

    # Initialize color
    curses.start_color()
    curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)

    info = json.loads(get_server_info())  # Convert JSON string to dictionary

    # Display the logo at the top
    logo = r"""
           _____                  __              ____                _____
          / ___/_________  __  __/ /_            / __ \____  _____   / ___/___  ______   _____  _____
          \__ \/ ___/ __ \/ / / / __/  ______   / / / / __ \/ ___/   \__ \/ _ \/ ___/ | / / _ \/ ___/
         ___/ / /__/ /_/ / /_/ / /_   /_____/  / /_/ / /_/ (__  )   ___/ /  __/ /   | |/ /  __/ /
        /____/\___/\____/\__,_/\__/            \____/ .___/____/   /____/\___/_/    |___/\___/_/
                                                   /_/
"""
    logo_lines = logo.split('\n')
    start_x = (width - max(len(line) for line in logo_lines)) // 2

    for i, line in enumerate(logo_lines):
        stdscr.addstr(i, start_x, line, curses.color_pair(1) | curses.A_BOLD)
    stdscr.refresh()

    # Initialize the database
    init_db()
    log_message("")
    log_message("----------------------------------------------------")
    log_message("Server Ip Address: http://" + info['ServerIP'] + ":201")
    log_message("Server Battery: " + info['ServerBattery'])
    log_message("Server CPU Usage: " + str(info['ServerCPUUsage']) + "%")
    log_message("Server Memory Usage: " + str(info['ServerMemoryUsage']) + "%")
    log_message("Server Storage Usage: " + str(info['ServerStorageUsage']) + "%")
    log_message("Server Status: Running")
    log_message("----------------------------------------------------")
    log_message("")
    # Loop to update the status and keep the UI responsive
    while True:
        details_box = curses.newwin(7, 37, 0 + 1, 3)
        details_box.box()

        # Displaying server details inside the box
        details_box.addstr(1, 1, f"Server IP: {info['ServerIP']}:201", curses.A_BOLD)
        details_box.addstr(2, 1, f"Server Port: 201", curses.A_BOLD)
        details_box.addstr(3, 1, f"Server Status: Running", curses.A_BOLD)
        details_box.addstr(4, 1, f"Battery: {info['ServerBattery']}",
                           curses.A_BOLD)  # Example, replace with actual data
        details_box.addstr(5, 1, "Performance: Normal", curses.A_BOLD)  # Example, replace with actual data
        details_box.refresh()

        log_contents = read_log_file()
        log_box = curses.newwin(height - 10, width - 10, 10, 5)
        log_box.box()
        for idx, line in enumerate(log_contents):
            if idx < height - 12:
                log_box.addstr(idx + 1, 1, line.strip(), curses.A_BOLD)
        log_box.refresh()
        # Warning message at the bottom
        exit_box = curses.newwin(3, 50, height - 3, width // 2 - 23)
        exit_box.box()
        exit_box.addstr(1, 10, "Press Ctrl+C to stop the server", curses.A_BOLD)
        exit_box.refresh()
        stdscr.refresh()
        time.sleep(1)


# Flask routes
@app.route('/')
def index():
    return render_template('index.html')


# HTML and JSON endpoints for devices
@app.route('/devices', methods=['GET'])
def get_devices():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('SELECT id, device_name, ip_address FROM devices')
    devices = cursor.fetchall()
    conn.close()
    log_message(f"Devices fetched: {devices}")
    return render_template('devices.html', devices=devices)


@app.route('/api/devices', methods=['GET'])
def get_devices_json():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('SELECT id, device_name, ip_address FROM devices')
    devices = cursor.fetchall()
    conn.close()
    log_message(f"Devices fetched: {devices}")
    return jsonify(devices)


# HTML and JSON endpoints for data
@app.route('/get_data', methods=['GET'])
def get_data_all():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('''
        SELECT d.device_name, dd.data
        FROM device_data dd
        JOIN devices d ON dd.device_id = d.id
    ''')
    data = cursor.fetchall()
    conn.close()
    log_message(f"Data fetched")
    return render_template('data.html', data=data)


@app.route('/api/get_data', methods=['GET'])
def get_data_all_json():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('''
        SELECT d.device_name, dd.data
        FROM device_data dd
        JOIN devices d ON dd.device_id = d.id
    ''')
    data = cursor.fetchall()
    conn.close()
    log_message(f"Data fetched")
    return jsonify(data)


# HTML and JSON endpoints for device-specific data
@app.route('/get_data/<device_id>', methods=['GET'])
def get_data(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('''
        SELECT d.device_name, dd.data
        FROM device_data dd
        JOIN devices d ON dd.device_id = d.id
        WHERE d.id = ?
    ''', (device_id,))
    data = cursor.fetchall()
    conn.close()
    log_message(f"Data fetched for device {device_id}")
    return render_template('data.html', data=data)


@app.route('/api/get_data/<device_id>', methods=['GET'])
def get_data_json(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('''
        SELECT d.device_name, dd.data
        FROM device_data dd
        JOIN devices d ON dd.device_id = d.id
        WHERE d.id = ?
    ''', (device_id,))
    data = cursor.fetchall()
    conn.close()
    log_message(f"Data fetched for device {device_id}")
    return jsonify(data)


@app.route('/send_data', methods=['POST'])
def send_data():
    data = request.json
    device_ip = request.remote_addr
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('SELECT id FROM devices WHERE ip_address = ?', (device_ip,))
    device = cursor.fetchone()
    if device:
        device_id = device[0]
        cursor.execute('INSERT INTO device_data (device_id, data) VALUES (?, ?)', (device_id, json.dumps(data)))
        conn.commit()
        log_message(f"Data inserted for device {device_id}")
    else:
        log_message(f"No device found with IP: {device_ip}")
    conn.close()
    return jsonify({"status": "success"})


@app.route('/register', methods=['POST'])
def register():
    data = request.json
    device_name = data['device_name']
    device_ip = request.remote_addr
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('SELECT id FROM devices WHERE ip_address = ?', (device_ip,))
    device = cursor.fetchone()
    if device:
        cursor.execute('UPDATE devices SET device_name = ? WHERE ip_address = ?', (device_name, device_ip))
        conn.commit()
        conn.close()
        message = f"Device with IP: {device_ip} already registered. Refreshed with new name: {device_name}"
        log_message(message)
        return jsonify({"status": "success", "message": message})
    else:
        cursor.execute('INSERT INTO devices (device_name, ip_address) VALUES (?, ?)', (device_name, device_ip))
        conn.commit()
        conn.close()
        log_message(f"Registered device: {device_name} with IP: {device_ip}")
        return jsonify({"status": "success"})


@app.route('/client_images/getAndroid', methods=['POST'])
def getAndroid():
    file_path = os.path.join(os.getcwd(), 'App', 'app-release.apk')
    return send_file(file_path, as_attachment=True)


@app.route('/client_images/getServer', methods=['GET'])
def getServer():
    file_path = os.path.join(os.getcwd(), 'App', 'server.exe')
    return send_file(file_path, as_attachment=True)


@app.route('/client_images/getWindows', methods=['GET'])
def getWindows():
    return send_file('./App/app-release.apk', as_attachment=True)


@app.route('/client_images', methods=['GET'])
def client_images():
    return render_template('client_images.html')


@app.route('/clear_data', methods=['GET'])
def clear_data():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM device_data')
    conn.commit()
    conn.close()
    log_message("Data cleared")
    return render_template('clear_data.html', status="success")


@app.route('/api/clear_data', methods=['POST'])
def clear_data_json():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM device_data')
    conn.commit()
    conn.close()
    log_message("Data cleared")
    return jsonify({"status": "success"})


@app.route('/clear_devices', methods=['GET'])
def clear_devices():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices')
    conn.commit()
    conn.close()
    log_message("Devices cleared")
    return render_template('clear_devices.html', status="success")


@app.route('/api/clear_devices', methods=['POST'])
def clear_devices_json():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices')
    conn.commit()
    conn.close()
    log_message("Devices cleared")
    return jsonify({"status": "success"})


# get the ip adres of the client

@app.route('/send_pit_data', methods=['POST'])
def send_pit_data():
    data = request.get_json(silent=True)
    if data is None:
        return jsonify({"status": "error", "message": "Invalid JSON format"}), 400

    try:
        log_message(f"Pit data received: {data}")
        with open('pit_data.json', 'w') as file:
            json.dump(data, file, indent=4)
        print("")
        return jsonify({"status": "success"})
    except Exception as e:
        log_message(f"Error saving pit data: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
    
    


@app.route('/alive', methods=['GET'])
def alive():
    log_message("Server Communication Tested")
    return jsonify({"status": "alive"})


@app.route('/delete_device/<device_id>', methods=['POST'])
def delete_device(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices WHERE id = ?', (device_id,))
    conn.commit()
    conn.close()
    log_message(f"Device {device_id} deleted")
    return render_template('delete_device.html', status="success", device_id=device_id)


@app.route('/api/delete_device/<device_id>', methods=['POST'])
def delete_device_json(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices WHERE id = ?', (device_id,))
    conn.commit()
    conn.close()
    log_message(f"Device {device_id} deleted")
    return jsonify({"status": "success"})


@app.route('/clear_data/<device_id>', methods=['POST'])
def clear_data_for_device(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM device_data WHERE device_id = ?', (device_id,))
    conn.commit()
    conn.close()
    log_message(f"Data for device {device_id} cleared")
    return jsonify({"status": "success"})


@app.route('/get_event_file', methods=['GET'])
def get_event_file():
    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()
    cursor.execute('SELECT match_data FROM event')
    data = cursor.fetchall()
    data = [json.loads(row[0]) for row in data]
    conn.close()
    log_message(f"Event data fetched")
    return jsonify(data)



@app.route('/post_event_file', methods=['POST'])
def post_match():
    if 'Event' not in request.files:
        return jsonify({"status": "error", "message": "No file provided"}), 400

    file = request.files['Event']
    try:
        data = json.load(file)
    except json.JSONDecodeError:
        return jsonify({"status": "error", "message": "Invalid JSON format"}), 400

    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()

    try:
        insert_data = ((match.get('key'), json.dumps(match)) for match in data)
        cursor.executemany('INSERT INTO event (match_id, match_data) VALUES (?, ?)', insert_data)

        conn.commit()
        conn.close()
        log_message(f"{len(data)} matches posted")
        return jsonify({"status": "success", "message": f"{len(data)} matches posted"}), 200
    except Exception as e:
        conn.close()
        return jsonify({"status": "error", "message": str(e)}), 500



@app.route('/clear_event_file', methods=['POST'])
def clear_event_data():
    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM event')
    conn.commit()
    conn.close()
    log_message("Event data cleared")
    return jsonify({"status": "success"})


@app.route('/api/get_health', methods=['GET'])
def get_health():
    server_info = json.loads(get_server_info())
    return jsonify(server_info)


# Main function
def main():
    mode = input("Enter mode (server/interpreter): ").strip().lower()

    if mode == "server":
        # Suppress specific warnings
        warnings.filterwarnings("ignore", category=UserWarning, message='.*server.*')
        log = logging.getLogger('werkzeug')
        log.setLevel(logging.ERROR)

        # Start the Flask app in a separate thread
        flask_thread = threading.Thread(target=run_flask_app)
        flask_thread.daemon = True
        flask_thread.start()

        # Start the curses interface
        curses.wrapper(curses_interface)
    elif mode == "interpreter":
        while True:
            process_json_input()
    else:
        print("Invalid mode selected. Please choose either 'server' or 'interpreter'.")


if __name__ == '__main__':
    main()

