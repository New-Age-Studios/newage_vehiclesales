import React from 'react';
import { VehicleData } from '../../types/contract';
import { Separator } from '../ui/separator';
import { useLocale } from '../../context/LocaleContext';

interface VehicleInfoProps {
  vehicle: VehicleData;
}

export const VehicleInfo: React.FC<VehicleInfoProps> = ({ vehicle }) => {
  const { t } = useLocale();
  const infoItems = [
    { label: t('spec_model'), value: vehicle.model },
    { label: t('spec_plate'), value: vehicle.plate },
    { 
      label: t('contract_color'), 
      value: (
        <div className="flex items-center space-x-2">
          {vehicle.color && vehicle.color !== 'Personalizada' && (
            <span className="font-bold">{vehicle.color}</span>
          )}
          {vehicle.colorRGB && (
            <div 
              className="w-4 h-4 rounded-sm rotate-3 shadow-[inset_0_0_2px_rgba(0,0,0,0.2)] opacity-80" 
              style={{ 
                backgroundColor: vehicle.colorRGB,
                borderRadius: '2px 4px 3px 5px',
              }}
            />
          )}
          {vehicle.isExotic && (
            <span className="text-[7px] font-black bg-zinc-900 text-white px-1.5 py-0.5 rounded-sm tracking-tighter ml-1">
              EXÓTICA
            </span>
          )}
        </div>
      )
    },
    { label: t('spec_mileage'), value: vehicle.mileage || '12.300 KM' },
    { label: t('spec_fuel'), value: vehicle.fuelType || vehicle.fuel || t('fuel_gasoline') },
    { label: t('spec_transmission'), value: vehicle.transmission || t('trans_auto') },
  ];

  return (
    <div className="space-y-3">
      <div className="flex items-center space-x-2">
        <h2 className="text-[9px] font-black text-zinc-800 uppercase tracking-widest whitespace-nowrap">{t('contract_tech_specs')}</h2>
        <Separator className="bg-zinc-200" />
      </div>
      
      <div className="grid grid-cols-2 gap-x-4 gap-y-2">
        {infoItems.map((item, idx) => (
          <div key={idx} className="flex flex-col border-b border-zinc-100 pb-0.5">
            <span className="text-[8px] font-bold text-zinc-400 uppercase tracking-tighter">{item.label}</span>
            <div className="text-[11px] font-black text-zinc-900 uppercase leading-none mt-0.5">{item.value}</div>
          </div>
        ))}
      </div>

      <div className="mt-2">
        <span className="text-[8px] font-bold text-zinc-400 uppercase block">{t('contract_seller_obs')}</span>
        <p className="text-[10px] text-zinc-800 font-medium italic leading-[1.3] mt-0.5 break-words line-clamp-3">
          "{vehicle.description}"
        </p>
      </div>
    </div>
  );
};
