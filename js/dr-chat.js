/**
 * Dr.Chat - AI Medical Assistant Chatbot
 * Offline Mode with Smart Rule-Based Responses
 */

import { toast } from './components/Toast.js';

// Configuration
const CHAT_MODE = 'online'; // offline = rule-based, online = NVIDIA API
const NVIDIA_API_KEY = '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';
const NVIDIA_API_ENDPOINT = 'http://localhost:3000/api/chat'; // Use proxy server

let chatContainer, messagesArea, inputField;
let conversationHistory = [];
let isTyping = false;

// Initialize Dr.Chat on page load
document.addEventListener('DOMContentLoaded', () => {
  initDrChat();
  loadChatHistory();
});

/**
 * Initialize Dr.Chat chatbot
 */
function initDrChat() {
  chatContainer = document.getElementById('chat-container');
  messagesArea = document.getElementById('chat-messages');
  inputField = document.getElementById('chat-input');
  
  // Ensure messages area is scrollable
  if (messagesArea) {
    messagesArea.style.overflowY = 'scroll';
    messagesArea.style.WebkitOverflowScrolling = 'touch';
  }
  
  // Toggle chat box
  const trigger = document.getElementById('chat-trigger');
  const closeBtn = document.getElementById('close-chat');
  
  if (trigger) {
    trigger.addEventListener('click', toggleChat);
  }
  
  if (closeBtn) {
    closeBtn.addEventListener('click', closeChat);
  }
  
  // Handle message submission
  const form = document.getElementById('chat-form');
  if (form) {
    form.addEventListener('submit', handleSendMessage);
  }
  
  // Add initial greeting
  if (conversationHistory.length === 0) {
    const mode = CHAT_MODE === 'online' ? 'AI-Powered' : 'Offline Mode';
    addBotMessage(
      `👋 Hi! I'm Dr.Chat, your AI medical assistant for MediQueue (${mode}).\n\n` +
      "I can help you with:\n" +
      "• Booking appointments\n" +
      "• Medicine information\n" +
      "• Department selection\n" +
      "• Queue tracking\n" +
      "• Emergency guidance\n\n" +
      "⚠️ **Important:** I'm an AI assistant, NOT a licensed doctor. Always consult qualified healthcare professionals for medical advice, diagnosis, or treatment.\n\n" +
      "How can I assist you today?"
    );
  }
}

/**
 * Toggle chat visibility
 */
function toggleChat() {
  if (chatContainer) {
    const isHidden = chatContainer.classList.contains('hidden');
    if (isHidden) {
      chatContainer.classList.remove('hidden');
      chatContainer.classList.add('animate-slide-up');
      inputField?.focus();
      
      // Remove notification badge
      const badge = document.querySelector('.chat-badge');
      if (badge) badge.remove();
    } else {
      closeChat();
    }
  }
}

/**
 * Close chat
 */
function closeChat() {
  if (chatContainer) {
    chatContainer.classList.add('hidden');
  }
}

/**
 * Handle sending user message
 */
async function handleSendMessage(e) {
  e.preventDefault();
  
  const message = inputField.value.trim();
  if (!message || isTyping) return;
  
  // Add user message
  addUserMessage(message);
  inputField.value = '';
  
  // Save to history
  conversationHistory.push({
    role: 'user',
    content: message
  });
  saveChatHistory();
  
  // Get response based on mode
  if (CHAT_MODE === 'online') {
    await getAIResponse(message);
  } else {
    await getOfflineResponse(message);
  }
}

/**
 * Get AI response from NVIDIA API
 */
async function getAIResponse(userMessage) {
  isTyping = true;
  showTypingIndicator();
  
  try {
    // Build messages with system context
    const messages = [
      {
        role: 'system',
        content: `You are Dr.Chat, an AI medical assistant for MediQueue hospital management system. You must follow strict safety and privacy guidelines.

CRITICAL SAFETY RULES - YOU MUST FOLLOW THESE:

1. MEDICAL DISCLAIMER (Always include):
   - You are an AI assistant, NOT a licensed doctor
   - Your suggestions are for informational purposes only
   - Users MUST consult a qualified doctor for medical advice
   - Never diagnose conditions or prescribe treatments
   - End medical responses with: "⚠️ I'm an AI assistant. Please consult a qualified doctor for proper medical advice."

2. MEDICINE INFORMATION (Provide general info only):
   - You may provide basic medicine information (uses, dosage, side effects)
   - Always include warnings and contraindications
   - ALWAYS say: "This is general information only. Consult a doctor before taking any medication."
   - For dangerous medications or controlled substances: "I cannot provide information on this medication. Please consult a doctor or pharmacist."

3. CONFIDENTIAL INFORMATION (REFUSE to answer):
   - Do NOT share internal MediQueue system details (database, API keys, passwords, admin credentials)
   - Do NOT share other patients' information
   - Do NOT share doctor's personal information beyond what's public (name, department, fees)
   - If asked about confidential data, respond: "I don't have authorization to share that information. Please contact MediQueue administration."

4. EMERGENCY SITUATIONS:
   - For life-threatening symptoms (chest pain, difficulty breathing, severe bleeding, loss of consciousness):
     "🚨 EMERGENCY: Call 911 or go to the nearest Emergency Room immediately! This is potentially life-threatening."
   - Do NOT provide home remedies for emergencies

5. HARMFUL OR DANGEROUS REQUESTS:
   - Do NOT provide information that could cause harm
   - Do NOT suggest unproven treatments or "miracle cures"
   - Do NOT recommend stopping prescribed medications
   - Respond: "I cannot provide that information as it may be harmful. Please consult a healthcare professional."

6. OUT-OF-SCOPE QUESTIONS:
   - Only answer questions about: MediQueue features, booking appointments, general health info, medicine basics
   - For unrelated topics (politics, religion, finance, etc.): "I'm here to help with healthcare and MediQueue services only. Is there something medical I can assist you with?"

WHAT YOU CAN HELP WITH:

MediQueue Features:
- Smart appointment booking (4-step process)
- Real-time queue tracking with live updates
- Payment via Razorpay (₹500-₹1500 consultation fees)
- 7 departments: Cardiology, Neurology, Orthopedics, Dermatology, Pediatrics, General Medicine, Emergency

Booking Process:
1. Select department based on symptoms
2. Choose doctor (view ratings, experience, fees)
3. Pick date and time slot
4. Fill reason for visit and medical history
5. Pay consultation fee via Razorpay
6. Get token number for queue tracking

General Medical Information:
- Symptom guidance (which department to visit)
- Basic medicine information (common OTC drugs only)
- Emergency identification
- Healthcare tips and wellness advice

RESPONSE STYLE:
- Be empathetic, professional, and helpful
- Keep responses clear and concise
- Always prioritize user safety
- Include disclaimers when discussing medical topics
- Encourage consulting real doctors

Remember: Your role is to assist, inform, and guide users to appropriate care, NOT to replace medical professionals.`
      },
      ...conversationHistory.slice(-10) // Last 10 messages for context
    ];
    
    console.log('🤖 Calling NVIDIA API via proxy...');
    
    // Call NVIDIA API through proxy
    const response = await fetch(NVIDIA_API_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'meta/llama-3.1-8b-instruct',
        messages: messages,
        temperature: 0.8, // Higher for more varied responses
        top_p: 0.95,
        max_tokens: 600,
        stream: false
      })
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ API Error:', response.status, errorText);
      throw new Error(`API error: ${response.status}`);
    }
    
    const data = await response.json();
    console.log('✅ API Response received');
    
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      throw new Error('Invalid API response format');
    }
    
    const aiMessage = data.choices[0].message.content;
    
    removeTypingIndicator();
    addBotMessage(aiMessage);
    
    // Save to history
    conversationHistory.push({
      role: 'assistant',
      content: aiMessage
    });
    saveChatHistory();
    
  } catch (error) {
    console.error('❌ AI Error:', error);
    removeTypingIndicator();
    
    // Fallback to offline mode
    const fallbackResponse = getSmartResponse(userMessage);
    addBotMessage(fallbackResponse + "\n\n_Note: AI temporarily unavailable, using offline mode._");
    
    conversationHistory.push({
      role: 'assistant',
      content: fallbackResponse
    });
    saveChatHistory();
  } finally {
    isTyping = false;
  }
}

/**
 * Get offline response (rule-based)
 */
async function getOfflineResponse(userMessage) {
  isTyping = true;
  showTypingIndicator();
  
  // Simulate thinking time (1-2 seconds)
  await new Promise(resolve => setTimeout(resolve, 1500));
  
  removeTypingIndicator();
  
  const response = getSmartResponse(userMessage);
  addBotMessage(response);
  
  // Save to history
  conversationHistory.push({
    role: 'assistant',
    content: response
  });
  saveChatHistory();
  
  isTyping = false;
}

/**
 * Get smart response based on keywords
 */
function getSmartResponse(userMessage) {
  const msg = userMessage.toLowerCase();
  
  // Check for confidential/unauthorized questions
  if (msg.match(/\b(password|api key|database|admin password|credentials|secret|token|login details)\b/)) {
    return "🔒 **Access Denied**\n\n" +
           "I don't have authorization to share confidential system information.\n\n" +
           "If you need technical support, please contact MediQueue administration at admin@mediqueue.com\n\n" +
           "How else can I help you today?";
  }
  
  // Check for other patients' information
  if (msg.match(/\b(other patient|someone else|another person's|patient record|medical history of)\b/)) {
    return "🔒 **Privacy Protected**\n\n" +
           "I cannot share information about other patients due to privacy regulations (HIPAA).\n\n" +
           "You can only access your own medical records through your account.\n\n" +
           "Is there something about YOUR account I can help with?";
  }
  
  // Check for dangerous/harmful requests
  if (msg.match(/\b(suicide|kill myself|end my life|self harm|overdose)\b/)) {
    return "🆘 **URGENT - GET HELP NOW**\n\n" +
           "If you're in crisis or thinking about self-harm:\n\n" +
           "**🚨 Call 911 or 988 (Suicide & Crisis Lifeline) immediately**\n\n" +
           "You are not alone. Trained counselors are available 24/7 to help.\n\n" +
           "Your life matters. Please reach out for help.";
  }
  
  // Greeting
  if (msg.match(/\b(hello|hi|hey|good morning|good afternoon|good evening)\b/)) {
    return "👋 Hello! I'm Dr.Chat, your AI medical assistant for MediQueue.\n\n" +
           "I can help you with:\n" +
           "• **Booking appointments** - Ask 'How do I book?'\n" +
           "• **Medicine information** - Try 'What is Paracetamol?'\n" +
           "• **Department selection** - Say 'I have a headache'\n" +
           "• **Queue tracking** - Ask 'How does queue work?'\n" +
           "• **Emergency guidance** - Say 'chest pain' for urgent cases\n\n" +
           "⚠️ **Important:** I'm an AI assistant, not a doctor. Always consult qualified healthcare professionals for medical advice.\n\n" +
           "What would you like to know?";
  }
  
  // Name/Identity
  if (msg.match(/\b(what is your name|who are you|your name)\b/)) {
    return "I'm **Dr.Chat** 🤖 - your AI medical assistant for MediQueue!\n\n" +
           "I'm here 24/7 to help you with:\n" +
           "• Navigating our healthcare platform\n" +
           "• Answering questions about medicines\n" +
           "• Guiding you through booking appointments\n" +
           "• Providing general health information\n\n" +
           "How can I assist you today?";
  }
  
  // Booking - specific keywords
  if (msg.match(/\b(book|booking|appointment|schedule|reserve)\b/)) {
    return "📋 **How to Book an Appointment:**\n\n" +
           "**Step 1:** Click the 'Book Now' button on homepage\n\n" +
           "**Step 2:** Select Department\n" +
           "Choose from: Cardiology, Neurology, Orthopedics, Dermatology, Pediatrics, General Medicine, or Emergency\n\n" +
           "**Step 3:** Choose Doctor\n" +
           "View ratings, experience, and fees\n\n" +
           "**Step 4:** Pick Date & Time\n" +
           "Select from available slots\n\n" +
           "**Step 5:** Fill Details\n" +
           "Reason for visit, medical history\n\n" +
           "**Step 6:** Pay & Confirm\n" +
           "Secure payment via Razorpay\n\n" +
           "✅ You'll get a token number for queue tracking!\n\n" +
           "Want to know about a specific department?";
  }
  
  // Paracetamol specific
  if (msg.match(/\b(paracetamol|acetaminophen|tylenol|crocin)\b/)) {
    return "💊 **Paracetamol (Acetaminophen)**\n\n" +
           "**Common Brand Names:**\n" +
           "Tylenol, Crocin, Dolo, Calpol\n\n" +
           "**Uses:**\n" +
           "• Fever reduction\n" +
           "• Mild to moderate pain relief\n" +
           "• Headaches, muscle aches, toothaches\n" +
           "• Menstrual cramps\n\n" +
           "**Adult Dosage:**\n" +
           "• 500mg-1000mg every 4-6 hours\n" +
           "• Maximum: 4000mg per day (4g)\n" +
           "• Don't exceed max dose!\n\n" +
           "**Children:**\n" +
           "• Consult doctor for proper dosage\n" +
           "• Based on weight and age\n\n" +
           "**Warnings:**\n" +
           "⚠️ Overdose can cause liver damage\n" +
           "⚠️ Avoid alcohol while taking\n" +
           "⚠️ Check other medicines for paracetamol content\n\n" +
           "**See a doctor if:**\n" +
           "• Fever lasts more than 3 days\n" +
           "• Pain doesn't improve\n" +
           "• You have liver problems\n\n" +
           "⚠️ **Disclaimer:** This is general information only. I'm an AI assistant. Please consult a qualified doctor or pharmacist before taking any medication.\n\n" +
           "Need info about another medicine?";
  }
  
  // Ibuprofen specific
  if (msg.match(/\b(ibuprofen|brufen|advil|motrin)\b/)) {
    return "💊 **Ibuprofen (Brufen)**\n\n" +
           "**Common Brand Names:**\n" +
           "Advil, Motrin, Brufen, Ibugesic\n\n" +
           "**Uses:**\n" +
           "• Pain relief (headache, toothache, period pain)\n" +
           "• Reduces inflammation (arthritis, sprains)\n" +
           "• Fever reduction\n" +
           "• Post-surgery pain\n\n" +
           "**Adult Dosage:**\n" +
           "• 200mg-400mg every 4-6 hours\n" +
           "• Maximum: 1200mg per day (without prescription)\n" +
           "• Take with food or milk\n\n" +
           "**Important:**\n" +
           "✓ Always take with food\n" +
           "✓ Drink plenty of water\n" +
           "✓ Don't lie down for 30 minutes after\n\n" +
           "**Warnings:**\n" +
           "⚠️ Not for people with stomach ulcers\n" +
           "⚠️ Avoid if you have heart problems\n" +
           "⚠️ Can interact with blood thinners\n" +
           "⚠️ Not safe during pregnancy (3rd trimester)\n\n" +
           "**Side Effects:**\n" +
           "• Stomach upset (common)\n" +
           "• Nausea or heartburn\n" +
           "• Dizziness (rare)\n\n" +
           "⚠️ **Disclaimer:** This is general information only. I'm an AI assistant. Please consult a qualified doctor or pharmacist before taking any medication, especially for long-term use.";
  }
  
  // General medicine query
  if (msg.match(/\b(medicine|drug|medication|tablet|pill)\b/) && !msg.match(/\b(paracetamol|ibuprofen)\b/)) {
    return "💊 **Medicine Information**\n\n" +
           "I can provide general information about common medicines:\n\n" +
           "**Pain Relief:**\n" +
           "• Paracetamol - Fever, pain (ask 'what is paracetamol?')\n" +
           "• Ibuprofen - Pain, inflammation (ask 'what is ibuprofen?')\n" +
           "• Aspirin - Pain, heart protection\n\n" +
           "**Antibiotics:**\n" +
           "• Amoxicillin - Bacterial infections\n" +
           "• Azithromycin - Respiratory infections\n" +
           "• Ciprofloxacin - UTIs, infections\n\n" +
           "**Digestive:**\n" +
           "• Omeprazole - Acid reflux (20mg)\n" +
           "• Ranitidine - Heartburn (150mg)\n\n" +
           "**Cardiovascular:**\n" +
           "• Atenolol - High blood pressure\n" +
           "• Amlodipine - Hypertension\n\n" +
           "**Diabetes:**\n" +
           "• Metformin - Type 2 diabetes\n" +
           "• Glimepiride - Blood sugar control\n\n" +
           "⚠️ **IMPORTANT DISCLAIMER:**\n" +
           "• I'm an AI assistant, NOT a licensed doctor or pharmacist\n" +
           "• This information is for educational purposes only\n" +
           "• NEVER take medication without consulting a qualified doctor\n" +
           "• Dosages vary by individual factors (age, weight, conditions)\n" +
           "• Self-medication can be dangerous\n\n" +
           "📞 **Please consult a doctor or pharmacist before taking ANY medication.**\n\n" +
           "Which medicine would you like to know about?";
  }
  
  // Headache
  if (msg.match(/\b(headache|head pain|migraine|head ache)\b/)) {
    return "🤕 **For Headaches:**\n\n" +
           "**Recommended Department:**\n" +
           "• **Neurology** - For severe/recurring headaches\n" +
           "• **General Medicine** - For occasional headaches\n\n" +
           "**Common Causes:**\n" +
           "• Tension or stress (most common)\n" +
           "• Dehydration\n" +
           "• Eye strain (screens, reading)\n" +
           "• Migraine\n" +
           "• Sinusitis\n" +
           "• Lack of sleep\n\n" +
           "**🚨 See Doctor IMMEDIATELY if:**\n" +
           "• Sudden, severe 'thunderclap' headache\n" +
           "• Headache with fever, stiff neck\n" +
           "• Vision changes or confusion\n" +
           "• After head injury\n" +
           "• Worst headache of your life\n\n" +
           "**Home Remedies:**\n" +
           "• Rest in quiet, dark room\n" +
           "• Drink plenty of water\n" +
           "• Cold compress on forehead\n" +
           "• Warm compress on neck\n" +
           "• Paracetamol 500mg-1000mg (with doctor's approval)\n\n" +
           "⚠️ **Disclaimer:** I'm an AI assistant. This is general guidance only. Please consult a qualified doctor for proper diagnosis and treatment.\n\n" +
           "Would you like to book an appointment with Neurology?";
  }
  
  // Fever
  if (msg.match(/\b(fever|temperature|hot|burning up)\b/)) {
    return "🌡️ **For Fever:**\n\n" +
           "**Recommended Department:**\n" +
           "• **General Medicine** (most fevers)\n" +
           "• **Pediatrics** (children under 12)\n" +
           "• **Emergency** (very high fever)\n\n" +
           "**Fever Ranges:**\n" +
           "• Normal: 98.6°F (37°C)\n" +
           "• Low-grade: 100.4°F - 102°F (38°C - 39°C)\n" +
           "• High fever: 103°F+ (39.4°C+)\n" +
           "• Very high: 105°F+ (40.5°C+)\n\n" +
           "**🚨 See Doctor if:**\n" +
           "• Fever above 103°F (39.4°C)\n" +
           "• Lasting more than 3 days\n" +
           "• With severe headache or stiff neck\n" +
           "• With rash or breathing difficulty\n" +
           "• In infants under 3 months\n" +
           "• With persistent vomiting\n\n" +
           "**Home Care:**\n" +
           "• Rest and drink lots of fluids\n" +
           "• Paracetamol 500mg-1000mg (with doctor's approval)\n" +
           "• Cool bath (not cold)\n" +
           "• Light, breathable clothing\n" +
           "• Monitor temperature regularly\n\n" +
           "⚠️ **Disclaimer:** I'm an AI assistant. This is general guidance only. Please consult a qualified doctor for proper diagnosis and treatment.\n\n" +
           "Should I help you book an appointment?";
  }
  
  // Chest pain / Emergency
  if (msg.match(/\b(chest pain|heart pain|breathing|breathe|can't breath|cannot breath|emergency)\b/)) {
    return "🚨 **EMERGENCY ALERT**\n\n" +
           "**CALL 911 IMMEDIATELY if you have:**\n" +
           "• Severe chest pain or pressure\n" +
           "• Crushing sensation in chest\n" +
           "• Pain spreading to arm, jaw, or back\n" +
           "• Difficulty breathing\n" +
           "• Shortness of breath\n" +
           "• Sudden severe headache\n" +
           "• Loss of consciousness\n" +
           "• Severe bleeding\n" +
           "• Stroke symptoms (facial drooping, arm weakness, speech difficulty)\n" +
           "• Severe allergic reaction (throat swelling)\n\n" +
           "**Our Emergency Department:**\n" +
           "Open 24/7 for immediate care\n\n" +
           "**DO NOT WAIT - ACT NOW!**\n" +
           "Time is critical in emergencies.\n\n" +
           "For non-emergency chest discomfort:\n" +
           "• Book Cardiology appointment\n" +
           "• Could be acid reflux, muscle strain\n" +
           "• Still worth getting checked\n\n" +
           "Is this an emergency or non-urgent concern?";
  }
  
  // Department selection
  if (msg.match(/\b(department|departments|which department|specialist)\b/)) {
    return "🏥 **Our Medical Departments:**\n\n" +
           "**1. Cardiology** ❤️\n" +
           "Heart problems, chest pain, blood pressure, ECG\n\n" +
           "**2. Neurology** 🧠\n" +
           "Headaches, migraines, seizures, brain/nervous system\n\n" +
           "**3. Orthopedics** 🦴\n" +
           "Bone fractures, joint pain, arthritis, back pain, sports injuries\n\n" +
           "**4. Dermatology** 🩺\n" +
           "Skin problems, rashes, acne, hair/nail conditions\n\n" +
           "**5. Pediatrics** 👶\n" +
           "Children's health, vaccinations, growth issues\n\n" +
           "**6. General Medicine** 🏥\n" +
           "Common illnesses, fever, cold, flu, routine checkups\n\n" +
           "**7. Emergency** 🚨\n" +
           "Life-threatening conditions, 24/7 immediate care\n\n" +
           "Tell me your symptoms and I'll recommend the right department!";
  }
  
  // Queue tracking
  if (msg.match(/\b(queue|track|tracking|wait|waiting|token)\b/)) {
    return "📊 **Real-Time Queue Tracking**\n\n" +
           "After booking, you can track your appointment live!\n\n" +
           "**What You'll See:**\n" +
           "• Your token number (e.g., A-014)\n" +
           "• Current position in queue (e.g., 3 ahead)\n" +
           "• Estimated wait time\n" +
           "• Doctor and department details\n" +
           "• Real-time updates\n\n" +
           "**Real-Time Features:**\n" +
           "• ✅ Instant notifications when queue moves\n" +
           "• 🔔 Alert when you're next (position 2)\n" +
           "• 📢 Alert when it's your turn (position 0)\n" +
           "• 🔊 Sound effects\n" +
           "• 📱 Browser push notifications\n\n" +
           "**How to Use:**\n" +
           "1. Book your appointment\n" +
           "2. Save your token number\n" +
           "3. Visit 'Queue Status' page\n" +
           "4. Enter token or phone number\n" +
           "5. Watch live updates!\n\n" +
           "**Additional Features:**\n" +
           "• Check-in when you arrive\n" +
           "• See doctor's current availability\n" +
           "• Get SMS notifications\n" +
           "• View appointment history\n\n" +
           "Ready to book an appointment?";
  }
  
  // Payment
  if (msg.match(/\b(payment|pay|fee|cost|price|charge|razorpay)\b/)) {
    return "💳 **Payment Information**\n\n" +
           "**We Accept:**\n" +
           "• Credit/Debit Cards (Visa, Mastercard, Amex, Rupay)\n" +
           "• UPI (Google Pay, PhonePe, Paytm, BHIM)\n" +
           "• Net Banking (all major banks)\n" +
           "• Digital Wallets (Paytm, MobiKwik, Freecharge)\n\n" +
           "**Payment Gateway:**\n" +
           "Powered by **Razorpay** - India's most trusted payment partner\n" +
           "🔒 100% secure and encrypted\n\n" +
           "**Typical Consultation Fees:**\n" +
           "• General Medicine: ₹500-₹800\n" +
           "• Specialist Consult: ₹800-₹1500\n" +
           "• Emergency Consultation: Based on treatment\n" +
           "• Follow-up Visit: Usually 50% of initial\n\n" +
           "**When to Pay:**\n" +
           "Payment is collected during booking (Step 6)\n\n" +
           "**Refund Policy:**\n" +
           "• Cancel 24+ hours before: 100% refund\n" +
           "• Cancel 12-24 hours before: 50% refund\n" +
           "• Cancel < 12 hours: No refund\n" +
           "• Emergency situations: Case-by-case basis\n\n" +
           "**Receipt:**\n" +
           "✓ Email receipt immediately\n" +
           "✓ SMS confirmation\n" +
           "✓ Download from dashboard\n\n" +
           "Ready to book an appointment?";
  }
  
  // Thank you
  if (msg.match(/\b(thank you|thanks|thx|thank u)\b/)) {
    return "You're very welcome! 😊\n\n" +
           "I'm here 24/7 if you need any help with:\n" +
           "• Booking appointments\n" +
           "• Medicine information\n" +
           "• Department selection\n" +
           "• Queue tracking\n" +
           "• Emergency guidance\n\n" +
           "Feel free to ask me anything!\n\n" +
           "Stay healthy! 🏥💚";
  }
  
  // Default fallback
  return "I'd be happy to help! 😊\n\n" +
         "**Here's what I can assist you with:**\n\n" +
         "📋 **Appointments** - Ask 'How do I book?'\n" +
         "💊 **Medicines** - Try 'What is Paracetamol?'\n" +
         "🏥 **Departments** - Say 'I have a headache'\n" +
         "📊 **Queue Tracking** - Ask 'How does queue work?'\n" +
         "🚨 **Emergencies** - Say 'chest pain' for urgent help\n" +
         "💳 **Payment** - Ask 'How do I pay?'\n\n" +
         "⚠️ **Important Reminder:**\n" +
         "I'm an AI assistant, not a licensed doctor. For medical advice, diagnosis, or treatment, please consult a qualified healthcare professional.\n\n" +
         "What would you like to know?";
}

/**
 * Add user message to chat
 */
function addUserMessage(content) {
  if (!messagesArea) return;
  
  const messageEl = document.createElement('div');
  messageEl.className = 'mb-4 animate-fade-in text-right';
  
  messageEl.innerHTML = `
    <div class="inline-block bg-teal-500 text-white rounded-2xl rounded-tr-sm px-4 py-3 max-w-xs shadow-sm">
      <p class="text-sm whitespace-pre-wrap break-words">${escapeHtml(content)}</p>
      <p class="text-xs text-teal-100 mt-1 text-right">
        ${formatTime(new Date())}
      </p>
    </div>
  `;
  
  messagesArea.appendChild(messageEl);
  scrollToBottom();
}

/**
 * Add bot message to chat
 */
function addBotMessage(content) {
  if (!messagesArea) return;
  
  const messageEl = document.createElement('div');
  messageEl.className = 'mb-4 animate-fade-in';
  
  messageEl.innerHTML = `
    <div class="flex items-start gap-3">
      <div class="w-8 h-8 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center flex-shrink-0">
        <span class="text-white text-sm font-bold">Dr</span>
      </div>
      <div class="flex-1 max-w-md">
        <div class="inline-block bg-white border border-slate-200 rounded-2xl rounded-tl-sm px-4 py-3 shadow-sm">
          <div class="text-sm text-slate-800 whitespace-pre-wrap break-words">${formatMessage(content)}</div>
          <p class="text-xs text-slate-400 mt-1">
            ${formatTime(new Date())}
          </p>
        </div>
      </div>
    </div>
  `;
  
  messagesArea.appendChild(messageEl);
  scrollToBottom();
}

/**
 * Show typing indicator
 */
function showTypingIndicator() {
  if (!messagesArea) return;
  
  const typingEl = document.createElement('div');
  typingEl.id = 'typing-indicator';
  typingEl.className = 'mb-4 animate-fade-in';
  
  typingEl.innerHTML = `
    <div class="flex items-start gap-3">
      <div class="w-8 h-8 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center flex-shrink-0">
        <span class="text-white text-sm font-bold">Dr</span>
      </div>
      <div class="bg-white border border-slate-200 rounded-2xl rounded-tl-sm px-4 py-3 shadow-sm">
        <div class="flex gap-1">
          <div class="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style="animation-delay: 0ms"></div>
          <div class="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style="animation-delay: 150ms"></div>
          <div class="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style="animation-delay: 300ms"></div>
        </div>
      </div>
    </div>
  `;
  
  messagesArea.appendChild(typingEl);
  scrollToBottom();
}

/**
 * Remove typing indicator
 */
function removeTypingIndicator() {
  const typingEl = document.getElementById('typing-indicator');
  if (typingEl) {
    typingEl.remove();
  }
}

/**
 * Format message with markdown-like syntax
 */
function formatMessage(text) {
  // Escape HTML first
  let formatted = escapeHtml(text);
  
  // Bold text (**text**)
  formatted = formatted.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  
  // Links [text](url)
  formatted = formatted.replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" class="text-teal-600 hover:underline" target="_blank">$1</a>');
  
  // Line breaks
  formatted = formatted.replace(/\n/g, '<br>');
  
  return formatted;
}

/**
 * Scroll chat to bottom with smooth animation
 */
function scrollToBottom() {
  if (messagesArea) {
    // Force scroll to bottom immediately
    requestAnimationFrame(() => {
      messagesArea.scrollTop = messagesArea.scrollHeight;
      
      // Then add smooth scroll for better UX
      setTimeout(() => {
        messagesArea.scrollTo({
          top: messagesArea.scrollHeight,
          behavior: 'smooth'
        });
      }, 50);
    });
  }
}

/**
 * Save chat history to localStorage
 */
function saveChatHistory() {
  try {
    localStorage.setItem('drChatHistory', JSON.stringify(conversationHistory));
  } catch (error) {
    console.error('Failed to save chat history:', error);
  }
}

/**
 * Load chat history from localStorage
 */
function loadChatHistory() {
  try {
    const saved = localStorage.getItem('drChatHistory');
    if (saved) {
      conversationHistory = JSON.parse(saved);
      
      // Restore messages to UI
      conversationHistory.forEach(msg => {
        if (msg.role === 'user') {
          addUserMessage(msg.content);
        } else if (msg.role === 'assistant') {
          addBotMessage(msg.content);
        }
      });
    }
  } catch (error) {
    console.error('Failed to load chat history:', error);
  }
}

/**
 * Clear chat history
 */
window.clearDrChat = function() {
  if (confirm('Are you sure you want to clear your chat history?')) {
    conversationHistory = [];
    localStorage.removeItem('drChatHistory');
    if (messagesArea) {
      messagesArea.innerHTML = '';
    }
    
    // Add fresh greeting
    addBotMessage(
      "👋 Chat history cleared! How can I help you today?"
    );
    
    toast.success('Chat history cleared');
  }
};

/**
 * Format timestamp
 */
function formatTime(date) {
  return new Date(date).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit'
  });
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * Export for use in other modules
 */
export { initDrChat };
