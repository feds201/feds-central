// Function to create the navigation bar
function createNavBar() {
    const navBar = document.createElement('nav');

    // Create the icon
    const icon = document.createElement('img');
    icon.src = '../../assets/logo.bmp'; // Replace with the actual path to your icon
    icon.alt = 'ScoutOps Icon';

    // Create the title
    const title = document.createElement('div');
    title.textContent = 'SCOUT-OPS';
    title.className = 'title';

    // Create the navigation links
    const navLinks = document.createElement('div');
    navLinks.className = 'links';
    const pages = [
        { name: 'Home', href: '../home/home.html' },
        { name: 'Servers Heath', href: '../../pages/serversHeath/serverZHeath.html' },
        { name: 'Settings', href: '../settings/settings.html' }
    ];
    pages.forEach(page => {
        const link = document.createElement('a');
        link.href = page.href;
        link.textContent = page.name;
        navLinks.appendChild(link);
    });

    // Append the title, icon, and links to the nav bar
    navBar.appendChild(icon);
    navBar.appendChild(title);
    navBar.appendChild(navLinks);

    // Append the nav bar to the body
    document.body.appendChild(navBar);
}

// Call the function to create and display the nav bar
createNavBar();