/**
 * Astryx Design System Tokens
 * Canonical Infortts Web Design System & Contemporary Matte Aesthetics
 */

export const astryxTokens = {
  colors: {
    canvas: '#090a0f',
    obsidian: '#0D1117',
    darkCarbon: '#090D1A',
    panelBg: '#121B2D',
    activeCard: '#1D2A44',
    black: '#05070C',
    white: '#FFFFFF',
    matte: {
      50: '#1a1c24',
      100: '#14161f',
      200: '#101218',
      300: '#0c0d12',
      400: '#08090d',
    },
    contemporary: {
      magenta: '#C800DF',
      rose: '#E60076',
      violet: '#8B5CF6',
      cyan: '#06B6D4',
      emerald: '#10B981',
      amber: '#F59E0B',
    },
    sonar: {
      cyan: '#00D2FF',
      cyanDim: '#005566',
      blue: '#0066FF',
      deepBlue: '#0B2A6B',
    },
    text: {
      primary: '#FFFFFF',
      titanium: '#E2E8F0',
      secondary: '#94A3B8',
      muted: '#64748B',
    },
    border: {
      subtle: 'rgba(255, 255, 255, 0.08)',
      default: 'rgba(255, 255, 255, 0.15)',
      active: 'rgba(0, 210, 255, 0.4)',
      glow: 'rgba(200, 0, 223, 0.4)',
    },
  },
  gradients: {
    house: 'linear-gradient(135deg, #00D2FF 0%, #0066FF 50%, #0B2A6B 100%)',
    astryx: 'linear-gradient(135deg, #C800DF 0%, #8B5CF6 50%, #00D2FF 100%)',
    neon: 'linear-gradient(135deg, #00F0FF 0%, #7B2BFF 50%, #FF1FA8 100%)',
    glass: 'linear-gradient(120deg, rgba(127, 224, 255, 0.2) 0%, rgba(184, 166, 255, 0.1) 50%, rgba(255, 158, 219, 0.05) 100%)',
    aurora: 'linear-gradient(120deg, #00E5A0 0%, #00B3FF 50%, #7A5CFF 100%)',
    matteSurface: 'linear-gradient(180deg, rgba(26, 28, 36, 0.8) 0%, rgba(16, 18, 24, 0.95) 100%)',
  },
  fonts: {
    sans: "'Jost', 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    mono: "'JetBrains Mono', 'Agave', Menlo, Monaco, Consolas, monospace",
  },
  shadows: {
    glowMagenta: '0 0 35px -5px rgba(200, 0, 223, 0.35)',
    glowCyan: '0 0 35px -5px rgba(6, 182, 212, 0.35)',
    glowSonar: '0 0 35px -5px rgba(0, 210, 255, 0.35)',
    glowViolet: '0 0 35px -5px rgba(139, 92, 246, 0.35)',
    matteCard: '0 10px 30px -10px rgba(0, 0, 0, 0.5)',
    elevated: '0 20px 40px -15px rgba(0, 0, 0, 0.7)',
  },
  radii: {
    none: '0px',
    sm: '4px',
    md: '8px',
    lg: '12px',
    xl: '16px',
    '2xl': '24px',
    full: '9999px',
  },
  transitions: {
    fast: '150ms cubic-bezier(0.4, 0, 0.2, 1)',
    normal: '250ms cubic-bezier(0.4, 0, 0.2, 1)',
    slow: '400ms cubic-bezier(0.4, 0, 0.2, 1)',
  },
} as const;

export type AstryxTokens = typeof astryxTokens;
