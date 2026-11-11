import React, { forwardRef } from 'react';
import { astryxTokens } from './tokens';

export type BadgeVariant =
  | 'default'
  | 'cyan'
  | 'sonar'
  | 'magenta'
  | 'violet'
  | 'success'
  | 'warning'
  | 'outline';

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant;
  size?: 'sm' | 'md';
  dot?: boolean;
  pulseDot?: boolean;
  icon?: React.ReactNode;
}

const variantStyles: Record<BadgeVariant, string> = {
  default: 'bg-white/10 text-[#E2E8F0] border border-white/10',
  cyan: 'bg-[#06B6D4]/15 text-[#06B6D4] border border-[#06B6D4]/30 shadow-[0_0_12px_rgba(6,182,212,0.2)]',
  sonar: 'bg-[#00D2FF]/15 text-[#00D2FF] border border-[#00D2FF]/40 shadow-[0_0_15px_rgba(0,210,255,0.25)]',
  magenta: 'bg-[#C800DF]/15 text-[#C800DF] border border-[#C800DF]/30 shadow-[0_0_12px_rgba(200,0,223,0.2)]',
  violet: 'bg-[#8B5CF6]/15 text-[#8B5CF6] border border-[#8B5CF6]/30 shadow-[0_0_12px_rgba(139,92,246,0.2)]',
  success: 'bg-[#10B981]/15 text-[#10B981] border border-[#10B981]/30 shadow-[0_0_12px_rgba(16,185,129,0.2)]',
  warning: 'bg-[#F59E0B]/15 text-[#F59E0B] border border-[#F59E0B]/30 shadow-[0_0_12px_rgba(245,158,11,0.2)]',
  outline: 'bg-transparent text-[#94A3B8] border border-white/20',
};

const dotColors: Record<BadgeVariant, string> = {
  default: 'bg-slate-400',
  cyan: 'bg-[#06B6D4]',
  sonar: 'bg-[#00D2FF]',
  magenta: 'bg-[#C800DF]',
  violet: 'bg-[#8B5CF6]',
  success: 'bg-[#10B981]',
  warning: 'bg-[#F59E0B]',
  outline: 'bg-slate-400',
};

export const Badge = forwardRef<HTMLSpanElement, BadgeProps>(
  (
    {
      variant = 'default',
      size = 'md',
      dot = false,
      pulseDot = false,
      icon,
      className = '',
      children,
      style,
      ...props
    },
    ref
  ) => {
    const sizeCls = size === 'sm' ? 'px-2 py-0.5 text-[10px]' : 'px-2.5 py-1 text-xs';

    return (
      <span
        ref={ref}
        className={`inline-flex items-center gap-1.5 font-medium rounded-full tracking-wide uppercase font-mono ${sizeCls} ${variantStyles[variant]} ${className}`}
        style={{
          fontFamily: astryxTokens.fonts.mono,
          ...style,
        }}
        {...props}
      >
        {dot && (
          <span className="relative flex h-2 w-2">
            {pulseDot && (
              <span
                className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${dotColors[variant]}`}
              />
            )}
            <span
              className={`relative inline-flex rounded-full h-2 w-2 ${dotColors[variant]}`}
            />
          </span>
        )}
        {icon && <span className="inline-flex shrink-0">{icon}</span>}
        <span>{children}</span>
      </span>
    );
  }
);

Badge.displayName = 'AstryxBadge';
