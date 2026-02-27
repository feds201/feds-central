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
                { label: "Crystal Geyser, Nestle Pure Life, Dasani, Aquafina, Fiji, and Evian", eco_impact: "high", value: 3 },
                { label: "Klean Kanteen, Hydro Flask, S'wheat, Ocean Bottle", eco_impact: "low", value: 1 },
                { label: "None of the above", eco_impact: "medium", value: 0 },
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
            question: "How many drills do you have in your workshop?",
            hint: "Enter an integer value",
            type: "int",
            min: 0,
            max: 200,
            eco_tip: "The material that these drills are made out of severely effcets the enviroment",
            eco_impact: "high",
            category: "materials"
        },
        {
            section: "III. Mechanical",
            question: "What do you do with your extra lumber",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "Throw it away", eco_impact: "high", value: 3 },
                { label: "Repurpose/Recycle", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Mechanical",
            question: "If you do Recycle/Repurpose your lumber, how do you do so?",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "We don't Recycle/Repurpose our lumber", eco_impact: "high", value: 3 },
                { label: "Save it for next year", eco_impact: "medium", value: 2 },
                { label: "Use for training", eco_impact: "medium", value: 2 },
                { label: "Donate/Sale", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Mechanical",
            question: "What do you do with your extra wires?",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "Throw them away", eco_impact: "high", value: 3 },
                { label: "Save them for next year", eco_impact: "medium", value: 2 },
                { label: "Use for training", eco_impact: "medium", value: 2 },
                { label: "Donate/Sale", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Mechanical",
            question: "How many batteries do you order for the season?",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "10-15", eco_impact: "high", value: 3 },
                { label: "8-10", eco_impact: "medium", value: 2 },
                { label: "2-8", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "energy"
        },
        {
            section: "III. Programming",
            question: " How many Laptops do you use?",
           hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "25-40", eco_impact: "high", value: 3 },
                { label: "15-25", eco_impact: "medium", value: 2 },
                { label: "5-15", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "energy"
        },
        {
            section: "III. Mechanical",
            question: "What do you do with your extra sensors?",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "Throw them away", eco_impact: "high", value: 3 },
                { label: "Save them for next year", eco_impact: "medium", value: 2 },
                { label: "Use for training", eco_impact: "medium", value: 2 },
                { label: "Donate/Sale", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Fabrics",
            question: "What do you do with your extra lexan/polycarb?",
            hint: "Select an option",
            type: "multiple-choice",
            options: [
                { label: "Throw them away", eco_impact: "high", value: 3 },
                { label: "Save them for next year", eco_impact: "medium", value: 2 },
                { label: "Use for training", eco_impact: "medium", value: 2 },
                { label: "Donate/Sale", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "medium",
            category: "materials"
        },
        {
            section: "III. Mechanical",
            question: " How often do you charge your batteries? ",
            hint: "Enter an integer value",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "energy"
        },
        {
            section: "III. Fabrics",
            question: "How often do you buy filaments?",

            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        },
        {
            section: "III. Mechanical",
            question: "How long did you run your large machines (in hours)?",

            type: "multiple-choice",
            options: [
                { label: "10-15 hours", eco_impact: "high", value: 3 },
                { label: "5-10 hours", eco_impact: "medium", value: 2 },
                { label: "3-5 hours", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "energy"
        },
        {
            section: "III. Fabrics",
            question: "What do you use for prototyping/training?",

            type: "multiple-choice",
            options: [
                { label: "New material", eco_impact: "high", value: 3 },
                { label: "Cardboard", eco_impact: "medium", value: 2 },
                { label: "Scrap material", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "materials"
        }
    ],
    '4': [
        {
            section: "IV. Transportation",
            question: " First Competion: How often do you use transportation? ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        {
            section: "IV. Transportation",
            question: " First Competion: What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "Plane", eco_impact: "high", value: 5 },
                { label: "Bus", eco_impact: "medium", value: 3 },
                { label: "Car", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        }
        , {
            section: "IV. Transportation",
            question: " First Competion: How many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        


        {
            section: "IV. Transportation",
            question: " Second Competion: How often do you use transportation? ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        {
            section: "IV. Transportation",
            question: " Second Competion: What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "Plane", eco_impact: "high", value: 5 },
                { label: "Bus", eco_impact: "medium", value: 3 },
                { label: "Car", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        }
        , {
            section: "IV. Transportation",
            question: " Second Competion: How many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },


         {
            section: "IV. Transportation",
            question: " Third Competion: How often do you use transportation? ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        {
            section: "IV. Transportation",
            question: " Third Competion: What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "Plane", eco_impact: "high", value: 5 },
                { label: "Bus", eco_impact: "medium", value: 3 },
                { label: "Car", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        }
        , {
            section: "IV. Transportation",
            question: " Third Competion: How many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },



         {
            section: "IV. Transportation",
            question: " Fourth Competion: How often do you use transportation? ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        {
            section: "IV. Transportation",
            question: " Fourth Competion: What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "Plane", eco_impact: "high", value: 5 },
                { label: "Bus", eco_impact: "medium", value: 3 },
                { label: "Car", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        }
        , {
            section: "IV. Transportation",
            question: " Fourth Competion: How many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
    ],
    '5': [
        {
            section: "IV. Transportation",
            question: " First Competion: How often do you use transportation? ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        {
            section: "IV. Transportation",
            question: " First Competion: What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "Plane", eco_impact: "high", value: 5 },
                { label: "Bus", eco_impact: "medium", value: 3 },
                { label: "Car", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        }
        , {
            section: "IV. Transportation",
            question: " First Competion: How many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },



        {
            section: "IV. Transportation",
            question: " Second Competion: How often do you use transportation? ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        {
            section: "IV. Transportation",
            question: " Second Competion: What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "Plane", eco_impact: "high", value: 5 },
                { label: "Bus", eco_impact: "medium", value: 3 },
                { label: "Car", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        }
        , {
            section: "IV. Transportation",
            question: " Second Competion: How many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },


         {
            section: "IV. Transportation",
            question: " Third Competion: How often do you use transportation? ",
            type: "multiple-choice",
            options: [
                { label: "Every day", eco_impact: "high", value: 3 },
                { label: "Every week", eco_impact: "medium", value: 2 },
                { label: "Every month", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        {
            section: "IV. Transportation",
            question: " Third Competion: What kind of transportation do you use? ",
            type: "multiple-choice",
            options: [
                { label: "Plane", eco_impact: "high", value: 5 },
                { label: "Bus", eco_impact: "medium", value: 3 },
                { label: "Car", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        }
        , {
            section: "IV. Transportation",
            question: " Third Competion: How many miles do you travel during the season? ",
            type: "multiple-choice",
            options: [
                { label: "5000+ miles", eco_impact: "high", value: 3 },
                { label: "500-2500 miles", eco_impact: "medium", value: 2 },
                { label: "0-500 miles", eco_impact: "low", value: 1 },
            ],
            eco_tip: "",
            eco_impact: "High",
            category: "transport"
        },
        
    ]
};
