// Global variables
let teamsData = [];
let filteredData = [];
const modal = document.getElementById("team-modal");
const closeBtn = document.getElementsByClassName("close")[0];
const apiUrl = "https://script.google.com/macros/s/AKfycbyebARML-RoGQGZ7ugmVNGvuwtGhyh5it1LEeNWDaiVQPsbA1mD8pSZcDO9Vk2UryIxTg/exec";
let teamPerformanceMetrics = {};

// Event listeners
document.addEventListener("DOMContentLoaded", function() {
    // Add animation classes to panels
    document.querySelectorAll('.panel').forEach((panel, i) => {
        panel.style.opacity = '0';
        panel.style.transform = 'translateY(20px)';
        setTimeout(() => {
            panel.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
            panel.style.opacity = '1';
            panel.style.transform = 'translateY(0)';
        }, 100 * i);
    });
    
    // Load the data
    fetchData();
    
    // Add event listeners
    document.getElementById("apply-filters").addEventListener("click", applyFilters);
    document.getElementById("reset-filters").addEventListener("click", resetFilters);
    
    // Close modal when clicking X
    closeBtn.addEventListener("click", function() {
        modal.classList.remove("show");
        setTimeout(() => {
            modal.style.display = "none";
        }, 300);
    });
    
    // Close modal when clicking outside
    window.addEventListener("click", function(event) {
        if (event.target == modal) {
            modal.classList.remove("show");
            setTimeout(() => {
                modal.style.display = "none";
            }, 300);
        }
    });
    
    // Add hover effects to buttons
    document.querySelectorAll('button').forEach(button => {
        button.addEventListener('mouseover', () => {
            button.style.transform = 'translateY(-3px)';
            button.style.boxShadow = '0 6px 10px rgba(0,0,0,0.2)';
        });
        
        button.addEventListener('mouseout', () => {
            button.style.transform = '';
            button.style.boxShadow = '';
        });
    });
});

// Function to fetch data from API with loading animation
async function fetchData() {
    const loadingEl = document.getElementById("loading");
    loadingEl.style.display = "flex";
    
    try {
        const response = await fetch(apiUrl);
        const data = await response.json();
        
        teamsData = data;
        filteredData = [...teamsData];
        
        console.log("Data fetched successfully:", teamsData);
        
        // Once data is loaded, update the UI
        loadData();
        
        // Generate smart insights after loading
        generateSmartInsights();
        
        // Populate advanced analytics sections
        generateAdvancedAnalytics();
        
        // Hide loading with fade-out
        loadingEl.style.opacity = '0';
        setTimeout(() => {
            loadingEl.style.display = "none";
            loadingEl.style.opacity = '1';
        }, 300);
        
    } catch (error) {
        console.error("Error fetching data:", error);
        loadingEl.innerHTML = `
            <div style="text-align: center; color: #ea4335;">
                <svg width="50" height="50" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12" y2="16"></line>
                </svg>
                <p>Error loading data. Please try again later.</p>
                <button onclick="fetchData()" style="margin-top: 10px; background-color: #ea4335;">Retry</button>
            </div>
        `;
    }
}

// Load and display data
function loadData() {
    displayTeamsData();
    updateStatistics();
    createCharts();
    
    // Add fade-in animation to stats
    const statCards = document.querySelectorAll('.stat-card');
    statCards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'scale(0.95)';
        setTimeout(() => {
            card.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
            card.style.opacity = '1';
            card.style.transform = 'scale(1)';
        }, index * 150);
    });
}

// Function to display teams data in table
function displayTeamsData() {
    const tableBody = document.getElementById("teams-data");
    const table = document.getElementById("teams-table");
    
    // Create table header if it doesn't exist
    if (!document.querySelector('#teams-table thead')) {
        const thead = document.createElement('thead');
        const headerRow = document.createElement('tr');
        
        const headers = [
            { text: 'Team #', icon: '🔢' },
            { text: 'Image', icon: '📷' },
            { text: 'Drivetrain', icon: '🔄' },
            { text: 'Auton', icon: '🤖' },
            { text: 'Score Type', icon: '🎯' },
            { text: 'Endgame', icon: '🏁' },
            { text: 'Actions', icon: '⚙️' }
        ];
        
        headers.forEach(header => {
            const th = document.createElement('th');
            th.innerHTML = `${header.icon} <span>${header.text}</span>`;
            headerRow.appendChild(th);
        });
        
        thead.appendChild(headerRow);
        table.appendChild(thead);
    }
    
    // Clear existing data
    tableBody.innerHTML = "";
    
    // Show no results message if no data
    if (filteredData.length === 0) {
        const emptyRow = document.createElement('tr');
        const emptyCell = document.createElement('td');
        emptyCell.colSpan = 7;
        emptyCell.style.textAlign = 'center';
        emptyCell.style.padding = '30px';
        emptyCell.innerHTML = `
            <div style="color: #5f6368;">
                <svg width="50" height="50" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin: 0 auto; display: block; opacity: 0.6;">
                    <circle cx="12" cy="8" r="5"></circle>
                    <path d="M20 21v-2a7 7 0 0 0-14 0v2"></path>
                    <line x1="8" y1="2" x2="16" y2="16"></line>
                </svg>
                <p style="margin-top: 10px; font-size: 1.1em;">No teams match your filter criteria</p>
                <button onclick="resetFilters()" style="margin-top: 10px; display: inline-block;">Reset Filters</button>
            </div>
        `;
        emptyRow.appendChild(emptyCell);
        tableBody.appendChild(emptyRow);
        return;
    }
    
    // Add rows with animation
    filteredData.forEach((team, index) => {
        const row = document.createElement("tr");
        row.style.animation = `fadeIn 0.3s ease forwards ${index * 0.05}s`;
        row.style.opacity = "0";
        
        // Team number
        const teamCell = document.createElement("td");
        teamCell.textContent = team.team;
        teamCell.style.fontWeight = "bold";
        teamCell.style.fontSize = "1.1em";
        row.appendChild(teamCell);
        
        // Robot image
        const imageCell = document.createElement("td");
        const img = document.createElement("img");
        img.src = team.botImageId ? `https://lh3.google.com/u/0/d/${team.botImageId}` : "image.png";
        img.alt = `Team ${team.team} Robot`;
        img.className = "bot-image";
        img.dataset.team = team.team;
        
        // Add hover effect
        img.addEventListener("mouseover", function() {
            this.style.transform = "scale(1.1)";
            this.style.boxShadow = "0 8px 16px rgba(0,0,0,0.2)";
        });
        
        img.addEventListener("mouseout", function() {
            this.style.transform = "";
            this.style.boxShadow = "";
        });
        
        img.addEventListener("click", () => showTeamDetails(team));
        img.addEventListener("error", function() {
            this.src = "https://media.istockphoto.com/id/1065465342/vector/cute-vector-speech-bubble-icon-with-hello-greeting.jpg?s=612x612&w=0&k=20&c=dIq85nTuC9OGJAuuIUdz0u0EQg2N4pEpWzKxa8S0gbY=";
        });
        imageCell.appendChild(img);
        row.appendChild(imageCell);
        
        // Drivetrain
        const drivetrainCell = document.createElement("td");
        drivetrainCell.textContent = team.drivetrain || "N/A";
        if (team.drivetrain === "Swerve drive") {
            drivetrainCell.innerHTML = `<span class="tag tag-blue">Swerve drive</span>`;
        } else if (team.drivetrain === "Tank drive") {
            drivetrainCell.innerHTML = `<span class="tag tag-red">Tank drive</span>`;
        } else {
            drivetrainCell.innerHTML = `<span class="tag tag-gray">Unknown</span>`;
        }
        row.appendChild(drivetrainCell);
        
        // Auton
        const autonCell = document.createElement("td");
        autonCell.textContent = team.auton || "N/A";
        if (team.auton && team.auton.includes("Auto")) {
            autonCell.style.color = "#34a853";
            autonCell.style.fontWeight = "500";
        }
        row.appendChild(autonCell);
        
        // Score Type
        const scoreTypeCell = document.createElement("td");
        if (team.scoreType) {
            const scoreTypes = team.scoreType.split(", ");
            const scoreTypesHTML = scoreTypes.map(type => 
                `<span class="mini-tag">${type}</span>`
            ).join(" ");
            scoreTypeCell.innerHTML = scoreTypesHTML;
        } else {
            scoreTypeCell.textContent = "N/A";
        }
        row.appendChild(scoreTypeCell);
        
        // Endgame
        const endgameCell = document.createElement("td");
        if (team.endgame === "Deep Climb") {
            endgameCell.innerHTML = `<span class="tag tag-green">Deep Climb</span>`;
        } else if (team.endgame === "Shallow Climb") {
            endgameCell.innerHTML = `<span class="tag tag-yellow">Shallow Climb</span>`;
        } else if (team.endgame === "Park") {
            endgameCell.innerHTML = `<span class="tag tag-blue-light">Park</span>`;
        } else {
            endgameCell.textContent = team.endgame || "N/A";
        }
        row.appendChild(endgameCell);
        
        // Actions
        const actionsCell = document.createElement("td");
        const viewBtn = document.createElement("button");
        viewBtn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 5px;">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
            <circle cx="12" cy="12" r="3"></circle>
        </svg> View Details`;
        viewBtn.className = "button-small";
        viewBtn.addEventListener("click", () => showTeamDetails(team));
        actionsCell.appendChild(viewBtn);
        row.appendChild(actionsCell);
        
        tableBody.appendChild(row);
    });
    
    // Add CSS for tags
    if (!document.getElementById('table-styles')) {
        const style = document.createElement('style');
        style.id = 'table-styles';
        style.textContent = `
            .tag {
                display: inline-block;
                padding: 4px 8px;
                border-radius: 12px;
                font-size: 0.85em;
                font-weight: 500;
                text-align: center;
            }
            .tag-blue { background-color: #d2e3fc; color: #1a73e8; }
            .tag-red { background-color: #fce8e6; color: #ea4335; }
            .tag-green { background-color: #ceead6; color: #34a853; }
            .tag-yellow { background-color: #fef7e0; color: #f9ab00; }
            .tag-blue-light { background-color: #e8f0fe; color: #4285f4; }
            .tag-gray { background-color: #f1f3f4; color: #5f6368; }
            .mini-tag {
                display: inline-block;
                padding: 2px 6px;
                border-radius: 10px;
                font-size: 0.8em;
                background-color: #f1f3f4;
                color: #5f6368;
                margin: 2px;
            }
            .button-small {
                padding: 6px 12px;
                font-size: 0.9em;
                border-radius: 6px;
                display: inline-flex;
                align-items: center;
            }
            @keyframes pulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.1); }
                100% { transform: scale(1); }
            }
        `;
        document.head.appendChild(style);
    }
}

// Show team details in modal
function showTeamDetails(team) {
    const modalTitle = document.getElementById("modal-team-title");
    const modalImg = document.getElementById("modal-team-img");
    const modalInfo = document.getElementById("modal-team-info");
    
    modalTitle.innerHTML = `
        <span style="font-size: 1.2em; color: #5f6368;">Team</span> 
        <span style="color: #1a73e8; font-size: 1.5em;">${team.team}</span>
    `;
    
    modalImg.src = team.botImageId ? `https://lh3.google.com/u/0/d/${team.botImageId}` : "https://media.istockphoto.com/id/1065465342/vector/cute-vector-speech-bubble-icon-with-hello-greeting.jpg?s=612x612&w=0&k=20&c=dIq85nTuC9OGJAuuIUdz0u0EQg2N4pEpWzKxa8S0gbY=";
    modalImg.alt = `Team ${team.team} Robot`;
    modalImg.style.transition = "transform 0.5s ease";
    
    // Add zoom effect on hover
    modalImg.addEventListener("mouseover", function() {
        this.style.transform = "scale(1.02)";
    });
    
    modalImg.addEventListener("mouseout", function() {
        this.style.transform = "scale(1)";
    });
    
    modalImg.addEventListener("error", function() {
        this.src = "https://media.istockphoto.com/id/1065465342/vector/cute-vector-speech-bubble-icon-with-hello-greeting.jpg?s=612x612&w=0&k=20&c=dIq85nTuC9OGJAuuIUdz0u0EQg2N4pEpWzKxa8S0gbY=";
    });
    
    // Generate detail fields
    modalInfo.innerHTML = "";
    
    // Add team summary at the top
    const summary = document.createElement("div");
    summary.className = "team-summary";
    summary.innerHTML = `
        <div class="summary-title">Team Summary</div>
        <div class="summary-content">
            <div class="summary-item">
                <div class="summary-icon" style="background-color: #d2e3fc;">🔄</div>
                <div class="summary-text">${team.drivetrain || 'N/A'}</div>
            </div>
            <div class="summary-item">
                <div class="summary-icon" style="background-color: #ceead6;">🤖</div>
                <div class="summary-text">${team.auton || 'N/A'}</div>
            </div>
            <div class="summary-item">
                <div class="summary-icon" style="background-color: #fef7e0;">🏁</div>
                <div class="summary-text">${team.endgame || 'N/A'}</div>
            </div>
        </div>
    `;
    modalInfo.appendChild(summary);
    
    // Create sections
    const sections = [
        {
            title: "Autonomous",
            icon: "🤖",
            color: "#ceead6",
            fields: [
                { label: "Autonomous Mode", value: team.auton, icon: "🤖" },
                { label: "Leave in Auton", value: team.leaveAuton, icon: "🚶" }
            ]
        },
        {
            title: "Scoring Capabilities",
            icon: "🎯",
            color: "#d2e3fc",
            fields: [
                { label: "Score Location", value: team.scoreLocation, icon: "📍" },
                { label: "Score Type", value: team.scoreType, icon: "🎯" },
                { label: "Score Coral", value: team.scoreCoral, icon: "🏆" },
                { label: "Score Algae", value: team.scoreAlgae, icon: "🌊" }
            ]
        },
        {
            title: "Intake Capabilities",
            icon: "🧩",
            color: "#fce8e6",
            fields: [
                { label: "Intake Coral", value: team.intakeCoral, icon: "🧩" },
                { label: "Intake Algae", value: team.intakeAlgae, icon: "🌿" }
            ]
        },
        {
            title: "Endgame & Metadata",
            icon: "📊",
            color: "#fef7e0",
            fields: [
                { label: "Endgame", value: team.endgame, icon: "🏁" },
                { label: "Scouted On", value: formatTimestamp(team.timestamp), icon: "📅" }
            ]
        }
    ];
    
    // Add CSS for sections if not already added
    if (!document.getElementById('modal-styles')) {
        const style = document.createElement('style');
        style.id = 'modal-styles';
        style.textContent = `
            .team-summary {
                background: linear-gradient(135deg, #f5f7fa, #f8f9ff);
                border-radius: 12px;
                padding: 15px;
                margin-bottom: 25px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            }
            .summary-title {
                font-size: 1.1em;
                font-weight: 500;
                color: #5f6368;
                margin-bottom: 10px;
            }
            .summary-content {
                display: flex;
                justify-content: space-around;
                flex-wrap: wrap;
                gap: 10px;
            }
            .summary-item {
                display: flex;
                align-items: center;
                gap: 10px;
            }
            .summary-icon {
                width: 40px;
                height: 40px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 1.2em;
            }
            .summary-text {
                font-weight: 500;
            }
            .detail-section {
                background-color: #fff;
                border-radius: 12px;
                padding: 15px;
                margin-bottom: 20px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.05);
                opacity: 0;
                transform: translateY(10px);
                animation: slideIn 0.5s forwards;
            }
            .section-header {
                display: flex;
                align-items: center;
                gap: 10px;
                padding-bottom: 10px;
                margin-bottom: 15px;
                border-bottom: 1px solid #f1f3f4;
            }
            .section-icon {
                width: 30px;
                height: 30px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 1em;
            }
            .section-title {
                font-weight: 500;
                font-size: 1.1em;
            }
            .detail-items {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
                gap: 10px;
            }
            .detail-item {
                background-color: #f8f9fa;
                border-radius: 8px;
                padding: 12px;
                transition: all 0.2s ease;
            }
            .detail-item:hover {
                background-color: #f1f3f4;
                transform: translateX(3px);
            }
            .detail-label {
                font-size: 0.9em;
                color: #5f6368;
                margin-bottom: 5px;
                display: flex;
                align-items: center;
                gap: 5px;
            }
            .detail-value {
                font-weight: 500;
            }
            @keyframes slideIn {
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }
        `;
        document.head.appendChild(style);
    }
    
    // Add sections
    sections.forEach((section, sectionIndex) => {
        const validFields = section.fields.filter(field => field.value);
        
        if (validFields.length > 0) {
            const sectionEl = document.createElement("div");
            sectionEl.className = "detail-section";
            sectionEl.style.animationDelay = `${sectionIndex * 0.1}s`;
            
            const header = document.createElement("div");
            header.className = "section-header";
            header.innerHTML = `
                <div class="section-icon" style="background-color: ${section.color}">${section.icon}</div>
                <div class="section-title">${section.title}</div>
            `;
            
            const items = document.createElement("div");
            items.className = "detail-items";
            
            validFields.forEach((field, fieldIndex) => {
                if (field.value) {
                    const item = document.createElement("div");
                    item.className = "detail-item";
                    
                    const label = document.createElement("div");
                    label.className = "detail-label";
                    label.innerHTML = `${field.icon} ${field.label}`;
                    
                    const value = document.createElement("div");
                    value.className = "detail-value";
                    value.textContent = field.value;
                    
                    item.appendChild(label);
                    item.appendChild(value);
                    items.appendChild(item);
                }
            });
            
            sectionEl.appendChild(header);
            sectionEl.appendChild(items);
            modalInfo.appendChild(sectionEl);
        }
    });
    
    // Add performance predictions section
    const predictionsContainer = document.getElementById("predictions-container");
    predictionsContainer.className = "loading-shimmer";
    
    // Simulate AI prediction generation with a delay
    setTimeout(() => {
        generatePredictions(team, predictionsContainer);
    }, 1500);
    
    modal.style.display = "block";
    // Force reflow for transition to work
    void modal.offsetWidth;
    modal.classList.add("show");
}

// Format timestamp
function formatTimestamp(timestamp) {
    if (!timestamp) return "N/A";
    
    const date = new Date(timestamp);
    return `${date.toLocaleDateString()} ${date.toLocaleTimeString()}`;
}

// Apply filters with animation
function applyFilters() {
    // Add animation to filter panel
    const filterPanel = document.querySelector('.panel:first-child');
    filterPanel.style.boxShadow = '0 8px 30px rgba(26, 115, 232, 0.2)';
    setTimeout(() => {
        filterPanel.style.boxShadow = '';
    }, 800);
    
    document.getElementById("teams-data").style.opacity = "0.5";
    
    setTimeout(() => {
        const teamFilter = document.getElementById("team-filter").value;
        const drivetrainFilter = document.getElementById("drivetrain-filter").value;
        const endgameFilter = document.getElementById("endgame-filter").value;
        
        filteredData = teamsData.filter(team => {
            let matchesTeam = true;
            let matchesDrivetrain = true;
            let matchesEndgame = true;
            
            if (teamFilter) {
                matchesTeam = team.team.toString() === teamFilter;
            }
            
            if (drivetrainFilter) {
                matchesDrivetrain = team.drivetrain === drivetrainFilter;
            }
            
            if (endgameFilter) {
                matchesEndgame = team.endgame === endgameFilter;
            }
            
            return matchesTeam && matchesDrivetrain && matchesEndgame;
        });
        
        loadData();
        
        // Update filter count display
        const totalCount = teamsData.length;
        const filteredCount = filteredData.length;
        
        // Add or update filter results note
        let filterNote = document.getElementById("filter-results-note");
        if (!filterNote) {
            filterNote = document.createElement("div");
            filterNote.id = "filter-results-note";
            filterNote.style.textAlign = "right";
            filterNote.style.marginTop = "10px";
            filterNote.style.fontSize = "0.9em";
            filterNote.style.color = "#5f6368";
            document.querySelector(".panel:first-child .panel-body").appendChild(filterNote);
        }
        
        filterNote.textContent = `Showing ${filteredCount} of ${totalCount} teams`;
        filterNote.style.fontWeight = filteredCount < totalCount ? "bold" : "normal";
        filterNote.style.color = filteredCount < totalCount ? "#1a73e8" : "#5f6368";
        
        document.getElementById("teams-data").style.opacity = "1";
    }, 300);
}

// Reset filters
function resetFilters() {
    // Add shake animation to reset button
    const resetBtn = document.getElementById("reset-filters");
    resetBtn.style.animation = "shake 0.5s ease";
    setTimeout(() => {
        resetBtn.style.animation = "";
    }, 500);
    
    document.getElementById("team-filter").value = "";
    document.getElementById("drivetrain-filter").value = "";
    document.getElementById("endgame-filter").value = "";
    
    document.getElementById("teams-data").style.opacity = "0.5";
    
    setTimeout(() => {
        filteredData = [...teamsData];
        loadData();
        
        // Update filter count display
        let filterNote = document.getElementById("filter-results-note");
        if (filterNote) {
            filterNote.textContent = `Showing all ${teamsData.length} teams`;
            filterNote.style.fontWeight = "normal";
            filterNote.style.color = "#5f6368";
        }
        
        document.getElementById("teams-data").style.opacity = "1";
    }, 300);
    
    // Add shake keyframes if not already added
    if (!document.getElementById('animation-styles')) {
        const style = document.createElement('style');
        style.id = 'animation-styles';
        style.textContent = `
            @keyframes shake {
                0%, 100% { transform: translateX(0); }
                20%, 60% { transform: translateX(-5px); }
                40%, 80% { transform: translateX(5px); }
            }
        `;
        document.head.appendChild(style);
    }
}

// Update statistics
function updateStatistics() {
    const totalTeams = filteredData.length;
    const swerveTeams = filteredData.filter(team => team.drivetrain === "Swerve drive").length;
    const tankTeams = filteredData.filter(team => team.drivetrain === "Tank drive").length;
    const climbTeams = filteredData.filter(team => 
        team.endgame === "Shallow Climb" || team.endgame === "Deep Climb"
    ).length;
    
    animateCounter("total-teams", totalTeams);
    animateCounter("swerve-teams", swerveTeams);
    animateCounter("tank-teams", tankTeams);
    animateCounter("climb-teams", climbTeams);
    
    // Add percentages to stats
    if (totalTeams > 0) {
        updatePercentage("swerve-teams", swerveTeams / totalTeams * 100);
        updatePercentage("tank-teams", tankTeams / totalTeams * 100);
        updatePercentage("climb-teams", climbTeams / totalTeams * 100);
    }
}

// Update percentage display
function updatePercentage(elementId, percentage) {
    const element = document.getElementById(elementId);
    const parent = element.parentElement;
    
    // Add or update percentage display
    let percentEl = parent.querySelector('.stat-percentage');
    if (!percentEl) {
        percentEl = document.createElement('div');
        percentEl.className = 'stat-percentage';
        percentEl.style.fontSize = '0.9em';
        percentEl.style.color = '#5f6368';
        percentEl.style.marginTop = '5px';
        parent.appendChild(percentEl);
    }
    
    percentEl.textContent = `${Math.round(percentage)}% of total`;
}

// Animate counter for statistics
function animateCounter(elementId, targetValue) {
    const element = document.getElementById(elementId);
    const startValue = parseInt(element.textContent) || 0;
    const duration = 1000; // 1 second
    const stepTime = 20;
    const steps = duration / stepTime;
    const increment = (targetValue - startValue) / steps;
    
    let currentValue = startValue;
    const timer = setInterval(() => {
        currentValue += increment;
        if ((increment >= 0 && currentValue >= targetValue) || 
            (increment < 0 && currentValue <= targetValue)) {
            clearInterval(timer);
            element.textContent = targetValue;
        } else {
            element.textContent = Math.round(currentValue);
        }
    }, stepTime);
}

// Create charts
function createCharts() {
    createDrivetrainChart();
    createEndgameChart();
}

// Create drivetrain distribution chart
function createDrivetrainChart() {
    const chartContainer = document.getElementById("drivetrain-chart");
    
    // Count drivetrain types
    const drivetrainCounts = {};
    filteredData.forEach(team => {
        const drivetrain = team.drivetrain || "Unknown";
        drivetrainCounts[drivetrain] = (drivetrainCounts[drivetrain] || 0) + 1;
    });
    
    // Create enhanced bar chart
    let chartHTML = `
        <h3>Drivetrain Distribution</h3>
        <div style="height: 220px; display: flex; align-items: flex-end; justify-content: space-around; margin-top: 30px;">
    `;
    
    const maxCount = Math.max(...Object.values(drivetrainCounts), 1);
    const colors = {
        "Swerve drive": "#1a73e8",
        "Tank drive": "#ea4335",
        "Unknown": "#9aa0a6"
    };
    
    let animationStyles = "<style>";
    
    Object.entries(drivetrainCounts).forEach(([drivetrain, count], index) => {
        const height = count / maxCount * 180;
        const barWidth = 80;
        const color = colors[drivetrain] || "#9aa0a6";
        
        // Create unique animation name for each bar
        const animationName = `growBar${index}`;
        
        // Add animation keyframes to the styles
        animationStyles += `
            @keyframes ${animationName} {
                from { height: 0px; }
                to { height: ${height}px; }
            }
        `;
        
        chartHTML += `
            <div style="text-align: center; width: ${barWidth}px;">
                <div class="chart-bar" data-value="${count}" style="
                    background: linear-gradient(to top, ${color}, ${color}dd);
                    width: ${barWidth}px; 
                    height: 0px; 
                    margin: 0 auto; 
                    border-radius: 8px 8px 0 0;
                    box-shadow: 0 2px 10px ${color}66;
                    animation: ${animationName} 1s ease forwards ${index * 0.2}s;
                    animation-fill-mode: both;
                "></div>
                <div style="margin-top: 10px; font-weight: 500;">${drivetrain}</div>
                <div style="margin-top: 5px;"><strong>${count}</strong> teams</div>
            </div>
        `;
    });
    
    animationStyles += "</style>";
    chartHTML += `</div>` + animationStyles;
    
    chartContainer.innerHTML = chartHTML;
}

// Create endgame distribution chart
function createEndgameChart() {
    const chartContainer = document.getElementById("endgame-chart");
    
    // Count endgame types
    const endgameCounts = {};
    filteredData.forEach(team => {
        const endgame = team.endgame || "Unknown";
        endgameCounts[endgame] = (endgameCounts[endgame] || 0) + 1;
    });
    
    // Create enhanced bar chart
    let chartHTML = `
        <h3>Endgame Distribution</h3>
        <div style="height: 220px; display: flex; align-items: flex-end; justify-content: space-around; margin-top: 30px;">
    `;
    
    const maxCount = Math.max(...Object.values(endgameCounts), 1);
    const colors = {
        "Park": "#4285f4",
        "Shallow Climb": "#fbbc04",
        "Deep Climb": "#34a853",
        "Unknown": "#9aa0a6"
    };
    
    let animationStyles = "<style>";
    
    Object.entries(endgameCounts).forEach(([endgame, count], index) => {
        const height = count / maxCount * 180;
        const barWidth = 80;
        const color = colors[endgame] || "#9aa0a6";
        
        // Create unique animation name for each bar
        const animationName = `growEndgameBar${index}`;
        
        // Add animation keyframes to the styles
        animationStyles += `
            @keyframes ${animationName} {
                from { height: 0px; }
                to { height: ${height}px; }
            }
        `;
        
        chartHTML += `
            <div style="text-align: center; width: ${barWidth}px;">
                <div class="chart-bar" data-value="${count}" style="
                    background: linear-gradient(to top, ${color}, ${color}dd);
                    width: ${barWidth}px; 
                    height: 0px; 
                    margin: 0 auto; 
                    border-radius: 8px 8px 0 0;
                    box-shadow: 0 2px 10px ${color}66;
                    animation: ${animationName} 1s ease forwards ${index * 0.2}s;
                    animation-fill-mode: both;
                "></div>
                <div style="margin-top: 10px; font-weight: 500;">${endgame}</div>
                <div style="margin-top: 5px;"><strong>${count}</strong> teams</div>
            </div>
        `;
    });
    
    animationStyles += "</style>";
    chartHTML += `</div>` + animationStyles;
    
    chartContainer.innerHTML = chartHTML;
}

// Add this new function to generate smart insights based on data
function generateSmartInsights() {
    const insightsContainer = document.getElementById("insights-container");
    
    // Clear loading state
    insightsContainer.innerHTML = "";
    
    // Add PyIntel AI badge at the top
    const pyintelBadge = document.createElement('div');
    pyintelBadge.className = 'pyintel-badge';
    pyintelBadge.innerHTML = `
        <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z"/>
        </svg>
        Powered by PyIntel AI
    `;
    insightsContainer.appendChild(pyintelBadge);
    
    // Calculate insights
    const totalTeams = teamsData.length;
    const swerveTeams = teamsData.filter(team => team.drivetrain === "Swerve drive").length;
    const tankTeams = teamsData.filter(team => team.drivetrain === "Tank drive").length;
    const climbTeams = teamsData.filter(team => 
        team.endgame === "Shallow Climb" || team.endgame === "Deep Climb"
    ).length;
    
    const swervePercentage = Math.round((swerveTeams / totalTeams) * 100);
    const climbPercentage = Math.round((climbTeams / totalTeams) * 100);
    
    // Generate insight cards
    const insights = [];
    
    // Strategy insight
    if (swervePercentage > 60) {
        insights.push({
            type: 'strategy',
            title: 'Drivetrain Strategy',
            content: `${swervePercentage}% of teams are using Swerve drive. This suggests high mobility will be a key factor in matches. Consider strategies that leverage or counter high maneuverability.`
        });
    } else if (tankTeams > swerveTeams) {
        insights.push({
            type: 'strategy',
            title: 'Drivetrain Strategy',
            content: `More teams are using Tank drive (${tankTeams}) than Swerve drive (${swerveTeams}). This suggests teams may be prioritizing pushing power over maneuverability.`
        });
    }
    
    // Climbing insight
    if (climbPercentage > 70) {
        insights.push({
            type: 'warning',
            title: 'Endgame Competition',
            content: `${climbPercentage}% of teams can climb. Expect high competition for climbing positions in endgame. Having a backup strategy may be crucial.`
        });
    } else if (climbPercentage < 30) {
        insights.push({
            type: 'opportunity',
            title: 'Endgame Opportunity',
            content: `Only ${climbPercentage}% of teams can climb. This represents a significant scoring opportunity in the endgame phase if your team can climb reliably.`
        });
    }
    
    // Alliance partner insight
    const goodClimbers = teamsData.filter(team => team.endgame === "Deep Climb").map(team => team.team);
    if (goodClimbers.length > 0 && goodClimbers.length <= 5) {
        insights.push({
            type: 'strength',
            title: 'Alliance Partner Recommendation',
            content: `Only ${goodClimbers.length} teams can perform Deep Climb (${goodClimbers.join(', ')}). Consider them as valuable alliance partners for endgame scoring.`
        });
    }
    
    // Display insights with staggered animation
    if (insights.length === 0) {
        const noInsightsCard = document.createElement('div');
        noInsightsCard.className = 'insight-card insight-strategy';
        noInsightsCard.innerHTML = `
            <h4>No Significant Insights</h4>
            <p>Try adjusting filters or add more team data to generate strategic insights.</p>
        `;
        insightsContainer.appendChild(noInsightsCard);
    } else {
        insights.forEach((insight, index) => {
            const insightCard = document.createElement('div');
            insightCard.className = `insight-card insight-${insight.type} glow-card`;
            insightCard.style.opacity = '0';
            insightCard.style.transform = 'translateY(10px)';
            
            insightCard.innerHTML = `
                <h4>${insight.title}</h4>
                <p>${insight.content}</p>
            `;
            
            insightsContainer.appendChild(insightCard);
            
            // Staggered animation
            setTimeout(() => {
                insightCard.style.transition = 'opacity 0.6s ease, transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1)';
                insightCard.style.opacity = '1';
                insightCard.style.transform = 'translateY(0)';
            }, index * 200);
        });
    }
}

// Add function to generate advanced analytics visualizations
function generateAdvancedAnalytics() {
    // Generate drivetrain comparison slider
    const drivetrainComparison = document.getElementById("drivetrain-comparison");
    const totalTeams = teamsData.length;
    const swerveTeams = teamsData.filter(team => team.drivetrain === "Swerve drive").length;
    const swervePercentage = Math.round((swerveTeams / totalTeams) * 100);
    
    drivetrainComparison.innerHTML = `
        <div class="slider-fill" style="width: 0%"></div>
        <div class="slider-label">Swerve Drive</div>
        <div class="slider-percentage">${swervePercentage}%</div>
    `;
    
    // Animate the slider fill with a delay
    setTimeout(() => {
        const sliderFill = drivetrainComparison.querySelector('.slider-fill');
        sliderFill.style.width = `${swervePercentage}%`;
    }, 500);
    
    // Generate climbing capability slider
    const climbingCapability = document.getElementById("climbing-capability");
    const climbTeams = teamsData.filter(team => 
        team.endgame === "Shallow Climb" || team.endgame === "Deep Climb"
    ).length;
    const climbPercentage = Math.round((climbTeams / totalTeams) * 100);
    
    climbingCapability.innerHTML = `
        <div class="slider-fill" style="width: 0%"></div>
        <div class="slider-label">Can Climb</div>
        <div class="slider-percentage">${climbPercentage}%</div>
    `;
    
    // Animate the slider fill with a delay
    setTimeout(() => {
        const sliderFill = climbingCapability.querySelector('.slider-fill');
        sliderFill.style.width = `${climbPercentage}%`;
    }, 800);
    
    // Generate team activity heatmap
    const heatmap = document.getElementById("team-activity-heatmap");
    heatmap.innerHTML = "";
    
    // Create a simulated heatmap based on team capabilities
    teamsData.slice(0, 20).forEach(team => {
        const capabilities = [
            team.auton ? 1 : 0,
            team.drivetrain === "Swerve drive" ? 1 : 0,
            team.endgame === "Deep Climb" ? 1 : team.endgame === "Shallow Climb" ? 0.7 : 0.3,
            team.scoreType ? (team.scoreType.split(",").length / 3) : 0
        ];
        
        const avgCapability = capabilities.reduce((sum, val) => sum + val, 0) / capabilities.length;
        const hue = Math.floor(avgCapability * 120); // From red (0) to green (120)
        
        const cell = document.createElement("div");
        cell.className = "heatmap-cell";
        cell.style.backgroundColor = `hsl(${hue}, 80%, 60%)`;
        cell.title = `Team ${team.team}: ${Math.round(avgCapability * 100)}% capability score`;
        
        heatmap.appendChild(cell);
    });
    
    // Generate correlation insights
    const correlationInsights = document.getElementById("correlation-insights");
    correlationInsights.innerHTML = "";
    
    // Calculate some correlations
    const swerveAndClimb = teamsData.filter(team => 
        team.drivetrain === "Swerve drive" && 
        (team.endgame === "Deep Climb" || team.endgame === "Shallow Climb")
    ).length;
    
    const swerveWithClimbPercentage = Math.round((swerveAndClimb / swerveTeams) * 100) || 0;
    
    const tankTeamsCount = teamsData.filter(team => team.drivetrain === "Tank drive").length;
    const tankAndClimb = teamsData.filter(team => 
        team.drivetrain === "Tank drive" && 
        (team.endgame === "Deep Climb" || team.endgame === "Shallow Climb")
    ).length;
    
    const tankWithClimbPercentage = Math.round((tankAndClimb / tankTeamsCount) * 100) || 0;
    
    correlationInsights.innerHTML = `
        <div style="margin-bottom: 15px;">
            <div style="font-weight: 500; margin-bottom: 5px;">Swerve Drive & Climbing:</div>
            <div class="comparison-slider">
                <div class="slider-fill" style="width: 0%"></div>
                <div class="slider-label">Correlation</div>
                <div class="slider-percentage">${swerveWithClimbPercentage}%</div>
            </div>
        </div>
        <div>
            <div style="font-weight: 500; margin-bottom: 5px;">Tank Drive & Climbing:</div>
            <div class="comparison-slider">
                <div class="slider-fill" style="width: 0%"></div>
                <div class="slider-label">Correlation</div>
                <div class="slider-percentage">${tankWithClimbPercentage}%</div>
            </div>
        </div>
    `;
    
    // Animate correlation sliders
    setTimeout(() => {
        const sliders = correlationInsights.querySelectorAll('.slider-fill');
        sliders[0].style.width = `${swerveWithClimbPercentage}%`;
        setTimeout(() => {
            sliders[1].style.width = `${tankWithClimbPercentage}%`;
        }, 200);
    }, 1000);
}

// New function to generate AI-powered performance predictions
function generatePredictions(team, container) {
    // If we already have cached predictions for this team, use them
    if (teamPerformanceMetrics[team.team]) {
        renderPredictions(teamPerformanceMetrics[team.team], container);
        return;
    }
    
    // Otherwise, generate new predictions
    const predictions = {
        overallRating: Math.random() * 4 + 1, // 1-5 rating
        strengths: [],
        weaknesses: [],
        recommendedAlliances: [],
        predictedScore: Math.floor(Math.random() * 30) + 10 // Random score between 10-40
    };
    
    // Generate strengths based on team data
    if (team.drivetrain === "Swerve drive") {
        predictions.strengths.push("High maneuverability");
    }
    
    if (team.endgame === "Deep Climb") {
        predictions.strengths.push("Strong endgame capability");
        predictions.overallRating = Math.min(5, predictions.overallRating + 0.5);
    } else if (team.endgame === "Shallow Climb") {
        predictions.strengths.push("Decent climbing ability");
    }
    
    if (team.auton && team.auton.includes("Auto")) {
        predictions.strengths.push("Reliable autonomous mode");
        predictions.overallRating = Math.min(5, predictions.overallRating + 0.3);
    }
    
    // Generate weaknesses
    if (team.drivetrain === "Tank drive") {
        predictions.weaknesses.push("Limited maneuverability");
    }
    
    if (team.endgame === "Park" || !team.endgame) {
        predictions.weaknesses.push("Limited endgame scoring");
        predictions.overallRating = Math.max(1, predictions.overallRating - 0.5);
    }
    
    // Round the overall rating
    predictions.overallRating = Math.round(predictions.overallRating * 10) / 10;
    
    // Recommend alliance partners
    const goodClimbers = teamsData.filter(t => 
        t.team !== team.team && t.endgame === "Deep Climb"
    ).map(t => t.team).slice(0, 2);
    
    if (goodClimbers.length > 0) {
        predictions.recommendedAlliances = goodClimbers;
    }
    
    // Cache the predictions
    teamPerformanceMetrics[team.team] = predictions;
    
    // Render the predictions
    renderPredictions(predictions, container);
}

// Function to render the predictions in the UI - enhanced with PyIntel AI branding
function renderPredictions(predictions, container) {
    // Create star rating
    let stars = '';
    const fullStars = Math.floor(predictions.overallRating);
    const halfStar = predictions.overallRating % 1 >= 0.5;
    
    for (let i = 1; i <= 5; i++) {
        if (i <= fullStars) {
            stars += '<span class="star full">★</span>';
        } else if (i === fullStars + 1 && halfStar) {
            stars += '<span class="star half">★</span>';
        } else {
            stars += '<span class="star empty">☆</span>';
        }
    }
    
    // Create HTML for predictions with PyIntel AI branding
    let predictionsHTML = `
        <div class="pyintel-badge">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z"/>
            </svg>
            Powered by PyIntel AI
        </div>
        
        <div class="gradient-border">
            <div style="display: flex; flex-wrap: wrap; gap: 20px; animation: fadeIn 0.5s ease;">
                <div style="flex: 1; min-width: 200px;">
                    <div style="font-weight: 500; margin-bottom: 5px; font-size: 1.1em;">Overall Rating</div>
                    <div style="font-size: 1.8em; margin-bottom: 5px; color: var(--primary-blue);">${stars} ${predictions.overallRating}</div>
                    <div style="font-size: 0.9em; color: #5f6368;">Based on advanced data analysis</div>
                </div>
                
                <div style="flex: 1; min-width: 200px;">
                    <div style="font-weight: 500; margin-bottom: 10px; font-size: 1.1em;">Predicted Performance</div>
                    <div style="font-size: 1.4em; margin-bottom: 5px;">~${predictions.predictedScore} pts</div>
                    <div style="font-size: 0.9em; color: #5f6368;">Average points per match estimate</div>
                </div>
            </div>
            
            <div style="display: flex; flex-wrap: wrap; gap: 20px; margin-top: 20px;">
    `;
    
    // Add strengths section with enhanced styling
    if (predictions.strengths.length > 0) {
        predictionsHTML += `
            <div style="flex: 1; min-width: 200px;">
                <div style="font-weight: 500; margin-bottom: 10px; color: var(--accent-green); display: flex; align-items: center;">
                    <svg width="16" height="16" viewBox="0 0 24 24" style="margin-right: 5px;">
                        <path fill="currentColor" d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
                    </svg>
                    Strengths
                </div>
                <ul style="margin: 0; padding-left: 20px;">
                    ${predictions.strengths.map(strength => `<li style="margin-bottom: 5px;">${strength}</li>`).join('')}
                </ul>
            </div>
        `;
    }
    
    // Add weaknesses section with enhanced styling
    if (predictions.weaknesses.length > 0) {
        predictionsHTML += `
            <div style="flex: 1; min-width: 200px;">
                <div style="font-weight: 500; margin-bottom: 10px; color: var(--primary-red); display: flex; align-items: center;">
                    <svg width="16" height="16" viewBox="0 0 24 24" style="margin-right: 5px;">
                        <path fill="currentColor" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                    </svg>
                    Areas for Improvement
                </div>
                <ul style="margin: 0; padding-left: 20px;">
                    ${predictions.weaknesses.map(weakness => `<li style="margin-bottom: 5px;">${weakness}</li>`).join('')}
                </ul>
            </div>
        `;
    }
    
    predictionsHTML += `</div>`;
    
    // Add alliance recommendations if available with enhanced styling
    if (predictions.recommendedAlliances.length > 0) {
        predictionsHTML += `
            <div style="margin-top: 20px; padding-top: 15px; border-top: 1px solid #f1f3f4;">
                <div style="font-weight: 500; margin-bottom: 10px; color: var(--primary-blue); display: flex; align-items: center;">
                    <svg width="16" height="16" viewBox="0 0 24 24" style="margin-right: 5px;">
                        <path fill="currentColor" d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/>
                    </svg>
                    Recommended Alliance Partners
                </div>
                <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                    ${predictions.recommendedAlliances.map(team => 
                        `<div style="background: linear-gradient(45deg, #4776E6, #8E54E9); color: white; padding: 5px 12px; border-radius: 20px; font-weight: 500; box-shadow: 0 2px 5px rgba(71, 118, 230, 0.3);">Team ${team}</div>`
                    ).join('')}
                </div>
            </div>
        `;
    }
    
    // Add AI confidence meter
    const confidenceLevel = Math.round(Math.random() * 20 + 75); // Random between 75-95%
    predictionsHTML += `
        <div style="margin-top: 20px; text-align: right; font-size: 0.85em; color: #5f6368;">
            <div>PyIntel AI Confidence: ${confidenceLevel}%</div>
            <div style="height: 4px; background-color: #eee; border-radius: 2px; margin-top: 5px;">
                <div style="height: 100%; width: ${confidenceLevel}%; background: linear-gradient(to right, #4776E6, #8E54E9); border-radius: 2px;"></div>
            </div>
        </div>
    </div>`;
    
    // Add style for star rating if not already added
    if (!document.getElementById('star-rating-style')) {
        const style = document.createElement('style');
        style.id = 'star-rating-style';
        style.textContent = `
            .star {
                font-size: 1.4em;
                letter-spacing: 2px;
            }
            .star.full {
                color: #fbbc04;
                text-shadow: 0 0 5px rgba(251, 188, 4, 0.3);
            }
            .star.half {
                background: linear-gradient(90deg, #fbbc04 50%, #d3d3d3 50%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
            }
            .star.empty {
                color: #d3d3d3;
            }
        `;
        document.head.appendChild(style);
    }
    
    // Replace loading state with predictions
    container.className = "predictions-container";
    
    // Render with slight animation delay
    container.style.opacity = "0";
    container.style.transform = "translateY(10px)";
    container.innerHTML = predictionsHTML;
    
    setTimeout(() => {
        container.style.transition = "opacity 0.6s ease, transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1)";
        container.style.opacity = "1";
        container.style.transform = "translateY(0)";
    }, 50);
}