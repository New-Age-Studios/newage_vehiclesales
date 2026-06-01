import React, { useEffect, useState } from 'react';

interface PartyBalloonsProps {
  message?: string;
}

export const PartyBalloons: React.FC<PartyBalloonsProps> = ({ message }) => {
  const [balloons, setBalloons] = useState<any[]>([]);

  useEffect(() => {
    // Elegant celebration colors
    const colors = ['#EF4444', '#3B82F6', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899', '#14B8A6'];
    const newBalloons = Array.from({ length: 25 }).map((_, i) => {
      const left = Math.random() * 100;
      const animationDuration = 3 + Math.random() * 2;
      const delay = Math.random() * 0.5;
      const color = colors[Math.floor(Math.random() * colors.length)];
      return { id: i, left, animationDuration, delay, color };
    });
    setBalloons(newBalloons);
  }, []);

  return (
    <div className="fixed inset-0 pointer-events-none overflow-hidden z-[9999] flex items-center justify-center">
      {message && (
        <div className="absolute z-10 w-full flex flex-col items-center justify-center py-12 bg-gradient-to-r from-transparent via-black/90 to-transparent animate-fade-in-up">
          <div className="flex items-center gap-4 mb-3">
            <span className="text-3xl animate-pulse">✨</span>
            <h1 className="text-5xl md:text-6xl font-black uppercase tracking-widest text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-yellow-400 to-amber-200 drop-shadow-[0_0_15px_rgba(250,204,21,0.6)]">
              Veículo Adquirido
            </h1>
            <span className="text-3xl animate-pulse">✨</span>
          </div>
          <p className="text-xl md:text-2xl text-zinc-100 font-light tracking-wide drop-shadow-md">
            {message}
          </p>
        </div>
      )}

      {balloons.map((b) => (
        <div
          key={b.id}
          className="absolute bottom-[-150px] flex flex-col items-center"
          style={{
            left: `${b.left}%`,
            animation: `floatUp ${b.animationDuration}s ease-in forwards`,
            animationDelay: `${b.delay}s`,
          }}
        >
          {/* Balloon shape */}
          <div 
            className="w-14 h-20 rounded-[50%] relative"
            style={{ 
              backgroundColor: b.color,
              boxShadow: 'inset -5px -5px 15px rgba(0,0,0,0.25), inset 5px 5px 10px rgba(255,255,255,0.4)'
            }}
          >
            {/* Highlight */}
            <div className="absolute top-2 left-2 w-3 h-6 rounded-full bg-white/40 transform -rotate-12 blur-[1px]"></div>
            
            {/* Balloon knot */}
            <div 
              className="absolute -bottom-2 left-1/2 -translate-x-1/2 border-l-[6px] border-r-[6px] border-b-[8px] border-transparent"
              style={{ borderBottomColor: b.color }}
            />
          </div>
          {/* String */}
          <div className="w-[1.5px] h-32 bg-white/50 mt-2 opacity-60" />
        </div>
      ))}
      <style>{`
        @keyframes floatUp {
          0% { transform: translateY(0) rotate(0deg); opacity: 1; }
          100% { transform: translateY(-130vh) rotate(${Math.random() > 0.5 ? 20 : -20}deg); opacity: 0; }
        }
        @keyframes fadeInUp {
          0% { transform: translateY(20px); opacity: 0; }
          100% { transform: translateY(0); opacity: 1; }
        }
        .animate-fade-in-up {
          animation: fadeInUp 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) forwards;
        }
      `}</style>
    </div>
  );
};
