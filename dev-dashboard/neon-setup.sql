-- =============================================
-- NEON AUTH + FEDS DEV CONSOLE DATABASE SCHEMA
-- =============================================
-- Run this in your Neon Console SQL Editor
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- FEDS APP TABLES (your custom tables)
-- =============================================

-- Services table
CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  url TEXT,
  description TEXT,
  tags TEXT[],
  owner_id TEXT NOT NULL,  -- References Neon Auth user.id (string)
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Credentials table
CREATE TABLE IF NOT EXISTS public.credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID REFERENCES public.services(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  password_encrypted TEXT NOT NULL,
  notes TEXT,
  owner_id TEXT NOT NULL,  -- References Neon Auth user.id (string)
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Authenticator entries table (TOTP codes for external services)
CREATE TABLE IF NOT EXISTS public.authenticator_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,  -- References Neon Auth user.id (string)
  service_name TEXT NOT NULL,
  totp_secret TEXT NOT NULL,
  totp_period INT DEFAULT 30,
  digits INT DEFAULT 6,
  issuer TEXT,
  account_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Main authenticator table (user's own TOTP setup)
CREATE TABLE IF NOT EXISTS public.authenticator (
  user_id TEXT PRIMARY KEY,  -- References Neon Auth user.id (string)
  totp_secret TEXT NOT NULL,
  totp_period INT DEFAULT 30,
  recovery_codes TEXT[],
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,  -- References Neon Auth user.id (string)
  action TEXT NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- INDEXES for performance
-- =============================================

CREATE INDEX IF NOT EXISTS idx_services_owner ON public.services(owner_id);
CREATE INDEX IF NOT EXISTS idx_credentials_owner ON public.credentials(owner_id);
CREATE INDEX IF NOT EXISTS idx_credentials_service ON public.credentials(service_id);
CREATE INDEX IF NOT EXISTS idx_authenticator_entries_user ON public.authenticator_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at DESC);

-- =============================================
-- NOTES
-- =============================================
-- 
-- Neon Auth (Better Auth) manages its own tables automatically:
--   - user
--   - session
--   - account
--   - verification
-- 
-- Your app tables reference user.id as TEXT (not UUID) because
-- Better Auth uses string IDs.
--
-- Row Level Security (RLS) is NOT enabled by default.
-- For production, consider enabling RLS with policies that check
-- the authenticated user against owner_id/user_id columns.
-- =============================================
