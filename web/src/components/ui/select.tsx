import * as React from "react"
import { cn } from "@/lib/utils"
import { ChevronDown } from "lucide-react"

export interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {}

const Select = React.forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <div className="relative w-full">
        <select
          className={cn(
            "flex h-10 w-full appearance-none rounded-md border border-zinc-800 bg-zinc-950 px-3 py-2 text-xs ring-offset-zinc-950 focus:outline-none focus:ring-2 focus:ring-concessionaire focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 text-zinc-200 font-bold uppercase tracking-tighter",
            className
          )}
          ref={ref}
          {...props}
        >
          {children}
        </select>
        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none" size={14} />
      </div>
    )
  }
)
Select.displayName = "Select"

export { Select }
