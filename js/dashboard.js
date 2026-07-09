// ============================================================
// DASHBOARD — doctor status board + real-time booking
// ============================================================

let currentUser = null;
let selectedDoctor = null;

const statusDot = {
  available: "bg-[#00FF87] shadow-[0_0_6px_#00FF87]",
  busy: "bg-[#FF3860] shadow-[0_0_6px_#FF3860]",
  offline: "bg-[#78909C]",
};

const statusLabel = {
  available: "AVAILABLE",
  busy: "IN SESSION",
  offline: "OFFLINE",
};

async function initDashboard() {
  const session = await requireSession("login.html");
  if (!session) return;
  currentUser = session.user;

  const { data: profile } = await db
    .from("profiles")
    .select("full_name")
    .eq("id", currentUser.id)
    .single();

  document.getElementById("user-name").textContent =
    profile?.full_name?.toUpperCase() || currentUser.email;

  await loadDoctors();
  await loadMyAppointments();
  subscribeToRealtime();
}

// ---- Load doctor status board ----
async function loadDoctors() {
  const { data: doctors, error } = await db
    .from("doctors")
    .select("*")
    .order("status", { ascending: true });

  const board = document.getElementById("doctor-board");
  board.innerHTML = "";

  if (error) {
    board.innerHTML = `<p class="text-[#B3261E] font-mono text-sm">ERROR LOADING BOARD — ${error.message}</p>`;
    return;
  }

  doctors.forEach((doc) => board.appendChild(renderDoctorCard(doc)));
}

function renderDoctorCard(doc) {
  const card = document.createElement("div");
  card.className =
    "relative border border-[#1B2936] bg-[#131920] p-5 flex flex-col gap-3 corner-bracket glass-panel";
  card.innerHTML = `
    <div class="flex items-center justify-between">
      <span class="font-mono text-[11px] tracking-widest text-[#78909C]">DR-${doc.id
      .slice(0, 6)
      .toUpperCase()}</span>
      <span class="flex items-center gap-2 font-mono text-[11px] tracking-widest text-[#EAF2F5]">
        <span class="w-2 h-2 rounded-full ${statusDot[doc.status]} ${doc.status === "available" ? "animate-pulse" : ""
    }"></span>
        ${statusLabel[doc.status]}
      </span>
    </div>
    <h3 class="font-display text-xl font-semibold text-[#EAF2F5]">${doc.full_name}</h3>
    <p class="text-sm text-[#78909C]">${doc.specialty}</p>
    <dl class="grid grid-cols-2 gap-y-1 font-mono text-xs text-[#78909C] border-t border-[#1B2936] pt-3 mt-1">
      <dt>EXPERIENCE</dt><dd class="text-right text-[#EAF2F5]">${doc.years_experience} YRS</dd>
      <dt>FEE</dt><dd class="text-right text-[#EAF2F5]">₹${doc.consultation_fee}</dd>
      <dt>LOCATION</dt><dd class="text-right text-[#EAF2F5]">${doc.clinic_location}</dd>
      <dt>RATING</dt><dd class="text-right text-[#EAF2F5]">${doc.rating} / 5.0</dd>
    </dl>
    <button
      ${doc.status === "offline" ? "disabled" : ""}
      onclick="openBookingPanel('${doc.id}', '${doc.full_name.replace(/'/g, "\\'")}')"
      class="mt-2 w-full bg-[#1C323E] text-[#00FFC4] border border-[#274757] font-mono text-xs tracking-widest py-2.5 disabled:bg-[#1B2936] disabled:text-[#78909C] disabled:border-transparent disabled:cursor-not-allowed hover:bg-[#00FFC4] hover:text-[#090D10] hover:border-[#00FFC4] hover:shadow-[0_0_8px_rgba(0,255,196,0.25)] transition-all duration-300">
      ${doc.status === "offline" ? "UNAVAILABLE" : "BOOK SLOT →"}
    </button>
  `;
  return card;
}

// ---- Booking panel ----
// ---- Booking panel & Wizard State ----
let currentStep = 0;
let selectedSlotId = null;
let captchaResult = null;

function generateCaptcha() {
  const num1 = Math.floor(Math.random() * 9) + 2;
  const num2 = Math.floor(Math.random() * 9) + 2;
  captchaResult = num1 + num2;
  const qEl = document.getElementById("captcha-question");
  if (qEl) {
    qEl.textContent = `${num1} + ${num2} = ?`;
  }
}

function renderWizardStep() {
  const steps = [0, 1, 2, 3];
  steps.forEach(s => {
    const el = document.getElementById(`booking-step-${s}`);
    if (el) {
      if (s === currentStep) {
        el.classList.remove('hidden');
      } else {
        el.classList.add('hidden');
      }
    }

    // Update step indicator styling
    const ind = document.getElementById(`step-ind-${s}`);
    if (ind) {
      if (s < currentStep) {
        ind.className = "step-indicator text-[#78909C] line-through font-mono text-[10px]";
      } else if (s === currentStep) {
        ind.className = "step-indicator text-[#00FFC4] font-semibold font-mono text-[10px] shadow-[0_0_8px_rgba(0,255,196,0.1)]";
      } else {
        ind.className = "step-indicator text-[#4A5560] font-mono text-[10px]";
      }
    }
  });

  // Buttons configuration
  const btnPrev = document.getElementById('btn-prev');
  const btnNext = document.getElementById('btn-next');

  if (currentStep === 0) {
    btnPrev.classList.add('hidden');
    btnPrev.disabled = true;
    btnNext.textContent = "NEXT →";
    btnNext.disabled = !selectedSlotId;
  } else {
    btnPrev.classList.remove('hidden');
    btnPrev.disabled = false;

    if (currentStep === 3) {
      btnNext.textContent = "AUTHORIZE & BOOK →";
      toggleVerifyNextButton();
    } else {
      btnNext.textContent = "NEXT →";
      btnNext.disabled = false;
    }
  }
}

function selectSlot(slotId) {
  selectedSlotId = slotId;
  const list = document.getElementById("slot-list");
  if (list) {
    const buttons = list.querySelectorAll("button");
    buttons.forEach(btn => {
      if (btn.getAttribute("data-id") === slotId) {
        btn.className = "w-full text-left border border-[#00FFC4] bg-[#00FFC4]/15 px-4 py-3 font-mono text-xs flex justify-between text-[#EAF2F5] transition-all duration-300 shadow-[0_0_8px_rgba(0,255,196,0.15)]";
      } else {
        btn.className = "w-full text-left border border-[#1B2936] bg-[#090D10] px-4 py-3 font-mono text-xs flex justify-between hover:border-[#00FFC4] hover:bg-[#00FFC4]/10 text-[#EAF2F5] transition-all duration-300";
      }
    });
  }
  const btnNext = document.getElementById("btn-next");
  if (btnNext) btnNext.disabled = false;
}

function validateStep(step) {
  if (step === 0) {
    if (!selectedSlotId) {
      alert("Please select an open time slot.");
      return false;
    }
    return true;
  }

  if (step === 1) {
    const name = document.getElementById("patient-name")?.value.trim();
    const age = parseInt(document.getElementById("patient-age")?.value, 10);
    if (!name) {
      alert("Please enter the patient's full name.");
      document.getElementById("patient-name")?.focus();
      return false;
    }
    if (!age || isNaN(age) || age < 1 || age > 120) {
      alert("Please enter a valid age (1-120).");
      document.getElementById("patient-age")?.focus();
      return false;
    }
    return true;
  }

  if (step === 2) {
    const idNum = document.getElementById("govt-id-number")?.value.trim();
    const emergencyName = document.getElementById("emergency-name")?.value.trim();
    const emergencyPhone = document.getElementById("emergency-phone")?.value.trim();
    const idType = document.getElementById("govt-id-type")?.value;

    if (!idNum) {
      alert("Please enter your Government ID Number.");
      document.getElementById("govt-id-number")?.focus();
      return false;
    }
    if (idType === "Aadhaar" && !/^\d{4}-\d{4}-\d{4}$/.test(idNum) && !/^\d{12}$/.test(idNum)) {
      alert("Aadhaar Card must be 12 digits (format: XXXX-XXXX-XXXX or 12 digits).");
      document.getElementById("govt-id-number")?.focus();
      return false;
    }
    if (!emergencyName) {
      alert("Please enter an Emergency Contact Name.");
      document.getElementById("emergency-name")?.focus();
      return false;
    }
    if (!emergencyPhone || !/^\d{10}$/.test(emergencyPhone.replace(/[\s-]/g, ""))) {
      alert("Please enter a valid 10-digit Emergency Contact Phone number.");
      document.getElementById("emergency-phone")?.focus();
      return false;
    }
    return true;
  }

  if (step === 3) {
    const captchaAns = parseInt(document.getElementById("captcha-answer")?.value, 10);
    const consent = document.getElementById("legal-consent")?.checked;
    const signature = document.getElementById("digital-signature")?.value.trim();

    if (isNaN(captchaAns) || captchaAns !== captchaResult) {
      alert("Incorrect Robot Protection Check answer.");
      document.getElementById("captcha-answer")?.focus();
      return false;
    }
    if (!consent) {
      alert("You must consent to the medical details agreement.");
      document.getElementById("legal-consent")?.focus();
      return false;
    }
    if (!signature) {
      alert("Please type your signature to authorize the booking.");
      document.getElementById("digital-signature")?.focus();
      return false;
    }
    return true;
  }
  return true;
}

function nextWizardStep() {
  if (!validateStep(currentStep)) return;
  if (currentStep < 3) {
    currentStep++;
    renderWizardStep();
  } else {
    confirmBooking();
  }
}

function prevWizardStep() {
  if (currentStep > 0) {
    currentStep--;
    renderWizardStep();
  }
}

function toggleVerifyNextButton() {
  if (currentStep !== 3) return;
  const consent = document.getElementById("legal-consent")?.checked;
  const signature = document.getElementById("digital-signature")?.value.trim();
  const btnNext = document.getElementById("btn-next");
  if (btnNext) {
    btnNext.disabled = (!consent || !signature);
  }
}

// Make wizard navigation global
window.nextWizardStep = nextWizardStep;
window.prevWizardStep = prevWizardStep;
window.selectSlot = selectSlot;
window.toggleVerifyNextButton = toggleVerifyNextButton;

async function openBookingPanel(doctorId, doctorName) {
  selectedDoctor = doctorId;
  document.getElementById("panel-doctor-name").textContent = doctorName;
  document.getElementById("booking-panel").classList.remove("translate-x-full");

  // Reset wizard state
  currentStep = 0;
  selectedSlotId = null;
  generateCaptcha();

  // Reset all steps inputs
  if (document.getElementById("captcha-answer")) document.getElementById("captcha-answer").value = "";
  if (document.getElementById("legal-consent")) document.getElementById("legal-consent").checked = false;
  if (document.getElementById("digital-signature")) document.getElementById("digital-signature").value = "";
  if (document.getElementById("govt-id-number")) document.getElementById("govt-id-number").value = "";
  if (document.getElementById("emergency-name")) document.getElementById("emergency-name").value = "";
  if (document.getElementById("emergency-phone")) document.getElementById("emergency-phone").value = "";

  const medHistChecks = document.getElementsByName("med-history");
  medHistChecks.forEach(ch => ch.checked = false);

  // Pre-populate patient name from user profile header
  const profileName = document.getElementById("user-name").textContent;
  const nameInput = document.getElementById("patient-name");
  if (nameInput) {
    nameInput.value = (profileName && profileName !== "…" && profileName !== "LOADING…") ? profileName : "";
  }

  // Reset clinical fields on panel open
  if (document.getElementById("patient-age")) document.getElementById("patient-age").value = "";
  if (document.getElementById("booking-reason")) document.getElementById("booking-reason").value = "";
  if (document.getElementById("previous-checkup")) {
    document.getElementById("previous-checkup").value = "false";
    togglePrescriptionField();
  }

  renderWizardStep();

  const { data: slots, error } = await db
    .from("slots")
    .select("*")
    .eq("doctor_id", doctorId)
    .eq("is_booked", false)
    .gte("slot_date", new Date().toISOString().slice(0, 10))
    .order("slot_date", { ascending: true })
    .order("start_time", { ascending: true });

  const list = document.getElementById("slot-list");
  list.innerHTML = "";

  if (error || !slots?.length) {
    list.innerHTML = `<p class="font-mono text-xs text-[#4A5560]">NO OPEN SLOTS FOUND.</p>`;
    return;
  }

  slots.forEach((slot) => {
    const btn = document.createElement("button");
    btn.setAttribute("data-id", slot.id);
    btn.className =
      "w-full text-left border border-[#1B2936] bg-[#090D10] px-4 py-3 font-mono text-xs flex justify-between hover:border-[#00FFC4] hover:bg-[#00FFC4]/10 text-[#EAF2F5] transition-all duration-300";
    btn.innerHTML = `<span>${slot.slot_date}</span><span class="text-[#00FFC4]">${slot.start_time.slice(
      0,
      5
    )}–${slot.end_time.slice(0, 5)}</span>`;
    btn.onclick = () => selectSlot(slot.id);
    list.appendChild(btn);
  });
}

function closeBookingPanel() {
  document.getElementById("booking-panel").classList.add("translate-x-full");
}

function togglePrescriptionField() {
  const select = document.getElementById("previous-checkup");
  const group = document.getElementById("prescription-notes-group");
  if (select && group) {
    if (select.value === "true") {
      group.classList.remove("hidden");
    } else {
      group.classList.add("hidden");
      const notes = document.getElementById("prescription-notes");
      if (notes) notes.value = "";
    }
  }
}

// ---- Confirm booking → creates the "work order" ----
async function confirmBooking() {
  const patientNameEl = document.getElementById("patient-name");
  const patientAgeEl = document.getElementById("patient-age");
  const previousCheckupEl = document.getElementById("previous-checkup");
  const prescriptionNotesEl = document.getElementById("prescription-notes");

  const consultationTypeEl = document.getElementById("consultation-type");
  const consultationModeEl = document.getElementById("consultation-mode");
  const govtIdTypeEl = document.getElementById("govt-id-type");
  const govtIdNumberEl = document.getElementById("govt-id-number");
  const emergencyNameEl = document.getElementById("emergency-name");
  const emergencyPhoneEl = document.getElementById("emergency-phone");

  const patientName = patientNameEl?.value.trim();
  const patientAge = parseInt(patientAgeEl?.value, 10);
  const previousCheckup = previousCheckupEl?.value === "true";
  const prescriptionNotes = previousCheckup ? prescriptionNotesEl?.value.trim() : null;

  const consultationType = consultationTypeEl?.value;
  const consultationMode = consultationModeEl?.value;
  const govtIdType = govtIdTypeEl?.value;
  const govtIdNumber = govtIdNumberEl?.value.trim();
  const emergencyName = emergencyNameEl?.value.trim();
  const emergencyPhone = emergencyPhoneEl?.value.trim();

  // Known medical history checkboxes
  const medHistory = Array.from(document.querySelectorAll('input[name="med-history"]:checked'))
    .map(el => el.value)
    .join(', ') || 'None';

  const { data, error } = await db
    .from("appointments")
    .insert({
      patient_id: currentUser.id,
      doctor_id: selectedDoctor,
      slot_id: selectedSlotId,
      reason: document.getElementById("booking-reason")?.value || null,
      patient_name: patientName,
      patient_age: patientAge,
      previous_checkup: previousCheckup,
      prescription_notes: prescriptionNotes,
      consultation_type: consultationType,
      consultation_mode: consultationMode,
      govt_id_type: govtIdType,
      govt_id_number: govtIdNumber,
      emergency_contact_name: emergencyName,
      emergency_contact_phone: emergencyPhone,
      medical_history: medHistory,
      consent_signed: true
    })
    .select()
    .single();

  if (error) {
    alert(`Booking failed — ${error.message}`);
    return;
  }

  closeBookingPanel();
  showTicket(data);
  await loadMyAppointments();
}


function showTicket(appointment) {
  const modal = document.getElementById("ticket-modal");
  document.getElementById("ticket-code").textContent = appointment.ticket_code;
  document.getElementById("ticket-status").textContent =
    appointment.status.toUpperCase();
  modal.classList.remove("hidden");
}

function closeTicket() {
  document.getElementById("ticket-modal").classList.add("hidden");
}

// ---- My appointments list ----
async function loadMyAppointments() {
  const { data, error } = await db
    .from("appointments")
    .select("id, ticket_code, status, created_at, doctors(full_name, specialty), slots(slot_date, start_time)")
    .eq("patient_id", currentUser.id)
    .order("created_at", { ascending: false });

  const list = document.getElementById("my-appointments");
  list.innerHTML = "";

  if (error || !data?.length) {
    list.innerHTML = `<p class="font-mono text-xs text-[#4A5560]">NO APPOINTMENTS ON RECORD.</p>`;
    return;
  }

  data.forEach((appt) => {
    const row = document.createElement("div");
    row.className =
      "flex items-center justify-between border border-[#1B2936] bg-[#131920] px-4 py-3 glass-panel";
    row.innerHTML = `
      <div>
        <p class="font-mono text-[11px] text-[#78909C]">#${appt.ticket_code}</p>
        <p class="text-sm font-medium text-[#EAF2F5]">${appt.doctors?.full_name || "—"}</p>
        <p class="text-xs text-[#78909C]">${appt.slots?.slot_date || ""} · ${appt.slots?.start_time?.slice(0, 5) || ""
      }</p>
      </div>
      <span class="font-mono text-[10px] tracking-widest px-2 py-1 border ${appt.status === "confirmed"
        ? "border-[#00FF87] text-[#00FF87]"
        : appt.status === "cancelled"
          ? "border-[#FF3860] text-[#FF3860]"
          : "border-[#78909C] text-[#78909C]"
      }">${appt.status.toUpperCase()}</span>
    `;
    list.appendChild(row);
  });
}

// ---- Real-time subscription: doctor status board updates live ----
function subscribeToRealtime() {
  db.channel("doctors-status")
    .on(
      "postgres_changes",
      { event: "UPDATE", schema: "public", table: "doctors" },
      () => loadDoctors()
    )
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "slots" },
      () => {
        if (selectedDoctor) openBookingPanel(selectedDoctor, document.getElementById("panel-doctor-name").textContent);
      }
    )
    .subscribe();
}
