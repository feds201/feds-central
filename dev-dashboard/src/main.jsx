import { Buffer } from 'buffer'
import '@/styles/globals.css'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from '@/App'
import '@neondatabase/neon-js/ui/css'

// Make Buffer available globally
window.Buffer = Buffer

ReactDOM.createRoot(document.getElementById('app')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
