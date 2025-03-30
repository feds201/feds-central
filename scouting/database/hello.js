/**
 * FRC Pit Scouting App - Google Apps Script Backend
 * This script handles storing and retrieving robot scouting data for FRC competitions.
 */

// Global settings
const SHEET_NAME = "Pit Scouting 2025";
const FOLDER_NAME = "FRC Pit Scouting Images";
const DEBUG_MODE = true; // Set to false in production

// Global settings for the new sheet
const CHECKLIST_SHEET_NAME = "Robot Checklist 2025";

/**
 * Handles HTTP POST requests from the scouting app
 * @param {Object} e - The event object from the POST request
 * @return {TextOutput} Response to the client
 */
function doPost(e) {
  try {
    logInfo("Received POST request");

    // Validate request data
    if (!e || !e.postData || !e.postData.contents) {
      return createErrorResponse("Invalid Request: Missing post data");
    }

    // Parse and validate the JSON data
    let data;
    try {
      data = JSON.parse(e.postData.contents);
    } catch (err) {
      return createErrorResponse("Invalid JSON format: " + err.message);
    }

    // Check for the 'type' key in the request
    if (!data.type) {
      return createErrorResponse("Missing required field: type (must be 'testconnection', 'pit', or 'checklist')");
    }

    // Route based on the 'type' field
    switch (data.type.toLowerCase()) {
      case 'testconnection':
        return testConnection();
      case 'pit':
        // Handle Pit Scouting data
        if (!data.team) {
          return createErrorResponse("Missing required field: team for pit scouting data");
        }
        return handlePitScoutingData(data);
      case 'checklist':
        // Handle Robot Checklist data
        if (!data.matchKey) {
          return createErrorResponse("Missing required field: matchKey for checklist data");
        }
        return handleChecklistData(data);
      default:
        return createErrorResponse("Invalid type: Must be 'testconnection', 'pit', or 'checklist'");
    }
  } catch (error) {
    logError("Error in doPost: " + error.toString());
    return createErrorResponse("Server error: " + error.toString());
  }
}

/**
 * Handles Pit Scouting data
 * @param {Object} data - The pit scouting data
 * @return {TextOutput} Response to the client
 */
function handlePitScoutingData(data) {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);
    const teamNumber = data.team;

    // Check if the team already exists in the sheet
    const teamRow = findTeamRow(sheet, teamNumber);

    // Process all three images
    let imageFileIds = ["", "", ""]; // Default empty file IDs for all three images
    if (data.botImage1 && data.botImage1.length > 100) {
      try {
        imageFileIds[0] = saveImageToDrive(data.botImage1, teamNumber, 1);
      } catch (imgError) {
        logError("Failed to save image 1: " + imgError.toString());
      }
    }
    if (data.botImage2 && data.botImage2.length > 100) {
      try {
        imageFileIds[1] = saveImageToDrive(data.botImage2, teamNumber, 2);
      } catch (imgError) {
        logError("Failed to save image 2: " + imgError.toString());
      }
    }
    if (data.botImage3 && data.botImage3.length > 100) {
      try {
        imageFileIds[2] = saveImageToDrive(data.botImage3, teamNumber, 3);
      } catch (imgError) {
        logError("Failed to save image 3: " + imgError.toString());
      }
    }

    if (teamRow) {
      // Update existing team data
      updateTeamData(sheet, teamRow, data, imageFileIds);
      logInfo("Team " + teamNumber + " data updated!");
      return ContentService.createTextOutput("Team " + teamNumber + " data updated successfully")
        .setMimeType(ContentService.MimeType.TEXT);
    } else {
      // Add new team data
      addTeamData(sheet, data, imageFileIds);
      logInfo("Team " + teamNumber + " data added!");
      return ContentService.createTextOutput("Team " + teamNumber + " data added successfully")
        .setMimeType(ContentService.MimeType.TEXT);
    }
  } catch (error) {
    logError("Error in handlePitScoutingData: " + error.toString());
    return createErrorResponse("Error processing pit scouting data: " + error.toString());
  }
}

/**
 * Updates existing team data in the sheet
 * @param {Sheet} sheet - The spreadsheet sheet
 * @param {number} teamRow - The row number to update
 * @param {Object} data - The team data
 * @param {Array} imageFileIds - Array of Drive file IDs for the bot images
 */
function updateTeamData(sheet, teamRow, data, imageFileIds) {
  try {
    // Update main data columns
    sheet.getRange(teamRow, 2, 1, 10).setValues([
      [
        data.drivetrain || "",
        data.auton || "",
        data.leaveAuton || "",
        data.scoreLocation || "",
        data.scoreType || "",
        data.intakeCoral || "",
        data.scoreCoral || "",
        data.intakeAlgae || "",
        data.scoreAlgae || "",
        data.endgame || "",
      ],
    ]);

    // Update image IDs (columns 12, 13, 14)
    sheet.getRange(teamRow, 12, 1, 3).setValues([
      [imageFileIds[0] || "", imageFileIds[1] || "", imageFileIds[2] || ""],
    ]);

    // Update image formulas for all three images if there are new images
    if (imageFileIds[0]) {
      updateImageFormula(sheet, teamRow, imageFileIds[0], 15); // Preview Image 1
    }

    if (imageFileIds[1]) {
      updateImageFormula(sheet, teamRow, imageFileIds[1], 16); // Preview Image 2
    }

    if (imageFileIds[2]) {
      updateImageFormula(sheet, teamRow, imageFileIds[2], 17); // Preview Image 3
    }

    // Update timestamp (column 18)
    sheet.getRange(teamRow, 18).setValue(new Date());
  } catch (error) {
    logError("Error in updateTeamData: " + error.toString());
    throw error;
  }
}

/**
 * Adds new team data to the sheet
 * @param {Sheet} sheet - The spreadsheet sheet
 * @param {Object} data - The team data
 * @param {Array} imageFileIds - Array of Drive file IDs for the bot images
 * @return {number} The row number of the new data
 */
function addTeamData(sheet, data, imageFileIds) {
  try {
    const lastRow = sheet.getLastRow() + 1;

    // Set main data columns
    sheet.getRange(lastRow, 1, 1, 11).setValues([
      [
        data.team,
        data.drivetrain || "",
        data.auton || "",
        data.leaveAuton || "",
        data.scoreLocation || "",
        data.scoreType || "",
        data.intakeCoral || "",
        data.scoreCoral || "",
        data.intakeAlgae || "",
        data.scoreAlgae || "",
        data.endgame || "",
      ],
    ]);

    // Set image IDs (columns 12, 13, 14)
    sheet.getRange(lastRow, 12, 1, 3).setValues([
      [imageFileIds[0] || "", imageFileIds[1] || "", imageFileIds[2] || ""],
    ]);

    // Set timestamp (column 18)
    sheet.getRange(lastRow, 18).setValue(new Date());

    // Set image formulas for all three images if they exist
    if (imageFileIds[0]) {
      updateImageFormula(sheet, lastRow, imageFileIds[0], 15); // Preview Image 1
    }

    if (imageFileIds[1]) {
      updateImageFormula(sheet, lastRow, imageFileIds[1], 16); // Preview Image 2
    }

    if (imageFileIds[2]) {
      updateImageFormula(sheet, lastRow, imageFileIds[2], 17); // Preview Image 3
    }

    return lastRow;
  } catch (error) {
    logError("Error in addTeamData: " + error.toString());
    throw error;
  }
}

/**
 * Updates the IMAGE formula in the sheet
 * @param {Sheet} sheet - The spreadsheet sheet
 * @param {number} row - The row number
 * @param {string} imageFileId - The Drive file ID
 * @param {number} column - The column number for the image formula
 */
function updateImageFormula(sheet, row, imageFileId, column) {
  const imageUri = "https://drive.google.com/uc?export=download&id=" + imageFileId;
  sheet.getRange(row, column).setFormula('=IMAGE("' + imageUri + '")');
  logInfo("Image added: " + imageUri);
}

/**
 * Finds a team's row in the sheet
 * @param {Sheet} sheet - The spreadsheet sheet
 * @param {string|number} teamNumber - The team number to find
 * @return {number|null} The row number or null if not found
 */
function findTeamRow(sheet, teamNumber) {
  try {
    const data = sheet.getDataRange().getValues();
    for (let i = 1; i < data.length; i++) {
      // Skip header
      if (data[i][0] == teamNumber) {
        // Team Number is in the first column
        return i + 1; // Return the row number (1-based index)
      }
    }
    return null; // Return null if the team is not found
  } catch (error) {
    logError("Error in findTeamRow: " + error.toString());
    throw error;
  }
}

/**
 * Saves a base64 image to Google Drive
 * @param {string} base64Image - Base64-encoded image data
 * @param {string|number} teamNumber - The team number for the image filename
 * @param {number} imageNumber - The image number (1, 2, or 3)
 * @return {string} The Drive file ID
 */
function saveImageToDrive(base64Image, teamNumber, imageNumber) {
  try {
    // Remove data URL prefix if present
    const base64Data = base64Image.replace(
      /^data:image\/(png|jpeg|jpg);base64,/,
      ""
    );

    const folder = getDriveFolder();
    const decodedImage = Utilities.base64Decode(base64Data);
    const filename = "team_" + teamNumber + "_" + imageNumber + ".png";
    const blob = Utilities.newBlob(decodedImage, "image/png", filename);

    // Check if an image already exists for this team and image number
    const existingFiles = folder.getFilesByName(filename);
    if (existingFiles.hasNext()) {
      // Delete existing file
      existingFiles.next().setTrashed(true);
    }

    const file = folder.createFile(blob);
    return file.getId();
  } catch (error) {
    logError("Error saving image: " + error.toString());
    throw error;
  }
}

/**
 * Gets or creates the Drive folder for storing images
 * @return {Folder} The Drive folder
 */
function getDriveFolder() {
  try {
    const folders = DriveApp.getFoldersByName(FOLDER_NAME);

    if (folders.hasNext()) {
      return folders.next();
    } else {
      return DriveApp.createFolder(FOLDER_NAME);
    }
  } catch (error) {
    logError("Error in getDriveFolder: " + error.toString());
    throw error;
  }
}

/**
 * Retrieves all scouting data from the sheet and returns as JSON
 * @return {TextOutput} JSON response with all team data
 */
function doGet(e) {
  try {
    logInfo("Received GET request");
    
    // Check for the 'type' parameter
    if (!e || !e.parameter || !e.parameter.type) {
      return createErrorResponse("Missing required parameter: type (must be 'testconnection', 'pit', or 'checklist')");
    }
    
    // Route based on the 'type' parameter
    switch (e.parameter.type.toLowerCase()) {
      case 'testconnection':
        return testConnection();
      case 'pit':
        return getScoutingData();
      case 'checklist':
        return getChecklistData();
      default:
        return createErrorResponse("Invalid type: Must be 'testconnection', 'pit', or 'checklist'");
    }
  } catch (error) {
    logError("Error in doGet: " + error.toString());
    return createErrorResponse("Server error: " + error.toString());
  }
}

/**
 * Gets all scouting data from the sheet
 * @return {TextOutput} JSON response with all team data
 */
function getScoutingData() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);
    const data = sheet.getDataRange().getValues();
    const headers = data[0]; // Save headers for reference

    const result = [];
    for (let i = 1; i < data.length; i++) {
      // Skip headers
      const row = data[i];

      // Create a team object with all properties
      const team = {
        team: row[0],
        drivetrain: row[1],
        auton: row[2],
        leaveAuton: row[3],
        scoreLocation: row[4],
        scoreType: row[5],
        intakeCoral: row[6],
        scoreCoral: row[7],
        intakeAlgae: row[8],
        scoreAlgae: row[9],
        endgame: row[10],
        botImageId1: row[11],
        botImageId2: row[12],
        botImageId3: row[13],
        timestamp: formatTimestamp(row[17]),
      };

      // Add download URLs if there are images
      if (row[11]) {
        team.botImageUrl1 =
          "https://drive.google.com/uc?export=download&id=" + row[11];
      }

      if (row[12]) {
        team.botImageUrl2 =
          "https://drive.google.com/uc?export=download&id=" + row[12];
      }

      if (row[13]) {
        team.botImageUrl3 =
          "https://drive.google.com/uc?export=download&id=" + row[13];
      }

      result.push(team);
    }

    logInfo("Returned " + result.length + " teams data");
    return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(
      ContentService.MimeType.JSON
    );
  } catch (error) {
    logError("Error in getScoutingData: " + error.toString());
    return createErrorResponse("Error retrieving scouting data: " + error.toString());
  }
}

/**
 * Test endpoint to verify connectivity
 * @return {TextOutput} JSON response with status
 */
function testConnection() {
  return ContentService.createTextOutput(
    JSON.stringify({
      status: "OK",
      timestamp: new Date().toISOString(),
      message: "Connection successful!",
    })
  ).setMimeType(ContentService.MimeType.JSON);
}

/**
 * Tests POST data processing by simulating a POST request
 * Can be run manually from the script editor for testing
 */
function testPostData() {
  // Create a test object that simulates a POST event
  const testEvent = {
    postData: {
      contents: JSON.stringify({
        team: "9876",
        drivetrain: "Tank Drive",
        auton: "Yes",
        leaveAuton: "Yes",
        scoreLocation: "L1 - 2 pieces",
        scoreType: "Coral only",
        intakeCoral: "Ground",
        scoreCoral: "L2",
        intakeAlgae: "Source",
        scoreAlgae: "Processor",
        endgame: "Deep Climb",
        botImage1: generateSampleImageBase64(),
        botImage2: generateSampleImageBase64(),
        botImage3: generateSampleImageBase64(),
      }),
    },
  };

  // Process the test event
  const response = doPost(testEvent);

  // Log the result for inspection
  Logger.log("Test POST response: " + response.getContent());

  return response.getContent();
}

/**
 * Tests GET data retrieval by simulating a GET request
 * Can be run manually from the script editor for testing
 */
function testGetData() {
  // Create a test object that simulates a GET event
  const testEvent = {
    parameter: {
      function: "getScoutingData",
    },
  };

  // Process the test event
  const response = doGet(testEvent);

  // Log the result for inspection
  Logger.log("Test GET response: " + response.getContent());

  return JSON.parse(response.getContent());
}

/**
 * Clears all data from the test sheet, keeping headers
 * Can be run manually from the script editor for testing
 */
function clearTestSheet() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);
    const lastRow = sheet.getLastRow();

    if (lastRow > 1) {
      sheet.deleteRows(2, lastRow - 1);
      SpreadsheetApp.getUi().alert("Test sheet cleared successfully");
      Logger.log("Test sheet cleared successfully");
    } else {
      SpreadsheetApp.getUi().alert("Test sheet is already empty");
      Logger.log("Test sheet is already empty");
    }
  } catch (error) {
    logError("Error clearing test sheet: " + error.toString());
    SpreadsheetApp.getUi().alert("Error clearing test sheet: " + error.toString());
  }
}

/**
 * Validate the entire sheet structure and data integrity
 * Can be run manually from the script editor for testing
 */
function validateSheetData() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);
    const data = sheet.getDataRange().getValues();

    if (data.length <= 1) {
      const result = { valid: true, message: "Sheet is empty (only headers)", rowCount: 0 };
      SpreadsheetApp.getUi().alert("Validation Result: " + result.message);
      return result;
    }

    let issues = [];
    let validRowCount = 0;

    // Check each row
    for (let i = 1; i < data.length; i++) {
      const row = data[i];
      const rowNum = i + 1;

      // Check team number
      if (!row[0]) {
        issues.push(`Row ${rowNum}: Missing team number`);
        continue;
      }

      // Check image ID and formula
      if (row[11] && !row[13]) {
        issues.push(`Row ${rowNum}: Image ID exists but formula is missing`);
      }

      // Check timestamp
      if (!row[12]) {
        issues.push(`Row ${rowNum}: Missing timestamp`);
      }

      validRowCount++;
    }

    const result = {
      valid: issues.length === 0,
      issues: issues,
      rowCount: validRowCount,
      message:
        issues.length === 0
          ? `All ${validRowCount} rows are valid`
          : `Found ${issues.length} issues in the data`,
    };
    
    // Show the results in a better format for complex data
    if (issues.length === 0) {
      SpreadsheetApp.getUi().alert("Validation Result: " + result.message);
    } else {
      const htmlOutput = HtmlService
        .createHtmlOutput('<p><strong>Validation Issues:</strong></p><ul><li>' + 
                         issues.join('</li><li>') + 
                         '</li></ul>')
        .setWidth(400)
        .setHeight(300);
      SpreadsheetApp.getUi().showModalDialog(htmlOutput, 'Validation Results');
    }
    
    return result;
  } catch (error) {
    logError("Error validating sheet data: " + error.toString());
    SpreadsheetApp.getUi().alert("Error: " + error.toString());
    return { valid: false, message: "Error: " + error.toString() };
  }
}

/**
 * Checks if all required services (Spreadsheet, Drive) are accessible
 * Can be run manually from the script editor for testing
 */
function checkServices() {
  const results = {
    spreadsheet: false,
    sheet: false,
    drive: false,
    folder: false,
  };

  try {
    // Check spreadsheet access
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    results.spreadsheet = !!ss;

    // Check sheet access
    const sheet = ss.getSheetByName(SHEET_NAME);
    results.sheet = !!sheet;

    // Check Drive access
    const testAccess = DriveApp.getRootFolder();
    results.drive = !!testAccess;

    // Check folder access
    const folders = DriveApp.getFoldersByName(FOLDER_NAME);
    results.folder = folders.hasNext();

    const allOk = Object.values(results).every(Boolean);

    const result = {
      success: allOk,
      services: results,
      message: allOk ? "All services are accessible" : "Some services are not accessible",
    };
    
    // Show results in a formatted dialog
    const serviceStatus = Object.entries(results).map(([name, status]) => 
      `${name}: ${status ? '✅' : '❌'}`).join('<br>');
    
    const htmlOutput = HtmlService
      .createHtmlOutput(`<p><strong>${result.message}</strong></p><p>${serviceStatus}</p>`)
      .setWidth(300)
      .setHeight(200);
    
    SpreadsheetApp.getUi().showModalDialog(htmlOutput, 'Service Check Results');
    
    return result;
  } catch (error) {
    logError("Error checking services: " + error.toString());
    SpreadsheetApp.getUi().alert("Error checking services: " + error.toString());
    return {
      success: false,
      services: results,
      message: "Error: " + error.toString(),
    };
  }
}

/**
 * Inserts demo data for testing
 * Can be run manually from the script editor for testing
 */
function insertDemoData() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);

    // Generate sample images
    const sampleBase64 = generateSampleImageBase64();

    // Prepare demo data
    const demoData = {
      team: "9999",
      drivetrain: "Swerve Drive",
      auton: "Yes",
      leaveAuton: "Yes",
      scoreLocation: "L2 - 3 pieces",
      scoreType: "Both",
      intakeCoral: "Ground",
      scoreCoral: "L3",
      intakeAlgae: "Can do ALL",
      scoreAlgae: "Processor",
      endgame: "Cycle then Deep Climb",
      notes : "Hi",
      botImage1: sampleBase64,
      botImage2: sampleBase64,
      botImage3: sampleBase64,
    };

    // Process using the main function
    const testEvent = {
      postData: {
        contents: JSON.stringify(demoData),
      },
    };

    const response = doPost(testEvent);
    Logger.log("Demo data inserted: " + response.getContent());
    
    // Show feedback to the user
    SpreadsheetApp.getUi().alert("Success: " + response.getContent());

    return response.getContent();
  } catch (error) {
    logError("Error in insertDemoData: " + error.toString());
    SpreadsheetApp.getUi().alert("Error: " + error.toString());
    return "Error: " + error.toString();
  }
}

/**
 * Validate the entire sheet structure and data integrity
 * Can be run manually from the script editor for testing
 */
function validateSheetData() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);
    const data = sheet.getDataRange().getValues();

    if (data.length <= 1) {
      const result = { valid: true, message: "Sheet is empty (only headers)", rowCount: 0 };
      SpreadsheetApp.getUi().alert("Validation Result: " + result.message);
      return result;
    }

    let issues = [];
    let validRowCount = 0;

    // Check each row
    for (let i = 1; i < data.length; i++) {
      const row = data[i];
      const rowNum = i + 1;

      // Check team number
      if (!row[0]) {
        issues.push(`Row ${rowNum}: Missing team number`);
        continue;
      }

      // Check image ID and formula
      if (row[11] && !row[13]) {
        issues.push(`Row ${rowNum}: Image ID exists but formula is missing`);
      }

      // Check timestamp
      if (!row[12]) {
        issues.push(`Row ${rowNum}: Missing timestamp`);
      }

      validRowCount++;
    }

    const result = {
      valid: issues.length === 0,
      issues: issues,
      rowCount: validRowCount,
      message:
        issues.length === 0
          ? `All ${validRowCount} rows are valid`
          : `Found ${issues.length} issues in the data`,
    };
    
    // Show the results in a better format for complex data
    if (issues.length === 0) {
      SpreadsheetApp.getUi().alert("Validation Result: " + result.message);
    } else {
      const htmlOutput = HtmlService
        .createHtmlOutput('<p><strong>Validation Issues:</strong></p><ul><li>' + 
                         issues.join('</li><li>') + 
                         '</li></ul>')
        .setWidth(400)
        .setHeight(300);
      SpreadsheetApp.getUi().showModalDialog(htmlOutput, 'Validation Results');
    }
    
    return result;
  } catch (error) {
    logError("Error validating sheet data: " + error.toString());
    SpreadsheetApp.getUi().alert("Error: " + error.toString());
    return { valid: false, message: "Error: " + error.toString() };
  }
}

/**
 * Checks if all required services (Spreadsheet, Drive) are accessible
 * Can be run manually from the script editor for testing
 */
function checkServices() {
  const results = {
    spreadsheet: false,
    sheet: false,
    drive: false,
    folder: false,
  };

  try {
    // Check spreadsheet access
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    results.spreadsheet = !!ss;

    // Check sheet access
    const sheet = ss.getSheetByName(SHEET_NAME);
    results.sheet = !!sheet;

    // Check Drive access
    const testAccess = DriveApp.getRootFolder();
    results.drive = !!testAccess;

    // Check folder access
    const folders = DriveApp.getFoldersByName(FOLDER_NAME);
    results.folder = folders.hasNext();

    const allOk = Object.values(results).every(Boolean);

    const result = {
      success: allOk,
      services: results,
      message: allOk ? "All services are accessible" : "Some services are not accessible",
    };
    
    // Show results in a formatted dialog
    const serviceStatus = Object.entries(results).map(([name, status]) => 
      `${name}: ${status ? '✅' : '❌'}`).join('<br>');
    
    const htmlOutput = HtmlService
      .createHtmlOutput(`<p><strong>${result.message}</strong></p><p>${serviceStatus}</p>`)
      .setWidth(300)
      .setHeight(200);
    
    SpreadsheetApp.getUi().showModalDialog(htmlOutput, 'Service Check Results');
    
    return result;
  } catch (error) {
    logError("Error checking services: " + error.toString());
    SpreadsheetApp.getUi().alert("Error checking services: " + error.toString());
    return {
      success: false,
      services: results,
      message: "Error: " + error.toString(),
    };
  }
}

/**
 * Clears all data from the test sheet, keeping headers
 * Can be run manually from the script editor for testing
 */
function clearTestSheet() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);
    const lastRow = sheet.getLastRow();

    if (lastRow > 1) {
      sheet.deleteRows(2, lastRow - 1);
      SpreadsheetApp.getUi().alert("Test sheet cleared successfully");
      Logger.log("Test sheet cleared successfully");
    } else {
      SpreadsheetApp.getUi().alert("Test sheet is already empty");
      Logger.log("Test sheet is already empty");
    }
  } catch (error) {
    logError("Error clearing test sheet: " + error.toString());
    SpreadsheetApp.getUi().alert("Error clearing test sheet: " + error.toString());
  }
}

/**
 * Runs the testConnection function and shows the result
 */
function testConnectionWithFeedback() {
  try {
    const response = testConnection();
    const result = JSON.parse(response.getContent());
    
    SpreadsheetApp.getUi().alert(`Connection Status: ${result.status}\n\nMessage: ${result.message}`);
  } catch (error) {
    SpreadsheetApp.getUi().alert("Error testing connection: " + error.toString());
  }
}

/**
 * Creates a menu in the spreadsheet UI
 */
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu("Pit Scouting")
    .addItem("Insert Demo Data", "insertDemoData")
    .addItem("Test Connection", "testConnectionWithFeedback")
    .addItem("Validate Sheet Data", "validateSheetData")
    .addItem("Check Services", "checkServices")
    .addSeparator()
    .addItem("Clear Test Data", "clearTestSheet")
    .addToUi();
}
// ...existing code...

/**
 * Tests GET data retrieval by simulating a GET request
 * Can be run manually from the script editor for testing
 */
function testGetData() {
  // Create a test object that simulates a GET event
  const testEvent = {
    parameter: {
      function: "getScoutingData",
    },
  };

  // Process the test event
  const response = doGet(testEvent);

  // Log the result for inspection
  Logger.log("Test GET response: " + response.getContent());

  return JSON.parse(response.getContent());
}

/**
 * Tests the image saving functionality
 * Can be run manually from the script editor for testing
 */
function testImageSaving() {
  // Generate a simple small red dot as a PNG
  const sampleBase64 = generateSampleImageBase64();

  try {
    const imageId = saveImageToDrive(sampleBase64, "TEST123", 1);
    Logger.log("Test image saved with ID: " + imageId);
    return imageId;
  } catch (error) {
    Logger.log("Test image saving failed: " + error.toString());
    return null;
  }
}

/**
 * Creates a test sheet structure for testing
 * Can be run manually from the script editor for testing
 */
function setupTestSheet() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(SHEET_NAME);

    // If sheet exists, offer to reset it
    if (sheet) {
      Logger.log("Test sheet already exists. Use clearTestSheet() to reset it.");
      return sheet;
    }

    // Create new sheet with headers
    sheet = ss.insertSheet(SHEET_NAME);

    // Set up headers
    const headers = [
      "Team Number",
      "Drivetrain",
      "Auton?",
      "Leaves in Auton?",
      "Score Location",
      "Score Type",
      "Coral Intake",
      "Coral Scoring",
      "Algae Intake",
      "Algae Scoring",
      "Endgame",
      "Image ID 1",
      "Image ID 2",
      "Image ID 3",
      "Timestamp",
      "Robot Image 1",
      "Robot Image 2",
      "Robot Image 3",
    ];

    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight("bold");
    sheet.setFrozenRows(1);

    // Format columns
    sheet.setColumnWidth(14, 200); // Make the image column wider

    Logger.log("Test sheet created successfully");
    return sheet;
  } catch (error) {
    Logger.log("Error setting up test sheet: " + error.toString());
    return null;
  }
}


/**
 * Inserts demo data for testing
 * Can be run manually from the script editor for testing
 */
function insertDemoData() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);

    // Generate sample images
    const sampleBase64 = generateSampleImageBase64();

    // Prepare demo data
    const demoData = {
      team: "9999",
      drivetrain: "Swerve Drive",
      auton: "Yes",
      leaveAuton: "Yes",
      scoreLocation: "L2 - 3 pieces",
      scoreType: "Both",
      intakeCoral: "Ground",
      scoreCoral: "L3",
      intakeAlgae: "Can do ALL",
      scoreAlgae: "Processor",
      endgame: "Cycle then Deep Climb",
      notes : "Hi",
      botImage1: sampleBase64,
      botImage2: sampleBase64,
      botImage3: sampleBase64,
    };

    // Process using the main function
    const testEvent = {
      postData: {
        contents: JSON.stringify(demoData),
      },
    };

    const response = doPost(testEvent);
    Logger.log("Demo data inserted: " + response.getContent());
    return response.getContent();
  } catch (error) {
    logError("Error in insertDemoData: " + error.toString());
    return "Error: " + error.toString();
  }
}

/**
 * Validate the entire sheet structure and data integrity
 * Can be run manually from the script editor for testing
 */
function validateSheetData() {
  try {
    const sheet = getSheetOrDie(SHEET_NAME);
    const data = sheet.getDataRange().getValues();

    if (data.length <= 1) {
      return { valid: true, message: "Sheet is empty (only headers)", rowCount: 0 };
    }

    let issues = [];
    let validRowCount = 0;

    // Check each row
    for (let i = 1; i < data.length; i++) {
      const row = data[i];
      const rowNum = i + 1;

      // Check team number
      if (!row[0]) {
        issues.push(`Row ${rowNum}: Missing team number`);
        continue;
      }

      // Check image ID and formula
      if (row[11] && !row[13]) {
        issues.push(`Row ${rowNum}: Image ID exists but formula is missing`);
      }

      // Check timestamp
      if (!row[12]) {
        issues.push(`Row ${rowNum}: Missing timestamp`);
      }

      validRowCount++;
    }

    return {
      valid: issues.length === 0,
      issues: issues,
      rowCount: validRowCount,
      message:
        issues.length === 0
          ? `All ${validRowCount} rows are valid`
          : `Found ${issues.length} issues in the data`,
    };
  } catch (error) {
    logError("Error validating sheet data: " + error.toString());
    return { valid: false, message: "Error: " + error.toString() };
  }
}

/**
 * Checks if all required services (Spreadsheet, Drive) are accessible
 * Can be run manually from the script editor for testing
 */
function checkServices() {
  const results = {
    spreadsheet: false,
    sheet: false,
    drive: false,
    folder: false,
  };

  try {
    // Check spreadsheet access
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    results.spreadsheet = !!ss;

    // Check sheet access
    const sheet = ss.getSheetByName(SHEET_NAME);
    results.sheet = !!sheet;

    // Check Drive access
    const testAccess = DriveApp.getRootFolder();
    results.drive = !!testAccess;

    // Check folder access
    const folders = DriveApp.getFoldersByName(FOLDER_NAME);
    results.folder = folders.hasNext();

    const allOk = Object.values(results).every(Boolean);

    return {
      success: allOk,
      services: results,
      message: allOk ? "All services are accessible" : "Some services are not accessible",
    };
  } catch (error) {
    logError("Error checking services: " + error.toString());
    return {
      success: false,
      services: results,
      message: "Error: " + error.toString(),
    };
  }
}

// ===== Utility Functions =====

/**
 * Formats a timestamp for JSON output
 * @param {Date} timestamp - The timestamp to format
 * @return {string} Formatted timestamp
 */
function formatTimestamp(timestamp) {
  if (!timestamp) return "";

  try {
    if (typeof timestamp === "string") {
      timestamp = new Date(timestamp);
    }
    return timestamp.toISOString();
  } catch (e) {
    return String(timestamp);
  }
}

/**
 * Gets a sheet by name or throws an error
 * @param {string} sheetName - The name of the sheet
 * @return {Sheet} The sheet object
 */
function getSheetOrDie(sheetName) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);
  if (!sheet) {
    throw new Error(`Sheet "${sheetName}" not found!`);
  }
  return sheet;
}

/**
 * Creates an error response
 * @param {string} message - The error message
 * @return {TextOutput} Error response object
 */
function createErrorResponse(message) {
  logError(message);
  return ContentService.createTextOutput(
    JSON.stringify({
      status: "error",
      message: message,
      timestamp: new Date().toISOString(),
    })
  ).setMimeType(ContentService.MimeType.JSON);
}

/**
 * Logs an info message
 * @param {string} message - The message to log
 */
function logInfo(message) {
  if (DEBUG_MODE) {
    Logger.log("✅ " + message);
  }
}

/**
 * Logs an error message
 * @param {string} message - The error message to log
 */
function logError(message) {
  Logger.log("❌ " + message);
}

/**
 * Generates a sample base64 image (a red dot)
 * @return {string} Base64-encoded PNG
 */
function generateSampleImage() {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  canvas.width = 10;
  canvas.height = 10;
  ctx.fillStyle = 'red';
  ctx.fillRect(0, 0, 10, 10);
  return canvas.toDataURL('image/png').split(',')[1];
}

function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu("Pit Scouting")
    .addItem("Insert Demo Data", "insertDemoData")
    .addItem("Test Connection", "testConnectionWithFeedback")
    .addItem("Validate Sheet Data", "validateSheetData")
    .addItem("Check Services", "checkServices")
    .addSeparator()
    .addItem("Clear Test Data", "clearTestSheet")
    .addToUi();
}

/**
 * Handles HTTP POST requests for the checklist sheet
 * @param {Object} data - The data object from the POST request
 * @return {TextOutput} Response to the client
 */
function handleChecklistData(data) {
  try {
    // Validate required fields
    if (!data.matchKey) {
      return createErrorResponse("Missing required field: matchKey");
    }

    const sheet = getSheetOrDie(CHECKLIST_SHEET_NAME);
    const matchKey = data.matchKey;

    // Check if the matchKey already exists in the sheet
    const matchRow = findMatchRow(sheet, matchKey);

    if (matchRow) {
      // Update existing match data
      updateChecklistData(sheet, matchRow, data);
      logInfo("Match " + matchKey + " data updated!");
      return ContentService.createTextOutput("Match " + matchKey + " data updated successfully")
        .setMimeType(ContentService.MimeType.TEXT);
    } else {
      // Add new match data
      addChecklistData(sheet, data);
      logInfo("Match " + matchKey + " data added!");
      return ContentService.createTextOutput("Match " + matchKey + " data added successfully")
        .setMimeType(ContentService.MimeType.TEXT);
    }
  } catch (error) {
    logError("Error in handleChecklistData: " + error.toString());
    return createErrorResponse("Server error: " + error.toString());
  }
}

/**
 * Updates existing match data in the checklist sheet
 * @param {Sheet} sheet - The spreadsheet sheet
 * @param {number} matchRow - The row number to update
 * @param {Object} data - The match data
 */
function updateChecklistData(sheet, matchRow, data) {
  try {
    const values = prepareChecklistRow(data);
    // Update all columns except matchKey (column 1) and timestamp (last column)
    // Now updating 60 columns (from column 2 to 61)
    sheet.getRange(matchRow, 2, 1, values.length).setValues([values]);
    
    // Update timestamp (column 62)
    sheet.getRange(matchRow, values.length + 2).setValue(new Date());
  } catch (error) {
    logError("Error in updateChecklistData: " + error.toString());
    throw error;
  }
}

/**
 * Adds new match data to the checklist sheet
 * @param {Sheet} sheet - The spreadsheet sheet
 * @param {Object} data - The match data
 * @return {number} The row number of the new data
 */
function addChecklistData(sheet, data) {
  try {
    const lastRow = sheet.getLastRow() + 1;
    const values = prepareChecklistRow(data);

    // Set main data columns (matchKey + data columns + timestamp)
    // Now we have 1 (matchKey) + 60 (data) + 1 (timestamp) = 62 columns
    sheet.getRange(lastRow, 1, 1, values.length + 2).setValues([
      [data.matchKey, ...values, new Date()]
    ]);

    return lastRow;
  } catch (error) {
    logError("Error in addChecklistData: " + error.toString());
    throw error;
  }
}


/**
 * Prepares a row of data for the checklist sheet
 * @param {Object} data - The match data
 * @return {Array} An array of values for the row
 */
function prepareChecklistRow(data) {
  return [
    data.chassisDriveMotors || false,
    data.chassisSteerMotors || false,
    data.chassisGearboxes || false,
    data.chassisTreadConditions || false,
    data.chassisWires || false,
    data.chassisBumpers || false,
    data.chassisLimelightProtectors || false,
    data.ethernetFrontLeftLimelight || false,
    data.ethernetFrontRightLimelight || false,
    data.ethernetBackLeftLimelight || false,
    data.ethernetBackRightLimelight || false,
    data.ethernetSwitch || false,
    data.ethernetRadio || false,
    data.climberString || false,
    data.climberClips || false,
    data.climberSprings || false,
    data.climberBumper || false,
    data.climberGearbox || false,
    data.climberMotors || false,
    data.climberWires || false,
    data.climberNutsAndBolts || false,
    data.climberReset || false,
    data.climberNumber || 0,
    data.elevatorRodOfDoom || false,
    data.elevatorStage0 || false,
    data.elevatorStage1 || false,
    data.elevatorStage2 || false,
    data.elevatorChain || false,
    data.elevatorGearbox || false,
    data.elevatorMotors || false,
    data.elevatorWires || false,
    data.elevatorNutsAndBolts || false,
    data.trapdoorPanels || false,
    data.trapdoorWires || false,
    data.trapdoorSupports || false,
    data.trapdoorHinges || false,
    data.trapdoorTensioners || false,
    data.trapdoorNutsAndBolts || false,
    data.trapdoorReset || false,
    data.carriageGearbox || false,
    data.carriageBeltbox || false,
    data.carriageMotors || false,
    data.carriageWires || false,
    data.carriageNutsAndBolts || false,
    data.carriageCoralSlide || false,
    data.carriageCarriage || false,
    data.gooseneckPanels || false,
    data.gooseneckWheels || false,
    data.gooseneckBelts || false,
    data.gooseneckNutsAndBolts || false,
    data.returningBatteryVoltage || 0.0,
    data.returningBatteryCCA || 0.0,
    data.returningNumber || 0,
    data.outgoingBatteryVoltage || 0.0,
    data.outgoingBatteryCCA || 0.0,
    data.outgoingNumber || 0,
    data.outgoingBatteryReplaced || false,
    data.allianceColor || "Blue",
    data.notes || ""
    // Removed allianceSelectionData
  ];
}

/**
 * Finds a match's row in the checklist sheet
 * @param {Sheet} sheet - The spreadsheet sheet
 * @param {string} matchKey - The match key to find
 * @return {number|null} The row number or null if not found
 */
function findMatchRow(sheet, matchKey) {
  try {
    const data = sheet.getDataRange().getValues();
    for (let i = 1; i < data.length; i++) {
      // Skip header
      if (data[i][0] == matchKey) {
        // Match Key is in the first column
        return i + 1; // Return the row number (1-based index)
      }
    }
    return null; // Return null if the match is not found
  } catch (error) {
    logError("Error in findMatchRow: " + error.toString());
    throw error;
  }
}

/**
 * Retrieves all checklist data from the sheet and returns as JSON
 * @return {TextOutput} JSON response with all match data
 */
function getChecklistData() {
  try {
    const sheet = getSheetOrDie(CHECKLIST_SHEET_NAME);
    const data = sheet.getDataRange().getValues();
    const headers = data[0]; // Save headers for reference

    const result = [];
    for (let i = 1; i < data.length; i++) {
      // Skip headers
      const row = data[i];

      // Create a match object with all properties
      const match = {};
      headers.forEach((header, index) => {
        match[header] = row[index];
      });

      result.push(match);
    }

    logInfo("Returned " + result.length + " matches data");
    return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(
      ContentService.MimeType.JSON
    );
  } catch (error) {
    logError("Error in getChecklistData: " + error.toString());
    return createErrorResponse("Error retrieving checklist data: " + error.toString());
  }
}

/**
 * Inserts demo data for the Robot Checklist
 * Can be run manually from the script editor for testing
 */
function insertDemoChecklistData() {
  const demoData = {
    matchKey: "MATCH_001",
    chassisDriveMotors: true,
    chassisSteerMotors: false,
    chassisGearboxes: true,
    chassisTreadConditions: true,
    chassisWires: true,
    chassisBumpers: true,
    chassisLimelightProtectors: false,
    ethernetFrontLeftLimelight: true,
    ethernetFrontRightLimelight: true,
    ethernetBackLeftLimelight: false,
    ethernetBackRightLimelight: false,
    ethernetSwitch: true,
    ethernetRadio: true,
    climberString: true,
    climberClips: true,
    climberSprings: false,
    climberBumper: true,
    climberGearbox: true,
    climberMotors: true,
    climberWires: true,
    climberNutsAndBolts: true,
    climberReset: false,
    climberNumber: 2,
    elevatorRodOfDoom: true,
    elevatorStage0: true,
    elevatorStage1: true,
    elevatorStage2: false,
    elevatorChain: true,
    elevatorGearbox: true,
    elevatorMotors: true,
    elevatorWires: true,
    elevatorNutsAndBolts: true,
    trapdoorPanels: true,
    trapdoorWires: true,
    trapdoorSupports: true,
    trapdoorHinges: true,
    trapdoorTensioners: true,
    trapdoorNutsAndBolts: true,
    trapdoorReset: false,
    carriageGearbox: true,
    carriageBeltbox: true,
    carriageMotors: true,
    carriageWires: true,
    carriageNutsAndBolts: true,
    carriageCoralSlide: true,
    carriageCarriage: true,
    gooseneckPanels: true,
    gooseneckWheels: true,
    gooseneckBelts: true,
    gooseneckNutsAndBolts: true,
    returningBatteryVoltage: 12.5,
    returningBatteryCCA: 500,
    returningNumber: 1,
    outgoingBatteryVoltage: 12.8,
    outgoingBatteryCCA: 520,
    outgoingNumber: 2,
    outgoingBatteryReplaced: false,
    allianceColor: "Blue",
    notes: "Robot performed well."
    // Removed allianceSelectionData
  };

  // Call the handleChecklistData function with the demo data
  const response = handleChecklistData(demoData);
  Logger.log("Demo data inserted for Robot Checklist: " + response.getContent());
}