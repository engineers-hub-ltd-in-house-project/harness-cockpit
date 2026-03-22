// Harness Cockpit favicon as inline SVG data URI
// Shield icon with H letter, representing harness/guard concept
export const faviconSvg = `data:image/svg+xml,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#539bf5"/>
      <stop offset="100%" stop-color="#2d6abf"/>
    </linearGradient>
  </defs>
  <rect x="4" y="4" width="56" height="56" rx="12" fill="#1a1e24" stroke="url(#g)" stroke-width="3"/>
  <path d="M20 18 L32 12 L44 18 L44 34 C44 42 38 48 32 52 C26 48 20 42 20 34 Z"
        fill="none" stroke="url(#g)" stroke-width="2.5" stroke-linejoin="round"/>
  <text x="32" y="40" text-anchor="middle" font-family="monospace" font-size="18" font-weight="bold" fill="#539bf5">H</text>
</svg>
`)}`;
