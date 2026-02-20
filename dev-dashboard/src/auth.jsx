import React, { createContext, useContext, useEffect, useState } from 'react';
import { api } from '@/lib/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Skip auth in dev mode
        if (!import.meta.env.PROD) {
            setUser({ id: 'dev', email: 'dev@feds201.com' });
            setLoading(false);
            return;
        }

        const session = api.getSession();
        if (!session) {
            setLoading(false);
            return;
        }

        // Validate the session by refreshing the access token.
        // If this fails, the stored session is dead — log out.
        fetch('/api/auth/refresh', { method: 'POST', credentials: 'include' })
            .then(async (res) => {
                if (res.ok) {
                    const data = await res.json();
                    if (data.token) {
                        localStorage.setItem('token', data.token);
                    }
                    setUser(session.user);
                } else {
                    api.signOut();
                }
            })
            .catch(() => {
                api.signOut();
            })
            .finally(() => {
                setLoading(false);
            });
    }, []);

    const login = async (email, password) => {
        const data = await api.signIn(email, password);
        setUser(data.user);
        return data;
    };

    const signup = async (email, password, name) => {
        const data = await api.signUp(email, password, name);
        setUser(data.user);
        return data;
    };

    const logout = () => {
        api.signOut();
        setUser(null);
    };

    const signInPasskey = async (email) => {
        const data = await api.signInPasskey(email);
        setUser(data.user);
        return data;
    }

    return (
        <AuthContext.Provider value={{ user, loading, login, signup, logout, signInPasskey }}>
            {children}
        </AuthContext.Provider>
    );
}

// Compat layer for existing code expecting authClient
export const authClient = {
    useSession: () => {
        const ctx = useContext(AuthContext);
        if (!ctx) {
            throw new Error("useSession must be used within AuthProvider");
        }
        return {
            data: ctx.user ? { user: ctx.user } : null,
            isPending: ctx.loading,
            isAuthenticated: !!ctx.user
        };
    },
    signOut: async () => {
        return api.signOut();
    }
};

export const useAuth = () => useContext(AuthContext);
