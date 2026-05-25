import React from 'react';
import { useLocale } from '../../context/LocaleContext';

interface VehiclePhotoProps {
  url?: string;
  model: string;
}

export const VehiclePhoto: React.FC<VehiclePhotoProps> = ({ url, model }) => {
  const [hasError, setHasError] = React.useState(false);
  const t = useLocale();

  return (
    <div className="relative group">
      <div className="aspect-square w-full bg-zinc-100 border border-zinc-200 overflow-hidden shadow-sm flex items-center justify-center">
        {url && !hasError ? (
          <img 
            src={url} 
            alt={model} 
            className="w-full h-full object-cover"
            onError={() => setHasError(true)}
          />
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center text-zinc-300 bg-zinc-50 space-y-1">
            <div className="w-10 h-10 border-2 border-zinc-200 rounded-full flex items-center justify-center">
              <span className="text-xl font-bold opacity-20">V</span>
            </div>
            <span className="text-[8px] text-center font-bold uppercase tracking-widest opacity-40 italic px-2">{t.contract.imageUnavailable}</span>
          </div>
        )}
      </div>
      <div className="mt-1 text-center">
        <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">{t.contract.figureCaption}</span>
      </div>
    </div>
  );
};
