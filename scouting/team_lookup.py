import os
import requests
import pandas as pd
from rich.console import Console
from rich.prompt import Prompt, Confirm
from rich.table import Table
from textblob import TextBlob  # For sentiment analysis

console = Console()

# Constants for external APIs
STATBOTICS_API = "https://api.statbotics.io/v2/team/"
BLUE_ALLIANCE_API = "https://www.thebluealliance.com/api/v3/team/"
BLUE_ALLIANCE_AUTH_KEY = "2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W"  # Replace with your API key

def analyze_feedback(comments):
    """Analyze feedback comments and classify them as positive or negative."""
    positive_comments = []
    negative_comments = []

    for comment in comments:
        if not comment or pd.isna(comment):
            continue
        sentiment = TextBlob(comment).sentiment.polarity
        if sentiment > 0:
            positive_comments.append(comment)
        else:
            negative_comments.append(comment)

    return positive_comments, negative_comments

def fetch_team_history(team_number):
    """Fetch team history from Statbotics and The Blue Alliance APIs."""
    history = {}

    # Fetch data from Statbotics API
    try:
        response = requests.get(f"{STATBOTICS_API}{team_number}")
        if response.status_code == 200:
            history["statbotics"] = response.json()
        else:
            console.print(f"[yellow]Statbotics API returned status {response.status_code} for team {team_number}[/yellow]")
    except Exception as e:
        console.print(f"[red]Error fetching data from Statbotics API: {e}[/red]")

    # Fetch data from The Blue Alliance API
    try:
        headers = {"X-TBA-Auth-Key": BLUE_ALLIANCE_AUTH_KEY}
        response = requests.get(f"{BLUE_ALLIANCE_API}frc{team_number}", headers=headers)
        if response.status_code == 200:
            history["blue_alliance"] = response.json()
        else:
            console.print(f"[yellow]The Blue Alliance API returned status {response.status_code} for team {team_number}[/yellow]")
    except Exception as e:
        console.print(f"[red]Error fetching data from The Blue Alliance API: {e}[/red]")

    return history

def display_team_profile(team_number, team_data, positive_comments, negative_comments, history):
    """Display a detailed profile for the team."""
    console.clear()
    console.print(f"[bold cyan]Team {team_number} Profile[/bold cyan]", justify="center")

    # Display basic stats
    table = Table(title="Team Statistics", box="SIMPLE")
    table.add_column("Metric", style="cyan")
    table.add_column("Value", style="green")

    for key, value in team_data.items():
        table.add_row(key, str(value))

    console.print(table)

    # Display feedback
    console.print("\n[bold green]Positive Feedback:[/bold green]")
    for comment in positive_comments:
        console.print(f"- {comment}")

    console.print("\n[bold red]Negative Feedback:[/bold red]")
    for comment in negative_comments:
        console.print(f"- {comment}")

    # Display external history
    if history:
        console.print("\n[bold yellow]External History:[/bold yellow]")
        if "statbotics" in history:
            console.print("[cyan]Statbotics Data:[/cyan]")
            console.print(history["statbotics"])
        if "blue_alliance" in history:
            console.print("[cyan]The Blue Alliance Data:[/cyan]")
            console.print(history["blue_alliance"])

    console.print("\n[italic]Press Enter to return to the main menu...[/italic]")
    input()

def team_lookup(data_path):
    """Main function for team lookup."""
    # Load scouting data
    try:
        df = pd.read_csv(data_path)
    except Exception as e:
        console.print(f"[red]Error loading data: {e}[/red]")
        return

    # Ask for team number
    team_number = Prompt.ask("Enter the team number to look up")

    # Filter data for the team
    team_data = df[df["teamNumber"] == team_number]
    if team_data.empty:
        console.print(f"[red]No data found for team {team_number}[/red]")
        return

    # Aggregate team stats
    team_stats = {
        "Matches Played": len(team_data),
        "Average Score": round(team_data["total_score"].mean(), 2) if "total_score" in team_data.columns else "N/A",
        "Highest Score": team_data["total_score"].max() if "total_score" in team_data.columns else "N/A",
        "Autonomous Average": round(team_data["auton_total"].mean(), 2) if "auton_total" in team_data.columns else "N/A",
        "Teleop Average": round(team_data["teleop_total"].mean(), 2) if "teleop_total" in team_data.columns else "N/A",
        "Endgame Average": round(team_data["endgame_total"].mean(), 2) if "endgame_total" in team_data.columns else "N/A",
    }

    # Analyze feedback
    comments = team_data["endgame_Comments"].tolist() if "endgame_Comments" in team_data.columns else []
    positive_comments, negative_comments = analyze_feedback(comments)

    # Ask if external APIs should be used
    use_wifi = Confirm.ask("Do you want to fetch additional data from external APIs?")
    history = fetch_team_history(team_number) if use_wifi else {}

    # Display the team profile
    display_team_profile(team_number, team_stats, positive_comments, negative_comments, history)

if __name__ == "__main__":
    # Default data path
    data_path = os.path.join(os.path.expanduser("~"), "AppData", "Local", "ScoutOps", "results.csv")
    if not os.path.exists(data_path):
        console.print(f"[red]Data file not found at {data_path}[/red]")
    else:
        team_lookup(data_path)
