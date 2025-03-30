import requests
import json
import logging

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def getImage():
    return "data:image/png;base64,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"

def test_connection(script_url):
    """
    Sends a GET request to test the connection with the Google Apps Script web app.
    
    Args:
        script_url: URL of the Google Apps Script web app
    """
    try:
        logger.info("Testing connection...")
        response = requests.get(f"{script_url}?type=testconnection")
        logger.info(f"Response status code: {response.status_code}")
        logger.info(f"Response content: {response.text}")
        return response.text
    except Exception as error:
        logger.error(f"Error in test_connection: {str(error)}")
        return f"Error: {str(error)}"

def post_pit_data(script_url):
    """
    Sends a POST request with pit scouting data to the Google Apps Script web app.
    
    Args:
        script_url: URL of the Google Apps Script web app
    """
    try:
        pit_data = {
            "type": "pit",
            "team": "1234",
            "drivetrain": "Tank Drive",
            "auton": "Yes",
            "leaveAuton": "Yes",
            "scoreLocation": "L1 - 2 pieces",
            "scoreType": "Coral only",
            "intakeCoral": "Ground",
            "scoreCoral": "L2",
            "intakeAlgae": "Source",
            "scoreAlgae": "Processor",
            "endgame": "Deep Climb",
            "botImage1": getImage(),
            "botImage2": getImage(),
            "botImage3":getImage()
        }
        logger.info("Sending POST request with pit scouting data...")
        response = requests.post(
            script_url,
            data=json.dumps(pit_data),
            headers={"Content-Type": "application/json"}
        )
        logger.info(f"Response status code: {response.status_code}")
        logger.info(f"Response content: {response.text}")
        return response.text
    except Exception as error:
        logger.error(f"Error in post_pit_data: {str(error)}")
        return f"Error: {str(error)}"

def post_checklist_data(script_url):
    """
    Sends a POST request with robot checklist data to the Google Apps Script web app.
    
    Args:
        script_url: URL of the Google Apps Script web app
    """
    try:
        checklist_data = {
            "type": "checklist",
            "matchKey": "MATCH_001",
            "chassisDriveMotors": True,
            "chassisSteerMotors": False,
            "chassisGearboxes": True,
            "chassisTreadConditions": True,
            "chassisWires": True,
            "chassisBumpers": True,
            "chassisLimelightProtectors": False,
            "ethernetFrontLeftLimelight": True,
            "ethernetFrontRightLimelight": True,
            "ethernetBackLeftLimelight": False,
            "ethernetBackRightLimelight": False,
            "ethernetSwitch": True,
            "ethernetRadio": True,
            "climberString": True,
            "climberClips": True,
            "climberSprings": False,
            "climberBumper": True,
            "climberGearbox": True,
            "climberMotors": True,
            "climberWires": True,
            "climberNutsAndBolts": True,
            "climberReset": False,
            "climberNumber": 2,
            "elevatorRodOfDoom": True,
            "elevatorStage0": True,
            "elevatorStage1": True,
            "elevatorStage2": False,
            "elevatorChain": True,
            "elevatorGearbox": True,
            "elevatorMotors": True,
            "elevatorWires": True,
            "elevatorNutsAndBolts": True,
            "trapdoorPanels": True,
            "trapdoorWires": True,
            "trapdoorSupports": True,
            "trapdoorHinges": True,
            "trapdoorTensioners": True,
            "trapdoorNutsAndBolts": True,
            "trapdoorReset": False,
            "carriageGearbox": True,
            "carriageBeltbox": True,
            "carriageMotors": True,
            "carriageWires": True,
            "carriageNutsAndBolts": True,
            "carriageCoralSlide": True,
            "carriageCarriage": True,
            "gooseneckPanels": True,
            "gooseneckWheels": True,
            "gooseneckBelts": True,
            "gooseneckNutsAndBolts": True,
            "returningBatteryVoltage": 12.5,
            "returningBatteryCCA": 500,
            "returningNumber": 1,
            "outgoingBatteryVoltage": 12.8,
            "outgoingBatteryCCA": 520,
            "outgoingNumber": 2,
            "outgoingBatteryReplaced": False,
            "allianceColor": "Blue",
            "notes": "Robot performed well."
        }
        logger.info("Sending POST request with robot checklist data...")
        response = requests.post(
            script_url,
            data=json.dumps(checklist_data),
            headers={"Content-Type": "application/json"}
        )
        logger.info(f"Response status code: {response.status_code}")
        logger.info(f"Response content: {response.text}")
        return response.text
    except Exception as error:
        logger.error(f"Error in post_checklist_data: {str(error)}")
        return f"Error: {str(error)}"

def get_pit_data(script_url):
    """
    Sends a GET request to retrieve all pit scouting data from the Google Apps Script web app.
    
    Args:
        script_url: URL of the Google Apps Script web app
    """
    try:
        logger.info("Retrieving pit scouting data...")
        response = requests.get(f"{script_url}?type=pit")
        logger.info(f"Response status code: {response.status_code}")
        logger.info(f"Response content: {response.text}")
        return response.text
    except Exception as error:
        logger.error(f"Error in get_pit_data: {str(error)}")
        return f"Error: {str(error)}"

def get_checklist_data(script_url):
    """
    Sends a GET request to retrieve all robot checklist data from the Google Apps Script web app.
    
    Args:
        script_url: URL of the Google Apps Script web app
    """
    try:
        logger.info("Retrieving robot checklist data...")
        response = requests.get(f"{script_url}?type=checklist")
        logger.info(f"Response status code: {response.status_code}")
        logger.info(f"Response content: {response.text}")
        return response.text
    except Exception as error:
        logger.error(f"Error in get_checklist_data: {str(error)}")
        return f"Error: {str(error)}"

def insert_demo_data(script_url):
    """
    Sends a POST request with demo data to the Google Apps Script web app.
    
    Args:
        script_url: URL of the Google Apps Script web app
    """
    try:
        demo_data = {
            "type": "pit",
            "team": "9999",
            "drivetrain": "Swerve Drive",
            "auton": "Yes",
            "leaveAuton": "Yes",
            "scoreLocation": "L2 - 3 pieces",
            "scoreType": "Both",
            "intakeCoral": "Ground",
            "scoreCoral": "L3",
            "intakeAlgae": "Can do ALL",
            "scoreAlgae": "Processor",
            "endgame": "Cycle then Deep Climb",
            "notes": "Hi",
            "botImage1": "demo_image_1",
            "botImage2": "demo_image_2",
            "botImage3": "demo_image_3"
        }
        
        logger.info("Sending POST request with demo data...")
        response = requests.post(
            script_url,
            data=json.dumps(demo_data),
            headers={"Content-Type": "application/json"}
        )
        logger.info(f"Response status code: {response.status_code}")
        logger.info(f"Response content: {response.text}")
        return response.text
    except Exception as error:
        logger.error(f"Error in insert_demo_data: {str(error)}")
        return f"Error: {str(error)}"

def main():
    # Replace with your actual Google Apps Script web app URL
    script_url = "https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec"
    
    print("FRC Scouting Suite Tester")
    print("=========================")
    
    # Ask for the script URL if not hardcoded
    url_input = input(f"Enter Google Apps Script URL [default: {script_url}]: ")
    if url_input.strip():
        script_url = url_input.strip()
    
    # Menu for testing
    while True:
        print("\nOptions:")
        print("1. Test Connection")
        print("2. Post Pit Scouting Data")
        print("3. Post Robot Checklist Data")
        print("4. Get Pit Scouting Data")
        print("5. Get Robot Checklist Data")
        print("6. Insert Demo Data")
        print("7. Exit")
        
        choice = input("Enter your choice: ")
        
        if choice == "1":
            result = test_connection(script_url)
        elif choice == "2":
            result = post_pit_data(script_url)
        elif choice == "3":
            result = post_checklist_data(script_url)
        elif choice == "4":
            result = get_pit_data(script_url)
        elif choice == "5":
            result = get_checklist_data(script_url)
        elif choice == "6":
            result = insert_demo_data(script_url)
        elif choice == "7":
            print("Exiting...")
            break
        else:
            print("Invalid choice. Please try again.")
            continue
        
        print("\nResult:")
        print(result)

if __name__ == "__main__":
    main()