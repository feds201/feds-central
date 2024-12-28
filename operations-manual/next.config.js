// Use dynamic import for ES module
async function loadNextra() {
    const nextra = await import('nextra');
    return nextra.default({
        theme: 'nextra-theme-docs',
        themeConfig: './theme.config.jsx'
    });
}

const withNextra = await loadNextra();

module.exports = withNextra;