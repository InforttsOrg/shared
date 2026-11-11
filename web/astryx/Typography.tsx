import React, { forwardRef } from 'react';
import { astryxTokens } from './tokens';

export interface HeadingProps extends React.HTMLAttributes<HTMLHeadingElement> {
  as?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6';
  gradient?: 'none' | 'astryx' | 'house' | 'neon';
}

const headingSizes = {
  h1: 'text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight',
  h2: 'text-3xl sm:text-4xl font-bold tracking-tight',
  h3: 'text-2xl sm:text-3xl font-bold tracking-tight',
  h4: 'text-xl sm:text-2xl font-semibold tracking-tight',
  h5: 'text-lg sm:text-xl font-semibold',
  h6: 'text-base font-semibold',
};

const gradientStyles = {
  none: 'text-white',
  astryx: 'text-transparent bg-clip-text bg-gradient-to-r from-[#C800DF] via-[#8B5CF6] to-[#00D2FF]',
  house: 'text-transparent bg-clip-text bg-gradient-to-r from-[#00D2FF] via-[#0066FF] to-[#8B5CF6]',
  neon: 'text-transparent bg-clip-text bg-gradient-to-r from-[#00F0FF] via-[#7B2BFF] to-[#FF1FA8]',
};

export const Heading = forwardRef<HTMLHeadingElement, HeadingProps>(
  ({ as = 'h2', gradient = 'none', className = '', children, style, ...props }, ref) => {
    return React.createElement(
      as,
      {
        ref,
        className: `font-sans ${headingSizes[as]} ${gradientStyles[gradient]} ${className}`,
        style: {
          fontFamily: astryxTokens.fonts.sans,
          ...style,
        },
        ...props,
      },
      children
    );
  }
);
Heading.displayName = 'AstryxHeading';

export interface TextProps extends React.HTMLAttributes<HTMLElement> {
  variant?: 'body' | 'lead' | 'small' | 'muted' | 'mono';
  as?: 'p' | 'span' | 'div';
}

const textVariants = {
  body: 'text-base text-[#E2E8F0] leading-relaxed',
  lead: 'text-lg sm:text-xl text-[#CBD5E1] font-light leading-relaxed',
  small: 'text-sm text-[#94A3B8] leading-normal',
  muted: 'text-sm text-[#64748B] leading-normal',
  mono: 'text-xs text-[#00D2FF] font-mono tracking-wide',
};

export const Text = forwardRef<HTMLElement, TextProps>(
  ({ variant = 'body', as = 'p', className = '', children, style, ...props }, ref) => {
    const isMono = variant === 'mono';
    return React.createElement(
      as,
      {
        ref,
        className: `${textVariants[variant]} ${className}`,
        style: {
          fontFamily: isMono ? astryxTokens.fonts.mono : astryxTokens.fonts.sans,
          ...style,
        },
        ...props,
      },
      children
    );
  }
);
Text.displayName = 'AstryxText';

export interface GradientTextProps extends React.HTMLAttributes<HTMLSpanElement> {
  gradient?: 'astryx' | 'house' | 'neon';
}

export const GradientText = forwardRef<HTMLSpanElement, GradientTextProps>(
  ({ gradient = 'astryx', className = '', children, ...props }, ref) => {
    return (
      <span
        ref={ref}
        className={`text-transparent bg-clip-text ${gradientStyles[gradient]} ${className}`}
        {...props}
      >
        {children}
      </span>
    );
  }
);
GradientText.displayName = 'AstryxGradientText';

export const Code = forwardRef<HTMLElement, React.HTMLAttributes<HTMLElement>>(
  ({ className = '', children, style, ...props }, ref) => {
    return (
      <code
        ref={ref}
        className={`px-1.5 py-0.5 rounded bg-white/[0.08] text-[#00D2FF] text-xs font-mono border border-white/[0.08] ${className}`}
        style={{
          fontFamily: astryxTokens.fonts.mono,
          ...style,
        }}
        {...props}
      >
        {children}
      </code>
    );
  }
);
Code.displayName = 'AstryxCode';
