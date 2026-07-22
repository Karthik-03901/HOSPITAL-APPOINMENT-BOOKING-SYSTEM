/**
 * Symptom Matcher - AI-Powered Department Suggestion
 * Real-time symptom-to-department matching with debounced search
 */

import { supabase } from '../supabaseClient.js';

class SymptomMatcher {
  constructor() {
    this.debounceTimer = null;
    this.debounceDelay = 500; // 500ms delay
    this.lastQuery = '';
    this.callbacks = {
      onSuggestions: null,
      onEmergency: null,
      onError: null
    };
  }

  /**
   * Initialize symptom matcher on input field
   * @param {string} inputId - ID of symptom input field
   * @param {Object} callbacks - Callback functions
   */
  init(inputId, callbacks = {}) {
    this.callbacks = { ...this.callbacks, ...callbacks };
    
    const input = document.getElementById(inputId);
    if (!input) {
      console.error(`Symptom input element #${inputId} not found`);
      return;
    }

    // Add event listener with debouncing
    input.addEventListener('input', (e) => {
      this.handleInput(e.target.value);
    });

    // Add placeholder with hint
    input.placeholder = 'e.g., chest pain, fever, headache...';
    
    console.log('✅ Symptom matcher initialized');
  }

  /**
   * Handle input with debouncing
   */
  handleInput(query) {
    // Clear previous timer
    clearTimeout(this.debounceTimer);

    // Skip if query too short
    if (query.trim().length < 3) {
      this.clearSuggestions();
      return;
    }

    // Skip if same as last query
    if (query.trim() === this.lastQuery) {
      return;
    }

    // Show loading state
    this.showLoading();

    // Debounce the search
    this.debounceTimer = setTimeout(() => {
      this.searchSymptoms(query.trim());
    }, this.debounceDelay);
  }

  /**
   * Search for matching departments
   */
  async searchSymptoms(symptoms) {
    try {
      this.lastQuery = symptoms;
      
      console.log('🔍 Searching symptoms:', symptoms);

      // Call RPC function
      const { data, error } = await supabase
        .rpc('suggest_departments', {
          p_symptoms: symptoms
        });

      if (error) throw error;

      // Check for emergency symptoms
      const hasEmergency = data.some(d => d.severity === 'emergency');
      
      if (hasEmergency && this.callbacks.onEmergency) {
        this.callbacks.onEmergency(data.filter(d => d.severity === 'emergency'));
      }

      // Trigger suggestions callback
      if (this.callbacks.onSuggestions) {
        this.callbacks.onSuggestions(data);
      }

      // Log search for analytics
      if (data.length > 0) {
        await this.logSearch(symptoms, data[0].department_name);
      }

    } catch (error) {
      console.error('Error searching symptoms:', error);
      if (this.callbacks.onError) {
        this.callbacks.onError(error);
      }
    }
  }

  /**
   * Get autocomplete suggestions
   */
  async getAutocomplete(query) {
    try {
      const { data, error } = await supabase
        .rpc('search_symptoms', {
          p_query: query,
          p_limit: 5
        });

      if (error) throw error;

      return data;
    } catch (error) {
      console.error('Error getting autocomplete:', error);
      return [];
    }
  }

  /**
   * Log search for analytics
   */
  async logSearch(symptoms, suggestedDept) {
    try {
      await supabase.rpc('log_symptom_search', {
        p_symptoms: symptoms,
        p_suggested_dept: suggestedDept
      });
    } catch (error) {
      console.error('Error logging search:', error);
    }
  }

  /**
   * Show loading state
   */
  showLoading() {
    if (this.callbacks.onSuggestions) {
      this.callbacks.onSuggestions([{ loading: true }]);
    }
  }

  /**
   * Clear suggestions
   */
  clearSuggestions() {
    if (this.callbacks.onSuggestions) {
      this.callbacks.onSuggestions([]);
    }
  }
}

// Create singleton instance
const symptomMatcher = new SymptomMatcher();

export { SymptomMatcher, symptomMatcher };
export default symptomMatcher;
