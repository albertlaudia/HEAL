import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // HEAL calm palette — warm off-white, sage, dawn gold, soft indigo
        bone: '#F8F4ED',      // main background
        paper: '#FBF8F2',     // card surface
        ink: '#2A2622',       // body text
        sage: {
          50: '#F2F5F0',
          100: '#E1E9DC',
          200: '#C5D3BB',
          300: '#A2B893',
          400: '#7E9B6C',
          500: '#5F7E4E',
          600: '#4A6439',
          700: '#3A4F2D',
          800: '#2D3D24',
          900: '#1F2B1A',
        },
        dawn: {
          50: '#FBF6EC',
          100: '#F4E7C8',
          200: '#E8CE92',
          300: '#D9B05C',
          400: '#C89538',
          500: '#A87825',
          600: '#855B1A',
          700: '#634214',
        },
        mist: {
          50: '#F5F6F9',
          100: '#E5E8F0',
          200: '#C9D0E0',
          300: '#9FAAC4',
          400: '#6B7BA0',
          500: '#475679',
          600: '#2F3B5C',
          700: '#1E2742',
        },
        clay: '#A57B5B',
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
        serif: ['var(--font-serif)', 'Georgia', 'serif'],
        hand: ['var(--font-hand)', 'cursive'],
      },
      animation: {
        'breathe-in': 'breatheIn 4s ease-in-out infinite',
        'breathe-out': 'breatheOut 4s ease-in-out infinite',
        'fade-up': 'fadeUp 0.6s ease-out',
        'fade-in': 'fadeIn 1s ease-out',
        'spin-slow': 'spin 18s linear infinite',
        'shimmer': 'shimmer 8s ease-in-out infinite',
      },
      keyframes: {
        breatheIn: { '0%, 100%': { transform: 'scale(1)' }, '50%': { transform: 'scale(1.4)' } },
        breatheOut: { '0%, 100%': { transform: 'scale(1.4)' }, '50%': { transform: 'scale(1)' } },
        fadeUp: { '0%': { opacity: '0', transform: 'translateY(20px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        fadeIn: { '0%': { opacity: '0' }, '100%': { opacity: '1' } },
        shimmer: { '0%, 100%': { opacity: '0.6' }, '50%': { opacity: '1' } },
      },
      backgroundImage: {
        'grain': "url(\"data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.06'/%3E%3C/svg%3E\")",
      },
    },
  },
  plugins: [],
};
export default config;
