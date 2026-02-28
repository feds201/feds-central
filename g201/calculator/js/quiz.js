import { modules } from './data.js';
import { calculateCategoryImpact } from './utils.js';

let currentQuestionIndex = 0;
let answers = [];
let currentEcoScore = 100;
let activeQuestions = [];
let activeModuleId = null;
let elements = {};
const moduleScores = {};
const moduleAnswers = {};

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
    const moduleNames = {
    '1': 'Shipping & Packaging',
    '2': 'Disposable Meal Items',
    '3': 'Build',
    '4': 'Transportation (FIRST)',
    '5': 'Transportation (Regional)'
};
const resultHeader = document.querySelector('.Eco-Friendly-text');
if (resultHeader) {
    resultHeader.textContent = `Module ${activeModuleId}: ${moduleNames[activeModuleId]} Complete!`;
}
   const finalScore = Math.round(currentEcoScore);

if (activeModuleId === 'secret') {
    if (elements.finalEcoScore) elements.finalEcoScore.textContent = '🤫';
    const scoreLabel = document.querySelector('.result-score');
    if (scoreLabel) scoreLabel.textContent = 'Team Vibe Score: IMMEASURABLE';
    if (elements.meterPointer) elements.meterPointer.style.left = '100%';
    if (elements.resultMessage) elements.resultMessage.textContent = "You have passed the vibe check. Clifford has been notified. Ritesh is proud. Lock in.";
} else {
    if (elements.finalEcoScore) elements.finalEcoScore.textContent = finalScore;
    moduleScores[activeModuleId] = finalScore;
    const moduleScoreEl = document.getElementById(`eco-score-module-${activeModuleId}`);
    if (moduleScoreEl) {
        moduleScoreEl.innerHTML = `<i class="fas fa-leaf"></i> Eco Score: ${finalScore}`;
    }
    if (elements.meterPointer) {
        elements.meterPointer.style.left = `${finalScore}%`;
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
}

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
        '5': 'Transportation (Regional)',
        'secret': '🤫 Funny Team Stuff'
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
    const moduleCategories = {
        '1': ['materials'],
        '2': ['materials'],
        '3': ['materials', 'energy'],
        '4': ['transport'],
        '5': ['transport'],
        'secret': []
    };
    const relevantCategories = moduleCategories[activeModuleId] || ['materials', 'transport', 'energy'];

    document.querySelectorAll('.impact-item').forEach(item => {
        item.style.display = relevantCategories.includes(item.dataset.category) ? 'flex' : 'none';
    });

    const matImpact = calculateCategoryImpact('materials', activeQuestions, answers);
    const transImpact = calculateCategoryImpact('transport', activeQuestions, answers);
    const enImpact = calculateCategoryImpact('energy', activeQuestions, answers);

    if (elements.materialsImpact) {
        elements.materialsImpact.textContent = matImpact > 0.7
            ? "Your team uses a large amount of disposable materials. Consider reducing waste and recycling more."
            : matImpact > 0.4
            ? "Your team used a moderate amount of disposable items. Consider reducing single-use plastics."
            : "Great job minimizing material usage! Your team shows strong awareness of waste reduction.";
    }
    if (elements.transportImpact) {
        elements.transportImpact.textContent = transImpact > 0.7
            ? "Your team's travel has a significant carbon footprint. Consider carpooling and trip optimization."
            : transImpact > 0.4
            ? "Your travel resulted in carbon emissions that could be reduced with more efficient planning."
            : "Your team is managing transportation efficiently with minimal environmental impact.";
    }
    if (elements.energyImpact) {
        elements.energyImpact.textContent = enImpact > 0.7
            ? "High battery and machine usage — look into energy management practices."
            : enImpact > 0.4
            ? "Battery and machine usage is within reasonable limits, but proper disposal and recycling are essential."
            : "Excellent energy management! Your team is minimizing battery waste and machine idle time.";
    }
}

function generateRecommendations() {
    const allRecommendations = {
        '1': [
            'Order parts in bulk to reduce packaging waste and shipping frequency',
            'Source parts locally where possible to cut transport emissions',
            'Reuse and flatten shipping boxes for recycling or cardboard prototyping',
        ],
        '2': [
            'Switch to reusable plates, utensils, and cloth napkins at competitions',
            'Set up a team water station with reusable bottles instead of buying packs',
            'Buy napkins and paper products made from recycled materials in bulk',
        ],
        '3': [
            'Use scrap aluminum and cardboard for prototyping before cutting new material',
            'Donate or sell leftover aluminum, lumber, and polycarbonate to other teams',
            'Recycle lead-acid batteries at auto stores — never landfill them',
            'Batch CNC/lathe operations to reduce total machine run hours',
            'Use PLA (compostable) filament for 3D printing where possible',
        ],
        '4': [
            'Carpool to competitions to reduce the number of vehicles on the road',
            'Choose ground transport over flying for regional competitions when possible',
            'Plan routes efficiently to minimize total miles traveled',
        ],
        '5': [
            'Carpool to regional competitions to reduce the number of vehicles on the road',
            'Combine trips and plan routes efficiently to minimize total miles traveled',
            'Consider closer regional competitions to reduce your travel footprint',
        ],
        'secret': [
    "Consider summoning fewer Cliffords. Or more. We honestly don't know.",
    "Ritesh music hours should be maximized at all times.",
    "Lock in. Always lock in.",
    "Popcorn consumption is not yet regulated by FIRST. Enjoy responsibly.",
],
    };

    const recs = allRecommendations[activeModuleId] || [];

    if (elements.customRecommendations) {
        elements.customRecommendations.innerHTML = recs.map(text => `
            <div class="recommendation-item">
                <i class="fas fa-check-circle"></i>
                <span>${text}</span>
            </div>
        `).join('');
    }

    // Hide the hardcoded static recommendation items since we're replacing them
    document.querySelectorAll('.eco-recommendations > .recommendation-item').forEach(el => {
        el.style.display = 'none';
    });
}

function generateSummary() {
    if (!elements.resultSummary) return;

    const moduleNames = {
        '1': 'Shipping & Packaging',
        '2': 'Disposable Meal Items',
        '3': 'Build',
        '4': 'Transportation (FIRST)',
        '5': 'Transportation (Regional)',
        'secret': '🤫 Funny Team Stuff'
    };

    let summaryHTML = '<h3>Your Detailed Responses:</h3>';

    for (const [moduleId, moduleAnswerList] of Object.entries(moduleAnswers)) {
        summaryHTML += `<h3>${moduleNames[moduleId] || 'Module ' + moduleId}</h3>`;
        let currentSection = '';
        moduleAnswerList.forEach((answer, index) => {
            if (currentSection !== answer.section) {
                currentSection = answer.section;
                summaryHTML += `<h4>${currentSection}</h4>`;
            }
            summaryHTML += `<p><strong>Q${index + 1}:</strong> ${answer.question}<br>
                          <strong>A:</strong> ${answer.answer}</p>`;
        });
    }

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

