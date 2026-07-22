/**
 * Testimonials Module
 * Continuous auto-scrolling testimonials carousel
 */

const testimonials = [
  {
    name: "Dr. Rajesh Sharma",
    role: "Chief Medical Officer",
    avatar: "DR",
    rating: 5,
    color: "teal",
    text: "MediQueue has transformed how we manage our OPD. The real-time queue tracking has reduced patient complaints by 80%. Highly recommended!"
  },
  {
    name: "Priya Mehta",
    role: "Patient",
    avatar: "PM",
    rating: 5,
    color: "purple",
    text: "As a patient, I love knowing exactly when my turn is coming. No more wasting hours in the waiting room. This app is a game-changer!"
  },
  {
    name: "Sunil Kumar",
    role: "Hospital Administrator",
    avatar: "SK",
    rating: 5,
    color: "blue",
    text: "The analytics dashboard gives us insights we never had before. We've optimized our staffing based on peak hours data. ROI in 3 months!"
  },
  {
    name: "Dr. Anjali Rao",
    role: "Cardiologist",
    avatar: "AR",
    rating: 5,
    color: "pink",
    text: "The waitlist automation feature is brilliant! When patients cancel, slots are automatically filled. Zero wastage now."
  },
  {
    name: "Amit Patel",
    role: "IT Manager",
    avatar: "AP",
    rating: 5,
    color: "indigo",
    text: "Integration was seamless. The API documentation is excellent, and support team helped us customize it to our needs."
  },
  {
    name: "Dr. Meera Desai",
    role: "Pediatrician",
    avatar: "MD",
    rating: 5,
    color: "green",
    text: "My patients' parents love the SMS reminders. No-show rate dropped from 25% to under 10%. Impressive results!"
  },
  {
    name: "Rahul Singh",
    role: "Front Desk Manager",
    avatar: "RS",
    rating: 5,
    color: "amber",
    text: "QR code check-in is super fast! Patients just scan and they're in the queue. Reduced check-in time by 80%."
  },
  {
    name: "Dr. Kavita Joshi",
    role: "Orthopedic Surgeon",
    avatar: "KJ",
    rating: 5,
    color: "cyan",
    text: "I can see my entire day's schedule at a glance. The priority queue system ensures emergency cases are seen first."
  },
  {
    name: "Neha Verma",
    role: "Patient",
    avatar: "NV",
    rating: 5,
    color: "rose",
    text: "Booked my appointment at 2 AM when I couldn't sleep! The 24/7 online booking is so convenient. Love it!"
  },
  {
    name: "Dr. Vikram Reddy",
    role: "Hospital Director",
    avatar: "VR",
    rating: 5,
    color: "violet",
    text: "Best investment we made this year. Patient satisfaction scores increased by 40%. The ROI speaks for itself!"
  }
];

function initTestimonials() {
  const track = document.getElementById('testimonials-track');
  if (!track) return;
  
  // Duplicate testimonials for seamless loop
  const allTestimonials = [...testimonials, ...testimonials];
  
  track.innerHTML = allTestimonials.map(t => createTestimonialCard(t)).join('');
}

function createTestimonialCard(testimonial) {
  const stars = '⭐'.repeat(testimonial.rating);
  
  return `
    <div class="testimonial-card">
      <div class="flex items-center gap-1 mb-4">
        <span class="text-lg">${stars}</span>
      </div>
      <p class="text-slate-600 leading-relaxed mb-6 text-sm">"${testimonial.text}"</p>
      <div class="flex items-center gap-3">
        <div class="avatar avatar-md bg-${testimonial.color}-100 text-${testimonial.color}-700">
          ${testimonial.avatar}
        </div>
        <div>
          <p class="font-semibold text-navy-900 text-sm">${testimonial.name}</p>
          <p class="text-xs text-slate-500">${testimonial.role}</p>
        </div>
      </div>
    </div>
  `;
}

// Initialize on page load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initTestimonials);
} else {
  initTestimonials();
}

export { testimonials, initTestimonials };
