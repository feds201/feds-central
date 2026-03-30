-- Migration: Create Custom App Users Table & Update Passkey Schema
-- =================================================================

-- 1. Create app_users table
CREATE TABLE IF NOT EXISTS public.app_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Modify passkey table to reference app_users (if needed) or create it if missing
-- We want to ensure 'user_id' can store our UUIDs. 
-- If the table exists from previous step, user_id is TEXT, which is fine for UUIDs.

CREATE TABLE IF NOT EXISTS public.passkey (
    id TEXT PRIMARY KEY,
    name TEXT,
    public_key TEXT NOT NULL,
    user_id TEXT NOT NULL, -- Storing UUID as TEXT to be safe/simple
    credential_id TEXT NOT NULL,
    counter INTEGER NOT NULL DEFAULT 0,
    device_type TEXT NOT NULL,
    backed_up BOOLEAN NOT NULL DEFAULT false,
    transports TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for querying passkeys by user
CREATE INDEX IF NOT EXISTS idx_passkey_user_id ON public.passkey(user_id);
-- Index for querying app_users by email
CREATE INDEX IF NOT EXISTS idx_app_users_email ON public.app_users(email);
