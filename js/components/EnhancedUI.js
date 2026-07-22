/**
 * Enhanced UI Components Library
 * Modern, accessible UI components inspired by shadcn/ui and Radix UI
 * Pure vanilla JavaScript implementation
 */

// =====================================================
// DIALOG/MODAL COMPONENT
// =====================================================

export class Dialog {
  constructor(options = {}) {
    this.options = {
      title: options.title || '',
      description: options.description || '',
      content: options.content || '',
      footer: options.footer || null,
      onClose: options.onClose || null,
      closeOnOverlay: options.closeOnOverlay !== false,
      closeOnEscape: options.closeOnEscape !== false,
      ...options
    };
    
    this.overlay = null;
    this.dialog = null;
    this.isOpen = false;
  }
  
  open() {
    if (this.isOpen) return;
    
    // Create overlay
    this.overlay = document.createElement('div');
    this.overlay.className = 'dialog-overlay';
    this.overlay.setAttribute('data-state', 'open');
    
    // Create dialog
    this.dialog = document.createElement('div');
    this.dialog.className = 'dialog-content';
    this.dialog.setAttribute('data-state', 'open');
    this.dialog.setAttribute('role', 'dialog');
    this.dialog.setAttribute('aria-modal', 'true');
    
    // Build dialog content
    let dialogHTML = '<div class="dialog-header">';
    if (this.options.title) {
      dialogHTML += `<h2 class="dialog-title">${this.options.title}</h2>`;
    }
    if (this.options.description) {
      dialogHTML += `<p class="dialog-description">${this.options.description}</p>`;
    }
    dialogHTML += '</div>';
    
    dialogHTML += `<div class="dialog-body p-6">${this.options.content}</div>`;
    
    if (this.options.footer) {
      dialogHTML += `<div class="dialog-footer">${this.options.footer}</div>`;
    }
    
    // Close button
    dialogHTML += `
      <button class="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-white transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:ring-offset-2 disabled:pointer-events-none" data-dialog-close>
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
        <span class="sr-only">Close</span>
      </button>
    `;
    
    this.dialog.innerHTML = dialogHTML;
    
    // Add to DOM
    document.body.appendChild(this.overlay);
    document.body.appendChild(this.dialog);
    document.body.style.overflow = 'hidden';
    
    // Event listeners
    if (this.options.closeOnOverlay) {
      this.overlay.addEventListener('click', () => this.close());
    }
    
    if (this.options.closeOnEscape) {
      document.addEventListener('keydown', this.handleEscape);
    }
    
    // Close button
    const closeBtn = this.dialog.querySelector('[data-dialog-close]');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => this.close());
    }
    
    this.isOpen = true;
  }
  
  close() {
    if (!this.isOpen) return;
    
    this.overlay?.setAttribute('data-state', 'closed');
    this.dialog?.setAttribute('data-state', 'closed');
    
    setTimeout(() => {
      this.overlay?.remove();
      this.dialog?.remove();
      document.body.style.overflow = '';
      
      if (this.options.onClose) {
        this.options.onClose();
      }
    }, 200);
    
    document.removeEventListener('keydown', this.handleEscape);
    this.isOpen = false;
  }
  
  handleEscape = (e) => {
    if (e.key === 'Escape') {
      this.close();
    }
  };
}

// =====================================================
// TOAST NOTIFICATION COMPONENT
// =====================================================

export class Toast {
  static container = null;
  static toasts = [];
  
  static init() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'fixed top-4 right-4 z-[100] flex flex-col gap-3 max-w-md';
      this.container.setAttribute('aria-live', 'polite');
      this.container.setAttribute('aria-atomic', 'true');
      document.body.appendChild(this.container);
    }
  }
  
  static show(message, type = 'info', duration = 3000) {
    this.init();
    
    const id = Date.now() + Math.random();
    
    const toast = document.createElement('div');
    toast.className = `toast-${type} animate-slide-down`;
    toast.setAttribute('data-toast-id', id);
    
    const icons = {
      success: `<svg class="h-5 w-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      error: `<svg class="h-5 w-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      warning: `<svg class="h-5 w-5 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>`,
      info: `<svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`
    };
    
    toast.innerHTML = `
      <div class="flex p-4">
        <div class="flex-shrink-0">
          ${icons[type]}
        </div>
        <div class="ml-3 flex-1 pt-0.5">
          <p class="text-sm font-medium text-slate-900">${message}</p>
        </div>
        <div class="ml-4 flex flex-shrink-0">
          <button class="inline-flex rounded-md text-slate-400 hover:text-slate-500 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:ring-offset-2" data-toast-close="${id}">
            <span class="sr-only">Close</span>
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>
    `;
    
    this.container.appendChild(toast);
    this.toasts.push({ id, element: toast });
    
    // Close button
    const closeBtn = toast.querySelector(`[data-toast-close="${id}"]`);
    closeBtn.addEventListener('click', () => this.dismiss(id));
    
    // Auto dismiss
    if (duration > 0) {
      setTimeout(() => this.dismiss(id), duration);
    }
    
    return id;
  }
  
  static dismiss(id) {
    const toastData = this.toasts.find(t => t.id === id);
    if (!toastData) return;
    
    toastData.element.style.animation = 'slide-up 0.3s ease-out forwards';
    toastData.element.style.opacity = '0';
    
    setTimeout(() => {
      toastData.element.remove();
      this.toasts = this.toasts.filter(t => t.id !== id);
    }, 300);
  }
  
  static success(message, duration) {
    return this.show(message, 'success', duration);
  }
  
  static error(message, duration) {
    return this.show(message, 'error', duration);
  }
  
  static warning(message, duration) {
    return this.show(message, 'warning', duration);
  }
  
  static info(message, duration) {
    return this.show(message, 'info', duration);
  }
}

// =====================================================
// LOADING COMPONENT
// =====================================================

export class Loading {
  static overlay = null;
  
  static show(message = 'Loading...') {
    if (this.overlay) return;
    
    this.overlay = document.createElement('div');
    this.overlay.className = 'fixed inset-0 z-[200] flex items-center justify-center bg-black/50 backdrop-blur-sm';
    
    this.overlay.innerHTML = `
      <div class="bg-white rounded-xl p-8 shadow-2xl flex flex-col items-center gap-4 min-w-[200px] animate-scale-in">
        <div class="relative">
          <div class="w-16 h-16 border-4 border-slate-200 rounded-full"></div>
          <div class="absolute top-0 left-0 w-16 h-16 border-4 border-teal-500 rounded-full border-t-transparent animate-spin"></div>
        </div>
        <p class="text-sm font-medium text-slate-900">${message}</p>
      </div>
    `;
    
    document.body.appendChild(this.overlay);
    document.body.style.overflow = 'hidden';
  }
  
  static hide() {
    if (!this.overlay) return;
    
    this.overlay.style.opacity = '0';
    setTimeout(() => {
      this.overlay?.remove();
      this.overlay = null;
      document.body.style.overflow = '';
    }, 200);
  }
}

// =====================================================
// ACCORDION COMPONENT
// =====================================================

export class Accordion {
  constructor(element, options = {}) {
    this.element = element;
    this.options = {
      allowMultiple: options.allowMultiple || false,
      ...options
    };
    
    this.items = Array.from(element.querySelectorAll('[data-accordion-item]'));
    this.init();
  }
  
  init() {
    this.items.forEach((item, index) => {
      const trigger = item.querySelector('[data-accordion-trigger]');
      const content = item.querySelector('[data-accordion-content]');
      
      if (!trigger || !content) return;
      
      trigger.addEventListener('click', () => {
        const isOpen = item.getAttribute('data-state') === 'open';
        
        if (!this.options.allowMultiple) {
          // Close all other items
          this.items.forEach(otherItem => {
            if (otherItem !== item) {
              this.close(otherItem);
            }
          });
        }
        
        if (isOpen) {
          this.close(item);
        } else {
          this.open(item);
        }
      });
    });
  }
  
  open(item) {
    const content = item.querySelector('[data-accordion-content]');
    item.setAttribute('data-state', 'open');
    content.style.height = content.scrollHeight + 'px';
  }
  
  close(item) {
    const content = item.querySelector('[data-accordion-content]');
    item.setAttribute('data-state', 'closed');
    content.style.height = '0px';
  }
}

// =====================================================
// TABS COMPONENT
// =====================================================

export class Tabs {
  constructor(element) {
    this.element = element;
    this.triggers = Array.from(element.querySelectorAll('[data-tabs-trigger]'));
    this.panels = Array.from(element.querySelectorAll('[data-tabs-content]'));
    
    this.init();
  }
  
  init() {
    this.triggers.forEach(trigger => {
      trigger.addEventListener('click', () => {
        const value = trigger.getAttribute('data-tabs-trigger');
        this.setActive(value);
      });
    });
    
    // Set first tab as active
    if (this.triggers.length > 0) {
      const firstValue = this.triggers[0].getAttribute('data-tabs-trigger');
      this.setActive(firstValue);
    }
  }
  
  setActive(value) {
    // Update triggers
    this.triggers.forEach(trigger => {
      if (trigger.getAttribute('data-tabs-trigger') === value) {
        trigger.setAttribute('data-state', 'active');
        trigger.classList.add('bg-white', 'text-slate-900', 'shadow-sm');
      } else {
        trigger.setAttribute('data-state', 'inactive');
        trigger.classList.remove('bg-white', 'text-slate-900', 'shadow-sm');
      }
    });
    
    // Update panels
    this.panels.forEach(panel => {
      if (panel.getAttribute('data-tabs-content') === value) {
        panel.setAttribute('data-state', 'active');
        panel.classList.remove('hidden');
      } else {
        panel.setAttribute('data-state', 'inactive');
        panel.classList.add('hidden');
      }
    });
  }
}

// =====================================================
// DROPDOWN COMPONENT
// =====================================================

export class Dropdown {
  constructor(trigger, menu, options = {}) {
    this.trigger = trigger;
    this.menu = menu;
    this.options = {
      placement: options.placement || 'bottom-end',
      closeOnClick: options.closeOnClick !== false,
      ...options
    };
    
    this.isOpen = false;
    this.init();
  }
  
  init() {
    this.trigger.addEventListener('click', (e) => {
      e.stopPropagation();
      this.toggle();
    });
    
    document.addEventListener('click', (e) => {
      if (!this.menu.contains(e.target) && !this.trigger.contains(e.target)) {
        this.close();
      }
    });
    
    if (this.options.closeOnClick) {
      this.menu.addEventListener('click', () => {
        this.close();
      });
    }
  }
  
  open() {
    if (this.isOpen) return;
    
    this.menu.setAttribute('data-state', 'open');
    this.menu.classList.remove('hidden');
    this.position();
    this.isOpen = true;
  }
  
  close() {
    if (!this.isOpen) return;
    
    this.menu.setAttribute('data-state', 'closed');
    setTimeout(() => {
      this.menu.classList.add('hidden');
    }, 200);
    this.isOpen = false;
  }
  
  toggle() {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }
  
  position() {
    const triggerRect = this.trigger.getBoundingClientRect();
    const menuRect = this.menu.getBoundingClientRect();
    
    // Simple positioning (can be enhanced)
    this.menu.style.position = 'absolute';
    this.menu.style.top = (triggerRect.bottom + 8) + 'px';
    this.menu.style.right = (window.innerWidth - triggerRect.right) + 'px';
  }
}

// =====================================================
// FORM VALIDATION
// =====================================================

export class FormValidator {
  constructor(form) {
    this.form = form;
    this.fields = new Map();
  }
  
  addField(name, rules) {
    this.fields.set(name, rules);
  }
  
  validate() {
    let isValid = true;
    const errors = {};
    
    this.fields.forEach((rules, fieldName) => {
      const field = this.form.querySelector(`[name="${fieldName}"]`);
      if (!field) return;
      
      const value = field.value.trim();
      const fieldErrors = [];
      
      // Required validation
      if (rules.required && !value) {
        fieldErrors.push(rules.required.message || 'This field is required');
      }
      
      // Min length validation
      if (rules.minLength && value.length < rules.minLength.value) {
        fieldErrors.push(rules.minLength.message || `Minimum ${rules.minLength.value} characters required`);
      }
      
      // Max length validation
      if (rules.maxLength && value.length > rules.maxLength.value) {
        fieldErrors.push(rules.maxLength.message || `Maximum ${rules.maxLength.value} characters allowed`);
      }
      
      // Email validation
      if (rules.email && value) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(value)) {
          fieldErrors.push(rules.email.message || 'Invalid email address');
        }
      }
      
      // Pattern validation
      if (rules.pattern && value) {
        if (!rules.pattern.value.test(value)) {
          fieldErrors.push(rules.pattern.message || 'Invalid format');
        }
      }
      
      // Custom validation
      if (rules.custom && value) {
        const customError = rules.custom(value);
        if (customError) {
          fieldErrors.push(customError);
        }
      }
      
      if (fieldErrors.length > 0) {
        isValid = false;
        errors[fieldName] = fieldErrors;
        this.showFieldError(field, fieldErrors[0]);
      } else {
        this.clearFieldError(field);
      }
    });
    
    return { isValid, errors };
  }
  
  showFieldError(field, message) {
    field.classList.add('input-error');
    
    let errorElement = field.parentElement.querySelector('.field-error');
    if (!errorElement) {
      errorElement = document.createElement('p');
      errorElement.className = 'field-error text-xs text-red-600 mt-1';
      field.parentElement.appendChild(errorElement);
    }
    errorElement.textContent = message;
  }
  
  clearFieldError(field) {
    field.classList.remove('input-error');
    const errorElement = field.parentElement.querySelector('.field-error');
    if (errorElement) {
      errorElement.remove();
    }
  }
  
  clearAll() {
    this.fields.forEach((rules, fieldName) => {
      const field = this.form.querySelector(`[name="${fieldName}"]`);
      if (field) {
        this.clearFieldError(field);
      }
    });
  }
}

// Export default object with all components
export default {
  Dialog,
  Toast,
  Loading,
  Accordion,
  Tabs,
  Dropdown,
  FormValidator
};
