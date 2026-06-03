import React, { useEffect, useRef, useState } from 'react'

export interface GlobeDataPoint {
  lat: number
  lng: number
  size: number // value of the spike (e.g. from 0 to 1)
  color?: string // optional custom spike color
  label?: string // hover text label
}

interface WebGLGlobeProps {
  data?: GlobeDataPoint[]
  width?: number
  height?: number
  globeRadius?: number
  autoRotateSpeed?: number
  primaryColor?: string
  secondaryColor?: string
  gridOpacity?: number
  className?: string
  style?: React.CSSProperties
}

// Pre-seeded telemetry nodes mapping actual global server coordinates
const SEEDED_TELEMETRY: GlobeDataPoint[] = [
  { lat: 40.7128, lng: -74.0060, size: 0.85, label: 'NEW YORK (MITOCHONDRIA-GATEWAY)' },
  { lat: 35.6762, lng: 139.6503, size: 0.95, label: 'TOKYO (CYANOBACTERIA-RECEPTOR)' },
  { lat: 51.5074, lng: -0.1278, size: 0.65, label: 'LONDON (MEESEEKS-COUNCIL)' },
  { lat: -33.8688, lng: 151.2093, size: 0.70, label: 'SYDNEY (KIMBERELLA-REGISTRY)' },
  { lat: 37.7749, lng: -122.4194, size: 0.90, label: 'SAN FRANCISCO (EDIACARA-GATEWAY)' },
  { lat: -22.9068, lng: -43.1729, size: 0.45, label: 'RIO DE JANEIRO (LEXI-POS-CORE)' },
  { lat: 55.7558, lng: 37.6173, size: 0.50, label: 'MOSCOW (ROOST-LEDGER-STORAGE)' },
  { lat: -1.2921, lng: 36.8219, size: 0.40, label: 'NAIROBI (CARE4U-ESCROW-POOL)' },
  { lat: 1.3521, lng: 103.8198, size: 0.80, label: 'SINGAPORE (SPARK-GEOSPATIAL)' }
]

export const WebGLGlobe: React.FC<WebGLGlobeProps> = ({
  data = SEEDED_TELEMETRY,
  width = 500,
  height = 500,
  globeRadius = 160,
  autoRotateSpeed = 0.003,
  primaryColor = 'hsl(190, 85%, 50%)', // Acoustic Cyan
  secondaryColor = 'hsl(213, 10%, 65%)', // Warm Metallic Steel
  gridOpacity = 0.08,
  className = '',
  style = {}
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  
  // Interactive drag rotation states
  const [rotation, setRotation] = useState({ x: 0.4, y: 0.5 })
  const isDragging = useRef(false)
  const previousMousePosition = useRef({ x: 0, y: 0 })
  const autoRotate = useRef(true)



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
    const FOV = 600 // Perspective camera depth

    // Extract colors to CSS clean formats
    const resolvedPrimary = primaryColor.startsWith('var(')
      ? getComputedStyle(document.documentElement).getPropertyValue(primaryColor.slice(4, -1)).trim() || 'hsl(190, 85%, 50%)'
      : primaryColor
    const resolvedSecondary = secondaryColor.startsWith('var(')
      ? getComputedStyle(document.documentElement).getPropertyValue(secondaryColor.slice(4, -1)).trim() || 'hsl(213, 10%, 65%)'
      : secondaryColor

    let angleX = rotation.x
    let angleY = rotation.y
    let animationFrameId: number

    // Render loop
    const tick = () => {
      if (autoRotate.current) {
        angleY += autoRotateSpeed
      }

      ctx.clearRect(0, 0, width, height)

      // Draw subtle background ambient lighting grid glow
      const grad = ctx.createRadialGradient(centerX, centerY, globeRadius * 0.8, centerX, centerY, globeRadius * 1.5)
      grad.addColorStop(0, 'rgba(14, 211, 244, 0.01)')
      grad.addColorStop(1, 'rgba(0, 0, 0, 0)')
      ctx.fillStyle = grad
      ctx.beginPath()
      ctx.arc(centerX, centerY, globeRadius * 1.5, 0, Math.PI * 2)
      ctx.fill()

      // Function to rotate and project a 3D cartesian point
      const project = (x: number, y: number, z: number) => {
        // Y-axis rotation (longitude)
        const x1 = x * Math.cos(angleY) - z * Math.sin(angleY)
        const z1 = x * Math.sin(angleY) + z * Math.cos(angleY)

        // X-axis rotation (latitude)
        const y2 = y * Math.cos(angleX) - z1 * Math.sin(angleX)
        const z2 = y * Math.sin(angleX) + z1 * Math.cos(angleX)

        // Perspective scale factor
        const scale = FOV / (FOV + z2)
        const sx = x1 * scale + centerX
        const sy = y2 * scale + centerY

        return { sx, sy, zDepth: z2 }
      }

      // Draw grid rings (Latitudinal & Longitudinal telemetry orbits)
      ctx.lineWidth = 1
      const rings = 12
      
      // Step A: Draw Latitude Rings
      for (let i = 1; i < rings; i++) {
        const lat = (i / rings) * Math.PI - Math.PI / 2
        const r = globeRadius * Math.cos(lat)
        const ringY = -globeRadius * Math.sin(lat)

        ctx.beginPath()
        let isFirst = true
        for (let j = 0; j <= 60; j++) {
          const lng = (j / 60) * Math.PI * 2
          const rx = r * Math.sin(lng)
          const rz = r * Math.cos(lng)

          const { sx, sy, zDepth } = project(rx, ringY, rz)
          
          // Translucent back hemisphere, solid front hemisphere
          const alpha = zDepth > 0 ? gridOpacity * 0.25 : gridOpacity
          ctx.strokeStyle = `hsla(190, 85%, 50%, ${alpha})`
          
          if (isFirst) {
            ctx.moveTo(sx, sy)
            isFirst = false
          } else {
            ctx.lineTo(sx, sy)
          }
        }
        ctx.stroke()
      }

      // Step B: Draw Longitude Rings
      for (let i = 0; i < rings; i++) {
        const lng = (i / rings) * Math.PI * 2

        ctx.beginPath()
        let isFirst = true
        for (let j = 0; j <= 60; j++) {
          const lat = (j / 60) * Math.PI - Math.PI / 2
          const r = globeRadius * Math.cos(lat)
          const rx = r * Math.sin(lng)
          const ry = -globeRadius * Math.sin(lat)
          const rz = r * Math.cos(lng)

          const { sx, sy, zDepth } = project(rx, ry, rz)
          
          const alpha = zDepth > 0 ? gridOpacity * 0.25 : gridOpacity
          ctx.strokeStyle = `hsla(190, 85%, 50%, ${alpha})`

          if (isFirst) {
            ctx.moveTo(sx, sy)
            isFirst = false
          } else {
            ctx.lineTo(sx, sy)
          }
        }
        ctx.stroke()
      }

      // Step C: Draw Equator highlighting orbit ring
      ctx.lineWidth = 1.5
      ctx.strokeStyle = `hsla(190, 85%, 50%, ${gridOpacity * 2.5})`
      ctx.beginPath()
      let isEquatorFirst = true
      for (let j = 0; j <= 72; j++) {
        const lng = (j / 72) * Math.PI * 2
        const rx = globeRadius * Math.sin(lng)
        const rz = globeRadius * Math.cos(lng)
        const { sx, sy } = project(rx, 0, rz)
        if (isEquatorFirst) {
          ctx.moveTo(sx, sy)
          isEquatorFirst = false
        } else {
          ctx.lineTo(sx, sy)
        }
      }
      ctx.stroke()

      // Step D: Render Telemetry data spikes (depth sorted)
      const projectedSpikes = data.map((pt) => {
        // Convert Lat/Lng to spherical coordinates
        const phi = (90 - pt.lat) * (Math.PI / 180)
        const theta = (pt.lng + 180) * (Math.PI / 180)

        // Sphere Surface coordinate (Base of the data spike)
        const bx = globeRadius * Math.sin(phi) * Math.sin(theta)
        const by = -globeRadius * Math.cos(phi)
        const bz = globeRadius * Math.sin(phi) * Math.cos(theta)

        // Spike Tip coordinate
        const spikeHeight = globeRadius * 0.35 * pt.size
        const tx = (globeRadius + spikeHeight) * Math.sin(phi) * Math.sin(theta)
        const ty = -(globeRadius + spikeHeight) * Math.cos(phi)
        const tz = (globeRadius + spikeHeight) * Math.sin(phi) * Math.cos(theta)

        const baseProj = project(bx, by, bz)
        const tipProj = project(tx, ty, tz)

        return {
          pt,
          base: baseProj,
          tip: tipProj,
          zDepth: (baseProj.zDepth + tipProj.zDepth) / 2
        }
      })

      // Sort projected coordinates by depth to draw back face spikes first and avoid occlusion bugs
      projectedSpikes.sort((a, b) => b.zDepth - a.zDepth)

      let nearestLabel: string | null = null
      let minDistance = 25

      projectedSpikes.forEach(({ pt, base, tip, zDepth }) => {
        const isBackFace = zDepth > 0

        // Skip far back hemisphere rendering of spikes for better legibility
        if (isBackFace) {
          ctx.lineWidth = 1
          ctx.strokeStyle = 'rgba(14, 211, 244, 0.08)'
          ctx.beginPath()
          ctx.moveTo(base.sx, base.sy)
          ctx.lineTo(tip.sx, tip.sy)
          ctx.stroke()
          return
        }

        // Front face telemetry rendering
        const spikeColor = pt.color || resolvedPrimary
        
        // Render 3D Spike Column Gradient
        const spikeGrad = ctx.createLinearGradient(base.sx, base.sy, tip.sx, tip.sy)
        spikeGrad.addColorStop(0, 'rgba(14, 211, 244, 0.05)')
        spikeGrad.addColorStop(0.5, 'rgba(14, 211, 244, 0.45)')
        spikeGrad.addColorStop(1, spikeColor)

        ctx.strokeStyle = spikeGrad
        ctx.lineWidth = 2.5
        ctx.beginPath()
        ctx.moveTo(base.sx, base.sy)
        ctx.lineTo(tip.sx, tip.sy)
        ctx.stroke()

        // Core base server node marker
        ctx.fillStyle = resolvedSecondary
        ctx.beginPath()
        ctx.arc(base.sx, base.sy, 2, 0, Math.PI * 2)
        ctx.fill()

        // Emissive light node blooming at the spike tip
        ctx.fillStyle = spikeColor
        ctx.shadowColor = spikeColor
        ctx.shadowBlur = 10
        ctx.beginPath()
        ctx.arc(tip.sx, tip.sy, 3 + pt.size * 1.5, 0, Math.PI * 2)
        ctx.fill()
        ctx.shadowBlur = 0 // reset shadow blur to avoid performance drag

        // Hover distance check on Canvas
        const mouseX = previousMousePosition.current.x
        const mouseY = previousMousePosition.current.y
        const distToTip = Math.sqrt(Math.pow(tip.sx - mouseX, 2) + Math.pow(tip.sy - mouseY, 2))
        if (distToTip < minDistance) {
          minDistance = distToTip
          nearestLabel = pt.label || `SERVER NODE [${pt.lat.toFixed(2)}, ${pt.lng.toFixed(2)}]`
        }
      })



      // Draw hover utility tooltip overlay on Canvas
      if (nearestLabel) {
        ctx.fillStyle = 'rgba(18, 20, 26, 0.88)'
        ctx.strokeStyle = 'rgba(14, 211, 244, 0.35)'
        ctx.lineWidth = 1
        
        const textWidth = ctx.measureText(nearestLabel).width
        const boxWidth = textWidth + 24
        const boxHeight = 28
        const bx = Math.max(10, Math.min(width - boxWidth - 10, previousMousePosition.current.x + 15))
        const by = Math.max(10, Math.min(height - boxHeight - 10, previousMousePosition.current.y - 35))

        // Draw HUD container card
        ctx.beginPath()
        ctx.roundRect(bx, by, boxWidth, boxHeight, 4)
        ctx.fill()
        ctx.stroke()

        // Draw telemetry label
        ctx.fillStyle = resolvedSecondary
        ctx.font = 'bold 9px var(--font-mono)'
        ctx.textAlign = 'left'
        ctx.textBaseline = 'middle'
        ctx.fillText(nearestLabel, bx + 12, by + boxHeight / 2)
      }

      animationFrameId = requestAnimationFrame(tick)
    }

    tick()

    return () => {
      cancelAnimationFrame(animationFrameId)
    }
  }, [data, rotation, width, height, globeRadius, autoRotateSpeed, primaryColor, secondaryColor, gridOpacity])

  // Canvas Mouse Drag Interaction Handlers
  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    isDragging.current = true
    autoRotate.current = false
    previousMousePosition.current = {
      x: e.clientX,
      y: e.clientY
    }
  }

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const rect = canvasRef.current?.getBoundingClientRect()
    if (!rect) return

    // Feed current relative coordinates for tooltips
    const relativeX = e.clientX - rect.left
    const relativeY = e.clientY - rect.top

    if (!isDragging.current) {
      previousMousePosition.current = { x: relativeX, y: relativeY }
      return
    }

    // Drag delta
    const deltaX = e.clientX - previousMousePosition.current.x
    const deltaY = e.clientY - previousMousePosition.current.y

    setRotation((prev) => ({
      x: Math.max(-Math.PI / 2.2, Math.min(Math.PI / 2.2, prev.x + deltaY * 0.007)),
      y: prev.y + deltaX * 0.007
    }))

    previousMousePosition.current = {
      x: e.clientX,
      y: e.clientY
    }
  }

  const handleMouseUp = () => {
    isDragging.current = false
    // Restore auto-rotation gently after inactivity
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
    </div>
  )
}
