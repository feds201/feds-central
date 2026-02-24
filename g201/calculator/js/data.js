export const modules = {
    '1': [
        {
            section: "I. Shipping and Packaging of Products",
            question: "What was the total weight (in lbs) of the packages that you transported?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 1500,
            eco_tip: "Every lbs of package weight contributes to carbon emissions.",
            eco_impact: "high",
            category: "materials"
        },
        {
            section: "I. Shipping and Packaging of Products",
            question: "How many parts did you have to order again in a weekly basis?",
            hint: "Pick the option that best describes your situation",
            type: "multiple-choice",
            options: [
                { label: "A lot (10-15)", eco_impact: "high", value: 3 },
                { label: "A good amount (5-8)", eco_impact: "medium", value: 2 },
                { label: "A little (2-3)", eco_impact: "low", value: 1 },
            ],
            eco_tip: "if you buy without reusing somehow, you adding more to the pile of waste",
            category: "materials",
        },
        {
            section: "I. Shipping and Packaging of Products",
            question: "How much do you bulk order during the season?",
            hint: "Pick the option that best describes your situation",
            type: "multiple-choice",
            options: [
                { label: "A good amount", eco_impact: "medium", value: 2 },
                { label: "A little", eco_impact: "low", value: 1 },
            ],
            eco_tip: "if you buy without reusing somehow, you adding more to the pile of waste",
            category: "materials",
        },
        {
            section: "I. Shipping and Packaging of Products",
            question: "Where do you order from?",
            hint: "Pick the option that best describes your situation",
            type: "multiple-choice",
            options: [
                { label: "Local", eco_impact: "low", value: 1 },
                { label: "Non-Local", eco_impact: "high", value: 3 },
            ],
            eco_tip: "if you buy without reusing somehow, you adding more to the pile of waste",
            category: "materials",
        },
    ],
    '2': [
        {
            section: "II. Disposable Meal Items",
            question: "How many boxes of 50 paper plates did you use?",
            hint: "Pick the option that best describes your situation",
            type: "multiple-choice",
            options: [
                { label: "12-16", eco_impact: "high", value: 3 },
                { label: "5-10", eco_impact: "medium", value: 2 },
                { label: "1-3", eco_impact: "low", value: 1 },
            ],
            eco_tip: "...",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "II. Disposable Meal Items",
            question: "How many boxes of 50 plastic forks did you use in a average competion?",
            hint: "Pick the option that best describes your situation",
            type: "multiple-choice",
            options: [
                { label: "10-15", eco_impact: "high", value: 3 },
                { label: "5-8", eco_impact: "medium", value: 2 },
                { label: "1-3", eco_impact: "low", value: 1 },
            ],
            eco_tip: "...",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "II. Disposable Meal Items",
            question: "How many packets of napkins did you use?",
            type: "multiple-choice",
            options: [
                { label: "5-8", eco_impact: "high", value: 3 },
                { label: "3-5", eco_impact: "medium", value: 2 },
                { label: "1-3", eco_impact: "low", value: 1 },
            ],
            eco_tip: "...",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "II. Disposable Meal Items",
            question: "What's your most purchased kind of water bottle pack?",
            type: "multiple-choice",
            options: [
                { label: "Aqua Fina", eco_impact: "high", value: 3 },
                { label: "", eco_impact: "medium", value: 2 },
                { label: "A little", eco_impact: "low", value: 1 },
            ],
            eco_tip: "Choose what kind of pack you use",
            eco_impact: "medium",
            category: "materials"
        }, {
            section: "II. Disposable Meal Items",
            question: "How many packs of these water bottles did you use during build seasons and competitions.",
            type: "multiple-choice",
            options: [
                { label: "A lot", eco_impact: "high", value: 3 },
                { label: "A good amount", eco_impact: "medium", value: 2 },
                { label: "A little", eco_impact: "low", value: 1 },
            ],
            eco_tip: "...",
            eco_impact: "medium",
            category: "materials"
        },
    ],
    '3': [
        {
            section: "III. Mechanical",
            question: "How do you use Drills?",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "For Robot", eco_impact: "medium", value: 2 },
                { label: "Own purpose", eco_impact: "medium", value: 2 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Mechanical",
            question: " How many Drills do you use?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 67,
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Programming",
            question: " How do you use Laptops?",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "For Robot", eco_impact: "medium", value: 2 },
                { label: "Own purpose", eco_impact: "medium", value: 2 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Programming",
            question: " How many Laptops do you use?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 30,
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Electrical",
            question: " How many Batteries/tools do you recharge",
            hint: "Enter an integer value",
            type: "multiple-choice",
            options: [
                { label: "For Robot", eco_impact: "High", value: 2 },
                { label: "Own purpose", eco_impact: "High", value: 2 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        },
        {
            section: "III. Electrical",
            question: " How often do you charge your batteries? ",
            hint: "Enter an integer value",
            type: "multiple-choice",
            options: [
                { label: "A lot", eco_impact: "high", value: 3 },
                { label: "A good amount", eco_impact: "medium", value: 2 },
                { label: "A little", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        },
        {
            section: "III. Fabrics",
            question: " How often do you buy filaments ",

            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 2 },
                { label: "Once in a week", eco_impact: "medium", value: 9 },
                { label: "Once in a week", eco_impact: "low", value: 5 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        }
    ],
    '4': [
        {
            section: "IV. Transportation",
            question: " Why do you use transportation ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 2 },
                { label: "Once in a week", eco_impact: "medium", value: 9 },
                { label: "Once in a week", eco_impact: "low", value: 5 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        },
        {
            section: "IV. Transportation",
            question: " What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "car", eco_impact: "high", value: 5 },
                { label: "public transport", eco_impact: "medium", value: 3 },
                { label: "walking/biking", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        }
        , {
            section: "IV. Transportation",
            question: " how many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        }

    ]
};
