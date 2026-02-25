<<<<<<< HEAD
# FRC Eco-Friendly Calculator (G201)

## Overview
The FRC Eco-Friendly Calculator is a web-based tool designed to help FIRST Robotics Competition (FRC) teams measure and understand their environmental impact. By answering a series of questions across different modules (Shipping, Materials, Energy, Transportation), teams receive an "Eco Score" and personalized recommendations for improvement.

## Features
- **Modular Assessment**: Divided into 4 modules covering key areas of team operations.
- **Eco Score**: A real-time score that reflects the environmental impact of your choices (0-100).
- **Personalized Recommendations**: Actionable steps based on your specific answers.
- **Visual Feedback**: Impact meters and progress tracking.

## Structure
The project is built with vanilla HTML, CSS, and JavaScript.

- `index.html`: The main entry point and UI structure.
- `css/style.css`: Styling and themes.
- `js/`:
  - `main.js`: Main entry point, event listeners, and DOM initialization.
  - `quiz.js`: Core quiz logic (state management, scoring, navigation).
  - `data.js`: Question data, categories, and options.
  - `utils.js`: Utility functions for calculations and theme toggling.

## How to Use
1. Open `index.html` in a web browser.
2. Select a module to start.
3. Answer the questions honestly.
4. Review your results and recommendations.
5. Implement changes and re-take the assessment to see your improvement!

## Contributing
Feel free to add more questions or improve the scoring algorithm in `js/data.js` and `js/utils.js`.
=======
# G201 - FRC Eco-Friendly Calculator

## Overview

The G201 Eco-Friendly Calculator is a web-based tool designed to help FRC teams measure their environmental impact. By answering a series of questions across different modules (Shipping, Disposables, Robot Components, Transportation), teams receive an "Eco Score" and personalized recommendations for improvement.

## Features

-   **Modular Assessment**: Questions are divided into logical modules.
-   **Eco Score**: A real-time score calculation based on user inputs.
-   **Personalized Recommendations**: Actionable steps to improve sustainability based on specific answers.
-   **Dark Mode**: Theme toggle for comfortable viewing.
-   **Unit Conversion**: Toggle between Imperial (lbs) and Metric (kg) units.

## Structure

The project is located in `g201/calculator/` and consists of:

-   `index.html`: The main entry point.
-   `css/style.css`: Stylesheet.
-   `js/`: JavaScript source files (ES Modules).
    -   `main.js`: Application entry point.
    -   `quiz.js`: Core quiz logic.
    -   `data.js`: Question data.
    -   `utils.js`: Utility functions.

## How to Run

1.  Clone the repository.
2.  Navigate to the `g201/calculator` directory.
3.  Serve the files using a local web server (required for ES Modules to work).
    *   For example, using Python:
        ```bash
        python3 -m http.server
        ```
    *   Or using `http-server` via npm:
        ```bash
        npx http-server
        ```
4.  Open the provided local URL (e.g., `http://localhost:8000`) in your web browser.

## Contributing

-   Modify `js/data.js` to update questions or scoring parameters.
-   Edit `js/quiz.js` to change the assessment logic.
>>>>>>> origin/main
