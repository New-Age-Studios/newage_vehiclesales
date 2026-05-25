import * as React from "react"
import { cn } from "../../lib/utils"

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    const variants = {
      primary: 'bg-concessionaire hover:bg-concessionaire-dark text-white shadow-lg',
      outline: 'border-2 border-concessionaire text-concessionaire hover:bg-concessionaire/10',
      ghost: 'text-zinc-400 hover:text-white transition-colors',
      danger: 'bg-red-600 hover:bg-red-700 text-white shadow-lg',
    }
    
    const sizes = {
      sm: 'px-3 py-1.5 text-xs font-semibold',
      md: 'px-6 py-2.5 text-sm font-bold uppercase tracking-wider',
      lg: 'px-8 py-3 text-base font-bold uppercase tracking-widest',
    }

    return (
      <button
        className={cn(
          "inline-flex items-center justify-center rounded-sm transition-all active:scale-95 disabled:opacity-50 disabled:pointer-events-none",
          variants[variant],
          sizes[size],
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button }
