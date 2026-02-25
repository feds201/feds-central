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
