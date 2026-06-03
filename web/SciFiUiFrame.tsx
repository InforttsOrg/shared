import React from 'react'

interface SciFiUiFrameProps {
  title?: string
  description?: string
  sideLabel?: string
  options?: string[]
  activeOptionIndex?: number
  onOptionChange?: (index: number) => void
  accentColor?: string // e.g. "var(--primary)" or "hsl(190, 85%, 50%)"
  secondaryColor?: string // e.g. "var(--text-secondary)" or "hsl(213, 10%, 65%)"
  children?: React.ReactNode
  className?: string
  style?: React.CSSProperties
}

export const SciFiUiFrame: React.FC<SciFiUiFrameProps> = ({
  title = "EXPERIMENT_STATE",
  description = "Dynamic holographic render of acoustic refraction wavefields.",
  sideLabel = "REFRACT_OS // VER 1.0.4",
  options = ['FLOW_01', 'FLOW_02', 'FLOW_03', 'FLOW_04'],
  activeOptionIndex = 0,
  onOptionChange,
  accentColor = 'var(--primary)',
  secondaryColor = 'var(--text-secondary)',
  children,
  className = '',
  style = {}
}) => {
  return (
    <div className={`scifi-shot-container ${className}`} style={{ ...style, '--accent-color': accentColor, '--secondary-color': secondaryColor } as React.CSSProperties}>
      <style>{`
        .scifi-shot-container {
          width: 100%;
          max-width: 450px;
          margin: auto;
          position: relative;
          font-family: var(--font-sans), 'Barlow', sans-serif;
          --accent-glow: rgba(14, 211, 244, 0.15);
        }

        /* Cinematic flickering entrance animation */
        @keyframes scifi-entrance {
          to, 20%, 40%, 60%, 80% { opacity: 1; }
          from, 10%, 30%, 50%, 70%, 90% { opacity: 0; }
        }

        .scifi-card {
          width: 100%;
          height: 320px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(0deg, var(--primary-bg) 0%, rgba(9, 13, 22, 0.4) 100%);
          border: 1px solid var(--accent-color);
          border-radius: 6px;
          box-shadow: 
            inset 0 0 20px var(--accent-glow),
            0 12px 32px rgba(0, 0, 0, 0.5);
          backdrop-filter: blur(12px) saturate(45%);
          position: relative;
          overflow: hidden;
          opacity: 0;
          animation: scifi-entrance 650ms 200ms linear forwards 1;
        }

        .scifi-card::after {
          content: "";
          position: absolute;
          inset: 0;
          pointer-events: none;
          background: linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(56, 189, 248, 0.02) 40%, rgba(0, 0, 0, 0) 100%);
        }

        .scifi-component-wrapper {
          margin: auto;
          width: 100%;
          height: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .scifi-description {
          margin-top: 15px;
          opacity: 0;
          animation: scifi-entrance 650ms 450ms linear forwards 1;
        }

        .scifi-description h1 {
          font-family: var(--font-heading), 'Outfit', sans-serif;
          background-color: var(--accent-color);
          padding: 3px 8px 5px 8px;
          color: var(--bg-dark, #05070c);
          letter-spacing: 1.5px;
          text-transform: uppercase;
          font-size: 20px;
          font-weight: 700;
          margin: 15px 0 8px;
          border: 1px solid var(--accent-color);
          border-radius: 4px;
          display: inline-block;
          text-shadow: none;
        }

        .scifi-description p {
          color: var(--secondary-color);
          opacity: 0.8;
          font-size: 13px;
          font-weight: 500;
          line-height: 1.5;
          letter-spacing: 0.5px;
          margin: 0;
        }

        .scifi-title-bar {
          height: 100%;
          width: 3px;
          position: absolute;
          top: 0;
          left: -40px;
          background: var(--accent-color);
          box-shadow: 0 0 10px var(--accent-color);
          opacity: 0;
          animation: scifi-entrance 650ms 650ms linear forwards 1;
        }

        .scifi-title-bar::before {
          content: attr(data-label);
          color: var(--accent-color);
          font-family: var(--font-mono), monospace;
          font-size: 9px;
          font-weight: 600;
          text-transform: uppercase;
          text-align: right;
          white-space: nowrap;
          position: absolute;
          left: -110px;
          top: -15px;
          width: 100px;
          transform-origin: 100% 100%;
          transform: rotateZ(-90deg);
          letter-spacing: 1.5px;
          opacity: 0.7;
        }

        .scifi-options {
          width: 180px;
          position: absolute;
          top: 0;
          right: -200px;
          opacity: 0;
          animation: scifi-entrance 650ms 850ms linear forwards 1;
        }

        .scifi-options p {
          color: var(--accent-color);
          font-family: var(--font-mono), monospace;
          font-size: 10px;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin: 0 0 10px 0;
          opacity: 0.8;
        }

        .scifi-btns {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .scifi-btn {
          height: 38px;
          padding: 0 12px;
          border: 1px solid var(--border, rgba(255,255,255,0.08));
          outline: 1px solid var(--accent-color);
          outline-offset: -3px;
          background-color: transparent;
          font-family: var(--font-mono), monospace;
          font-size: 12px;
          letter-spacing: 1px;
          color: var(--text-primary, #fff);
          cursor: pointer;
          transition: all 450ms cubic-bezier(0.16, 1, 0.3, 1);
          text-align: left;
          text-transform: uppercase;
          border-radius: 2px;
        }

        .scifi-btn:hover, .scifi-btn:focus {
          background-color: var(--primary-bg);
          outline-offset: 0px;
          box-shadow: 0 0 10px var(--accent-glow);
        }

        .scifi-btn.active {
          outline: 1px solid var(--accent-color);
          outline-offset: 0px;
          border-color: var(--accent-color);
          background-color: var(--accent-color);
          color: var(--bg-dark, #05070c) !important;
          font-weight: 700;
          box-shadow: 0 0 15px var(--accent-glow);
        }

        /* Responsive handling if containers are narrow */
        @media (max-width: 900px) {
          .scifi-shot-container {
            max-width: 100%;
            padding-left: 50px;
            padding-right: 200px;
          }
        }

        @media (max-width: 768px) {
          .scifi-shot-container {
            padding: 0;
            margin-bottom: 220px; /* Leave space for options below if wrapped */
          }
          .scifi-options {
            position: static;
            width: 100%;
            margin-top: 20px;
          }
          .scifi-btns {
            flex-direction: row;
            flex-wrap: wrap;
          }
          .scifi-btn {
            flex: 1 1 calc(50% - 5px);
          }
          .scifi-title-bar {
            display: none;
          }
        }
      `}</style>

      <div className="scifi-card">
        <div id="component" className="scifi-component-wrapper">
          {children}
        </div>
      </div>

      <div className="scifi-description">
        <h1>{title}</h1>
        <p>{description}</p>
      </div>

      <div className="scifi-title-bar" data-label={sideLabel}></div>

      {options && options.length > 0 && (
        <div className="scifi-options">
          <p>TRANSITION_MODE</p>
          <div className="scifi-btns">
            {options.map((option, index) => (
              <button
                key={index}
                className={`scifi-btn ${activeOptionIndex === index ? 'active' : ''}`}
                onClick={() => onOptionChange?.(index)}
              >
                {option}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
