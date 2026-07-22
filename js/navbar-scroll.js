/**
 * Smart Navbar Scroll Behavior
 * Hides navbar when scrolling down, shows when scrolling up
 */

(function() {
  let lastScrollY = window.scrollY;
  let ticking = false;
  const navbar = document.querySelector('nav');
  const scrollThreshold = 100; // Start hiding after 100px scroll

  if (!navbar) return;

  function updateNavbar() {
    const currentScrollY = window.scrollY;

    // If at the very top, always show navbar
    if (currentScrollY < scrollThreshold) {
      navbar.style.transform = 'translateY(0)';
      navbar.style.transition = 'transform 0.3s ease';
    } 
    // If scrolling down, hide navbar
    else if (currentScrollY > lastScrollY && currentScrollY > scrollThreshold) {
      navbar.style.transform = 'translateY(-100%)';
      navbar.style.transition = 'transform 0.3s ease';
    } 
    // If scrolling up, show navbar
    else if (currentScrollY < lastScrollY) {
      navbar.style.transform = 'translateY(0)';
      navbar.style.transition = 'transform 0.3s ease';
    }

    lastScrollY = currentScrollY;
    ticking = false;
  }

  function requestTick() {
    if (!ticking) {
      requestAnimationFrame(updateNavbar);
      ticking = true;
    }
  }

  // Listen for scroll events
  window.addEventListener('scroll', requestTick, { passive: true });

  // Initial state
  navbar.style.transition = 'transform 0.3s ease';
})();
