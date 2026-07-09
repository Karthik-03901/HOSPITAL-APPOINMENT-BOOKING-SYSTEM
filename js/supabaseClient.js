// ============================================================
// SUPABASE CLIENT — single shared instance
// Replace the placeholders below with your actual project values.
// Find them in: Supabase Dashboard > Project Settings > API
// ============================================================

const SUPABASE_URL = "https://cwedqtowujshvaysrshq.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3ZWRxdG93dWpzaHZheXNyc2hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1ODUzMjEsImV4cCI6MjA5OTE2MTMyMX0.xkDr_bUh-c67G7ebieXfUC8SEPwy3jDTkGsg9Hs8pFg";

// supabase-js is loaded globally via the CDN script tag in each HTML page
const { createClient } = supabase;

const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});

// Guard used on protected pages (dashboard etc.)
async function requireSession(redirectTo = "login.html") {
  const {
    data: { session },
  } = await db.auth.getSession();
  if (!session) {
    window.location.href = redirectTo;
    return null;
  }
  return session;
}
