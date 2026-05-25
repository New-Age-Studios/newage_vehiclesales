import React, { useState, useRef, useEffect } from 'react';
import { cn } from "@/lib/utils";
import { ChevronDown, Check } from "lucide-react";

interface CustomSelectProps {
  value: string;
  options: string[];
  onChange: (value: string) => void;
  label?: string;
}

export const CustomSelect: React.FC<CustomSelectProps> = ({ value, options, onChange, label }) => {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative w-full" ref={containerRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={cn(
          "flex h-7 w-full items-center justify-between rounded-md border border-zinc-800 bg-zinc-950 px-3 py-1 text-[9px] font-black uppercase tracking-widest text-zinc-200 transition-all focus:outline-none focus:ring-1 focus:ring-concessionaire",
          isOpen && "border-concessionaire shadow-[0_0_10px_rgba(34,197,94,0.2)]"
        )}
      >
        <span>{value}</span>
        <ChevronDown className={cn("text-zinc-500 transition-transform duration-200", isOpen && "rotate-180 text-concessionaire")} size={12} />
      </button>

      {isOpen && (
        <div className="absolute z-50 mt-1 w-full rounded-md border border-zinc-800 bg-zinc-950 p-1 shadow-2xl animate-in fade-in slide-in-from-top-1 duration-200">
          {options.map((option) => (
            <button
              key={option}
              onClick={() => {
                onChange(option);
                setIsOpen(false);
              }}
              className={cn(
                "flex w-full items-center justify-between rounded px-2 py-2 text-[10px] font-bold uppercase tracking-tighter transition-colors",
                value === option 
                  ? "bg-concessionaire/10 text-concessionaire" 
                  : "text-zinc-400 hover:bg-zinc-900 hover:text-white"
              )}
            >
              <span>{option}</span>
              {value === option && <Check size={12} />}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};
