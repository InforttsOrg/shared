import React, { useEffect, useRef, useState } from 'react'

interface ParticleEqualizerProps {
  width?: number
  height?: number
  baseRadius?: number
  layers?: number // Number of concentric rings of particles
  particlesPerLayer?: number
  primaryColor?: string
  secondaryColor?: string
  simulatedBpm?: number // BPM for the automatic synthwave generator
  className?: string
  style?: React.CSSProperties
}

class EqualizerParticle {
  angle: number
  layerIndex: number
  targetHeight: number = 0
  currentHeight: number = 0
  velocity: number = 0
  size: number
  colorType: 'primary' | 'secondary'

  constructor(angle: number, layerIndex: number, totalLayers: number) {
    this.angle = angle
    this.layerIndex = layerIndex
    
    // Closer to outer layers = slightly larger particles
    this.size = 1.0 + (layerIndex / totalLayers) * 1.5
    
    // Vary colors between main and secondary tones for premium visual texture
    this.colorType = Math.random() > 0.45 ? 'primary' : 'secondary'
  }

  update(frequencyValue: number) {
    // Apply dampened gravity / spring inertia to the heights for liquid movement
    this.targetHeight = frequencyValue * 120

    const springStrength = 0.15
    const dampening = 0.82

    const acceleration = (this.targetHeight - this.currentHeight) * springStrength
    this.velocity += acceleration
    this.velocity *= dampening
    this.currentHeight += this.velocity
  }
}

export const ParticleEqualizer: React.FC<ParticleEqualizerProps> = ({
  width = 500,
  height = 500,
  baseRadius = 110,
  layers = 6,
  particlesPerLayer = 54,
  primaryColor = 'hsl(190, 85%, 50%)', // Acoustic Cyan
  secondaryColor = 'hsl(205, 80%, 45%)', // Low-frequency Blue
  simulatedBpm = 110,
  className = '',
  style = {}
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const particlesRef = useRef<EqualizerParticle[]>([])
  const animationFrameRef = useRef<number | null>(null)

  // Web Audio Context State
  const [micActive, setMicActive] = useState<boolean>(false)
  const audioCtxRef = useRef<AudioContext | null>(null)
  const analyserRef = useRef<AnalyserNode | null>(null)
  const mediaStreamRef = useRef<MediaStream | null>(null)

  // Interactive Drag States
  const [rotation, setRotation] = useState({ x: 0.6, y: -0.4 })
  const isDragging = useRef(false)
  const previousMousePosition = useRef({ x: 0, y: 0 })
  const autoRotate = useRef(true)

  // Initialize particles list
  useEffect(() => {
    const list: EqualizerParticle[] = []
    for (let l = 0; l < layers; l++) {
      for (let p = 0; p < particlesPerLayer; p++) {
        const angle = (p / particlesPerLayer) * Math.PI * 2
        list.push(new EqualizerParticle(angle, l, layers))
      }
    }
    particlesRef.current = list
  }, [layers, particlesPerLayer])

  // Audio Reactive Loop
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const dpr = window.devicePixelRatio || 1
    canvas.width = width * dpr
    canvas.height = height * dpr
    canvas.style.width = `${width}px`
    canvas.style.height = `${height}px`

    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.scale(dpr, dpr)

    const centerX = width / 2
    const centerY = height / 2
    const FOV = 500 // Camera depth scale

    // Fetch colors
    const resolvedPrimary = primaryColor.startsWith('var(')
      ? getComputedStyle(document.documentElement).getPropertyValue(primaryColor.slice(4, -1)).trim() || 'hsl(190, 85%, 50%)'
      : primaryColor
    const resolvedSecondary = secondaryColor.startsWith('var(')
      ? getComputedStyle(document.documentElement).getPropertyValue(secondaryColor.slice(4, -1)).trim() || 'hsl(205, 80%, 45%)'
      : secondaryColor

    let angleX = rotation.x
    let angleY = rotation.y
    const freqData = new Uint8Array(256)

    // Generator clocks for the built-in simulated synth music
    let time = 0
    const hzFactor = (simulatedBpm / 60) * Math.PI * 2

    const render = () => {
      time += 0.016 // ~16ms tick
      if (autoRotate.current) {
        angleY += 0.002
      }

      ctx.clearRect(0, 0, width, height)

      // 1. Fetch frequency buffer from microphone or generate simulated rhythms
      if (analyserRef.current) {
        analyserRef.current.getByteFrequencyData(freqData)
      } else {
        // Built-in Synthwave rhythmic generator (highly structured low, mid, and high frequencies)
        const kickPulse = Math.max(0, Math.sin(time * hzFactor))
        const snarePulse = Math.max(0, Math.cos(time * hzFactor * 0.5))
        const hihatPulse = Math.abs(Math.sin(time * hzFactor * 4)) * 0.35

        for (let i = 0; i < 256; i++) {
          if (i < 32) {
            // Bass / Kick
            freqData[i] = (kickPulse * 0.75 + Math.sin(time * 8 + i * 0.1) * 0.15) * 255
          } else if (i < 128) {
            // Mids / Snare / Melody
            freqData[i] = (snarePulse * 0.4 + Math.cos(time * 5 + i * 0.05) * 0.2) * 255
          } else {
            // Treble / HiHats
            freqData[i] = (hihatPulse * 0.5 + Math.sin(time * 20 + i * 0.01) * 0.1) * 255
          }
        }
      }

      // 2. Project 3D points
      const project = (x: number, y: number, z: number) => {
        // Rotate Y
        const x1 = x * Math.cos(angleY) - z * Math.sin(angleY)
        const z1 = x * Math.sin(angleY) + z * Math.cos(angleY)

        // Rotate X
        const y2 = y * Math.cos(angleX) - z1 * Math.sin(angleX)
        const z2 = y * Math.sin(angleX) + z1 * Math.cos(angleX)

        const scale = FOV / (FOV + z2)
        const sx = x1 * scale + centerX
        const sy = y2 * scale + centerY

        return { sx, sy, zDepth: z2 }
      }

      // 3. Process & Sort particles by depth to handle overlapping transparency gracefully
      const particles = particlesRef.current
      const projected = particles.map((p) => {
        // Find corresponding index in the frequency data based on particle angle
        const sectorIndex = Math.floor((p.angle / (Math.PI * 2)) * 120)
        const val = freqData[sectorIndex] / 255.0

        p.update(val)

        // Calculate radial coordinates of the concentric layers
        const ringRadius = baseRadius + p.layerIndex * 12
        const rx = ringRadius * Math.cos(p.angle)
        const rz = ringRadius * Math.sin(p.angle)
        
        // Base of the particle (at height 0 in the cylinder plane)
        const baseProj = project(rx, 30, rz)
        // Tall floating visual point
        const tipProj = project(rx, 30 - p.currentHeight * (1.0 - p.layerIndex * 0.08), rz)

        return {
          particle: p,
          base: baseProj,
          tip: tipProj,
          zDepth: tipProj.zDepth
        }
      })

      // Sort by depth (backface elements first)
      projected.sort((a, b) => b.zDepth - a.zDepth)

      // 4. Render particles and volumetric frequency columns
      projected.forEach(({ particle, base, tip, zDepth }) => {
        const isBackFace = zDepth > 100
        const opacity = isBackFace ? 0.25 : 0.85

        const mainColor = particle.colorType === 'primary' ? resolvedPrimary : resolvedSecondary
        
        // Draw physical glowing light beam columns from base to frequency tip
        ctx.beginPath()
        ctx.lineWidth = 1.0 + (layers - particle.layerIndex) * 0.15
        
        const beamGrad = ctx.createLinearGradient(base.sx, base.sy, tip.sx, tip.sy)
        beamGrad.addColorStop(0, `hsla(205, 80%, 45%, ${opacity * 0.02})`)
        beamGrad.addColorStop(0.6, `hsla(190, 85%, 50%, ${opacity * 0.25})`)
        beamGrad.addColorStop(1.0, `${mainColor.replace(')', `, ${opacity})`).replace('hsl', 'hsla')}`)
        
        ctx.strokeStyle = beamGrad
        ctx.moveTo(base.sx, base.sy)
        ctx.lineTo(tip.sx, tip.sy)
        ctx.stroke()

        // Draw particle node bubble floating on the wave tip
        ctx.fillStyle = mainColor.replace(')', `, ${opacity})`).replace('hsl', 'hsla')
        ctx.beginPath()
        ctx.arc(tip.sx, tip.sy, particle.size, 0, Math.PI * 2)
        ctx.fill()
      })

      // Draw active mode HUD
      ctx.fillStyle = 'rgba(255,255,255,0.02)'
      ctx.strokeStyle = 'rgba(255,255,255,0.06)'
      ctx.lineWidth = 1
      ctx.beginPath()
      ctx.roundRect(15, 15, 140, 24, 4)
      ctx.fill()
      ctx.stroke()

      ctx.fillStyle = resolvedSecondary
      ctx.font = 'bold 8px var(--font-mono)'
      ctx.textAlign = 'left'
      ctx.textBaseline = 'middle'
      ctx.fillText(micActive ? '🎙️ MIC STREAM ACTIVE' : '⚡ RHYTHM SIMULATION', 25, 27)

      animationFrameRef.current = requestAnimationFrame(render)
    }

    render()

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current)
      }
    }
  }, [rotation, width, height, baseRadius, layers, particlesPerLayer, primaryColor, secondaryColor, simulatedBpm, micActive])

  // Microphone stream activations
  const toggleMicrophone = async () => {
    if (micActive) {
      // Shutdown mic
      if (mediaStreamRef.current) {
        mediaStreamRef.current.getTracks().forEach(t => t.stop())
      }
      analyserRef.current = null
      audioCtxRef.current = null
      setMicActive(false)
    } else {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
        const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)()
        const source = audioCtx.createMediaStreamSource(stream)
        const analyser = audioCtx.createAnalyser()
        
        analyser.fftSize = 512
        source.connect(analyser)

        analyserRef.current = analyser
        audioCtxRef.current = audioCtx
        mediaStreamRef.current = stream
        setMicActive(true)
      } catch (err) {
        console.error('Failed to capture microphone input stream:', err)
        alert('Microphone access denied. Falling back to rhythm simulation.')
      }
    }
  }

  // Drag Interactions
  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    isDragging.current = true
    autoRotate.current = false
    previousMousePosition.current = {
      x: e.clientX,
      y: e.clientY
    }
  }

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDragging.current) return

    const deltaX = e.clientX - previousMousePosition.current.x
    const deltaY = e.clientY - previousMousePosition.current.y

    setRotation((prev) => ({
      x: Math.max(0.1, Math.min(Math.PI / 2.2, prev.x + deltaY * 0.007)),
      y: prev.y + deltaX * 0.007
    }))

    previousMousePosition.current = {
      x: e.clientX,
      y: e.clientY
    }
  }

  const handleMouseUp = () => {
    isDragging.current = false
    setTimeout(() => {
      if (!isDragging.current) {
        autoRotate.current = true
      }
    }, 4000)
  }

  return (
    <div
      className={`aces-volumetric-card ${className}`}
      style={{
        width: `${width}px`,
        height: `${height}px`,
        display: 'inline-block',
        position: 'relative',
        borderRadius: '8px',
        border: '1px solid var(--border)',
        background: 'var(--aces-dark-carbon)',
        cursor: isDragging.current ? 'grabbing' : 'grab',
        ...style
      }}
    >
      <canvas
        ref={canvasRef}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        style={{
          display: 'block'
        }}
      />
      
      {/* Microphone toggle HUD element */}
      <button
        onClick={toggleMicrophone}
        style={{
          position: 'absolute',
          bottom: '15px',
          right: '15px',
          background: micActive ? 'rgba(14, 211, 244, 0.15)' : 'rgba(255, 255, 255, 0.03)',
          border: `1px solid ${micActive ? 'var(--primary)' : 'var(--border)'}`,
          color: micActive ? 'var(--primary)' : 'var(--text-secondary)',
          padding: '6px 12px',
          borderRadius: '4px',
          fontSize: '9px',
          fontWeight: '700',
          fontFamily: 'var(--font-mono)',
          cursor: 'pointer',
          textTransform: 'uppercase',
          letterSpacing: '0.5px',
          transition: 'all 0.2s'
        }}
      >
        {micActive ? '🎙️ STOP MONITOR' : '🎙️ LIVE MICROPHONE'}
      </button>
    </div>
  )
}
