document.addEventListener('DOMContentLoaded', function() {
    // Get DOM elements
    const questionElement = document.getElementById('question');
    const sectionHeadingElement = document.getElementById('section-heading');
    const currentQuestionElement = document.getElementById('current-question');
    const currentQuestionDisplayElement = document.getElementById('current-question-display');
    const totalQuestionsElement = document.getElementById('total-questions');
    const totalQuestionsDisplayElement = document.getElementById('total-questions-display');
    const answerInput = document.getElementById('answer-input');
    const errorMessage = document.getElementById('error-message');
    const nextButton = document.getElementById('next-btn');
    const backButton = document.getElementById('back-btn');
    const resultContainer = document.getElementById('result');
    const questionCard = document.querySelector('.question-card');
    const actionsContainer = document.querySelector('.actions');
    const progressBar = document.getElementById('progress-bar');
    const restartButton = document.getElementById('restart-btn');
    const resultSummary = document.getElementById('result-summary');
    const ecoTip = document.getElementById('eco-tip');
    const ecoScore = document.getElementById('eco-score');
    const finalEcoScore = document.getElementById('final-eco-score');
    const resultMessage = document.getElementById('result-message');
    const meterPointer = document.getElementById('meter-pointer');
    const materialsImpact = document.getElementById('materials-impact');
    const transportImpact = document.getElementById('transport-impact');
    const energyImpact = document.getElementById('energy-impact');
    const customRecommendations = document.getElementById('custom-recommendations');
    const themeToggle = document.getElementById('theme-toggle');
    const htmlElement = document.documentElement;
    const themeIcon = themeToggle.querySelector('i');
    const unitToggle = document.getElementById('unit-toggle');

    // Define questions
    const questions = [
        {
            section: "I. Shipping and Packaging of Products",
            question: "What was the total weight (in lbs) of the packages that you transported?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Every lbs of package weight contributes to carbon emissions during transport.",
            eco_impact: "high",
            category: "materials",
            videoLink: "https://www.youtube.com/watch?v=5qx2WFpNTPs" // Sustainable packaging video
        },
        {
            section: "II. Disposable Meal Items",
            question: "How many boxes of 50 paper plates did you use?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,           
            max: 1500,
            eco_tip: "Paper plates can be composted, but reusable dishes are more eco-friendly.",
            eco_impact: "medium",
            category: "materials",
            videoLink: "https://www.youtube.com/watch?v=NBnihk6Fq3U" // Eco-friendly dining materials
        },
        {
            section: "II. Disposable Meal Items",
            question: "How many boxes of 150 plastic forks did you use?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Plastic utensils are difficult to recycle. Consider bamboo or other biodegradable alternatives.",
            eco_impact: "high",
            category: "materials",
            videoLink: "https://www.youtube.com/watch?v=NMAeRTJA_xQ" // Alternative to plastic utensils
        },
        {
            section: "II. Disposable Meal Items",
            question: "How many packets of 75 napkins did you use?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Paper napkins have a high environmental cost. Consider cloth napkins for team events.",
            eco_impact: "medium",
            category: "materials",
            videoLink: "https://www.youtube.com/watch?v=KD_sDi_Omw4" // Sustainable napkin alternatives
        },
        {
            section: "II. Disposable Meal Items",
            question: "How many cartons of 50 water bottles did you use?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Single-use plastic bottles have a significant environmental impact. Reusable bottles are much better.",
            eco_impact: "high",
            category: "materials",
            videoLink: "https://www.youtube.com/watch?v=jTYkzGpP3WQ" // Reusable water bottle options
        },
        {
            section: "III. Robot Components",
            question: "How much old wires (in lbs) did you waste?",
            hint: "Enter a decimal value",
            type: "double",
            min: 0,
            max: 1500,
            eco_tip: "Electronic waste contains valuable materials that can be recycled properly.",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Robot Components",
            question: "How many cardboard boxes/pieces did you use for prototyping?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Cardboard is recyclable, but try to reuse it for multiple prototypes when possible.",
            eco_impact: "low",
            category: "materials"
        },
        {
            section: "III. Robot Components",
            question: "How many 20 by 20 aluminum bars and parts did you use in total?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Aluminum has a high environmental cost to produce, but is highly recyclable.",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Robot Components",
            question: "How much lumber (in lbs) did you use?",
            hint: "Enter a decimal value",
            type: "double",
            min: 0,
            max: 1500,
            eco_tip: "Sustainable lumber is a renewable resource but still has environmental impact.",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Robot Components",
            question: "How many batteries died in total?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Batteries contain harmful chemicals and should be properly recycled.",
            eco_impact: "high",
            category: "energy",
            videoLink: "https://www.youtube.com/watch?v=wEXG0o6A0bA" // Battery recycling video
        },
        {
            section: "IV. 3-D Printing Materials",
            question: "How much filament waste (in lbs) did you waste in total?",
            hint: "Enter a decimal value",
            type: "double",
            min: 0,
            max: 1500,
            eco_tip: "3D printing filament is often made from plastics that are difficult to recycle.",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "V. Transportation to/from comps",
            question: "What was your milage from your vehicle in total through trips?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Transportation is a major contributor to carbon emissions.",
            eco_impact: "high",
            category: "transport",
            videoLink: "https://www.youtube.com/watch?v=17xh_VRrnMU" // Eco-friendly transportation video
        },
        {
            section: "V. Transportation to/from comps",
            question: "How much fuel (in gallons) did you use in total while pulling a trailer or during a trip?",
            hint: "Enter a decimal value",
            type: "double",
            min: 0,
            max: 1500,
            eco_tip: "Every gallon of fuel burned produces CO2 emissions that contribute to climate change.",
            eco_impact: "high",
            category: "transport",
            videoLink: "https://www.youtube.com/watch?v=ZS_4Htwj0OQ" // Fuel efficiency video
        }
    ];

    let currentQuestionIndex = 0;
    let answers = [];
    let currentEcoScore = 0;
    
    // Initialize quiz
    function initQuiz() {
        currentQuestionIndex = 0;
        answers = [];
        currentEcoScore = 100; // Start with perfect score
        ecoScore.textContent = currentEcoScore;
        displayQuestion();
        totalQuestionsElement.textContent = questions.length;
        totalQuestionsDisplayElement.textContent = questions.length;
        resultContainer.classList.add('hidden');
        questionCard.classList.remove('hidden');
        actionsContainer.classList.remove('hidden');
        updateProgressBar();
        
        // Hide back button on first question
        backButton.classList.add('hidden');
    }
    
    // Display current question
    function displayQuestion() {
        const question = questions[currentQuestionIndex];
        sectionHeadingElement.textContent = question.section;
        questionElement.textContent = question.question;
        currentQuestionElement.textContent = currentQuestionIndex + 1;
        currentQuestionDisplayElement.textContent = currentQuestionIndex + 1;
        
        // Set input attributes based on question type
        answerInput.value = answers[currentQuestionIndex] ? answers[currentQuestionIndex].answer : '';
        answerInput.min = question.min;
        answerInput.max = question.max;
        answerInput.step = question.type === 'int' ? '1' : '0.01';
        answerInput.placeholder = `Enter value (${question.min}-${question.max})`;
        
        // Update hint
        document.querySelector('.input-hint').innerHTML = `<i class="fas fa-info-circle"></i> ${question.hint}`;
        
        // Update eco tip
        ecoTip.textContent = question.eco_tip;
        
        // Clear error message
        errorMessage.textContent = '';
        
        // Show/hide back button based on question index
        if (currentQuestionIndex === 0) {
            backButton.classList.add('hidden');
        } else {
            backButton.classList.remove('hidden');
        }
        
        // Focus on the input
        setTimeout(() => {
            answerInput.focus();
        }, 100);
        
        updateProgressBar();
    }
    
    // Update progress bar
    function updateProgressBar() {
        const progress = (currentQuestionIndex + 1) / questions.length * 100;
        progressBar.style.width = progress + '%';
    }
    
    // Validate the current answer
    function validateAnswer() {
        const question = questions[currentQuestionIndex];
        const value = answerInput.value.trim();
        
        if (value === '') {
            errorMessage.textContent = 'Please enter a value';
            return false;
        }
        
        const numValue = parseFloat(value);
        
        if (isNaN(numValue)) {
            errorMessage.textContent = 'Please enter a valid number';
            return false;
        }
        
        if (question.type === 'int' && !Number.isInteger(numValue)) {
            errorMessage.textContent = 'Please enter an integer value';
            return false;
        }
        
        if (numValue < question.min || numValue > question.max) {
            errorMessage.textContent = `Value must be between ${question.min} and ${question.max}`;
            return false;
        }
        
        return true;
    }
    
    // Calculate eco impact for an answer
    function calculateEcoImpact(question, value) {
        // Calculate what percentage of the max possible value this answer represents
        const range = question.max - question.min;
        const normalizedValue = range > 0 ? (value - question.min) / range : 0;
        
        // Base impact factors by impact level
        let impactFactor;
        switch (question.eco_impact) {
            case 'high': impactFactor = -20; break;
            case 'medium': impactFactor = -12; break;
            case 'low': impactFactor = -6; break;
            default: impactFactor = -10;
        }
        
        // Apply a curve to make higher values disproportionately more impactful
        const curvedImpact = Math.pow(normalizedValue, 1.5);
        
        // Calculate final impact
        return curvedImpact * impactFactor;
    }
    
    // Update eco score based on current answer
    function updateEcoScore() {
        const question = questions[currentQuestionIndex];
        const value = parseFloat(answerInput.value);
        
        const impact = calculateEcoImpact(question, value);
        currentEcoScore = Math.max(0, Math.min(100, currentEcoScore + impact ));
        ecoScore.textContent = Math.round(currentEcoScore);
    }
    
    // Handle next button click
    nextButton.addEventListener('click', function() {
        if (!validateAnswer()) return;
        
        // Update eco score BEFORE saving the answer
        updateEcoScore();
        
        // Save answer
        answers[currentQuestionIndex] = {
            question: questions[currentQuestionIndex].question,
            answer: answerInput.value,
            section: questions[currentQuestionIndex].section,
            category: questions[currentQuestionIndex].category
        };
        
        // Move to next question or finish quiz
        currentQuestionIndex++;
        
        if (currentQuestionIndex < questions.length) {
            displayQuestion();
        } else {
            finishQuiz();
        }
    });
    
    // Handle back button click
    backButton.addEventListener('click', function() {
        currentQuestionIndex--;
        displayQuestion();
    });
    
    // Handle input enter key
    answerInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            nextButton.click();
        }
    });
    
    // Clear error on input change
    answerInput.addEventListener('input', function() {
        errorMessage.textContent = '';
    });
    
    // Calculate overall impact for a category
    function calculateCategoryImpact(category) {
        let totalImpact = 0;
        let count = 0;
        
        questions.forEach((question, index) => {
            if (question.category === category && answers[index]) {
                const value = parseFloat(answers[index].answer);
                const normalized = (value - question.min) / (question.max - question.min);
                
                let weight;
                switch (question.eco_impact) {
                    case 'high': weight = 3; break;
                    case 'medium': weight = 2; break;
                    default: weight = 1;
                }
                
                totalImpact += normalized * weight;
                count += weight;
            }
        });
        
        return count > 0 ? totalImpact / count : 0;
    }
    
    // Generate recommendations based on answers
    function generateRecommendations() {
        // Get all available video links from questions organized by category
        const videoLinks = {
            materials: questions
                .filter(q => q.category === 'materials' && q.videoLink)
                .map(q => q.videoLink),
            transport: questions
                .filter(q => q.category === 'transport' && q.videoLink)
                .map(q => q.videoLink),
            energy: questions
                .filter(q => q.category === 'energy' && q.videoLink)
                .map(q => q.videoLink)
        };
        
        // Calculate impact levels for displaying appropriate messages
        const materialsImpact = calculateCategoryImpact('materials');
        const transportImpact = calculateCategoryImpact('transport');
        const energyImpact = calculateCategoryImpact('energy');
        
        // Define all recommendations with video links
        const allRecommendations = [
            {
                category: 'materials',
                text: 'Replace single-use plastic items with biodegradable alternatives',
                videoIndex: 0,
                impact: 'high'
            },
            {
                category: 'materials',
                text: 'Implement a materials recycling program for your workspace',
                videoIndex: 1,
                impact: 'medium'
            },
            {
                category: 'materials',
                text: 'Set up a recycling station for scrap materials from robot building',
                videoIndex: 2,
                impact: 'low'
            },
            {
                category: 'transport',
                text: 'Implement a carpooling system for team travel to competitions',
                videoIndex: 0,
                impact: 'high'
            },
            {
                category: 'transport',
                text: 'Plan trips more efficiently to reduce fuel consumption',
                videoIndex: 1,
                impact: 'medium'
            },
            {
                category: 'energy',
                text: 'Implement a battery recycling program',
                videoIndex: 0,
                impact: 'high'
            },
            {
                category: 'energy',
                text: 'Explore renewable energy options for powering practice sessions',
                videoIndex: 1,
                impact: 'medium'
            },
            {
                category: 'energy',
                text: 'Ensure all electronics are turned off when not in use',
                videoIndex: 0,
                impact: 'low'
            }
        ];
        
        // Build HTML for recommendations
        let recommendations = [];
        
        // Process recommendations according to their impact level
        allRecommendations.forEach(rec => {
            // Get appropriate video link if available
            const categoryVideos = videoLinks[rec.category] || [];
            const videoLink = categoryVideos.length > rec.videoIndex ? categoryVideos[rec.videoIndex] : 
                            (categoryVideos.length > 0 ? categoryVideos[0] : null);
            
            // Check if recommendation should be shown based on impact level
            let showRec = true;
            if (rec.category === 'materials' && rec.impact === 'high' && materialsImpact < 0.4) showRec = false;
            if (rec.category === 'transport' && rec.impact === 'high' && transportImpact < 0.4) showRec = false;
            if (rec.category === 'energy' && rec.impact === 'high' && energyImpact < 0.4) showRec = false;
            
            // Always show at least one recommendation per category
            if (showRec || recommendations.filter(r => r.includes(rec.category)).length === 0) {
                recommendations.push(`<div class='recommendation-item' data-category="${rec.category}">
                    <i class='fas fa-check-circle'></i>
                    <span>${rec.text}</span>
                    ${videoLink ? `<a href="${videoLink}" target="_blank" class="video-link">
                        <i class="fas fa-video"></i> Watch tutorial
                    </a>` : ''}
                </div>`);
            }
        });
        
        // Always ensure we have at least 4 recommendations
        if (recommendations.length < 4) {
            for (let i = 0; i < allRecommendations.length && recommendations.length < 4; i++) {
                const rec = allRecommendations[i];
                const alreadyAdded = recommendations.some(r => r.includes(rec.text));
                
                if (!alreadyAdded) {
                    const categoryVideos = videoLinks[rec.category] || [];
                    const videoLink = categoryVideos.length > 0 ? categoryVideos[0] : null;
                    
                    recommendations.push(`<div class='recommendation-item' data-category="${rec.category}">
                        <i class='fas fa-check-circle'></i>
                        <span>${rec.text}</span>
                        ${videoLink ? `<a href="${videoLink}" target="_blank" class="video-link">
                            <i class="fas fa-video"></i> Watch tutorial
                        </a>` : ''}
                    </div>`);
                }
            }
        }
        
        return recommendations;
    }
    
    // Finish quiz and show results
    function finishQuiz() {
        questionCard.classList.add('hidden');
        actionsContainer.classList.add('hidden');
        resultContainer.classList.remove('hidden');
        
        // Round eco score for display
        const finalScore = Math.round(currentEcoScore);
        finalEcoScore.textContent = finalScore;
        
        // Set meter pointer position
        const pointerPosition = (finalScore / 100) * 100;
        meterPointer.style.left = `${pointerPosition}%`;
        
        // Set result message based on score
        if (finalScore >= 80) {
            resultMessage.textContent = "Excellent! Your team is very eco-conscious. Keep up the great work!";
        } else if (finalScore >= 60) {
            resultMessage.textContent = "Your team is making good progress toward sustainability, but there's room for improvement.";
        } else if (finalScore >= 40) {
            resultMessage.textContent = "Your team needs to make more efforts to reduce environmental impact.";
        } else {
            resultMessage.textContent = "Your team has a significant environmental footprint. Urgent action is recommended.";
        }
        
        // Set category impact messages
        const matImpact = calculateCategoryImpact('materials');
        const transImpact = calculateCategoryImpact('transport');
        const enImpact = calculateCategoryImpact('energy');
        
        // Materials impact text
        if (matImpact > 0.7) {
            materialsImpact.textContent = "Your team uses a large amount of disposable materials. Consider reducing waste and recycling more.";
        } else if (matImpact > 0.4) {
            materialsImpact.textContent = "Your team used a moderate amount of disposable items. Consider reducing single-use plastics.";
        } else {
            materialsImpact.textContent = "Great job minimizing material usage! Your team shows strong awareness of waste reduction.";
        }
        
        // Transport impact text
        if (transImpact > 0.7) {
            transportImpact.textContent = "Your team's travel has a significant carbon footprint. Consider carpooling and trip optimization.";
        } else if (transImpact > 0.4) {
            transportImpact.textContent = "Your travel resulted in carbon emissions that could be reduced with more efficient planning.";
        } else {
            transportImpact.textContent = "Your team is managing transportation efficiently with minimal environmental impact.";
        }
        
        // Energy impact text
        if (enImpact > 0.7) {
            energyImpact.textContent = "High battery usage indicates potential for improvement in energy management.";
        } else if (enImpact > 0.4) {
            energyImpact.textContent = "Battery usage is within reasonable limits, but proper disposal and recycling are essential.";
        } else {
            energyImpact.textContent = "Excellent energy management! Your team is minimizing battery waste.";
        }
        
        // Generate custom recommendations with improved styling
        const customRecs = generateRecommendations();
        if (customRecs.length > 0) {
            customRecommendations.innerHTML = customRecs.join('');
            
            // Add heading before custom recommendations
            const recommendationHeading = document.createElement('h4');
            recommendationHeading.textContent = "Suggested Action Steps:";
            recommendationHeading.style.marginBottom = '15px';
            recommendationHeading.style.color = getComputedStyle(document.documentElement).getPropertyValue('--eco-friendly-color');
            customRecommendations.prepend(recommendationHeading);
            
        }
        
        // Generate result summary HTML
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
        
        resultSummary.innerHTML = summaryHTML;
    }
    
    // Restart quiz
    restartButton.addEventListener('click', function() {
        initQuiz();
    });
    
    // Initialize the quiz
    initQuiz();

    // Dark mode toggle functionality
    const savedTheme = localStorage.getItem('theme') || 'light';
    setTheme(savedTheme);
    
    // Toggle theme when button is clicked
    themeToggle.addEventListener('click', () => {
        const currentTheme = htmlElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        setTheme(newTheme);
        localStorage.setItem('theme', newTheme);
    });

    // Function to set the theme and update the icon
    function setTheme(theme) {
        htmlElement.setAttribute('data-theme', theme);
        
        if (theme === 'dark') {
            themeIcon.classList.remove('fa-moon');
            themeIcon.classList.add('fa-sun');
            themeToggle.setAttribute('aria-label', 'Toggle light mode');
        } else {
            themeIcon.classList.remove('fa-sun');
            themeIcon.classList.add('fa-moon');
            themeToggle.setAttribute('aria-label', 'Toggle dark mode');
        }
    }

    // Lbs to Kg converter
    const savedUnit = localStorage.getItem('unit') || 'lbs';
    setUnit(savedUnit);
        
    
// Toggle unit when button is clicked
unitToggle.addEventListener('click', () => {
    const currentUnit = htmlElement.getAttribute('data-unit');
    console.log(currentUnit); // Ensure this logs the correct value
    const newUnit = currentUnit === 'kg' ? 'lbs' : 'kg';
    setUnit(newUnit);
    localStorage.setItem('unit', newUnit);

    if (text.textContent.includes("lbs")) {
        text.textContent = text.textContent.replace("lbs", "kg");
    } else if (text.textContent.includes("kg")) {
        text.textContent = text.textContent.replace("kg", "lbs");
    }
});

// Function to set the unit and update the icon
function setUnit(unit) {
    htmlElement.setAttribute('data-unit', unit);

    if (unit === 'kg') {
        unitIcon.classList.remove('fa-scale-unbalanced');
        unitIcon.classList.add('fa-scale-unbalanced-flip'); // Fixed typo
        themeToggle.setAttribute('aria-label', 'Convert to lbs'); // Fixed spacing in 'aria-label'
    } else {
        unitIcon.classList.remove('fa-scale-unbalanced-flip');
        unitIcon.classList.add('fa-scale-unbalanced'); // Fixed typo
        themeToggle.setAttribute('aria-label', 'Convert to kg'); // Fixed spacing in 'aria-label'
    }
}

    // Enhanced function to show only results page with beautiful animations
    function previewResultsPage() {
        // Hide question-related elements with fade
        questionCard.classList.add('fade-out');
        actionsContainer.classList.add('fade-out');
        
        setTimeout(() => {
            questionCard.classList.add('hidden');
            actionsContainer.classList.add('hidden');
            
            // Show results container with fade-in
            resultContainer.classList.remove('hidden');
            resultContainer.classList.add('fade-in');
        }, 500);
        
        // Sample eco score
        const sampleScore = 65;
        finalEcoScore.textContent = sampleScore;
        
        // Set meter pointer position
        const pointerPosition = (sampleScore / 100) * 100;
        meterPointer.style.left = `${pointerPosition}%`;
        
        // Set sample result message
        resultMessage.textContent = "Your team is making good progress toward sustainability, but there's room for improvement.";
        
        // Sample impact messages
        materialsImpact.textContent = "Your team used a moderate amount of disposable items. Consider reducing single-use plastics.";
        transportImpact.textContent = "Your travel resulted in carbon emissions that could be reduced with more efficient planning.";
        energyImpact.textContent = "Battery usage is within reasonable limits, but proper disposal and recycling are essential.";
        
        // Generate sample recommendations
        const sampleRecommendations = [
            `<div class='recommendation-item' data-category="materials">
                <i class='fas fa-check-circle'></i>
                <span>Replace single-use plastic items with biodegradable alternatives</span>
                <a href="https://www.youtube.com/watch?v=NBnihk6Fq3U" target="_blank" class="video-link">
                    <i class="fas fa-video"></i> Watch tutorial
                </a>
            </div>`,
            `<div class='recommendation-item' data-category="transport">
                <i class='fas fa-check-circle'></i>
                <span>Plan trips more efficiently to reduce fuel consumption</span>
                <a href="https://www.youtube.com/watch?v=17xh_VRrnMU" target="_blank" class="video-link">
                    <i class="fas fa-video"></i> Watch tutorial
                </a>
            </div>`,
            `<div class='recommendation-item' data-category="energy">
                <i class='fas fa-check-circle'></i>
                <span>Implement a battery recycling program</span>
                <a href="https://www.youtube.com/watch?v=wEXG0o6A0bA" target="_blank" class="video-link">
                    <i class="fas fa-video"></i> Watch tutorial
                </a>
            </div>`,
            `<div class='recommendation-item' data-category="materials">
                <i class='fas fa-check-circle'></i>
                <span>Set up a recycling station for scrap materials from robot building</span>
                <a href="https://www.youtube.com/watch?v=5qx2WFpNTPs" target="_blank" class="video-link">
                    <i class="fas fa-video"></i> Watch tutorial
                </a>
            </div>`
        ];
        
        // Display sample recommendations
        customRecommendations.innerHTML = sampleRecommendations.join('');
        
        // Add heading before custom recommendations
        const recommendationHeading = document.createElement('h4');
        recommendationHeading.textContent = "Suggested Action Steps:";
        recommendationHeading.style.marginBottom = '15px';
        recommendationHeading.style.color = getComputedStyle(document.documentElement).getPropertyValue('--eco-friendly-color');
        customRecommendations.prepend(recommendationHeading);
        
        // Generate sample result summary HTML
        let summaryHTML = '<h3>Your Detailed Responses:</h3>';
        
        // Sample sections with questions and answers
        const sampleSections = {
            "I. Shipping and Packaging of Products": [
                { q: "What was the total weight (in lbs) of the packages that you transported?", a: "1200" }
            ],
            "II. Disposable Meal Items": [
                { q: "How many boxes of 50 paper plates did you use?", a: "45" },
                { q: "How many boxes of 150 plastic forks did you use?", a: "30" },
                { q: "How many packets of 75 napkins did you use?", a: "60" }
            ],
            "III. Robot Components": [
                { q: "How much old wires (in lbs) did you waste?", a: "12.5" },
                { q: "How many batteries died in total?", a: "8" }
            ]
        };
        
        // Build sample summary HTML
        let qIndex = 1;
        for (const section in sampleSections) {
            summaryHTML += `<h4>${section}</h4>`;
            
            sampleSections[section].forEach(item => {
                summaryHTML += `<p><strong>Q${qIndex}:</strong> ${item.q}<br>
                              <strong>A:</strong> ${item.a}</p>`;
                qIndex++;
            });
        }
        
        resultSummary.innerHTML = summaryHTML;
    }
    
    // CALL THIS FUNCTION TO SHOW ONLY RESULTS PAGE
    // Comment out when you want normal quiz functionality

    // previewResultsPage();
    
    // If preview mode is active, register restart button to reload page instead
    restartButton.addEventListener('click', function() {
        // Check if we're in preview mode (by checking if questions are hidden)
        if (questionCard.classList.contains('hidden')) {
            location.reload();
        } else {
            initQuiz();
        }
    });
});
