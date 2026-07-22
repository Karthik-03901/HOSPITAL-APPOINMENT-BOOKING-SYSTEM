/**
 * Real-Time Queue Management using Supabase Realtime
 * Handles WebSocket connections for live updates
 */

import { supabase } from '../supabaseClient.js';
import { toast } from '../components/Toast.js';

class RealtimeQueueManager {
  constructor() {
    this.channel = null;
    this.appointmentId = null;
    this.callbacks = {
      onQueueUpdate: null,
      onPositionChange: null,
      onAppointmentCalled: null
    };
  }

  /**
   * Subscribe to queue updates for a specific appointment
   * @param {string} appointmentId - The appointment ID to track
   * @param {Object} callbacks - Callback functions for different events
   */
  async subscribe(appointmentId, callbacks = {}) {
    this.appointmentId = appointmentId;
    this.callbacks = { ...this.callbacks, ...callbacks };

    // Create a channel for this appointment
    this.channel = supabase
      .channel(`queue:${appointmentId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'appointments',
          filter: `id=eq.${appointmentId}`
        },
        (payload) => {
          this.handleAppointmentUpdate(payload);
        }
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'queue_positions',
          filter: `appointment_id=eq.${appointmentId}`
        },
        (payload) => {
          this.handleQueuePositionUpdate(payload);
        }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          console.log('✅ Connected to real-time queue updates');
          toast.success('Live queue tracking active');
        } else if (status === 'CHANNEL_ERROR') {
          console.error('❌ Failed to connect to real-time updates');
          toast.error('Failed to connect to live updates');
        }
      });

    // Fetch initial queue position
    await this.fetchCurrentPosition();
  }

  /**
   * Handle appointment status updates
   */
  handleAppointmentUpdate(payload) {
    console.log('Appointment updated:', payload.new);
    
    const { status, check_in_time } = payload.new;
    
    if (status === 'called' && this.callbacks.onAppointmentCalled) {
      this.callbacks.onAppointmentCalled(payload.new);
      
      // Show urgent notification
      toast.success('🔔 Your turn! Please proceed to the consultation room', 10000);
      
      // Browser notification
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('Your Turn - MediQueue', {
          body: 'Please proceed to the consultation room',
          icon: '/icons/icon-192x192.png',
          badge: '/icons/badge-72x72.png',
          requireInteraction: true
        });
      }
    }
    
    if (this.callbacks.onQueueUpdate) {
      this.callbacks.onQueueUpdate(payload.new);
    }
  }

  /**
   * Handle queue position updates
   */
  handleQueuePositionUpdate(payload) {
    console.log('Queue position updated:', payload.new);
    
    const { position, estimated_time } = payload.new;
    
    if (this.callbacks.onPositionChange) {
      this.callbacks.onPositionChange({
        position,
        estimatedTime: estimated_time,
        event: payload.eventType
      });
    }
    
    // Show notification for significant position changes
    if (position <= 3 && position > 0) {
      const messages = {
        3: '3 patients ahead. Get ready!',
        2: '2 patients ahead. Almost your turn!',
        1: 'Next in line! Please be ready.'
      };
      
      toast.info(`You are #${position}: ${messages[position]}`);
    }
  }

  /**
   * Fetch current queue position
   */
  async fetchCurrentPosition() {
    try {
      const { data, error } = await supabase
        .from('queue_positions')
        .select('position, estimated_time, status')
        .eq('appointment_id', this.appointmentId)
        .single();

      if (error) throw error;

      if (data && this.callbacks.onPositionChange) {
        this.callbacks.onPositionChange({
          position: data.position,
          estimatedTime: data.estimated_time,
          status: data.status,
          event: 'INITIAL'
        });
      }
    } catch (error) {
      console.error('Error fetching queue position:', error);
    }
  }

  /**
   * Unsubscribe from updates
   */
  unsubscribe() {
    if (this.channel) {
      supabase.removeChannel(this.channel);
      this.channel = null;
      console.log('Unsubscribed from queue updates');
    }
  }

  /**
   * Check in to the queue (patient has arrived)
   */
  async checkIn() {
    try {
      const { data, error } = await supabase
        .from('appointments')
        .update({
          check_in_time: new Date().toISOString(),
          status: 'checked_in'
        })
        .eq('id', this.appointmentId)
        .select()
        .single();

      if (error) throw error;

      toast.success('✅ Checked in successfully!');
      return data;
    } catch (error) {
      console.error('Check-in error:', error);
      toast.error('Failed to check in. Please try again.');
      throw error;
    }
  }
}

// Export singleton instance
export const realtimeQueue = new RealtimeQueueManager();

// Export class for multiple instances
export { RealtimeQueueManager };
