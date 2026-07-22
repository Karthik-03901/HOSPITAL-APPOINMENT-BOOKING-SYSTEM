/**
 * Demo Queue Simulator
 * Simulates real-time queue updates for testing without Supabase
 * Remove this in production and use actual Supabase realtime
 */

export class DemoQueueSimulator {
  constructor() {
    this.position = 5;
    this.interval = null;
    this.callbacks = {};
  }

  /**
   * Start simulating queue updates
   */
  start(callbacks = {}) {
    this.callbacks = callbacks;
    
    console.log('🎬 Demo Queue Simulator Started');
    console.log('Position will decrease every 30 seconds');
    
    // Initial position
    this.notifyPositionChange();
    
    // Update every 30 seconds
    this.interval = setInterval(() => {
      if (this.position > 0) {
        this.position--;
        this.notifyPositionChange();
        
        if (this.position === 0) {
          this.notifyAppointmentCalled();
          this.stop();
        }
      }
    }, 30000); // 30 seconds
  }

  /**
   * Stop simulation
   */
  stop() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
      console.log('🛑 Demo Queue Simulator Stopped');
    }
  }

  /**
   * Manually advance queue (for testing)
   */
  advance() {
    if (this.position > 0) {
      this.position--;
      this.notifyPositionChange();
      
      if (this.position === 0) {
        this.notifyAppointmentCalled();
      }
    }
  }

  /**
   * Notify position change
   */
  notifyPositionChange() {
    if (this.callbacks.onPositionChange) {
      const estimatedMinutes = this.position * 15;
      const estimatedTime = new Date(Date.now() + estimatedMinutes * 60000).toISOString();
      
      this.callbacks.onPositionChange({
        position: this.position,
        estimatedTime,
        status: this.position === 0 ? 'called' : 'waiting',
        event: 'UPDATE'
      });
    }
  }

  /**
   * Notify appointment called
   */
  notifyAppointmentCalled() {
    if (this.callbacks.onAppointmentCalled) {
      this.callbacks.onAppointmentCalled({
        status: 'called',
        called_at: new Date().toISOString()
      });
    }
  }
}

// Add button to manually advance queue (for testing)
export function addDemoControls() {
  const controls = document.createElement('div');
  controls.className = 'fixed bottom-4 right-4 z-50';
  controls.innerHTML = `
    <div class="bg-purple-600 text-white p-4 rounded-lg shadow-lg">
      <p class="text-xs font-bold mb-2">🎬 DEMO MODE</p>
      <button 
        id="demo-advance-btn" 
        class="px-4 py-2 bg-white text-purple-600 rounded font-semibold text-sm hover:bg-purple-50"
      >
        ⏭️ Advance Queue
      </button>
      <p class="text-xs mt-2 opacity-75">Click to move up in queue</p>
    </div>
  `;
  
  document.body.appendChild(controls);
  
  return controls;
}
