import React, { forwardRef } from 'react';
import { astryxTokens } from './tokens';

export type CardVariant = 'matte' | 'elevated' | 'interactive' | 'glass' | 'glow';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant;
  padding?: 'none' | 'sm' | 'md' | 'lg';
}

const variantStyles: Record<CardVariant, string> = {
  matte:
    'bg-[#101218]/90 backdrop-blur-md border border-white/[0.08] text-[#E2E8F0] shadow-[0_10px_30px_-10px_rgba(0,0,0,0.5)]',
  elevated:
    'bg-[#14161f] border border-white/[0.12] text-[#E2E8F0] shadow-[0_20px_40px_-15px_rgba(0,0,0,0.7)]',
  interactive:
    'bg-[#101218]/90 backdrop-blur-md border border-white/[0.08] text-[#E2E8F0] hover:border-[#00D2FF]/50 hover:shadow-[0_0_30px_rgba(0,210,255,0.15)] hover:-translate-y-0.5 transition-all duration-300',
  glass:
    'bg-[#121B2D]/60 backdrop-blur-xl border border-white/[0.1] text-white shadow-[0_8px_32px_0_rgba(0,0,0,0.37)]',
  glow:
    'bg-[#101218]/95 border border-[#C800DF]/30 text-white shadow-[0_0_35px_-5px_rgba(200,0,223,0.25)]',
};

const paddingStyles = {
  none: '',
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8',
};

export const Card = forwardRef<HTMLDivElement, CardProps>(
  ({ variant = 'matte', padding = 'md', className = '', children, style, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={`rounded-xl overflow-hidden font-sans ${variantStyles[variant]} ${paddingStyles[padding]} ${className}`}
        style={{
          fontFamily: astryxTokens.fonts.sans,
          ...style,
        }}
        {...props}
      >
        {children}
      </div>
    );
  }
);
Card.displayName = 'AstryxCard';

export const CardHeader = forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className = '', children, ...props }, ref) => (
    <div ref={ref} className={`flex flex-col space-y-1.5 pb-4 ${className}`} {...props}>
      {children}
    </div>
  )
);
CardHeader.displayName = 'AstryxCardHeader';

export const CardTitle = forwardRef<HTMLHeadingElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className = '', children, ...props }, ref) => (
    <h3
      ref={ref}
      className={`text-lg font-semibold tracking-tight text-white ${className}`}
      {...props}
    >
      {children}
    </h3>
  )
);
CardTitle.displayName = 'AstryxCardTitle';

export const CardDescription = forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className = '', children, ...props }, ref) => (
  <p ref={ref} className={`text-sm text-[#94A3B8] ${className}`} {...props}>
    {children}
  </p>
));
CardDescription.displayName = 'AstryxCardDescription';

export const CardContent = forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className = '', children, ...props }, ref) => (
    <div ref={ref} className={`pt-0 ${className}`} {...props}>
      {children}
    </div>
  )
);
CardContent.displayName = 'AstryxCardContent';

export const CardFooter = forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className = '', children, ...props }, ref) => (
    <div ref={ref} className={`flex items-center pt-4 border-t border-white/[0.06] ${className}`} {...props}>
      {children}
    </div>
  )
);
CardFooter.displayName = 'AstryxCardFooter';
