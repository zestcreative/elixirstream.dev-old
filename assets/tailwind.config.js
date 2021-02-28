module.exports = {
  purge: [
    '../lib/elixir_stream_web/live/**/*.ex',
    '../lib/elixir_stream_web/live/**/*.leex',
    '../lib/elixir_stream_web/templates/**/*.eex',
    '../lib/elixir_stream_web/templates/**/*.leex',
    '../lib/elixir_stream_web/views/**/*.ex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
