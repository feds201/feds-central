import sqlite3
from flask import Flask, request, jsonify, send_file, render_template
import json


app = Flask(__name__)

# Initialize SQLite database
def init_db():
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
    print("Device database initialized")

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
    print("Match database initialized")




init_db()

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
    print(f"Devices fetched: {devices}")
    return render_template('devices.html', devices=devices)

@app.route('/api/devices', methods=['GET'])
def get_devices_json():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('SELECT id, device_name, ip_address FROM devices')
    devices = cursor.fetchall()
    conn.close()
    print(f"Devices fetched: {devices}")
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
    print(f"Data fetched: {data}")
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
    print(f"Data fetched: {data}")
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
    print(f"Data fetched for device {device_id}: {data}")
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
    print(f"Data fetched for device {device_id}: {data}")
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
        cursor.execute('INSERT INTO device_data (device_id, data) VALUES (?, ?)', (device_id, str(data)))
        conn.commit()
        print(f"Data inserted for device {device_id}: {data}")
    else:
        print(f"No device found with IP: {device_ip}")
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
        print(message)
        return jsonify({"status": "success", "message": message})
    else:
        cursor.execute('INSERT INTO devices (device_name, ip_address) VALUES (?, ?)', (device_name, device_ip))
        conn.commit()
        conn.close()
        print(f"Registered device: {device_name} with IP: {device_ip}")
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
    print("Data cleared")
    return render_template('clear_data.html', status="success")

@app.route('/api/clear_data', methods=['POST'])
def clear_data_json():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM device_data')
    conn.commit()
    conn.close()
    print("Data cleared")
    return jsonify({"status": "success"})

@app.route('/clear_devices', methods=['GET'])
def clear_devices():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices')
    conn.commit()
    conn.close()
    print("Devices cleared")
    return render_template('clear_devices.html', status="success")

@app.route('/api/clear_devices', methods=['POST'])
def clear_devices_json():
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices')
    conn.commit()
    conn.close()
    print("Devices cleared")
    return jsonify({"status": "success"})

@app.route('/alive', methods=['GET'])
def alive():
    return jsonify({"status": "alive"})

@app.route('/delete_device/<device_id>', methods=['POST'])
def delete_device(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices WHERE id = ?', (device_id,))
    conn.commit()
    conn.close()
    print(f"Device {device_id} deleted")
    return render_template('delete_device.html', status="success", device_id=device_id)

@app.route('/api/delete_device/<device_id>', methods=['POST'])
def delete_device_json(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM devices WHERE id = ?', (device_id,))
    conn.commit()
    conn.close()
    print(f"Device {device_id} deleted")
    return jsonify({"status": "success"})

@app.route('/clear_data/<device_id>', methods=['POST'])
def clear_data_for_device(device_id):
    conn = sqlite3.connect('devices.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM device_data WHERE device_id = ?', (device_id,))
    conn.commit()
    conn.close()
    print(f"Data for device {device_id} cleared")
    return jsonify({"status": "success"})

@app.route('/get_event_file', methods=['GET'])
def get_event_file():
    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()
    cursor.execute('SELECT match_data FROM event')
    data = cursor.fetchall()
    conn.close()
    print(f"Data fetched: {data}")
    return jsonify(data)


@app.route('/post_match', methods=['POST'])
def post_match():
    data = request.json
    if not data:
        return jsonify({"status": "error", "message": "No data provided"}), 400

    conn = sqlite3.connect('match.db')
    cursor = conn.cursor()

    try:
        for match in data['data']:
            print(match)
            match_id = match.get('key')
            match_data = json.dumps(match)
            cursor.execute('INSERT INTO event (match_id, match_data) VALUES (?, ?)', (match_id, match_data))

        conn.commit()
        conn.close()
        print(f"{len(data)} matches posted")
        return jsonify({"status": "success", "message": f"{len(data)} matches posted"}), 200
    except Exception as e:
        conn.close()
        print(f"Error occurred: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
    # return jsonify({"status": "success", "message": "Match data received"}), 200

@app.route('/clear_event_data', methods=['POST'])
def clear_event_data():
    print("Event data cleared")
    return jsonify({"status": "success"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
