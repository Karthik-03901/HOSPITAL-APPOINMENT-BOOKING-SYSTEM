// ============================================================
// AUTH — signup / login / logout handlers
// ============================================================

function setFormStatus(el, message, isError = false) {
  el.textContent = message;
  el.classList.remove("hidden");
  el.classList.toggle("text-[#B3261E]", isError);
  el.classList.toggle("text-[#0E7C7B]", !isError);
}

// ---- SIGN UP ----
async function handleSignup(event) {
  event.preventDefault();
  const form = event.target;
  const statusEl = document.getElementById("form-status");
  const submitBtn = form.querySelector("button[type=submit]");

  const fullName = form.fullName.value.trim();
  const email = form.email.value.trim();
  const password = form.password.value;

  submitBtn.disabled = true;
  submitBtn.textContent = "CREATING ACCOUNT…";

  const { data, error } = await db.auth.signUp({
    email,
    password,
    options: {
      data: { full_name: fullName, role: "patient" },
    },
  });

  submitBtn.disabled = false;
  submitBtn.textContent = "CREATE ACCOUNT";

  if (error) {
    setFormStatus(statusEl, `ERROR — ${error.message}`, true);
    return;
  }

  setFormStatus(
    statusEl,
    "ACCOUNT CREATED — check your email to confirm, then log in."
  );
  form.reset();
}

// ---- LOG IN ----
async function handleLogin(event) {
  event.preventDefault();
  const form = event.target;
  const statusEl = document.getElementById("form-status");
  const submitBtn = form.querySelector("button[type=submit]");

  const email = form.email.value.trim();
  const password = form.password.value;

  submitBtn.disabled = true;
  submitBtn.textContent = "VERIFYING…";

  const { data, error } = await db.auth.signInWithPassword({ email, password });

  submitBtn.disabled = false;
  submitBtn.textContent = "LOG IN";

  if (error) {
    setFormStatus(statusEl, `ERROR — ${error.message}`, true);
    return;
  }

  window.location.href = "dashboard.html";
}

// ---- LOG OUT ----
async function handleLogout() {
  await db.auth.signOut();
  window.location.href = "login.html";
}
