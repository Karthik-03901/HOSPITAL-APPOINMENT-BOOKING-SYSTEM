/**
 * TOTP Backend API Server
 * Handles Two-Factor Authentication operations using otplib and qrcode
 * Runs on port 3001
 */

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { TOTP } = require('otplib');
const QRCode = require('qrcode');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Supabase client (for database operations)
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://cgohfhvokszbolsafpxu.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnb2hmaHZva3N6Ym9sc2FmcHh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1OTU1MTYsImV4cCI6MjA5OTE3MTUxNn0.8eVNb7lpBYSv29yzUc_8mXNj9KiFBT4gdcWBdOrRIKI';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Create TOTP instance
const totp = new TOTP({
  step: 30,        // 30-second time window
  window: [1, 1],  // ±1 time step tolerance (90 seconds)
  digits: 6        // 6-digit codes
});

// ==========================================
// API ENDPOINTS
// ==========================================

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'TOTP server is running' });
});

/**
 * Generate new TOTP secret and QR code
 * POST /api/totp/generate
 * Body: { email: string, userId: string }
 */
app.post('/api/totp/generate', async (req, res) => {
  try {
    const { email, userId } = req.body;
    
    if (!email || !userId) {
      return res.status(400).json({ error: 'Email and userId are required' });
    }
    
    // Generate secret
    const secret = totp.generateSecret();
    
    // Create otpauth URL
    const otpauthUrl = totp.keyuri(email, 'MediQueue', secret);
    
    // Generate QR code as data URL
    const qrCodeDataUrl = await QRCode.toDataURL(otpauthUrl);
    
    res.json({
      secret,
      qrCode: qrCodeDataUrl,
      otpauthUrl,
      manual: secret // For manual entry
    });
    
  } catch (error) {
    console.error('Error generating TOTP:', error);
    res.status(500).json({ error: 'Failed to generate TOTP' });
  }
});

/**
 * Verify TOTP token
 * POST /api/totp/verify
 * Body: { secret: string, token: string }
 */
app.post('/api/totp/verify', async (req, res) => {
  try {
    const { secret, token } = req.body;
    
    if (!secret || !token) {
      return res.status(400).json({ error: 'Secret and token are required' });
    }
    
    // Verify the token
    const isValid = totp.verify({ secret, token });
    
    res.json({ valid: isValid });
    
  } catch (error) {
    console.error('Error verifying TOTP:', error);
    res.status(500).json({ error: 'Failed to verify TOTP' });
  }
});

/**
 * Generate backup codes
 * POST /api/totp/backup-codes
 * Body: { userId: string }
 */
app.post('/api/totp/backup-codes', async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'UserId is required' });
    }
    
    // Generate 10 backup codes (8 characters each)
    const backupCodes = [];
    for (let i = 0; i < 10; i++) {
      const code = generateBackupCode();
      backupCodes.push(code);
    }
    
    res.json({ backupCodes });
    
  } catch (error) {
    console.error('Error generating backup codes:', error);
    res.status(500).json({ error: 'Failed to generate backup codes' });
  }
});

/**
 * Verify backup code
 * POST /api/totp/verify-backup
 * Body: { userId: string, code: string }
 */
app.post('/api/totp/verify-backup', async (req, res) => {
  try {
    const { userId, code } = req.body;
    
    if (!userId || !code) {
      return res.status(400).json({ error: 'UserId and code are required' });
    }
    
    // Get user's backup codes from database
    const { data: settings, error } = await supabase
      .from('user_2fa_settings')
      .select('backup_codes')
      .eq('user_id', userId)
      .eq('totp_enabled', true)
      .single();
    
    if (error || !settings) {
      return res.status(404).json({ error: 'No TOTP settings found' });
    }
    
    const backupCodes = settings.backup_codes || [];
    
    // Check if code exists and is unused
    const codeIndex = backupCodes.findIndex(bc => 
      bc.code === code && !bc.used_at
    );
    
    if (codeIndex === -1) {
      return res.json({ valid: false });
    }
    
    // Mark code as used
    backupCodes[codeIndex].used_at = new Date().toISOString();
    
    // Update database
    const { error: updateError } = await supabase
      .from('user_2fa_settings')
      .update({ backup_codes: backupCodes })
      .eq('user_id', userId);
    
    if (updateError) {
      throw updateError;
    }
    
    res.json({ valid: true });
    
  } catch (error) {
    console.error('Error verifying backup code:', error);
    res.status(500).json({ error: 'Failed to verify backup code' });
  }
});

/**
 * Check TOTP status for user
 * GET /api/totp/status/:userId
 */
app.get('/api/totp/status/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({ error: 'UserId is required' });
    }
    
    // Call Supabase function
    const { data, error } = await supabase.rpc('check_totp_reauth_required', {
      p_user_id: userId
    });
    
    if (error) {
      throw error;
    }
    
    res.json(data);
    
  } catch (error) {
    console.error('Error checking TOTP status:', error);
    res.status(500).json({ error: 'Failed to check TOTP status' });
  }
});

/**
 * Save TOTP settings
 * POST /api/totp/save
 * Body: { userId: string, secret: string, backupCodes: array }
 */
app.post('/api/totp/save', async (req, res) => {
  try {
    const { userId, secret, backupCodes } = req.body;
    
    if (!userId || !secret || !backupCodes) {
      return res.status(400).json({ error: 'UserId, secret, and backupCodes are required' });
    }
    
    // Format backup codes for database
    const formattedCodes = backupCodes.map(code => ({
      code,
      used_at: null
    }));
    
    // Encrypt secret (in production, use proper encryption)
    const encryptedSecret = Buffer.from(secret).toString('base64');
    
    // Insert or update TOTP settings
    const { error } = await supabase
      .from('user_2fa_settings')
      .upsert({
        user_id: userId,
        totp_enabled: true,
        totp_secret: encryptedSecret,
        backup_codes: formattedCodes,
        last_used_at: new Date().toISOString()
      });
    
    if (error) {
      throw error;
    }
    
    res.json({ success: true });
    
  } catch (error) {
    console.error('Error saving TOTP settings:', error);
    res.status(500).json({ error: 'Failed to save TOTP settings' });
  }
});

/**
 * Update last used timestamp
 * POST /api/totp/update-last-used
 * Body: { userId: string }
 */
app.post('/api/totp/update-last-used', async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'UserId is required' });
    }
    
    // Call Supabase function
    const { data, error } = await supabase.rpc('update_totp_last_used', {
      p_user_id: userId
    });
    
    if (error) {
      throw error;
    }
    
    res.json({ success: true });
    
  } catch (error) {
    console.error('Error updating last used:', error);
    res.status(500).json({ error: 'Failed to update last used timestamp' });
  }
});

// ==========================================
// HELPER FUNCTIONS
// ==========================================

/**
 * Generate a secure backup code
 */
function generateBackupCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous characters
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// ==========================================
// START SERVER
// ==========================================

app.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════╗
║   TOTP Backend API Server                ║
║   Running on http://localhost:${PORT}     ║
║   Status: ✅ Ready                        ║
╚══════════════════════════════════════════╝

Available Endpoints:
  GET  /health
  POST /api/totp/generate
  POST /api/totp/verify
  POST /api/totp/backup-codes
  POST /api/totp/verify-backup
  GET  /api/totp/status/:userId
  POST /api/totp/save
  POST /api/totp/update-last-used
  `);
});
