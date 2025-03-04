import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

def analyze_scouting_data(data_csv=None, data_str=None):
    """
    Analyze robotics scouting data to identify team strengths across autonomous, teleop, and endgame.
    
    Parameters:
    -----------
    data_csv : str, optional
        Path to CSV file containing scouting data
    data_str : str, optional
        String containing CSV data
    
    Returns:
    --------
    dict
        Dictionary containing analysis results
    """
    # Load data - either from CSV file or from string
    if data_csv:
        df = pd.read_csv(data_csv)
    elif data_str:
        import io
        df = pd.read_csv(io.StringIO(data_str))
    else:
        raise ValueError("Either data_csv or data_str must be provided")
    
    # Convert boolean columns - more robust approach
    bool_columns = []
    for col in df.columns:
        # Only check string columns
        if df[col].dtype == object:  # Check dtype instead of using str accessor
            # Check if the column contains TRUE or FALSE values
            sample_values = df[col].dropna().unique()
            if any(val in ['TRUE', 'FALSE'] for val in sample_values if isinstance(val, str)):
                bool_columns.append(col)
    
    # Convert identified boolean columns
    for col in bool_columns:
        df[col] = df[col].map({'TRUE': True, 'FALSE': False})
    
    # Calculate phase scores
    df['auton_total'] = (
        df['autonPoints_CoralScoringLevel1'] +
        df['autonPoints_CoralScoringLevel2'] +
        df['autonPoints_CoralScoringLevel3'] +
        df['autonPoints_CoralScoringLevel4'] +
        df['autonPoints_AlgaeScoringProcessor'] +
        df['autonPoints_AlgaeScoringBarge']
    )
    
    # Add bonus point for left barge in auton
    df.loc[df['autonPoints_LeftBarge'] == True, 'auton_total'] += 5
    
    df['teleop_total'] = (
        df['teleOpPoints_CoralScoringLevel1'] +
        df['teleOpPoints_CoralScoringLevel2'] +
        df['teleOpPoints_CoralScoringLevel3'] +
        df['teleOpPoints_CoralScoringLevel4'] +
        df['teleOpPoints_AlgaeScoringProcessor'] +
        df['teleOpPoints_AlgaeScoringBarge']
    )
    
    # Calculate endgame points
    df['endgame_total'] = 0
    df.loc[df['endPoints_Deep_Climb'] == True, 'endgame_total'] += 15  # Deep climb worth 15 points
    df.loc[df['endPoints_Shallow_Climb'] == True, 'endgame_total'] += 10  # Shallow climb worth 10 points
    df.loc[df['endPoints_Park'] == True, 'endgame_total'] += 5  # Park worth 5 points
    
    # Calculate defense value (binary for now)
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
    
    # Best autonomous teams (top 3)
    best_auton = team_stats.sort_values('auton_total_mean', ascending=False).head(3)
    team_strengths['best_auton_teams'] = best_auton.index.tolist()
    
    # Best teleop teams (top 3)
    best_teleop = team_stats.sort_values('teleop_total_mean', ascending=False).head(3)
    team_strengths['best_teleop_teams'] = best_teleop.index.tolist()
    
    # Best endgame teams (top 3)
    best_endgame = team_stats.sort_values('endgame_total_mean', ascending=False).head(3)
    team_strengths['best_endgame_teams'] = best_endgame.index.tolist()
    
    # Best defense teams
    best_defense = team_stats.sort_values('defense_value_mean', ascending=False)
    best_defense = best_defense[best_defense['defense_value_mean'] > 0].head(3)
    team_strengths['best_defense_teams'] = best_defense.index.tolist()
    
    # Most consistent teams (top 3)
    most_consistent = team_stats.sort_values('consistency', ascending=False).head(3)
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
            'comments': team_data['endPoints_Comments'].tolist()
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
        'team_profiles': team_profiles
    }

def calculate_climbing_percentage(team_data):
    """Calculate the percentage of matches where a team successfully climbed"""
    total_matches = len(team_data)
    if total_matches == 0:
        return 0
    
    climbs = team_data['endPoints_Deep_Climb'].sum() + team_data['endPoints_Shallow_Climb'].sum()
    return round((climbs / total_matches) * 100, 2)

def generate_strategy_report(analysis_results):
    """Generate a comprehensive strategy report based on analysis results"""
    team_strengths = analysis_results['team_strengths']
    team_profiles = analysis_results['team_profiles']
    
    report = "# ROBOTICS COMPETITION STRATEGY REPORT\n\n"
    
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
    
    # Save or show
    if output_dir:
        plt.savefig(f"{output_dir}/team_performance.png", dpi=300, bbox_inches='tight')
    else:
        plt.show()
    
    return plt







# ...existing code...

# Example usage with the provided data
if __name__ == "__main__":
    # Your data in CSV string format
    data_str = """teamNumber,scouterName,matchKey,allianceColor,eventKey,station,autonPoints_CoralScoringLevel1,autonPoints_CoralScoringLevel2,autonPoints_CoralScoringLevel3,autonPoints_CoralScoringLevel4,autonPoints_LeftBarge,autonPoints_AlgaeScoringProcessor,autonPoints_AlgaeScoringBarge,teleOpPoints_CoralScoringLevel1,teleOpPoints_CoralScoringLevel2,teleOpPoints_CoralScoringLevel3,teleOpPoints_CoralScoringLevel4,teleOpPoints_AlgaeScoringBarge,teleOpPoints_AlgaeScoringProcessor,teleOpPoints_Defense,endPoints_Deep_Climb,endPoints_Shallow_Climb,endPoints_Park,endPoints_Comments
5635,Ritesh,1,Red,2025isde1,1,4,3,2,1,TRUE,5,6,3,4,5,6,1,2,TRUE,FALSE,FALSE,FALSE,"Good autonomous, consistent scoring."
172,Sarah,1,Blue,2025isde1,3,2,1,0,0,FALSE,3,2,5,4,3,2,4,3,TRUE,TRUE,FALSE,FALSE,"Strong teleop, good climb."
254,John,2,Red,2025isde1,2,3,2,1,0,TRUE,4,3,6,5,4,3,2,1,FALSE,FALSE,TRUE,FALSE,"Reliable park, decent scoring."
687,Emily,2,Blue,2025isde1,1,1,1,1,1,FALSE,2,1,2,3,4,5,3,4,TRUE,FALSE,FALSE,TRUE,"Defense focused, shallow climb."
330,David,3,Red,2025isde1,3,0,0,0,0,TRUE,1,0,1,2,3,4,5,6,FALSE,TRUE,FALSE,FALSE,"Excellent deep climb, limited scoring."
4481,Jessica,3,Blue,2025isde1,2,2,2,2,2,FALSE,6,5,4,3,2,1,6,5,TRUE,FALSE,TRUE,FALSE,"Great scoring, good park."
195,Michael,4,Red,2025isde1,1,4,4,3,2,TRUE,5,4,3,2,1,0,1,2,FALSE,TRUE,FALSE,FALSE,"Fast autonomous, reliable climb."
2056,Ashley,4,Blue,2025isde1,3,3,3,3,3,FALSE,4,3,2,1,0,1,2,3,TRUE,FALSE,FALSE,TRUE,"Consistent scoring, good defense."
4613,Kevin,5,Red,2025isde1,2,1,0,0,0,TRUE,3,2,5,6,1,2,3,4,FALSE,FALSE,TRUE,FALSE,"Parked, average teleop."
118,Amanda,5,Blue,2025isde1,1,0,1,2,3,FALSE,2,1,6,5,4,3,2,1,TRUE,TRUE,FALSE,FALSE,"Strong climb, some scoring issues."
581,Brian,6,Red,2025isde1,3,2,3,4,5,TRUE,1,0,1,0,5,6,3,2,FALSE,FALSE,FALSE,TRUE,"Defense and shallow climb, minimal scoring."
973,Nicole,6,Blue,2025isde1,2,3,4,5,6,FALSE,6,5,2,1,4,3,5,6,TRUE,TRUE,FALSE,FALSE,"High scoring, successful climb."
1678,Christopher,7,Red,2025isde1,1,4,5,6,1,TRUE,5,6,3,4,2,1,2,1,FALSE,FALSE,TRUE,FALSE,"Great autonomous, good park."
3467,Melissa,7,Blue,2025isde1,3,1,2,3,4,FALSE,4,3,5,6,3,4,1,0,TRUE,TRUE,FALSE,FALSE,"Climb and consistent scoring."
696,Matthew,8,Red,2025isde1,2,5,6,1,2,TRUE,3,2,6,5,1,2,4,3,FALSE,FALSE,FALSE,TRUE,"Shallow climb and defense."
2767,Stephanie,8,Blue,2025isde1,1,6,1,2,3,FALSE,2,1,1,2,5,6,5,4,TRUE,TRUE,FALSE,FALSE,"Successful climb, average scoring."
1538,Andrew,9,Red,2025isde1,3,1,2,3,4,TRUE,1,0,2,3,6,5,1,2,FALSE,FALSE,TRUE,FALSE,"Parked, decent autonomous."
4911,Rebecca,9,Blue,2025isde1,2,2,3,4,5,FALSE,6,5,3,4,2,1,6,5,TRUE,TRUE,FALSE,FALSE,"High scoring, good climb."
6328,Patrick,10,Red,2025isde1,1,3,4,5,6,TRUE,5,6,4,3,0,1,3,4,FALSE,FALSE,FALSE,TRUE,"Defense and shallow climb, some scoring."
2910,Laura,10,Blue,2025isde1,3,4,5,6,1,FALSE,4,3,2,1,6,5,2,1,TRUE,TRUE,FALSE,FALSE,"Consistent scoring and climb."
"""
    
    # Create a directory for the web report
    import os
    report_dir = "web_report"
    os.makedirs(report_dir, exist_ok=True)
    
    # Save visualizations to the report directory
    analysis_results = analyze_scouting_data(data_str=data_str)
    report = generate_strategy_report(analysis_results)
    visualize_team_performance(analysis_results, output_dir=report_dir)
    with open(f"{report_dir}/strategy_report.md", "w") as f:
        f.write(report)
    print(f"Strategy report saved to {report_dir}/strategy_report.md")
    print("Visualizations saved to web_report directory.")
    print("Analysis complete.")