import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import json
import sys
import time
from datetime import datetime
from typing import Dict, List, Optional, Union, Any
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
        Path to JSON file containing scouting data
    data_str : str, optional
        String containing JSON data
    
    Returns:
    --------
    dict
        Dictionary containing analysis results
    """
    with console.status("[bold green]Loading and processing data...[/bold green]", spinner="dots"):
        # Load data - either from JSON file or from string
        if data_path:
            try:
                with open(data_path, 'r') as f:
                    data = json.load(f)
                    df = pd.DataFrame(data)
            except Exception as e:
                console.print(f"[bold red]Error loading data file: {e}[/bold red]")
                return {}
        elif data_str:
            try:
                import io
                data = json.loads(data_str)
                df = pd.DataFrame(data)
            except Exception as e:
                console.print(f"[bold red]Error parsing data string: {e}[/bold red]")
                return {}
        else:
            console.print("[bold red]Either data_path or data_str must be provided[/bold red]")
            return {}
        
        # Normalize the nested JSON structure
        try:
            # Flatten the nested JSON columns
            if 'autonPoints' in df.columns:
                auton_df = pd.json_normalize(df['autonPoints'])
                auton_df.columns = ['autonPoints_' + col for col in auton_df.columns]
                df = pd.concat([df.drop(['autonPoints'], axis=1), auton_df], axis=1)
            
            if 'teleOpPoints' in df.columns:
                teleop_df = pd.json_normalize(df['teleOpPoints'])
                teleop_df.columns = ['teleOpPoints_' + col for col in teleop_df.columns]
                df = pd.concat([df.drop(['teleOpPoints'], axis=1), teleop_df], axis=1)
            
            if 'endPoints' in df.columns:
                endgame_df = pd.json_normalize(df['endPoints'])
                endgame_df.columns = ['endPoints_' + col for col in endgame_df.columns]
                df = pd.concat([df.drop(['endPoints'], axis=1), endgame_df], axis=1)
        except Exception as e:
            console.print(f"[bold red]Error normalizing JSON data: {e}[/bold red]")
            return {}
        
        # Convert boolean columns - more robust approach
        bool_columns = []
        for col in df.columns:
            # Only check string columns
            if df[col].dtype == object:  # Check dtype instead of using str accessor
                # Check if the column contains TRUE or FALSE values
                sample_values = df[col].dropna().unique()
                if any(val in ['TRUE', 'FALSE', True, False] for val in sample_values if isinstance(val, (str, bool))):
                    bool_columns.append(col)
        
        # Convert identified boolean columns
        for col in bool_columns:
            df[col] = df[col].map({'TRUE': True, 'FALSE': False, True: True, False: False})
        
        # Calculate phase scores
        df['auton_total'] = 0
        for col in df.columns:
            if col.startswith('autonPoints_CoralScoring') or col.startswith('autonPoints_AlgaeScoring'):
                df['auton_total'] += df[col].fillna(0)
        
        # Add bonus point for left barge in auton
        if 'autonPoints_LeftBarge' in df.columns:
            df.loc[df['autonPoints_LeftBarge'] == True, 'auton_total'] += 5
        
        df['teleop_total'] = 0
        for col in df.columns:
            if col.startswith('teleOpPoints_CoralScoring') or col.startswith('teleOpPoints_AlgaeScoring'):
                df['teleop_total'] += df[col].fillna(0)
        
        # Calculate endgame points
        df['endgame_total'] = 0
        if 'endPoints_Deep_Climb' in df.columns:
            df.loc[df['endPoints_Deep_Climb'] == True, 'endgame_total'] += 15  # Deep climb worth 15 points
        if 'endPoints_Shallow_Climb' in df.columns:
            df.loc[df['endPoints_Shallow_Climb'] == True, 'endgame_total'] += 10  # Shallow climb worth 10 points
        if 'endPoints_Park' in df.columns:
            df.loc[df['endPoints_Park'] == True, 'endgame_total'] += 5  # Park worth 5 points
        
        # Calculate defense value (binary for now)
        df['defense_value'] = 0
        if 'teleOpPoints_Defense' in df.columns:
            df['defense_value'] = df['teleOpPoints_Defense'].astype(int) * 5  # Assign 5 points for playing defense
        
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
        
        # Best autonomous teams (top 5)
        best_auton = team_stats.sort_values('auton_total_mean', ascending=False).head(5)
        team_strengths['best_auton_teams'] = best_auton.index.tolist()
        
        # Best teleop teams (top 5)
        best_teleop = team_stats.sort_values('teleop_total_mean', ascending=False).head(5)
        team_strengths['best_teleop_teams'] = best_teleop.index.tolist()
        
        # Best endgame teams (top 5)
        best_endgame = team_stats.sort_values('endgame_total_mean', ascending=False).head(5)
        team_strengths['best_endgame_teams'] = best_endgame.index.tolist()
        
        # Best defense teams
        best_defense = team_stats.sort_values('defense_value_mean', ascending=False)
        best_defense = best_defense[best_defense['defense_value_mean'] > 0].head(5)
        team_strengths['best_defense_teams'] = best_defense.index.tolist()
        
        # Most consistent teams (top 5)
        most_consistent = team_stats.sort_values('consistency', ascending=False).head(5)
        team_strengths['most_consistent_teams'] = most_consistent.index.tolist()
        
        # Best overall teams (by average score, top 5)
        best_overall = team_stats.sort_values('total_score_mean', ascending=False).head(5)
        team_strengths['best_overall_teams'] = best_overall.index.tolist()
        
        # Create detailed team profiles
        team_profiles = {}
        for team in df['teamNumber'].unique():
            team_data = df[df['teamNumber'] == team]
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
                'comments': team_data['endPoints_Comments'].tolist() if 'endPoints_Comments' in team_data.columns else []
            }
            
            # Add performance breakdown
            profile['performance_breakdown'] = {
                'auton': round((team_stats_row['auton_total_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0,
                'teleop': round((team_stats_row['teleop_total_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0,
                'endgame': round((team_stats_row['endgame_total_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0,
                'defense': round((team_stats_row['defense_value_mean'] / profile['average_score']) * 100, 2) if profile['average_score'] > 0 else 0
            }
            
            team_profiles[team] = profile
    
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
    if 'endPoints_Deep_Climb' in team_data.columns:
        climbs += team_data['endPoints_Deep_Climb'].sum()
    if 'endPoints_Shallow_Climb' in team_data.columns:
        climbs += team_data['endPoints_Shallow_Climb'].sum()
    
    return round((climbs / total_matches) * 100, 2)

def generate_strategy_report(analysis_results):
    """Generate a comprehensive strategy report based on analysis results"""
    team_strengths = analysis_results['team_strengths']
    team_profiles = analysis_results['team_profiles']
    
    report = "# ROBOTICS COMPETITION STRATEGY REPORT\n\n"
    report += f"*Generated by PyIntel Scoutz on {datetime.now().strftime('%Y-%m-%d %H:%M')}*\n\n"
    report += "*Powered by PyIntel AI*\n\n"
    
    # Best teams section
    report += "## TOP PERFORMING TEAMS\n\n"
    
    report += "### Best Teams at Autonomous\n"
    for team in team_strengths['best_auton_teams']:
        profile = team_profiles[team]
        report += f"- Team {team}: Avg. {profile['auton_average']} pts ({profile['performance_breakdown']['auton']}% of total score)\n"
    
    report += "\n### Best Teams at Teleop\n"
    for team in team_strengths['best_teleop_teams']:
        profile = team_profiles[team]
        report += f"- Team {team}: Avg. {profile['teleop_average']} pts ({profile['performance_breakdown']['teleop']}% of total score)\n"
    
    report += "\n### Best Teams at Endgame\n"
    for team in team_strengths['best_endgame_teams']:
        profile = team_profiles[team]
        report += f"- Team {team}: Avg. {profile['endgame_average']} pts, {profile['climbing_percentage']}% successful climbs\n"
    
    if team_strengths['best_defense_teams']:
        report += "\n### Best Defense Teams\n"
        for team in team_strengths['best_defense_teams']:
            profile = team_profiles[team]
            report += f"- Team {team}: Consistently plays defense\n"
    
    report += "\n### Most Consistent Teams\n"
    for team in team_strengths['most_consistent_teams']:
        profile = team_profiles[team]
        report += f"- Team {team}: Consistency rating {profile['consistency_rating']}/10\n"
    
    report += "\n### Best Overall Teams\n"
    for team in team_strengths['best_overall_teams']:
        profile = team_profiles[team]
        report += f"- Team {team}: Avg. {profile['average_score']} pts, {profile['matches_played']} matches\n"
    
    # Detailed team profiles
    report += "\n\n## DETAILED TEAM PROFILES\n"
    
    for team_number, profile in sorted(team_profiles.items()):
        report += f"\n### Team {team_number}\n"
        report += f"- **Matches Played:** {profile['matches_played']}\n"
        report += f"- **Average Score:** {profile['average_score']} points\n"
        report += f"- **Highest Score:** {profile['highest_score']} points\n"
        report += f"- **Consistency Rating:** {profile['consistency_rating']}/10\n"
        report += f"- **Performance Breakdown:**\n"
        report += f"  - Autonomous: {profile['auton_average']} pts ({profile['performance_breakdown']['auton']}%)\n"
        report += f"  - Teleop: {profile['teleop_average']} pts ({profile['performance_breakdown']['teleop']}%)\n"
        report += f"  - Endgame: {profile['endgame_average']} pts ({profile['performance_breakdown']['endgame']}%)\n"
        if profile['plays_defense']:
            report += f"  - Defense: Active ({profile['performance_breakdown']['defense']}% impact)\n"
        report += f"- **Climbing Success Rate:** {profile['climbing_percentage']}%\n"
        if profile['comments']:
            report += "- **Scout Comments:**\n"
            for comment in profile['comments']:
                if comment:  # Only include non-empty comments
                    report += f"  - \"{comment}\"\n"
    
    # Alliance selection strategy
    report += "\n\n## ALLIANCE SELECTION STRATEGY\n\n"
    
    # Top picks for first alliance partner
    report += "### Recommended First Pick Teams\n"
    best_overall = team_strengths['best_overall_teams'][:3]
    for team in best_overall:
        profile = team_profiles[team]
        report += f"- Team {team}: {profile['average_score']} avg pts, strongest in {get_strongest_phase(profile)}\n"
    
    # Top picks for second alliance partner (complementary skills)
    report += "\n### Recommended Second Pick Teams\n"
    
    # Look for teams with complementary skills (e.g., if we have a strong teleop team, look for strong auton/endgame)
    complementary_teams = find_complementary_teams(team_profiles, best_overall)
    for team in complementary_teams:
        profile = team_profiles[team]
        report += f"- Team {team}: {profile['average_score']} avg pts, strongest in {get_strongest_phase(profile)}\n"
    
    # Match strategy
    report += "\n\n## MATCH STRATEGY RECOMMENDATIONS\n\n"
    
    # Based on overall analysis, provide some general strategic recommendations
    report += "1. **Autonomous Priority**: Teams should focus on scoring in higher levels and leaving the barge for bonus points\n"
    report += "2. **Teleop Scoring**: Prioritize consistent scoring over attempting difficult high-level scoring\n"
    report += "3. **Endgame Strategy**: Successful climbs are crucial for maximizing points\n"
    report += "4. **Defense Considerations**: Use defense strategically against top-scoring opponents\n"
    
    return report

def get_strongest_phase(team_profile):
    """Determine which phase a team is strongest in"""
    phases = {
        'Autonomous': team_profile['auton_average'],
        'Teleop': team_profile['teleop_average'],
        'Endgame': team_profile['endgame_average']
    }
    return max(phases, key=phases.get)

def find_complementary_teams(team_profiles, exclude_teams):
    """Find teams with complementary skills to the top teams"""
    # Create a list of all teams excluding the already picked ones
    all_teams = set(team_profiles.keys()) - set(exclude_teams)
    
    # Score each team based on their strengths
    team_scores = {}
    for team in all_teams:
        profile = team_profiles[team]
        # Simple scoring: weight endgame and auton slightly higher as they're often more valuable
        score = (profile['auton_average'] * 1.2 + 
                profile['teleop_average'] + 
                profile['endgame_average'] * 1.3 +
                profile['consistency_rating'] * 2)  # Consistency is very important
        team_scores[team] = score
    
    # Return top 3 complementary teams
    return sorted(team_scores.keys(), key=lambda x: team_scores[x], reverse=True)[:3]

def visualize_team_performance(analysis_results, output_dir=None):
    """Generate visualizations of team performance"""
    team_stats = analysis_results['team_stats']
    team_profiles = analysis_results['team_profiles']
    
    # Prepare data for visualization
    teams = list(team_profiles.keys())
    team_data = pd.DataFrame({
        'Team': teams,
        'Autonomous': [team_profiles[t]['auton_average'] for t in teams],
        'Teleop': [team_profiles[t]['teleop_average'] for t in teams],
        'Endgame': [team_profiles[t]['endgame_average'] for t in teams],
        'Total': [team_profiles[t]['average_score'] for t in teams]
    })
    
    # Sort by total score
    team_data = team_data.sort_values('Total', ascending=False)
    
    # Set up the plots
    plt.figure(figsize=(12, 8))
    
    # Create the stacked bar chart
    ax = team_data.plot(x='Team', y=['Autonomous', 'Teleop', 'Endgame'], kind='bar', stacked=True, 
                        color=['#FF9999', '#66B2FF', '#99FF99'])
    
    # Add total score line
    ax2 = ax.twinx()
    ax2.plot(team_data['Team'], team_data['Total'], 'ko-', linewidth=2, markersize=8)
    
    # Labels and title
    ax.set_xlabel('Team Number')
    ax.set_ylabel('Average Points by Phase')
    ax2.set_ylabel('Total Average Score')
    plt.title('Team Performance Breakdown')
    ax.legend(loc='upper left')
    
    # Add PyIntel Scoutz watermark
    plt.figtext(0.5, 0.01, "Generated by PyIntel Scoutz - Powered by PyIntel AI", 
                ha="center", fontsize=8, color='gray')
    
    # Save or show
    if output_dir:
        plt.savefig(f"{output_dir}/team_performance.png", dpi=300, bbox_inches='tight')
        return f"{output_dir}/team_performance.png"
    else:
        plt.close()  # Close plot to prevent display in terminal
        return None

def display_team_details(team_number, analysis_results):
    """Display detailed information about a specific team"""
    console.clear()
    console.print(f"[bold cyan]TEAM {team_number} DETAILS[/bold cyan]", justify="center")
    
    team_profiles = analysis_results['team_profiles']
    if team_number not in team_profiles:
        console.print("[bold red]Team not found in the dataset![/bold red]")
        return
    
    profile = team_profiles[team_number]
    
    table = Table(title=f"Team {team_number} Performance", box=box.ROUNDED, show_header=False)
    table.add_column("Metric", style="cyan")
    table.add_column("Value", style="yellow")
    
    table.add_row("Matches Played", str(profile['matches_played']))
    table.add_row("Average Score", f"{profile['average_score']} points")
    table.add_row("Highest Score", f"{profile['highest_score']} points")
    table.add_row("Consistency Rating", f"{profile['consistency_rating']}/10")
    
    # Phase breakdown
    table.add_section()
    table.add_row("Autonomous Average", f"{profile['auton_average']} pts ({profile['performance_breakdown']['auton']}%)")
    table.add_row("Teleop Average", f"{profile['teleop_average']} pts ({profile['performance_breakdown']['teleop']}%)")
    table.add_row("Endgame Average", f"{profile['endgame_average']} pts ({profile['performance_breakdown']['endgame']}%)")
    
    table.add_section()
    table.add_row("Plays Defense", "Yes" if profile['plays_defense'] else "No")
    table.add_row("Climbing Success Rate", f"{profile['climbing_percentage']}%")
    
    console.print(table)
    
    # Scout comments
    if profile['comments']:
        console.print("\n[bold cyan]Scout Comments:[/bold cyan]")
        for comment in profile['comments']:
            if comment:  # Only print non-empty comments
                console.print(f" - \"{comment}\"")
    
    # Strongest phase
    strongest = get_strongest_phase(profile)
    console.print(f"\n[bold green]Team {team_number} is strongest in [/bold green][bold yellow]{strongest}[/bold yellow]")
    
    # Recommendations
    console.print("\n[bold cyan]Recommendations:[/bold cyan]")
    if strongest == "Autonomous":
        console.print(" - Excellent autonomous performer - consider for first pick position")
        console.print(" - Partner with strong teleop or endgame teams to complement")
    elif strongest == "Teleop":
        console.print(" - Strong teleop scorer - good all-around alliance partner")
        console.print(" - Partner with teams strong in autonomous for a balanced alliance")
    else:  # Endgame
        console.print(" - Valuable endgame capabilities - can secure crucial points")
        console.print(" - Partner with consistent scorers for well-rounded alliance")
    
    if profile['plays_defense']:
        console.print(" - Consider for defensive role against high-scoring opponents")
    
    console.print("\nPress Enter to return to the main menu...", end="")
    input()

def display_team_list(analysis_results):
    """Display a sortable list of all teams"""
    console.clear()
    console.print("[bold cyan]TEAM PERFORMANCE OVERVIEW[/bold cyan]", justify="center")
    
    team_profiles = analysis_results['team_profiles']
    
    while True:
        console.print("\nSort by: ", end="")
        sort_options = [
            "1. Average Score", 
            "2. Autonomous", 
            "3. Teleop", 
            "4. Endgame", 
            "5. Consistency"
        ]
        for option in sort_options:
            console.print(option)
        
        choice = Prompt.ask("Enter your choice (or 'b' to go back)", default="1")
        
        if choice.lower() == 'b':
            return
        
        try:
            choice = int(choice)
            if choice < 1 or choice > 5:
                console.print("[bold red]Invalid choice. Please try again.[/bold red]")
                continue
        except ValueError:
            console.print("[bold red]Invalid choice. Please try again.[/bold red]")
            continue
        
        # Sort teams based on selection
        sort_key = {
            1: 'average_score',
            2: 'auton_average',
            3: 'teleop_average',
            4: 'endgame_average',
            5: 'consistency_rating'
        }[choice]
        
        sorted_teams = sorted(team_profiles.items(), 
                             key=lambda x: x[1][sort_key], 
                             reverse=True)
        
        # Create and display table
        table = Table(title="Team Rankings", box=box.ROUNDED)
        table.add_column("Rank", style="dim")
        table.add_column("Team #", style="cyan bold")
        table.add_column("Avg Score", justify="right")
        table.add_column("Auton", justify="right")
        table.add_column("Teleop", justify="right")
        table.add_column("Endgame", justify="right")
        table.add_column("Consistency", justify="right")
        
        for i, (team, profile) in enumerate(sorted_teams, 1):
            table.add_row(
                str(i),
                str(team),
                f"{profile['average_score']:.1f}",
                f"{profile['auton_average']:.1f}",
                f"{profile['teleop_average']:.1f}",
                f"{profile['endgame_average']:.1f}",
                f"{profile['consistency_rating']:.1f}"
            )
        
        console.print(table)
        console.print("\nType a team number to view details, or press Enter to reselect sort option: ", end="")
        team_choice = input().strip()
        
        if team_choice:
            try:
                team_number = team_choice
                if team_number in team_profiles:
                    display_team_details(team_number, analysis_results)
                else:
                    console.print(f"[bold red]Team {team_number} not found![/bold red]")
                    console.print("Press Enter to continue...", end="")
                    input()
            except ValueError:
                console.print("[bold red]Invalid team number.[/bold red]")
                console.print("Press Enter to continue...", end="")
                input()

def display_alliance_selections(analysis_results):
    """Display recommended alliance selections"""
    console.clear()
    console.print("[bold cyan]ALLIANCE SELECTION RECOMMENDATIONS[/bold cyan]", justify="center")
    
    team_strengths = analysis_results['team_strengths']
    team_profiles = analysis_results['team_profiles']
    
    # First pick recommendations
    console.print("\n[bold green]Recommended First Pick Teams:[/bold green]")
    best_overall = team_strengths['best_overall_teams'][:3]
    
    table1 = Table(box=box.ROUNDED)
    table1.add_column("Team", style="cyan bold")
    table1.add_column("Avg Score", justify="right")
    table1.add_column("Strongest Phase", style="yellow")
    table1.add_column("Key Strength")
    
    for team in best_overall:
        profile = team_profiles[team]
        strongest = get_strongest_phase(profile)
        
        key_strength = ""
        if strongest == "Autonomous":
            key_strength = "High autonomous scoring"
        elif strongest == "Teleop":
            key_strength = "Consistent teleop performance"
        else:
            key_strength = f"Strong {strongest.lower()} capabilities"

        table1.add_row(
            str(team),
            f"{profile['average_score']:.1f}",
            strongest,
            key_strength
        )
    
    console.print(table1)
    
    # Second pick recommendations (complementary skills)
    console.print("\n[bold green]Recommended Second Pick Teams:[/bold green]")
    complementary_teams = find_complementary_teams(team_profiles, best_overall)
    
    table2 = Table(box=box.ROUNDED)
    table2.add_column("Team", style="cyan bold")
    table2.add_column("Avg Score", justify="right")
    table2.add_column("Strongest Phase", style="yellow")
    table2.add_column("Complementary Skill")
    
    for team in complementary_teams:
        profile = team_profiles[team]
        strongest = get_strongest_phase(profile)
        
        complementary_skill = ""
        if strongest == "Autonomous":
            complementary_skill = "Fills autonomous gap"
        elif strongest == "Teleop":
            complementary_skill = "Adds teleop scoring power"
        else:  # Endgame
            complementary_skill = "Secures endgame points"
            
        if profile['plays_defense']:
            complementary_skill += ", defensive capability"
            
        table2.add_row(
            str(team),
            f"{profile['average_score']:.1f}",
            strongest,
            complementary_skill
        )
    
    console.print(table2)
    
    # Alliance strategy advice
    console.print("\n[bold cyan]Alliance Strategy Recommendations:[/bold cyan]")
    
    strategy_panel = Panel(
        "1. Pair high autonomous scorers with strong endgame teams for balanced alliances\n"
        "2. Consider one defensive robot if facing high-scoring opponents\n"
        "3. Prioritize consistency over occasional high scores\n"
        "4. Look for complementary capabilities when selecting alliance partners",
        title="Strategy Tips",
        border_style="green"
    )
    console.print(strategy_panel)
    
    console.print("\nPress Enter to return to the main menu...", end="")
    input()

def predict_match_outcome(team_profiles, alliance_1, alliance_2):
    """
    Predict match outcome based on team statistics using Monte Carlo simulation
    
    Parameters:
    -----------
    team_profiles : dict
        Dictionary containing team profile data
    alliance_1 : list
        List of team numbers in alliance 1
    alliance_2 : list
        List of team numbers in alliance 2
    
    Returns:
    --------
    tuple
        (probability_victory_1, probability_victory_2, expected_score_1, expected_score_2)
    """
    import numpy as np
    from scipy import stats
    
    # Check that all teams exist in profiles
    all_teams = set(alliance_1 + alliance_2)
    missing_teams = [team for team in all_teams if team not in team_profiles]
    if missing_teams:
        raise ValueError(f"Teams {missing_teams} not found in profiles")
    
    # Calculate base expected scores (sum of averages)
    expected_score_1 = sum(team_profiles[team]['average_score'] for team in alliance_1)
    expected_score_2 = sum(team_profiles[team]['average_score'] for team in alliance_2)
    
    # Calculate alliance synergy factors based on complementary strengths
    alliance_1_phases = [get_strongest_phase(team_profiles[team]) for team in alliance_1]
    alliance_2_phases = [get_strongest_phase(team_profiles[team]) for team in alliance_2]
    
    # Bonus for having each phase covered (autonomous, teleop, endgame)
    phase_diversity_1 = len(set(alliance_1_phases)) / 3.0  # 1.0 if all three phases covered
    phase_diversity_2 = len(set(alliance_2_phases)) / 3.0  # 1.0 if all three phases covered
    
    synergy_bonus_1 = expected_score_1 * 0.05 * phase_diversity_1  # Up to 5% bonus for diverse skills
    synergy_bonus_2 = expected_score_2 * 0.05 * phase_diversity_2
    
    # Account for defense - defensive robots can reduce opponent's score
    defense_factor_1 = sum(1 if team_profiles[team]['plays_defense'] else 0 for team in alliance_1) * 0.03
    defense_factor_2 = sum(1 if team_profiles[team]['plays_defense'] else 0 for team in alliance_2) * 0.03
    
    # Defense reduces opponent's expected score
    expected_score_1 = expected_score_1 * (1 - defense_factor_2)
    expected_score_2 = expected_score_2 * (1 - defense_factor_1)
    
    # Add synergy bonus
    expected_score_1 += synergy_bonus_1
    expected_score_2 += synergy_bonus_2
    
    # Get variance estimates for each team
    variance_1 = sum((team_profiles[team]['total_score_std'] ** 2) 
                     if 'total_score_std' in team_profiles[team] else 
                     team_profiles[team]['average_score'] * 0.1 
                     for team in alliance_1)
    
    variance_2 = sum((team_profiles[team]['total_score_std'] ** 2)
                     if 'total_score_std' in team_profiles[team] else
                     team_profiles[team]['average_score'] * 0.1
                     for team in alliance_2)
    
    # Monte Carlo simulation for more accurate prediction
    num_simulations = 10000
    wins_1 = 0
    wins_2 = 0
    ties = 0
    
    np.random.seed(42)  # For reproducible results
    
    for _ in range(num_simulations):
        # Simulate a match result using normal distribution
        score_1 = np.random.normal(expected_score_1, np.sqrt(variance_1))
        score_2 = np.random.normal(expected_score_2, np.sqrt(variance_2))
        
        if score_1 > score_2:
            wins_1 += 1
        elif score_2 > score_1:
            wins_2 += 1
        else:
            ties += 1
    
    # Calculate win probabilities
    probability_victory_1 = wins_1 / num_simulations
    probability_victory_2 = wins_2 / num_simulations
    
    # Format expected scores to 2 decimal places
    expected_score_1 = round(expected_score_1, 2)
    expected_score_2 = round(expected_score_2, 2)
    
    return probability_victory_1, probability_victory_2, expected_score_1, expected_score_2

def analyze_team_trends(analysis_results):
    """Analyze how teams improve over matches"""
    # Generate match-by-match graphs showing performance trends
    # Highlight teams showing rapid improvement

    trends = {}
    for team, profiles in analysis_results['team_profiles'].items():
        trends[team] = []
        for match, profile in profiles.items():
            trends[team].append((match, profile['average_score']))
    

    return trends

def generate_match_strategy(our_alliance, opponent_alliance, team_profiles):
    """Generate specific strategy for an upcoming match"""
    # Identify opponent strengths to counter
    # Recommend specific robot positioning and tactics

    opponent_strengths = [get_strongest_phase(team_profiles[team]) for team in opponent_alliance]
    strategy = []

    for team in our_alliance:
        team_profile = team_profiles[team]
        if "Autonomous" in opponent_strengths:
            strategy.append(f"{team} should prioritize autonomous tasks.")
        if "Teleop" in opponent_strengths:
            strategy.append(f"{team} should focus on scoring during teleop.")

    return strategy

from cache import display_welcome_screen, analyze_scouting_data
from rich.console import Console
from rich.prompt import Prompt
import os
import sys

console = Console()

def display_match_prediction(analysis_results):
    """Display match prediction interface and results"""
    console.clear()
    console.print("[bold cyan]MATCH OUTCOME PREDICTION[/bold cyan]", justify="center")
    
    team_profiles = analysis_results['team_profiles']
    available_teams = sorted(list(team_profiles.keys()))
    
    # Display available teams
    console.print("\n[yellow]Available Teams:[/yellow]")
    team_table = Table(show_header=False, box=box.SIMPLE)
    team_table.add_column("Teams", style="cyan")
    
    # Format teams in rows of 6
    team_rows = [available_teams[i:i+6] for i in range(0, len(available_teams), 6)]
    for row in team_rows:
        team_table.add_row(" ".join(row))
    
    console.print(team_table)
    
    # Get alliance teams
    console.print("\n[bold green]Enter Red Alliance Teams:[/bold green]")
    red_alliance = []
    for i in range(3):
        while True:
            team = Prompt.ask(f"Red Alliance Team #{i+1}", default="")
            if team in available_teams:
                red_alliance.append(team)
                break
            elif team == "":
                break
            else:
                console.print(f"[bold red]Team {team} not found in dataset![/bold red]")
    
    console.print("\n[bold blue]Enter Blue Alliance Teams:[/bold blue]")
    blue_alliance = []
    for i in range(3):
        while True:
            team = Prompt.ask(f"Blue Alliance Team #{i+1}", default="")
            if team in available_teams:
                blue_alliance.append(team)
                break
            elif team == "":
                break
            else:
                console.print(f"[bold red]Team {team} not found in dataset![/bold red]")
    
    if len(red_alliance) == 0 or len(blue_alliance) == 0:
        console.print("[bold red]Must have at least one team on each alliance![/bold red]")
        console.print("\nPress Enter to continue...", end="")
        input()
        return
    
    # Run the prediction
    with console.status("[bold green]Calculating match outcome...[/bold green]", spinner="dots"):
        try:
            red_prob, blue_prob, red_score, blue_score = predict_match_outcome(
                team_profiles, red_alliance, blue_alliance)
            
            # Format probabilities as percentages
            red_prob = round(red_prob * 100, 2)
            blue_prob = round(blue_prob * 100, 2)
        except Exception as e:
            console.print(f"[bold red]Error calculating prediction: {e}[/bold red]")
            console.print("\nPress Enter to continue...", end="")
            input()
            return
    
    # Display results
    console.clear()
    console.print("[bold cyan]MATCH PREDICTION RESULTS[/bold cyan]", justify="center")
    
    # Alliance compositions
    red_teams = " + ".join(red_alliance)
    blue_teams = " + ".join(blue_alliance)
    
    console.print(f"\n[bold red]RED ALLIANCE:[/bold red] {red_teams}")
    console.print(f"[bold blue]BLUE ALLIANCE:[/bold blue] {blue_teams}")
    
    # Create results table
    results = Table(title="Match Prediction", box=box.ROUNDED)
    results.add_column("Alliance", style="bold")
    results.add_column("Expected Score", justify="right")
    results.add_column("Win Probability", justify="right")
    
    # Add colored rows for each alliance
    results.add_row("🔴 Red", f"{red_score}", f"{red_prob}%", style="red")
    results.add_row("🔵 Blue", f"{blue_score}", f"{blue_prob}%", style="blue")
    
    console.print("\n", results)
    
    # Determine favorite
    if red_prob > blue_prob:
        console.print(f"\n[bold]Prediction: [red]RED Alliance[/red] favored to win " +
                     f"({red_prob}% probability)[/bold]")
    elif blue_prob > red_prob:
        console.print(f"\n[bold]Prediction: [blue]BLUE Alliance[/blue] favored to win " +
                     f"({blue_prob}% probability)[/bold]")
    else:
        console.print("\n[bold yellow]Prediction: Match too close to call![/bold yellow]")
    
    # Key factors
    console.print("\n[bold cyan]Key Factors:[/bold cyan]")
    
    # Check phase strengths
    red_phases = [get_strongest_phase(team_profiles[team]) for team in red_alliance]
    blue_phases = [get_strongest_phase(team_profiles[team]) for team in blue_alliance]
    
    # Red alliance factors
    red_factors = []
    if len(set(red_phases)) == 3:
        red_factors.append("✓ Well-balanced across all phases")
    elif red_phases.count('Autonomous') > blue_phases.count('Autonomous'):
        red_factors.append("✓ Strong autonomous advantage")
    elif red_phases.count('Endgame') > blue_phases.count('Endgame'):
        red_factors.append("✓ Strong endgame advantage")
    
    defense_red = sum(1 if team_profiles[team]['plays_defense'] else 0 for team in red_alliance)
    if defense_red > 0:
        red_factors.append(f"✓ {defense_red} defensive robot(s)")
        
    # Blue alliance factors
    blue_factors = []
    if len(set(blue_phases)) == 3:
        blue_factors.append("✓ Well-balanced across all phases")
    elif blue_phases.count('Autonomous') > red_phases.count('Autonomous'):
        blue_factors.append("✓ Strong autonomous advantage")
    elif blue_phases.count('Endgame') > red_phases.count('Endgame'):
        blue_factors.append("✓ Strong endgame advantage")
        
    defense_blue = sum(1 if team_profiles[team]['plays_defense'] else 0 for team in blue_alliance)
    if defense_blue > 0:
        blue_factors.append(f"✓ {defense_blue} defensive robot(s)")
    
    # Print factors
    if red_factors:
        console.print("[bold red]RED Advantages:[/bold red]")
        for factor in red_factors:
            console.print(f"  {factor}")
    
    if blue_factors:
        console.print("[bold blue]BLUE Advantages:[/bold blue]")
        for factor in blue_factors:
            console.print(f"  {factor}")
    
    console.print("\nPress Enter to continue...", end="")
    input()

def check_for_updates(data_path: str) -> Dict:
    """
    Check if there's a newer version of the data file available.
    
    Parameters:
    -----------
    data_path : str
        Path to the current JSON data file
    
    Returns:
    --------
    dict
        Information about available updates
    """
    try:
        # Load current data file to get version info
        with open(data_path, 'r') as f:
            current_data = json.load(f)
        
        # Extract version info if available, otherwise default to "1.0"
        current_version = current_data.get('metadata', {}).get('version', "1.0")
        
        # This would normally connect to a server to check for updates
        # For demo purposes, we'll simulate this by checking a local "update_repository" folder
        update_repo_path = os.path.join(os.path.dirname(os.path.dirname(data_path)), "update_repository")
        
        if not os.path.exists(update_repo_path):
            os.makedirs(update_repo_path, exist_ok=True)
            return {
                "has_update": False,
                "message": "Update repository not found. Created one for future updates.",
                "latest_version": current_version
            }
        
        # Check for newer files in the repository
        update_files = [f for f in os.listdir(update_repo_path) if f.endswith('.json')]
        
        if not update_files:
            return {
                "has_update": False,
                "message": "No update files found in repository.",
                "latest_version": current_version
            }
        
        # Find the latest version by extracting version from filename
        # Assuming filename format like "scouting_data_v2.1.json"
        latest_file = None
        latest_version = current_version
        
        for file in update_files:
            try:
                file_version = file.split('_v')[1].split('.json')[0]
                if compare_versions(file_version, latest_version) > 0:
                    latest_version = file_version
                    latest_file = file
            except (IndexError, ValueError):
                continue
        
        if latest_file:
            return {
                "has_update": True,
                "message": f"Update available: version {latest_version}",
                "latest_version": latest_version,
                "update_file": os.path.join(update_repo_path, latest_file)
            }
        else:
            return {
                "has_update": False,
                "message": "You have the latest version.",
                "latest_version": current_version
            }
                
    except Exception as e:
        return {
            "has_update": False,
            "message": f"Error checking for updates: {e}",
            "latest_version": "unknown"
        }

def compare_versions(version1: str, version2: str) -> int:
    """
    Compare two version strings.
    
    Returns:
    - 1 if version1 > version2
    - 0 if version1 == version2
    - -1 if version1 < version2
    """
    v1_parts = [int(x) for x in version1.split('.')]
    v2_parts = [int(x) for x in version2.split('.')]
    
    # Pad with zeros if needed
    while len(v1_parts) < len(v2_parts):
        v1_parts.append(0)
    while len(v2_parts) < len(v1_parts):
        v2_parts.append(0)
    
    for i in range(len(v1_parts)):
        if v1_parts[i] > v2_parts[i]:
            return 1
        elif v1_parts[i] < v2_parts[i]:
            return -1
    
    return 0  # Versions are equal

def update_data_file(data_path: str, update_info: Dict) -> bool:
    """
    Update the data file with a newer version.
    
    Parameters:
    -----------
    data_path : str
        Path to the current JSON data file
    update_info : dict
        Information about the available update
    
    Returns:
    --------
    bool
        Whether update was successful
    """
    try:
        # Load current data
        with open(data_path, 'r') as f:
            current_data = json.load(f)
        
        # Create backup before updating
        backup_path = f"{data_path}.bak"
        with open(backup_path, 'w') as f:
            json.dump(current_data, f, indent=2)
        
        console.print(f"[green]Created backup at {backup_path}[/green]")
        
        # Load update data
        with open(update_info['update_file'], 'r') as f:
            update_data = json.load(f)
        
        # Check if the update file has the expected structure
        if isinstance(update_data, list):
            # If the file is a list of records, replace the main data
            merged_data = update_data
            
            # Preserve metadata if it exists
            if isinstance(current_data, dict) and 'metadata' in current_data:
                merged_data = {
                    'metadata': {
                        **current_data['metadata'],
                        'version': update_info['latest_version'],
                        'last_updated': datetime.now().isoformat()
                    },
                    'data': update_data
                }
        elif isinstance(update_data, dict):
            # For dictionary structure, merge appropriately
            if 'data' in update_data:
                # If the update has a 'data' key, use its structure
                merged_data = update_data
                merged_data['metadata'] = merged_data.get('metadata', {})
                merged_data['metadata']['version'] = update_info['latest_version']
                merged_data['metadata']['last_updated'] = datetime.now().isoformat()
            else:
                # Otherwise, treat the whole dict as data
                merged_data = {
                    'metadata': {
                        'version': update_info['latest_version'],
                        'last_updated': datetime.now().isoformat()
                    },
                    'data': update_data
                }
                
        # Write the updated data
        with open(data_path, 'w') as f:
            json.dump(merged_data, f, indent=2)
            
        console.print(f"[bold green]Successfully updated data to version {update_info['latest_version']}[/bold green]")
        return True
        
    except Exception as e:
        console.print(f"[bold red]Error updating data: {e}[/bold red]")
        return False

def display_update_menu(data_path: str):
    """Display the update menu and handle update operations"""
    console.clear()
    console.print("[bold cyan]DATA UPDATE CENTER[/bold cyan]", justify="center")
    
    with console.status("[bold green]Checking for updates...[/bold green]", spinner="dots"):
        update_info = check_for_updates(data_path)
    
    if update_info["has_update"]:
        console.print(f"[bold green]Update available![/bold green] Version: {update_info['latest_version']}")
        
        # Show update details
        update_panel = Panel(
            f"Current version: {update_info.get('current_version', 'Unknown')}\n"
            f"Available version: {update_info['latest_version']}\n\n"
            f"Update file: {os.path.basename(update_info['update_file'])}",
            title="Update Details",
            border_style="green"
        )
        console.print(update_panel)
        
        # Prompt for update
        if Confirm.ask("Would you like to update to the latest version?"):
            with console.status("[bold green]Applying update...[/bold green]", spinner="dots"):
                success = update_data_file(data_path, update_info)
            
            if success:
                console.print("[bold green]✓ Update completed successfully![/bold green]")
            else:
                console.print("[bold red]✗ Update failed. Using existing data.[/bold red]")
        else:
            console.print("[yellow]Update canceled. Using existing data.[/yellow]")
    else:
        console.print(f"[yellow]{update_info['message']}[/yellow]")
    
    console.print("\nPress Enter to continue...", end="")
    input()

def main():
    display_welcome_screen()
    
    # Ask for input data
    console.print("\n[yellow]Choose data source:[/yellow]")
    console.print("1. JSON file")
    console.print("2. QR Code data (as text)")
    
    choice = Prompt.ask("Enter your choice", choices=["1", "2"], default="1")
    
    analysis_results = {}
    data_path = None
    
    if choice == "1":
        data_path = Prompt.ask("Enter path to JSON file", default="scouting_data.json")
        if not os.path.exists(data_path):
            console.print(f"[bold red]Error: File not found at {data_path}[/bold red]")
            return
        analysis_results = analyze_scouting_data(data_path=data_path)
    else:
        data_str = Prompt.ask("Paste QR code data (JSON string)")
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
        console.print("6. Update Data Files")  # New option
        console.print("7. Exit")
        
        menu_choice = Prompt.ask("Select an option", choices=["1", "2", "3", "4", "5", "6", "7"], default="1")
        
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
            if data_path:
                display_update_menu(data_path)
                # Reload analysis with updated data if needed
                analysis_results = analyze_scouting_data(data_path=data_path)
            else:
                console.print("[bold yellow]Update only available for JSON file data sources[/bold yellow]")
                console.print("\nPress Enter to continue...", end="")
                input()
        elif menu_choice == "7":
            break


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[italic]Program terminated by user.[/italic]")
        sys.exit(0)