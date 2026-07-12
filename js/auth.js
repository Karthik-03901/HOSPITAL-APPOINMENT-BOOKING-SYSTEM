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
 */
export async function signIn({ email, password }) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/**
 * Returns the current session's profile (role, name, etc.) or null.
 */
export async function getCurrentProfile() {
  const { data: sessionData } = await supabase.auth.getSession();
  const user = sessionData.session?.user;
  if (!user) return null;

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .single();

  if (error) throw error;
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
