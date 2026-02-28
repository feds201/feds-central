import { startModule, handleNext, handleBack, restartQuiz, setElements } from './quiz.js';
import { setTheme, setUnit } from './utils.js';

document.addEventListener('DOMContentLoaded', () => {
    // Cache DOM elements
    const elements = {
        questionElement: document.getElementById('question'),
        sectionHeading: document.getElementById('section-heading'),
        currentQuestion: document.getElementById('current-question'),
        currentQuestionDisplay: document.getElementById('current-question-display'),
        totalQuestions: document.getElementById('total-questions'),
        totalQuestionsDisplay: document.getElementById('total-questions-display'),
        answerInput: document.getElementById('answer-input'),
        errorMessage: document.getElementById('error-message'),
        nextButton: document.getElementById('next-btn'),
        backButton: document.getElementById('back-btn'),
        resultContainer: document.getElementById('result'),
        questionCard: document.querySelector('.question-card'),
        actionsContainer: document.querySelector('.actions'),
        progressBar: document.getElementById('progress-bar'),
        restartButton: document.getElementById('restart-btn'),
        resultSummary: document.getElementById('result-summary'),
        ecoTip: document.getElementById('eco-tip'),
        ecoScore: document.getElementById('eco-score'),
        finalEcoScore: document.getElementById('final-eco-score'),
        resultMessage: document.getElementById('result-message'),
        meterPointer: document.getElementById('meter-pointer'),
        materialsImpact: document.getElementById('materials-impact'),
        transportImpact: document.getElementById('transport-impact'),
        energyImpact: document.getElementById('energy-impact'),
        customRecommendations: document.getElementById('custom-recommendations'),
        themeToggle: document.getElementById('theme-toggle'),
        unitToggle: document.getElementById('unit-toggle'),
        modulesWrapper: document.querySelector('.modules-wrapper'),
        mcContainer: document.getElementById('mc-container'),
        questionText: document.getElementById('question')
    };

    // Pass elements to quiz module
    setElements(elements);

    // Event Listeners

    // Start buttons
   const startButtons = document.querySelectorAll('.start-btn');
startButtons.forEach(btn => {
    btn.addEventListener('click', () => {
        // Check for explicit data-module attribute first, then fall back to class
        let moduleNumber = btn.dataset.module;
        if (!moduleNumber) {
            const module = btn.closest('.module');
            moduleNumber = [...module.classList]
                .find(c => c.startsWith('module') && c !== 'module')
                ?.replace('module', '');
        }
        if (moduleNumber) {
            startModule(moduleNumber);
        }
    });
});

    // Navigation
    if (elements.nextButton) {
        elements.nextButton.addEventListener('click', handleNext);
    }

    if (elements.backButton) {
        elements.backButton.addEventListener('click', handleBack);
    }

    if (elements.restartButton) {
        elements.restartButton.addEventListener('click', restartQuiz);
    }

    // Input handling
    if (elements.answerInput) {
        elements.answerInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                handleNext();
            }
        });

        elements.answerInput.addEventListener('input', () => {
             if (elements.errorMessage) elements.errorMessage.textContent = '';
        });
    }

    // Theme Toggle
    const savedTheme = localStorage.getItem('theme') || 'light';
    setTheme(savedTheme);

    if (elements.themeToggle) {
        elements.themeToggle.addEventListener('click', () => {
            const currentTheme = document.documentElement.getAttribute('data-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            setTheme(newTheme);
            localStorage.setItem('theme', newTheme);
        });
    }

    // Unit Toggle
    const savedUnit = localStorage.getItem('unit') || 'lbs';
    setUnit(savedUnit);

    if (elements.unitToggle) {
        elements.unitToggle.addEventListener('click', () => {
            const currentUnit = document.documentElement.getAttribute('data-unit');
            const newUnit = currentUnit === 'kg' ? 'lbs' : 'kg';
            setUnit(newUnit);
            localStorage.setItem('unit', newUnit);
        });
    }
});
