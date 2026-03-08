import threading
# curses is only used for the local dashboard; may not be available on Windows
try:
    import curses
except ImportError:
    curses = None
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
from flask import Flask, request, jsonify, send_file, render_template, redirect
from flask_cors import CORS
import json
import psutil
import requests
import io
import qrcode

# Rebranding the server as Scout Ops Server
app = Flask("Scout Ops Server")
# allow cross‑origin requests from clients (Android/desktop web UI)
CORS(app)

TBA_API_KEY = os.environ.get('TBA_API_KEY')

# base directories for file operations
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, 'output_jsons')
LOG_FILE = os.path.join(OUTPUT_DIR, 'log.txt')

# ensure output directory and log file exist
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)
if not os.path.exists(LOG_FILE):
    with open(LOG_FILE, 'w') as f:
        f.write('')

# monkey‑patch sqlite3.connect so that any relative database path is resolved
# inside the output directory. This saves us from changing dozens of calls.
_original_sqlite_connect = sqlite3.connect

def _sqlite_connect(path, *args, **kwargs):
    if not os.path.isabs(path):
        path = os.path.join(OUTPUT_DIR, path)
    return _original_sqlite_connect(path, *args, **kwargs)

sqlite3.connect = _sqlite_connect

# Improved logging function
def log_message(message):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    formatted_message = f"[{timestamp}] [Scout Ops Server] {message}"
    with open(LOG_FILE, 'a') as file:
        file.write(formatted_message + '\n')
    print(formatted_message)

# Function to take input and save it
def process_json_input():
    count = 1
    while True:
        # Input for a JSON object
        input_data = input(f"Enter JSON object {count} (or type 'exit' to stop): ")

        if input_data.lower() == 'exit':
            log_message("Exiting JSON input mode.")
            break

        try:
            # Parse the input string into a Python dictionary
            json_data = json.loads(input_data)

            # Define the output file name
            output_filename = f"output_{count}.json"

            # Write the JSON data to a file
            with open(os.path.join(OUTPUT_DIR, output_filename), "w") as f:
                json.dump(json_data, f, indent=4)

            log_message(f"Processed and saved JSON object {count} as {output_filename}")
            count += 1
        except json.JSONDecodeError as e:
            log_message(f"Error processing JSON input: {e}. Please check the format.")

# Create output directory if not exists
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# we no longer change working directory; paths will be constructed explicitly


def get_server_info():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        server_ip = s.getsockname()[0]
        s.close()
    except Exception:
        server_ip = "Unable to get IP Address"

    try:
        cpu_usage = psutil.cpu_percent()
        memory_usage = psutil.virtual_memory().percent
        storage_usage = psutil.disk_usage(BASE_DIR).percent
        battery = psutil.sensors_battery()
        battery_status = f"{battery.percent}%" if battery else "N/A"
    except Exception:
        cpu_usage = 0
        memory_usage = 0
        storage_usage = 0
        battery_status = "N/A"

    return {
        "ServerIP": server_ip,
        "ServerBattery": battery_status,
        "ServerCPUUsage": cpu_usage,
        "ServerMemoryUsage": memory_usage,
        "ServerStorageUsage": storage_usage
    }


# Initialize SQLite database
def init_db():
    clear_log_file()

    Devicesconn = sqlite3.connect(os.path.join(OUTPUT_DIR, 'devices.db'))
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

    Matchconn = sqlite3.connect(os.path.join(OUTPUT_DIR, 'match.db'))
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

    shutil.move(os.path.join(OUTPUT_DIR, 'devices.db'), os.path.join(backup_dir, 'devices.db'))
    shutil.move(os.path.join(OUTPUT_DIR, 'match.db'), os.path.join(backup_dir, 'match.db'))
    shutil.move(LOG_FILE, os.path.join(backup_dir, 'log.txt'))
    pit_path = os.path.join(OUTPUT_DIR, 'pit_data.json')
    if os.path.exists(pit_path):
        shutil.move(pit_path, os.path.join(backup_dir, 'pit_data.json'))
    print(f"Moved databases to {backup_dir}")


def signal_handler(sig, frame):
    log_message("")
    log_message("Gracefully stopping the server...")
    log_message("\nServer stopped.")
    create_log_folder()
    if curses:
        try:
            curses.endwin()  # Restore terminal to original state
        except Exception:
            pass
    sys.exit(0)


# Function to run the Flask app in a separate thread
def run_flask_app():
    # allow PORT override (e.g. for Heroku, docker, etc.)
    port = int(os.environ.get('PORT', 201))
    http_server = WSGIServer(('0.0.0.0', port), app)
    print(f"Starting HTTP server on port {port}")
    http_server.serve_forever()


def read_log_file():
    with open(LOG_FILE, 'r') as file:
        return file.readlines()


def clear_log_file():
    with open(LOG_FILE, 'w') as file:
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

    info = get_server_info()

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
    help_shown_until = 0
    help_text = "Press 'c' to clear logs | 'h' for help | Ctrl+C to exit"
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

        # Non-blocking key handling
        key = stdscr.getch()
        if key != -1:
            try:
                ch = chr(key).lower()
            except Exception:
                ch = ''

            if ch == 'c':
                clear_log_file()
                log_message("Logs cleared via keyboard 'c'")
            elif ch == 'h':
                help_shown_until = time.time() + 5

        # If help requested, show a short help box above the exit box
        if time.time() < help_shown_until:
            help_w = len(help_text) + 4
            help_box = curses.newwin(3, help_w, height - 6, width // 2 - help_w // 2)
            help_box.box()
            try:
                help_box.addstr(1, 2, help_text, curses.A_BOLD)
            except Exception:
                pass
            help_box.refresh()

        stdscr.refresh()
        time.sleep(1)


# Flask routes
@app.before_request
def log_incoming_request():
    try:
        remote = request.remote_addr
        path = request.path
        method = request.method
        log_message(f"Incoming HTTP {method} request for {path} from {remote}")
    except Exception:
        pass

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
    rows = cursor.fetchall()
    conn.close()
    devices = []
    for r in rows:
        devices.append({"id": r[0], "device_name": r[1], "ip_address": r[2]})
    log_message(f"Devices fetched: {devices}")
    return jsonify(devices)


# HTML and JSON endpoints for data
@app.route('/get_data', methods=['GET'])
def get_data_all():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    # include device id as third column so the page can clear by device
    cursor.execute('''
        SELECT d.id, d.device_name, dd.data
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
        SELECT d.id, d.device_name, dd.data
        FROM device_data dd
        JOIN devices d ON dd.device_id = d.id
    ''')
    rows = cursor.fetchall()
    conn.close()
    out = []
    for r in rows:
        # r: (device_id, device_name, data)
        try:
            parsed = json.loads(r[2])
        except Exception:
            parsed = r[2]
        out.append({"device_id": r[0], "device_name": r[1], "data": parsed})
    log_message(f"Data fetched")
    return jsonify(out)


# HTML and JSON endpoints for device-specific data
@app.route('/get_data/<device_id>', methods=['GET'])
def get_data(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('''
        SELECT d.id, d.device_name, dd.data
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
        SELECT d.id, d.device_name, dd.data
        FROM device_data dd
        JOIN devices d ON dd.device_id = d.id
        WHERE d.id = ?
    ''', (device_id,))
    rows = cursor.fetchall()
    conn.close()
    out = []
    for r in rows:
        try:
            parsed = json.loads(r[2])
        except Exception:
            parsed = r[2]
        out.append({"device_id": r[0], "device_name": r[1], "data": parsed})
    log_message(f"Data fetched for device {device_id}")
    return jsonify(out)


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
    file_path = os.path.join(BASE_DIR, 'App', 'app-release.apk')
    return send_file(file_path, as_attachment=True)


@app.route('/client_images/getServer', methods=['GET'])
def getServer():
    file_path = os.path.join(BASE_DIR, 'App', 'server.exe')
    return send_file(file_path, as_attachment=True)


@app.route('/client_images/getWindows', methods=['GET'])
def getWindows():
    return send_file(os.path.join(BASE_DIR, 'App', 'app-release.apk'), as_attachment=True)


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
        with open(os.path.join(OUTPUT_DIR, 'pit_data.json'), 'w') as file:
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


@app.route('/generate_qrcode/<device_id>', methods=['POST'])
def generate_qrcode(device_id):
    # create a simple QR code containing all data rows for the given device
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('SELECT dd.data FROM device_data dd WHERE dd.device_id = ?', (device_id,))
    rows = cursor.fetchall()
    conn.close()
    text = "\n".join(r[0] for r in rows)
    img = qrcode.make(text or "")
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    buf.seek(0)
    return send_file(buf, mimetype='image/png')


@app.route('/get_event_file', methods=['GET'])
def get_event_file():
    # API that returns raw event JSON stored in the database
    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()
    cursor.execute('SELECT match_data FROM event')
    rows = cursor.fetchall()
    data = []
    for row in rows:
        raw = row[0]
        try:
            data.append(json.loads(raw))
        except Exception:
            # not JSON — return raw string so clients can handle CSV or plain text
            data.append(raw)
    conn.close()
    log_message(f"Event data fetched")
    return jsonify(data)


@app.route('/api/get_event_file', methods=['GET'])
def get_event_file_api():
    log_message("/api/get_event_file requested")
    return get_event_file()


@app.route('/api/get_event_file.csv', methods=['GET'])
def get_event_file_csv():
    """Return the stored event rows as a single CSV text response.

    If the stored match_data rows look like CSV (contain commas), join them
    with newlines and return with Content-Type text/csv. Otherwise return
    a 204 No Content.
    """
    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()
    cursor.execute('SELECT match_data FROM event')
    rows = cursor.fetchall()
    conn.close()

    csv_lines = []
    for row in rows:
        raw = row[0]
        # treat row as CSV if it contains a comma or newline
        if isinstance(raw, str) and (',' in raw or '\n' in raw):
            csv_lines.append(raw.strip())

    if not csv_lines:
        log_message('/api/get_event_file.csv: no CSV rows found')
        return ('', 204)

    csv_text = '\n'.join(csv_lines)
    log_message('/api/get_event_file.csv: serving CSV')
    return (csv_text, 200, {'Content-Type': 'text/csv; charset=utf-8'})


@app.route('/receive_match_csv', methods=['POST'])
def receive_match_csv():
    # Accept raw CSV in the request body and store as a single row in match.db
    content_type = request.headers.get('Content-Type', '')
    if 'text/csv' not in content_type and 'text/plain' not in content_type:
        return jsonify({"status": "error", "message": "Content-Type must be text/csv or text/plain"}), 400

    csv_text = request.get_data(as_text=True)
    if not csv_text:
        return jsonify({"status": "error", "message": "Empty body"}), 400

    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()
    match_id = datetime.now().strftime('csv_%Y%m%d%H%M%S')
    cursor.execute('INSERT INTO event (match_id, match_data) VALUES (?, ?)', (match_id, csv_text))
    conn.commit()
    conn.close()
    log_message(f"Received match CSV stored as {match_id}")
    return jsonify({"status": "success", "match_id": match_id})


@app.route('/event', methods=['GET'])
def event_page():
    # render simple HTML list of matches stored in the database
    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()
    cursor.execute('SELECT match_data FROM event')
    rows = cursor.fetchall()
    matches = [json.loads(r[0]) for r in rows]
    conn.close()
    return render_template('event.html', matches=matches)


@app.route('/logs', methods=['GET'])
def view_logs():
    # show log file contents in a preformatted block
    try:
        lines = read_log_file()
        message = '<pre>' + '\n'.join(lines) + '</pre>'
    except FileNotFoundError:
        message = 'no log file yet'
    return render_template('info.html', message=message)



@app.route('/post_event_file', methods=['POST'])
def post_match():
    if 'Event' not in request.files:
        return jsonify({"status": "error", "message": "No file provided"}), 400

    file = request.files['Event']
    # note: file.read() will be used below, no change needed
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
        # if this request came from an HTML form, redirect back to UI
        if request.content_type and request.content_type.startswith('multipart/form-data'):
            return redirect('/event')
        return jsonify({"status": "success", "message": f"{len(data)} matches posted"}), 200
    except Exception as e:
        conn.close()
        if request.content_type and request.content_type.startswith('multipart/form-data'):
            # flash or log then redirect
            log_message(f"Error posting event via form: {e}")
            return redirect('/event')
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
    server_info = get_server_info()
    return jsonify(server_info)


@app.route('/api/tba/team/<int:team_number>', methods=['GET'])
def get_tba_team_data(team_number):
    if not TBA_API_KEY:
        return jsonify({"error": "TBA_API_KEY environment variable is not set"}), 500

    url = f"https://www.thebluealliance.com/api/v3/team/frc{team_number}"
    headers = {"X-TBA-Auth-Key": TBA_API_KEY}
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            resp = jsonify(data)
            resp.headers.add('Access-Control-Allow-Origin', '*')
            return resp
        else:
            return jsonify({"error": "Failed to fetch data from TBA", "status_code": response.status_code}), response.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/server_info', methods=['GET'])
def get_server_info_endpoint():
    return jsonify(get_server_info())


# Main function
def main():
    # simple argument-based mode selection; fallback to interactive prompt
    args = [a.lower() for a in sys.argv[1:]]
    if 'server' in args:
        mode = 'server'
    elif 'interpreter' in args or 'cli' in args:
        mode = 'interpreter'
    else:
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

        headless = ('--headless' in args) or os.environ.get('HEADLESS') == '1'
        if headless or not curses:
            if not curses and not headless:
                print("curses module unavailable; falling back to headless mode")
            print("Running server in headless mode (no curses interface)")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                signal_handler(None, None)
        else:
            # Start the curses interface, will block until exit
            curses.wrapper(curses_interface)
    elif mode == "interpreter":
        while True:
            process_json_input()
    else:
        print("Invalid mode selected. Please choose either 'server' or 'interpreter'.")


if __name__ == '__main__':
    main()

