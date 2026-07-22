import { supabase } from "./supabaseClient.js";

/**
 * Signs up a new user and creates their profile row.
 * @param {{email: string, password: string, fullName: string, role: "patient"|"doctor"|"admin", phone?: string}} params
 */
export async function signUp({ email, password, fullName, role, phone }) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
        role: role,
        phone: phone ?? null
      }
    }
  });
  if (error) throw error;
  return data;
}

/**
 * Signs in an existing user with email/password.
 * Supports demo credentials and Supabase auth.
 */
export async function signIn({ email, password }) {
  // Demo users for testing (remove in production)
  const DEMO_USERS = {
    'karthiksaravanavel18@gmail.com': { password: 'admin123', role: 'admin', name: 'Admin User', id: 'admin-demo-id' },
    'idselect@gmail.com': { password: 'doctor123', role: 'doctor', name: 'Dr. Smith', id: 'doctor-demo-id' },
    'patient@mediqueue.com': { password: 'patient123', role: 'patient', name: 'John Doe', id: 'patient-demo-id' }
  };
  
  // Try demo credentials first
  if (DEMO_USERS[email]) {
    const demoUser = DEMO_USERS[email];
    if (demoUser.password === password) {
      // Create a mock session for demo user
      const mockSession = {
        user: {
          id: demoUser.id,
          email: email,
          user_metadata: {
            full_name: demoUser.name
          }
        }
      };
      
      // Store demo session
      localStorage.setItem('mediqueue_demo_session', JSON.stringify({
        email: email,
        role: demoUser.role,
        name: demoUser.name,
        id: demoUser.id,
        isDemo: true
      }));
      
      return { data: mockSession, error: null };
    }
  }
  
  // Try Supabase authentication
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return { data, error: null };
}

export async function signOut() {
  // Clear demo session
  localStorage.removeItem('mediqueue_demo_session');
  
  // Sign out from Supabase
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/**
 * Returns the current session's profile (role, name, etc.) or null.
 */
export async function getCurrentProfile() {
  // Check for demo session first (from auth.js - old method)
  const demoSession = localStorage.getItem('mediqueue_demo_session');
  if (demoSession) {
    const demo = JSON.parse(demoSession);
    return {
      id: demo.id,
      email: demo.email,
      full_name: demo.name,
      role: demo.role,
      isDemo: true
    };
  }
  
  // Check for mediqueue_session (from login.js - new method)
  const sessionStr = localStorage.getItem('mediqueue_session') || sessionStorage.getItem('mediqueue_session');
  if (sessionStr) {
    try {
      const session = JSON.parse(sessionStr);
      return {
        id: session.id,
        email: session.email,
        full_name: session.name,
        role: session.role,
        isDemo: true
      };
    } catch (e) {
      console.error('Error parsing session:', e);
      // Clear invalid session
      localStorage.removeItem('mediqueue_session');
      sessionStorage.removeItem('mediqueue_session');
    }
  }
  
  // Try Supabase session
  const { data: sessionData } = await supabase.auth.getSession();
  const user = sessionData.session?.user;
  if (!user) return null;

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .single();

  if (error) {
    console.error('Error fetching profile:', error);
    // If profile doesn't exist, return basic info with patient role as default
    return {
      id: user.id,
      email: user.email,
      full_name: user.email.split('@')[0],
      role: 'patient'
    };
  }
  
  return profile;
}

/**
 * Redirects to the correct dashboard based on role.
 * Call this after successful login.
 */
export function redirectToDashboard(role) {
  const routes = {
    patient: "./pages/dashboard-patient.html",
    doctor: "./pages/dashboard-doctor.html",
    admin: "./pages/dashboard-admin.html"
  };
  window.location.href = routes[role] ?? "./index.html";
}
