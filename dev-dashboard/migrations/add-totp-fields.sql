-- Migration: Add additional TOTP fields to authenticator_entries
-- Run this in your Neon Console SQL Editor

ALTER TABLE public.authenticator_entries 
ADD COLUMN IF NOT EXISTS digits INT DEFAULT 6,
ADD COLUMN IF NOT EXISTS issuer TEXT,
ADD COLUMN IF NOT EXISTS account_name TEXT;

-- Update existing rows to have default values
UPDATE public.authenticator_entries 
SET digits = 6 
WHERE digits IS NULL;
