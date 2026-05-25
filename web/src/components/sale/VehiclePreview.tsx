import React from 'react';
import { Camera } from 'lucide-react';

interface VehiclePreviewProps {
  model: string;
}

export const VehiclePreview: React.FC<VehiclePreviewProps> = ({ model }) => {
  const photoUrl = `https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/${model.toLowerCase()}.jpg`;
  
  return (
    <div className="relative group rounded-xl overflow-hidden h-40 bg-zinc-900 border border-zinc-800 flex items-center justify-center">
      <img 
        src={photoUrl} 
        alt={model}
        className="w-full h-full object-cover opacity-60 group-hover:scale-105 transition-transform duration-700"
        onError={(e) => {
          (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&q=80&w=800';
        }}
      />
      <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-transparent to-transparent"></div>
      <div className="absolute bottom-4 left-4 flex items-center space-x-2">
        <div className="bg-concessionaire p-1.5 rounded-lg">
          <Camera size={14} className="text-black" />
        </div>
        <span className="text-[10px] font-black text-white uppercase tracking-widest">Visualização em Tempo Real</span>
      </div>
    </div>
  );
};
