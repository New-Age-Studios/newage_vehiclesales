import React, { useEffect, useState } from 'react';
import { Camera, RotateCw, ZoomIn, Eye, Sparkles } from 'lucide-react';
import { useLocale } from '../../context/LocaleContext';

export const CameraOverlay: React.FC = () => {
  const [blink, setBlink] = useState(true);
  const t = useLocale();

  // Blinking REC effect
  useEffect(() => {
    const interval = setInterval(() => {
      setBlink((prev) => !prev);
    }, 750);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="absolute inset-0 w-full h-full pointer-events-none select-none flex flex-col justify-between p-6 bg-transparent">
      
      {/* Top DSLR Status Bar */}
      <div className="w-full flex justify-between items-center text-white/70 font-mono text-[10px] tracking-widest uppercase">
        {/* REC Indicator */}
        <div className="flex items-center space-x-2 bg-black/60 px-3 py-1.5 rounded-lg border border-white/10">
          <span className={`w-2.5 h-2.5 rounded-full bg-red-600 transition-opacity duration-300 ${blink ? 'opacity-100' : 'opacity-20'}`}></span>
          <span className="font-black">{t.cameraOverlay.captureMode}</span>
        </div>

        {/* Battery & Storage Info */}
        <div className="flex items-center space-x-4 bg-black/60 px-3 py-1.5 rounded-lg border border-white/10">
          <span>RAW</span>
          <span>1080P</span>
          <div className="flex items-center space-x-1">
            <span className="font-bold">{t.cameraOverlay.battery}</span>
            <div className="w-6 h-3 border border-white/40 rounded-sm p-[1px] flex items-center">
              <div className="w-full h-full bg-green-500 rounded-[1px]"></div>
            </div>
            <span>100%</span>
          </div>
        </div>
      </div>

      {/* Center Viewfinder / Focusing Grid */}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-0">
        {/* 3x3 Grid Lines */}
        <div className="w-full h-full grid grid-cols-3 grid-rows-3 relative opacity-25">
          <div className="border-r border-b border-white/40"></div>
          <div className="border-r border-b border-white/40"></div>
          <div className="border-b border-white/40"></div>
          <div className="border-r border-b border-white/40"></div>
          <div className="border-r border-b border-white/40"></div>
          <div className="border-b border-white/40"></div>
          <div className="border-r border-white/40"></div>
          <div className="border-r border-white/40"></div>
          <div></div>

          {/* DSLR Center Focusing Brackets */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-28 h-20 border-2 border-concessionaire/60 rounded-xl flex items-center justify-center">
            <div className="w-2.5 h-2.5 rounded-full bg-concessionaire/80 animate-ping"></div>
            <div className="w-1 h-1 rounded-full bg-concessionaire"></div>
          </div>
        </div>
      </div>

      {/* DSLR Settings Bar & Instructions Dashboard */}
      <div className="w-full flex flex-col items-center space-y-4 z-10 pointer-events-none">
        
        {/* Camera Exposure / Settings strip */}
        <div className="flex items-center space-x-8 bg-zinc-950/90 border border-zinc-800 px-6 py-2.5 rounded-2xl shadow-xl text-white/80 font-mono text-xs tracking-wider">
          <div className="flex items-center space-x-1.5">
            <span className="text-zinc-500 font-bold">F</span>
            <span className="font-bold">2.8</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="text-zinc-500 font-bold">SS</span>
            <span className="font-bold">1/250</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="text-zinc-500 font-bold">ISO</span>
            <span className="font-bold text-concessionaire">400</span>
          </div>
          <div className="w-px h-4 bg-zinc-800"></div>
          <div className="flex items-center space-x-1.5">
            <span className="text-zinc-500 font-bold">EV</span>
            <span className="font-bold text-green-400">+0.3</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="text-zinc-500 font-bold">FOCUS</span>
            <span className="font-bold uppercase text-concessionaire flex items-center gap-1">
              AF-C <span className="w-1.5 h-1.5 rounded-full bg-concessionaire"></span>
            </span>
          </div>
        </div>

        {/* Instructions Cards */}
        <div className="w-full max-w-2xl bg-zinc-950/95 border border-zinc-800 rounded-3xl p-5 shadow-2xl flex justify-between items-center">
          
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-concessionaire/10 border border-concessionaire/20 rounded-2xl text-concessionaire">
              <Camera size={22} className="animate-pulse" />
            </div>
            <div>
              <h4 className="text-sm font-black text-white uppercase tracking-tight">{t.cameraOverlay.photographVehicle}</h4>
              <p className="text-[10px] text-zinc-500 uppercase font-bold tracking-wider mt-0.5">{t.cameraOverlay.positionBestAngle}</p>
            </div>
          </div>

          <div className="flex items-center space-x-6">
            <div className="flex flex-col items-center">
              <div className="flex items-center space-x-1">
                <kbd className="px-2 py-1 rounded bg-zinc-900 border border-zinc-800 text-white font-mono text-[9px] font-bold shadow-sm">MOUSE</kbd>
              </div>
              <span className="text-[8px] text-zinc-500 uppercase font-black tracking-wider mt-1.5 flex items-center gap-1">
                <RotateCw size={8} /> {t.cameraOverlay.orbit}
              </span>
            </div>

            <div className="flex flex-col items-center">
              <div className="flex items-center space-x-1">
                <kbd className="px-2 py-1 rounded bg-zinc-900 border border-zinc-800 text-white font-mono text-[9px] font-bold shadow-sm">SCROLL</kbd>
              </div>
              <span className="text-[8px] text-zinc-500 uppercase font-black tracking-wider mt-1.5 flex items-center gap-1">
                <ZoomIn size={8} /> {t.cameraOverlay.zoom}
              </span>
            </div>

            <div className="flex flex-col items-center">
              <div className="flex items-center space-x-1">
                <kbd className="px-2.5 py-1 rounded bg-concessionaire text-black font-mono text-[9px] font-black shadow-sm">E</kbd>
              </div>
              <span className="text-[8px] text-concessionaire uppercase font-black tracking-wider mt-1.5 flex items-center gap-1">
                <Eye size={8} /> {t.cameraOverlay.capture}
              </span>
            </div>

            <div className="flex flex-col items-center">
              <div className="flex items-center space-x-1">
                <kbd className="px-2 py-1 rounded bg-red-950/40 border border-red-900/60 text-red-400 font-mono text-[9px] font-bold shadow-sm">ESC</kbd>
              </div>
              <span className="text-[8px] text-red-400 uppercase font-black tracking-wider mt-1.5">{t.cameraOverlay.cancel}</span>
            </div>
          </div>

        </div>

      </div>

    </div>
  );
};
