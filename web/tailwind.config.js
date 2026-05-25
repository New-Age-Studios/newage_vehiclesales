/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        paper: {
          DEFAULT: '#f7f3ea',
          darker: '#e8e4d9',
        },
        concessionaire: {
          dark: '#14532d',
          DEFAULT: '#166534',
        }
      },
      fontFamily: {
        serif: ['"Playfair Display"', 'serif'],
        sans: ['Inter', 'sans-serif'],
      },
      backgroundImage: {
        'surface': "radial-gradient(circle, #1a1a1a 0%, #0a0a0a 100%)",
      }
    },
  },
  plugins: [],
}
