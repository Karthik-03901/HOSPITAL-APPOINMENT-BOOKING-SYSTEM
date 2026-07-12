/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./*.html",
    "./pages/**/*.html",
    "./js/**/*.js"
  ],
  theme: {
    extend: {
      colors: {
        // Enhanced medical palette with glassmorphic support
        navy: {
          950: "#081826",
          900: "#0F2540",
          800: "#173A5E",
          700: "#20507D",
          600: "#2A6BA0",
          500: "#3B7BC0"
        },
        teal: {
          700: "#097568",
          600: "#0B7B6F",
          500: "#0E9384",
          400: "#2BB3A3",
          300: "#5FC9BC",
          200: "#A3E4DD",
          100: "#D4F3F0",
          50: "#E8F9F7"
        },
        slate: {
          800: "#2C3E50",
          700: "#36485A",
          600: "#42566A",
          500: "#5B7083",
          400: "#8DA2B5",
          300: "#B7C5D1",
          200: "#D4DCE3",
          100: "#E7EDF1",
          50: "#F3F6F8"
        },
        paper: "#F6F8F7",
        green: {
          600: "#059669",
          500: "#10B981",
          400: "#34D399",
          300: "#6EE7B7"
        },
        amber: {
          600: "#D97706",
          500: "#F59E0B",
          400: "#FBBF24",
          300: "#FCD34D"
        },
        coral: {
          600: "#C23B3B",
          500: "#D64545",
          400: "#EF4444",
          300: "#F87171"
        },
        // Additional professional palettes
        purple: {
          600: "#7C3AED",
          500: "#8B5CF6",
          400: "#A78BFA",
          300: "#C4B5FD"
        },
        blue: {
          600: "#2563EB",
          500: "#3B82F6",
          400: "#60A5FA",
          300: "#93C5FD"
        }
      },
      fontFamily: {
        display: ["Space Grotesk", "sans-serif"],
        body: ["Inter", "IBM Plex Sans", "sans-serif"],
        mono: ["JetBrains Mono", "IBM Plex Mono", "monospace"]
      },
      fontSize: {
        '2xs': '0.625rem',
        '3xl': '1.875rem',
        '4xl': '2.25rem',
        '5xl': '3rem',
        '6xl': '3.75rem',
        '7xl': '4.5rem',
      },
      letterSpacing: {
        widest2: "0.2em",
        tighter: "-0.02em",
        tight: "-0.01em"
      },
      backgroundImage: {
        "grid-fade": "linear-gradient(180deg, rgba(255,255,255,0.04) 1px, transparent 1px)",
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-conic": "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
        "mesh-gradient": "radial-gradient(at 40% 20%, hsla(189,100%,56%,0.3) 0px, transparent 50%), radial-gradient(at 80% 0%, hsla(189,100%,56%,0.2) 0px, transparent 50%), radial-gradient(at 0% 50%, hsla(189,100%,56%,0.2) 0px, transparent 50%)",
        "glass-gradient": "linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)"
      },
      backdropBlur: {
        xs: '2px',
        '3xl': '64px'
      },
      boxShadow: {
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        'hover': '0 10px 40px -5px rgba(0, 0, 0, 0.1), 0 15px 30px -5px rgba(0, 0, 0, 0.08)',
        'glass': '0 8px 32px 0 rgba(31, 38, 135, 0.15)',
        'glass-lg': '0 8px 32px 0 rgba(31, 38, 135, 0.25)',
        'inner-glow': 'inset 0 2px 4px 0 rgba(255, 255, 255, 0.1)',
        'neon': '0 0 5px theme("colors.teal.400"), 0 0 20px theme("colors.teal.400")',
        'neon-hover': '0 0 10px theme("colors.teal.400"), 0 0 30px theme("colors.teal.400"), 0 0 50px theme("colors.teal.400")'
      },
      animation: {
        'spin-slow': 'spin 3s linear infinite',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-slow': 'bounce 2s infinite',
        'float': 'float 6s ease-in-out infinite',
        'glow': 'glow 2s ease-in-out infinite alternate',
        'shimmer': 'shimmer 2.5s linear infinite',
        'fade-in': 'fadeIn 0.5s ease-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'scale-in': 'scaleIn 0.3s ease-out'
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-20px)' }
        },
        glow: {
          'from': { textShadow: '0 0 5px #0E9384, 0 0 10px #0E9384' },
          'to': { textShadow: '0 0 10px #0E9384, 0 0 20px #0E9384, 0 0 30px #0E9384' }
        },
        shimmer: {
          '0%': { backgroundPosition: '-1000px 0' },
          '100%': { backgroundPosition: '1000px 0' }
        },
        fadeIn: {
          'from': { opacity: '0' },
          'to': { opacity: '1' }
        },
        slideUp: {
          'from': { transform: 'translateY(30px)', opacity: '0' },
          'to': { transform: 'translateY(0)', opacity: '1' }
        },
        scaleIn: {
          'from': { transform: 'scale(0.9)', opacity: '0' },
          'to': { transform: 'scale(1)', opacity: '1' }
        }
      },
      transitionProperty: {
        'height': 'height',
        'spacing': 'margin, padding'
      },
      blur: {
        xs: '2px'
      }
    }
  },
  plugins: []
};
