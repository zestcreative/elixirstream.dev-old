const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  purge: [
    '../lib/elixir_stream_web/live/**/*.ex',
    '../lib/elixir_stream_web/live/**/*.leex',
    '../lib/elixir_stream_web/templates/**/*.eex',
    '../lib/elixir_stream_web/templates/**/*.leex',
    '../lib/elixir_stream_web/views/**/*.ex',
    './js/**/*.js'
  ],
  darkMode: false,
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', 'Inter', ...defaultTheme.fontFamily.sans],
        mono: ['Fira Code VF', 'Fira Code', ...defaultTheme.fontFamily.mono]
      },
      colors: {
        brand: {
          DEFAULT: '#9428EC',
          '50': '#FDFAFF',
          '100': '#F1E3FC',
          '200': '#DAB4F8',
          '300': '#C285F4',
          '400': '#AB56F0',
          '500': '#9428EC',
          '600': '#7A12CE',
          '700': '#5E0E9F',
          '800': '#420A70',
          '900': '#270642'
        },
        accent: {
          '100': '#E6FFFA',
          '200': '#B2F5EA',
          '300': '#81E6D9',
          '400': '#4FD1C5',
          '500': '#38B2AC',
          '600': '#319795',
          '700': '#2C7A7B',
          '800': '#285E61',
          '900': '#234E52'
        }
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
