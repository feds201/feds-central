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

Simply open `g201/calculator/index.html` in a modern web browser. No build step is required.

## Contributing

-   Modify `js/data.js` to update questions or scoring parameters.
-   Edit `js/quiz.js` to change the assessment logic.
