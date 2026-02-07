-- Migration: Add file vault table for encrypted file storage
-- Run this in your Neon Console SQL Editor

CREATE TABLE IF NOT EXISTS public.vault_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,  -- References Neon Auth user.id (string)
  filename TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  encrypted_data TEXT NOT NULL,  -- Base64 encoded encrypted file data
  encryption_iv TEXT NOT NULL,   -- Initialization vector for decryption
  tags TEXT[],
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for user queries
CREATE INDEX IF NOT EXISTS idx_vault_files_user ON public.vault_files(user_id);
CREATE INDEX IF NOT EXISTS idx_vault_files_created ON public.vault_files(created_at DESC);
