/**
 * Real-Time Queue Management Module
 * Handles live queue position updates via Supabase Realtime
 */

import { supabase } from '../supabaseClient.js';

class RealtimeQueueManager {
  constructor() {
    this.channel = null;
    this.appointmentId = null;
    this.callbacks = {
      onPositionChange: null,
      onQueueUpdate: null,
      onAppointmentCalled: null,
      onDoctorDelay: null,
      onError: null
    };
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectDelay = 2000;
  }

  /**
   * Subscribe to real-time updates for an appointment
   * @param {string} appointmentId - UUID of the appointment
   * @param {Object} callbacks - Callback functions
   */
  async subscribe(appointmentId, callbacks = {}) {
    this.appointmentId = appointmentId;
    this.callbacks = { ...this.callbacks, ...callbacks };

    try {
      // Unsubscribe from previous channel if exists
      await this.unsubscribe();

      console.log('🔔 Subscribing to real-time updates for:', appointmentId);

      // Create channel for this appointment
      this.channel = supabase.channel(`queue:${appointmentId}`)
        
        // Listen for queue position updates
        .on(
          'postgres_changes',
          {
            event: 'UPDATE',
            schema: 'public',
            table: 'queue_positions',
            filter: `appointment_id=eq.${appointmentId}`
          },
          (payload) => {
            console.log('📊 Queue position updated:', payload);
            this.handleQueuePositionUpdate(payload);
          }
        )
        
        // Listen for appointment status updates
        .on(
          'postgres_changes',
          {
            event: 'UPDATE',
            schema: 'public',
            table: 'appointments',
            filter: `id=eq.${appointmentId}`
          },
          (payload) => {
            console.log('📋 Appointment updated:', payload);
            this.handleAppointmentUpdate(payload);
          }
        )
        
        // Subscribe to the channel
        .subscribe((status) => {
          console.log('📡 Realtime connection status:', status);
          
          if (status === 'SUBSCRIBED') {
            console.log('✅ Successfully subscribed to realtime updates');
            this.reconnectAttempts = 0;
          } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
            console.log('❌ Realtime connection error, attempting reconnect...');
            this.handleReconnect();
          }
        });

      return true;
    } catch (error) {
      console.error('❌ Error subscribing to realtime:', error);
      if (this.callbacks.onError) {
        this.callbacks.onError(error);
      }
      return false;
    }
  }

  /**
   * Unsubscribe from real-time updates
   */
  async unsubscribe() {
    if (this.channel) {
      console.log('🔕 Unsubscribing from realtime updates');
      await supabase.removeChannel(this.channel);
      this.channel = null;
    }
  }

  /**
   * Handle queue position updates
   */
  handleQueuePositionUpdate(payload) {
    const { new: newData, old: oldData } = payload;

    // Extract position data
    const positionData = {
      position: newData.position,
      estimatedTime: newData.estimated_time,
      status: newData.status,
      actualCallTime: newData.actual_call_time,
      event: 'POSITION_UPDATE',
      previousPosition: oldData?.position
    };

    // Trigger position change callback
    if (this.callbacks.onPositionChange) {
      this.callbacks.onPositionChange(positionData);
    }

    // Check if position is 1 or 0 (next in line or called)
    if (newData.position <= 1 && oldData?.position > 1) {
      this.notifyNextInLine(positionData);
    }

    // Check if appointment was called
    if (newData.status === 'called' && oldData?.status !== 'called') {
      this.notifyAppointmentCalled(positionData);
    }
  }

  /**
   * Handle appointment status updates
   */
  handleAppointmentUpdate(payload) {
    const { new: newData, old: oldData } = payload;

    const appointmentData = {
      id: newData.id,
      status: newData.status,
      checkInTime: newData.check_in_time,
      updatedAt: newData.updated_at,
      previousStatus: oldData?.status,
      event: 'APPOINTMENT_UPDATE'
    };

    // Trigger general queue update callback
    if (this.callbacks.onQueueUpdate) {
      this.callbacks.onQueueUpdate(appointmentData);
    }

    // Handle specific status changes
    switch (newData.status) {
      case 'called':
        if (oldData?.status !== 'called') {
          this.notifyAppointmentCalled(appointmentData);
        }
        break;
      
      case 'consulting':
        if (this.callbacks.onQueueUpdate) {
          this.callbacks.onQueueUpdate({
            ...appointmentData,
            message: 'Consultation has started'
          });
        }
        break;
      
      case 'completed':
        if (this.callbacks.onQueueUpdate) {
          this.callbacks.onQueueUpdate({
            ...appointmentData,
            message: 'Consultation completed'
          });
        }
        break;
    }
  }

  /**
   * Notify when next in line
   */
  notifyNextInLine(positionData) {
    console.log('🔔 Patient is next in line!');
    
    // Browser notification
    this.sendBrowserNotification(
      'Almost Your Turn!',
      'You are next in line. Please get ready.',
      'queue-next'
    );

    // Play notification sound
    this.playNotificationSound();
  }

  /**
   * Notify when appointment is called
   */
  notifyAppointmentCalled(data) {
    console.log('🔔 Appointment called!');
    
    // Trigger callback
    if (this.callbacks.onAppointmentCalled) {
      this.callbacks.onAppointmentCalled(data);
    }

    // Browser notification
    this.sendBrowserNotification(
      "It's Your Turn!",
      'Please proceed to the consultation room.',
      'queue-called'
    );

    // Play sound
    this.playNotificationSound('urgent');

    // Vibrate if supported
    if ('vibrate' in navigator) {
      navigator.vibrate([200, 100, 200]);
    }
  }

  /**
   * Send browser notification
   */
  async sendBrowserNotification(title, body, tag) {
    if ('Notification' in window && Notification.permission === 'granted') {
      try {
        const notification = new Notification(title, {
          body,
          icon: '/assets/logo.png',
          badge: '/assets/badge-icon.png',
          tag,
          requireInteraction: true,
          vibrate: [200, 100, 200]
        });

        notification.onclick = () => {
          window.focus();
          notification.close();
        };

        // Auto-close after 10 seconds
        setTimeout(() => notification.close(), 10000);
      } catch (error) {
        console.error('Error showing notification:', error);
      }
    }
  }

  /**
   * Play notification sound
   */
  playNotificationSound(type = 'normal') {
    try {
      const sounds = {
        normal: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWm98OScTgwOUKXi7q1hGwU7k9j0zHcrBxl6yvLbjDgKGGS35+qkUBELTKXh8rZqHQU3jtT0ynUrBCB5yPLaiTkIGGO15+moUhILS6Xi8rRqHAU4jdPzyXQrBSF4yPDZiTgIGGS15+mnUREKTKLe8bJmGwQ4jdT0ynQrBSB4x/HZiDgIGGOz5einTxEKTKLe8bFmGgQ5jdP0yXMrBSF4yPDZiTcIGGO14+mnThALTKLe8bFmGgU5jdT0yXMrBSB4yPDZiTcIGGO14+mnThAKTKPe8bFmGgU5jdT0yXMrBSF4yPDZiTcIGGO14+mnThAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAK',
        urgent: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWm98OScTgwOUKXi7q1hGwU7k9j0zHcrBxl6yvLbjDgKGGS35+qkUBELTKXh8rZqHQU3jtT0ynUrBCB5yPLaiTkIGGO15+moUhILS6Xi8rRqHAU4jdPzyXQrBSF4yPDZiTgIGGS15+mnUREKTKLe8bJmGwQ4jdT0ynQrBSB4x/HZiDgIGGOz5einTxEKTKLe8bFmGgQ5jdP0yXMrBSF4yPDZiTcIGGO14+mnThALTKLe8bFmGgU5jdT0yXMrBSB4yPDZiTcIGGO14+mnThAKTKPe8bFmGgU5jdT0yXMrBSF4yPDZiTcIGGO14+mnThAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAKTKPe8rFmGgU5jtT0yXMrBSB4yPDZiTcIGGO14+mnTRAK'
      };

      const audio = new Audio(sounds[type] || sounds.normal);
      audio.volume = 0.5;
      audio.play().catch(err => console.log('Could not play sound:', err));
    } catch (error) {
      console.log('Error playing notification sound:', error);
    }
  }

  /**
   * Handle reconnection attempts
   */
  async handleReconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('❌ Max reconnection attempts reached');
      if (this.callbacks.onError) {
        this.callbacks.onError(new Error('Failed to reconnect to realtime updates'));
      }
      return;
    }

    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1); // Exponential backoff

    console.log(`🔄 Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`);

    setTimeout(() => {
      this.subscribe(this.appointmentId, this.callbacks);
    }, delay);
  }

  /**
   * Manually refresh queue position (fallback for non-realtime)
   */
  async refreshPosition() {
    if (!this.appointmentId) return null;

    try {
      const { data, error } = await supabase
        .rpc('get_appointment_status', {
          p_appointment_id: this.appointmentId
        });

      if (error) throw error;

      if (data && data.success && data.queue) {
        const positionData = {
          position: data.queue.position,
          estimatedTime: data.queue.estimated_time,
          status: data.queue.status,
          event: 'MANUAL_REFRESH'
        };

        if (this.callbacks.onPositionChange) {
          this.callbacks.onPositionChange(positionData);
        }

        return positionData;
      }
    } catch (error) {
      console.error('Error refreshing position:', error);
      return null;
    }
  }

  /**
   * Check connection status
   */
  isConnected() {
    return this.channel && this.channel.state === 'joined';
  }
}

// Create singleton instance
const realtimeQueue = new RealtimeQueueManager();

// Export both the class and singleton instance
export { RealtimeQueueManager, realtimeQueue };
export default realtimeQueue;
