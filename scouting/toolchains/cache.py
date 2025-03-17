import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import json
import sys
import time
import csv
from datetime import datetime
from typing import Dict, List, Optional, Union, Any, Set
import requests
import hashlib

# Terminal UI elements
import argparse
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TimeElapsedColumn
from rich.prompt import Prompt, Confirm
from rich.table import Table
from rich.markdown import Markdown
from rich.align import Align
from rich.text import Text
from rich import box

console = Console()

# ASCII Art for PyIntel Scoutz
PYINTEL_LOGO = """
  _____            _           _            _      _____                          _         
 |  __ \          (_)         | |          | |    / ____|                        | |        
 | |__) |  _   _   _   _ __   | |_    ___  | |   | (___     ___    ___    _   _  | |_   ____
 |  ___/  | | | | | | | '_ \  | __|  / _ \ | |    \___ \   / __|  / _ \  | | | | | __| |_  /
 | |      | |_| | | | | | | | | |_  |  __/ | |    ____) | | (__  | (_) | | |_| | | |_   / / 
 |_|       \__, | |_| |_| |_|  \__|  \___| |_|   |_____/   \___|  \___/   \__,_|  \__| /___|
            __/ |                                                                           
           |___/                                                                            
"""

POWERED_BY = "Powered by PyIntel AI"
# Global set to store filtered teams
FILTERED_TEAMS = set()

def display_welcome_screen():
    """Display the welcome screen with logo and info"""
    console.clear()
    console.print(f"[bold cyan]{PYINTEL_LOGO}[/bold cyan]")
    console.print(f"[italic dim]{POWERED_BY}[/italic dim]", justify="center")
    console.print("\n[bold green]Welcome to PyIntel Scoutz - FRC Scouting Analysis Tool[/bold green]", justify="center")
    console.print("[yellow]Analyze your scouting data and generate powerful insights for your team[/yellow]\n", justify="center")

def analyze_scouting_data(data_path: Optional[str] = None, data_str: Optional[str] = None) -> Dict:
    """
    Analyze robotics scouting data to identify team strengths across autonomous, teleop, and endgame.
    
    Parameters:
    -----------
    data_path : str, optional
        Path to CSV or JSON file containing scouting data
    data_str : str, optional
        String containing CSV or JSON data
    
    Returns:
    --------
    dict
        Dictionary containing analysis results
    """
    with console.status("[bold green]Loading and processing data...[/bold green]", spinner="dots"):
        # Detect file type and load data appropriately
        if data_path:
            try:
                file_ext = os.path.splitext(data_path)[1].lower()
                if file_ext == '.csv':
                    df = pd.read_csv(data_path)
                    # Convert teamNumber to string if it's not already
                    if df['teamNumber'].dtype != 'object':
                        df['teamNumber'] = df['teamNumber'].astype(str)
                elif file_ext == '.json':
                    with open(data_path, 'r') as f:
                        data = json.load(f)
                        df = pd.DataFrame(data)
                else:
                    console.print(f"[bold red]Unsupported file format: {file_ext}[/bold red]")
                    return {}
            except Exception as e:
                console.print(f"[bold red]Error loading data file: {e}[/bold red]")
                return {}
        elif data_str:
            try:
                # Try to determine if the string is CSV or JSON
                if data_str.strip().startswith('{') or data_str.strip().startswith('['):
                    # Looks like JSON
                    data = json.loads(data_str)
                    df = pd.DataFrame(data)
                else:
                    # Assume CSV
                    import io
                    df = pd.read_csv(io.StringIO(data_str))
                    # Convert teamNumber to string if it's not already
                    if df['teamNumber'].dtype != 'object':
                        df['teamNumber'] = df['teamNumber'].astype(str)
            except Exception as e:
                console.print(f"[bold red]Error parsing data string: {e}[/bold red]")
                return {}
        else:
            console.print("[bold red]Either data_path or data_str must be provided[/bold red]")
            return {}
        
        # Process the data based on format
        try:
            # For CSV data, we already have flat structure with prefixed columns
            # Convert boolean columns
            bool_columns = [
                'auton_LeftBarge',
                'teleop_Defense',
                'endgame_Deep_Climb',
                'endgame_Shallow_Climb',
                'endgame_Park'
            ]
            
            for col in bool_columns:
                if col in df.columns:
                    # Handle various forms of boolean representation
                    df[col] = df[col].map(lambda x: str(x).upper() in ('TRUE', 'YES', 'Y', '1', 'T', 'TRUE'))
            
            # Calculate phase scores
            df['auton_total'] = 0
            
            # Autonomous scoring
            for level in range(1, 5):
                col = f'auton_CoralScoringLevel{level}'
                if col in df.columns:
                    df['auton_total'] += df[col].fillna(0) * level
            
            # Add specific autonomous points
            if 'auton_AlgaeScoringProcessor' in df.columns:
                df['auton_total'] += df['auton_AlgaeScoringProcessor'].fillna(0) * 3
            
            if 'auton_AlgaeScoringBarge' in df.columns:
                df['auton_total'] += df['auton_AlgaeScoringBarge'].fillna(0) * 2
            
            # Add bonus point for left barge in auton
            if 'auton_LeftBarge' in df.columns:
                df.loc[df['auton_LeftBarge'] == True, 'auton_total'] += 5
            
            # Calculate teleop points
            df['teleop_total'] = 0
            
            # Teleop coral scoring
            for level in range(1, 5):
                col = f'teleop_CoralScoringLevel{level}'
                if col in df.columns:
                    df['teleop_total'] += df[col].fillna(0) * level
            
            # Teleop algae scoring
            if 'teleop_AlgaeScoringProcessor' in df.columns:
                df['teleop_total'] += df['teleop_AlgaeScoringProcessor'].fillna(0) * 3
                
            if 'teleop_AlgaeScoringBarge' in df.columns:
                df['teleop_total'] += df['teleop_AlgaeScoringBarge'].fillna(0) * 2
            
            # Calculate endgame points
            df['endgame_total'] = 0
            if 'endgame_Deep_Climb' in df.columns:
                df.loc[df['endgame_Deep_Climb'] == True, 'endgame_total'] += 15  # Deep climb worth 15 points
            if 'endgame_Shallow_Climb' in df.columns:
                df.loc[df['endgame_Shallow_Climb'] == True, 'endgame_total'] += 10  # Shallow climb worth 10 points
            if 'endgame_Park' in df.columns:
                df.loc[df['endgame_Park'] == True, 'endgame_total'] += 5  # Park worth 5 points
            
            # Calculate defense value (binary for now)
            df['defense_value'] = 0
            if 'teleop_Defense' in df.columns:
                df['defense_value'] = df['teleop_Defense'].astype(int) * 5  # Assign 5 points for playing defense
            
            # Calculate total match score
            df['total_score'] = df['auton_total'] + df['teleop_total'] + df['endgame_total'] + df['defense_value']
            
            # Group by team number to get team performance stats
            team_stats = df.groupby('teamNumber').agg({
                'auton_total': ['mean', 'std', 'max'],
                'teleop_total': ['mean', 'std', 'max'],
                'endgame_total': ['mean', 'std', 'max'],
                'defense_value': ['mean'],
                'total_score': ['mean', 'std', 'max', 'count']
            })
            
            # Make the column names more readable
            team_stats.columns = [f"{col[0]}_{col[1]}" for col in team_stats.columns]
            
            # Calculate consistency (lower std dev is more consistent)
            team_stats['consistency'] = 1 / (team_stats['total_score_std'] + 1)  # Add 1 to avoid division by zero
            
            # Identify team strengths
            team_strengths = {}
            
            # Filter out teams that should be excluded
            global FILTERED_TEAMS
            valid_teams = [team for team in team_stats.index if team not in FILTERED_TEAMS]
            filtered_team_stats = team_stats.loc[valid_teams]
            
            # Best autonomous teams (top 5)
            best_auton = filtered_team_stats.sort_values('auton_total_mean', ascending=False).head(5)
            team_strengths['best_auton_teams'] = best_auton.index.tolist()
            
            # Best teleop teams (top 5)
            best_teleop = filtered_team_stats.sort_values('teleop_total_mean', ascending=False).head(5)
            team_strengths['best_teleop_teams'] = best_teleop.index.tolist()
            
            # Best endgame teams (top 5)
            best_endgame = filtered_team_stats.sort_values('endgame_total_mean', ascending=False).head(5)
            team_strengths['best_endgame_teams'] = best_endgame.index.tolist()
            
            # Best defense teams
            best_defense = filtered_team_stats.sort_values('defense_value_mean', ascending=False)
            best_defense = best_defense[best_defense['defense_value_mean'] > 0].head(5)
            team_strengths['best_defense_teams'] = best_defense.index.tolist()
            
            # Most consistent teams (top 5)
            most_consistent = filtered_team_stats.sort_values('consistency', ascending=False).head(5)
            team_strengths['most_consistent_teams'] = most_consistent.index.tolist()
            
            # Best overall teams (by average score, top 5)
            best_overall = filtered_team_stats.sort_values('total_score_mean', ascending=False).head(5)
            team_strengths['best_overall_teams'] = best_overall.index.tolist()
            
            # Create detailed team profiles
            team_profiles = {}
            for team in df['teamNumber'].unique():
                team_data = df[df['teamNumber'] == team]
                if team not in team_stats.index:
                    continue  # Skip if team has no stats (shouldn't happen, but just in case)
                
                team_stats_row = team_stats.loc[team]
                
                profile = {
                    'team_number': team,
                    'matches_played': int(team_stats_row['total_score_count']),
                    'average_score': round(team_stats_row['total_score_mean'], 2),
                    'highest_score': team_stats_row['total_score_max'],
                    'auton_average': round(team_stats_row['auton_total_mean'], 2),
                    'teleop_average': round(team_stats_row['teleop_total_mean'], 2),
                    'endgame_average': round(team_stats_row['endgame_total_mean'], 2),
                    'plays_defense': team_stats_row['defense_value_mean'] > 0,
                    'consistency_rating': round(team_stats_row['consistency'] * 10, 2),  # Scale for readability
                    'climbing_percentage': calculate_climbing_percentage(team_data),
                    'comments': team_data['endgame_Comments'].tolist() if 'endgame_Comments' in team_data.columns else [],
                    'filtered': team in FILTERED_TEAMS  # Flag if team is filtered
                }
                
                # Add performance breakdown
                profile['performance_breakdown'] = {
                    'auton': round((team_stats_row['auton_total_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0,
                    'teleop': round((team_stats_row['teleop_total_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0,
                    'endgame': round((team_stats_row['endgame_total_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0,
                    'defense': round((team_stats_row['defense_value_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0
                }
                
                team_profiles[team] = profile
        except Exception as e:
            console.print(f"[bold red]Error processing data: {e}[/bold red]")
            import traceback
            traceback.print_exc()
            return {}
    
    return {
        'team_stats': team_stats,
        'team_strengths': team_strengths,
        'team_profiles': team_profiles,
        'raw_data': df
    }

def calculate_climbing_percentage(team_data):
    """Calculate the percentage of matches where a team successfully climbed"""
    total_matches = len(team_data)
    if total_matches == 0:
        return 0
    
    climbs = 0
    if 'endgame_Deep_Climb' in team_data.columns:
        climbs += team_data['endgame_Deep_Climb'].sum()
    if 'endgame_Shallow_Climb' in team_data.columns:
        climbs += team_data['endgame_Shallow_Climb'].sum()
    
    return round((climbs / total_matches) * 100, 2)

def manage_team_filters(team_profiles):
    """Interface for managing team filters"""
    global FILTERED_TEAMS
    
    console.clear()
    console.print("[bold cyan]TEAM FILTER MANAGEMENT[/bold cyan]", justify="center")
    
    while True:
        # Show current filters
        console.print("\n[bold yellow]Currently Filtered Teams:[/bold yellow]")
        if FILTERED_TEAMS:
            for team in sorted(FILTERED_TEAMS):
                console.print(f" - Team {team}")
        else:
            console.print(" - No teams currently filtered")
        
        # Show options
        console.print("\n[bold green]Filter Options:[/bold green]")
        console.print("1. Add team to filter")
        console.print("2. Remove team from filter")
        console.print("3. Clear all filters")
        console.print("4. Back to main menu")
        
        choice = Prompt.ask("Select option", choices=["1", "2", "3", "4"], default="1")
        
        if choice == "1":
            # Show available teams
            available_teams = sorted(list(team_profiles.keys()))
            
            console.print("\n[cyan]Available Teams:[/cyan]")
            team_table = Table(show_header=False, box=box.SIMPLE)
            team_table.add_column("Teams", style="cyan")
            
            # Format teams in rows of 6
            team_rows = [available_teams[i:i+6] for i in range(0, len(available_teams), 6)]
            for row in team_rows:
                team_table.add_row(" ".join(row))
            
            console.print(team_table)
            
            # Get team to filter
            team = Prompt.ask("Enter team number to filter")
            
            if team in team_profiles:
                FILTERED_TEAMS.add(team)
                console.print(f"[green]Team {team} added to filters[/green]")
            else:
                console.print(f"[bold red]Team {team} not found in dataset![/bold red]")
        
        elif choice == "2":
            if not FILTERED_TEAMS:
                console.print("[yellow]No teams currently filtered[/yellow]")
                continue
                
            team = Prompt.ask("Enter team number to remove from filter")
            
            if team in FILTERED_TEAMS:
                FILTERED_TEAMS.remove(team)
                console.print(f"[green]Team {team} removed from filters[/green]")
            else:
                console.print(f"[bold red]Team {team} not in filter list![/bold red]")
        
        elif choice == "3":
            if Confirm.ask("Are you sure you want to clear all filters?"):
                FILTERED_TEAMS.clear()
                console.print("[green]All filters cleared[/green]")
        
        else:  # choice == "4"
            break
        
        console.print("\nPress Enter to continue...", end="")
        input()
        console.clear()
        console.print("[bold cyan]TEAM FILTER MANAGEMENT[/bold cyan]", justify="center")

def display_team_list(analysis_results):
    """Display the list of teams and their profiles"""
    console.clear()
    team_profiles = analysis_results['team_profiles']
    table = Table(title="Team List")

    table.add_column("Team Number", justify="right", style="cyan", no_wrap=True)
    table.add_column("Matches Played", justify="right", style="magenta")
    table.add_column("Average Score", justify="right", style="green")
    table.add_column("Highest Score", justify="right", style="green")
    table.add_column("Auton Average", justify="right", style="yellow")
    table.add_column("Teleop Average", justify="right", style="yellow")
    table.add_column("Endgame Average", justify="right", style="yellow")
    table.add_column("Consistency Rating", justify="right", style="blue")
    table.add_column("Climbing Percentage", justify="right", style="blue")
    table.add_column("Plays Defense", justify="right", style="red")
    table.add_column("Status", justify="center", style="white")

    # Sort teams by average score
    sorted_teams = sorted(team_profiles.items(), key=lambda x: x[1]['average_score'], reverse=True)

    for team, profile in sorted_teams:
        # Add a filtered indicator
        status = "[red]FILTERED[/red]" if profile['filtered'] else ""
        
        table.add_row(
            team,
            str(profile['matches_played']),
            str(profile['average_score']),
            str(profile['highest_score']),
            str(profile['auton_average']),
            str(profile['teleop_average']),
            str(profile['endgame_average']),
            str(profile['consistency_rating']),
            str(profile['climbing_percentage']),
            "Yes" if profile['plays_defense'] else "No",
            status
        )

    console.print(table)
    
    # Add a pause to prevent the screen from immediately clearing
    console.print("\n[italic]Press Enter to return to main menu...[/italic]")
    input()

def display_alliance_selections(analysis_results):
    """Display alliance selection recommendations"""
    console.clear()
    team_strengths = analysis_results['team_strengths']
    team_profiles = analysis_results['team_profiles']
    
    console.print("[bold cyan]ALLIANCE SELECTION RECOMMENDATIONS[/bold cyan]", justify="center")

    # Create a panel with a table inside for each category
    categories = [
        ("Best Autonomous Teams", 'best_auton_teams', 'auton_average'),
        ("Best Teleop Teams", 'best_teleop_teams', 'teleop_average'),
        ("Best Endgame Teams", 'best_endgame_teams', 'endgame_average'),
        ("Best Defense Teams", 'best_defense_teams', 'consistency_rating'),
        ("Most Consistent Teams", 'most_consistent_teams', 'consistency_rating'),
        ("Best Overall Teams", 'best_overall_teams', 'average_score')
    ]
    
    for title, key, metric in categories:
        console.print(f"\n[bold green]{title}:[/bold green]")
        
        # Create a table with more details
        table = Table(show_header=True, box=box.SIMPLE)
        table.add_column("Team", style="cyan")
        table.add_column(f"{metric.replace('_', ' ').title()}", justify="right", style="green")
        table.add_column("Matches", justify="right", style="magenta")
        table.add_column("Consistency", justify="right", style="blue")
        
        for team in team_strengths[key]:
            profile = team_profiles[team]
            table.add_row(
                team,
                str(profile[metric]),
                str(profile['matches_played']),
                str(profile['consistency_rating'])
            )
        
        console.print(table)

    # Add a visual representation of team strengths
    console.print("\n[yellow]Team Distribution Across Categories:[/yellow]")
    
    # Find teams that appear in multiple categories
    category_counts = {}
    for _, key, _ in categories:
        for team in team_strengths[key]:
            if team not in category_counts:
                category_counts[team] = 0
            category_counts[team] += 1
    
    # Show top versatile teams (appearing in multiple categories)
    versatile_teams = sorted(category_counts.items(), key=lambda x: x[1], reverse=True)[:5]
    if versatile_teams:
        console.print("\n[bold cyan]Most Versatile Teams:[/bold cyan]")
        for team, count in versatile_teams:
            if count > 1:  # Only show teams in multiple categories
                console.print(f"Team {team}: Appears in {count} categories")
    
    # Add a pause to prevent the screen from immediately clearing
    console.print("\n[italic]Press Enter to return to main menu...[/italic]")
    input()

def generate_strategy_report(analysis_results):
    """Generate a comprehensive strategy report from analysis results"""
    team_profiles = analysis_results['team_profiles']
    team_strengths = analysis_results['team_strengths']
    
    report = f"# PyIntel Scoutz Strategy Report\n\n"
    report += f"*Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n\n"
    
    report += "## Alliance Selection Recommendations\n\n"
    
    report += "### Best Autonomous Teams\n\n"
    for team in team_strengths['best_auton_teams']:
        profile = team_profiles[team]
        report += f"- **Team {team}**: {profile['auton_average']} avg pts, {profile['consistency_rating']} consistency\n"
    
    report += "\n### Best Teleop Teams\n\n"
    for team in team_strengths['best_teleop_teams']:
        profile = team_profiles[team]
        report += f"- **Team {team}**: {profile['teleop_average']} avg pts, {profile['consistency_rating']} consistency\n"
    
    report += "\n### Best Endgame Teams\n\n"
    for team in team_strengths['best_endgame_teams']:
        profile = team_profiles[team]
        report += f"- **Team {team}**: {profile['endgame_average']} avg pts, {profile['climbing_percentage']}% climbing\n"
    
    report += "\n### Best Defense Teams\n\n"
    for team in team_strengths['best_defense_teams']:
        profile = team_profiles[team]
        report += f"- **Team {team}**: {'Yes' if profile['plays_defense'] else 'No'} defense, {profile['consistency_rating']} consistency\n"
    
    report += "\n## Team Profiles\n\n"
    
    for team, profile in team_profiles.items():
        # Skip filtered teams
        if profile['filtered']:
            continue
            
        report += f"### Team {team}\n\n"
        report += f"- **Matches Played**: {profile['matches_played']}\n"
        report += f"- **Average Score**: {profile['average_score']}\n"
        report += f"- **Highest Score**: {profile['highest_score']}\n"
        report += f"- **Autonomous Average**: {profile['auton_average']}\n"
        report += f"- **Teleop Average**: {profile['teleop_average']}\n"
        report += f"- **Endgame Average**: {profile['endgame_average']}\n"
        report += f"- **Consistency Rating**: {profile['consistency_rating']}\n"
        report += f"- **Climbing Percentage**: {profile['climbing_percentage']}%\n"
        report += f"- **Plays Defense**: {'Yes' if profile['plays_defense'] else 'No'}\n\n"
        
        report += "#### Performance Breakdown\n\n"
        report += f"- Autonomous: {profile['performance_breakdown']['auton']}%\n"
        report += f"- Teleop: {profile['performance_breakdown']['teleop']}%\n"
        report += f"- Endgame: {profile['performance_breakdown']['endgame']}%\n"
        report += f"- Defense: {profile['performance_breakdown']['defense']}%\n\n"
        
        if profile['comments']:
            report += "#### Scout Comments\n\n"
            for comment in profile['comments']:
                if comment and not pd.isna(comment):
                    report += f"- {comment}\n"
            report += "\n"
    
    return report

def visualize_team_performance(analysis_results, output_dir):
    """Generate visualizations of team performance data"""
    try:
        team_profiles = analysis_results['team_profiles']
        
        # Create output directory if it doesn't exist
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        # Set up the style
        plt.style.use('seaborn-v0_8-darkgrid')
        
        # Create performance breakdown chart
        fig, ax = plt.subplots(figsize=(12, 8))
        
        # Prepare data for the chart
        teams = [team for team in team_profiles.keys() if not team_profiles[team]['filtered']]
        auton_scores = [team_profiles[team]['auton_average'] for team in teams]
        teleop_scores = [team_profiles[team]['teleop_average'] for team in teams]
        endgame_scores = [team_profiles[team]['endgame_average'] for team in teams]
        
        # Sort teams by total score
        team_scores = [(team, team_profiles[team]['average_score']) for team in teams]
        team_scores.sort(key=lambda x: x[1], reverse=True)
        teams = [t[0] for t in team_scores[:15]]  # Top 15 teams
        auton_scores = [team_profiles[team]['auton_average'] for team in teams]
        teleop_scores = [team_profiles[team]['teleop_average'] for team in teams]
        endgame_scores = [team_profiles[team]['endgame_average'] for team in teams]
        
        # Create the stacked bar chart
        width = 0.7
        ax.bar(teams, auton_scores, width, label='Autonomous', color='gold')
        ax.bar(teams, teleop_scores, width, bottom=auton_scores, label='Teleop', color='forestgreen')
        ax.bar(teams, endgame_scores, width, bottom=[a+t for a, t in zip(auton_scores, teleop_scores)], 
               label='Endgame', color='royalblue')
        
        # Add labels and title
        ax.set_ylabel('Average Score Points')
        ax.set_xlabel('Team Number')
        ax.set_title('Team Performance Breakdown (Top 15 Teams)', fontsize=16, fontweight='bold')
        ax.legend(loc='upper right')
        
        # Rotate x-axis labels for better readability
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Save the figure
        output_path = os.path.join(output_dir, 'team_performance_breakdown.png')
        plt.savefig(output_path)
        plt.close()
        
        # Create consistency rating chart
        fig, ax = plt.subplots(figsize=(12, 8))
        
        # Prepare data
        teams = [team for team in team_profiles.keys() if not team_profiles[team]['filtered']]
        consistency_ratings = [team_profiles[team]['consistency_rating'] for team in teams]
        
        # Sort by consistency
        team_consistency = list(zip(teams, consistency_ratings))
        team_consistency.sort(key=lambda x: x[1], reverse=True)
        teams = [t[0] for t in team_consistency[:15]]  # Top 15 most consistent teams
        consistency_ratings = [t[1] for t in team_consistency[:15]]
        
        # Create bar chart with color gradient
        bars = ax.bar(teams, consistency_ratings, width=0.7)
        
        # Color gradient based on consistency
        max_consistency = max(consistency_ratings)
        for i, bar in enumerate(bars):
            cmap = plt.get_cmap('viridis')
            bar.set_color(cmap(consistency_ratings[i] / max_consistency))
        
        # Add labels and title
        ax.set_ylabel('Consistency Rating')
        ax.set_xlabel('Team Number')
        ax.set_title('Team Consistency Ratings (Top 15 Teams)', fontsize=16, fontweight='bold')
        
        # Rotate x-axis labels for better readability
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Save the figure
        output_path = os.path.join(output_dir, 'team_consistency_ratings.png')
        plt.savefig(output_path)
        plt.close()
        
        return os.path.join(output_dir, 'team_performance_breakdown.png')
    
    except Exception as e:
        console.print(f"[bold red]Error generating visualizations: {e}[/bold red]")
        import traceback
        traceback.print_exc()
        return None

def display_match_prediction(analysis_results):
    """Display UI for match prediction"""
    console.clear()
    console.print("[bold cyan]MATCH PREDICTION TOOL[/bold cyan]", justify="center")
    console.print("[yellow]Predict match outcomes based on team performance data[/yellow]\n")
    
    team_profiles = analysis_results['team_profiles']
    teams = sorted(list(team_profiles.keys()))
    
    # Show available teams
    console.print("\n[cyan]Available Teams:[/cyan]")
    team_table = Table(show_header=False, box=box.SIMPLE)
    team_table.add_column("Teams", style="cyan")
    
    # Format teams in rows of 6
    team_rows = [teams[i:i+6] for i in range(0, len(teams), 6)]
    for row in team_rows:
        team_table.add_row(" ".join(row))
    
    console.print(team_table)
    
    # Get teams for red alliance
    console.print("\n[bold red]Red Alliance:[/bold red]")
    red_team1 = Prompt.ask("Red Alliance Team 1", default=teams[0] if teams else "")
    red_team2 = Prompt.ask("Red Alliance Team 2", default=teams[1] if len(teams) > 1 else "")
    red_team3 = Prompt.ask("Red Alliance Team 3", default=teams[2] if len(teams) > 2 else "")
    
    # Get teams for blue alliance
    console.print("\n[bold blue]Blue Alliance:[/bold blue]")
    blue_team1 = Prompt.ask("Blue Alliance Team 1", default=teams[3] if len(teams) > 3 else "")
    blue_team2 = Prompt.ask("Blue Alliance Team 2", default=teams[4] if len(teams) > 4 else "")
    blue_team3 = Prompt.ask("Blue Alliance Team 3", default=teams[5] if len(teams) > 5 else "")
    
    # Validate teams
    red_teams = [team for team in [red_team1, red_team2, red_team3] if team in team_profiles]
    blue_teams = [team for team in [blue_team1, blue_team2, blue_team3] if team in team_profiles]
    
    if len(red_teams) == 0 or len(blue_teams) == 0:
        console.print("[bold red]Error: Not enough valid teams selected[/bold red]")
        console.print("\nPress Enter to continue...", end="")
        input()
        return
    
    # Calculate alliance scores
    red_score = sum(team_profiles[team]['average_score'] for team in red_teams)
    blue_score = sum(team_profiles[team]['average_score'] for team in blue_teams)
    
    # Add a small random factor (±10%)
    import random
    red_factor = random.uniform(0.9, 1.1)
    blue_factor = random.uniform(0.9, 1.1)
    
    red_score *= red_factor
    blue_score *= blue_factor
    
    # Display prediction
    console.print("\n[bold]Match Prediction:[/bold]")
    console.print(f"[bold red]Red Alliance:[/bold red] {red_score:.2f} points")
    console.print(f"[bold blue]Blue Alliance:[/bold blue] {blue_score:.2f} points")
    
    win_margin = abs(red_score - blue_score)
    confidence = min(90, (win_margin / ((red_score + blue_score) / 2)) * 100)
    
    if red_score > blue_score:
        console.print(f"\n[bold red]Red Alliance wins[/bold red] with {confidence:.1f}% confidence")
    elif blue_score > red_score:
        console.print(f"\n[bold blue]Blue Alliance wins[/bold blue] with {confidence:.1f}% confidence")
    else:
        console.print("\n[bold yellow]It's a tie! 50% confidence[/bold yellow]")
    
    # Display alliance strengths
    console.print("\n[bold]Alliance Strengths:[/bold]")
    
    red_auton = sum(team_profiles[team]['auton_average'] for team in red_teams)
    red_teleop = sum(team_profiles[team]['teleop_average'] for team in red_teams)
    red_endgame = sum(team_profiles[team]['endgame_average'] for team in red_teams)
    red_defense = any(team_profiles[team]['plays_defense'] for team in red_teams)
    
    blue_auton = sum(team_profiles[team]['auton_average'] for team in blue_teams)
    blue_teleop = sum(team_profiles[team]['teleop_average'] for team in blue_teams)
    blue_endgame = sum(team_profiles[team]['endgame_average'] for team in blue_teams)
    blue_defense = any(team_profiles[team]['plays_defense'] for team in blue_teams)
    
    console.print(f"[red]Red Autonomous:[/red] {red_auton:.2f} vs [blue]Blue Autonomous:[/blue] {blue_auton:.2f}")
    console.print(f"[red]Red Teleop:[/red] {red_teleop:.2f} vs [blue]Blue Teleop:[/blue] {blue_teleop:.2f}")
    console.print(f"[red]Red Endgame:[/red] {red_endgame:.2f} vs [blue]Blue Endgame:[/blue] {blue_endgame:.2f}")
    console.print(f"[red]Red Defense:[/red] {'Yes' if red_defense else 'No'} vs [blue]Blue Defense:[/blue] {'Yes' if blue_defense else 'No'}")
    
    console.print("\nPress Enter to continue...", end="")
    input()

def display_update_menu(data_path):
    """Display UI for updating data files"""
    console.clear()
    console.print("[bold cyan]DATA FILE UPDATE[/bold cyan]", justify="center")
    console.print("[yellow]Update or manage your scouting data files[/yellow]\n")
    
    console.print("\n[bold green]Update Options:[/bold green]")
    console.print("1. Append data from another file")
    console.print("2. Export data to another format")
    console.print("3. Back to main menu")
    
    choice = Prompt.ask("Select option", choices=["1", "2", "3"], default="1")
    
    if choice == "1":
        # Append data from another file
        new_file = Prompt.ask("Enter path to additional data file")
        
        if not os.path.exists(new_file):
            console.print(f"[bold red]Error: File not found at {new_file}[/bold red]")
            console.print("\nPress Enter to continue...", end="")
            input()
            return
        
        try:
            # Load original data
            file_ext = os.path.splitext(data_path)[1].lower()
            if file_ext == '.csv':
                original_df = pd.read_csv(data_path)
            elif file_ext == '.json':
                with open(data_path, 'r') as f:
                    data = json.load(f)
                    original_df = pd.DataFrame(data)
            
            # Load new data
            new_ext = os.path.splitext(new_file)[1].lower()
            if new_ext == '.csv':
                new_df = pd.read_csv(new_file)
            elif new_ext == '.json':
                with open(new_file, 'r') as f:
                    data = json.load(f)
                    new_df = pd.DataFrame(data)
            else:
                console.print(f"[bold red]Unsupported file format: {new_ext}[/bold red]")
                console.print("\nPress Enter to continue...", end="")
                input()
                return
            
            # Combine data
            combined_df = pd.concat([original_df, new_df], ignore_index=True)
            
            # Save combined data
            if file_ext == '.csv':
                backup_path = f"{data_path}.bak"
                # Create backup
                original_df.to_csv(backup_path, index=False)
                combined_df.to_csv(data_path, index=False)
            else:  # JSON
                backup_path = f"{data_path}.bak"
                # Create backup
                with open(backup_path, 'w') as f:
                    json.dump(original_df.to_dict(orient='records'), f, indent=2)
                with open(data_path, 'w') as f:
                    json.dump(combined_df.to_dict(orient='records'), f, indent=2)
            
            console.print(f"[green]Successfully added {len(new_df)} records to {data_path}[/green]")
            console.print(f"[green]Backup of original data saved to {backup_path}[/green]")
            
        except Exception as e:
            console.print(f"[bold red]Error updating data file: {e}[/bold red]")
            import traceback
            traceback.print_exc()
        
    elif choice == "2":
        # Export data to another format
        try:
            # Load original data
            file_ext = os.path.splitext(data_path)[1].lower()
            if file_ext == '.csv':
                df = pd.read_csv(data_path)
                export_format = "json"
                export_path = os.path.splitext(data_path)[0] + ".json"
            elif file_ext == '.json':
                with open(data_path, 'r') as f:
                    data = json.load(f)
                    df = pd.DataFrame(data)
                export_format = "csv"
                export_path = os.path.splitext(data_path)[0] + ".csv"
            
            # Ask for export path
            export_path = Prompt.ask("Enter export file path", default=export_path)
            
            # Export data
            if export_format == "json":
                with open(export_path, 'w') as f:
                    json.dump(df.to_dict(orient='records'), f, indent=2)
            else:  # CSV
                df.to_csv(export_path, index=False)
            
            console.print(f"[green]Successfully exported data to {export_path}[/green]")
            
        except Exception as e:
            console.print(f"[bold red]Error exporting data: {e}[/bold red]")
            import traceback
            traceback.print_exc()
    
    console.print("\nPress Enter to continue...", end="")
    input()

def main():
    display_welcome_screen()
    
    # Ask for input data
    console.print("\n[yellow]Choose data source:[/yellow]")
    console.print("1. CSV file")
    console.print("2. JSON file")
    console.print("3. QR Code data (as text)")
    
    choice = Prompt.ask("Enter your choice", choices=["1", "2", "3"], default="1")
    
    analysis_results = {}
    data_path = None
    
    if choice == "1":
        data_path = Prompt.ask("Enter path to CSV file", default="scouting_data.csv")
        if not os.path.exists(data_path):
            console.print(f"[bold red]Error: File not found at {data_path}[/bold red]")
            return
        analysis_results = analyze_scouting_data(data_path=data_path)
    elif choice == "2":
        data_path = Prompt.ask("Enter path to JSON file", default="scouting_data.json")
        if not os.path.exists(data_path):
            console.print(f"[bold red]Error: File not found at {data_path}[/bold red]")
            return
        analysis_results = analyze_scouting_data(data_path=data_path)
    else:
        data_str = Prompt.ask("Paste QR code data (CSV or JSON string)")
        analysis_results = analyze_scouting_data(data_str=data_str)
    
    if not analysis_results:
        console.print("[bold red]No valid data to analyze. Exiting.[/bold red]")
        return

    # Show menu for analysis options
    while True:
        console.clear()
        console.print("\n[bold cyan]SCOUTZ ANALYSIS MENU[/bold cyan]")
        console.print("1. View Team List")
        console.print("2. View Alliance Recommendations")
        console.print("3. Export Strategy Report")
        console.print("4. Generate Performance Visualization")
        console.print("5. Predict Match Outcome")
        console.print("6. Manage Team Filters")  # New option
        console.print("7. Update Data Files")
        console.print("8. Exit")
        
        menu_choice = Prompt.ask("Select an option", choices=["1", "2", "3", "4", "5", "6", "7", "8"], default="1")
        
        if menu_choice == "1":
            display_team_list(analysis_results)
        elif menu_choice == "2":
            display_alliance_selections(analysis_results)
        elif menu_choice == "3":
            report = generate_strategy_report(analysis_results)
            output_path = Prompt.ask("Save report to", default="strategy_report.md")
            with open(output_path, "w") as f:
                f.write(report)
            console.print(f"[green]Report saved to {output_path}[/green]")
            console.print("\nPress Enter to continue...", end="")
            input()
        elif menu_choice == "4":
            output_dir = Prompt.ask("Save visualization to directory", default=".")
            viz_path = visualize_team_performance(analysis_results, output_dir)
            if viz_path:
                console.print(f"[green]Visualization saved to {viz_path}[/green]")
            console.print("\nPress Enter to continue...", end="")
            input()
        elif menu_choice == "5":
            display_match_prediction(analysis_results)
        elif menu_choice == "6":
            manage_team_filters(analysis_results['team_profiles'])
            # Reload analysis with updated filters
            if data_path:
                analysis_results = analyze_scouting_data(data_path=data_path)
        elif menu_choice == "7":
            if data_path:
                display_update_menu(data_path)
                # Reload analysis with updated data if needed
                analysis_results = analyze_scouting_data(data_path=data_path)
            else:
                console.print("[bold yellow]Update only available for file data sources[/bold yellow]")
                console.print("\nPress Enter to continue...", end="")
                input()
        elif menu_choice == "8":
            break


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[italic]Program terminated by user.[/italic]")
        sys.exit(0)