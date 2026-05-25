import React from 'react';
import { Camera } from 'lucide-react';
import { useLocale } from '../../context/LocaleContext';

interface VehiclePreviewProps {
  model: string;
  photoUrl?: string;
  onTakePhoto?: () => void;
}

export const VehiclePreview: React.FC<VehiclePreviewProps> = ({ model, photoUrl, onTakePhoto }) => {
  const t = useLocale();
  const defaultPhoto = `https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/${model.toLowerCase()}.jpg`;
  const displayPhoto = photoUrl || defaultPhoto;
  const hasCustomPhoto = !!photoUrl;

  return (
    <button 
      onClick={onTakePhoto}
      disabled={!onTakePhoto}
      className="w-full text-left relative group rounded-xl overflow-hidden h-40 bg-zinc-900 border border-zinc-800 flex items-center justify-center cursor-pointer hover:border-concessionaire/40 transition-all duration-300 focus:outline-none"
    >
      <img 
        src={displayPhoto} 
        alt={model}
        className="w-full h-full object-cover opacity-60 group-hover:scale-105 transition-transform duration-700"
        onError={(e) => {
          (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&q=80&w=800';
        }}
      />
      <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-transparent to-transparent"></div>
      
      {!hasCustomPhoto && onTakePhoto && (
        <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/60 backdrop-blur-sm group-hover:bg-black/40 transition-all duration-300">
          <div className="bg-red-500 p-2.5 rounded-full text-white mb-2 animate-bounce">
            <Camera size={20} />
          </div>
          <span className="text-[10px] font-black text-white uppercase tracking-widest">{t.vehiclePreview.takePhoto}</span>
          <span className="text-[8px] font-bold text-red-400 uppercase mt-0.5 tracking-wider">{t.vehiclePreview.mandatory}</span>
        </div>
      )}

      {hasCustomPhoto && (
        <div className="absolute bottom-4 left-4 flex items-center space-x-2">
          <div className="bg-concessionaire p-1.5 rounded-lg">
            <Camera size={14} className="text-black" />
          </div>
          <span className="text-[10px] font-black text-white uppercase tracking-widest">
            {onTakePhoto ? t.vehiclePreview.photoCaptured : t.vehiclePreview.vehiclePhoto}
          </span>
        </div>
      )}
    </button>
  );
};
