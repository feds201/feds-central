import { modules } from './data.js';
import { calculateCategoryImpact } from './utils.js';

let currentQuestionIndex = 0;
let answers = [];
let currentEcoScore = 100;
let activeQuestions = [];
let activeModuleId = null;
let elements = {};
const moduleScores = {};

export function setElements(domElements) {
    elements = domElements;
}

export function startModule(moduleId) {
    activeModuleId = moduleId;
    activeQuestions = modules[moduleId];

    if (!activeQuestions) {
        console.error("Module not found:", moduleId);
        return;
    }

    currentQuestionIndex = 0;
    answers = [];
    currentEcoScore = 100;

    if (elements.ecoScore) elements.ecoScore.textContent = currentEcoScore;
    if (elements.totalQuestions) elements.totalQuestions.textContent = activeQuestions.length;
    if (elements.totalQuestionsDisplay) elements.totalQuestionsDisplay.textContent = activeQuestions.length;

    elements.resultContainer.classList.add('hidden');
    elements.questionCard.classList.remove('hidden');
    elements.actionsContainer.classList.remove('hidden');
    elements.modulesWrapper.classList.add('hidden');
    elements.backButton.classList.add('hidden');

    displayQuestion();
    updateProgressBar();
}

export function displayQuestion() {
    const question = activeQuestions[currentQuestionIndex];
    if (!question) return;

    if (question.type === 'multiple-choice') {
        elements.answerInput.classList.add('hidden');
        elements.mcContainer.classList.remove('hidden');
        elements.mcContainer.innerHTML = question.options.map((opt, i) => `
            <label class="mc-option">
                <input type="radio" name="mc-answer" value="${i}">
                ${opt.label}
            </label>
        `).join('');

        // Restore answer if exists
        if (answers[currentQuestionIndex]) {
             const savedVal = answers[currentQuestionIndex].answer;
             
             // Find index by value
             const idx = question.options.findIndex(o => o.value == savedVal);
             if (idx !== -1) {
                 const radio = elements.mcContainer.querySelector(`input[value="${idx}"]`);
                 if (radio) radio.checked = true;
             }
        }
    } else {
        elements.answerInput.classList.remove('hidden');
        elements.mcContainer.classList.add('hidden');

        elements.answerInput.value = answers[currentQuestionIndex] ? answers[currentQuestionIndex].answer : '';
        elements.answerInput.min = question.min;
        elements.answerInput.max = question.max;
        elements.answerInput.step = question.type === 'int' ? '1' : '0.01';
        elements.answerInput.placeholder = `Enter value (${question.min}-${question.max})`;

        setTimeout(() => {
            elements.answerInput.focus();
        }, 100);
    }

    if (elements.sectionHeading) elements.sectionHeading.textContent = question.section;
    if (elements.questionText) elements.questionText.textContent = question.question;
    if (elements.currentQuestion) elements.currentQuestion.textContent = currentQuestionIndex + 1;
    if (elements.currentQuestionDisplay) elements.currentQuestionDisplay.textContent = currentQuestionIndex + 1;

    const hintContainer = document.querySelector('.input-hint');
    if (hintContainer) hintContainer.innerHTML = `<i class="fas fa-info-circle"></i> ${question.hint}`;

    if (elements.ecoTip) elements.ecoTip.textContent = question.eco_tip;
    if (elements.errorMessage) elements.errorMessage.textContent = '';

    if (currentQuestionIndex === 0) {
        elements.backButton.classList.add('hidden');
    } else {
        elements.backButton.classList.remove('hidden');
    }

    updateProgressBar();
}

function updateProgressBar() {
    if (!elements.progressBar) return;
    const progress = (currentQuestionIndex + 1) / activeQuestions.length * 100;
    elements.progressBar.style.width = progress + '%';
}

export function validateAnswer() {
    const question = activeQuestions[currentQuestionIndex];
    let value;

    if (question.type === 'multiple-choice') {
        const selected = elements.mcContainer.querySelector('input[name="mc-answer"]:checked');
        if (!selected) {
            elements.errorMessage.textContent = 'Please select an option';
            return false;
        }
        return true;
    } else {
        value = elements.answerInput.value.trim();
        if (value === '') {
            elements.errorMessage.textContent = 'Please enter a value';
            return false;
        }

        const numValue = parseFloat(value);
        if (isNaN(numValue)) {
            elements.errorMessage.textContent = 'Please enter a valid number';
            return false;
        }

        if (question.type === 'int' && !Number.isInteger(numValue)) {
            elements.errorMessage.textContent = 'Please enter an integer value';
            return false;
        }

        if (numValue < question.min || numValue > question.max) {
            elements.errorMessage.textContent = `Value must be between ${question.min} and ${question.max}`;
            return false;
        }
        return true;
    }
}

export function handleNext() {
    if (!validateAnswer()) return;

    const question = activeQuestions[currentQuestionIndex];
    let savedAnswer;
    let valueForScore;

    if (question.type === 'multiple-choice') {
        const selected = elements.mcContainer.querySelector('input[name="mc-answer"]:checked');
        const selectedIndex = selected.value;
        savedAnswer = question.options[selectedIndex].value;
        valueForScore = savedAnswer;
    } else {
        savedAnswer = elements.answerInput.value;
        valueForScore = parseFloat(savedAnswer);
    }

    answers[currentQuestionIndex] = {
        question: question.question,
        answer: savedAnswer,
        section: question.section,
        category: question.category,
        scoreBefore: currentEcoScore  // snapshot score before this question's impact
    };

    updateEcoScore(question, valueForScore);

    currentQuestionIndex++;

    if (currentQuestionIndex < activeQuestions.length) {
        displayQuestion();
    } else {
        finishQuiz();
    }
}

export function handleBack() {
    if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
        // Restore the score to what it was before this question was answered
        if (answers[currentQuestionIndex]) {
            currentEcoScore = answers[currentQuestionIndex].scoreBefore;
            if (elements.ecoScore) elements.ecoScore.textContent = Math.round(currentEcoScore);
        }
        displayQuestion();
    }
}
function updateOverallScore() {
    const coreModules = ['1', '2', '3'];
    const completedCore = coreModules.filter(m => moduleScores[m] !== undefined);
    if (completedCore.length === 0) return;

    const transportScore = moduleScores['4'] ?? moduleScores['5'];
    const allScores = completedCore.map(m => moduleScores[m]);
    if (transportScore !== undefined) allScores.push(transportScore);

    const lowest = Math.min(...allScores);

    const overallEl = document.getElementById('overall-eco-score');
    if (overallEl) overallEl.textContent = lowest;

    const overallCard = document.getElementById('overall-score-card');
    if (overallCard) overallCard.classList.remove('hidden');
}



function updateEcoScore(question, value) {
    let impactFactor;
switch (question.eco_impact?.toLowerCase()) {
        case 'high': impactFactor = -20; break;
        case 'medium': impactFactor = -12; break;
        case 'low': impactFactor = -6; break;
        default: impactFactor = -10;
    }

    let normalizedValue;
    if (question.type === 'multiple-choice') {
        normalizedValue = (value - 1) / (3 - 1);
    } else {
        const range = question.max - question.min;
        normalizedValue = range > 0 ? (value - question.min) / range : 0;
    }

    const curvedImpact = Math.pow(normalizedValue, 1.5);
    const impact = curvedImpact * impactFactor;

    currentEcoScore = Math.max(0, Math.min(100, currentEcoScore + impact));
    if (elements.ecoScore) elements.ecoScore.textContent = Math.round(currentEcoScore);
}

function finishQuiz() {
    elements.questionCard.classList.add('hidden');
    elements.actionsContainer.classList.add('hidden');
    elements.resultContainer.classList.remove('hidden');

    const finalScore = Math.round(currentEcoScore);
   

    if (elements.finalEcoScore) elements.finalEcoScore.textContent = finalScore;
moduleScores[activeModuleId] = finalScore;
updateOverallScore();
const moduleScoreEl = document.getElementById(`eco-score-module-${activeModuleId}`);
if (moduleScoreEl) {
    moduleScoreEl.innerHTML = `<i class="fas fa-leaf"></i> Eco Score: ${finalScore}`;
}

const moduleScoreDiv = moduleScoreEl?.closest(`[class*="eco-score-module-${activeModuleId}"]`);
if (moduleScoreDiv) {
    moduleScoreDiv.classList.add('completed');
}
    if (elements.meterPointer) {
        const pointerPosition = (finalScore / 100) * 100;
        elements.meterPointer.style.left = `${pointerPosition}%`;
    }

    if (elements.resultMessage) {
        if (finalScore >= 80) {
            elements.resultMessage.textContent = "Excellent! Your team is very eco-conscious. Keep up the great work!";
        } else if (finalScore >= 60) {
            elements.resultMessage.textContent = "Your team is making good progress toward sustainability, but there's room for improvement.";
        } else if (finalScore >= 40) {
            elements.resultMessage.textContent = "Your team needs to make more efforts to reduce environmental impact.";
        } else {
            elements.resultMessage.textContent = "Your team has a significant environmental footprint. Urgent action is recommended.";
        }
    }
const overallScore = calculateOverallScore();
const overallEl = document.getElementById('overall-eco-score');
if (overallEl && overallScore !== null) {
    overallEl.textContent = overallScore;
}
const overallCard = document.getElementById('overall-score-card');
if (overallCard) overallCard.classList.remove('hidden');
    updateImpactTexts();
    generateRecommendations();
    generateSummary();


    const overallSummaryEl = document.getElementById('overall-score-summary');
if (overallSummaryEl) {
    const moduleNames = {
        '1': 'Shipping & Packaging',
        '2': 'Disposable Meal Items',
        '3': 'Mechanical/Programming/Fabrics',
        '4': 'Transportation (First)',
        '5': 'Transportation (Regional)'
    };
    let html = '';
    for (const [id, score] of Object.entries(moduleScores)) {
        html += `<div class="module-score-row">
            <span>${moduleNames[id] || 'Module ' + id}</span>
            <span>${score}/100</span>
        </div>`;
    }
    overallSummaryEl.innerHTML = html;
}
}

function updateImpactTexts() {
    const matImpact = calculateCategoryImpact('materials', activeQuestions, answers);
    const transImpact = calculateCategoryImpact('transport', activeQuestions, answers);
    const enImpact = calculateCategoryImpact('energy', activeQuestions, answers);

    if (elements.materialsImpact) {
        if (matImpact > 0.7) {
            elements.materialsImpact.textContent = "Your team uses a large amount of disposable materials. Consider reducing waste and recycling more.";
        } else if (matImpact > 0.4) {
            elements.materialsImpact.textContent = "Your team used a moderate amount of disposable items. Consider reducing single-use plastics.";
        } else {
            elements.materialsImpact.textContent = "Great job minimizing material usage! Your team shows strong awareness of waste reduction.";
        }
    }

    if (elements.transportImpact) {
        if (transImpact > 0.7) {
            elements.transportImpact.textContent = "Your team's travel has a significant carbon footprint. Consider carpooling and trip optimization.";
        } else if (transImpact > 0.4) {
            elements.transportImpact.textContent = "Your travel resulted in carbon emissions that could be reduced with more efficient planning.";
        } else {
            elements.transportImpact.textContent = "Your team is managing transportation efficiently with minimal environmental impact.";
        }
    }

    if (elements.energyImpact) {
        if (enImpact > 0.7) {
            elements.energyImpact.textContent = "High battery usage indicates potential for improvement in energy management.";
        } else if (enImpact > 0.4) {
            elements.energyImpact.textContent = "Battery usage is within reasonable limits, but proper disposal and recycling are essential.";
        } else {
            elements.energyImpact.textContent = "Excellent energy management! Your team is minimizing battery waste.";
        }
    }
}

function generateRecommendations() {
    const materialsImpact = calculateCategoryImpact('materials', activeQuestions, answers);
    const transportImpact = calculateCategoryImpact('transport', activeQuestions, answers);
    const energyImpact = calculateCategoryImpact('energy', activeQuestions, answers);

    const allRecommendations = [
        { category: 'materials', text: 'Replace single-use plastic items with biodegradable alternatives', impact: 'high' },
        { category: 'materials', text: 'Implement a materials recycling program for your workspace', impact: 'medium' },
        { category: 'materials', text: 'Set up a recycling station for scrap materials from robot building', impact: 'low' },
        { category: 'transport', text: 'Implement a carpooling system for team travel to competitions', impact: 'high' },
        { category: 'transport', text: 'Plan trips more efficiently to reduce fuel consumption', impact: 'medium' },
        { category: 'energy', text: 'Implement a battery recycling program', impact: 'high' },
        { category: 'energy', text: 'Explore renewable energy options for powering practice sessions', impact: 'medium' },
        { category: 'energy', text: 'Ensure all electronics are turned off when not in use', impact: 'low' }
    ];

    let recommendations = [];

    allRecommendations.forEach(rec => {
        let showRec = true;
        if (rec.category === 'materials' && rec.impact === 'high' && materialsImpact < 0.4) showRec = false;
        if (rec.category === 'transport' && rec.impact === 'high' && transportImpact < 0.4) showRec = false;
        if (rec.category === 'energy' && rec.impact === 'high' && energyImpact < 0.4) showRec = false;

        if (showRec || recommendations.filter(r => r.includes(rec.category)).length === 0) {
            recommendations.push(`<div class='recommendation-item' data-category="${rec.category}">
                <i class='fas fa-check-circle'></i>
                <span>${rec.text}</span>
            </div>`);
        }
    });

    if (recommendations.length < 4) {
        for (let i = 0; i < allRecommendations.length && recommendations.length < 4; i++) {
             const rec = allRecommendations[i];
             const alreadyAdded = recommendations.some(r => r.includes(rec.text));
             if (!alreadyAdded) {
                  recommendations.push(`<div class='recommendation-item' data-category="${rec.category}">
                    <i class='fas fa-check-circle'></i>
                    <span>${rec.text}</span>
                </div>`);
             }
        }
    }

    if (elements.customRecommendations) {
        elements.customRecommendations.innerHTML = recommendations.join('');
        const recommendationHeading = document.createElement('h4');
        recommendationHeading.textContent = "Suggested Action Steps:";
        recommendationHeading.style.marginBottom = '15px';
        recommendationHeading.style.color = getComputedStyle(document.documentElement).getPropertyValue('--eco-friendly-color');
        elements.customRecommendations.prepend(recommendationHeading);
    }
}

function generateSummary() {
    if (!elements.resultSummary) return;

    let summaryHTML = '<h3>Your Detailed Responses:</h3>';
    let currentSection = '';

    answers.forEach((answer, index) => {
        if (currentSection !== answer.section) {
            currentSection = answer.section;
            summaryHTML += `<h4>${currentSection}</h4>`;
        }

        summaryHTML += `<p><strong>Q${index + 1}:</strong> ${answer.question}<br>
                      <strong>A:</strong> ${answer.answer}</p>`;
    });

    elements.resultSummary.innerHTML = summaryHTML;
}

export function restartQuiz() {
    elements.resultContainer.classList.add('hidden');
    elements.questionCard.classList.add('hidden');
    elements.actionsContainer.classList.add('hidden');
    elements.modulesWrapper.classList.remove('hidden');

    currentQuestionIndex = 0;
    answers = [];
    currentEcoScore = 0;
    activeModuleId = null;
    activeQuestions = [];

    if (elements.ecoScore) elements.ecoScore.textContent = '0';
    if (elements.currentQuestion) elements.currentQuestion.textContent = '1';
    if (elements.progressBar) elements.progressBar.style.width = '0%';
}

