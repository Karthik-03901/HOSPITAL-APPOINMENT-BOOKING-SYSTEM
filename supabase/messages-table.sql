-- =====================================================
-- MESSAGES TABLE FOR CHAT FUNCTIONALITY
-- Real-time messaging system
-- =====================================================

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  sender TEXT NOT NULL CHECK (sender IN ('user', 'admin', 'bot')),
  user_id UUID,
  user_email TEXT,
  user_name TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_user ON messages(user_id);
CREATE INDEX idx_messages_unread ON messages(read) WHERE read = FALSE;

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Allow all operations (simplified for demo)
DROP POLICY IF EXISTS "messages_all" ON messages;
CREATE POLICY "messages_all" ON messages 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Create notification for new admin messages
CREATE OR REPLACE FUNCTION notify_new_admin_message()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.sender = 'admin' THEN
    -- Could trigger external notification here
    PERFORM pg_notify('new_admin_message', NEW.id::TEXT);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_admin_message ON messages;
CREATE TRIGGER trigger_notify_admin_message
  AFTER INSERT ON messages
  FOR EACH ROW
  WHEN (NEW.sender = 'admin')
  EXECUTE FUNCTION notify_new_admin_message();

-- Test insertion
INSERT INTO messages (content, sender, user_name) 
VALUES ('Welcome to MediQueue! How can we help you today?', 'bot', 'System');

SELECT 'Messages table created successfully!' as status;
