/** Design System LuxRH v1 — violet d'application, turquoise d'action, gris de travail. */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        violet: {
          DEFAULT: '#714B67',   // violet primaire — identité, barre d'application
          deep: '#5C3D54',      // violet profond — survol, accents
          veil: '#F3ECF1',      // violet voile — fonds de sélection
          line: '#EADFE6',
        },
        action: {
          DEFAULT: '#017E84',   // turquoise action — boutons primaires, liens
          hover: '#01686D',
          veil: '#E4F1F2',
        },
        ink: {
          DEFAULT: '#1F2937',
          strong: '#3A3438',
          body: '#4A4348',
          soft: '#5B5459',
          muted: '#6B6469',
          faint: '#6E666C',
        },
        rule: { DEFAULT: '#E4E1E3', strong: '#D6D2D4', rail: '#F1EFF0', alt: '#EFEDEE' },
        canvas: '#F6F5F6',
        danger: { DEFAULT: '#C0392B', deep: '#A5302A', ink: '#8E2A22', veil: '#FBEAE8' },
        success: { DEFAULT: '#1E7E34', ink: '#186429', veil: '#E8F5EA' },
        warn: { DEFAULT: '#B7791F', deep: '#8C5C13', ink: '#7D5312', veil: '#FDF3E2' },
        highlight: '#F5C842',
      },
      fontFamily: {
        sans: ["'Public Sans'", 'system-ui', 'sans-serif'],
        mono: ["'IBM Plex Mono'", 'ui-monospace', 'monospace'],
      },
      fontSize: {
        '2xs': ['11px', '1.4'],
        xs: ['12px', '1.5'],
        sm: ['13px', '1.55'],
        base: ['14px', '1.6'],
        lg: ['16px', '1.5'],
        xl: ['20px', '1.35'],
        '2xl': ['24px', '1.25'],
        '3xl': ['32px', '1.15'],
      },
      borderRadius: { DEFAULT: '6px', md: '8px', lg: '10px' },
      boxShadow: {
        card: '0 1px 2px rgba(31,41,55,0.04)',
        pop: '0 8px 24px rgba(31,41,55,0.12)',
      },
      keyframes: {
        shimmer: { '0%': { backgroundPosition: '-320px 0' }, '100%': { backgroundPosition: '320px 0' } },
      },
      animation: { shimmer: 'shimmer 1.2s linear infinite' },
    },
  },
  plugins: [],
}
