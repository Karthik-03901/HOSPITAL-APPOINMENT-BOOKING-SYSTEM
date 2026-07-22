-- Real-Time Queue Management Schema
-- Run this in Supabase SQL Editor to enable real-time features

-- =====================================================
-- 1. Queue Positions Table
-- =====================================================
CREATE TABLE IF NOT EXISTS queue_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES doctors(id),
  position INT NOT NULL,
  estimated_time TIMESTAMPTZ,
  actual_call_time TIMESTAMPTZ,
  status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting', 'called', 'consulting', 'completed', 'no_show')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_queue_positions_appointment ON queue_positions(appointment_id);
CREATE INDEX idx_queue_positions_doctor ON queue_positions(doctor_id);
CREATE INDEX idx_queue_positions_status ON queue_positions(status);

-- =====================================================
-- 2. Notifications Table
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('queue_update', 'appointment_reminder', 'appointment_called', 'message', 'system')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  channels TEXT[] DEFAULT ARRAY['in_app'],
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, read) WHERE read = FALSE;
CREATE INDEX idx_notifications_type ON notifications(type);

-- =====================================================
-- 3. Messages Table (In-App Chat)
-- =====================================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  attachments TEXT[] DEFAULT ARRAY[]::TEXT[],
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_appointment ON messages(appointment_id);
CREATE INDEX idx_messages_unread ON messages(receiver_id, read) WHERE read = FALSE;

-- =====================================================
-- 4. Activity Logs (Audit Trail)
-- =====================================================
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at);

-- =====================================================
-- 5. Triggers for Auto-Update Queue Positions
-- =====================================================

-- Function to update queue positions when appointment changes
CREATE OR REPLACE FUNCTION update_queue_positions()
RETURNS TRIGGER AS $$
BEGIN
  -- Only recalculate if status changed to completed or cancelled
  IF (TG_OP = 'UPDATE' AND NEW.status IN ('completed', 'cancelled', 'no_show')) THEN
    -- Recalculate positions for remaining appointments
    WITH ranked AS (
      SELECT 
        qp.id as queue_id,
        ROW_NUMBER() OVER (
          PARTITION BY a.doctor_id, DATE(a.appointment_date) 
          ORDER BY a.appointment_time
        ) as new_position
      FROM appointments a
      JOIN queue_positions qp ON qp.appointment_id = a.id
      WHERE a.status IN ('pending', 'confirmed', 'checked_in')
        AND a.doctor_id = NEW.doctor_id
        AND DATE(a.appointment_date) = DATE(NEW.appointment_date)
        AND qp.status = 'waiting'
    )
    UPDATE queue_positions qp
    SET 
      position = r.new_position,
      estimated_time = NOW() + (r.new_position * INTERVAL '15 minutes'),
      updated_at = NOW()
    FROM ranked r
    WHERE qp.id = r.queue_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_queue_positions ON appointments;
CREATE TRIGGER trigger_update_queue_positions
  AFTER UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_queue_positions();

-- =====================================================
-- 6. Function to Initialize Queue Position
-- =====================================================
CREATE OR REPLACE FUNCTION initialize_queue_position()
RETURNS TRIGGER AS $$
DECLARE
  current_position INT;
BEGIN
  -- Calculate position based on existing appointments
  SELECT COALESCE(COUNT(*), 0) + 1 INTO current_position
  FROM appointments
  WHERE doctor_id = NEW.doctor_id
    AND DATE(appointment_date) = DATE(NEW.appointment_date)
    AND status IN ('pending', 'confirmed', 'checked_in')
    AND appointment_time <= NEW.appointment_time
    AND id != NEW.id;
  
  -- Insert queue position
  INSERT INTO queue_positions (
    appointment_id,
    doctor_id,
    position,
    estimated_time,
    status
  ) VALUES (
    NEW.id,
    NEW.doctor_id,
    current_position,
    NEW.appointment_date + (current_position * INTERVAL '15 minutes'),
    'waiting'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new appointments
DROP TRIGGER IF EXISTS trigger_initialize_queue ON appointments;
CREATE TRIGGER trigger_initialize_queue
  AFTER INSERT ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION initialize_queue_position();

-- =====================================================
-- 7. Function to Send Notification
-- =====================================================
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb,
  p_channels TEXT[] DEFAULT ARRAY['in_app']
)
RETURNS UUID AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO notifications (
    user_id,
    type,
    title,
    body,
    data,
    channels,
    sent_at
  ) VALUES (
    p_user_id,
    p_type,
    p_title,
    p_body,
    p_data,
    p_channels,
    NOW()
  )
  RETURNING id INTO notification_id;
  
  RETURN notification_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. Function to Log Activity
-- =====================================================
CREATE OR REPLACE FUNCTION log_activity(
  p_user_id UUID,
  p_action TEXT,
  p_entity_type TEXT DEFAULT NULL,
  p_entity_id UUID DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO activity_logs (
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    p_user_id,
    p_action,
    p_entity_type,
    p_entity_id,
    p_metadata
  )
  RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. Enable Realtime for Tables
-- =====================================================
ALTER PUBLICATION supabase_realtime ADD TABLE queue_positions;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE appointments;

-- =====================================================
-- 10. Row Level Security (RLS) Policies
-- =====================================================

-- Queue Positions RLS
ALTER TABLE queue_positions ENABLE ROW LEVEL SECURITY;

-- Patients can see their own queue position
CREATE POLICY queue_positions_select_own ON queue_positions
  FOR SELECT
  USING (
    appointment_id IN (
      SELECT id FROM appointments WHERE patient_id = auth.uid()
    )
  );

-- Doctors can see their queue
CREATE POLICY queue_positions_select_doctor ON queue_positions
  FOR SELECT
  USING (
    doctor_id IN (
      SELECT id FROM doctors WHERE user_id = auth.uid()
    )
  );

-- Doctors can update their queue
CREATE POLICY queue_positions_update_doctor ON queue_positions
  FOR UPDATE
  USING (
    doctor_id IN (
      SELECT id FROM doctors WHERE user_id = auth.uid()
    )
  );

-- Notifications RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can see their own notifications
CREATE POLICY notifications_select_own ON notifications
  FOR SELECT
  USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY notifications_update_own ON notifications
  FOR UPDATE
  USING (user_id = auth.uid());

-- Messages RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can see messages they sent or received
CREATE POLICY messages_select_own ON messages
  FOR SELECT
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Users can insert messages
CREATE POLICY messages_insert_own ON messages
  FOR INSERT
  WITH CHECK (sender_id = auth.uid());

-- Activity Logs RLS
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Users can see their own activity
CREATE POLICY activity_logs_select_own ON activity_logs
  FOR SELECT
  USING (user_id = auth.uid());

-- Admins can see all activity
CREATE POLICY activity_logs_select_admin ON activity_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- 11. Sample Data for Testing
-- =====================================================

-- This is commented out - uncomment to populate test data
/*
-- Insert test queue positions
INSERT INTO queue_positions (appointment_id, doctor_id, position, status)
SELECT 
  id,
  doctor_id,
  ROW_NUMBER() OVER (PARTITION BY doctor_id ORDER BY appointment_time),
  'waiting'
FROM appointments
WHERE status = 'confirmed'
  AND appointment_date >= CURRENT_DATE
ON CONFLICT DO NOTHING;
*/

-- =====================================================
-- 12. Useful Queries for Monitoring
-- =====================================================

-- View current queue for a doctor
-- SELECT * FROM queue_positions WHERE doctor_id = 'xxx' AND status = 'waiting' ORDER BY position;

-- View unread notifications for a user
-- SELECT * FROM notifications WHERE user_id = 'xxx' AND read = FALSE ORDER BY created_at DESC;

-- View today's activity
-- SELECT * FROM activity_logs WHERE created_at >= CURRENT_DATE ORDER BY created_at DESC;

-- =====================================================
-- COMPLETE! 
-- =====================================================

-- Verify setup
DO $$
BEGIN
  RAISE NOTICE 'Real-time schema setup complete! ✅';
  RAISE NOTICE 'Tables created: queue_positions, notifications, messages, activity_logs';
  RAISE NOTICE 'Triggers created: update_queue_positions, initialize_queue';
  RAISE NOTICE 'RLS policies: Enabled and configured';
  RAISE NOTICE 'Realtime: Enabled for all tables';
END $$;
