/**
 * Mock data for development and testing
 * This will be replaced with real Supabase queries in production
 */

// Departments with detailed information
export const departments = [
  {
    id: 'dept-1',
    name: 'Cardiology',
    description: 'Heart and cardiovascular system care',
    icon: '❤️',
    avgWaitTime: 15,
    totalDoctors: 4,
    availableToday: true,
    consultationFee: 500
  },
  {
    id: 'dept-2',
    name: 'Orthopedics',
    description: 'Bone, joint, and muscle treatment',
    icon: '🦴',
    avgWaitTime: 20,
    totalDoctors: 3,
    availableToday: true,
    consultationFee: 600
  },
  {
    id: 'dept-3',
    name: 'Pediatrics',
    description: 'Healthcare for infants and children',
    icon: '👶',
    avgWaitTime: 10,
    totalDoctors: 5,
    availableToday: true,
    consultationFee: 400
  },
  {
    id: 'dept-4',
    name: 'Dermatology',
    description: 'Skin, hair, and nail care',
    icon: '🔬',
    avgWaitTime: 12,
    totalDoctors: 3,
    availableToday: true,
    consultationFee: 450
  },
  {
    id: 'dept-5',
    name: 'Neurology',
    description: 'Brain and nervous system treatment',
    icon: '🧠',
    avgWaitTime: 25,
    totalDoctors: 2,
    availableToday: false,
    consultationFee: 700
  },
  {
    id: 'dept-6',
    name: 'Ophthalmology',
    description: 'Eye care and vision treatment',
    icon: '👁️',
    avgWaitTime: 15,
    totalDoctors: 4,
    availableToday: true,
    consultationFee: 500
  },
  {
    id: 'dept-7',
    name: 'Dentistry',
    description: 'Dental and oral health care',
    icon: '🦷',
    avgWaitTime: 10,
    totalDoctors: 6,
    availableToday: true,
    consultationFee: 350
  },
  {
    id: 'dept-8',
    name: 'General Medicine',
    description: 'Primary healthcare and consultations',
    icon: '🩺',
    avgWaitTime: 8,
    totalDoctors: 8,
    availableToday: true,
    consultationFee: 300
  }
];

// Doctors with comprehensive profiles
export const doctors = [
  // Cardiology
  {
    id: 'doc-1',
    name: 'Dr. Anjali Rao',
    departmentId: 'dept-1',
    specialization: 'Interventional Cardiologist',
    qualification: 'MBBS, MD, DM (Cardiology)',
    experience: 15,
    rating: 4.8,
    totalReviews: 234,
    consultationFee: 500,
    languages: ['English', 'Hindi', 'Telugu'],
    availableDays: [1, 2, 3, 4, 5], // Monday to Friday
    timeSlots: ['09:00', '09:30', '10:00', '10:30', '11:00', '14:00', '14:30', '15:00', '15:30', '16:00'],
    bio: 'Specialist in heart disease prevention and treatment with 15 years of experience.',
    nextAvailable: '2026-07-13',
    image: null
  },
  {
    id: 'doc-2',
    name: 'Dr. Rajesh Kumar',
    departmentId: 'dept-1',
    specialization: 'Cardiac Surgeon',
    qualification: 'MBBS, MS, MCh (Cardiac Surgery)',
    experience: 20,
    rating: 4.9,
    totalReviews: 456,
    consultationFee: 600,
    languages: ['English', 'Hindi'],
    availableDays: [2, 3, 4, 5, 6],
    timeSlots: ['10:00', '10:30', '11:00', '15:00', '15:30', '16:00'],
    bio: 'Renowned cardiac surgeon specializing in complex heart surgeries.',
    nextAvailable: '2026-07-14',
    image: null
  },
  // Orthopedics
  {
    id: 'doc-3',
    name: 'Dr. Priya Sharma',
    departmentId: 'dept-2',
    specialization: 'Joint Replacement Specialist',
    qualification: 'MBBS, MS (Ortho), DNB',
    experience: 12,
    rating: 4.7,
    totalReviews: 189,
    consultationFee: 600,
    languages: ['English', 'Hindi', 'Punjabi'],
    availableDays: [1, 2, 4, 5],
    timeSlots: ['09:00', '09:30', '10:00', '14:00', '14:30', '15:00', '15:30'],
    bio: 'Expert in joint replacement surgeries and sports injuries.',
    nextAvailable: '2026-07-13',
    image: null
  },
  {
    id: 'doc-4',
    name: 'Dr. Vikram Singh',
    departmentId: 'dept-2',
    specialization: 'Spine Surgeon',
    qualification: 'MBBS, MS (Ortho), Fellowship (Spine)',
    experience: 18,
    rating: 4.9,
    totalReviews: 312,
    consultationFee: 700,
    languages: ['English', 'Hindi'],
    availableDays: [1, 3, 5],
    timeSlots: ['10:00', '11:00', '15:00', '16:00'],
    bio: 'Leading spine surgeon with expertise in minimally invasive procedures.',
    nextAvailable: '2026-07-15',
    image: null
  },
  // Pediatrics
  {
    id: 'doc-5',
    name: 'Dr. Meera Patel',
    departmentId: 'dept-3',
    specialization: 'Pediatrician',
    qualification: 'MBBS, MD (Pediatrics)',
    experience: 10,
    rating: 4.8,
    totalReviews: 567,
    consultationFee: 400,
    languages: ['English', 'Hindi', 'Gujarati'],
    availableDays: [1, 2, 3, 4, 5, 6],
    timeSlots: ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '14:00', '14:30', '15:00', '15:30', '16:00'],
    bio: 'Compassionate pediatrician specializing in child healthcare and vaccinations.',
    nextAvailable: '2026-07-13',
    image: null
  },
  {
    id: 'doc-6',
    name: 'Dr. Arjun Reddy',
    departmentId: 'dept-3',
    specialization: 'Pediatric Neurologist',
    qualification: 'MBBS, MD, DM (Pediatric Neurology)',
    experience: 14,
    rating: 4.9,
    totalReviews: 234,
    consultationFee: 550,
    languages: ['English', 'Hindi', 'Telugu'],
    availableDays: [2, 3, 4, 5],
    timeSlots: ['10:00', '10:30', '11:00', '15:00', '15:30', '16:00'],
    bio: 'Expert in pediatric neurological disorders and developmental issues.',
    nextAvailable: '2026-07-14',
    image: null
  },
  // Dermatology
  {
    id: 'doc-7',
    name: 'Dr. Kavita Nair',
    departmentId: 'dept-4',
    specialization: 'Dermatologist & Cosmetologist',
    qualification: 'MBBS, MD (Dermatology)',
    experience: 8,
    rating: 4.7,
    totalReviews: 423,
    consultationFee: 450,
    languages: ['English', 'Hindi', 'Malayalam'],
    availableDays: [1, 2, 3, 4, 5],
    timeSlots: ['09:00', '09:30', '10:00', '10:30', '14:00', '14:30', '15:00', '15:30', '16:00'],
    bio: 'Specialized in skin treatments, hair care, and cosmetic procedures.',
    nextAvailable: '2026-07-13',
    image: null
  },
  // Ophthalmology
  {
    id: 'doc-8',
    name: 'Dr. Suresh Iyer',
    departmentId: 'dept-6',
    specialization: 'Eye Surgeon',
    qualification: 'MBBS, MS (Ophthalmology)',
    experience: 16,
    rating: 4.8,
    totalReviews: 389,
    consultationFee: 500,
    languages: ['English', 'Hindi', 'Tamil'],
    availableDays: [1, 2, 3, 4, 5],
    timeSlots: ['09:00', '09:30', '10:00', '10:30', '11:00', '14:30', '15:00', '15:30', '16:00'],
    bio: 'Expert in cataract surgery, LASIK, and retinal treatments.',
    nextAvailable: '2026-07-13',
    image: null
  },
  // Dentistry
  {
    id: 'doc-9',
    name: 'Dr. Neha Gupta',
    departmentId: 'dept-7',
    specialization: 'Orthodontist',
    qualification: 'BDS, MDS (Orthodontics)',
    experience: 9,
    rating: 4.9,
    totalReviews: 512,
    consultationFee: 350,
    languages: ['English', 'Hindi'],
    availableDays: [1, 2, 3, 4, 5, 6],
    timeSlots: ['09:00', '09:30', '10:00', '10:30', '11:00', '14:00', '14:30', '15:00', '15:30'],
    bio: 'Specialized in braces, aligners, and dental cosmetic procedures.',
    nextAvailable: '2026-07-13',
    image: null
  },
  // General Medicine
  {
    id: 'doc-10',
    name: 'Dr. Amit Verma',
    departmentId: 'dept-8',
    specialization: 'General Physician',
    qualification: 'MBBS, MD (Medicine)',
    experience: 11,
    rating: 4.7,
    totalReviews: 678,
    consultationFee: 300,
    languages: ['English', 'Hindi'],
    availableDays: [1, 2, 3, 4, 5, 6],
    timeSlots: ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'],
    bio: 'Experienced general physician for common health issues and preventive care.',
    nextAvailable: '2026-07-13',
    image: null
  }
];

// Simulated booked slots (for realistic availability)
export const bookedSlots = {
  '2026-07-13': {
    'doc-1': ['09:00', '10:00', '14:00', '15:00'],
    'doc-3': ['09:00', '14:00'],
    'doc-5': ['09:00', '09:30', '10:00', '14:00'],
    'doc-7': ['09:00', '10:00', '14:00', '15:00', '16:00'],
    'doc-8': ['09:00', '10:00', '14:30'],
    'doc-9': ['09:00', '10:00', '11:00', '14:00'],
    'doc-10': ['09:00', '09:30', '10:00', '10:30', '14:00', '14:30']
  },
  '2026-07-14': {
    'doc-2': ['10:00', '15:00'],
    'doc-6': ['10:00', '15:00'],
  },
  '2026-07-15': {
    'doc-4': ['10:00', '15:00']
  }
};

// Helper functions
export function getDepartmentById(id) {
  return departments.find(d => d.id === id);
}

export function getDoctorById(id) {
  return doctors.find(d => d.id === id);
}

export function getDoctorsByDepartment(departmentId) {
  return doctors.filter(d => d.departmentId === departmentId);
}

export function getAvailableSlots(doctorId, date) {
  const doctor = getDoctorById(doctorId);
  if (!doctor) return [];
  
  const dateObj = new Date(date);
  const dayOfWeek = dateObj.getDay();
  
  // Check if doctor is available on this day
  if (!doctor.availableDays.includes(dayOfWeek)) {
    return [];
  }
  
  // Get booked slots for this date and doctor
  const booked = bookedSlots[date]?.[doctorId] || [];
  
  // Filter out booked slots
  return doctor.timeSlots.filter(slot => !booked.includes(slot));
}

export function isSlotAvailable(doctorId, date, time) {
  const availableSlots = getAvailableSlots(doctorId, date);
  return availableSlots.includes(time);
}
