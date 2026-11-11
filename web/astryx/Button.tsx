import React, { forwardRef } from 'react';
import { astryxTokens } from './tokens';

export type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger' | 'sonar';
export type ButtonSize = 'sm' | 'md' | 'lg';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  fullWidth?: boolean;
}

const variantStyles: Record<ButtonVariant, string> = {
  primary:
    'bg-gradient-to-r from-[#C800DF] via-[#8B5CF6] to-[#00D2FF] text-white font-medium shadow-[0_0_25px_rgba(200,0,223,0.35)] hover:shadow-[0_0_35px_rgba(0,210,255,0.5)] border-0 hover:brightness-110 active:scale-[0.98]',
  sonar:
    'bg-[#00D2FF] text-[#05070C] font-semibold shadow-[0_0_25px_rgba(0,210,255,0.4)] hover:shadow-[0_0_35px_rgba(0,210,255,0.65)] hover:bg-[#38dcfc] active:scale-[0.98]',
  secondary:
    'bg-[#101218] text-[#E2E8F0] border border-white/10 hover:border-white/20 hover:bg-[#1a1c24] active:scale-[0.98]',
  outline:
    'bg-transparent text-[#E2E8F0] border border-white/20 hover:border-[#00D2FF] hover:text-[#00D2FF] hover:shadow-[0_0_20px_rgba(0,210,255,0.2)] active:scale-[0.98]',
  ghost:
    'bg-transparent text-[#94A3B8] hover:text-white hover:bg-white/5 active:scale-[0.98]',
  danger:
    'bg-[#E60076]/90 text-white font-medium border border-[#E60076] hover:bg-[#E60076] hover:shadow-[0_0_25px_rgba(230,0,118,0.4)] active:scale-[0.98]',
};

const sizeStyles: Record<ButtonSize, string> = {
  sm: 'px-3 py-1.5 text-xs rounded-md gap-1.5',
  md: 'px-4 py-2 text-sm rounded-lg gap-2',
  lg: 'px-6 py-3 text-base rounded-xl gap-2.5',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      isLoading = false,
      leftIcon,
      rightIcon,
      fullWidth = false,
      disabled,
      className = '',
      children,
      style,
      ...props
    },
    ref
  ) => {
    const isDisabled = disabled || isLoading;

    return (
      <button
        ref={ref}
        disabled={isDisabled}
        className={`inline-flex items-center justify-center font-sans tracking-wide transition-all duration-200 cursor-pointer select-none disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none ${
          fullWidth ? 'w-full' : ''
        } ${variantStyles[variant]} ${sizeStyles[size]} ${className}`}
        style={{
          fontFamily: astryxTokens.fonts.sans,
          ...style,
        }}
        {...props}
      >
        {isLoading && (
          <svg
            className="animate-spin -ml-1 mr-2 h-4 w-4 text-current"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"
            />
          </svg>
        )}
        {!isLoading && leftIcon && <span className="inline-flex shrink-0">{leftIcon}</span>}
        <span>{children}</span>
        {!isLoading && rightIcon && <span className="inline-flex shrink-0">{rightIcon}</span>}
      </button>
    );
  }
);

Button.displayName = 'AstryxButton';
