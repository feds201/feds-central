-- =============================================
-- BETTER AUTH PASSKEY SCHEMA & QUERIES
-- =============================================
-- This script ensures the necessary table for WebAuthn/Passkeys 
-- exists in your Neon database and provides utility queries.
-- =============================================

-- 1. Create the passkey table (Better Auth Standard Schema)
-- Run this if you are seeing "Failed to fetch passkeys" errors.
CREATE TABLE IF NOT EXISTS public.passkey (
    id TEXT PRIMARY KEY,
    name TEXT,
    public_key TEXT NOT NULL,
    user_id TEXT NOT NULL, -- References your "app_users" table id
    credential_id TEXT NOT NULL,
    counter INTEGER NOT NULL DEFAULT 0,
    device_type TEXT NOT NULL,
    backed_up BOOLEAN NOT NULL DEFAULT false,
    transports TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Add Index for performance
CREATE INDEX IF NOT EXISTS idx_passkey_user_id ON public.passkey(user_id);

-- 3. Ensure current_challenge column exists in app_users
ALTER TABLE public.app_users ADD COLUMN IF NOT EXISTS current_challenge TEXT;

-- 3. Utility Query: List all passkeys with associated user email
-- (Assumes the Better Auth "app_users" table exists)
/*
SELECT 
    pk.name as passkey_name,
    pk.device_type,
    pk.created_at,
    u.email as user_email
FROM 
    public.passkey pk
JOIN 
    public.app_users u ON pk.user_id = u.id
ORDER BY 
    pk.created_at DESC;
*/

-- 4. Utility Query: Find passkeys for a specific email
/*
SELECT * FROM public.passkey 
WHERE user_id = (SELECT id FROM public.app_users WHERE email = 'your-email@example.com');
*/

-- 5. Audit Log for schema update
-- INSERT INTO audit_logs (user_id, action, details) 
-- VALUES ('system', 'schema_update', '{"table": "passkey", "description": "Added passkey support table"}');
