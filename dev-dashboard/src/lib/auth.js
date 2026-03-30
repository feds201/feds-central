
// Basic Auth Helper for Neon (Mock/Local Storage for now)
// Note: Replace this with actual Better Auth SDK integration when config is available.

const STORAGE_KEY = 'feds_session';

const getCurrentUser = async () => {
    const json = localStorage.getItem(STORAGE_KEY);
    if (json) {
        return JSON.parse(json);
    }
    return null;
};

const signIn = async (providerOrEmail, password) => {
    // Simulate successful login
    const user = {
        id: 'user_12345',
        email: 'demo@feds.com',
        full_name: 'Demo User'
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
    window.location.reload(); // Simple reload to refresh app state
    return { user, error: null };
};

const signOut = async () => {
    localStorage.removeItem(STORAGE_KEY);
    window.location.href = '/';
};

export const auth = {
    getUser: getCurrentUser,
    signIn,
    signOut
};
