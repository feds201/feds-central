import csv

def convert_to_csv(data_line, output_file="scouting_data.csv"):
    # Define column headers based on FRC scouting data structure
    headers = [
        "Team Number", 
        "Scouter Name",
        "Match Number", 
        "Alliance", 
        "Event Code",
        "Auto Score L1", 
        "Auto Score L2", 
        "Auto Score L3", 
        "Auto Score L4",
        "Auto Algae", 
        "Auto Successful",
        "Teleop Coral L4", 
        "Teleop Coral L3", 
        "Teleop Coral L2", 
        "Teleop Coral L1",
        "Teleop Algae Processor", 
        "Teleop Algae Barge", 
        "Teleop Algae Pickup", 
        "Endgame Position",
        "Defense Played", 
        "Robot Disabled", 
        "Tipped Over", 
        "No Show",
        "Comments"
    ]
    
    # Parse the comma-separated line while respecting quotes
    csv_reader = csv.reader([data_line])
    values = next(csv_reader)
    
    # Write to CSV file
    with open(output_file, 'w', newline='') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow(headers)
        csv_writer.writerow(values)
    
    print(f"CSV file created successfully: {output_file}")

# The data to convert
data = '5635,Ritesh,1,Red,2025isde1,1,4,3,2,1,TRUE,5,6,3,4,5,6,1,2,TRUE,FALSE,FALSE,FALSE,"Good autonomous, consistent scoring."'

# Convert the data
convert_to_csv(data)

# If you want to process multiple lines
def process_multiple_lines(input_file, output_file="scouting_data.csv"):
    with open(input_file, 'r') as f:
        lines = f.readlines()
    
    headers = [
        "Team Number", 
        "Scouter Name",
        "Match Number", 
        "Alliance", 
        "Event Code",
        "Auto Score L1", 
        "Auto Score L2", 
        "Auto Score L3", 
        "Auto Score L4",
        "Auto Algae", 
        "Auto Successful",
        "Teleop Coral L4", 
        "Teleop Coral L3", 
        "Teleop Coral L2", 
        "Teleop Coral L1",
        "Teleop Algae Processor", 
        "Teleop Algae Barge", 
        "Teleop Algae Pickup", 
        "Endgame Position",
        "Defense Played", 
        "Robot Disabled", 
        "Tipped Over", 
        "No Show",
        "Comments"
    ]
    
    with open(output_file, 'w', newline='') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow(headers)
        
        for line in lines:
            line = line.strip()
            if line:  # Skip empty lines
                csv_reader = csv.reader([line])
                values = next(csv_reader)
                csv_writer.writerow(values)
    
    print(f"CSV file with multiple records created: {output_file}")

# Example usage for multiple lines:
# process_multiple_lines("input_data.txt")


if __name__ == "__main__":

    while True:
        print("Enter the data to convert to CSV (or 'exit' to quit):")
        data = input()
        if data.lower() == "exit":
            break
        convert_to_csv(data)