import requests
import json
import csv
import os
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
from datetime import datetime

class BlueAllianceClient:
    def __init__(self):
        # TBA API base URL
        self.base_url = "https://www.thebluealliance.com/api/v3"
        # You need to get your own key from The Blue Alliance
        self.headers = {
            "X-TBA-Auth-Key": "2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W"  # Replace with your actual TBA API key
        }

    def get_event_data(self, event_key):
        """Get all relevant data for an event."""
        data = {}
        
        # Get basic event info
        data['event_info'] = self.get_api_data(f"/event/{event_key}")
        
        # Get teams at the event
        data['teams'] = self.get_api_data(f"/event/{event_key}/teams")
        
        # Get matches
        data['matches'] = self.get_api_data(f"/event/{event_key}/matches")
        
        # Get rankings
        data['rankings'] = self.get_api_data(f"/event/{event_key}/rankings")
        
        # Get alliances
        data['alliances'] = self.get_api_data(f"/event/{event_key}/alliances")
        
        return data

    def get_api_data(self, endpoint):
        """Make a request to the TBA API."""
        url = self.base_url + endpoint
        response = requests.get(url, headers=self.headers)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
            return None

    def convert_to_csv(self, data, output_folder):
        """Convert the JSON data to CSV files."""
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)
        
        csv_files = []
        
        # Process each data type
        for data_type, items in data.items():
            if not items:
                continue
                
            filename = os.path.join(output_folder, f"{data_type}.csv")
            csv_files.append(filename)
            
            if data_type == 'event_info':
                # Handle single object data
                self.single_object_to_csv(items, filename)
            elif data_type == 'rankings' and 'rankings' in items:
                # Special handling for rankings data structure
                self.rankings_to_csv(items, filename)
            else:
                # Handle array of objects
                self.array_to_csv(items, filename)
                
        return csv_files

    def single_object_to_csv(self, data, filename):
        """Convert a single JSON object to CSV."""
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            # Write header
            writer.writerow(data.keys())
            # Write data
            writer.writerow(data.values())

    def array_to_csv(self, data, filename):
        """Convert an array of JSON objects to CSV."""
        if not data:
            return
            
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            # Get all possible fieldnames from all objects
            fieldnames = set()
            for item in data:
                fieldnames.update(item.keys())
            
            writer = csv.DictWriter(csvfile, fieldnames=sorted(fieldnames))
            writer.writeheader()
            for item in data:
                writer.writerow(item)

    def rankings_to_csv(self, data, filename):
        """Special handling for rankings data structure."""
        rankings = data.get('rankings', [])
        if not rankings:
            return
            
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            # Extract all possible fieldnames
            fieldnames = set()
            for ranking in rankings:
                fieldnames.update(ranking.keys())
                if 'extra_stats' in ranking:
                    fieldnames.remove('extra_stats')
                if 'sort_orders' in ranking:
                    fieldnames.remove('sort_orders')
                    
            # Add extra stats and sort orders with their names
            if rankings and 'extra_stats' in rankings[0]:
                for i, name in enumerate(data.get('extra_stats_info', [])):
                    fieldnames.add(f"extra_{name['name']}")
                    
            if rankings and 'sort_orders' in rankings[0]:
                for i, name in enumerate(data.get('sort_order_info', [])):
                    fieldnames.add(f"sort_{name['name']}")
            
            writer = csv.DictWriter(csvfile, fieldnames=sorted(fieldnames))
            writer.writeheader()
            
            for ranking in rankings:
                row = ranking.copy()
                
                # Handle extra_stats
                if 'extra_stats' in row:
                    extra_stats = row.pop('extra_stats')
                    for i, value in enumerate(extra_stats):
                        if i < len(data.get('extra_stats_info', [])):
                            name = data['extra_stats_info'][i]['name']
                            row[f"extra_{name}"] = value
                
                # Handle sort_orders
                if 'sort_orders' in row:
                    sort_orders = row.pop('sort_orders')
                    for i, value in enumerate(sort_orders):
                        if i < len(data.get('sort_order_info', [])):
                            name = data['sort_order_info'][i]['name']
                            row[f"sort_{name}"] = value
                
                writer.writerow(row)


class BlueAllianceApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Ritesh is jha best")
        self.root.geometry("600x450")
        self.root.resizable(True, True)
        
        self.client = BlueAllianceClient()
        
        # Configure style
        style = ttk.Style()
        style.configure('TFrame', background='#f0f0f0')
        style.configure('TLabel', background='#f0f0f0', font=('Arial', 12))
        style.configure('TEntry', font=('Arial', 12))
        style.configure('TButton', font=('Arial', 12))
        
        # Main frame
        main_frame = ttk.Frame(root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title
        title_label = ttk.Label(main_frame, text="FEDS Blue Alliance Data Converter", 
                                font=('Arial', 16, 'bold'))
        title_label.pack(pady=(0, 20))
        
        # API Key frame
        api_frame = ttk.Frame(main_frame)
        api_frame.pack(fill=tk.X, pady=10)
        
        api_label = ttk.Label(api_frame, text="TBA API Key:")
        api_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.api_key_var = tk.StringVar()
        self.api_key_entry = ttk.Entry(api_frame, textvariable=self.api_key_var, width=50)
        self.api_key_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        # Event key frame
        event_frame = ttk.Frame(main_frame)
        event_frame.pack(fill=tk.X, pady=10)
        
        event_label = ttk.Label(event_frame, text="Event Key:")
        event_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.event_key_var = tk.StringVar()
        self.event_key_entry = ttk.Entry(event_frame, textvariable=self.event_key_var, width=20)
        self.event_key_entry.pack(side=tk.LEFT)
        
        event_help = ttk.Label(event_frame, text="(e.g., 2023miliv)")
        event_help.pack(side=tk.LEFT, padx=(5, 0))
        
        # Output directory frame
        output_frame = ttk.Frame(main_frame)
        output_frame.pack(fill=tk.X, pady=10)
        
        output_label = ttk.Label(output_frame, text="Output Directory:")
        output_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.output_dir_var = tk.StringVar(value=os.path.join(os.path.dirname(__file__), "tba_data"))
        self.output_dir_entry = ttk.Entry(output_frame, textvariable=self.output_dir_var, width=40)
        self.output_dir_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        browse_button = ttk.Button(output_frame, text="Browse", command=self.browse_directory)
        browse_button.pack(side=tk.LEFT, padx=(5, 0))
        
        # Fetch button
        fetch_button = ttk.Button(
            main_frame, 
            text="Fetch and Convert Data", 
            command=self.fetch_and_convert,
            style='Accent.TButton'
        )
        fetch_button.pack(pady=20)
        
        # Status frame
        status_frame = ttk.Frame(main_frame)
        status_frame.pack(fill=tk.X, pady=10)
        
        self.status_var = tk.StringVar()
        status_label = ttk.Label(status_frame, textvariable=self.status_var, foreground="blue")
        status_label.pack(fill=tk.X)
        
        # Progress bar
        self.progress_var = tk.DoubleVar()
        self.progress = ttk.Progressbar(
            main_frame, 
            orient=tk.HORIZONTAL, 
            length=100, 
            mode='determinate',
            variable=self.progress_var
        )
        self.progress.pack(fill=tk.X, pady=10)
        
        # Results frame
        self.results_frame = ttk.Frame(main_frame)
        self.results_frame.pack(fill=tk.BOTH, expand=True)
        
        # Load saved API key if available
        self.load_api_key()

    def browse_directory(self):
        directory = filedialog.askdirectory()
        if directory:
            self.output_dir_var.set(directory)

    def load_api_key(self):
        """Load saved API key if available."""
        try:
            if os.path.exists('tba_config.json'):
                with open('tba_config.json', 'r') as f:
                    config = json.load(f)
                    if 'api_key' in config:
                        self.api_key_var.set(config['api_key'])
        except Exception as e:
            print(f"Error loading API key: {e}")

    def save_api_key(self):
        """Save API key for future use."""
        try:
            config = {'api_key': self.api_key_var.get()}
            with open('tba_config.json', 'w') as f:
                json.dump(config, f)
        except Exception as e:
            print(f"Error saving API key: {e}")

    def fetch_and_convert(self):
        # Get input values
        api_key = self.api_key_var.get().strip()
        event_key = self.event_key_var.get().strip()
        output_dir = self.output_dir_var.get().strip()
        
        # Validate inputs
        if not api_key:
            messagebox.showerror("Error", "Please enter a TBA API key")
            return
            
        if not event_key:
            messagebox.showerror("Error", "Please enter an event key")
            return
            
        # Save API key for future use
        self.save_api_key()
        
        # Update client API key
        self.client.headers["X-TBA-Auth-Key"] = api_key
        
        # Clear previous results
        for widget in self.results_frame.winfo_children():
            widget.destroy()
            
        self.status_var.set("Fetching data from The Blue Alliance...")
        self.progress_var.set(10)
        self.root.update()
        
        try:
            # Create event-specific directory
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            event_dir = os.path.join(output_dir, f"{event_key}_{timestamp}")
            
            # Fetch data
            event_data = self.client.get_event_data(event_key)
            
            if not event_data['event_info']:
                messagebox.showerror("Error", f"Could not find event with key: {event_key}")
                self.status_var.set("Error: Event not found")
                self.progress_var.set(0)
                return
                
            self.status_var.set("Converting data to CSV...")
            self.progress_var.set(50)
            self.root.update()
            
            # Convert to CSV
            csv_files = self.client.convert_to_csv(event_data, event_dir)
            
            self.status_var.set(f"Done! {len(csv_files)} CSV files created.")
            self.progress_var.set(100)
            
            # Show results
            results_label = ttk.Label(
                self.results_frame, 
                text=f"Data saved to:", 
                font=('Arial', 12, 'bold')
            )
            results_label.pack(anchor=tk.W, pady=(10, 5))
            
            path_label = ttk.Label(self.results_frame, text=event_dir)
            path_label.pack(anchor=tk.W)
            
            files_label = ttk.Label(
                self.results_frame, 
                text=f"Files created:", 
                font=('Arial', 12, 'bold')
            )
            files_label.pack(anchor=tk.W, pady=(10, 5))
            
            for file_path in csv_files:
                file_name = os.path.basename(file_path)
                file_label = ttk.Label(self.results_frame, text=file_name)
                file_label.pack(anchor=tk.W)
                
            # Open folder button
            open_button = ttk.Button(
                self.results_frame, 
                text="Open Output Folder", 
                command=lambda: os.startfile(event_dir)
            )
            open_button.pack(pady=10)
            
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
            self.status_var.set(f"Error: {str(e)}")
            self.progress_var.set(0)


if __name__ == "__main__":
    # Create root window
    root = tk.Tk()
    app = BlueAllianceApp(root)
    root.mainloop()