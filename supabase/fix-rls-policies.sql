-- Fix RLS Policies for Testing
-- This allows unauthenticated access for testing
-- Run this in Supabase SQL Editor

-- =====================================================
-- Temporary: Allow Public Access for Testing
-- =====================================================

-- Drop restrictive policies
DROP POLICY IF EXISTS "queue_positions_select_own" ON queue_positions;
DROP POLICY IF EXISTS "queue_positions_select_doctor" ON queue_positions;
DROP POLICY IF EXISTS "appointments_select_own" ON appointments;
DROP POLICY IF EXISTS "appointments_select_doctor" ON appointments;
DROP POLICY IF EXISTS "appointments_update_own" ON appointments;

-- Create permissive policies for testing
-- Anyone can view queue positions
CREATE POLICY "queue_positions_public_select" ON queue_positions
  FOR SELECT
  USING (true);

-- Anyone can view appointments
CREATE POLICY "appointments_public_select" ON appointments
  FOR SELECT
  USING (true);

-- Anyone can update appointments (for check-in)
CREATE POLICY "appointments_public_update" ON appointments
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Anyone can insert appointments (for booking)
CREATE POLICY "appointments_public_insert" ON appointments
  FOR INSERT
  WITH CHECK (true);

-- Anyone can insert queue positions
CREATE POLICY "queue_positions_public_insert" ON queue_positions
  FOR INSERT
  WITH CHECK (true);

-- Anyone can update queue positions
CREATE POLICY "queue_positions_public_update" ON queue_positions
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE '✅ RLS policies updated for testing!';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  WARNING: These policies allow public access';
  RAISE NOTICE '   Only use for development/testing';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Refresh your browser';
  RAISE NOTICE '2. Try booking again';
  RAISE NOTICE '3. Check queue status page';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
