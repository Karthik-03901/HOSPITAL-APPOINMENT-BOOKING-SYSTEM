# 🎨 Quick UI Reference Card

## 🚀 Setup (Copy-Paste)

```html
<!-- Add to <head> -->
<link rel="stylesheet" href="../css/enhanced-ui.css" />

<!-- Add to JavaScript -->
<script type="module">
import { Dialog, Toast, Loading } from '../components/EnhancedUI.js';
</script>
```

---

## 📋 Most Used Components

### Buttons
```html
<button class="btn-default">Primary</button>
<button class="btn-outline">Secondary</button>
<button class="btn-ghost-new">Ghost</button>
<button class="btn-destructive">Delete</button>
```

### Cards
```html
<div class="card-modern p-6">
  <h3 class="card-title">Title</h3>
  <p class="card-description">Description</p>
</div>
```

### Inputs
```html
<input type="text" class="input-modern" placeholder="Enter text..." />
```

### Badges
```html
<span class="badge-success">Active</span>
<span class="badge-warning">Pending</span>
<span class="badge-error">Failed</span>
```

### Alerts
```html
<div class="alert-success">
  <h4 class="alert-title">Success!</h4>
  <p class="alert-description">Action completed.</p>
</div>
```

---

## 💻 JavaScript Quick Reference

### Toast
```javascript
Toast.success('Saved!');
Toast.error('Failed!');
Toast.warning('Check this');
Toast.info('FYI');
```

### Loading
```javascript
Loading.show('Processing...');
Loading.hide();
```

### Dialog
```javascript
const dialog = new Dialog({
  title: 'Confirm',
  content: 'Are you sure?',
  footer: '<button class="btn-default">OK</button>'
});
dialog.open();
```

---

## 🎨 Quick Styling

### Hover Lift
```html
<div class="hover-lift">Rises on hover</div>
```

### Glass Effect
```html
<div class="glass-modern p-6">Glass card</div>
```

### Gradient Text
```html
<h1 class="text-gradient-primary">Gradient</h1>
```

---

## 📊 Sizes

### Buttons
- `btn-sm` - Small
- (default) - Medium  
- `btn-lg` - Large
- `btn-xl` - Extra Large

### Progress Bars
- `progress-bar-sm` - Thin
- (default) - Medium
- `progress-bar-lg` - Thick

---

## 🎯 Common Patterns

### Form
```html
<div class="card-modern p-6">
  <div class="card-header">
    <h3 class="card-title">Form Title</h3>
  </div>
  <div class="card-content space-y-4">
    <input type="text" class="input-modern" />
    <input type="email" class="input-modern" />
  </div>
  <div class="card-footer">
    <button class="btn-outline">Cancel</button>
    <button class="btn-default">Submit</button>
  </div>
</div>
```

### Success Message
```javascript
Loading.show('Saving...');
await saveData();
Loading.hide();
Toast.success('Saved successfully!');
```

### Confirmation Dialog
```javascript
const dialog = new Dialog({
  title: 'Delete Appointment?',
  description: 'This action cannot be undone.',
  footer: `
    <button class="btn-outline" onclick="dialog.close()">Cancel</button>
    <button class="btn-destructive" onclick="deleteItem()">Delete</button>
  `
});
dialog.open();
```

---

## 🔗 Quick Links

- **Full Guide:** `UI_ENHANCEMENT_GUIDE.md`
- **Demo Page:** `ui-components-demo.html`
- **CSS File:** `css/enhanced-ui.css`
- **JS Library:** `js/components/EnhancedUI.js`
