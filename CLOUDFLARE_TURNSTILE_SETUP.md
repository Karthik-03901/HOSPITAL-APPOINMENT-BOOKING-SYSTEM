# ☁️ Cloudflare Turnstile Setup Guide

## What is Cloudflare Turnstile?

Cloudflare Turnstile is a user-friendly, privacy-preserving alternative to CAPTCHA. It's:
- ✅ **Free** - No cost for most use cases
- ✅ **Privacy-friendly** - GDPR compliant
- ✅ **Easy to integrate** - Simple API
- ✅ **Better UX** - Often invisible to users
- ✅ **No Google dependency** - Runs on Cloudflare's network

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Get Cloudflare Turnstile Keys (2 minutes)

1. **Go to Cloudflare Dashboard:**
   - Visit: https://dash.cloudflare.com
   - Login or create free account

2. **Navigate to Turnstile:**
   - Select your account
   - Go to "Turnstile" in left sidebar
   - OR visit: https://dash.cloudflare.com/?to=/:account/turnstile

3. **Create Widget:**
   - Click "Add site" or "Add widget"
   - **Widget name:** MediQueue Hospital
   - **Domains:** Add your domains:
     ```
     localhost
     127.0.0.1
     yourdomain.com
     www.yourdomain.com
     ```
   - **Widget Mode:** Choose one:
     - **Managed (Recommended)** - Best balance of security and UX
     - **Non-interactive** - Most invisible, may need fallback
     - **Invisible** - Runs in background
   - Click "Create"

4. **Copy Keys:**
   - **Site Key** - Starts with `0x4A...` or similar
   - **Secret Key** - Keep this secure (for server-side verification)

---

### Step 2: Update Security Module (1 minute)

Open `js/security.js` and update the site key:

```javascript
// Replace test key with your actual key
const TURNSTILE_SITE_KEY = 'YOUR_SITE_KEY_HERE';
```

**Test Keys (for development):**
```javascript
// Always passes
const TURNSTILE_SITE_KEY = '1x00000000000000000000AA';

// Always blocks  
const TURNSTILE_SITE_KEY = '2x00000000000000000000AB';

// Forces interactive challenge
const TURNSTILE_SITE_KEY = '3x00000000000000000000FF';
```

---

### Step 3: Test (2 minutes)

1. **Open Login Page:**
   - Navigate to `pages/login.html`

2. **Trigger CAPTCHA:**
   - Enter any email
   - Enter wrong password
   - Click "Sign In"
   - Repeat 3 times

3. **Verify Turnstile Appears:**
   - On 4th attempt, Turnstile widget should appear
   - Complete the challenge
   - Should allow login attempt

4. **Check Console:**
   ```javascript
   ✅ Turnstile verified: [token]
   ```

---

## 📋 Comparison: Turnstile vs reCAPTCHA

| Feature | Cloudflare Turnstile | Google reCAPTCHA |
|---------|---------------------|------------------|
| **Cost** | Free (unlimited) | Free (limited) |
| **Privacy** | ✅ GDPR compliant | ⚠️ Google tracking |
| **User Experience** | ✅ Often invisible | ❌ Intrusive |
| **Speed** | ✅ Fast (<100ms) | ⚠️ Slower |
| **Accessibility** | ✅ Excellent | ⚠️ Issues reported |
| **Setup** | ✅ Simple | ⚠️ More complex |
| **Dependence** | Cloudflare | Google |
| **Mobile** | ✅ Optimized | ⚠️ Can be clunky |

---

## 🎨 Widget Modes Explained

### 1. Managed (Recommended) ⭐
```javascript
// Automatically chooses best method
// Shows challenge only when needed
// Best for most use cases
```
**When to use:** General websites, login forms, signups

### 2. Non-Interactive
```javascript
// Runs in background
// User sees nothing (if successful)
// May show fallback challenge
```
**When to use:** High-traffic sites, trusted users

### 3. Invisible
```javascript
// Always runs in background
// No visible widget
// Requires button click trigger
```
**When to use:** Checkout flows, payment forms

---

## 💻 Code Examples

### Basic Implementation (Already Done!)

The security module already includes Turnstile integration:

```javascript
import { showCaptcha, verifyCaptcha } from './security.js';

// Show Turnstile when needed
await showCaptcha('captcha-container');

// Verify before proceeding
const isValid = await verifyCaptcha();
if (isValid) {
  // Proceed with login
}
```

---

### Custom Container

```html
<!-- Add a specific container in your HTML -->
<div id="my-turnstile-container"></div>
```

```javascript
// Show in custom container
await showCaptcha('my-turnstile-container');
```

---

### Manual Widget Creation

```html
<!-- Automatic render -->
<div class="cf-turnstile" 
     data-sitekey="YOUR_SITE_KEY"
     data-callback="onTurnstileSuccess"></div>

<script>
function onTurnstileSuccess(token) {
  console.log('Turnstile verified:', token);
}
</script>
```

---

### Programmatic Rendering

```javascript
window.turnstile.render('#container', {
  sitekey: 'YOUR_SITE_KEY',
  theme: 'light', // or 'dark'
  size: 'normal', // or 'compact'
  callback: function(token) {
    // Called on success
    console.log('Success:', token);
  },
  'error-callback': function() {
    // Called on error
    console.error('Error occurred');
  },
  'expired-callback': function() {
    // Called when token expires
    console.warn('Token expired');
  }
});
```

---

## 🔒 Server-Side Verification (Recommended for Production)

### Why Verify Server-Side?
- ✅ Prevents token manipulation
- ✅ Validates with Cloudflare
- ✅ Checks for replay attacks
- ✅ More secure

### Verification Endpoint

```javascript
// Example using Node.js/Express
app.post('/verify-turnstile', async (req, res) => {
  const { token } = req.body;
  const SECRET_KEY = process.env.TURNSTILE_SECRET_KEY;
  
  // Verify with Cloudflare
  const response = await fetch(
    'https://challenges.cloudflare.com/turnstile/v0/siteverify',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        secret: SECRET_KEY,
        response: token
      })
    }
  );
  
  const data = await response.json();
  
  if (data.success) {
    res.json({ verified: true });
  } else {
    res.status(400).json({ verified: false, errors: data['error-codes'] });
  }
});
```

---

## 🎨 Styling & Customization

### Theme Options

```javascript
window.turnstile.render('#container', {
  sitekey: 'YOUR_SITE_KEY',
  theme: 'light', // 'light' or 'dark' or 'auto'
});
```

### Size Options

```javascript
window.turnstile.render('#container', {
  sitekey: 'YOUR_SITE_KEY',
  size: 'normal', // 'normal' or 'compact'
});
```

### Custom CSS

```css
/* Style the container */
#captcha-container {
  display: flex;
  justify-content: center;
  padding: 1rem 0;
  margin: 1rem 0;
}

/* Match your theme colors */
.cf-turnstile {
  border-radius: 0.5rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
```

---

## 🧪 Testing Guide

### Test Scenarios

#### 1. Test with Always-Pass Key
```javascript
const TURNSTILE_SITE_KEY = '1x00000000000000000000AA';
// Result: Always verifies successfully
```

#### 2. Test with Always-Block Key
```javascript
const TURNSTILE_SITE_KEY = '2x00000000000000000000AB';
// Result: Always fails verification
```

#### 3. Test with Force-Challenge Key
```javascript
const TURNSTILE_SITE_KEY = '3x00000000000000000000FF';
// Result: Always shows interactive challenge
```

---

## 📊 Analytics & Monitoring

### View Turnstile Stats

1. Go to Cloudflare Dashboard
2. Navigate to Turnstile
3. Select your widget
4. View metrics:
   - Total requests
   - Verified requests
   - Failed requests
   - Challenge rate
   - Response times

---

## 🐛 Troubleshooting

### Issue: Widget Not Showing

**Solution:**
```javascript
// Check if script loaded
console.log('Turnstile loaded:', !!window.turnstile);

// Check container exists
const container = document.getElementById('captcha-container');
console.log('Container found:', !!container);

// Check console for errors
```

---

### Issue: Verification Always Fails

**Solution:**
```javascript
// Check token exists
const token = container.querySelector('[name="cf-turnstile-response"]')?.value;
console.log('Token:', token);

// Verify site key is correct
console.log('Site key:', TURNSTILE_SITE_KEY);
```

---

### Issue: Widget Shows Wrong Domain Error

**Solution:**
1. Go to Cloudflare Dashboard
2. Edit your widget
3. Add all your domains:
   ```
   localhost
   127.0.0.1
   yourdomain.com
   *.yourdomain.com
   ```

---

### Issue: Token Expired

**Solution:**
```javascript
// Tokens expire after 5 minutes
// Add expired callback to handle
window.turnstile.render('#container', {
  sitekey: 'YOUR_SITE_KEY',
  'expired-callback': function() {
    // Reset and show new challenge
    window.turnstile.reset();
  }
});
```

---

## 🔐 Security Best Practices

### DO's:
- ✅ Always verify tokens server-side in production
- ✅ Use HTTPS in production
- ✅ Keep secret key secure (never in client code)
- ✅ Implement rate limiting alongside Turnstile
- ✅ Monitor for unusual patterns
- ✅ Set appropriate timeout values

### DON'Ts:
- ❌ Don't trust client-side verification alone
- ❌ Don't expose secret key
- ❌ Don't reuse tokens
- ❌ Don't skip server validation
- ❌ Don't disable in production

---

## 📱 Mobile Considerations

### Responsive Design
```css
/* Mobile-friendly Turnstile */
@media (max-width: 640px) {
  #captcha-container {
    transform: scale(0.9);
    transform-origin: center;
  }
}
```

### Touch-Friendly
- Turnstile is optimized for mobile
- Works with both tap and click
- Supports gesture-based verification

---

## 🌍 Accessibility

### WCAG Compliance
- ✅ Keyboard accessible
- ✅ Screen reader friendly
- ✅ High contrast support
- ✅ Focus indicators
- ✅ Clear error messages

### ARIA Attributes
Turnstile automatically includes:
- `role="button"`
- `aria-label` descriptors
- `aria-live` regions for status updates

---

## 🔄 Migration from reCAPTCHA

If you were using Google reCAPTCHA before:

### Changes Made:
1. ✅ Script URL updated to Cloudflare
2. ✅ API calls updated (render, reset, verify)
3. ✅ Site key format different
4. ✅ Response field name changed

### Migration Steps:
1. ✅ Get Turnstile keys
2. ✅ Update `TURNSTILE_SITE_KEY` in security.js
3. ✅ No HTML changes needed (handled automatically)
4. ✅ Test thoroughly

---

## 📚 Additional Resources

### Official Documentation:
- **Turnstile Docs:** https://developers.cloudflare.com/turnstile/
- **API Reference:** https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/
- **Server Verification:** https://developers.cloudflare.com/turnstile/get-started/server-side-validation/

### Community:
- **Cloudflare Community:** https://community.cloudflare.com
- **Status Page:** https://www.cloudflarestatus.com

---

## ✅ Setup Checklist

- [ ] Created Cloudflare account
- [ ] Created Turnstile widget
- [ ] Added all domains (localhost + production)
- [ ] Copied site key
- [ ] Updated `js/security.js` with site key
- [ ] Tested with wrong passwords (3 times)
- [ ] Verified widget appears
- [ ] Completed challenge successfully
- [ ] Checked browser console (no errors)
- [ ] Tested on mobile device
- [ ] Documented secret key securely
- [ ] Planned server-side verification

---

## 🎉 Success!

If all checkboxes are ticked, your Cloudflare Turnstile integration is complete!

**Benefits You Get:**
- ✅ Better user experience
- ✅ Improved privacy
- ✅ Faster load times
- ✅ Free forever
- ✅ Easy to maintain
- ✅ Cloudflare's global network

---

## 📞 Support

### Need Help?
1. Check Cloudflare Turnstile docs
2. Review browser console for errors
3. Test with test keys
4. Check domain configuration
5. Contact Cloudflare support

---

**Status:** ✅ READY TO USE  
**Setup Time:** ~5 minutes  
**Cost:** Free  
**Privacy:** ✅ GDPR Compliant  

**Your Cloudflare Turnstile integration is complete!** ☁️✨
