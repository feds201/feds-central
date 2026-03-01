// utils.js

export function setTheme(theme) {
    const htmlElement = document.documentElement;
    const themeToggle = document.getElementById('theme-toggle');
    if (!themeToggle) return;
    const themeIcon = themeToggle.querySelector('i');

    htmlElement.setAttribute('data-theme', theme);

    if (themeIcon) {
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
}

export function setUnit(unit) {
    const htmlElement = document.documentElement;
    const unitToggle = document.getElementById('unit-toggle');
    if (!unitToggle) return;
    const unitIcon = unitToggle.querySelector('i');

    htmlElement.setAttribute('data-unit', unit);

    if (unitIcon) {
        if (unit === 'kg') {
            unitIcon.classList.remove('fa-scale-unbalanced');
            unitIcon.classList.add('fa-scale-unbalanced-flip');
            unitToggle.setAttribute('aria-label', 'Convert to lbs');
        } else {
            unitIcon.classList.remove('fa-scale-unbalanced-flip');
            unitIcon.classList.add('fa-scale-unbalanced');
            unitToggle.setAttribute('aria-label', 'Convert to kg');
        }
    }
}

export function calculateEcoImpact(question, value) {
    // Calculate what percentage of the max possible value this answer represents
    let normalizedValue;
    if (question.type === 'multiple-choice') {
        // Assuming values are 1, 2, 3
         normalizedValue = (value - 1) / (3 - 1);
    } else {
        const range = question.max - question.min;
        normalizedValue = range > 0 ? (value - question.min) / range : 0;
    }

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

export function calculateCategoryImpact(category, questions, answers) {
    let totalImpact = 0;
    let count = 0;

    questions.forEach((question, index) => {
        if (question.category === category && answers[index]) {
            const value = parseFloat(answers[index].answer);

            let normalized;
            if (question.type === 'multiple-choice') {
                normalized = (value - 1) / (3 - 1);
            } else {
                const range = question.max - question.min;
                normalized = range > 0 ? (value - question.min) / range : 0;
            }

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
