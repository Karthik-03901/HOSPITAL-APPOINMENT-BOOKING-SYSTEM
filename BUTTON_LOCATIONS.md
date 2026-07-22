# 🎯 Smart Routing Button Locations

## Visual Guide to Button Locations

```
┌─────────────────────────────────────────────────────────────────┐
│                         NAVIGATION BAR                          │
│  MediQueue  [Home] [Profile] [Dashboard] [Sign In] [Book Now]  │ ← Button #2
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        HERO SECTION                             │
│                                                                 │
│   Healthcare                                                    │
│   reimagined                                                    │
│                                                                 │
│   Next-generation hospital management with AI-powered...       │
│                                                                 │
│   [Start Free Trial] [Watch Demo]                              │ ← Button #1
│   ↑                                                             │
│   Button #1: "Start Free Trial"                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     HOW IT WORKS SECTION                        │
│                                                                 │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐          │
│  │     [1]     │   │     [2]     │   │     [3]     │          │
│  │   Create    │   │    Book     │   │  Track Live │          │
│  │   Account   │   │ Appointment │   │             │          │
│  │             │   │             │   │ [Track Now] │ ← Button #3
│  └─────────────┘   └─────────────┘   └─────────────┘          │
│                                            ↑                    │
│                                    Button #3: "Track Now"       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Button Details

### Button #1: "Start Free Trial"
- **Location:** Hero Section (top of page)
- **HTML ID:** `btn-create-account`
- **Visual:** Large primary button (teal background)
- **Text:** "Start Free Trial"
- **Icon:** Right arrow →

### Button #2: "Book Now"
- **Location:** Navigation Bar (top right)
- **HTML ID:** `btn-book-appointment`
- **Visual:** Primary button in navbar (teal background)
- **Text:** "Book Now"
- **Icon:** None

### Button #3: "Track Now"
- **Location:** How It Works Section, Step 3
- **HTML ID:** `btn-track-live`
- **Visual:** Secondary button (teal border, transparent background)
- **Text:** "Track Now"
- **Icon:** Eye icon 👁️

---

## HTML Structure

### Button #1 - Start Free Trial
```html
<a href="#login" id="btn-create-account" class="btn-primary text-base py-4 px-8">
  Start Free Trial
  <svg>...</svg>
</a>
```

### Button #2 - Book Now
```html
<a href="./pages/book-appointment.html" id="btn-book-appointment" class="btn-primary">
  Book Now
</a>
```

### Button #3 - Track Now
```html
<a href="#track-live" id="btn-track-live" class="inline-flex items-center gap-2 px-6 py-3 rounded-lg bg-teal-500/20 text-teal-300 border border-teal-400/30">
  <svg>...</svg>
  Track Now
</a>
```

---

## Page Layout

```
┌──────────────────────────────────────────┐
│         NAVIGATION (fixed top)           │
│         Contains: Button #2              │
├──────────────────────────────────────────┤
│                                          │
│         HERO SECTION                     │
│         Contains: Button #1              │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│         FEATURES SECTION                 │
│         (no smart routing buttons)       │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│         HOW IT WORKS SECTION             │
│         Contains: Button #3              │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│         TESTIMONIALS                     │
│         (no smart routing buttons)       │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│         PRICING                          │
│         (no smart routing buttons)       │
│                                          │
└──────────────────────────────────────────┘
```

---

## CSS Classes Used

### Primary Button Style
```css
.btn-primary {
  background: linear-gradient(to right, teal-500, teal-600);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: 600;
  transition: all 0.3s;
}
```

### Secondary Button Style (Track Now)
```css
background: teal-500/20 (semi-transparent)
color: teal-300
border: teal-400/30
padding: 0.75rem 1.5rem
border-radius: 0.5rem
```

---

## Button States

### Default State
- Normal appearance
- Hover: Slight scale transform
- Cursor: pointer

### Click State
- Prevents default link behavior
- Runs JavaScript logic
- Shows loading indicator (optional)

### After Click
- May show toast notification
- Redirects to appropriate page
- May store intended destination

---

## Accessibility

All buttons include:
- ✅ Semantic HTML (`<a>` tags)
- ✅ Descriptive text
- ✅ Clear visual feedback
- ✅ Keyboard accessible
- ✅ Touch-friendly size
- ✅ Screen reader compatible

---

## Mobile Responsiveness

### Desktop (> 768px)
- Button #1: Full size, side-by-side with "Watch Demo"
- Button #2: Visible in navbar
- Button #3: Full size in How It Works

### Mobile (< 768px)
- Button #1: Stacked vertically
- Button #2: Hidden (mobile menu)
- Button #3: Full width, centered

---

## Color Scheme

- **Primary:** Teal (#14B8A6)
- **Primary Dark:** Teal (#0D9488)
- **Text on Primary:** White (#FFFFFF)
- **Border:** Teal/30 (30% opacity)
- **Background:** Teal/20 (20% opacity)

---

## Testing in Browser

### To Test Button Locations:
1. Open `index.html` in browser
2. Look for navigation bar → Find "Book Now" (Button #2)
3. Scroll to hero section → Find "Start Free Trial" (Button #1)
4. Scroll down to "How It Works" → Find "Track Now" in Step 3 (Button #3)

### Visual Confirmation:
- All buttons should have smooth hover effects
- All buttons should be clickable
- Check browser console for initialization log:
  ```
  Smart routing initialized: { 
    createAccount: true, 
    bookAppointment: true, 
    trackLive: true 
  }
  ```

---

## Quick Find

**Need to find buttons in code?**

```bash
# Search for button IDs
grep -r "btn-create-account" .
grep -r "btn-book-appointment" .
grep -r "btn-track-live" .

# Search for smart routing script
grep -r "smart-routing.js" .
```

**In VS Code:**
- Press `Ctrl+P` → Type `index.html` → Enter
- Press `Ctrl+F` → Search for button IDs
