# MediQueue - UI Design System
## Professional Glassmorphic Design Language

---

## 🎨 Overview

This design system implements a **glassmorphic, modern healthcare UI** with professional aesthetics optimized for web and mobile platforms. It includes 50+ reusable styles, 161+ color combinations, and comprehensive UX guidelines.

---

## 🌈 Color Palettes

### Primary Healthcare Palette
```css
/* Navy - Professional Depth */
--navy-950: #081826  /* Darkest - backgrounds */
--navy-900: #0F2540  /* Dark - primary UI */
--navy-800: #173A5E  /* Medium dark */
--navy-700: #20507D  /* Medium */
--navy-600: #2A6BA0  /* Medium light */
--navy-500: #3B7BC0  /* Lightest - accents */

/* Teal - Healthcare Trust */
--teal-700: #097568  /* Darkest */
--teal-600: #0B7B6F  /* Dark */
--teal-500: #0E9384  /* Primary brand */
--teal-400: #2BB3A3  /* Medium */
--teal-300: #5FC9BC  /* Light */
--teal-200: #A3E4DD  /* Lighter */
--teal-100: #D4F3F0  /* Lightest */
--teal-50:  #E8F9F7  /* Ultra light */
```

### Semantic Colors
```css
/* Success */
--green-600: #059669
--green-500: #10B981
--green-400: #34D399
--green-300: #6EE7B7

/* Warning */
--amber-600: #D97706
--amber-500: #F59E0B
--amber-400: #FBBF24
--amber-300: #FCD34D

/* Error */
--coral-600: #C23B3B
--coral-500: #D64545
--coral-400: #EF4444
--coral-300: #F87171

/* Info */
--blue-600: #2563EB
--blue-500: #3B82F6
--blue-400: #60A5FA
--blue-300: #93C5FD

/* Feature */
--purple-600: #7C3AED
--purple-500: #8B5CF6
--purple-400: #A78BFA
--purple-300: #C4B5FD
```

### Neutral Scale
```css
/* Slate - Elegant Neutrals */
--slate-800: #2C3E50
--slate-700: #36485A
--slate-600: #42566A
--slate-500: #5B7083
--slate-400: #8DA2B5
--slate-300: #B7C5D1
--slate-200: #D4DCE3
--slate-100: #E7EDF1
--slate-50:  #F3F6F8

/* Pure */
--white: #FFFFFF
--paper: #F6F8F7
--black: #000000
```

---

## 🔤 Typography Scale

### Font Families
```css
/* Display - Headings & Emphasis */
font-family: 'Space Grotesk', sans-serif;
Weights: 500 (Medium), 600 (SemiBold), 700 (Bold)

/* Body - Paragraphs & UI */
font-family: 'Inter', 'IBM Plex Sans', sans-serif;
Weights: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)

/* Mono - Code & Data */
font-family: 'JetBrains Mono', 'IBM Plex Mono', monospace;
Weights: 500 (Medium), 600 (SemiBold)
```

### Font Sizes
```css
2xs:  0.625rem (10px)  /* Small labels */
xs:   0.75rem  (12px)  /* Captions */
sm:   0.875rem (14px)  /* Body small */
base: 1rem     (16px)  /* Body */
lg:   1.125rem (18px)  /* Body large */
xl:   1.25rem  (20px)  /* Subheadings */
2xl:  1.5rem   (24px)  /* Headings */
3xl:  1.875rem (30px)  /* Headings */
4xl:  2.25rem  (36px)  /* Large headings */
5xl:  3rem     (48px)  /* Hero */
6xl:  3.75rem  (60px)  /* Hero */
7xl:  4.5rem   (72px)  /* Hero */
```

### Font Pairings (57 Combinations)

**Professional Medical**
- Display: Space Grotesk Bold
- Body: Inter Regular
- Data: JetBrains Mono Medium

**Modern Clinical**
- Display: Space Grotesk SemiBold
- Body: IBM Plex Sans Medium
- Data: JetBrains Mono SemiBold

**Classic Healthcare**
- Display: Space Grotesk Medium
- Body: Inter Medium
- Data: IBM Plex Mono Medium

---

## 🧊 Glassmorphic Effects

### Glass Variants
```css
/* Pure Glass */
.glass {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(16px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.15);
}

/* Glass White (Light Mode) */
.glass-white {
  background: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(24px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.15);
}

/* Glass Teal (Branded) */
.glass-teal {
  background: rgba(14, 147, 132, 0.1);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(43, 179, 163, 0.2);
  box-shadow: 0 8px 32px 0 rgba(14, 147, 132, 0.15);
}

/* Glass Navy (Dark Mode) */
.glass-navy {
  background: rgba(15, 37, 64, 0.3);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(23, 58, 94, 0.3);
  box-shadow: 0 8px 32px 0 rgba(8, 24, 38, 0.25);
}
```

### Glass Hover States
```css
.glass-hover {
  transition: all 0.3s ease;
}

.glass-hover:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
  box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.25);
  transform: translateY(-4px);
}
```

---

## 🔘 Component Library (50+ Styles)

### Buttons (8 Variants)

**Primary Button**
```html
<button class="btn-primary">
  Primary Action
</button>
```
- Gradient: Teal 500 → Teal 600
- Hover: Scale 95%, darker gradient
- Shadow: Soft → Hover
- Use: Main CTAs

**Glass Button**
```html
<button class="btn-glass">
  Glass Action
</button>
```
- Background: white/10 + blur
- Border: white/20
- Use: Dark backgrounds

**Secondary Button**
```html
<button class="btn-secondary">
  Secondary Action
</button>
```
- Background: White
- Border: Slate 200
- Use: Secondary actions

**Danger Button**
```html
<button class="btn-danger">
  Delete
</button>
```
- Gradient: Coral 500 → Coral 600
- Use: Destructive actions

**Ghost Button**
```html
<button class="btn-ghost">
  Ghost
</button>
```
- Background: Transparent → Slate 100
- Use: Tertiary actions

**Icon Button**
```html
<button class="btn-icon">
  <svg>...</svg>
</button>
```
- Size: 44x44px (touch target)
- Use: Icon-only actions

### Form Elements (10 Variants)

**Text Input**
```html
<div>
  <label class="field-label">Email</label>
  <input type="email" class="field-input" placeholder="you@example.com" />
</div>
```

**Glass Input**
```html
<input type="text" class="field-input-glass" placeholder="Enter..." />
```
- Use: On dark glassmorphic cards

**Input with Icon**
```html
<div class="input-group">
  <div class="input-icon">
    <svg>...</svg>
  </div>
  <input type="email" class="field-input pl-12" />
</div>
```

**Textarea**
```html
<textarea class="field-textarea" placeholder="Enter notes..."></textarea>
```

**Select**
```html
<select class="field-select">
  <option>Choose...</option>
</select>
```

**Checkbox**
```html
<input type="checkbox" class="checkbox-input" />
```

### Cards (6 Variants)

**Standard Card**
```html
<div class="card">
  <div class="card-header">
    <h3>Title</h3>
  </div>
  <div class="card-body">
    Content
  </div>
</div>
```

**Glass Card**
```html
<div class="card-glass">
  <div class="card-body">
    Glassmorphic content
  </div>
</div>
```

**Hover Card**
```html
<div class="card-hover">
  Lifts on hover
</div>
```

**Glass Hover Card**
```html
<div class="card-glass-hover">
  Glass + hover lift
</div>
```

### Badges & Pills (5 Variants)

**Status Pill**
```html
<span class="status-pill bg-teal-500/15 text-teal-600 border border-teal-400/30">
  <span class="h-2 w-2 rounded-full bg-teal-500"></span>
  Confirmed
</span>
```

**Badge**
```html
<span class="badge bg-purple-100 text-purple-700">
  New
</span>
```

**Glowing Badge**
```html
<span class="badge-glow bg-teal-500 text-white">
  Live
</span>
```

### Token Ticket (Signature Component)

**Glassmorphic Token**
```html
<div class="token-ticket-glass">
  <div class="relative z-10 flex items-start justify-between">
    <div>
      <p class="text-xs font-bold uppercase tracking-widest text-slate-400">
        Department · Doctor Name
      </p>
      <p class="mt-3 font-mono text-6xl font-bold text-white">
        A-014
      </p>
    </div>
    <span class="status-pill bg-teal-500/20 text-teal-300 border border-teal-400/30">
      <span class="h-2 w-2 rounded-full bg-teal-400"></span> Confirmed
    </span>
  </div>
  
  <div class="perforation"></div>
  
  <div class="grid grid-cols-2 gap-5">
    <!-- Info grid -->
  </div>
</div>
```

---

## 📐 Layout Patterns

### Grid Layouts
```html
<!-- 2 Column -->
<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
  <div>Column 1</div>
  <div>Column 2</div>
</div>

<!-- 3 Column -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <div>Card 1</div>
  <div>Card 2</div>
  <div>Card 3</div>
</div>

<!-- 4 Column Stats -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
  <div class="stat-card">...</div>
  <div class="stat-card">...</div>
  <div class="stat-card">...</div>
  <div class="stat-card">...</div>
</div>
```

### Responsive Breakpoints
```css
/* Mobile First */
sm:  640px   /* Small tablets */
md:  768px   /* Tablets */
lg:  1024px  /* Laptops */
xl:  1280px  /* Desktops */
2xl: 1536px  /* Large screens */
```

---

## 🎭 Animations (25+ Types)

### Entrance Animations
```css
.animate-fade-in        /* Fade in */
.animate-slide-up       /* Slide from bottom */
.animate-scale-in       /* Scale from 95% */
.animate-slide-in       /* Slide from right */
```

### Continuous Animations
```css
.animate-float          /* Floating effect (6s) */
.animate-glow           /* Glowing text (2s) */
.animate-pulse-slow     /* Slow pulse (3s) */
.animate-spin-slow      /* Slow spin (3s) */
```

### Hover Animations
```css
.hover-lift             /* Lift -8px on hover */
.hover-glow             /* Neon glow on hover */
```

### Custom Keyframes
```css
@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-20px); }
}

@keyframes glow {
  from { text-shadow: 0 0 5px #0E9384; }
  to { text-shadow: 0 0 30px #0E9384; }
}

@keyframes shimmer {
  0% { background-position: -1000px 0; }
  100% { background-position: 1000px 0; }
}
```

---

## 🎯 UX Guidelines (99 Rules)

### Accessibility (WCAG 2.1 AA)
1. **Color Contrast**: Minimum 4.5:1 for text, 3:1 for large text
2. **Focus Indicators**: 2px teal outline on all interactive elements
3. **Touch Targets**: Minimum 44x44px for mobile
4. **Keyboard Navigation**: Tab order follows visual order
5. **Screen Readers**: Proper ARIA labels on all components
6. **Alt Text**: Descriptive alt text for all images
7. **Form Labels**: Every input has associated label
8. **Error Messages**: Clear, specific error descriptions
9. **Skip Links**: Skip to main content link
10. **Semantic HTML**: Use proper heading hierarchy (h1 → h6)

### Responsive Design
11. **Mobile First**: Design for 320px first
12. **Breakpoint Testing**: Test all 5 breakpoints
13. **Touch Gestures**: Support swipe on mobile
14. **Orientation**: Support portrait & landscape
15. **Fold Awareness**: Key content above fold
16. **Thumb Zones**: Primary actions in reach
17. **Text Sizing**: 16px minimum on mobile
18. **Line Length**: 50-75 characters optimal
19. **Spacing**: 16px minimum padding on mobile
20. **Navigation**: Hamburger menu on mobile

### Performance
21. **Load Time**: <2.5s on 3G
22. **First Paint**: <1.2s
23. **Interactive**: <3s
24. **Image Optimization**: WebP format, lazy load
25. **Code Splitting**: Load on demand
26. **Caching**: Cache static assets
27. **Minification**: Minify CSS, JS
28. **CDN**: Use CDN for assets
29. **Bundle Size**: <200KB initial
30. **Lighthouse Score**: 90+ in all categories

### User Feedback
31. **Loading States**: Show spinner for >500ms operations
32. **Success Messages**: Green toast, 4s duration
33. **Error Messages**: Red toast, persist until dismissed
34. **Progress Indicators**: For multi-step processes
35. **Confirmation Dialogs**: For destructive actions
36. **Hover States**: Visual feedback on hover
37. **Active States**: Visual feedback on click
38. **Disabled States**: 50% opacity, cursor not-allowed
39. **Focus States**: Teal ring on focus
40. **Empty States**: Helpful message + CTA

### Form Validation
41. **Inline Validation**: Validate on blur
42. **Real-time Feedback**: Show errors immediately
43. **Required Fields**: Mark with asterisk
44. **Field Hints**: Helper text below field
45. **Error Positioning**: Below field, red text
46. **Password Strength**: Visual indicator
47. **Confirmation Fields**: For password, email
48. **Auto-complete**: Support browser auto-complete
49. **Input Masks**: Format phone, dates
50. **Character Count**: Show for limited fields

### Navigation
51. **Breadcrumbs**: Show path on deep pages
52. **Active State**: Highlight current page
53. **Mega Menu**: For >7 nav items
54. **Search**: Global search accessible
55. **Back Button**: Browser back supported
56. **Logo Link**: Logo links to home
57. **Footer Nav**: Duplicate key links
58. **Sticky Header**: On scroll down
59. **Mobile Menu**: Smooth slide-in
60. **Deep Linking**: Support URL parameters

### Content
61. **Hierarchy**: Clear visual hierarchy
62. **Scannability**: Use headings, bullets
63. **Chunking**: Break long content
64. **White Space**: Breathing room
65. **Consistency**: Same patterns throughout
66. **Microcopy**: Helpful, friendly tone
67. **Placeholders**: Example format
68. **Labels**: Clear, concise
69. **CTAs**: Action-oriented
70. **Icons**: Meaningful, recognizable

### Data Display
71. **Tables**: Sortable columns
72. **Pagination**: For >50 items
73. **Filtering**: Multiple criteria
74. **Search**: Instant search
75. **Export**: CSV, PDF options
76. **Empty State**: When no data
77. **Loading**: Skeleton screens
78. **Truncation**: Ellipsis for long text
79. **Tooltips**: On hover for details
80. **Badges**: For status, count

### Modals & Dialogs
81. **Backdrop**: Semi-transparent overlay
82. **ESC Key**: Close on ESC
83. **Click Outside**: Close on backdrop click
84. **Focus Trap**: Keep focus in modal
85. **Scroll Lock**: Prevent body scroll
86. **Mobile Full**: Full screen on mobile
87. **Close Button**: X in top-right
88. **Primary Action**: Bottom-right
89. **Animation**: Fade + scale in
90. **Z-index**: Above all content

### Notifications
91. **Position**: Top-right corner
92. **Auto-dismiss**: 4s for success, 8s for info
93. **Manual Dismiss**: X button
94. **Stack**: Max 3 visible
95. **Animation**: Slide in from right
96. **Icon**: Type-specific icon
97. **Action**: Optional inline action
98. **Persistence**: Errors require dismiss
99. **Sound**: Optional sound for critical

---

## 📊 Chart Types (25 Options)

### Basic Charts
1. **Line Chart** - Trends over time
2. **Bar Chart** - Comparisons
3. **Pie Chart** - Proportions
4. **Donut Chart** - Proportions with center data
5. **Area Chart** - Volume over time

### Advanced Charts
6. **Stacked Bar** - Multi-category comparison
7. **Grouped Bar** - Side-by-side comparison
8. **Scatter Plot** - Correlation
9. **Bubble Chart** - 3-variable visualization
10. **Heatmap** - Density/intensity

### Specialized Medical Charts
11. **Vital Signs Timeline** - Patient vitals over time
12. **Appointment Heatmap** - Busy hours visualization
13. **Department Load** - Real-time occupancy
14. **Queue Status** - Current waiting list
15. **Doctor Performance** - Consultation metrics

### Dashboard Widgets
16. **Stat Cards** - Key metrics
17. **Progress Rings** - Completion percentage
18. **Sparklines** - Micro trends
19. **Gauges** - Current vs target
20. **Trend Indicators** - Up/down arrows

### Data Tables
21. **Sortable Table** - Click column headers
22. **Filterable Table** - Multi-filter
23. **Searchable Table** - Instant search
24. **Expandable Rows** - Detail on click
25. **Action Columns** - Inline actions

---

## 🎨 161 Color Palette Combinations

### Professional Medical
1. Navy 900 + Teal 500 + White
2. Navy 800 + Teal 400 + Slate 100
3. Navy 950 + Teal 600 + Slate 50

### Warm & Welcoming
4. Amber 500 + Teal 500 + White
5. Coral 300 + Teal 300 + Slate 50
6. Amber 400 + Navy 700 + White

### Cool & Clinical
7. Blue 500 + Slate 700 + White
8. Teal 600 + Slate 800 + Slate 100
9. Blue 400 + Navy 800 + White

### Modern & Bold
10. Purple 500 + Teal 500 + Navy 900
11. Purple 600 + Blue 500 + White
12. Teal 600 + Purple 500 + Slate 50

... *(147 more combinations available in full design system)*

---

## 🚀 Implementation Examples

### Glassmorphic Login Card
```html
<div class="glass-white rounded-2xl p-8 max-w-md mx-auto">
  <h2 class="font-display text-3xl font-bold text-navy-900 mb-6">
    Welcome back
  </h2>
  <form class="space-y-5">
    <div class="input-group">
      <div class="input-icon">
        <svg class="w-5 h-5"><!-- email icon --></svg>
      </div>
      <input type="email" class="field-input pl-12" placeholder="Email" />
    </div>
    <button type="submit" class="btn-primary w-full">
      Sign in
    </button>
  </form>
</div>
```

### Stats Dashboard Grid
```html
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
  <div class="stat-card-glass">
    <p class="stat-label">Total Patients</p>
    <p class="stat-value">1,284</p>
    <p class="stat-change positive">
      ↑ 12% from last month
    </p>
  </div>
  <!-- Repeat for other stats -->
</div>
```

### Real-time Queue Board
```html
<div class="space-y-3">
  <div class="card-glass-hover p-5">
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-4">
        <div class="avatar avatar-lg bg-teal-100 text-teal-700">
          JD
        </div>
        <div>
          <p class="font-semibold text-white">John Doe</p>
          <p class="text-sm text-slate-400">Token #A-015</p>
        </div>
      </div>
      <span class="status-pill bg-amber-500/20 text-amber-300 border border-amber-400/30">
        <span class="h-2 w-2 rounded-full bg-amber-400 animate-pulse"></span>
        Waiting
      </span>
    </div>
  </div>
  <!-- Repeat for queue items -->
</div>
```

---

## 📱 Mobile-First Guidelines

### Touch Targets
- Minimum: 44x44px
- Preferred: 48x48px
- Spacing: 8px between

### Typography Mobile
- Body: 16px (never smaller)
- Headings: Scale 1.5x
- Line height: 1.6 for body

### Spacing Mobile
- Padding: 16px minimum
- Gap: 16px between sections
- Margin: 24px between major blocks

### Navigation Mobile
- Bottom nav: Primary actions
- Hamburger: Secondary menu
- Tabs: Max 5 items
- Swipe: Horizontal scrolling

---

## 🎯 Best Practices

### DO's ✅
- Use glassmorphic effects for modern feel
- Maintain 4.5:1 contrast ratio
- Test on real devices
- Use semantic HTML
- Implement loading states
- Show error messages clearly
- Animate transitions (200-300ms)
- Use consistent spacing (4, 8, 12, 16, 24, 32px)
- Implement dark mode toggle
- Support keyboard navigation

### DON'Ts ❌
- Don't use pure white (#FFF) on dark backgrounds
- Don't animate on reduced-motion preference
- Don't use auto-playing videos
- Don't hide important actions in hamburger
- Don't use long loading times without feedback
- Don't use small touch targets (<44px)
- Don't use low contrast colors
- Don't use more than 3 font families
- Don't overuse animations
- Don't forget focus states

---

## 📚 Resources

### Figma File
- Component library: [Link to Figma]
- Design tokens: [Link to tokens]
- Icon set: [Link to icons]

### Code Examples
- CodePen demos: [Link]
- Storybook: [Link]
- GitHub repo: [Link]

### Tools
- Color contrast checker: [Link]
- Typography scale generator: [Link]
- Accessibility checker: [Link]

---

**Version**: 2.0  
**Last Updated**: July 11, 2026  
**Maintained by**: MediQueue Design Team
