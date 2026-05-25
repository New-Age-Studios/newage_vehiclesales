import React, { useState, useEffect, useRef } from 'react';
import { cn } from "@/lib/utils";

interface ColorPickerProps {
  color: string;
  onChange: (color: string) => void;
}

export const ColorPicker: React.FC<ColorPickerProps> = ({ color, onChange }) => {
  const [hue, setHue] = useState(0);
  const [saturation, setSaturation] = useState(100);
  const [brightness, setBrightness] = useState(100);
  
  const satRef = useRef<HTMLDivElement>(null);
  const hueRef = useRef<HTMLDivElement>(null);

  // Convert HSB to Hex
  const hsbToHex = (h: number, s: number, b: number) => {
    b /= 100;
    const l = (b * (2 - s / 100)) / 2;
    if (l !== 0) {
      if (l === 1) {
        s = 0;
      } else if (l < 0.5) {
        s = (s * b) / (l * 2);
      } else {
        s = (s * b) / (2 - l * 2);
      }
    }
    return hsvToHex(h, s, b * 100);
  };

  const hsvToHex = (h: number, s: number, v: number) => {
    s /= 100; v /= 100;
    const i = Math.floor(h / 60);
    const f = h / 60 - i;
    const p = v * (1 - s);
    const q = v * (1 - f * s);
    const t = v * (1 - (1 - f) * s);
    let r = 0, g = 0, bl = 0;
    switch (i % 6) {
      case 0: r = v; g = t; bl = p; break;
      case 1: r = q; g = v; bl = p; break;
      case 2: r = p; g = v; bl = t; break;
      case 3: r = p; g = q; bl = v; break;
      case 4: r = t; g = p; bl = v; break;
      case 5: r = v; g = p; bl = q; break;
    }
    const toHex = (x: number) => Math.round(x * 255).toString(16).padStart(2, '0');
    return `#${toHex(r)}${toHex(g)}${toHex(bl)}`.toUpperCase();
  };

  const handleSatMouseDown = (e: React.MouseEvent | React.TouchEvent) => {
    const move = (event: any) => {
      if (!satRef.current) return;
      const rect = satRef.current.getBoundingClientRect();
      const x = 'touches' in event ? event.touches[0].clientX : event.clientX;
      const y = 'touches' in event ? event.touches[0].clientY : event.clientY;
      const s = Math.max(0, Math.min(100, ((x - rect.left) / rect.width) * 100));
      const v = Math.max(0, Math.min(100, (1 - (y - rect.top) / rect.height) * 100));
      setSaturation(s);
      setBrightness(v);
      onChange(hsvToHex(hue, s, v));
    };
    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    move(e);
  };

  const handleHueMouseDown = (e: React.MouseEvent | React.TouchEvent) => {
    const move = (event: any) => {
      if (!hueRef.current) return;
      const rect = hueRef.current.getBoundingClientRect();
      const x = 'touches' in event ? event.touches[0].clientX : event.clientX;
      const h = Math.max(0, Math.min(360, ((x - rect.left) / rect.width) * 360));
      setHue(h);
      onChange(hsvToHex(h, saturation, brightness));
    };
    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    move(e);
  };

  return (
    <div className="flex flex-col space-y-4 p-2 bg-zinc-900 rounded-xl border border-zinc-800">
      {/* Saturation/Brightness Square */}
      <div 
        ref={satRef}
        onMouseDown={handleSatMouseDown}
        className="relative w-full h-40 rounded-lg cursor-crosshair overflow-hidden"
        style={{ backgroundColor: `hsl(${hue}, 100%, 50%)` }}
      >
        <div className="absolute inset-0 bg-gradient-to-r from-white to-transparent"></div>
        <div className="absolute inset-0 bg-gradient-to-t from-black to-transparent"></div>
        
        {/* Selector Dot */}
        <div 
          className="absolute w-3 h-3 border-2 border-white rounded-full -translate-x-1/2 translate-y-1/2 shadow-lg"
          style={{ 
            left: `${saturation}%`, 
            bottom: `${brightness}%`,
            backgroundColor: color 
          }}
        />
      </div>

      {/* Hue Slider */}
      <div className="px-1">
        <div 
          ref={hueRef}
          onMouseDown={handleHueMouseDown}
          className="relative w-full h-4 rounded-full cursor-pointer"
          style={{ background: 'linear-gradient(to right, #ff0000 0%, #ffff00 17%, #00ff00 33%, #00ffff 50%, #0000ff 67%, #ff00ff 83%, #ff0000 100%)' }}
        >
          <div 
            className="absolute w-4 h-4 bg-white border-2 border-zinc-900 rounded-full -translate-x-1/2 shadow-md top-0"
            style={{ left: `${(hue / 360) * 100}%` }}
          />
        </div>
      </div>
    </div>
  );
};
