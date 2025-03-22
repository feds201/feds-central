import requests
import json
import csv
import os
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
from datetime import datetime

class StatboticsClient:
    def __init__(self):
        # Statbotics API base URL
        self.base_url = "https://api.statbotics.io/v3"
        self.tba = BlueAllianceClient()
        
    def get_event_data(self, event_key):
        """Get all relevant data for an event from Statbotics."""
        data = {}
        
        # Get basic event info
        data['event_info'] = self.get_api_data(f"/event/{event_key}")
        
        # Get teams at the event with their stats
        event_teams = self.get_api_data(f"/team_events?event={event_key}&limit=500")
        if event_teams:
            data['event_teams'] = event_teams
        
        # Get match predictions
        match_predictions = self.get_api_data(f"/matches?event={event_key}&limit=500")
        if match_predictions:
            data['match_predictions'] = match_predictions
            
        # Get team rankings
        team_rankings = self.get_api_data(f"/team_events?event={event_key}&metric=epa_rank&limit=500")
        if team_rankings:
            data['team_rankings'] = team_rankings
            
        return data

    def get_match_prediction(self, match_key):
        """Get prediction data for a specific match."""
        return self.get_api_data(f"/match/{match_key}")

    def get_api_data(self, endpoint):
        """Make a request to the Statbotics API."""
        url = self.base_url + endpoint
        print(url)
        try:
            response = requests.get(url)
            
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Error: {response.status_code}")
                print(response.text)
                return None
        except Exception as e:
            print(f"API request error: {e}")
            return None

    def fetch_teams(self, eventkey):
        print(eventkey)
        """Fetch teams from the Statbotics API."""
        teams_data = self.tba.get_api_data(f"/event/{eventkey}/teams")
        teams = []
        if teams_data:
            for team in teams_data:
                if 'team_number' in team:
                    teams.append(team['team_number'])
        print(teams)
        return teams

    def fetch_event_data(self, eventkey):
        """Fetch event data including teams and matches."""
        event_data = self.get_api_data(f"/event/{eventkey}")
        return event_data
    
    def fetch_team_epa(self, team_numbers):
        
        """Fetch EPA data for specific teams."""
        epa_data = []
        for team_number in team_numbers:
            data = self.get_api_data(f"/team/{team_number}")
            team_epa = data["norm_epa"]
            team_record = data["record"]
            epa_data.append((team_epa, team_record))
        return epa_data
    

    def fetch_match_data(self, matchkey):
        """Fetch match data from the Statbotics API."""
        match_data = self.get_api_data(f"/match/{matchkey}")
        return match_data



class BlueAllianceClient:
    def __init__(self):
        # TBA API base URL
        self.base_url = "https://www.thebluealliance.com/api/v3"
        # You need to get your own key from The Blue Alliance
        self.headers = {
            "X-TBA-Auth-Key": "2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W"  # Replace with your actual TBA API key
        }

    def fetch_teams(self, eventkey):
        """Fetch teams from the Statbotics API."""
        teams_data = self.get_api_data(f"/event/{eventkey}/teams")
        return teams_data

    def fetch_match_teams(self, matchkey):
        """Fetch teams for a specific match."""
        match_data = self.get_api_data(f"/match/{matchkey}/teams")
        for team in match_data:
            print(team['team_number'])
        return match_data

    def get_event_data(self, event_key):
        """Get all relevant data for an event."""
        data = {}
        
        # Get basic event info
        data['event_info'] = self.get_api_data(f"/event/{event_key}")
        
        # Get teams at the event
        data['teams'] = self.get_api_data(f"/event/{event_key}/teams")
        
        # Get matches with detailed breakdown
        matches = self.get_api_data(f"/event/{event_key}/matches")
        
        # For each match, get detailed scoring data if available
        if matches:
            for match in matches:
                # Ensure score_breakdown data is complete
                if 'score_breakdown' in match and match['score_breakdown']:
                    # Already has detailed scoring data
                    pass
                else:
                    # Get match details including score breakdown
                    match_detail = self.get_api_data(f"/match/{match['key']}")
                    if match_detail and 'score_breakdown' in match_detail:
                        match['score_breakdown'] = match_detail['score_breakdown']
                        
        data['matches'] = matches
        
        # Get rankings
        data['rankings'] = self.get_api_data(f"/event/{event_key}/rankings")
        
        # Get alliances
        data['alliances'] = self.get_api_data(f"/event/{event_key}/alliances")
        
        # Get match details with score breakdowns
        data['match_details'] = self.get_api_data(f"/event/{event_key}/matches")
        
        return data

    def get_api_data(self, endpoint):
        """Make a request to the TBA API."""
        url = self.base_url + endpoint
        print(url)
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
            elif data_type == 'matches':
                # Enhanced handling for match data with all scoring info
                self.matches_to_csv(items, filename)
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
                fieldnames.update(self.flatten_keys(item))
            
            writer = csv.DictWriter(csvfile, fieldnames=sorted(fieldnames))
            writer.writeheader()
            for item in data:
                writer.writerow(self.flatten_dict(item))
    
    def flatten_dict(self, d, parent_key='', sep='_'):
        """Flatten nested dictionaries for CSV export."""
        items = []
        for k, v in d.items():
            new_key = f"{parent_key}{sep}{k}" if parent_key else k
            if isinstance(v, dict):
                items.extend(self.flatten_dict(v, new_key, sep=sep).items())
            elif isinstance(v, list):
                if all(isinstance(item, dict) for item in v):
                    for i, item in enumerate(v):
                        items.extend(self.flatten_dict(item, f"{new_key}{sep}{i}", sep=sep).items())
                else:
                    items.append((new_key, json.dumps(v)))
            else:
                items.append((new_key, v))
        return dict(items)
        
    def flatten_keys(self, d, parent_key='', sep='_'):
        """Get all keys from a nested dictionary."""
        keys = []
        for k, v in d.items():
            new_key = f"{parent_key}{sep}{k}" if parent_key else k
            if isinstance(v, dict):
                keys.extend(self.flatten_keys(v, new_key, sep=sep))
            elif isinstance(v, list) and all(isinstance(item, dict) for item in v):
                for i, item in enumerate(v):
                    keys.extend(self.flatten_keys(item, f"{new_key}{sep}{i}", sep=sep))
            else:
                keys.append(new_key)
        return keys

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
                
    def matches_to_csv(self, matches, filename):
        """Enhanced handling for matches with all scoring information."""
        if not matches:
            return
            
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            # Get all possible fieldnames from all matches including deeply nested scoring data
            fieldnames = set()
            for match in matches:
                flat_match = self.flatten_dict(match)
                fieldnames.update(flat_match.keys())
            
            writer = csv.DictWriter(csvfile, fieldnames=sorted(fieldnames))
            writer.writeheader()
            
            for match in matches:
                flat_match = self.flatten_dict(match)
                writer.writerow(flat_match)



class ScoutingApp:
    def __init__(self, root):
        self.root = root
        self.root.title("FEDS Scouting Suite")
        self.root.geometry("800x650")
        self.root.resizable(True, True)
        
        self.tba_client = BlueAllianceClient()
        self.statbotics_client = StatboticsClient()
        
        # Configure style
        style = ttk.Style()
        style.configure('TFrame', background='#f0f0f0')
        style.configure('TLabel', background='#f0f0f0', font=('Arial', 12))
        style.configure('TEntry', font=('Arial', 12))
        style.configure('TButton', font=('Arial', 12))
        
        # Create notebook for tabs
        self.notebook = ttk.Notebook(root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create tabs
        self.tba_tab = ttk.Frame(self.notebook)
        self.stats_tab = ttk.Frame(self.notebook)
        
        self.notebook.add(self.tba_tab, text="Blue Alliance Data")
        self.notebook.add(self.stats_tab, text="Match Statistics")
        
        # Initialize tabs
        self.init_tba_tab()
        self.init_stats_tab()
        
        # Load saved settings
        self.load_saved_settings()

    def init_stats_tab(self):
        """Initialize the Statistics tab for combined match data."""
        main_frame = ttk.Frame(self.stats_tab, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title
        title_label = ttk.Label(main_frame, text="Combined Match Statistics", 
                                font=('Arial', 16, 'bold'))
        title_label.pack(pady=(0, 20))
        
        # Event key frame
        event_frame = ttk.Frame(main_frame)
        event_frame.pack(fill=tk.X, pady=10)
        
        event_label = ttk.Label(event_frame, text="Event Key:")
        event_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.stats_event_key_var = tk.StringVar()
        self.stats_event_key_entry = ttk.Entry(event_frame, textvariable=self.stats_event_key_var, width=20)
        self.stats_event_key_entry.pack(side=tk.LEFT)
        
        event_help = ttk.Label(event_frame, text="(e.g., 2025miket)")
        event_help.pack(side=tk.LEFT, padx=(5, 0))
        
        # Match key frame
        match_frame = ttk.Frame(main_frame)
        match_frame.pack(fill=tk.X, pady=10)
        
        match_label = ttk.Label(match_frame, text="Match Number:")
        match_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.stats_match_number_var = tk.StringVar()
        self.stats_match_number_entry = ttk.Entry(match_frame, textvariable=self.stats_match_number_var, width=10)
        self.stats_match_number_entry.pack(side=tk.LEFT)
        
        match_help = ttk.Label(match_frame, text="(e.g., qm1, sf2m3)")
        match_help.pack(side=tk.LEFT, padx=(5, 0))
        
        # Match type frame
        match_type_frame = ttk.Frame(main_frame)
        match_type_frame.pack(fill=tk.X, pady=10)
        
        match_type_label = ttk.Label(match_type_frame, text="Match Type:")
        match_type_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.stats_match_type_var = tk.StringVar(value="qm")
        match_types = ["qm", "sf", "f", "qf"]
        match_type_combo = ttk.Combobox(match_type_frame, textvariable=self.stats_match_type_var, 
                                        values=match_types, width=10)
        match_type_combo.pack(side=tk.LEFT)
        
        # Output directory frame
        output_frame = ttk.Frame(main_frame)
        output_frame.pack(fill=tk.X, pady=10)
        
        output_label = ttk.Label(output_frame, text="Output Directory:")
        output_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.stats_output_dir_var = tk.StringVar(value=os.path.join(os.path.dirname(__file__), "match_stats"))
        self.stats_output_dir_entry = ttk.Entry(output_frame, textvariable=self.stats_output_dir_var, width=40)
        self.stats_output_dir_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        browse_button = ttk.Button(output_frame, text="Browse", command=self.stats_browse_directory)
        browse_button.pack(side=tk.LEFT, padx=(5, 0))
        
        # TBA API Key frame
        api_frame = ttk.Frame(main_frame)
        api_frame.pack(fill=tk.X, pady=10)
        
        api_label = ttk.Label(api_frame, text="TBA API Key:")
        api_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.stats_api_key_var = tk.StringVar()
        self.stats_api_key_entry = ttk.Entry(api_frame, textvariable=self.stats_api_key_var, width=50)
        self.stats_api_key_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        # Button frame
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill=tk.X, pady=10)
        
        # Fetch match data button
        fetch_button = ttk.Button(
            button_frame, 
            text="Fetch Match Data", 
            command=self.fetch_combined_match_data
        )
        fetch_button.pack(side=tk.LEFT, padx=(0, 10))
        
        # Generate team insights button (separate function)
        team_insights_button = ttk.Button(
            button_frame, 
            text="Generate Team Insights", 
            command=self.generate_team_insights
        )
        team_insights_button.pack(side=tk.LEFT)
        
        # Status frame
        status_frame = ttk.Frame(main_frame)
        status_frame.pack(fill=tk.X, pady=10)
        
        self.stats_status_var = tk.StringVar()
        stats_status_label = ttk.Label(status_frame, textvariable=self.stats_status_var, foreground="blue")
        stats_status_label.pack(fill=tk.X)
        
        # Progress bar
        self.stats_progress_var = tk.DoubleVar()
        self.stats_progress = ttk.Progressbar(
            main_frame, 
            orient=tk.HORIZONTAL, 
            length=100, 
            mode='determinate',
            variable=self.stats_progress_var
        )
        self.stats_progress.pack(fill=tk.X, pady=10)
        
        # Results frame
        self.stats_results_frame = ttk.Frame(main_frame)
        self.stats_results_frame.pack(fill=tk.BOTH, expand=True)

    def init_tba_tab(self):
        """Initialize the Blue Alliance tab."""
        main_frame = ttk.Frame(self.tba_tab, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title
        title_label = ttk.Label(main_frame, text="Blue Alliance Data Converter", 
                                font=('Arial', 16, 'bold'))
        title_label.pack(pady=(0, 20))
        
        # API Key frame
        api_frame = ttk.Frame(main_frame)
        api_frame.pack(fill=tk.X, pady=10)
        
        api_label = ttk.Label(api_frame, text="TBA API Key:")
        api_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.tba_api_key_var = tk.StringVar()
        self.tba_api_key_entry = ttk.Entry(api_frame, textvariable=self.tba_api_key_var, width=50)
        self.tba_api_key_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        # Event key frame
        event_frame = ttk.Frame(main_frame)
        event_frame.pack(fill=tk.X, pady=10)
        
        event_label = ttk.Label(event_frame, text="Event Key:")
        event_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.tba_event_key_var = tk.StringVar()
        self.tba_event_key_entry = ttk.Entry(event_frame, textvariable=self.tba_event_key_var, width=20)
        self.tba_event_key_entry.pack(side=tk.LEFT)
        
        event_help = ttk.Label(event_frame, text="(e.g., 2023miliv)")
        event_help.pack(side=tk.LEFT, padx=(5, 0))
        
        # Output directory frame
        output_frame = ttk.Frame(main_frame)
        output_frame.pack(fill=tk.X, pady=10)
        
        output_label = ttk.Label(output_frame, text="Output Directory:")
        output_label.pack(side=tk.LEFT, padx=(0, 10))
        
        self.tba_output_dir_var = tk.StringVar(value=os.path.join(os.path.dirname(__file__), "tba_data"))
        self.tba_output_dir_entry = ttk.Entry(output_frame, textvariable=self.tba_output_dir_var, width=40)
        self.tba_output_dir_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        browse_button = ttk.Button(output_frame, text="Browse", command=self.tba_browse_directory)
        browse_button.pack(side=tk.LEFT, padx=(5, 0))
        
        # Update existing data option
        self.tba_update_existing = tk.BooleanVar(value=True)
        update_check = ttk.Checkbutton(main_frame, text="Update existing files (don't create new folder)", 
                                      variable=self.tba_update_existing)
        update_check.pack(anchor=tk.W, pady=5)
        
        # Fetch button
        fetch_button = ttk.Button(
            main_frame, 
            text="Fetch and Convert TBA Data", 
            command=self.tba_fetch_and_convert
        )
        fetch_button.pack(pady=20)
        
        # Status frame
        status_frame = ttk.Frame(main_frame)
        status_frame.pack(fill=tk.X, pady=10)
        
        self.tba_status_var = tk.StringVar()
        tba_status_label = ttk.Label(status_frame, textvariable=self.tba_status_var, foreground="blue")
        tba_status_label.pack(fill=tk.X)
        
        # Progress bar
        self.tba_progress_var = tk.DoubleVar()
        self.tba_progress = ttk.Progressbar(
            main_frame, 
            orient=tk.HORIZONTAL, 
            length=100, 
            mode='determinate',
            variable=self.tba_progress_var
        )
        self.tba_progress.pack(fill=tk.X, pady=10)
        
        # Results frame
        self.tba_results_frame = ttk.Frame(main_frame)
        self.tba_results_frame.pack(fill=tk.BOTH, expand=True)

    def stats_browse_directory(self):
        directory = filedialog.askdirectory()
        if directory:
            self.stats_output_dir_var.set(directory)

    def tba_browse_directory(self):
        directory = filedialog.askdirectory()
        if directory:
            self.tba_output_dir_var.set(directory)

    def load_saved_settings(self):
        """Load saved settings if available."""
        try:
            if os.path.exists('scouting_config.json'):
                with open('scouting_config.json', 'r') as f:
                    config = json.load(f)
                    # TBA settings
                    if 'tba_api_key' in config:
                        self.tba_api_key_var.set(config['tba_api_key'])
                        self.stats_api_key_var.set(config['tba_api_key'])  # Share API key between tabs
                    if 'tba_event_key' in config:
                        self.tba_event_key_var.set(config['tba_event_key'])
                        self.stats_event_key_var.set(config['tba_event_key'])  # Share event key between tabs
                    if 'tba_output_dir' in config:
                        self.tba_output_dir_var.set(config['tba_output_dir'])
                        
                    # Stats settings
                    if 'stats_output_dir' in config:
                        self.stats_output_dir_var.set(config['stats_output_dir'])
        except Exception as e:
            print(f"Error loading saved settings: {e}")

    def save_settings(self):
        """Save settings for future use."""
        try:
            config = {
                'tba_api_key': self.tba_api_key_var.get(),
                'tba_event_key': self.tba_event_key_var.get(),
                'tba_output_dir': self.tba_output_dir_var.get(),
                'stats_output_dir': self.stats_output_dir_var.get()
            }
            with open('scouting_config.json', 'w') as f:
                json.dump(config, f)
        except Exception as e:
            print(f"Error saving settings: {e}")

    def fetch_combined_match_data(self):
        """Fetch and combine data from TBA and Statbotics for a specific match."""
        # Get input values
        api_key = self.stats_api_key_var.get().strip()
        event_key = self.stats_event_key_var.get().strip()
        match_type = self.stats_match_type_var.get().strip()
        match_number = self.stats_match_number_var.get().strip()
        output_dir = self.stats_output_dir_var.get().strip()
        
        # Validate inputs
        if not api_key:
            messagebox.showerror("Error", "Please enter a TBA API key")
            return
            
        if not event_key:
            messagebox.showerror("Error", "Please enter an event key")
            return
            
        if not match_number:
            messagebox.showerror("Error", "Please enter a match number")
            return
        
        # Construct match key
        match_key = f"{event_key}_{match_type}{match_number}"
        
        # Save settings for future use
        self.save_settings()
        
        # Update client API key
        self.tba_client.headers["X-TBA-Auth-Key"] = api_key
        
        # Clear previous results
        for widget in self.stats_results_frame.winfo_children():
            widget.destroy()
            
        self.stats_status_var.set("Fetching match data from TBA and Statbotics...")
        self.stats_progress_var.set(10)
        self.root.update()
        
        try:
            # Create output directory if it doesn't exist
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
            
            # Step 1: Get match data from TBA
            self.stats_status_var.set("Fetching match data from The Blue Alliance...")
            self.root.update()
            
            tba_match_data = self.tba_client.get_api_data(f"/match/{match_key}")
            if not tba_match_data:
                messagebox.showerror("Error", f"Could not find match with key: {match_key}")
                self.stats_status_var.set("Error: Match not found in TBA")
                self.stats_progress_var.set(0)
                return
                
            self.stats_progress_var.set(40)
            self.root.update()
            
            # Step 2: Get match predictions from Statbotics
            self.stats_status_var.set("Fetching match predictions from Statbotics...")
            self.root.update()
            
            statbotics_match_data = self.statbotics_client.get_match_prediction(match_key)
            
            self.stats_progress_var.set(70)
            self.root.update()
            
            # Step 3: Get team data for all teams in the match
            teams = []
            # if tba_match_data and 'alliances' in tba_match_data:
            if 'red' in tba_match_data['alliances'] and 'team_keys' in tba_match_data['alliances']['red']:
                teams.extend([team.replace('frc', '') for team in tba_match_data['alliances']['red']['team_keys']])
            if 'blue' in tba_match_data['alliances'] and 'team_keys' in tba_match_data['alliances']['blue']:
                teams.extend([team.replace('frc', '') for team in tba_match_data['alliances']['blue']['team_keys']])
            #         teams.extend([team.replace('frc', '') for team in tba_match_data['alliances']['red']['team_keys']])
            #     if 'blue' in tba_match_data['alliances'] and 'team_keys' in tba_match_data['alliances']['blue']:
            #         teams.extend([team.replace('frc', '') for team in tba_match_data['alliances']['blue']['team_keys']])

            # Get team info for all teams involved
            team_data = {}
            teams_opr =  self.tba_client.get_api_data(f"/event/{event_key}/oprs")
            teams_epa = self.statbotics_client.fetch_team_epa([201, 302])
            print(teams_opr)
            for team in teams:
                team_info = self.tba_client.get_api_data(f"/team/frc{team}")
                if team_info:
                    team_data[team] = {
                        "nickname": team_info.get('nickname', ''),
                        "name": team_info.get('name', ''),
                        "city": team_info.get('city', ''),
                        "state_prov": team_info.get('state_prov', ''),
                        "country": team_info.get('country', ''),
                        "opr": teams_opr.get("oprs", {}).get("frc" + team, 0),
                        "epa": teams_epa[0]
                    }
            
            # Step 4: Combine data into desired output format
            combined_data = self.create_combined_match_data(tba_match_data, statbotics_match_data, team_data)
            
            # Step 5: Save the combined data
            output_filename = os.path.join(output_dir, f"{match_key}_combined.json")
            with open(output_filename, 'w') as f:
                json.dump(combined_data, f, indent=4)
                
            # Step 6: Turn it into csv : results.csv
            
            # Replace the existing CSV creation code with this updated version
            csv_filename = os.path.join(output_dir, "results.csv")
            with open(csv_filename, 'w', newline='') as csvfile:
                # Define columns for match results
                fieldnames = [
                    'match_key', 'match_name', 'winner',
                    'red_score', 'blue_score', 
                    'red_auto_points', 'blue_auto_points',
                    'red_teleop_points', 'blue_teleop_points',
                    'red_endgame_points', 'blue_endgame_points',
                    'red_foul_points', 'blue_foul_points',
                    'red_total_pieces', 'blue_total_pieces',
                    'red_auto_bonus', 'blue_auto_bonus', 
                    'red_coral_bonus', 'blue_coral_bonus',
                    'red_barge_bonus', 'blue_barge_bonus'
                ]
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                
                # Extract match result data
                writer.writerow({
                    'match_key': combined_data.get('key', ''),
                    'match_name': combined_data.get('match_name', ''),
                    'winner': combined_data.get('result', {}).get('winner', ''),
                    'red_score': combined_data.get('result', {}).get('red_score', 0),
                    'blue_score': combined_data.get('result', {}).get('blue_score', 0),
                    'red_auto_points': combined_data.get('result', {}).get('red_auto_points', 0),
                    'blue_auto_points': combined_data.get('result', {}).get('blue_auto_points', 0),
                    'red_teleop_points': combined_data.get('result', {}).get('red_teleop_points', 0),
                    'blue_teleop_points': combined_data.get('result', {}).get('blue_teleop_points', 0),
                    'red_endgame_points': combined_data.get('result', {}).get('red_endgame_points', 0),
                    'blue_endgame_points': combined_data.get('result', {}).get('blue_endgame_points', 0),
                    'red_foul_points': combined_data.get('result', {}).get('red_foul_points', 0),
                    'blue_foul_points': combined_data.get('result', {}).get('blue_foul_points', 0),
                    'red_total_pieces': combined_data.get('result', {}).get('red_total_pieces', 0),
                    'blue_total_pieces': combined_data.get('result', {}).get('blue_total_pieces', 0),
                    'red_auto_bonus': combined_data.get('result', {}).get('red_auto_bonus', False),
                    'blue_auto_bonus': combined_data.get('result', {}).get('blue_auto_bonus', False),
                    'red_coral_bonus': combined_data.get('result', {}).get('red_coral_bonus', False),
                    'blue_coral_bonus': combined_data.get('result', {}).get('blue_coral_bonus', False),
                    'red_barge_bonus': combined_data.get('result', {}).get('red_barge_bonus', False),
                    'blue_barge_bonus': combined_data.get('result', {}).get('blue_barge_bonus', False)
                })

            # Create a second CSV specifically for Team Insights
            insights_filename = os.path.join(output_dir, "Team_Insights.csv")
            with open(insights_filename, 'w', newline='') as csvfile:
                fieldnames = [
                    'team', 'nickname', 'city', 'state', 'country', 
                    'opr', 'epa_current', 'epa_recent', 'epa_mean', 'epa_max',
                    'wins', 'losses', 'ties', 'win_rate'
                ]
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                
                # Write data for each team
                for team, data in team_data.items():
                    # Extract data safely with defaults
                    epa_data = data.get('epa', [{}, {}])
                    epa = epa_data[0] if len(epa_data) > 0 else {}
                    record = epa_data[1] if len(epa_data) > 1 else {}
                    
                    writer.writerow({
                        'team': team,
                        'nickname': data.get('nickname', ''),
                        'city': data.get('city', ''),
                        'state': data.get('state_prov', ''),
                        'country': data.get('country', ''),
                        'opr': data.get('opr', 0),
                        'epa_current': epa.get('current', 0),
                        'epa_recent': epa.get('recent', 0),
                        'epa_mean': epa.get('mean', 0),
                        'epa_max': epa.get('max', 0),
                        'wins': record.get('wins', 0),
                        'losses': record.get('losses', 0),
                        'ties': record.get('ties', 0),
                        'win_rate': record.get('winrate', 0)
                    })

            # Update status to include both files
            self.stats_status_var.set(f"Done! Combined match data and team insights saved.")
            self.stats_progress_var.set(100)

            # Add information about the Team Insights file in the UI
            results_label = ttk.Label(
                self.stats_results_frame, 
                text=f"Data saved to:", 
                font=('Arial', 12, 'bold')
            )
            results_label.pack(anchor=tk.W, pady=(10, 5))

            path_label = ttk.Label(self.stats_results_frame, text=output_filename)
            path_label.pack(anchor=tk.W)

            insights_label = ttk.Label(self.stats_results_frame, text=insights_filename)
            insights_label.pack(anchor=tk.W)
            
            # Display the data in a preview
            results_label = ttk.Label(
                self.stats_results_frame, 
                text=f"Data saved to:", 
                font=('Arial', 12, 'bold')
            )
            results_label.pack(anchor=tk.W, pady=(10, 5))
            
            path_label = ttk.Label(self.stats_results_frame, text=output_filename)
            path_label.pack(anchor=tk.W)
            
            # Create a text widget to display the JSON data
            preview_frame = ttk.LabelFrame(self.stats_results_frame, text="Preview")
            preview_frame.pack(fill=tk.BOTH, expand=True, pady=10)
            
            preview_text = tk.Text(preview_frame, wrap=tk.NONE, height=15)
            preview_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            
            scrollbar_y = ttk.Scrollbar(preview_frame, orient=tk.VERTICAL, command=preview_text.yview)
            scrollbar_y.pack(side=tk.RIGHT, fill=tk.Y)
            preview_text.configure(yscrollcommand=scrollbar_y.set)
            
            scrollbar_x = ttk.Scrollbar(self.stats_results_frame, orient=tk.HORIZONTAL, command=preview_text.xview)
            scrollbar_x.pack(fill=tk.X, before=preview_frame)
            preview_text.configure(xscrollcommand=scrollbar_x.set)
            
            # Insert the JSON data
            preview_text.insert(tk.END, json.dumps(combined_data, indent=4))
            preview_text.configure(state=tk.DISABLED)  # Make it read-only
            
            # Open folder button
            open_button = ttk.Button(
                self.stats_results_frame, 
                text="Open Output Folder", 
                command=lambda: os.startfile(os.path.dirname(output_filename))
            )
            open_button.pack(pady=10)
            
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
            self.stats_status_var.set(f"Error: {str(e)}")
            self.stats_progress_var.set(0)

    def create_combined_match_data(self, tba_match_data, statbotics_match_data, team_data):
        """Create a combined data structure from TBA and Statbotics data."""
        combined_data = {
            "key": tba_match_data.get("key", ""),
            "event": tba_match_data.get("event_key", ""),
            "elim": tba_match_data.get("comp_level", "") != "qm",
            "comp_level": tba_match_data.get("comp_level", ""),
            "match_number": tba_match_data.get("match_number", 0),
            "match_name": self.format_match_name(tba_match_data),
            "status": "Completed" if tba_match_data.get("actual_time", 0) > 0 else "Scheduled"
        }
        
        # Add alliance information
        if 'alliances' in tba_match_data:
            alliances = {"red": {}, "blue": {}}
            
            for color in ["red", "blue"]:
                if color in tba_match_data['alliances']:
                    alliance_data = tba_match_data['alliances'][color]
                    alliances[color] = {
                        "team_keys": [team.replace('frc', '') for team in alliance_data.get('team_keys', [])],
                        "surrogate_team_keys": alliance_data.get('surrogate_team_keys', []),
                        "dq_team_keys": alliance_data.get('dq_team_keys', [])
                    }
            
            combined_data["alliances"] = alliances
        
        # Add prediction data from Statbotics
        if statbotics_match_data:
            combined_data["pred"] = {
                "winner": statbotics_match_data.get('winner', ''),
                "red_win_prob": statbotics_match_data.get('red_win_prob', 0),
                "red_score": statbotics_match_data.get('red_score', 0),
                "blue_score": statbotics_match_data.get('blue_score', 0),
            }

            # Add RP predictions if available
            if 'red_auto' in statbotics_match_data:
                combined_data["pred"]["red_auto_rp"] = statbotics_match_data.get('red_auto', 0)
                combined_data["pred"]["blue_auto_rp"] = statbotics_match_data.get('blue_auto', 0)
                combined_data["pred"]["red_rp_1"] = statbotics_match_data.get('red_auto', 0)
                combined_data["pred"]["blue_rp_1"] = statbotics_match_data.get('blue_auto', 0)

            if 'red_rp_1' in statbotics_match_data:
                combined_data["pred"]["red_rp_1"] = statbotics_match_data.get('red_rp_1', 0)
                combined_data["pred"]["blue_rp_1"] = statbotics_match_data.get('blue_rp_1', 0)

            if 'red_rp_2' in statbotics_match_data:
                combined_data["pred"]["red_rp_2"] = statbotics_match_data.get('red_rp_2', 0)
                combined_data["pred"]["blue_rp_2"] = statbotics_match_data.get('blue_rp_2', 0)
                combined_data["pred"]["red_coral_rp"] = statbotics_match_data.get('red_rp_2', 0)
                combined_data["pred"]["blue_coral_rp"] = statbotics_match_data.get('blue_rp_2', 0)

            if 'red_rp_3' in statbotics_match_data:
                combined_data["pred"]["red_rp_3"] = statbotics_match_data.get('red_rp_3', 0)
                combined_data["pred"]["blue_rp_3"] = statbotics_match_data.get('blue_rp_3', 0)
                combined_data["pred"]["red_barge_rp"] = statbotics_match_data.get('red_rp_3', 0)
                combined_data["pred"]["blue_barge_rp"] = statbotics_match_data.get('blue_rp_3', 0)
        
        # Add match results from TBA
        if 'score_breakdown' in tba_match_data and tba_match_data['score_breakdown']:
            score_data = tba_match_data['score_breakdown']
            result = {
                "winner": tba_match_data.get('winning_alliance', ''),
            }
            
            # Add scores and key game-agnostic data for each alliance
            for color in ["red", "blue"]:
                if color in score_data:
                    alliance_score = score_data[color]
                    
                    # Basic scoring
                    result[f"{color}_score"] = alliance_score.get('totalPoints', 0)
                    result[f"{color}_no_foul"] = result[f"{color}_score"] - alliance_score.get('foulPoints', 0)
                    
                    # Auto, Teleop, Endgame
                    result[f"{color}_auto_points"] = alliance_score.get('autoPoints', 0)
                    result[f"{color}_teleop_points"] = alliance_score.get('teleopPoints', 0)
                    result[f"{color}_endgame_points"] = alliance_score.get('endGameBargePoints', 0)
                    
                    # Penalties
                    result[f"{color}_foul_count"] = alliance_score.get('foulCount', 0)
                    result[f"{color}_tech_foul_count"] = alliance_score.get('techFoulCount', 0)
                    result[f"{color}_foul_points"] = alliance_score.get('foulPoints', 0)
                    result[f"{color}_adjust_points"] = alliance_score.get('adjustPoints', 0)
                    
                    # Robot status
                    result[f"{color}_robot1_auto"] = alliance_score.get('autoLineRobot1', '')
                    result[f"{color}_robot2_auto"] = alliance_score.get('autoLineRobot2', '')
                    result[f"{color}_robot3_auto"] = alliance_score.get('autoLineRobot3', '')
                    
                    result[f"{color}_robot1_endgame"] = alliance_score.get('endGameRobot1', '')
                    result[f"{color}_robot2_endgame"] = alliance_score.get('endGameRobot2', '')
                    result[f"{color}_robot3_endgame"] = alliance_score.get('endGameRobot3', '')
                    
                    # Ranking points and achievements
                    result[f"{color}_rp"] = alliance_score.get('rp', 0)
                    result[f"{color}_auto_bonus"] = alliance_score.get('autoBonusAchieved', False)
                    result[f"{color}_coral_bonus"] = alliance_score.get('coralBonusAchieved', False)
                    result[f"{color}_barge_bonus"] = alliance_score.get('bargeBonusAchieved', False)
                    
                    # Standard RP translations
                    result[f"{color}_rp_1"] = alliance_score.get('autoBonusAchieved', False)
                    result[f"{color}_rp_2"] = alliance_score.get('coralBonusAchieved', False) 
                    result[f"{color}_rp_3"] = alliance_score.get('bargeBonusAchieved', False)
                    
                    # Game pieces
                    if 'teleopCoralCount' in alliance_score:
                        result[f"{color}_teleop_pieces"] = alliance_score.get('teleopCoralCount', 0)
                    if 'autoCoralCount' in alliance_score:
                        result[f"{color}_auto_pieces"] = alliance_score.get('autoCoralCount', 0)
                        result[f"{color}_total_pieces"] = result[f"{color}_teleop_pieces"] + result[f"{color}_auto_pieces"]
                    
                    # Check for penalties
                    for penalty in ['g206Penalty', 'g410Penalty', 'g418Penalty', 'g428Penalty', 'foulCount']:
                        if penalty in alliance_score:
                            result[f"{color}_{penalty}"] = alliance_score.get(penalty, False)
            
            combined_data["result"] = result
        
        # Add team data
        combined_data["tba"] = {
            "teams": team_data
        }
        
        return combined_data

    def format_match_name(self, match_data):
        """Format the match name based on its type and number."""
        comp_level = match_data.get('comp_level', 'qm')
        match_number = match_data.get('match_number', 1)
        
        if comp_level == 'qm':
            return f"Qual {match_number}"
        elif comp_level == 'qf':
            set_number = match_data.get('set_number', 1)
            return f"Quarterfinal {set_number} Match {match_number}"
        elif comp_level == 'sf':
            set_number = match_data.get('set_number', 1)
            return f"Semifinal {set_number} Match {match_number}"
        elif comp_level == 'f':
            return f"Final {match_number}"
        else:
            return f"{comp_level.upper()} {match_number}"

    def tba_fetch_and_convert(self):
        # Get input values
        api_key = self.tba_api_key_var.get().strip()
        event_key = self.tba_event_key_var.get().strip()
        output_dir = self.tba_output_dir_var.get().strip()
        update_existing = self.tba_update_existing.get()
        
        # Validate inputs
        if not api_key:
            messagebox.showerror("Error", "Please enter a TBA API key")
            return
            
        if not event_key:
            messagebox.showerror("Error", "Please enter an event key")
            return
            
        # Save settings for future use
        self.save_settings()
        
        # Update client API key
        self.tba_client.headers["X-TBA-Auth-Key"] = api_key
        
        # Clear previous results
        for widget in self.tba_results_frame.winfo_children():
            widget.destroy()
            
        self.tba_status_var.set("Fetching data from The Blue Alliance...")
        self.tba_progress_var.set(10)
        self.root.update()
        
        try:
            # Determine output directory
            if update_existing:
                # Use event_key directly as the folder name for updating existing files
                event_dir = os.path.join(output_dir, event_key)
            else:
                # Create event-specific directory with timestamp
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                event_dir = os.path.join(output_dir, f"{event_key}_{timestamp}")
            
            # Fetch data
            event_data = self.tba_client.get_event_data(event_key)
            
            if not event_data['event_info']:
                messagebox.showerror("Error", f"Could not find event with key: {event_key}")
                self.tba_status_var.set("Error: Event not found")
                self.tba_progress_var.set(0)
                return
                
            self.tba_status_var.set("Converting data to CSV...")
            self.tba_progress_var.set(50)
            self.root.update()
            
            # Convert to CSV
            csv_files = self.tba_client.convert_to_csv(event_data, event_dir)
            
            if update_existing:
                self.tba_status_var.set(f"Done! Updated {len(csv_files)} CSV files.")
            else:
                self.tba_status_var.set(f"Done! Created {len(csv_files)} CSV files.")
            self.tba_progress_var.set(100)
            
            # Show results
            results_label = ttk.Label(
                self.tba_results_frame, 
                text=f"Data saved to:", 
                font=('Arial', 12, 'bold')
            )
            results_label.pack(anchor=tk.W, pady=(10, 5))
            
            path_label = ttk.Label(self.tba_results_frame, text=event_dir)
            path_label.pack(anchor=tk.W)
            
            files_label = ttk.Label(
                self.tba_results_frame, 
                text=f"Files created/updated:", 
                font=('Arial', 12, 'bold')
            )
            files_label.pack(anchor=tk.W, pady=(10, 5))
            
            for file_path in csv_files:
                file_name = os.path.basename(file_path)
                file_label = ttk.Label(self.tba_results_frame, text=file_name)
                file_label.pack(anchor=tk.W)
                
            # Open folder button
            open_button = ttk.Button(
                self.tba_results_frame, 
                text="Open Output Folder", 
                command=lambda: os.startfile(event_dir)
            )
            open_button.pack(pady=10)
            
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
            self.tba_status_var.set(f"Error: {str(e)}")
            self.tba_progress_var.set(0)

    def generate_team_insights(self):
        # Fetch teams for the event
        event_key = self.stats_event_key_var.get().strip()
        if not event_key:
            messagebox.showerror("Error", "Please enter an event key")
            return

        teams = self.tba_client.fetch_teams(event_key)
        if not teams:
            messagebox.showerror("Error", "No teams found for the event")
            return

        # Define output directory
        output_dir = self.stats_output_dir_var.get().strip()
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        # Fetch team data
        team_data = {}
        teams_opr = self.tba_client.get_api_data(f"/event/{event_key}/oprs")
        teams_epa = self.statbotics_client.fetch_team_epa(teams)
        for i, team in enumerate(teams):
            team_info = self.tba_client.get_api_data(f"/team/frc{team}")
            if team_info:
                team_data[team] = {
                    "nickname": team_info.get('nickname', ''),
                    "city": team_info.get('city', ''),
                    "state_prov": team_info.get('state_prov', ''),
                    "country": team_info.get('country', ''),
                    "opr": teams_opr.get("oprs", {}).get(f"frc{team}", 0),
                    "epa": teams_epa[i] if i < len(teams_epa) else {}
                }

        # Write insights to CSV
        insights_filename = os.path.join(output_dir, "Team_Insights.csv")
        with open(insights_filename, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = [
                'team', 'nickname', 'city', 'state', 'country', 
                'opr', 'epa_current', 'epa_recent', 'epa_mean', 'epa_max',
                'wins', 'losses', 'ties', 'win_rate'
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()

            for team, data in team_data.items():
                epa_data = data.get('epa', {})
                record = epa_data.get('record', {})
                writer.writerow({
                    'team': team,
                    'nickname': data.get('nickname', ''),
                    'city': data.get('city', ''),
                    'state': data.get('state_prov', ''),
                    'country': data.get('country', ''),
                    'opr': data.get('opr', 0),
                    'epa_current': epa_data.get('norm_epa', 0),
                    'epa_recent': epa_data.get('recent_epa', 0),
                    'epa_mean': epa_data.get('mean_epa', 0),
                    'epa_max': epa_data.get('max_epa', 0),
                    'wins': record.get('wins', 0),
                    'losses': record.get('losses', 0),
                    'ties': record.get('ties', 0),
                    'win_rate': record.get('winrate', 0)
                })

        # Update status
        self.stats_status_var.set(f"Done! Team insights saved to {insights_filename}")
        self.stats_progress_var.set(100)

            


if __name__ == "__main__":
    # Create root window
    root = tk.Tk()
    app = ScoutingApp(root)
    root.mainloop()

