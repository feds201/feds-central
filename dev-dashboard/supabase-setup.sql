-- FEDS Dev Console - Supabase Database Schema Setup
-- Run this SQL in your Supabase project's SQL Editor

-- ============================================
-- Create Tables
-- ============================================

-- 1. Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

-- 2. Authenticator Table (Main account TOTP)
CREATE TABLE IF NOT EXISTS public.authenticator (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  totp_secret text NOT NULL,
  totp_period int DEFAULT 30,
  recovery_codes text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 3. Authenticator Entries Table (Service-specific TOTP)
CREATE TABLE IF NOT EXISTS public.authenticator_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  service_name text NOT NULL,
  totp_secret text NOT NULL,
  totp_period int DEFAULT 30,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 4. Services Table
CREATE TABLE IF NOT EXISTS public.services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  url text,
  description text,
  tags text[],
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 5. Credentials Table
CREATE TABLE IF NOT EXISTS public.credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  username text NOT NULL,
  password_encrypted text NOT NULL,
  notes text,
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- Enable Row Level Security (RLS)
-- ============================================

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE authenticator ENABLE ROW LEVEL SECURITY;
ALTER TABLE authenticator_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE credentials ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Create Indexes for Performance
-- ============================================

CREATE INDEX IF NOT EXISTS audit_logs_user_id_created_at 
  ON audit_logs(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS services_owner_id 
  ON services(owner_id);

CREATE INDEX IF NOT EXISTS credentials_service_id 
  ON credentials(service_id);

CREATE INDEX IF NOT EXISTS credentials_owner_id 
  ON credentials(owner_id);

CREATE INDEX IF NOT EXISTS authenticator_entries_user_id 
  ON authenticator_entries(user_id);

-- ============================================
-- RLS Policies for audit_logs
-- ============================================

DROP POLICY IF EXISTS "Users can view their own audit logs" ON audit_logs;
CREATE POLICY "Users can view their own audit logs" 
  ON audit_logs FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert audit logs" ON audit_logs;
CREATE POLICY "System can insert audit logs" 
  ON audit_logs FOR INSERT 
  WITH CHECK (true);

-- ============================================
-- RLS Policies for authenticator
-- ============================================

DROP POLICY IF EXISTS "Users can view their own authenticator" ON authenticator;
CREATE POLICY "Users can view their own authenticator" 
  ON authenticator FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own authenticator" ON authenticator;
CREATE POLICY "Users can manage their own authenticator" 
  ON authenticator FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- RLS Policies for authenticator_entries
-- ============================================

DROP POLICY IF EXISTS "Users can view their own entries" ON authenticator_entries;
CREATE POLICY "Users can view their own entries" 
  ON authenticator_entries FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own entries" ON authenticator_entries;
CREATE POLICY "Users can manage their own entries" 
  ON authenticator_entries FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- RLS Policies for services
-- ============================================

DROP POLICY IF EXISTS "Users can view their own services" ON services;
CREATE POLICY "Users can view their own services" 
  ON services FOR SELECT 
  USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Users can manage their own services" ON services;
CREATE POLICY "Users can manage their own services" 
  ON services FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = owner_id);

-- ============================================
-- RLS Policies for credentials
-- ============================================

DROP POLICY IF EXISTS "Users can view their own credentials" ON credentials;
CREATE POLICY "Users can view their own credentials" 
  ON credentials FOR SELECT 
  USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Users can manage their own credentials" ON credentials;
CREATE POLICY "Users can manage their own credentials" 
  ON credentials FOR INSERT, UPDATE, DELETE 
  USING (auth.uid() = owner_id);
