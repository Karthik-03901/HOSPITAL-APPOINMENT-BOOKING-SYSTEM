/**
 * Modal dialog system
 * Usage:
 *   import { Modal } from './components/Modal.js';
 *   const modal = new Modal({ title: 'Confirm', content: '...', onConfirm: () => {} });
 *   modal.open();
 */

export class Modal {
  constructor(options = {}) {
    this.options = {
      title: options.title || 'Dialog',
      content: options.content || '',
      showClose: options.showClose !== false,
      showCancel: options.showCancel !== false,
      confirmText: options.confirmText || 'Confirm',
      cancelText: options.cancelText || 'Cancel',
      confirmClass: options.confirmClass || 'btn-primary',
      size: options.size || 'md', // 'sm' | 'md' | 'lg' | 'xl'
      onConfirm: options.onConfirm || null,
      onCancel: options.onCancel || null,
      onClose: options.onClose || null
    };
    
    this.element = null;
    this.backdrop = null;
    this.isOpen = false;
  }
  
  /**
   * Create modal DOM
   */
  create() {
    if (this.element) return;
    
    // Backdrop
    this.backdrop = document.createElement('div');
    this.backdrop.className = 'modal-backdrop fixed inset-0 bg-navy-950/50 backdrop-blur-sm z-40 opacity-0 transition-opacity duration-300';
    
    // Modal container
    const container = document.createElement('div');
    container.className = 'modal-container fixed inset-0 z-50 flex items-center justify-center p-4 opacity-0 transition-opacity duration-300';
    
    // Modal
    const modal = document.createElement('div');
    modal.className = `
      modal-dialog
      bg-white rounded-xl shadow-2xl
      ${this.getSizeClass()}
      w-full
      transform scale-95 transition-transform duration-300
    `;
    
    modal.innerHTML = `
      <div class="modal-header flex items-center justify-between p-6 border-b border-slate-100">
        <h3 class="font-display text-lg font-semibold text-navy-900">${this.options.title}</h3>
        ${this.options.showClose ? `
          <button class="modal-close-btn text-slate-400 hover:text-navy-900 transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        ` : ''}
      </div>
      
      <div class="modal-body p-6">
        ${this.options.content}
      </div>
      
      <div class="modal-footer flex items-center justify-end gap-3 p-6 border-t border-slate-100">
        ${this.options.showCancel ? `
          <button class="modal-cancel-btn btn-secondary">${this.options.cancelText}</button>
        ` : ''}
        <button class="modal-confirm-btn ${this.options.confirmClass}">${this.options.confirmText}</button>
      </div>
    `;
    
    container.appendChild(modal);
    
    this.element = container;
    this.modal = modal;
    
    // Event listeners
    if (this.options.showClose) {
      modal.querySelector('.modal-close-btn').addEventListener('click', () => this.close());
    }
    
    if (this.options.showCancel) {
      modal.querySelector('.modal-cancel-btn').addEventListener('click', () => this.cancel());
    }
    
    modal.querySelector('.modal-confirm-btn').addEventListener('click', () => this.confirm());
    
    this.backdrop.addEventListener('click', () => this.close());
    
    // Prevent closing when clicking inside modal
    modal.addEventListener('click', (e) => e.stopPropagation());
  }
  
  /**
   * Get size class
   */
  getSizeClass() {
    const sizes = {
      sm: 'max-w-sm',
      md: 'max-w-md',
      lg: 'max-w-lg',
      xl: 'max-w-xl'
    };
    return sizes[this.options.size] || sizes.md;
  }
  
  /**
   * Open modal
   */
  open() {
    if (this.isOpen) return;
    
    this.create();
    document.body.appendChild(this.backdrop);
    document.body.appendChild(this.element);
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden';
    
    // Trigger animation
    requestAnimationFrame(() => {
      this.backdrop.classList.remove('opacity-0');
      this.element.classList.remove('opacity-0');
      this.modal.classList.remove('scale-95');
      this.modal.classList.add('scale-100');
    });
    
    this.isOpen = true;
  }
  
  /**
   * Close modal
   */
  close() {
    if (!this.isOpen) return;
    
    // Animate out
    this.backdrop.classList.add('opacity-0');
    this.element.classList.add('opacity-0');
    this.modal.classList.remove('scale-100');
    this.modal.classList.add('scale-95');
    
    setTimeout(() => {
      if (this.backdrop.parentNode) {
        this.backdrop.parentNode.removeChild(this.backdrop);
      }
      if (this.element.parentNode) {
        this.element.parentNode.removeChild(this.element);
      }
      
      // Restore body scroll
      document.body.style.overflow = '';
      
      if (this.options.onClose) {
        this.options.onClose();
      }
      
      this.isOpen = false;
    }, 300);
  }
  
  /**
   * Handle confirm
   */
  async confirm() {
    if (this.options.onConfirm) {
      const result = await this.options.onConfirm();
      if (result !== false) {
        this.close();
      }
    } else {
      this.close();
    }
  }
  
  /**
   * Handle cancel
   */
  cancel() {
    if (this.options.onCancel) {
      this.options.onCancel();
    }
    this.close();
  }
  
  /**
   * Update modal content
   */
  setContent(content) {
    if (this.modal) {
      this.modal.querySelector('.modal-body').innerHTML = content;
    }
  }
  
  /**
   * Set loading state
   */
  setLoading(isLoading) {
    if (!this.modal) return;
    
    const confirmBtn = this.modal.querySelector('.modal-confirm-btn');
    
    if (isLoading) {
      confirmBtn.disabled = true;
      confirmBtn.innerHTML = `
        <svg class="animate-spin h-4 w-4 inline-block mr-2" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Processing...
      `;
    } else {
      confirmBtn.disabled = false;
      confirmBtn.textContent = this.options.confirmText;
    }
  }
}

/**
 * Quick confirm dialog
 */
export function confirmDialog(message, title = 'Confirm Action') {
  return new Promise((resolve) => {
    const modal = new Modal({
      title,
      content: `<p class="text-sm text-slate-600">${message}</p>`,
      onConfirm: () => resolve(true),
      onCancel: () => resolve(false),
      onClose: () => resolve(false)
    });
    modal.open();
  });
}

/**
 * Alert dialog
 */
export function alertDialog(message, title = 'Notice') {
  return new Promise((resolve) => {
    const modal = new Modal({
      title,
      content: `<p class="text-sm text-slate-600">${message}</p>`,
      showCancel: false,
      onConfirm: () => resolve(true)
    });
    modal.open();
  });
}
