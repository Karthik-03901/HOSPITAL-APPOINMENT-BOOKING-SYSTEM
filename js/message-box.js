/**
 * Floating Message Box
 * Real-time chat widget with Supabase integration
 */

import { supabase } from './supabaseClient.js';
import { toast } from './components/Toast.js';

let messageContainer, messagesArea, realtimeChannel;
let sessionId = null;

document.addEventListener('DOMContentLoaded', () => {
  initMessageBox();
  sessionId = getOrCreateSessionId();
  subscribeToMessages();
});

function getOrCreateSessionId() {
  let id = localStorage.getItem('chatSessionId');
  if (!id) {
    id = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    localStorage.setItem('chatSessionId', id);
  }
  return id;
}

function initMessageBox() {
  messageContainer = document.getElementById('message-container');
  messagesArea = document.getElementById('messages-area');
  
  // Toggle message box
  document.getElementById('message-trigger')?.addEventListener('click', toggleMessageBox);
  document.getElementById('close-message')?.addEventListener('click', closeMessageBox);
  
  // Handle message submission
  document.getElementById('message-form')?.addEventListener('submit', handleSendMessage);
  
  // Load previous messages
  loadPreviousMessages();
}

function toggleMessageBox() {
  if (messageContainer) {
    const isHidden = messageContainer.classList.contains('hidden');
    if (isHidden) {
      messageContainer.classList.remove('hidden');
      messageContainer.classList.add('animate-slide-up');
    } else {
      closeMessageBox();
    }
  }
}

function closeMessageBox() {
  if (messageContainer) {
    messageContainer.classList.add('hidden');
  }
}

async function loadPreviousMessages() {
  try {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('user_id', sessionId)
      .order('created_at', { ascending: true })
      .limit(50);
    
    if (error) throw error;
    
    if (data && data.length > 0) {
      messagesArea.innerHTML = '';
      data.forEach(msg => {
        addMessage(msg.content, msg.sender, new Date(msg.created_at));
      });
    }
  } catch (error) {
    console.error('Failed to load messages:', error);
  }
}

async function handleSendMessage(e) {
  e.preventDefault();
  
  const input = document.getElementById('message-input');
  const message = input.value.trim();
  
  if (!message) return;
  
  // Add to UI immediately
  const now = new Date();
  addMessage(message, 'user', now);
  input.value = '';
  
  // Save to Supabase
  try {
    const { data, error } = await supabase
      .from('messages')
      .insert({
        content: message,
        sender: 'user',
        user_id: sessionId,
        user_email: localStorage.getItem('userEmail') || null,
        user_name: localStorage.getItem('userName') || 'Guest',
        created_at: now.toISOString()
      })
      .select();
    
    if (error) throw error;
    
    // Simulate auto-reply after 2 seconds
    setTimeout(() => {
      sendBotReply(message);
    }, 2000);
    
  } catch (error) {
    console.error('Failed to send message:', error);
    toast.error('Failed to send message');
  }
}

async function sendBotReply(userMessage) {
  const replies = [
    "Thank you for your message! Our support team will respond shortly.",
    "We've received your inquiry. A team member will be with you soon!",
    "Thanks for reaching out! We typically respond within 5 minutes.",
    "Got it! Let me connect you with someone who can help.",
  ];
  
  const reply = replies[Math.floor(Math.random() * replies.length)];
  
  try {
    const { error } = await supabase
      .from('messages')
      .insert({
        content: reply,
        sender: 'bot',
        user_id: sessionId,
        created_at: new Date().toISOString()
      });
    
    if (error) throw error;
    
    addMessage(reply, 'bot', new Date());
  } catch (error) {
    console.error('Failed to send bot reply:', error);
  }
}

function addMessage(content, sender, timestamp) {
  if (!messagesArea) return;
  
  const messageEl = document.createElement('div');
  messageEl.className = `mb-3 animate-fade-in ${sender === 'user' ? 'text-right' : 'text-left'}`;
  
  const bgColor = sender === 'user' ? 'bg-teal-500 text-white' : 
                  sender === 'bot' ? 'bg-blue-100 text-blue-900' : 
                  'bg-white text-slate-900';
  
  const timeColor = sender === 'user' ? 'text-teal-100' : 'text-slate-400';
  
  messageEl.innerHTML = `
    <div class="inline-block ${bgColor} rounded-lg px-4 py-2 max-w-xs shadow-sm">
      <p class="text-sm">${escapeHtml(content)}</p>
      <p class="text-xs ${timeColor} mt-1">
        ${formatTime(timestamp)}
      </p>
    </div>
  `;
  
  messagesArea.appendChild(messageEl);
  messagesArea.scrollTop = messagesArea.scrollHeight;
}

function subscribeToMessages() {
  realtimeChannel = supabase
    .channel('messages_channel')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `user_id=eq.${sessionId}`
      },
      (payload) => {
        const msg = payload.new;
        // Only add if it's from admin (user and bot messages already added locally)
        if (msg.sender === 'admin') {
          addMessage(msg.content, 'admin', new Date(msg.created_at));
          
          // Show notification if message box is closed
          if (messageContainer && messageContainer.classList.contains('hidden')) {
            toast.info('New message from support!');
            
            // Add badge to trigger button
            const trigger = document.getElementById('message-trigger');
            if (trigger && !trigger.querySelector('.badge')) {
              const badge = document.createElement('span');
              badge.className = 'absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center badge';
              badge.textContent = '1';
              trigger.style.position = 'relative';
              trigger.appendChild(badge);
            }
          }
        }
      }
    )
    .subscribe();
}

function formatTime(date) {
  return new Date(date).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit'
  });
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  if (realtimeChannel) {
    supabase.removeChannel(realtimeChannel);
  }
});

export { initMessageBox };
