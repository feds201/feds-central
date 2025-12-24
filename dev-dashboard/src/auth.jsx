import React, { createContext, useContext, useEffect, useState } from 'react';
import { api } from '@/lib/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const session = api.getSession();
        if (session) {
            setUser(session.user);
        }
        setLoading(false);
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
    }
};

export const useAuth = () => useContext(AuthContext);
